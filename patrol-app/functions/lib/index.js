"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentWebhook = exports.createCheckout = void 0;
exports.fulfillTopup = fulfillTopup;
// functions/src/index.ts
const admin = __importStar(require("firebase-admin"));
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const utils_1 = require("./utils");
const payments_1 = require("./payments");
const reloadly_1 = require("./providers/reloadly");
// ──────────────────────────────────────────────────────────
// init & db
// ──────────────────────────────────────────────────────────
admin.initializeApp();
const db = admin.firestore();
// Log what the runtime actually sees at cold start
const BOOT_FLAGS = {
    MOCK_PAYMENTS: process.env.MOCK_PAYMENTS,
    FUNCTIONS_EMULATOR: process.env.FUNCTIONS_EMULATOR,
    FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST,
    PROJECT_ID: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT,
    WEBHOOK_URL: process.env.WEBHOOK_URL,
    SUCCESS_URL: process.env.SUCCESS_URL,
    CANCEL_URL: process.env.CANCEL_URL,
};
console.log("[BOOT] env flags:", BOOT_FLAGS);
// A conservative "emulator-ish" detector
function isEmulatorLikeEnv() {
    return (process.env.MOCK_PAYMENTS === "1" ||
        process.env.FUNCTIONS_EMULATOR === "true" ||
        !!process.env.FIREBASE_AUTH_EMULATOR_HOST);
}
// ──────────────────────────────────────────────────────────
// Callable (v2): createCheckout
// ──────────────────────────────────────────────────────────
exports.createCheckout = (0, https_1.onCall)(async (request) => {
    try {
        const emulatorMode = isEmulatorLikeEnv();
        const uid = request.auth?.uid ??
            (emulatorMode ? "local-debug-uid" : undefined);
        if (!uid) {
            // Make this error explicit (so you see it in logs, not as generic INTERNAL)
            throw new https_1.HttpsError("unauthenticated", "Login required");
        }
        // Echo what we see per-call for fast debugging
        console.log("[createCheckout] emulatorMode=", emulatorMode, {
            MOCK_PAYMENTS: process.env.MOCK_PAYMENTS,
            FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST,
        });
        const data = request.data ?? {};
        const rawMsisdn = String(data.msisdn ?? "");
        const amountZAR = Number(data.amount ?? 0);
        const bundle = data.bundle ?? null;
        const operatorInput = data.operator;
        if (!rawMsisdn || !amountZAR || amountZAR < 5) {
            throw new https_1.HttpsError("invalid-argument", "Invalid msisdn/amount");
        }
        const msisdn = (0, utils_1.normalizeMsisdn)(rawMsisdn);
        const operator = operatorInput || (0, utils_1.guessOperator)(msisdn);
        // Create a topup doc first (works in emulator and prod)
        const topupRef = await db.collection("topups").add((0, utils_1.cleanForFirestore)({
            uid,
            msisdn,
            operator,
            bundle,
            amountZAR,
            provider: "Reloadly",
            status: "initiated",
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        }));
        const successUrl = process.env.SUCCESS_URL || "http://localhost:5173/success";
        const cancelUrl = process.env.CANCEL_URL || "http://localhost:5173/cancel";
        const notifyUrl = process.env.WEBHOOK_URL ||
            "http://127.0.0.1:5005/makhi-cctv/us-central1/paymentWebhook";
        // ── MOCK SHORT-CIRCUIT: never touch external APIs when MOCK_PAYMENTS=1 ──
        if (process.env.MOCK_PAYMENTS === "1") {
            console.log("[createCheckout] MOCK mode engaged. Auto-paying & fulfilling.", { topupId: topupRef.id });
            await topupRef.update({
                status: "paid",
                webhookStatus: "MOCK_SUCCESS",
            });
            await fulfillTopup(topupRef.id);
            return {
                checkoutUrl: `http://localhost/mock/ozow/${topupRef.id}`,
                topupId: topupRef.id,
                mock: true,
            };
        }
        // ── REAL MODE: call Ozow (or your real PSP) ──
        const checkout = await (0, payments_1.createCheckoutOzow)({
            reference: topupRef.id,
            amountZAR,
            cancelUrl,
            successUrl,
            notifyUrl,
        });
        return { checkoutUrl: checkout.paymentUrl, topupId: topupRef.id };
    }
    catch (err) {
        console.error("[createCheckout] ERROR", err?.stack || err);
        // Ensure this becomes a clear callable error instead of opaque INTERNAL.
        const message = err instanceof https_1.HttpsError
            ? err.message
            : err?.message || "Unexpected error";
        throw new https_1.HttpsError("internal", `createCheckout failed: ${message}`);
    }
});
// ──────────────────────────────────────────────────────────
// Express app (HTTP) with /health and /payments/webhook
// ──────────────────────────────────────────────────────────
const app = (0, express_1.default)();
app.use((0, cors_1.default)({ origin: true }));
app.use(express_1.default.json());
// helpful probe
app.get("/health", (_req, res) => {
    res.status(200).json({
        ok: true,
        boot: BOOT_FLAGS,
        runtime: {
            MOCK_PAYMENTS: process.env.MOCK_PAYMENTS,
            FUNCTIONS_EMULATOR: process.env.FUNCTIONS_EMULATOR,
            FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST,
        },
    });
});
// webhook endpoint (remember: append /payments/webhook after function name)
app.post("/payments/webhook", async (req, res) => {
    try {
        const body = req.body || {};
        const txRef = body.transactionReference || body.reference || body.ref;
        const status = String(body.status || "").toUpperCase();
        if (!txRef) {
            return res.status(400).send("Missing reference");
        }
        const ref = db.collection("topups").doc(txRef);
        const snap = await ref.get();
        if (!snap.exists) {
            return res.status(404).send("Unknown reference");
        }
        if (status === "SUCCESS" ||
            status === "COMPLETED" ||
            process.env.MOCK_PAYMENTS === "1") {
            await ref.update({
                status: "paid",
                webhookStatus: status || "MOCK_SUCCESS",
            });
            await fulfillTopup(txRef);
            return res.status(200).send("ok");
        }
        await ref.update({
            status: "failed",
            webhookStatus: status || "UNKNOWN",
        });
        return res.status(200).send("ok");
    }
    catch (e) {
        console.error("[webhook] ERROR", e?.stack || e);
        return res.status(500).send("error");
    }
});
exports.paymentWebhook = (0, https_1.onRequest)(app);
// ──────────────────────────────────────────────────────────
async function fulfillTopup(topupId) {
    const docSnap = await db.collection("topups").doc(topupId).get();
    if (!docSnap.exists)
        return;
    // Mock: fulfill locally without calling Reloadly
    if (process.env.MOCK_PAYMENTS === "1") {
        await docSnap.ref.update({
            status: "fulfilled",
            providerRef: "MOCK_RELOADLY",
            fulfilledAt: firestore_1.FieldValue.serverTimestamp(),
        });
        console.log("[fulfillTopup] MOCK fulfilled", { topupId });
        return;
    }
    const data = docSnap.data();
    if (data.status !== "paid")
        return;
    const msisdn = data.msisdn;
    const amountZAR = data.amountZAR;
    const token = await (0, reloadly_1.getReloadlyToken)();
    const opInfo = (await (0, reloadly_1.reloadlyFindOperator)(token, msisdn));
    const operatorId = Number(opInfo?.operatorId ?? opInfo?.id ?? opInfo?.operator?.id ?? 0);
    if (!operatorId) {
        throw new https_1.HttpsError("failed-precondition", "Could not detect operator for MSISDN");
    }
    const result = (await (0, reloadly_1.reloadlyTopupLocalAmount)(token, msisdn, operatorId, amountZAR));
    const providerRef = String(result?.transactionId ?? result?.id ?? result?.reference ?? "unknown");
    await docSnap.ref.update({
        status: "fulfilled",
        providerRef,
        fulfilledAt: firestore_1.FieldValue.serverTimestamp(),
    });
    console.log("[fulfillTopup] REAL fulfilled", { topupId, providerRef });
}
//# sourceMappingURL=index.js.map