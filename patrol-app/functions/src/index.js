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
exports.onBreakdownCreated = exports.onEscortCreated = exports.onSosAlertCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const params_1 = require("firebase-functions/params");
const twilio_1 = __importDefault(require("twilio"));
(0, app_1.initializeApp)();
const db = (0, firestore_2.getFirestore)();
const TWILIO_SID = (0, params_1.defineSecret)("TWILIO_ACCOUNT_SID");
const TWILIO_TOKEN = (0, params_1.defineSecret)("TWILIO_AUTH_TOKEN");
const TWILIO_FROM = (0, params_1.defineSecret)("TWILIO_FROM");
async function sendSms(to, body) {
    const client = (0, twilio_1.default)(TWILIO_SID.value(), TWILIO_TOKEN.value());
    await client.messages.create({ to, from: TWILIO_FROM.value(), body });
}
exports.onSosAlertCreated = (0, firestore_1.onDocumentCreated)({
    document: "alerts/{alertId}",
    secrets: [TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM],
    region: "europe-west1"
}, async (event) => {
    const data = event.data?.data();
    if (!data || data.type !== "sos")
        return;
    const msg = data.message || "SOS Alert";
    const loc = data.locationText ? ` @ ${data.locationText}` : "";
    const text = `Makhi SOS: ${msg}${loc}`;
    const cfg = await db.doc("settings/notify").get();
    const recipients = cfg.exists ? (cfg.data()?.recipients || []) : [];
    if (!recipients.length) {
        logger.warn("No recipients configured in settings/notify.recipients");
        return;
    }
    await Promise.all(recipients.map((to) => sendSms(to, text).catch((e) => logger.error(e))));
    logger.info(`SOS SMS sent to ${recipients.length} recipient(s)`);
});
exports.onEscortCreated = (0, firestore_1.onDocumentCreated)({
    document: "escort_requests/{id}",
    secrets: [TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM],
    region: "europe-west1"
}, async (event) => {
    const r = event.data?.data();
    if (!r)
        return;
    const text = `Escort requested by ${r.requesterName}: ${r.from} → ${r.to}`;
    const cfg = await db.doc("settings/notify").get();
    const recipients = cfg.exists ? (cfg.data()?.patrol || []) : [];
    if (!recipients.length)
        return;
    await Promise.all(recipients.map((to) => sendSms(to, text)));
});
exports.onBreakdownCreated = (0, firestore_1.onDocumentCreated)({
    document: "breakdown_requests/{id}",
    secrets: [TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM],
    region: "europe-west1"
}, async (event) => {
    const r = event.data?.data();
    if (!r)
        return;
    const text = `Breakdown: ${r.vehicle || ""} at ${r.location} — ${r.requesterName}`;
    const cfg = await db.doc("settings/notify").get();
    const recipients = cfg.exists ? (cfg.data()?.towing || []) : [];
    if (!recipients.length)
        return;
    await Promise.all(recipients.map((to) => sendSms(to, text)));
});
//# sourceMappingURL=index.js.map