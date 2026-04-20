"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.serverTimestamp = exports.funcs = exports.db = exports.auth = exports.app = exports.callCreateCheckout = void 0;
exports.ensureSignedIn = ensureSignedIn;
// src/firebaseClient.ts
const app_1 = require("firebase/app");
const auth_1 = require("firebase/auth");
const firestore_1 = require("firebase/firestore");
Object.defineProperty(exports, "serverTimestamp", { enumerable: true, get: function () { return firestore_1.serverTimestamp; } });
const functions_1 = require("firebase/functions");
/**
 * Use emulators when running locally.
 * You can force this via Vite env: VITE_USE_EMULATORS=1
 */
const useEmulators = (typeof window !== "undefined" &&
    (window.location.hostname === "localhost" ||
        window.location.hostname === "127.0.0.1")) ||
    (typeof import.meta !== "undefined" &&
        import.meta.env?.VITE_USE_EMULATORS === "1");
// Minimal Firebase config — projectId is enough for emulator.
// In production, add the full config from Firebase console.
const firebaseConfig = {
    apiKey: "dev-placeholder",
    authDomain: "dev-placeholder",
    projectId: "makhi-cctv",
    appId: "dev-placeholder",
};
const app = (0, app_1.getApps)().length ? (0, app_1.getApps)()[0] : (0, app_1.initializeApp)(firebaseConfig);
exports.app = app;
// Auth
const auth = (0, auth_1.getAuth)(app);
exports.auth = auth;
// Firestore
const db = (0, firestore_1.getFirestore)(app);
exports.db = db;
// Functions
const funcs = (0, functions_1.getFunctions)(app);
exports.funcs = funcs;
if (useEmulators) {
    (0, auth_1.connectAuthEmulator)(auth, "http://127.0.0.1:9100", { disableWarnings: true });
    (0, firestore_1.connectFirestoreEmulator)(db, "127.0.0.1", 8085);
    (0, functions_1.connectFunctionsEmulator)(funcs, "127.0.0.1", 5005);
}
// Helper: ensure we have a user (anonymous is fine for your tests)
async function ensureSignedIn() {
    return new Promise((resolve) => {
        const unsub = (0, auth_1.onAuthStateChanged)(auth, async (user) => {
            if (!user)
                await (0, auth_1.signInAnonymously)(auth);
            unsub();
            resolve();
        });
    });
}
// Callable functions
exports.callCreateCheckout = (0, functions_1.httpsCallable)(funcs, "createCheckout");
//# sourceMappingURL=firebaseClient.js.map