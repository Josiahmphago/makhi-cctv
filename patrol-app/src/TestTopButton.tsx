import React, { useState } from "react";
import { httpsCallable } from "firebase/functions";
import { signInWithEmailAndPassword } from "firebase/auth";
import { fn, auth } from "./firebaseClient";

export default function TestTopupButton() {
  const [loading, setLoading] = useState(false);
  const [output, setOutput] = useState<string | null>(null);

  const run = async () => {
    try {
      setLoading(true);
      setOutput(null);

      // 1) optional: sign into the Auth emulator so request.auth.uid exists
      try {
        await signInWithEmailAndPassword(auth, "test@local.dev", "pass1234");
      } catch {
        // If user doesn't exist in emulator, create via signInWith... won’t work.
        // You can skip auth entirely because your function allows emulator fallback.
        console.info("Auth emulator sign-in failed/ignored (OK for emulator).");
      }

      // 2) call the callable
      const createCheckout = httpsCallable(fn, "createCheckout");
      const res: any = await createCheckout({ msisdn: "0825550000", amount: 25 });

      // 3) show result
      const data = res?.data ?? {};
      console.log("createCheckout =>", data);
      setOutput(JSON.stringify(data, null, 2));
    } catch (e: any) {
      console.error(e);
      setOutput(`Error: ${e?.message || e}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: 16, border: "1px solid #ddd", borderRadius: 8 }}>
      <button onClick={run} disabled={loading} style={{ padding: "8px 12px" }}>
        {loading ? "Working..." : "Test createCheckout (emulator)"}
      </button>
      {output && (
        <pre style={{ marginTop: 12, background: "#f6f6f6", padding: 12 }}>
          {output}
        </pre>
      )}
    </div>
  );
}
