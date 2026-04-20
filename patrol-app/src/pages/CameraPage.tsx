import { useEffect, useState } from "react";
import type { CctvCamera } from "@/type";
import StreamModal from "@/components/StreamModal";

export default function CameraPage() {
  const [cam, setCam] = useState<CctvCamera | null>(null);
  useEffect(() => {
    setCam({
      id: "single",
      name: "cam_block_f_street_1",
      ipAddress: "192.168.18.25",
      isActive: true,
      thumbnailUrl: "http://192.168.18.25/shot",
      streamUrl: "http://192.168.18.25/stream",
    });
  }, []);
  if (!cam) return <div className="p-4">Loading…</div>;

  return (
    <div className="p-4">
      <h1 className="text-xl font-semibold mb-3">{cam.name}</h1>
      <img className="rounded-lg border" src={cam.thumbnailUrl} />
      <div className="mt-3">
        <StreamModal cam={cam} onClose={() => {}} />
      </div>
    </div>
  );
}
