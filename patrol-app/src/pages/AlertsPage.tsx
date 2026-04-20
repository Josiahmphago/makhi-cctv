import { useCollection } from "../hooks/useCollection";

type Alert = {
  id?: string;
  cameraId?: string | null;
  cameraName?: string;
  type: string;
  message?: string;
  status: "open" | "closed";
  at: any;
};

export default function AlertsPage() {
  const { data, loading, error } = useCollection<Alert>("alerts", { orderBy: ["at", "desc"] });

  return (
    <div className="page">
      <h2>Alerts</h2>
      {loading && <p>Loading…</p>}
      {error && <p style={{ color: "tomato" }}>{String(error)}</p>}
      {(!loading && data.length === 0) && <p>No alerts yet.</p>}

      {data.map((a) => (
        <div className="card" key={(a as any).id}>
          <div className="row">
            <b>{a.type}</b>
            <span>{a.status}</span>
          </div>
          <div className="row small">
            <span>{a.cameraName}</span>
            <span>{a.message}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
