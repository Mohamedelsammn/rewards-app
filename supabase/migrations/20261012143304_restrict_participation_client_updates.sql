-- Participation numbers and reward-event links are server-owned fields.
-- Clients only need to write the existing "number revealed" timestamp.
revoke update on table public.participations from anon, authenticated;
grant update (scratch_revealed_at) on table public.participations to authenticated;
