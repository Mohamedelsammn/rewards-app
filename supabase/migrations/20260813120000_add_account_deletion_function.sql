-- Self-service account deletion (Google Play "account deletion" compliance
-- pass) for the anonymous, device-scoped participant identity model used by
-- this app's regular (non-admin) users.
--
-- IMPORTANT -- APPLY THIS FILE MANUALLY: it was written and reviewed without
-- live access to the Supabase project (the MCP database connection was
-- unavailable this session). Apply it via the Supabase SQL editor, or
-- `supabase db push` / `psql`, then re-run this migration's paired
-- verification script (supabase/verification/account_deletion_checks.sql)
-- against the real project before relying on it in production.
--
-- ---------------------------------------------------------------------------
-- Dependency map (public schema; grounded in this project's actual schema,
-- inspected directly via prior execute_sql/list_tables calls this session --
-- not guessed):
--
--   auth.users (id)
--     <-- admin_users.id                              ON DELETE CASCADE
--     <-- user_devices.auth_uid                        ON DELETE CASCADE
--     <-- auth.identities.user_id                       ON DELETE CASCADE
--     <-- auth.sessions.user_id                          ON DELETE CASCADE
--     <-- auth.mfa_factors.user_id                        ON DELETE CASCADE
--     <-- auth.one_time_tokens.user_id                     ON DELETE CASCADE
--     <-- auth.oauth_authorizations.user_id                 ON DELETE CASCADE
--     <-- auth.oauth_consents.user_id                        ON DELETE CASCADE
--     <-- auth.webauthn_credentials.user_id                   ON DELETE CASCADE
--     <-- auth.webauthn_challenges.user_id                     ON DELETE CASCADE
--
--   public.users (id)  -- NOT linked to auth.users by any FK; the link is
--                          indirect, via user_devices.auth_uid -> users.user_id
--     <-- user_devices.user_id          ON DELETE CASCADE
--     <-- participations.user_id        ON DELETE CASCADE
--     <-- notifications.user_id         ON DELETE CASCADE
--     <-- ad_reward_events.user_id      ON DELETE CASCADE
--
--   public.participations (id)
--     <-- winners.participation_id      ON DELETE NO ACTION  *** the one gap
--         a raw cascade would trip over: a participation the caller WON
--         cannot be deleted while a winners row still references it, so
--         this function deletes the winners row first, explicitly.
--
--   Two things the schema does NOT handle automatically on delete, so this
--   function does them explicitly:
--     - giveaways.participant_count only has an INSERT trigger
--       (fn_trg_maintain_participant_count); nothing decrements it when a
--       participation is removed.
--     - participation_number_pool.is_used / assigned_participation_id have
--       no FK to participations at all (plain columns) -- a freed number
--       must be explicitly returned to the pool or it is lost forever for
--       that giveaway.
--
--   admin_users / giveaways.created_by / winners.selected_by are never
--   touched by this function -- it only ever resolves auth.uid() to a
--   user_devices row, which admin identities never have (admins have no
--   user_devices row at all), so an admin calling this gets
--   'identity_not_linked' and nothing is deleted. Admin account deletion is
--   a distinct, not-yet-defined product flow (an admin's giveaways involve
--   OTHER users' participations/winners, which must never be deleted as a
--   side effect of one admin's own account going away) and is deliberately
--   out of scope here.
-- ---------------------------------------------------------------------------

create or replace function public.fn_delete_own_account()
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid;
  v_participation record;
begin
  -- Authorization is derived ENTIRELY from auth.uid() -- never a
  -- client-supplied id. If this session isn't linked to a participant
  -- identity (e.g. it's an admin session, or a brand-new anonymous session
  -- that never registered), there is nothing of this kind to delete.
  select ud.user_id into v_user_id
  from public.user_devices ud
  where ud.auth_uid = auth.uid();

  if v_user_id is null then
    raise exception 'identity_not_linked' using errcode = 'P4001';
  end if;

  -- Must precede the participations delete below: winners.participation_id
  -- is ON DELETE NO ACTION, so a stale winner row referencing this user's
  -- entry would otherwise block the cascade from public.users.
  delete from public.winners
  where participation_id in (
    select id from public.participations where user_id = v_user_id
  );

  -- Bookkeeping the schema doesn't handle automatically (see header
  -- comment) -- done before the cascading delete below, while these rows
  -- still exist to read.
  for v_participation in
    select giveaway_id, participation_number
    from public.participations
    where user_id = v_user_id
  loop
    update public.giveaways
    set participant_count = greatest(participant_count - 1, 0)
    where id = v_participation.giveaway_id;

    update public.participation_number_pool
    set is_used = false, assigned_participation_id = null
    where giveaway_id = v_participation.giveaway_id
      and number = v_participation.participation_number;
  end loop;

  -- Cascades to user_devices, participations, notifications, and
  -- ad_reward_events for this user (all ON DELETE CASCADE from users.id --
  -- see dependency map above). This is the participant's application data.
  delete from public.users where id = v_user_id;

  -- Cascades through the auth.* tables listed above, and (redundantly,
  -- harmlessly -- already removed by the users cascade just above)
  -- user_devices.auth_uid. This revokes the identity/session itself.
  delete from auth.users where id = auth.uid();
end;
$$;

-- Explicit grant so this is reachable via supabase.rpc() from an
-- authenticated (non-service-role) client regardless of default
-- privileges -- the function's own internal auth.uid() resolution is the
-- real authorization boundary, this grant only controls reachability.
-- Matches the exact same pattern already used for fn_admin_delete_giveaway.
grant execute on function public.fn_delete_own_account() to authenticated;
