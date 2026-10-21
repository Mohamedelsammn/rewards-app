import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (request.method !== 'POST') return reply({ code: 'method_not_allowed' }, 405);
  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) return reply({ code: 'unauthorized' }, 401);
  const url = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !anonKey || !serviceKey) return reply({ code: 'server_configuration' }, 500);

  const caller = createClient(url, anonKey, { global: { headers: { Authorization: authorization } } });
  const { data: authData, error: authError } = await caller.auth.getUser();
  if (authError || !authData.user) return reply({ code: 'unauthorized' }, 401);
  const body = await request.json().catch(() => null);
  const giveawayId = typeof body?.giveawayId === 'string' ? body.giveawayId : '';
  if (!/^[0-9a-f-]{36}$/i.test(giveawayId)) return reply({ code: 'invalid_giveaway' }, 400);

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { data: allowed } = await admin.rpc('fn_check_rate_limit', {
    p_bucket_key: `reward-frame:${authData.user.id}`,
    p_max_hits: 5,
    p_window_seconds: 60,
  });
  if (allowed !== true) return reply({ code: 'rate_limited' }, 429);
  const { data: adminAccount } = await admin.from('admin_users').select('id')
    .eq('id', authData.user.id).maybeSingle();
  if (adminAccount) return reply({ code: 'not_participant' }, 403);
  const { data: giveaway, error: giveawayError } = await admin
    .from('giveaways').select('id,status,starts_at,ends_at,start_date,end_date,end_time')
    .eq('id', giveawayId).maybeSingle();
  if (giveawayError || !giveaway) return reply({ code: 'giveaway_not_found' }, 404);
  const now = Date.now();
  const start = Date.parse(giveaway.starts_at ?? `${giveaway.start_date}T00:00:00Z`);
  const end = Date.parse(giveaway.ends_at ?? `${giveaway.end_date}T${giveaway.end_time}Z`);
  if (giveaway.status !== 'active' || !Number.isFinite(start) || !Number.isFinite(end) || now < start || now >= end) {
    return reply({ code: 'giveaway_not_joinable' }, 409);
  }

  const { data: device } = await admin.from('user_devices').select('user_id').eq('auth_uid', authData.user.id).maybeSingle();
  if (!device?.user_id) return reply({ code: 'identity_not_linked' }, 401);
  const { data: alreadyJoined } = await admin.from('participations').select('id')
    .eq('giveaway_id', giveawayId).eq('user_id', device.user_id).maybeSingle();
  if (alreadyJoined) return reply({ code: 'already_participated' }, 409);
  const { data: existing } = await admin.from('ad_reward_events').select('id')
    .eq('auth_uid', authData.user.id).eq('giveaway_id', giveawayId).eq('status', 'pending')
    .order('created_at', { ascending: false }).limit(1).maybeSingle();
  if (existing) return reply({ eventId: existing.id });

  const { data: event, error } = await admin.from('ad_reward_events').insert({
    auth_uid: authData.user.id,
    user_id: device.user_id,
    giveaway_id: giveawayId,
    status: 'pending',
    reward_item: 'participation_frame',
    reward_amount: 1,
  }).select('id').single();
  if (error || !event) return reply({ code: 'claim_unavailable' }, 503);
  return reply({ eventId: event.id });
});
