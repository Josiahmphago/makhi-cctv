"use strict";
// functions/src/payments.ts
/**
 * Ozow create-checkout stub.
 * In MOCK mode you never hit this (index.ts short-circuits).
 * In real mode, add proper signing + POST to Ozow API here.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.createCheckoutOzow = createCheckoutOzow;
async function createCheckoutOzow(args) {
    const { reference, amountZAR, successUrl, cancelUrl, notifyUrl } = args;
    // Read env (you'll fill real values when leaving mock)
    const siteCode = process.env.OZOW_SITE_CODE;
    const privateKey = process.env.OZOW_PRIVATE_KEY;
    const baseUrl = process.env.OZOW_API_URL || "https://api.ozow.com";
    if (!siteCode || !privateKey) {
        // Keep it explicit why it failed
        throw new Error("Ozow credentials missing. Set OZOW_SITE_CODE and OZOW_PRIVATE_KEY in .env");
    }
    // TODO: Implement Ozow checksum + request here.
    // For now we simulate returning a hosted payment page URL.
    const fakeUrl = `${baseUrl.replace(/\/+$/, "")}/pay/${encodeURIComponent(reference)}?amount=${amountZAR.toFixed(2)}&success=${encodeURIComponent(successUrl)}&cancel=${encodeURIComponent(cancelUrl)}&notify=${encodeURIComponent(notifyUrl)}`;
    return { paymentUrl: fakeUrl };
}
//# sourceMappingURL=payments.js.map