// src/pages/AgentsPage.tsx
import { useState } from "react";
import { db } from "../lib/firebase";
import { collection, addDoc, deleteDoc, doc, getDocs } from "firebase/firestore";

type Agent = {
  id?: string;
  name: string;
  phone?: string;
  role: "patrol" | "escort" | "towing" | "police";
  active: boolean;
};

export default function AgentsPage() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [form, setForm] = useState<Agent>({ name: "", phone: "", role: "patrol", active: true });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function refresh() {
    if (!db) { setError("DB_NOT_READY"); setAgents([]); return; }
    const snap = await getDocs(collection(db, "agents"));
    setAgents(snap.docs.map(d => ({ id: d.id, ...(d.data() as any) })));
  }

  async function onCreate() {
    if (!db) return setError("DB_NOT_READY");
    if (!form.name) return alert("Name required");
    setBusy(true);
    try {
      await addDoc(collection(db, "agents"), form as any);
      setForm({ name: "", phone: "", role: "patrol", active: true });
      await refresh();
    } catch (e: any) {
      setError(e?.message || String(e));
    } finally {
      setBusy(false);
    }
  }

  async function onDelete(id: string) {
    if (!db) return setError("DB_NOT_READY");
    await deleteDoc(doc(db, "agents", id));
    await refresh();
  }

  return (
    <div className="page">
      <h2>Patrol Agents</h2>
      {error && <div style={{color:"tomato"}}>{error}</div>}

      <div className="card">
        <h3>+ Add agent</h3>
        <div className="grid">
          <input placeholder="Name" value={form.name} onChange={e=>setForm({...form, name:e.target.value})}/>
          <input placeholder="Phone" value={form.phone} onChange={e=>setForm({...form, phone:e.target.value})}/>
          <select value={form.role} onChange={e=>setForm({...form, role: e.target.value as Agent["role"]})}>
            <option value="patrol">patrol</option>
            <option value="escort">escort</option>
            <option value="towing">towing</option>
            <option value="police">police</option>
          </select>
          <label>
            <input type="checkbox" checked={form.active} onChange={e=>setForm({...form, active:e.target.checked})}/> Active
          </label>
        </div>
        <button disabled={busy} onClick={onCreate}>{busy?"Saving…":"Create"}</button>
        <button style={{marginLeft:8}} onClick={refresh}>Refresh</button>
      </div>

      <div style={{marginTop:16}}>
        {agents.length===0 ? <p>No agents.</p> : agents.map(a=>(
          <div className="card" key={a.id} style={{marginBottom:8, display:"flex", justifyContent:"space-between"}}>
            <div>
              <b>{a.name}</b> <span className="small">({a.role})</span>
              <div className="small">{a.phone || "—"} · {a.active ? "Active" : "Inactive"}</div>
            </div>
            {a.id && <button onClick={()=>onDelete(a.id!)}>Delete</button>}
          </div>
        ))}
      </div>
    </div>
  );
}
