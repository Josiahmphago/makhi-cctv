// src/pages/BreakdownPage.tsx
import { useState } from "react";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} from "firebase/firestore";
import { db } from "../lib/firebase";
import { useCollection } from "../hooks/useCollection";

type TowStatus = "pending" | "assigned" | "onroute" | "towed" | "cancelled";

type TowRequest = {
  id?: string;
  callerName: string;
  phone?: string;
  location?: string;
  vehicle?: string;
  notes?: string;
  status: TowStatus;
  createdAt: Timestamp | ReturnType<typeof serverTimestamp> | null;
  assignedTowId?: string;
};

export default function BreakdownPage() {
  const { data: requests, loading, error } = useCollection<TowRequest>(
    "tow_requests",
    { orderBy: ["createdAt", "desc"] }
  );

  const [form, setForm] = useState({
    callerName: "",
    phone: "",
    location: "",
    vehicle: "",
    notes: "",
  });
  const [busy, setBusy] = useState(false);

  const onCreate = async () => {
    if (!form.callerName.trim()) return alert("Name required");
    setBusy(true);
    try {
      await addDoc(collection(db, "tow_requests"), {
        callerName: form.callerName.trim(),
        phone: form.phone.trim(),
        location: form.location.trim(),
        vehicle: form.vehicle.trim(),
        notes: form.notes.trim(),
        status: "pending" as TowStatus,
        createdAt: serverTimestamp(),
      });
      setForm({ callerName: "", phone: "", location: "", vehicle: "", notes: "" });
    } catch (e: any) {
      alert(e.message || String(e));
    } finally {
      setBusy(false);
    }
  };

  const onUpdate = async (id: string, patch: Partial<TowRequest>) => {
    try {
      await updateDoc(doc(db, "tow_requests", id), patch);
    } catch (e: any) {
      alert(e.message || String(e));
    }
  };

  const onDelete = async (id: string) => {
    if (!confirm("Delete this breakdown/tow request?")) return;
    try {
      await deleteDoc(doc(db, "tow_requests", id));
    } catch (e: any) {
      alert(e.message || String(e));
    }
  };

  return (
    <div className="page">
      <h2>Breakdown / Towing</h2>

      {/* Create */}
      <div className="card">
        <h3>+ New breakdown</h3>
        <div className="grid">
          <input
            placeholder="Caller name *"
            value={form.callerName}
            onChange={(e) => setForm((f) => ({ ...f, callerName: e.target.value }))}
          />
          <input
            placeholder="Phone"
            value={form.phone}
            onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
          />
          <input
            placeholder="Location (street)"
            value={form.location}
            onChange={(e) => setForm((f) => ({ ...f, location: e.target.value }))}
          />
          <input
            placeholder="Vehicle (e.g. Toyota Corolla, reg #)"
            value={form.vehicle}
            onChange={(e) => setForm((f) => ({ ...f, vehicle: e.target.value }))}
          />
          <input
            placeholder="Notes"
            value={form.notes}
            onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))}
          />
        </div>
        <button disabled={busy} onClick={onCreate}>
          {busy ? "Saving..." : "Create"}
        </button>
      </div>

      {/* List */}
      <div style={{ marginTop: 16 }}>
        {loading && <p>Loading…</p>}
        {error && <p style={{ color: "tomato" }}>{String(error)}</p>}
        {!loading && (!requests || requests.length === 0) && <p>No breakdowns.</p>}

        {requests?.map((r) => {
          const id = r.id!;
          return (
            <div className="card" key={id} style={{ marginBottom: 12 }}>
              <div className="row">
                <b>{r.callerName}</b>
                <span>{r.phone}</span>
              </div>
              <div className="row small">
                <span>Loc: {r.location || "—"}</span>
                <span>Vehicle: {r.vehicle || "—"}</span>
                <span>Status: {r.status}</span>
              </div>

              <div className="row">
                <select
                  value={r.status}
                  onChange={(ev) =>
                    onUpdate(id, { status: ev.target.value as TowStatus })
                  }
                >
                  <option value="pending">pending</option>
                  <option value="assigned">assigned</option>
                  <option value="onroute">onroute</option>
                  <option value="towed">towed</option>
                  <option value="cancelled">cancelled</option>
                </select>

                <input
                  placeholder="Assign towId"
                  defaultValue={r.assignedTowId || ""}
                  onBlur={(ev) => onUpdate(id, { assignedTowId: ev.target.value })}
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
