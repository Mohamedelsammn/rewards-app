import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// AdMob's SSV `ad_unit` query parameter contains the numeric ad-unit ID,
// rather than the full `ca-app-pub-.../...` SDK identifier.
const EXPECTED_AD_UNIT = '6209750271';
const EXPECTED_REWARD_ITEM = 'participation_frame';
const MAX_CALLBACK_AGE_MS = 24 * 60 * 60 * 1000;
type GoogleKey = { keyId: number; pem: string };
let cachedKeys: { expiresAt: number; keys: GoogleKey[] } | undefined;

function decodeBase64Url(value: string): Uint8Array {
  const normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  const binary = atob(normalized + '='.repeat((4 - normalized.length % 4) % 4));
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

// WebCrypto ECDSA uses the IEEE P1363 r||s representation. AdMob's
// signature parameter is ASN.1 DER, so convert the two integers explicitly.
function derEcdsaToP1363(der: Uint8Array): Uint8Array {
  if (der[0] !== 0x30) throw new Error('Invalid ECDSA signature');
  let offset = 2;
  if (der[1] & 0x80) offset = 2 + (der[1] & 0x7f);
  if (der[offset] !== 0x02) throw new Error('Invalid ECDSA r');
  const rLength = der[offset + 1];
  const r = der.slice(offset + 2, offset + 2 + rLength);
  offset += 2 + rLength;
  if (der[offset] !== 0x02) throw new Error('Invalid ECDSA s');
  const sLength = der[offset + 1];
  const s = der.slice(offset + 2, offset + 2 + sLength);
  const raw = new Uint8Array(64);
  raw.set(r.slice(Math.max(0, r.length - 32)), 32 - Math.min(32, r.length));
  raw.set(s.slice(Math.max(0, s.length - 32)), 64 - Math.min(32, s.length));
  return raw;
}

async function googleKeys(): Promise<GoogleKey[]> {
  if (cachedKeys && Date.now() < cachedKeys.expiresAt) return cachedKeys.keys;
  const response = await fetch('https://www.gstatic.com/admob/reward/verifier-keys.json');
  if (!response.ok) throw new Error('Could not load AdMob verification keys');
  const body = await response.json();
  if (!Array.isArray(body.keys)) throw new Error('Invalid AdMob key response');
  const keys = body.keys as GoogleKey[];
  cachedKeys = { keys, expiresAt: Date.now() + 24 * 60 * 60 * 1000 };
  return keys;
}

function pemBytes(pem: string): Uint8Array {
  const base64 = pem.replace(/-----BEGIN PUBLIC KEY-----|-----END PUBLIC KEY-----|\s/g, '');
  return Uint8Array.from(atob(base64), (character) => character.charCodeAt(0));
}

async function verifySignature(rawQuery: string, signature: string, keyId: number): Promise<boolean> {
  const keyInfo = (await googleKeys()).find((key) => key.keyId === keyId);
  if (!keyInfo) return false;
  const key = await crypto.subtle.importKey(
    'spki', pemBytes(keyInfo.pem), { name: 'ECDSA', namedCurve: 'P-256' }, false, ['verify'],
  );
  const der = decodeBase64Url(signature);
  return await crypto.subtle.verify(
    { name: 'ECDSA', hash: 'SHA-256' }, key, derEcdsaToP1363(der), new TextEncoder().encode(rawQuery),
  );
}

Deno.serve(async (request) => {
  if (request.method !== 'GET') return new Response('Method not allowed', { status: 405 });
  const rawQuery = new URL(request.url).search.slice(1);
  const signatureAt = rawQuery.lastIndexOf('&signature=');
  if (signatureAt < 0 || signatureAt + 10 >= rawQuery.length) return new Response('Invalid callback', { status: 400 });
  const signedQuery = rawQuery.slice(0, signatureAt);
  const params = new URLSearchParams(rawQuery);
  const signature = params.get('signature') ?? '';
  const keyId = Number(params.get('key_id'));
  try {
    if (!Number.isInteger(keyId) || !(await verifySignature(signedQuery, signature, keyId))) {
      return new Response('Invalid signature', { status: 401 });
    }
  } catch (_) {
    return new Response('Signature verification unavailable', { status: 503 });
  }

  const transactionId = params.get('transaction_id') ?? '';
  const authUid = params.get('user_id') ?? '';
  const eventId = params.get('custom_data') ?? '';
  const rewardAmount = Number(params.get('reward_amount'));
  const rewardItem = params.get('reward_item') ?? '';
  const adUnit = params.get('ad_unit') ?? '';
  const timestamp = Number(params.get('timestamp'));
  if (!transactionId || !/^[0-9a-f-]{36}$/i.test(authUid) || !/^[0-9a-f-]{36}$/i.test(eventId) ||
      rewardAmount !== 1 || rewardItem !== EXPECTED_REWARD_ITEM || adUnit !== EXPECTED_AD_UNIT ||
      !Number.isFinite(timestamp) || Math.abs(Date.now() - timestamp) > MAX_CALLBACK_AGE_MS) {
    return new Response('Invalid reward callback fields', { status: 400 });
  }

  const url = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceKey) return new Response('Server configuration unavailable', { status: 503 });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { data: event, error: readError } = await admin.from('ad_reward_events')
    .select('id,auth_uid,giveaway_id,status,ad_network_txn_id,reward_item,reward_amount')
    .eq('id', eventId).maybeSingle();
  if (readError || !event || event.auth_uid !== authUid || event.reward_item !== rewardItem ||
      event.reward_amount !== rewardAmount) return new Response('Claim mismatch', { status: 403 });
  if (event.status === 'verified' || event.status === 'consumed') {
    if (event.ad_network_txn_id !== transactionId) return new Response('Claim already used', { status: 409 });
    const { error: retryAttachError } = await admin.rpc('fn_attach_verified_reward_frame', { p_event_id: eventId });
    return retryAttachError
      ? new Response('Could not attach verified reward', { status: 503 })
      : new Response('OK', { status: 200 });
  }
  if (event.status !== 'pending') return new Response('Claim unavailable', { status: 409 });

  const { data: changed, error: updateError } = await admin.from('ad_reward_events').update({
    ad_network_txn_id: transactionId,
    status: 'verified',
    verified_at: new Date(timestamp).toISOString(),
  }).eq('id', eventId).eq('status', 'pending').select('id').maybeSingle();
  if (updateError) return new Response('Could not record reward', { status: 503 });
  if (!changed) return new Response('Callback already processed', { status: 200 });
  const { error: attachError } = await admin.rpc('fn_attach_verified_reward_frame', { p_event_id: eventId });
  if (attachError) return new Response('Could not attach verified reward', { status: 503 });
  return new Response('OK', { status: 200 });
});
