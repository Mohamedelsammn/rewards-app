-- Prevent a schedule edit from changing the meaning of participation history.
-- Descriptive fields remain editable. This is enforced in Postgres even if a
-- client bypasses the Flutter form. Existing rows and participation data are untouched.
create or replace function public.fn_guard_giveaway_schedule_edit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.start_date is distinct from old.start_date
     or new.starts_at is distinct from old.starts_at
     or new.end_date is distinct from old.end_date
     or new.end_time is distinct from old.end_time
     or new.ends_at is distinct from old.ends_at then
    if old.status in ('active', 'ended')
       or coalesce(old.starts_at, old.start_date::timestamp at time zone 'UTC') <= clock_timestamp()
       or exists (select 1 from public.participations p where p.giveaway_id = old.id)
       or exists (select 1 from public.winners w where w.giveaway_id = old.id) then
      raise exception 'giveaway_schedule_locked' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.fn_guard_giveaway_schedule_edit() from public, anon, authenticated;
create trigger giveaway_schedule_edit_guard
  before update on public.giveaways
  for each row execute function public.fn_guard_giveaway_schedule_edit();
