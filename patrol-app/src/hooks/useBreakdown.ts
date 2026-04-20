import { db } from "../lib/firebase";
import { addDoc, collection, doc, serverTimestamp, updateDoc } from "firebase/firestore";
import type { BreakdownRequest, BreakdownStatus } from "../type";

export async function createBreakdown(payload: Omit<BreakdownRequest,"id"|"createdAt"|"status">) {
  await addDoc(collection(db, "breakdown_requests"), {
    ...payload,
    status: "open",
    createdAt: serverTimestamp(),
  });
}

export async function updateBreakdownStatus(id: string, status: BreakdownStatus, assignedTowId?: string) {
  await updateDoc(doc(db, "breakdown_requests", id), { status, assignedTowId: assignedTowId ?? null });
}
