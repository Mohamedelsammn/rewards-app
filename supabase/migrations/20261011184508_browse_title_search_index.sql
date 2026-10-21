-- Support bounded Unicode title substring searches as the catalog grows.
-- Existing rows and all application/RLS contracts are unchanged.
set local lock_timeout = '5s';
create extension if not exists pg_trgm with schema extensions;
create index giveaways_browse_title_trgm_idx
 on public.giveaways using gin (title extensions.gin_trgm_ops)
 where status in ('scheduled', 'active', 'ended');
