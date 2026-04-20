import { useState } from "react";
import { useCameras } from "../hooks/useCameras";
import CameraCard from "../components/CameraCard";

export default function PatrolDashboard() {
  const [teamFilter, setTeamFilter] = useState<string>("");
  const { cameras, loading } = useCameras(teamFilter || undefined);

  return (
    <div style={{ padding: 16, maxWidth: 1200, margin: "0 auto" }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 10 }}>
        Patrol Dashboard
      </h1>

      <div
        style={{
          display: "flex",
          gap: 12,
          alignItems: "center",
          marginBottom: 16,
          flexWrap: "wrap",
        }}
      >
        <input
          placeholder="Filter by patrolTeamId (optional)"
          value={teamFilter}
          onChange={(e) => setTeamFilter(e.target.value)}
          style={{
            padding: "8px 12px",
            borderRadius: 8,
            border: "1px solid #e5e7eb",
            width: 260,
          }}
        />
        <span style={{ fontSize: 12, color: "#6b7280" }}>
          Showing {loading ? "…" : cameras.length} cameras
        </span>
      </div>

      {loading ? (
        <div>Loading cameras…</div>
      ) : cameras.length === 0 ? (
        <div>No cameras found. Add docs in <code>cctv_cameras</code>.</div>
      ) : (
        <div
          style={{
            display: "grid",
            gap: 12,
            gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))",
          }}
        >
          {cameras.map((c) => (
            <CameraCard key={c.id} cam={c} />
          ))}
        </div>
      )}
    </div>
  );
}
