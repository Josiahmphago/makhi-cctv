// src/components/patrol/StreamModal.tsx
import React, { useEffect, useRef } from "react";
import { CctvCamera } from "../../hooks/useCctvCameras";

type Props = {
  cam: CctvCamera | null;
  onClose: () => void;
};

export const StreamModal: React.FC<Props> = ({ cam, onClose }) => {
  const dialogRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function esc(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    document.addEventListener("keydown", esc);
    return () => document.removeEventListener("keydown", esc);
  }, [onClose]);

  if (!cam) return null;

  const isHls = cam.uiType === "hls";
  const url = cam.streamUrl || "";

  return (
    <div
      ref={dialogRef}
      className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4"
    >
      <div className="bg-white rounded-2xl w-full max-w-4xl overflow-hidden shadow-lg">
        <div className="flex items-center justify-between p-3 border-b">
          <div className="font-semibold">{cam.name}</div>
          <button
            className="text-sm px-3 py-1 rounded bg-gray-100 hover:bg-gray-200"
            onClick={onClose}
          >
            Close
          </button>
        </div>
        <div className="p-3">
          <div className="rounded-lg overflow-hidden bg-black">
            {isHls ? (
              <video src={url} controls autoPlay className="w-full h-auto" />
            ) : (
              <img src={url} alt={cam.name} className="w-full h-auto" />
            )}
          </div>
          {(cam.area || cam.location) && (
            <div className="text-xs text-gray-500 mt-2">
              {["Area: " + (cam.area ?? ""), cam.location]
                .filter(Boolean)
                .join(" • ")}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
