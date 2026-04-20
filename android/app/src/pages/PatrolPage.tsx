// src/pages/PatrolPage.tsx
import React, { useState } from "react";
import { useCctvCameras, CctvCamera } from "../hooks/useCctvCameras";
import { CameraCard } from "../components/patrol/CameraCard";
import { StreamModal } from "../components/patrol/StreamModal";

export default function PatrolPage() {
  const { cams, loading } = useCctvCameras();
  const [active, setActive] = useState<CctvCamera | null>(null);

  return (
    <div className="p-4 max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-3">
        <h1 className="text-xl font-semibold">Patrol Dashboard</h1>
        <div className="text-sm text-gray-500">
          {loading ? "Loading cameras…" : `${cams.length} camera(s)`}
        </div>
      </div>

      {cams.length === 0 && !loading && (
        <div className="text-sm text-gray-500">
          No active cameras found in <code>cctv_cameras</code> (isActive=true).
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {cams.map((cam) => (
          <CameraCard key={cam.id} cam={cam} onOpen={setActive} />
        ))}
      </div>

      <StreamModal cam={active} onClose={() => setActive(null)} />
    </div>
  );
}
