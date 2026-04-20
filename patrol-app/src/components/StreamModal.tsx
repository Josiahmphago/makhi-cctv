import React, { useMemo } from "react";
import { CctvCamera } from "../hooks/useCameras";

type Props = {
  cam: CctvCamera;
  onClose?: () => void;
};

export default function StreamModal({ cam, onClose }: Props) {
  // Best-effort URLs
  const liveUrl = useMemo(() => {
    if (cam.streamUrl && cam.streamUrl.trim().length > 0) return cam.streamUrl;
    if (cam.ip && cam.ip.trim().length > 0) return `http://${cam.ip}:81/stream`; // ESP32-CAM default
    return "";
  }, [cam.streamUrl, cam.ip]);

  const stillUrl = useMemo(() => {
    // If you later add `snapshotUrl` to the type, prefer it:
    // (cam as any).snapshotUrl ?? fallback to /capture
    const explicit = (cam as any).snapshotUrl as string | undefined;
    if (explicit && explicit.trim().length > 0) return explicit;
    if (cam.ip && cam.ip.trim().length > 0) return `http://${cam.ip}/capture`;
    return "";
  }, [cam.ip]);

  return (
    <div className="modal">
      <div className="modal-body">
        <div className="row" style={{ justifyContent: "space-between" }}>
          <h3>{cam.name} stream</h3>
          <button onClick={onClose}>Close</button>
        </div>

        {!liveUrl && (
          <div className="card" style={{ background: "#fff3cd", borderColor: "#ffe69c" }}>
            <b>Missing stream URL</b>
            <div>No <code>streamUrl</code> or <code>ip</code> found on this camera.</div>
          </div>
        )}

        {liveUrl && (
          <div style={{ display: "grid", gap: 12 }}>
            <div className="card">
              <div className="row" style={{ justifyContent: "space-between" }}>
                <b>Live stream</b>
                <a href={liveUrl} target="_blank" rel="noreferrer">
                  Open raw stream
                </a>
              </div>
              <div style={{ overflow: "hidden", borderRadius: 8 }}>
                {/* Many ESP32-CAM streams are MJPEG; <img> can render it */}
                <img
                  src={liveUrl}
                  alt={`${cam.name} stream`}
                  style={{ display: "block", width: "100%", maxHeight: 480, objectFit: "contain" }}
                />
              </div>
            </div>

            {stillUrl && (
              <div className="card">
                <div className="row" style={{ justifyContent: "space-between" }}>
                  <b>Snapshot</b>
                  <a href={stillUrl} target="_blank" rel="noreferrer">
                    Open snapshot
                  </a>
                </div>
                <img
                  src={stillUrl}
                  alt={`${cam.name} snapshot`}
                  style={{ display: "block", width: "100%", maxWidth: 640 }}
                />
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
