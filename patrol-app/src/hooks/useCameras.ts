import { useEffect, useMemo, useState } from "react";
import {
  addDoc,
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  updateDoc,
  where,
  FirestoreError,
} from "firebase/firestore";
import { db } from "../lib/firebase";

export type CctvCamera = {
  id: string;
  name: string;
  status?: "Active" | "Inactive";
  teamId?: string;
  location?: string;

  // Networking/stream fields
  ip?: string;
  streamUrl?: string;

  // Optional aliases some components referenced earlier
  ipAddress?: string;   // alias for ip when coming from legacy docs
  snapshotUrl?: string; // direct still endpoint if present
};

export type UseCamerasResult = {
  cameras: CctvCamera[];
  loading: boolean;
  error: string | null;
  createCamera: (seed?: Partial<CctvCamera>) => Promise<string>;
  updateCamera: (id: string, patch: Partial<CctvCamera>) => Promise<void>;
};

/**
 * Subscribe to CCTV cameras. Optionally filter by patrol team id.
 */
export function useCameras(teamId?: string): UseCamerasResult {
  const [cameras, setCameras] = useState<CctvCamera[]>([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);

  const q = useMemo(() => {
    const base = collection(db, "cctv_cameras");
    const parts = [];
    if (teamId && teamId.trim().length > 0) parts.push(where("teamId", "==", teamId));
    parts.push(orderBy("name"));
    return query(base, ...parts);
  }, [teamId]);

  useEffect(() => {
    setLoading(true);
    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows = snap.docs.map((d) => {
          const data = d.data() as any;
          const cam: CctvCamera = {
            id: d.id,
            name: data.name ?? "camera",
            status: data.status ?? "Active",
            teamId: data.teamId,
            location: data.location,
            ip: data.ip ?? data.ipAddress ?? undefined,
            ipAddress: data.ipAddress, // keep alias if stored
            streamUrl: data.streamUrl,
            snapshotUrl: data.snapshotUrl,
          };
        return cam;
        });
        setCameras(rows);
        setErr(null);
        setLoading(false);
      },
      (e: FirestoreError) => {
        setErr(e.message);
        setLoading(false);
      }
    );
    return () => unsub();
  }, [q]);

  const createCamera = async (seed?: Partial<CctvCamera>) => {
    const docRef = await addDoc(collection(db, "cctv_cameras"), {
      name: seed?.name ?? "cam_block_f_street_1",
      status: seed?.status ?? "Active",
      teamId: seed?.teamId ?? "",
      location: seed?.location ?? "",
      ip: seed?.ip ?? "",
      streamUrl: seed?.streamUrl ?? "",
      ipAddress: seed?.ipAddress ?? undefined,
      snapshotUrl: seed?.snapshotUrl ?? undefined,
      createdAt: Date.now(),
    });
    return docRef.id;
  };

  const updateCamera = async (id: string, patch: Partial<CctvCamera>) => {
    await updateDoc(doc(db, "cctv_cameras", id), patch as any);
  };

  return {
    cameras,
    loading,
    error: err,
    createCamera,
    updateCamera,
  };
}
