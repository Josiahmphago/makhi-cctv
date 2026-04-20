import { db } from "../lib/firebase";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import type { CommunityAlert } from "../type";

export async function sendCommunityAlert(payload: Omit<CommunityAlert,"id"|"createdAt">) {
  await addDoc(collection(db, "community_alerts"), {
    ...payload,
    createdAt: serverTimestamp(),
  });
}
