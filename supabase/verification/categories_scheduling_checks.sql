-- Synthetic fixtures exist only inside this transaction and are rolled back.
begin;
do $test$
declare
 owner_id uuid; participant_id uuid; future_id uuid; expired_id uuid; active_id uuid;
 fixture_category_id uuid; first_entry record; repeated_entry record; super_id uuid := gen_random_uuid(); count_rows integer;
 other_owner_id uuid; participant_auth_uid uuid;
begin
 select id into owner_id from public.admin_users order by created_at limit 1;
 select id into participant_id from public.users order by created_at limit 1;
 if owner_id is null or participant_id is null then raise exception 'verification_fixture_prerequisite_missing'; end if;
 insert into public.giveaway_categories(name_en,name_ar) values ('Verification category','فئة اختبار') returning id into fixture_category_id;
 insert into public.giveaways(title,organizer_name,prize_description,description_rules,start_date,end_date,end_time,status,created_by,starts_at,ends_at,category_id)
 values ('__verification_future','Verification','','',current_date,current_date+2,'12:00','active',owner_id,now()+interval '1 day',now()+interval '2 days',fixture_category_id) returning id into future_id;
 if (select status from public.giveaways where id=future_id) <> 'scheduled' then raise exception 'future_not_scheduled'; end if;
 begin perform public.fn_create_participation(future_id,participant_id); raise exception 'early_join_allowed';
 exception when sqlstate 'P1002' then null; end;
 insert into public.giveaways(title,organizer_name,prize_description,description_rules,start_date,end_date,end_time,status,created_by,starts_at,ends_at)
 values ('__verification_expired','Verification','','',current_date-2,current_date-1,'12:00','active',owner_id,now()-interval '2 days',now()-interval '1 day') returning id into expired_id;
 begin perform public.fn_create_participation(expired_id,participant_id); raise exception 'late_join_allowed';
 exception when sqlstate 'P1002' then null; end;
 begin
 insert into public.giveaways(title,organizer_name,prize_description,description_rules,start_date,end_date,end_time,status,created_by,starts_at,ends_at)
 values ('__verification_invalid','Verification','','',current_date,current_date,'12:00','active',owner_id,now()+interval '2 days',now()+interval '1 day');
 raise exception 'invalid_interval_allowed'; exception when sqlstate '22023' then null; end;
 insert into public.giveaways(title,organizer_name,prize_description,description_rules,start_date,end_date,end_time,status,created_by,starts_at,ends_at)
 values ('__verification_active','Verification','','',current_date-1,current_date+1,'12:00','scheduled',owner_id,now()-interval '1 hour',now()+interval '1 day') returning id into active_id;
 -- Eligible immediately, without waiting for cron.
 select * into first_entry from public.fn_create_participation(active_id,participant_id);
 select * into repeated_entry from public.fn_create_participation(active_id,participant_id);
 if first_entry.participation_id <> repeated_entry.participation_id or first_entry.participation_number <> repeated_entry.participation_number then raise exception 'not_idempotent'; end if;
 if (select count(*) from public.participations where giveaway_id=active_id) <> 1 then raise exception 'duplicate_entries'; end if;

 perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_id,'role','authenticated','user_metadata',jsonb_build_object('role','super_admin'))::text,true);
 execute 'set local role authenticated';
 begin insert into public.giveaway_categories(name_en,name_ar) values ('Unauthorized','غير مصرح'); raise exception 'ordinary_admin_catalog_create_allowed';
 exception when insufficient_privilege then null; end;
 update public.giveaway_categories set name_en='Unauthorized edit' where id=fixture_category_id;
 get diagnostics count_rows=row_count;
 if count_rows <> 0 then raise exception 'ordinary_admin_catalog_edit_allowed'; end if;
 update public.giveaways set category_id=fixture_category_id where id=future_id;
 get diagnostics count_rows=row_count;
 if count_rows <> 1 then raise exception 'owner_category_assignment_failed'; end if;
 execute 'reset role';

 select id into other_owner_id from public.admin_users where id<>owner_id limit 1;
 if other_owner_id is null then raise exception 'second_admin_prerequisite_missing'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',other_owner_id,'role','authenticated')::text,true);
 execute 'set local role authenticated';
 update public.giveaways set starts_at=now()-interval '1 hour' where id=future_id;
 get diagnostics count_rows=row_count;
 if count_rows <> 0 then raise exception 'other_admin_changed_start_time'; end if;
 execute 'reset role';

 select auth_uid into participant_auth_uid from public.user_devices where user_id=participant_id limit 1;
 if participant_auth_uid is null then raise exception 'linked_participant_prerequisite_missing'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',participant_auth_uid,'role','authenticated')::text,true);
 execute 'set local role authenticated';
 begin
   update public.participations set participation_number=participation_number+1 where id=first_entry.participation_id;
   raise exception 'participant_changed_number';
 exception when insufficient_privilege then null; end;
 begin perform public.fn_allocate_participation_number(active_id); raise exception 'participant_allocated_number';
 exception when insufficient_privilege then null; end;
 execute 'reset role';

 -- A synthetic super-admin tests permission without promoting any real account.
 insert into auth.users(id,email) values (super_id,'verification-'||super_id||'@invalid.example');
 insert into public.admin_users(id,full_name,email,role) values (super_id,'Verification','verification-'||super_id||'@invalid.example','super_admin');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',super_id,'role','authenticated')::text,true);
 execute 'set local role authenticated';
 insert into public.giveaway_categories(name_en,name_ar,sort_order) values ('Authorized','مصرح',99);
 update public.giveaway_categories set is_active=false,sort_order=123 where id=fixture_category_id;
 get diagnostics count_rows=row_count;
 if count_rows <> 1 then raise exception 'super_admin_catalog_update_failed'; end if;
 begin delete from public.giveaway_categories where id=fixture_category_id; raise exception 'category_delete_allowed';
 exception when insufficient_privilege then null; end;
 execute 'reset role';
 perform set_config('request.jwt.claims','{}',true);
 execute 'set local role anon';
 if exists(select 1 from public.giveaway_categories where id=fixture_category_id) then raise exception 'inactive_visible_to_public'; end if;
 begin insert into public.giveaway_categories(name_en,name_ar) values ('Anon','مجهول'); raise exception 'anon_create_allowed';
 exception when insufficient_privilege then null; end;
 begin perform public.fn_create_participation(future_id,participant_id); raise exception 'public_allocation_allowed';
 exception when insufficient_privilege then null; end;
 execute 'reset role';
end $test$;
rollback;
select 'scheduling_category_security_and_idempotency_checks_passed' as result;
