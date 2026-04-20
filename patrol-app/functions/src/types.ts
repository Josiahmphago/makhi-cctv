import type { FieldValue, Timestamp } from "firebase-admin/firestore";

export type TopupStatus = "initiated" | "paid" | "fulfilled" | "failed";

// functions/src/types.ts

export interface TopupDoc {
  uid: string;
  msisdn: string;            // normalized E.164 or ZA local without spaces
  operator?: string | null;  // guessed or detected operator
  bundle?: string | null;    // optional bundle name/code
  amountZAR: number;
  provider: "Reloadly";
  status: "initiated" | "paid" | "fulfilled" | "failed";
  webhookStatus?: string;
  providerRef?: string;
  createdAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  fulfilledAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
}

