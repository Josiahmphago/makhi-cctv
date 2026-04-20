import { useState } from "react";
import { useCameras, CctvCamera } from "../hooks/useCameras";
import CameraCard from "../components/CameraCard";
import StreamModal from "../components/StreamModal";

export default function PatrolDashboard() {
  const [teamFilter, setTeamFilter] = useState("");
  const { cameras, loading, error, createCamera, updateCamera } = useCameras(
    teamFilter.trim() || undefined
  );

  const [seedBusy, setSeedBusy] = useState(false);
  const [live, setLive] = useState<CctvCamera | null>(null);

  const onSeed = async () => {
    setSeedBusy(true);
    try {
      await createCamera({
        name: "cam_block_f_street_1",
        status: "Active",
        location: "pta",
        teamId: teamFilter || "",
        ip: "192.168.18.25", // change per your LAN
        // streamUrl: "http://192.168.18.25:81/stream", // optional
      });
    } catch (e: any) {
      alert(e?.message || String(e));
    } finally {
      setSeedBusy(false);
    }
  };

  const onToggleActive = async (cam: CctvCamera) => {
    const next = cam.status === "Active" ? "Inactive" : "Active";
    await updateCamera(cam.id, { status: next });
  };

  return (
    <div className="page">
      <h2>Patrol Dashboard</h2>

      <div className="card">
        <div className="row" style={{ gap: 12, alignItems: "center" }}>
          <button disabled={seedBusy} onClick={onSeed}>
            {seedBusy ? "Seeding…" : "+ Seed camera"}
          </button>
          <div style={{ width: 1, height: 24, background: "#eee" }} />
          <label>Filter by patrolTeamId (optional)</label>
          <input
            placeholder="team id…"
            value={teamFilter}
            onChange={(e) => setTeamFilter(e.target.value)}
            style={{ width: 220 }}
          />
        </div>
      </div>

      {loading && <p>Loading cameras…</p>}
      {error && <p style={{ color: "tomato" }}>{error}</p>}

      {!loading && cameras.length === 0 && (
        <p>No cameras found. Add docs in <code>cctv_cameras</code>.</p>
      )}

      {cameras.map((cam) => (
        <CameraCard
          key={cam.id}
          cam={cam}
          onView={setLive}
          onAlert={() => alert("TODO: trigger patrol/community alert")}
          onDeactivate={onToggleActive}
        />
      ))}

      {live && <StreamModal cam={live} onClose={() => setLive(null)} />}
    </div>
  );
}
