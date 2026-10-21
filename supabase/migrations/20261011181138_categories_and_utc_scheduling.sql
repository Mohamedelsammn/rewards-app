-- Additive rollout. Legacy columns/enum/Edge Function response contracts remain.
-- Existing rows keep nullable UTC fields and use their existing server UTC interpretation.
create table public.giveaway_categories (
  id uuid primary key default gen_random_uuid(),
  name_en text not null check (length(btrim(name_en)) between 1 and 80),
  name_ar text not null check (length(btrim(name_ar)) between 1 and 80),
  icon text check (icon is null or length(icon) <= 16),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.giveaway_categories enable row level security;
revoke all on public.giveaway_categories from anon, authenticated;
grant select on public.giveaway_categories to anon, authenticated;
grant insert, update on public.giveaway_categories to authenticated;
grant all on public.giveaway_categories to service_role;
-- No DELETE grant/policy: disabling preserves references and history.
create policy categories_read on public.giveaway_categories for select to anon, authenticated
 using (is_active or exists (select 1 from public.admin_users a where a.id = (select auth.uid()) and a.role = 'super_admin'));
create policy categories_create on public.giveaway_categories for insert to authenticated
 with check (exists (select 1 from public.admin_users a where a.id = (select auth.uid()) and a.role = 'super_admin'));
create policy categories_update on public.giveaway_categories for update to authenticated
 using (exists (select 1 from public.admin_users a where a.id = (select auth.uid()) and a.role = 'super_admin'))
 with check (exists (select 1 from public.admin_users a where a.id = (select auth.uid()) and a.role = 'super_admin'));
create trigger categories_updated_at before update on public.giveaway_categories
 for each row execute function public.fn_trg_set_updated_at();
create index categories_active_order_idx on public.giveaway_categories (sort_order, id) where is_active;

alter table public.giveaways
 add column category_id uuid references public.giveaway_categories(id) on delete restrict,
 add column starts_at timestamptz,
 add column ends_at timestamptz,
 add constraint giveaway_utc_interval check (starts_at is null or ends_at is null or ends_at > starts_at) not valid;
create index giveaways_category_browse_idx on public.giveaways(category_id, created_at desc, id desc)
 where status in ('scheduled', 'active', 'ended');
create index giveaways_browse_idx on public.giveaways(created_at desc, id desc)
 where status in ('scheduled', 'active', 'ended');
create index giveaways_starts_at_idx on public.giveaways(starts_at) where status = 'scheduled';
create index giveaways_ends_at_idx on public.giveaways(ends_at) where status = 'active';

create function public.fn_trg_giveaway_schedule() returns trigger
 language plpgsql set search_path = '' as $$
begin
  if TG_OP = 'INSERT' then
    NEW.starts_at := coalesce(NEW.starts_at, NEW.start_date::timestamp at time zone 'UTC');
    NEW.ends_at := coalesce(NEW.ends_at, (NEW.end_date + NEW.end_time) at time zone 'UTC');
  else
    -- Old clients changing legacy fields remain supported. New clients submit UTC.
    if NEW.start_date is distinct from OLD.start_date and NEW.starts_at is not distinct from OLD.starts_at then
      NEW.starts_at := NEW.start_date::timestamp at time zone 'UTC';
    end if;
    if (NEW.end_date is distinct from OLD.end_date or NEW.end_time is distinct from OLD.end_time)
      and NEW.ends_at is not distinct from OLD.ends_at then
      NEW.ends_at := (NEW.end_date + NEW.end_time) at time zone 'UTC';
    end if;
  end if;
  if TG_OP = 'INSERT' or NEW.starts_at is distinct from OLD.starts_at or NEW.ends_at is distinct from OLD.ends_at then
    if NEW.ends_at <= NEW.starts_at then raise exception 'invalid_giveaway_dates' using errcode = '22023'; end if;
    NEW.start_date := (NEW.starts_at at time zone 'UTC')::date;
    NEW.end_date := (NEW.ends_at at time zone 'UTC')::date;
    NEW.end_time := (NEW.ends_at at time zone 'UTC')::time;
  end if;
  if NEW.status in ('active','scheduled') and NEW.starts_at > clock_timestamp() then NEW.status := 'scheduled'; end if;
  if NEW.category_id is not null and (TG_OP = 'INSERT' or NEW.category_id is distinct from OLD.category_id) then
    if not exists (select 1 from public.giveaway_categories c where c.id = NEW.category_id and c.is_active) then
      raise exception 'category_inactive_or_missing' using errcode = '22023';
    end if;
  end if;
  return NEW;
end $$;
revoke all on function public.fn_trg_giveaway_schedule() from public, anon, authenticated;
create trigger giveaway_schedule before insert or update on public.giveaways
 for each row execute function public.fn_trg_giveaway_schedule();

CREATE OR REPLACE FUNCTION public.fn_create_participation(p_giveaway_id uuid, p_user_id uuid)
 RETURNS TABLE(participation_id uuid, participation_number integer, participation_sequence bigint, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_giveaway record;
  v_seq bigint;
  v_num integer;
  v_participation_id uuid;
  v_created_at timestamptz;
  v_pool_size integer;
begin
  select * into v_giveaway from public.giveaways where id = p_giveaway_id for update;
  if not found then
    raise exception 'giveaway_not_found' using errcode = 'P1001';
  end if;

  -- Idempotency is checked first, even after the giveaway has ended or filled.
  if exists (select 1 from public.participations p where p.giveaway_id = p_giveaway_id and p.user_id = p_user_id) then
    return query select p.id, p.participation_number, p.participation_sequence, p.created_at
      from public.participations p where p.giveaway_id = p_giveaway_id and p.user_id = p_user_id;
    return;
  end if;

  if v_giveaway.status not in ('active', 'scheduled')
     or clock_timestamp() < coalesce(v_giveaway.starts_at, v_giveaway.start_date::timestamp at time zone 'UTC')
     or clock_timestamp() >= coalesce(v_giveaway.ends_at, (v_giveaway.end_date + v_giveaway.end_time) at time zone 'UTC') then
    raise exception 'giveaway_not_active' using errcode = 'P1002';
  end if;

  v_pool_size := power(10, v_giveaway.number_digit_width)::integer;
  if v_giveaway.participant_count >= v_pool_size
     or (v_giveaway.max_participants is not null and v_giveaway.participant_count >= v_giveaway.max_participants) then
    raise exception 'giveaway_full' using errcode = 'P1003';
  end if;


  v_num := public.fn_allocate_participation_number(p_giveaway_id);
  v_seq := public.fn_next_participation_sequence(p_giveaway_id);

  insert into public.participations as p (giveaway_id, user_id, participation_sequence, participation_number)
  values (p_giveaway_id, p_user_id, v_seq, v_num)
  returning p.id, p.created_at into v_participation_id, v_created_at;

  return query select v_participation_id, v_num, v_seq, v_created_at;
end;
$function$;

CREATE OR REPLACE FUNCTION public.fn_update_giveaway_statuses()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_giveaway record;
begin
  update public.giveaways
  set status = 'active'
  where status = 'scheduled'
    and coalesce(starts_at, start_date::timestamp at time zone 'UTC') <= clock_timestamp();

  for v_giveaway in
    update public.giveaways
    set status = 'ended'
    where status = 'active'
      and coalesce(ends_at, (end_date + end_time) at time zone 'UTC') <= clock_timestamp()
    returning id, created_by
  loop
    if exists (select 1 from public.participations where giveaway_id = v_giveaway.id)
       and not exists (select 1 from public.winners where giveaway_id = v_giveaway.id) then
      begin
        perform public.fn_select_winner(v_giveaway.id, null::uuid, v_giveaway.created_by, 1::smallint);
      exception when others then
        raise warning 'auto winner selection failed for giveaway %: %', v_giveaway.id, sqlerrm;
      end;
    end if;
  end loop;
end;
$function$;

-- Keep the existing service-role-only RPC boundary.
revoke all on function public.fn_create_participation(uuid,uuid) from public, anon, authenticated;
grant execute on function public.fn_create_participation(uuid,uuid) to service_role;
revoke all on function public.fn_update_giveaway_statuses() from public, anon, authenticated;
grant execute on function public.fn_update_giveaway_statuses() to service_role;

-- Catalog is centrally editable; the initial catalog is data, never Flutter constants.
insert into public.giveaway_categories (name_en,name_ar,icon,sort_order) values
 ('Phones','الهواتف','📱',10), ('Electronics','الإلكترونيات','🎧',20),
 ('Gaming','الألعاب','🎮',30), ('Accessories','الإكسسوارات','⌚',40),
 ('Home Appliances','الأجهزة المنزلية','🏠',50), ('Other','أخرى',null,60);

alter publication supabase_realtime add table public.giveaway_categories;
