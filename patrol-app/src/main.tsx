// src/main.tsx
import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client"; // ✅ React 18 API
import App from "./App";
import "./index.css";
import { ensureAnon } from "./lib/auth";

function Boot() {
  const [ready, setReady] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const initError =
    (typeof window !== "undefined" &&
      (window as any).__MAKHI_INIT_ERROR) ||
    null;

  useEffect(() => {
    (async () => {
      try {
        await ensureAnon(); // handles anonymous sign-in internally
      } catch (e: any) {
        setErr(e?.message || String(e));
      } finally {
        setReady(true);
      }
    })();
  }, []);

  if (!ready)
    return (
      <div style={{ padding: 24, fontFamily: "system-ui" }}>
        <h2>Makhi CCTV — Starting…</h2>
        <p>Initializing Firebase / auth / config…</p>
      </div>
    );

  return (
    <>
      {(initError || err) && (
        <div
          style={{
            background: "#fff3cd",
            color: "#7a5c00",
            padding: 8,
            border: "1px solid #ffe69c",
          }}
        >
          {initError ? `Init: ${initError} ` : ""}
          {err ? `Auth: ${err}` : ""}
        </div>
      )}
      <App />
    </>
  );
}

// ✅ Mount React tree
const rootEl = document.getElementById("root")!;
createRoot(rootEl).render(
  <React.StrictMode>
    <Boot />
  </React.StrictMode>
);
