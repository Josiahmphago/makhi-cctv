import { initializeApp, getApps } from "firebase/app";
import { connectFirestoreEmulator, getFirestore } from "firebase/firestore";
import { connectAuthEmulator, getAuth } from "firebase/auth";

const cfg = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
};

const useEmu = String(import.meta.env.VITE_USE_EMULATORS || "").toLowerCase() === "true";

const app = getApps().length ? getApps()[0] : initializeApp(cfg);

// Export non-null singletons
export const db = getFirestore(app);
export const auth = getAuth(app);

// Optional emulator hookups (safe in browser)
if (useEmu) {
  try {
    connectFirestoreEmulator(db, "127.0.0.1", 8080);
  } catch {}
  try {
    connectAuthEmulator(auth, "http://127.0.0.1:9099");
  } catch {}
}
