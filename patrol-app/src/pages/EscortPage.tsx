import { useState } from "react";
import { addDoc, collection, deleteDoc, doc, updateDoc, Timestamp } from "firebase/firestore";
import { db } from "../lib/firebase";
import { useCollection } from "../hooks/useCollection";

type EscortReq = {
  id?: string;
  requesterName: string;
  phone?: string;
  from?: string;
  to?: string;
  status: "pending" | "assigned" | "enroute" | "done" | "cancelled";
  createdAt: any;
  assignedAgentId?: string;
};

export default function EscortPage() {
  const { data: requests, loading, error } = useCollection<EscortReq>(
    "escort_requests",
    { orderBy: ["createdAt", "desc"] }
  );

  const [form, setForm] = useState({ requesterName: "", phone: "", from: "", to: "" });
  const [busy, setBusy] = useState(false);

  const onCreate = async () => {
    if (!form.requesterName) return alert("Name required");
    setBusy(true);
    try {
      await addDoc(collection(db, "escort_requests"), {
        requesterName: form.requesterName,
        phone: form.phone || "",
        from: form.from || "",
        to: form.to || "",
        status: "pending",
        createdAt: Timestamp.now(),
      } as EscortReq);
      setForm({ requesterName: "", phone: "", from: "", to: "" });
    } finally { setBusy(false); }
  };

  const onUpdate = async (id: string, patch: Partial<EscortReq>) =>
    updateDoc(doc(db, "escort_requests", id), patch);

  const onDelete = async (id: string) => {
    if (!confirm("Delete this escort request?")) return;
    await deleteDoc(doc(db, "escort_requests", id));
  };

  return (
    <div className="page">
      <h2>Escort Requests</h2>

      <div className="card">
        <h3>+ New escort</h3>
        <div className="grid">
          <input placeholder="Name *" value={form.requesterName} onChange={(e)=>setForm(f=>({...f, requesterName: e.target.value}))}/>
          <input placeholder="Phone" value={form.phone} onChange={(e)=>setForm(f=>({...f, phone: e.target.value}))}/>
          <input placeholder="From" value={form.from} onChange={(e)=>setForm(f=>({...f, from: e.target.value}))}/>
          <input placeholder="To" value={form.to} onChange={(e)=>setForm(f=>({...f, to: e.target.value}))}/>
        </div>
        <button disabled={busy} onClick={onCreate}>{busy ? "Saving…" : "Create"}</button>
      </div>

      <div style={{ marginTop: 16 }}>
        {loading && <p>Loading…</p>}
        {error && <p style={{ color: "tomato" }}>{String(error)}</p>}
        {!loading && (!requests || requests.length === 0) && <p>No requests yet.</p>}

        {requests?.map((r) => {
          const id = (r as any).id || "";
          return (
            <div className="card" key={id} style={{ marginBottom: 12 }}>
              <div className="row">
                <b>{r.requesterName}</b>
                <span>{r.phone}</span>
              </div>
              <div className="row small">
                <span>From: {r.from || "—"}</span>
                <span>To: {r.to || "—"}</span>
                <span>Status: {r.status}</span>
              </div>

              <div className="row">
                <select
                  value={r.status}
                  onChange={(ev) => onUpdate(id, { status: ev.target.value as EscortReq["status"] })}
                >
                  <option value="pending">pending</option>
                  <option value="assigned">assigned</option>
                  <option value="enroute">enroute</option>
                  <option value="done">done</option>
                  <option value="cancelled">cancelled</option>
                </select>

                <input
                  placeholder="Assign agentId"
                  defaultValue={r.assignedAgentId || ""}
                  onBlur={(ev) => onUpdate(id, { assignedAgentId: ev.target.value })}
                />

                <button onClick={() => onDelete(id)}>Delete</button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
