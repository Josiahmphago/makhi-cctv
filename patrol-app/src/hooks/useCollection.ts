import { useEffect, useState } from "react";
import {
  collection, onSnapshot, orderBy, query, where as fbWhere, limit as fbLimit,
  type FirestoreError, type WhereFilterOp,
} from "firebase/firestore";
import { db } from "../lib/firebase";

type OrderBy = [string, "asc" | "desc"] | [string];
type Where = [string, WhereFilterOp, any];

export function useCollection<T = any>(
  coll: string,
  opts?: { where?: Where[]; orderBy?: OrderBy; limit?: number }
) {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string|null>(null);

  useEffect(() => {
    if (!db) { setLoading(false); return; }
    setLoading(true); setError(null);

    const col = collection(db, coll);
    const constraints: any[] = [];
    if (opts?.where?.length) opts.where.forEach(w => constraints.push(fbWhere(w[0], w[1], w[2])));
    if (opts?.orderBy) { const o = opts.orderBy; constraints.push(orderBy(o[0], (o[1] as any) || "asc")); }
    if (typeof opts?.limit === "number") constraints.push(fbLimit(opts.limit));

    const q = constraints.length ? query(col, ...constraints) : query(col);

    const unsub = onSnapshot(q, (snap) => {
      const rows = snap.docs.map(d => ({ id: d.id, ...d.data() } as T));
      setData(rows); setLoading(false);
    }, (err: FirestoreError) => {
      setError(err.message || String(err)); setLoading(false);
    });

    return () => unsub();
  }, [coll, JSON.stringify(opts || {})]);

  return { data, loading, error };
}
