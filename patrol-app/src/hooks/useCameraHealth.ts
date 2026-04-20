// src/hooks/useCameraHealth.ts
import { useEffect, useState } from "react";
import type { CctvCamera } from "../type";

type Health = {
  online: boolean;
  lastChecked: number;
  latencyMs?: number;
  heap?: number;
  rssi?: number;
  error?: string;
};

export function useCameraHealth(cam: CctvCamera | null, intervalMs = 6000) {
  const [health, setHealth] = useState<Health>({ online: false, lastChecked: 0 });

  useEffect(() => {
    if (!cam?.ipAddress) return;

    let timer: any;
    const url = `http://${cam.ipAddress}/status`; // your firmware serves /status JSON

    const check = async () => {
      const start = performance.now();
      try {
        const res = await fetch(url, { method: "GET", cache: "no-store" });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json().catch(() => ({}));
        const latency = Math.round(performance.now() - start);
        setHealth({
          online: true,
          lastChecked: Date.now(),
          latencyMs: latency,
          heap: typeof data.heap === "number" ? data.heap : undefined,
          rssi: typeof data.rssi === "number" ? data.rssi : undefined,
        });
      } catch (e: any) {
        setHealth({
          online: false,
          lastChecked: Date.now(),
          error: e?.message || "fetch failed",
        });
      }
    };

    check();
    timer = setInterval(check, intervalMs);
    return () => clearInterval(timer);
  }, [cam?.ipAddress, intervalMs]);

  return health;
}
