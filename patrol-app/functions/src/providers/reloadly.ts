// functions/src/providers/reloadly.ts
// Node 18+ has global fetch – no imports required.

const RELOADLY_AUTH = "https://auth.reloadly.com/oauth/token";
const RELOADLY_TOPUP = "https://topups.reloadly.com/topups";
const RELOADLY_OPERATORS_AUTO = "https://topups.reloadly.com/operators/auto-detect";

export async function getReloadlyToken(): Promise<string> {
  const clientId = process.env.RELOADLY_CLIENT_ID;
  const clientSecret = process.env.RELOADLY_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error("Reloadly credentials missing. Set RELOADLY_CLIENT_ID and RELOADLY_CLIENT_SECRET in .env");
  }

  const body = {
    client_id: clientId,
    client_secret: clientSecret,
    grant_type: "client_credentials",
    audience: "https://topups.reloadly.com",
  };

  const r = await fetch(RELOADLY_AUTH, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!r.ok) {
    const text = await r.text();
    throw new Error(`Reloadly auth failed ${r.status}: ${text}`);
  }
  const json = (await r.json()) as any;
  return json.access_token as string;
}

export async function reloadlyFindOperator(token: string, msisdn: string): Promise<any> {
  const url = `${RELOADLY_OPERATORS_AUTO}?phone=${encodeURIComponent(msisdn)}&includeBundles=true`;
  const r = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/com.reloadly.topups-v1+json",
    },
  });

  if (!r.ok) {
    const text = await r.text();
    throw new Error(`Reloadly operator lookup failed ${r.status}: ${text}`);
  }
  return r.json();
}

export async function reloadlyTopupLocalAmount(
  token: string,
  msisdn: string,
  operatorId: number,
  amountZAR: number
): Promise<any> {
  const body = {
    operatorId,
    amount: amountZAR,
    useLocalAmount: true,
    recipientPhone: { countryCode: "ZA", number: msisdn },
  };

  const r = await fetch(RELOADLY_TOPUP, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      Accept: "application/com.reloadly.topups-v1+json",
    },
    body: JSON.stringify(body),
  });

  if (!r.ok) {
    const text = await r.text();
    throw new Error(`Reloadly topup failed ${r.status}: ${text}`);
  }
  return r.json();
}
