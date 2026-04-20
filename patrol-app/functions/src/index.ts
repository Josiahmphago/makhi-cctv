// functions/src/index.ts
import * as admin from "firebase-admin";
import express, { Request, Response } from "express";
import cors from "cors";
import { FieldValue } from "firebase-admin/firestore";

import {
  onCall,
  onRequest,
  CallableRequest,
  HttpsError,
} from "firebase-functions/v2/https";

import { cleanForFirestore, guessOperator, normalizeMsisdn } from "./utils";
import { createCheckoutOzow } from "./payments";
import {
  getReloadlyToken,
  reloadlyFindOperator,
  reloadlyTopupLocalAmount,
} from "./providers/reloadly";
import { TopupDoc } from "./types";

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
function isEmulatorLikeEnv(): boolean {
  return (
    process.env.MOCK_PAYMENTS === "1" ||
    process.env.FUNCTIONS_EMULATOR === "true" ||
    !!process.env.FIREBASE_AUTH_EMULATOR_HOST
  );
}

// ──────────────────────────────────────────────────────────
// Callable (v2): createCheckout
// ──────────────────────────────────────────────────────────
export const createCheckout = onCall(async (request: CallableRequest<any>) => {
  try {
    const emulatorMode = isEmulatorLikeEnv();
    const uid =
      request.auth?.uid ??
      (emulatorMode ? "local-debug-uid" : undefined);

    if (!uid) {
      // Make this error explicit (so you see it in logs, not as generic INTERNAL)
      throw new HttpsError("unauthenticated", "Login required");
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
    const operatorInput = data.operator as string | undefined;

    if (!rawMsisdn || !amountZAR || amountZAR < 5) {
      throw new HttpsError("invalid-argument", "Invalid msisdn/amount");
    }

    const msisdn = normalizeMsisdn(rawMsisdn);
    const operator = operatorInput || guessOperator(msisdn);

    // Create a topup doc first (works in emulator and prod)
    const topupRef = await db.collection("topups").add(
      cleanForFirestore<TopupDoc>({
        uid,
        msisdn,
        operator,
        bundle,
        amountZAR,
        provider: "Reloadly",
        status: "initiated",
        createdAt: FieldValue.serverTimestamp(),
      })
    );

    const successUrl =
      process.env.SUCCESS_URL || "http://localhost:5173/success";
    const cancelUrl =
      process.env.CANCEL_URL || "http://localhost:5173/cancel";
    const notifyUrl =
      process.env.WEBHOOK_URL ||
      "http://127.0.0.1:5005/makhi-cctv/us-central1/paymentWebhook";

    // ── MOCK SHORT-CIRCUIT: never touch external APIs when MOCK_PAYMENTS=1 ──
    if (process.env.MOCK_PAYMENTS === "1") {
      console.log(
        "[createCheckout] MOCK mode engaged. Auto-paying & fulfilling.",
        { topupId: topupRef.id }
      );

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
    const checkout = await createCheckoutOzow({
      reference: topupRef.id,
      amountZAR,
      cancelUrl,
      successUrl,
      notifyUrl,
    });

    return { checkoutUrl: checkout.paymentUrl, topupId: topupRef.id };
  } catch (err: any) {
    console.error("[createCheckout] ERROR", err?.stack || err);
    // Ensure this becomes a clear callable error instead of opaque INTERNAL.
    const message =
      err instanceof HttpsError
        ? err.message
        : (err?.message as string) || "Unexpected error";
    throw new HttpsError("internal", `createCheckout failed: ${message}`);
  }
});

// ──────────────────────────────────────────────────────────
// Express app (HTTP) with /health and /payments/webhook
// ──────────────────────────────────────────────────────────
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// helpful probe
app.get("/health", (_req: Request, res: Response) => {
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
app.post("/payments/webhook", async (req: Request, res: Response) => {
  try {
    const body = req.body || {};
    const txRef: string =
      body.transactionReference || body.reference || body.ref;
    const status: string = String(body.status || "").toUpperCase();

    if (!txRef) {
      return res.status(400).send("Missing reference");
    }

    const ref = db.collection("topups").doc(txRef);
    const snap = await ref.get();
    if (!snap.exists) {
      return res.status(404).send("Unknown reference");
    }

    if (
      status === "SUCCESS" ||
      status === "COMPLETED" ||
      process.env.MOCK_PAYMENTS === "1"
    ) {
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
  } catch (e: any) {
    console.error("[webhook] ERROR", e?.stack || e);
    return res.status(500).send("error");
  }
});

export const paymentWebhook = onRequest(app);

// ──────────────────────────────────────────────────────────
export async function fulfillTopup(topupId: string) {
  const docSnap = await db.collection("topups").doc(topupId).get();
  if (!docSnap.exists) return;

  // Mock: fulfill locally without calling Reloadly
  if (process.env.MOCK_PAYMENTS === "1") {
    await docSnap.ref.update({
      status: "fulfilled",
      providerRef: "MOCK_RELOADLY",
      fulfilledAt: FieldValue.serverTimestamp(),
    });
    console.log("[fulfillTopup] MOCK fulfilled", { topupId });
    return;
  }

  const data = docSnap.data() as any;
  if (data.status !== "paid") return;

  const msisdn: string = data.msisdn;
  const amountZAR: number = data.amountZAR;

  const token = await getReloadlyToken();

  const opInfo = (await reloadlyFindOperator(token, msisdn)) as any;
  const operatorId = Number(
    opInfo?.operatorId ?? opInfo?.id ?? opInfo?.operator?.id ?? 0
  );
  if (!operatorId) {
    throw new HttpsError(
      "failed-precondition",
      "Could not detect operator for MSISDN"
    );
  }

  const result = (await reloadlyTopupLocalAmount(
    token,
    msisdn,
    operatorId,
    amountZAR
  )) as any;

  const providerRef = String(
    result?.transactionId ?? result?.id ?? result?.reference ?? "unknown"
  );

  await docSnap.ref.update({
    status: "fulfilled",
    providerRef,
    fulfilledAt: FieldValue.serverTimestamp(),
  });
  console.log("[fulfillTopup] REAL fulfilled", { topupId, providerRef });
}
