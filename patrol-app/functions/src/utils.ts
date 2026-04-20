// functions/src/utils.ts

/**
 * Very light input cleaner so Firestore doesn't reject undefined values.
 */
export function cleanForFirestore<T extends Record<string, any>>(obj: T): T {
  const out: Record<string, any> = {};
  Object.keys(obj).forEach((k) => {
    const v = (obj as any)[k];
    if (v !== undefined) out[k] = v;
  });
  return out as T;
}

/**
 * Normalize ZA MSISDN:
 * - Strip non-digits
 * - If starts with 0, convert to 27xxxxxxxxx
 * - If already 27..., keep it
 * - If 9 digits (no leading 0), assume 27 + that
 */
export function normalizeMsisdn(input: string): string {
  const digits = (input || "").replace(/\D+/g, "");
  if (!digits) return "";
  if (digits.startsWith("27")) return digits;
  if (digits.startsWith("0") && digits.length === 10) return `27${digits.slice(1)}`;
  if (digits.length === 9) return `27${digits}`; // fallback
  return digits;
}

/**
 * Naive operator guess based on ZA prefixes.
 * (You can refine this, or skip when using Reloadly lookup.)
 */
export function guessOperator(msisdn: string): string | null {
  // Basic patterns—improve later if needed
  const p = msisdn.replace(/\D+/g, "");
  if (!p.startsWith("27")) return null;

  // Example prefixes (Vodacom/MTN/Cell C/Telkom)
  if (/^27(60|61|71|72|76|79|82|83)\d{7}$/.test(p)) return "Vodacom?";
  if (/^27(63|64|73|78)\d{7}$/.test(p)) return "MTN?";
  if (/^27(84|74|84)\d{7}$/.test(p)) return "Cell C?";
  if (/^27(81)\d{7}$/.test(p)) return "Telkom?";
  return null;
}
