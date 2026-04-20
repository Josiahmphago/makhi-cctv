import React, { useEffect, useState } from "react";
import {
  collection,
  query,
  orderBy,
  onSnapshot,
  addDoc,
  updateDoc,
  doc,
  serverTimestamp,
} from "firebase/firestore";

// ⚠️ UPDATE THIS IMPORT PATH ⚠️
// Change "../firebase" to whatever file in *your* app exports `db` (Firestore instance).
// Examples in your project might be: "../firebaseClient", "../config/firebase", etc.
import { db } from "../firebase"; 

type PatrolAgent = {
  id: string;
  name: string;
  phone?: string;
  role?: string;
  zone?: string;
  onDuty: boolean;
  notes?: string;
};

const PatrolAgentsPanel: React.FC = () => {
  const [agents, setAgents] = useState<PatrolAgent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [newName, setNewName] = useState("");
  const [newPhone, setNewPhone] = useState("");
  const [newZone, setNewZone] = useState("");
  const [newRole, setNewRole] = useState("patrol");

  useEffect(() => {
    const q = query(collection(db, "patrolAgents"), orderBy("name"));

    const unsubscribe = onSnapshot(
      q,
      (snap) => {
        const list: PatrolAgent[] = snap.docs.map((d) => {
          const data = d.data() as any;
          return {
            id: d.id,
            name: data.name ?? "Unknown",
            phone: data.phone,
            role: data.role,
            zone: data.zone,
            onDuty: !!data.onDuty,
            notes: data.notes,
          };
        });
        setAgents(list);
        setLoading(false);
      },
      (err) => {
        console.error(err);
        setError(err.message || "Failed to load patrol agents");
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  const handleAddAgent = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;

    try {
      await addDoc(collection(db, "patrolAgents"), {
        name: newName.trim(),
        phone: newPhone.trim() || null,
        role: newRole || "patrol",
        zone: newZone.trim() || null,
        onDuty: false, // new agents start off-duty
        notes: null,
        lastStatusChange: serverTimestamp(),
      });

      setNewName("");
      setNewPhone("");
      setNewZone("");
      setNewRole("patrol");
    } catch (err: any) {
      console.error(err);
      setError(err.message || "Failed to add agent");
    }
  };

  const toggleOnDuty = async (agent: PatrolAgent) => {
    try {
      await updateDoc(doc(db, "patrolAgents", agent.id), {
        onDuty: !agent.onDuty,
        lastStatusChange: serverTimestamp(),
      });
    } catch (err: any) {
      console.error(err);
      setError(err.message || "Failed to update duty status");
    }
  };

  if (loading) {
    return <div>Loading patrol agents…</div>;
  }

  return (
    <div style={{ padding: "1rem", maxWidth: 900, margin: "0 auto" }}>
      <h2 style={{ marginBottom: "1rem" }}>Patrol Agents</h2>

      {error && (
        <div
          style={{
            marginBottom: "1rem",
            padding: "0.75rem",
            background: "#ffe5e5",
            borderRadius: 8,
            fontSize: 14,
          }}
        >
          {error}
        </div>
      )}

      {/* Add new agent form */}
      <form
        onSubmit={handleAddAgent}
        style={{
          display: "grid",
          gridTemplateColumns: "2fr 1.5fr 1fr 1fr auto",
          gap: "0.5rem",
          marginBottom: "1rem",
          alignItems: "center",
        }}
      >
        <input
          placeholder="Name (required)"
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
        />
        <input
          placeholder="Phone (optional)"
          value={newPhone}
          onChange={(e) => setNewPhone(e.target.value)}
        />
        <input
          placeholder="Zone (e.g. Block A)"
          value={newZone}
          onChange={(e) => setNewZone(e.target.value)}
        />
        <select
          value={newRole}
          onChange={(e) => setNewRole(e.target.value)}
        >
          <option value="patrol">Patrol</option>
          <option value="police">Police</option>
          <option value="community">Community</option>
        </select>
        <button type="submit">Add</button>
      </form>

      {/* Agents list */}
      {agents.length === 0 ? (
        <div>No patrol agents found yet. Add one above.</div>
      ) : (
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr>
              <th align="left">Name</th>
              <th align="left">Phone</th>
              <th align="left">Role</th>
              <th align="left">Zone</th>
              <th align="left">On Duty</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {agents.map((a) => (
              <tr key={a.id} style={{ borderTop: "1px solid #eee" }}>
                <td>{a.name}</td>
                <td>{a.phone || "-"}</td>
                <td>{a.role || "-"}</td>
                <td>{a.zone || "-"}</td>
                <td>{a.onDuty ? "✅ Yes" : "❌ No"}</td>
                <td>
                  <button type="button" onClick={() => toggleOnDuty(a)}>
                    {a.onDuty ? "Set Off Duty" : "Set On Duty"}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default PatrolAgentsPanel;
