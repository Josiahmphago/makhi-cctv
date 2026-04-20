import { useEffect, useMemo, useState } from "react";
import { collection, onSnapshot, query, where } from "firebase/firestore";
import { db } from "../lib/firebase";
import type { CameraDoc } from "../types";

export function useCameras(teamId?: string) {
  const [cameras, setCameras] = useState<Array<{ id: string; data: CameraDoc }>>(
    []
  );
  const [loading, setLoading] = useState(true);

  const q = useMemo(() => {
    const col = collection(db, "cctv_cameras");
    return teamId ? query(col, where("patrolTeamId", "==", teamId)) : col;
  }, [teamId]);

  useEffect(() => {
    setLoading(true);
    const unsub = onSnapshot(q, (snap) => {
      const rows = snap.docs.map((d) => ({ id: d.id, data: d.data() as CameraDoc }));
      setCameras(rows);
      setLoading(false);
    });
    return () => unsub();
  }, [q]);

  return { cameras, loading };
}
