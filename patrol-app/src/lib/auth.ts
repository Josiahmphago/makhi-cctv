import { auth } from "./firebase";
import { onAuthStateChanged, signInAnonymously } from "firebase/auth";

export async function ensureAnon(): Promise<void> {
  // If already signed in, resolve immediately
  const current = auth.currentUser;
  if (current) return;

  await new Promise<void>((resolve, reject) => {
    const unsub = onAuthStateChanged(
      auth,
      async (user) => {
        if (user) {
          unsub();
          resolve();
        } else {
          try {
            await signInAnonymously(auth);
            // wait for state change to deliver the user
          } catch (e) {
            unsub();
            reject(e);
          }
        }
      },
      (err) => {
        unsub();
        reject(err);
      }
    );
  });
}
