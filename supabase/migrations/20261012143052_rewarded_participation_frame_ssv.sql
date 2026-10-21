-- Secure, non-transferable participation-number frame entitlement.
-- The AdMob SSV callback is the only path that marks an event verified.
-- Pending rows are initiated by a JWT-authenticated Edge Function.

alter table public.ad_reward_events
  alter column user_id drop not null,
  alter column ad_network_txn_id drop not null;

alter table public.ad_reward_events
  add column auth_uid uuid references auth.users(id) on delete cascade,
  add column reward_item text,
  add column reward_amount integer,
  add constraint ad_reward_events_identity_present
    check (user_id is not null or auth_uid is not null),
  add constraint ad_reward_events_reward_amount_valid
    check (reward_amount is null or reward_amount > 0);

create index ad_reward_events_auth_giveaway_status_idx
  on public.ad_reward_events (auth_uid, giveaway_id, status, created_at desc);

create unique index ad_reward_events_one_pending_per_identity_giveaway
  on public.ad_reward_events (auth_uid, giveaway_id)
  where status = 'pending' and auth_uid is not null;

create unique index participations_reward_event_unique
  on public.participations (ad_reward_event_id)
  where ad_reward_event_id is not null;

-- The existing account-deletion flow removes both a participant and their
-- reward events. Null the optional cosmetic link before deleting an event,
-- so a linked FK can never block account/giveaway cleanup.
alter table public.participations
  drop constraint if exists participations_ad_reward_event_id_fkey;
alter table public.participations
  add constraint participations_ad_reward_event_id_fkey
  foreign key (ad_reward_event_id) references public.ad_reward_events(id) on delete set null;

-- Attach an entitlement only after the SSV handler has verified Google's
-- signature and marked the event verified. This is service-role-only and
-- idempotent, so retries cannot grant another frame.
create or replace function public.fn_attach_verified_reward_frame(p_event_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_event public.ad_reward_events%rowtype;
  v_user_id uuid;
  v_participation public.participations%rowtype;
begin
  select * into v_event
  from public.ad_reward_events
  where id = p_event_id
  for update;

  if not found or v_event.status not in ('verified', 'consumed') then
    return false;
  end if;

  select ud.user_id into v_user_id
  from public.user_devices ud
  where ud.auth_uid = v_event.auth_uid;

  if v_user_id is null then
    return false;
  end if;

  select * into v_participation
  from public.participations p
  where p.giveaway_id = v_event.giveaway_id and p.user_id = v_user_id
  for update;

  if not found then
    return false;
  end if;

  if v_participation.ad_reward_event_id = v_event.id then
    update public.ad_reward_events
    set status = 'consumed', consumed_at = coalesce(consumed_at, now())
    where id = v_event.id;
    return true;
  end if;

  if v_participation.ad_reward_event_id is not null or exists (
    select 1 from public.participations p
    where p.ad_reward_event_id = v_event.id and p.id <> v_participation.id
  ) then
    return false;
  end if;

  update public.participations
  set ad_reward_event_id = v_event.id
  where id = v_participation.id and ad_reward_event_id is null;

  if not found then
    return false;
  end if;

  update public.ad_reward_events
  set status = 'consumed', consumed_at = coalesce(consumed_at, now())
  where id = v_event.id;

  return true;
end;
$$;

revoke all on function public.fn_attach_verified_reward_frame(uuid) from public, anon, authenticated;
grant execute on function public.fn_attach_verified_reward_frame(uuid) to service_role;

-- Participation may be created before Google's asynchronous SSV callback.
-- This trigger catches that order; the SSV handler calls the same idempotent
-- attachment RPC if the participation already exists.
create or replace function public.fn_attach_verified_reward_frame_after_participation()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_event_id uuid;
begin
  select e.id into v_event_id
  from public.ad_reward_events e
  join public.user_devices ud on ud.auth_uid = e.auth_uid
  where ud.user_id = new.user_id
    and e.giveaway_id = new.giveaway_id
    and e.status = 'verified'
  order by e.verified_at desc nulls last, e.created_at desc
  limit 1;

  if v_event_id is not null then
    perform public.fn_attach_verified_reward_frame(v_event_id);
  end if;
  return new;
end;
$$;

revoke all on function public.fn_attach_verified_reward_frame_after_participation() from public, anon, authenticated;

create trigger participations_attach_verified_reward_frame
after insert on public.participations
for each row execute function public.fn_attach_verified_reward_frame_after_participation();
