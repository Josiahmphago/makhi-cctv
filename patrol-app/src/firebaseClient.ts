// src/firebaseClient.ts (FRONTEND ONLY — do not place in functions/)
import { initializeApp } from "firebase/app";
import { getFirestore, connectFirestoreEmulator } from "firebase/firestore";
import { getFunctions, connectFunctionsEmulator } from "firebase/functions";
import { getAuth, connectAuthEmulator } from "firebase/auth";

// Use minimal config locally
const app = initializeApp({
  apiKey: "demo",
  authDomain: "demo.firebaseapp.com",
  projectId: "makhi-cctv",
});

export const db = getFirestore(app);
export const auth = getAuth(app);
export const fn = getFunctions(app);

// Vite exposes envs on import.meta.env
const useEmu =
  typeof import.meta !== "undefined" &&
  (import.meta as any).env?.VITE_USE_EMULATORS === "1";

if (useEmu) {
  // These ports must match your running emulator suite
  connectAuthEmulator(auth, "http://127.0.0.1:9100", { disableWarnings: true });
  connectFirestoreEmulator(db, "127.0.0.1", 8085);
  connectFunctionsEmulator(fn, "127.0.0.1", 5005);
  console.log("[Makhi] Using Firebase emulators");
}
