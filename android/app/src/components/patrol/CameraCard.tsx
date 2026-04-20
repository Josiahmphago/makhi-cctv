import { useEffect, useMemo, useState } from "react";
import type { CameraDoc } from "../types";

type Props = {
  cam: { id: string; data: CameraDoc };
  refreshMs?: number; // snapshot refresh interval
};

export default function CameraCard({ cam, refreshMs = 10000 }: Props) {
  const { name, ipAddress, area, location, isActive } = cam.data;

  // A changing URL busts the cache to get a fresh frame from /shot or /capture
  const [ver, setVer] = useState(() => Date.now());
  useEffect(() => {
    const t = setInterval(() => setVer(Date.now()), refreshMs);
    return () => clearInterval(t);
  }, [refreshMs]);

  // prefer /shot if your firmware supports it; fallback to /capture
  const shotUrl = useMemo(
    () => `http://${ipAddress}/shot?ts=${ver}`,
    [ipAddress, ver]
  );
  const capUrl = useMemo(
    () => `http://${ipAddress}/capture?ts=${ver}`,
    [ipAddress, ver]
  );
  const streamUrl = `http://${ipAddress}/stream`;

  // try /shot first; if it errors, fallback to /capture for the thumbnail
  const [imgSrc, setImgSrc] = useState(shotUrl);
  useEffect(() => setImgSrc(shotUrl), [shotUrl]);
  const onImgError = () => setImgSrc(capUrl);

  return (
    <div
      style={{
        border: "1px solid #e5e7eb",
        borderRadius: 12,
        padding: 12,
        display: "grid",
        gap: 8,
        background: "#fff",
        boxShadow: "0 1px 2px rgba(0,0,0,0.06)",
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", gap: 8 }}>
        <div>
          <div style={{ fontWeight: 600 }}>{name || cam.id}</div>
          <div style={{ fontSize: 12, color: "#6b7280" }}>
            {area || "—"} • {location || "—"}
          </div>
        </div>
        <div
          title={isActive ? "Active" : "Inactive"}
          style={{
            width: 10,
            height: 10,
            borderRadius: "50%",
            marginTop: 6,
            background: isActive ? "#10b981" : "#f59e0b",
          }}
        />
      </div>

      <a href={streamUrl} target="_blank" rel="noreferrer" title="Open live stream">
        <img
          src={imgSrc}
          onError={onImgError}
          alt={`${name || cam.id} snapshot`}
          style={{
            width: "100%",
            aspectRatio: "4 / 3",
            objectFit: "cover",
            borderRadius: 8,
            background: "#f3f4f6",
          }}
        />
      </a>

      <div style={{ display: "flex", gap: 8 }}>
        <a
          href={streamUrl}
          target="_blank"
          rel="noreferrer"
          style={btn}
          title="Open MJPEG stream"
        >
          🎥 Stream
        </a>
        <a
          href={`http://${ipAddress}/status`}
          target="_blank"
          rel="noreferrer"
          style={btnGhost}
          title="Open status JSON"
        >
          📊 Status
        </a>
      </div>

      <div style={{ fontSize: 12, color: "#6b7280" }}>
        IP: <code>{ipAddress}</code>
      </div>
    </div>
  );
}

const btn: React.CSSProperties = {
  padding: "8px 12px",
  borderRadius: 8,
  background: "#111827",
  color: "#fff",
  textDecoration: "none",
  fontSize: 14,
};
const btnGhost: React.CSSProperties = {
  ...btn,
  background: "transparent",
  color: "#111827",
  border: "1px solid #111827",
};
