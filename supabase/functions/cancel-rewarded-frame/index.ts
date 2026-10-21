import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: cors });
  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) return new Response('Unauthorized', { status: 401, headers: cors });
  const url = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const caller = createClient(url, anonKey, { global: { headers: { Authorization: authorization } } });
  const { data } = await caller.auth.getUser();
  if (!data.user) return new Response('Unauthorized', { status: 401, headers: cors });
  const body = await request.json().catch(() => null);
  const eventId = typeof body?.eventId === 'string' ? body.eventId : '';
  if (!/^[0-9a-f-]{36}$/i.test(eventId)) return new Response('Invalid claim', { status: 400, headers: cors });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  await admin.from('ad_reward_events').update({ status: 'invalid' })
    .eq('id', eventId).eq('auth_uid', data.user.id).eq('status', 'pending');
  return new Response(JSON.stringify({ cancelled: true }), {
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
});
