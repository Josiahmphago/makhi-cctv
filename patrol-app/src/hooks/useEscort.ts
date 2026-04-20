import { db } from "../lib/firebase";
import { addDoc, collection, doc, serverTimestamp, updateDoc } from "firebase/firestore";
import type { EscortRequest, EscortStatus } from "../type";

export async function createEscort(payload: Omit<EscortRequest,"id"|"createdAt"|"status">) {
  await addDoc(collection(db, "escort_requests"), {
    ...payload,
    status: "open",
    createdAt: serverTimestamp(),
  });
}

export async function updateEscortStatus(id: string, status: EscortStatus, assignedPatrolId?: string) {
  await updateDoc(doc(db, "escort_requests", id), { status, assignedPatrolId: assignedPatrolId ?? null });
}
