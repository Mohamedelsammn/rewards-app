-- Manual verification script for fn_delete_own_account
-- (supabase/migrations/20260813120000_add_account_deletion_function.sql).
--
-- NOT EXECUTED THIS SESSION -- the Supabase MCP database connection was
-- unavailable, so none of this has been run against the real project yet.
-- Run it yourself (Supabase SQL editor / psql) after applying the
-- migration, or hand it to me once the connection is back. It mirrors the
-- exact pattern already used successfully earlier in this project to test
-- fn_admin_delete_giveaway: `set local request.jwt.claim.sub = '<uuid>'`
-- makes auth.uid() resolve to a chosen identity for one statement/session,
-- without needing a real JWT.
--
-- Each numbered block is one scenario from Phase 5 of the task. Run blocks
-- 0 through 8 in order in a single session; block 9 is a standalone,
-- independent check.

-- =============================================================================
-- 0. SETUP -- one throwaway giveaway owned by a real admin, two test
--    participants (User A, User B), User A wins.
-- =============================================================================
-- Replace :admin_id with a real admin_users.id from your project
-- (select id, email from admin_users;).

begin;

insert into public.giveaways
  (id, title, organizer_name, prize_description, description_rules, start_date, end_date, end_time, status, number_digit_width, created_by)
values
  ('22222222-2222-2222-2222-222222222222', 'ACCOUNT DELETION TEST GIVEAWAY', 'QA', 'Test Prize', 'Test rules',
   current_date, current_date + 30, '18:00', 'active', 4, :'admin_id');

insert into public.users (id, full_name, phone_e164, country_code)
values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Test User A', '+201000000901', 'EG'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'Test User B', '+201000000902', 'EG');

