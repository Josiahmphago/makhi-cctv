import { addDoc, collection, deleteDoc, doc } from "firebase/firestore";
import { useState } from "react";
import { db } from "../lib/firebase";
import { useCollection } from "../hooks/useCollection";

type PoliceShift = {
  id?: string;
  officerName: string;
  phone?: string;
  area?: string;
  onDuty: boolean;
};

export default function PolicePage() {
  const { data, loading, error } = useCollection<PoliceShift>("police_shifts", { orderBy: ["officerName", "asc"] });
  const [form, setForm] = useState({ officerName: "", phone: "", area: "" });

  const add = async () => {
    if (!form.officerName) return alert("Officer name required");
    await addDoc(collection(db, "police_shifts"), { ...form, onDuty: true });
    setForm({ officerName: "", phone: "", area: "" });
  };

  const del = async (id: string) => { await deleteDoc(doc(db, "police_shifts", id)); };

  return (
    <div className="page">
      <h2>Police On Duty</h2>
      <div className="card">
        <h3>+ Add officer</h3>
        <div className="grid">
          <input placeholder="Officer *" value={form.officerName} onChange={(e)=>setForm(f=>({...f, officerName: e.target.value}))}/>
          <input placeholder="Phone" value={form.phone} onChange={(e)=>setForm(f=>({...f, phone: e.target.value}))}/>
          <input placeholder="Area" value={form.area} onChange={(e)=>setForm(f=>({...f, area: e.target.value}))}/>
        </div>
        <button onClick={add}>Add</button>
      </div>

      {loading && <p>Loading…</p>}
      {error && <p style={{ color: "tomato" }}>{String(error)}</p>}
      {(!loading && data.length === 0) && <p>No officers.</p>}

      {data.map((p) => (
        <div className="card" key={p.id} style={{ marginTop: 8 }}>
          <div className="row">
            <b>{p.officerName}</b>
            <span>{p.phone}</span>
          </div>
          <div className="row small">
            <span>Area: {p.area || "—"}</span>
            <span>Status: {p.onDuty ? "On duty" : "Off duty"}</span>
          </div>
          <button onClick={() => del((p as any).id)}>Delete</button>
        </div>
      ))}
    </div>
  );
}