-- auth.users + user_devices rows the deletion function actually reads.
-- auth_uid values below are what request.jwt.claim.sub is set to further down.
insert into auth.users (id, instance_id, aud, role, is_anonymous, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('cccccccc-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', true, now(), now(), '{}', '{}'),
  ('dddddddd-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', true, now(), now(), '{}', '{}');

insert into public.user_devices (id, user_id, auth_uid)
values
  (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001', 'cccccccc-0000-0000-0000-000000000003'),
  (gen_random_uuid(), 'bbbbbbbb-0000-0000-0000-000000000002', 'dddddddd-0000-0000-0000-000000000004');

do $$
declare
  v_giveaway_id constant uuid := '22222222-2222-2222-2222-222222222222';
  v_seq bigint;
  v_num int;
  v_pA uuid;
  v_pB uuid;
begin
  v_seq := public.fn_next_participation_sequence(v_giveaway_id);
  v_num := public.fn_allocate_participation_number(v_giveaway_id);
  insert into public.participations (id, giveaway_id, user_id, participation_sequence, participation_number)
  values (gen_random_uuid(), v_giveaway_id, 'aaaaaaaa-0000-0000-0000-000000000001', v_seq, v_num)
  returning id into v_pA;

  v_seq := public.fn_next_participation_sequence(v_giveaway_id);
  v_num := public.fn_allocate_participation_number(v_giveaway_id);
  insert into public.participations (id, giveaway_id, user_id, participation_sequence, participation_number)
  values (gen_random_uuid(), v_giveaway_id, 'bbbbbbbb-0000-0000-0000-000000000002', v_seq, v_num)
  returning id into v_pB;

  -- User A wins -- exercises the winners.participation_id NO ACTION path.
  insert into public.winners (giveaway_id, participation_id, rank, selected_by)
  values (v_giveaway_id, v_pA, 1, :'admin_id');

  insert into public.notifications (user_id, type, title, body, data)
  values ('aaaaaaaa-0000-0000-0000-000000000001', 'winner_announcement', 'Congratulations!', 'You won!',
          jsonb_build_object('giveawayId', v_giveaway_id, 'winnerId', gen_random_uuid()));
end $$;

commit;

-- Sanity check on the seeded state before deleting anything.
select 'before: participant_count' as check, participant_count::text as value
from public.giveaways where id = '22222222-2222-2222-2222-222222222222';
select 'before: pool used count' as check, count(*)::text as value
from public.participation_number_pool
where giveaway_id = '22222222-2222-2222-2222-222222222222' and is_used = true;

-- =============================================================================
-- 1 & 2. User A can delete User A's account; User B's data must be untouched.
-- =============================================================================

set local request.jwt.claim.sub = 'cccccccc-0000-0000-0000-000000000003'; -- User A's auth_uid
select public.fn_delete_own_account();

-- =============================================================================
-- 3-5. Verify User A's data is gone, User B's is not.
-- =============================================================================

select 'User A users row (expect 0)' as check, count(*)::text as value
from public.users where id = 'aaaaaaaa-0000-0000-0000-000000000001';

select 'User A auth.users row (expect 0)' as check, count(*)::text as value
from auth.users where id = 'cccccccc-0000-0000-0000-000000000003';

select 'User A user_devices row (expect 0)' as check, count(*)::text as value
from public.user_devices where user_id = 'aaaaaaaa-0000-0000-0000-000000000001';

select 'User A participations (expect 0)' as check, count(*)::text as value
from public.participations where user_id = 'aaaaaaaa-0000-0000-0000-000000000001';

select 'User A winner record (expect 0 -- deleted, since it was personal to the deleted entry)' as check, count(*)::text as value
from public.winners w
join public.participations p on p.id = w.participation_id
where p.user_id = 'aaaaaaaa-0000-0000-0000-000000000001';

select 'User A notifications (expect 0)' as check, count(*)::text as value
from public.notifications where user_id = 'aaaaaaaa-0000-0000-0000-000000000001';

-- unrelated User B (expect all still present -- 1 each)
select 'User B users row (expect 1)' as check, count(*)::text as value
from public.users where id = 'bbbbbbbb-0000-0000-0000-000000000002';
select 'User B participations (expect 1)' as check, count(*)::text as value
from public.participations where user_id = 'bbbbbbbb-0000-0000-0000-000000000002';
select 'User B auth.users row (expect 1)' as check, count(*)::text as value
from auth.users where id = 'dddddddd-0000-0000-0000-000000000004';

-- bookkeeping: participant_count decremented, pool slot freed.
select 'giveaway participant_count (expect 1, down from 2)' as check, participant_count::text as value
from public.giveaways where id = '22222222-2222-2222-2222-222222222222';
select 'pool used count (expect 1, down from 2)' as check, count(*)::text as value
from public.participation_number_pool
where giveaway_id = '22222222-2222-2222-2222-222222222222' and is_used = true;

-- =============================================================================
-- 2 (negative). User B must NOT be able to delete User A's account by
-- calling the function while authenticated as someone else -- there is no
-- parameter to even attempt this with (no client-supplied id accepted at
-- all), so this just confirms User B deleting themselves only ever affects
-- User B.
-- =============================================================================

set local request.jwt.claim.sub = 'dddddddd-0000-0000-0000-000000000004'; -- User B's auth_uid
select public.fn_delete_own_account();

select 'User B users row (expect 0 now)' as check, count(*)::text as value
from public.users where id = 'bbbbbbbb-0000-0000-0000-000000000002';

-- =============================================================================
-- 8. Unrelated giveaway (and this test giveaway's own row) must remain --
-- account deletion must never delete a giveaway.
-- =============================================================================

select 'test giveaway itself still exists (expect 1)' as check, count(*)::text as value
from public.giveaways where id = '22222222-2222-2222-2222-222222222222';

-- =============================================================================
-- 9 (independent). A caller with no linked user_devices row (e.g. an admin,
-- or a brand-new anonymous session) must be rejected, not silently succeed.
-- =============================================================================

set local request.jwt.claim.sub = :'admin_id';
-- Expected: ERROR: identity_not_linked (SQLSTATE P4001). If this instead
-- succeeds or deletes anything, STOP -- that is a real bug.
select public.fn_delete_own_account();

-- =============================================================================
-- CLEANUP -- remove the test giveaway and its now-empty child rows.
-- =============================================================================
delete from public.giveaways where id = '22222222-2222-2222-2222-222222222222';
