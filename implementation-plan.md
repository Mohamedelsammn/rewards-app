# Reward Giveaway App — Implementation Plan

**Type:** Mobile Giveaway / Rewards application
**Stack:** Flutter (Clean Architecture) + Supabase (Postgres, Auth, Storage, Edge Functions) + FCM + AdMob
**Status:** Single source of truth for the development phase (companion file: `tasks.md`)

---

## 1. Project Overview

### 1.1 Summary
A gamified mobile giveaway/rewards app with two roles — **User** and **Admin**. Users browse and join giveaways without a traditional login, unlock a 4-digit participation number by watching a rewarded ad, and reveal it through a scratch-card interaction. Admins create giveaways, publish them, and track performance through an analytics dashboard, ultimately selecting winners.

### 1.2 Sources Analyzed
- Project brief document (`final-doc.docx`) — functional/technical requirements, updated user flow, participation-number constraints, Supabase/architecture mandate.
- UI/UX design screens: Splash Screen, Role Selection, Reward Giveaway Home (User Home), Giveaway Details, User Registration, Admin Dashboard, Create Giveaway, Giveaway Analytics.

### 1.3 Screens Referenced but Not Provided as Mockups
The bottom navigation bars in the provided screens reference tabs that were **not** included as standalone mockups. They are still mandatory per the brief and are designed here from the written requirements:
- **My Giveaways** (User tab)
- **Settings** (User tab)
- **Admin Profile / Admin Settings** (Admin tab)
- **Admin Login** (not shown; required — see §1.4 item 7)

### 1.4 Resolved Ambiguities & Key Architectural Decisions
The brief explicitly asks that ambiguities be identified and resolved safely rather than silently assumed. These are the material ones found while cross-referencing the written spec against the UI/UX design:

| # | Ambiguity | Resolution Adopted |
|---|---|---|
| 1 | A 4-digit participation number allows only 10,000 combinations, yet the **Giveaway Analytics** mockup shows a single active giveaway with **12,450 participants** — a direct contradiction. | Decouple two identifiers: `participation_sequence` (unbounded `bigint`, powers the admin "Ticket #" list and ordering — this is what `#8492` in the mockup represents) and `participation_number` (bounded 4-digit value, 0000–9999, unique **per giveaway**, revealed via the Scratch Card — this is the gamified "lucky number"). A giveaway can have unlimited participants; only the scratch-reveal number space is capped at 10,000 by default (see §16). |
| 2 | There is no login screen, but Supabase RLS requires an authenticated principal (`auth.uid()`) to protect writes. | Use Supabase **Anonymous Auth**, created silently on first app launch, as the security principal for every device install. No credentials are ever requested from ordinary users. |
| 3 | "A phone number must not create another account from another device" and "the same phone number must always resolve to the same user identity." | A `user_devices` join table maps each device's anonymous `auth.uid()` to a single canonical `public.users` row. A server-side Edge Function (`register-or-link-user`) finds-or-creates by normalized phone and links the current device to the existing profile instead of creating a duplicate. |
| 4 | The brief does not describe multi-admin ownership boundaries (does each admin only see their own giveaways?). | Treated as a single global `admin` role with equal access to all giveaways for the MVP — documented assumption, easy to evolve into per-organization scoping later if required. |
| 5 | The mockup shows a manual "Select Winner" CTA; the brief doesn't specify whether selection is random or admin-picked. | Support both: the Edge Function accepts either an explicit `participation_id` (manual pick) or `null` (server picks uniformly at random among eligible participations). |
| 6 | Scope of participation-number uniqueness (per giveaway vs. global). | **Per giveaway.** Global uniqueness would exhaust the 10,000-number space almost immediately across a multi-giveaway platform and doesn't match the "what happens if a giveaway exceeds 10,000 participants" framing in the brief. |
| 7 | Role Selection offers "Continue as Admin" with no visible credential screen. Admin actions are privileged (create/edit giveaways, pick winners) and cannot rely on anonymous auth. | Insert an **Admin Login** screen (Supabase Auth email/password) between Role Selection and the Admin Dashboard. Not present in the provided mockups but required for security; styled to match the existing design system. |
| 8 | "Requirement" chips on Giveaway Details (follow / share / tag) — is completion of these tracked or purely informational? | Treated as **informational/soft requirements** for MVP (no reliable server-side verification exists for Instagram follows). Stored as structured `giveaway_requirements` rows so they can later gain verification without a schema change. |

---

## 2. Goals
- Ship an MVP with **no traditional login for users**, while keeping identity, uniqueness, and write-access provably secure server-side.
- Deliver a modern, premium, lightly gamified experience (scratch card reveal, rewarded ads, confetti/haptics).
- Guarantee **collision-free, server-generated** participation numbers under all load conditions, including the 4-digit constraint.
- Give admins clear visibility into campaign performance and a safe winner-selection workflow.
- Build on Clean Architecture + BLoC so features are independently testable and swappable.
- Keep Supabase as the **only** backend — no bespoke server, only Postgres + RLS + Edge Functions.

---

## 3. Updated User Flow

```
Splash Screen
   ↓
Role Selection
   ↓
User Home  ──(browse/search freely, no info required)──▶ Giveaway Details
   ↓ (tap "Generate My Number")
Local identity exists? ──No──▶ User Registration (Name + Phone, validated, no OTP)
   ↓                                     ↓
   Yes                          register-or-link-user (Edge Function)
   ↓                                     ↓
Rewarded Advertisement (must complete to proceed)
   ↓
create-participation (Edge Function: verifies ad reward, allocates number server-side)
   ↓
Scratch Card (presentation only — number already persisted)
   ↓
Participation number revealed → saved participation visible in My Giveaways
```
Key constraints preserved from the brief:
- Users can browse, search, and view details with **zero** personal information.
- Name + Phone are requested **only** at the moment of participation.
- **No OTP** anywhere in the MVP.
- The participation number is **never** generated on the client.

## 4. Updated Admin Flow
```
Splash → Role Selection → "Continue as Admin"
   ↓
Admin Login (email/password, Supabase Auth) [not in mockups, required — §1.4 #7]
   ↓
Admin Dashboard (stats, active campaign card)
   ├─▶ Create Giveaway → Publish (writes to `giveaways`, uploads image to Storage)
   ├─▶ Giveaway Analytics → Select Winner (admin-select-winner Edge Function) → push notification to winner
   └─▶ Admin Profile / Settings
```
Admin authorization is enforced both at the router level (redirect if unauthenticated / not in `admin_users`) and at the database level (RLS policies keyed off `admin_users`).

---

## 5. Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| UI Framework | Flutter / Dart | Cross-platform mobile client |
| Architecture | Clean Architecture, feature-first | Separation of presentation / domain / data |
| State Management | `flutter_bloc` (Bloc + Cubit) | Predictable, testable state |
| DI | `get_it` + `injectable` | Dependency wiring / codegen |
| Routing | `go_router` | Declarative navigation, guards, shells |
| Models | `freezed` + `json_serializable`, `equatable` | Immutable models, DTOs, value equality |
| Backend | Supabase (Postgres, Auth, Storage, Edge Functions, Realtime) | BaaS backend |
| Push | Firebase Cloud Messaging (FCM) | Notifications |
| Ads | Google Mobile Ads (AdMob) — App Open, Banner, Rewarded | Monetization + reward gating |
| Local persistence | `flutter_secure_storage` (identity/session), `shared_preferences` (non-sensitive UI prefs), `hive` (cache) | Local state |

---

## 6. Architecture

Clean Architecture with 3 layers per feature:
- **Presentation** — Widgets + Bloc/Cubit + Freezed States/Events.
- **Domain** — Entities, Repository interfaces, (optional) UseCases. Pure Dart, no Flutter/Supabase imports.
- **Data** — Repository implementations, Supabase data sources, DTO → Entity mapping.

Cross-cutting `core/` holds error handling, network/session utilities, theming, and DI registration. Features never import Supabase directly in presentation — only through injected repository interfaces, keeping the client swappable and testable.

---

## 7. Flutter Folder Structure

```
lib/
  main.dart
  bootstrap.dart
  core/
    di/                     # get_it + injectable setup
    error/                  # Failure hierarchy, Result/Either helpers
    network/                # Supabase client provider, connectivity
    theme/                  # colors, typography, spacing (matches design: purple/indigo gradient, soft cards)
    utils/                  # phone normalization, date helpers, validators
  config/
    env.dart                # dart-define driven environment config
    supabase_config.dart
    admob_config.dart
  routing/
    app_router.dart         # GoRouter root config
    route_guards.dart       # admin auth guard, user identity guard
  services/
    ad_service/             # AppOpenAdManager, BannerAdWidget, RewardedAdManager
    notification_service/   # FCM init, topic subscribe, deep link handling
    secure_storage_service.dart
    cache/                  # Hive-backed TTL cache layer
    analytics_logger.dart
  shared/
    widgets/                # buttons, cards, chips, skeleton loaders, empty states
    extensions/
  features/
    splash/
    role_selection/
    admin_auth/             # Admin Login
    user_home/               # Reward Giveaway Home + search
    giveaway_details/
    participation/           # Registration + orchestration of ad → number → scratch
    scratch_card/
    my_giveaways/
    settings/
    admin_dashboard/
    create_giveaway/
    giveaway_analytics/
    admin_settings/
```
Each `features/<x>/` follows `presentation/ domain/ data/`.

---

## 8. Feature Architecture

| Feature | Screens | Bloc/Cubit | Repository | Key Entities |
|---|---|---|---|---|
| splash | Splash | `SplashCubit` | `AuthRepository` | — |
| role_selection | Role Selection | (stateless / lightweight `RoleSelectionCubit`) | — | — |
| admin_auth | Admin Login | `AdminAuthBloc` | `AuthRepository` | `AdminUser` |
| user_home | User Home (Home tab) | `UserHomeBloc` | `GiveawayRepository` | `Giveaway` |
| giveaway_details | Giveaway Details | `GiveawayDetailsBloc` | `GiveawayRepository` | `Giveaway`, `GiveawayRequirement` |
| participation | Registration modal, orchestration | `ParticipationBloc` | `UserRepository`, `ParticipationRepository`, `AdRepository` | `UserProfile`, `Participation` |
| scratch_card | Scratch Card reveal | `ScratchCardCubit` | — (pure presentation) | `Participation` (read-only) |
| my_giveaways | My Giveaways tab | `MyGiveawaysBloc` | `ParticipationRepository` | `Participation`, `Giveaway` |
| settings | Settings tab | `SettingsCubit` | `SettingsLocalRepository` | — |
| admin_dashboard | Admin Dashboard | `AdminDashboardBloc` | `GiveawayRepository` | `Giveaway`, dashboard stats |
| create_giveaway | Create Giveaway | `CreateGiveawayBloc` | `GiveawayRepository`, `StorageRepository` | `Giveaway` |
| giveaway_analytics | Giveaway Analytics | `GiveawayAnalyticsBloc` | `GiveawayRepository`, `WinnerRepository` | `Giveaway`, `Participation`, `Winner` |
| admin_settings | Admin Profile/Settings | `SettingsCubit` (admin variant) | `AuthRepository` | `AdminUser` |

### 8.1 Traceability Matrix (Screen → DB → Backend)

| Screen | Primary Table(s) | Edge Function(s) |
|---|---|---|
| Splash | `auth.users` | — (anonymous sign-in via SDK) |
| Role Selection | — | — |
| Admin Login | `auth.users`, `admin_users` | — (Supabase Auth SDK) |
| User Home | `giveaways` | — |
| Giveaway Details | `giveaways`, `giveaway_requirements` | — |
| User Registration | `users`, `user_devices` | `register-or-link-user` |
| Participation (ad + number) | `participations`, `participation_number_pool`, `ad_reward_events` | `verify-ad-reward`, `create-participation` |
| Scratch Card | `participations` (read) | — |
| My Giveaways | `participations`, `giveaways`, `winners` | — |
| Settings | local only | — |
| Admin Dashboard | `giveaways` (aggregates) | — |
| Create Giveaway | `giveaways`, `giveaway_requirements`, Storage | — (direct RLS-guarded insert) |
| Giveaway Analytics | `giveaways`, `participations`, `winners` | `admin-select-winner` |

---

## 9. Navigation Architecture

`go_router` with two `ShellRoute`s (User shell, Admin shell) plus top-level, non-shell routes:

```
/                          → Splash
/role-selection            → Role Selection
/admin/login                → Admin Login

// User shell (bottom nav: Home / My Giveaways / Settings)
/user/home                  → User Home
/user/giveaways/:id         → Giveaway Details
/user/my-giveaways          → My Giveaways
/user/settings              → Settings
/user/participate/:giveawayId  → Registration → Ad → Scratch (full-screen flow, pushed above shell)

// Admin shell (bottom nav: Dashboard / Analytics / Profile) — guarded
/admin/dashboard             → Admin Dashboard
/admin/create-giveaway       → Create Giveaway
/admin/analytics/:giveawayId → Giveaway Analytics
/admin/settings              → Admin Profile/Settings
```
**Guards:**
- `adminAuthGuard` — redirects to `/admin/login` if no active admin session or the session's user is not present in `admin_users`.
- `userIdentityGuard` — the participation flow does not gate navigation (users can always view details); it only gates the "Generate My Number" action, which triggers registration inline if no local identity/session exists.

---

## 10. Database Architecture

Relational overview (Postgres, Supabase-managed):

```
auth.users (Supabase managed, anonymous + admin email accounts)
   │
   ├─ 1:N → user_devices → N:1 → users            (device → canonical profile)
   │
   └─ 1:1 → admin_users                            (only for admin accounts)

users 1:N participations N:1 giveaways
giveaways 1:N giveaway_requirements
giveaways 1:1 giveaway_counters
giveaways 1:N participation_number_pool
participations 1:1(optional) winners
users 1:N notifications
users 1:N ad_reward_events
```
All primary keys are `uuid` (`gen_random_uuid()`) except the number pool and sequence helper tables, which use composite/natural keys for performance.

---

## 11. Complete Database Schema

See migrations applied via Supabase MCP for the authoritative, executed version. Base design (from the original brief) below; the executed schema additionally adds `winners.celebration_acknowledged_at` for exactly-once winner-celebration tracking (see engineering-log entry).

```sql
-- ============ USERS & IDENTITY ============

create table public.users (
  id            uuid primary key default gen_random_uuid(),
  full_name     text not null,
  phone_e164    text not null unique,          -- normalized, e.g. +12025550190
  country_code  text not null,                  -- e.g. "US"
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  is_blocked    boolean not null default false
);

create table public.user_devices (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.users(id) on delete cascade,
  auth_uid      uuid not null unique references auth.users(id) on delete cascade,
  fcm_token     text,
  device_info   jsonb,
  first_seen_at timestamptz not null default now(),
  last_seen_at  timestamptz not null default now()
);
create index idx_user_devices_user_id on public.user_devices(user_id);

create table public.admin_users (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null,
  email       text not null unique,
  role        text not null default 'admin' check (role in ('admin','super_admin')),
  created_at  timestamptz not null default now()
);

-- ============ GIVEAWAYS ============

create type giveaway_status as enum ('draft','scheduled','active','ended','archived');

create table public.giveaways (
  id                 uuid primary key default gen_random_uuid(),
  title              text not null,
  organizer_name     text not null,
  prize_description  text not null,
  description_rules  text not null,
  image_url          text,
  start_date         date not null,
  end_date           date not null,
  end_time           time not null,
  status             giveaway_status not null default 'draft',
  number_digit_width smallint not null default 4 check (number_digit_width between 4 and 6),
  max_participants   integer,                     -- optional hard cap; null = unlimited
  participant_count  integer not null default 0,   -- denormalized, trigger-maintained (see §15)
  created_by         uuid not null references public.admin_users(id),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  check (end_date >= start_date)
);
create index idx_giveaways_status on public.giveaways(status);
create index idx_giveaways_end on public.giveaways(end_date, end_time);

create table public.giveaway_requirements (
  id           uuid primary key default gen_random_uuid(),
  giveaway_id  uuid not null references public.giveaways(id) on delete cascade,
  sort_order   smallint not null default 0,
  type         text not null check (type in ('follow','share','tag_friends','custom')),
  label        text not null,
  external_url text
);
create index idx_giveaway_requirements_giveaway on public.giveaway_requirements(giveaway_id);

-- ============ PARTICIPATION NUMBERING (see §16 for rationale) ============

create table public.giveaway_counters (
  giveaway_id     uuid primary key references public.giveaways(id) on delete cascade,
  next_sequence   bigint not null default 1
);

create table public.participation_number_pool (
  giveaway_id  uuid not null references public.giveaways(id) on delete cascade,
  number       integer not null,
  is_used      boolean not null default false,
  assigned_participation_id uuid,
  primary key (giveaway_id, number)
);
create index idx_pool_unused on public.participation_number_pool(giveaway_id) where not is_used;

create table public.participations (
  id                     uuid primary key default gen_random_uuid(),
  giveaway_id            uuid not null references public.giveaways(id) on delete cascade,
  user_id                uuid not null references public.users(id) on delete cascade,
  participation_sequence bigint not null,        -- unbounded, admin "Ticket #"
  participation_number   integer not null,        -- bounded 4-digit "lucky number"
  ad_reward_event_id     uuid not null references public.ad_reward_events(id),
  scratch_revealed_at    timestamptz,
  created_at             timestamptz not null default now(),
  unique (giveaway_id, user_id),                  -- one participation per user per giveaway
  unique (giveaway_id, participation_number),
  unique (giveaway_id, participation_sequence)
);
create index idx_participations_user on public.participations(user_id);
create index idx_participations_giveaway on public.participations(giveaway_id, created_at desc);

-- ============ WINNERS ============

create table public.winners (
  id               uuid primary key default gen_random_uuid(),
  giveaway_id      uuid not null references public.giveaways(id) on delete cascade,
  participation_id uuid not null references public.participations(id),
  rank             smallint not null default 1,
  selected_by      uuid not null references public.admin_users(id),
  selected_at      timestamptz not null default now(),
  prize_delivery_status text not null default 'pending'
      check (prize_delivery_status in ('pending','contacted','shipped','delivered')),
  notes            text,
  celebration_acknowledged_at timestamptz,        -- null = celebration not yet shown to winner
  unique (giveaway_id, participation_id)
);

-- ============ NOTIFICATIONS ============

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references public.users(id) on delete cascade,   -- null = broadcast/log-only
  type       text not null check (type in
              ('giveaway_starting','giveaway_ending_soon','winner_announcement','participation_confirmed','general')),
  title      text not null,
  body       text not null,
  data       jsonb,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_notifications_user on public.notifications(user_id, created_at desc);

-- ============ ADVERTISEMENT ABUSE PREVENTION ============

create table public.ad_reward_events (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.users(id) on delete cascade,
  giveaway_id       uuid not null references public.giveaways(id) on delete cascade,
  ad_network_txn_id text not null unique,      -- AdMob SSV transaction id, prevents replay
  status            text not null default 'pending' check (status in ('pending','verified','consumed','invalid')),
  verified_at       timestamptz,
  consumed_at       timestamptz,
  created_at        timestamptz not null default now()
);
create index idx_ad_reward_user_giveaway on public.ad_reward_events(user_id, giveaway_id);
```

---

## 12. Supabase RLS Strategy

RLS is **enabled on every table**, default-deny. A security-definer helper resolves the calling device to a business user:

```sql
create or replace function public.fn_current_user_id()
returns uuid language sql stable security definer as $$
  select ud.user_id from public.user_devices ud where ud.auth_uid = auth.uid()
$$;

create or replace function public.fn_is_admin()
returns boolean language sql stable security definer as $$
  select exists (select 1 from public.admin_users a where a.id = auth.uid())
$$;
```

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `users` | own row (`id = fn_current_user_id()`) | **client: none** — only via `register-or-link-user` (service role) | own `full_name` only | none |
| `user_devices` | own rows | server-side only | server-side only | none |
| `admin_users` | own row if `id = auth.uid()` | server-provisioned only | none from client | none |
| `giveaways` | `status in ('scheduled','active','ended')` for everyone; all rows if `fn_is_admin()` | admin only | admin only | admin only (soft: set `archived`) |
| `giveaway_requirements` | same visibility as parent giveaway | admin only | admin only | admin only |
| `participation_number_pool` | **no client access** (service role only) | — | — | — |
| `giveaway_counters` | **no client access** | — | — | — |
| `participations` | own rows (`user_id = fn_current_user_id()`); admin sees all | **client: none** — only via `create-participation` (service role) | own row, **only** the `scratch_revealed_at` column, via a narrow policy/RPC | none |
| `winners` | public (announcements) | admin only | admin only (incl. `celebration_acknowledged_at` self-ack via narrow policy) | admin only |
| `notifications` | own rows | server-side only (triggers/Edge Functions) | own rows, `is_read` only | none |
| `ad_reward_events` | own rows | **no client access** — created only by `verify-ad-reward` (service role) | service role only | none |

---

## 13. Supabase Storage

| Bucket | Access | Notes |
|---|---|---|
| `giveaway-images` | Public read; write restricted to `fn_is_admin()` | Path: `giveaway-images/{giveaway_id}/{filename}`. Enforce ≤5MB, JPG/PNG/GIF via client-side pre-check **and** a storage policy / Edge Function validation. |
| `admin-avatars` | Public read; write restricted to the owning admin (`auth.uid() = owner`) | Optional, used on Admin Profile. |

---

## 14. Supabase Edge Functions

| Function | Trigger | Auth | Responsibility |
|---|---|---|---|
| `register-or-link-user` | Called from Registration screen | Verified anonymous JWT | Normalize/validate phone, find-or-create `public.users` by `phone_e164`, upsert `user_devices` link for the calling `auth.uid()`. Returns `user_id` + profile. |
| `verify-ad-reward` | Client-invoked after rewarded ad completes (real AdMob SSV webhook deferred until production AdMob credentials exist) | Verified JWT (+ signed request from Google in production) | Prevents `ad_network_txn_id` replay, inserts `ad_reward_events` row with `status='verified'`. |
| `create-participation` | Called after rewarded ad completes | Verified JWT | Confirms an unconsumed `verified` `ad_reward_events` row exists for (user, giveaway); confirms giveaway is `active` and under `max_participants`/pool capacity; calls `fn_allocate_participation_number` + `fn_next_participation_sequence`; inserts `participations`; marks the ad event `consumed`; all inside one transaction. Returns the participation (including the number) to the client. |
| `admin-select-winner` *(deferred)* | Admin taps "Select Winner" | Verified admin JWT | Accepts optional `participation_id` (manual) or picks uniformly at random among that giveaway's participations if omitted; inserts `winners`; enqueues a `winner_announcement` notification + FCM push. |
| `update-giveaway-statuses` *(deferred)* | Scheduled (cron, every 5 min) | Service role | Flips `draft/scheduled → active → ended` based on `start_date`/`end_date`/`end_time`. |
| `notify-giveaway-ending-soon` *(deferred)* | Scheduled (cron, hourly) | Service role | Finds giveaways ending within a configurable window and sends a broadcast FCM topic push + logs `giveaway_ending_soon` notifications. |

Only `register-or-link-user`, `verify-ad-reward` and `create-participation` are reachable with a normal user JWT; all others require either an admin JWT or run purely as service-role scheduled jobs — the service-role key itself is **never** shipped to the Flutter client.

---

## 15. Server-side Business Logic

Postgres functions/triggers backing the Edge Functions:

- `fn_normalize_phone(text) returns text` — E.164 normalization (mirrors client-side validation; server is the source of truth).
- `fn_current_user_id()`, `fn_is_admin()` — see §12.
- `fn_allocate_participation_number(giveaway_id uuid) returns integer` — atomic pool pop (see §16).
- `fn_next_participation_sequence(giveaway_id uuid) returns bigint` — atomic increment on `giveaway_counters`.
- `trg_populate_number_pool()` — **AFTER INSERT** trigger on `giveaways`: materializes `10^number_digit_width` shuffled rows into `participation_number_pool` and a matching `giveaway_counters` row.
- `trg_maintain_participant_count()` — **AFTER INSERT** trigger on `participations`: increments `giveaways.participant_count`.
- `trg_set_updated_at()` — generic `updated_at` maintenance trigger on `users`, `giveaways`.

---

## 16. Participation Number Generation

**What it is:** a 4-digit number (default `number_digit_width = 4`, i.e. 0000–9999) shown after the Scratch Card reveal. Distinct from `participation_sequence`, the unbounded ticket counter shown in Admin Analytics (see resolved ambiguity §1.4 #1).

**Where it is generated:** exclusively inside the `create-participation` **Edge Function**, which calls the Postgres function `fn_allocate_participation_number` inside the same transaction as the `participations` insert. The Flutter client never computes, guesses, or is trusted with generating this value — it only *displays* whatever the server already persisted.

**How it is generated (collision-proof by construction):**
1. On giveaway creation, `trg_populate_number_pool` pre-materializes every possible number for that giveaway (0000–9999 for the default width) into `participation_number_pool`, in random order via `order by random()` at insert time.
2. `fn_allocate_participation_number` executes an atomic `UPDATE ... FOR UPDATE SKIP LOCKED ... LIMIT 1 RETURNING number` claim — no retry loop, no collision handling needed.
3. If the pool query returns no row (pool exhausted), the function raises a typed exception (`pool_exhausted`).

**Uniqueness scope:** **per giveaway**, not global (§1.4 #6).

**Scalability note:** at 10,000 rows per giveaway, the pool table stays trivial. A Feistel-network-based format-preserving permutation is a documented future drop-in replacement if needed (see original brief §27).

---

## 17. User Identity Strategy

`auth.uid()` (anonymous, one per device install) → `user_devices.auth_uid` → `user_devices.user_id` → `public.users`. All RLS policies resolve identity through this chain via `fn_current_user_id()`.

`register-or-link-user` finds-or-creates by normalized phone and links the calling device — guaranteeing "same phone always resolves to the same identity" and "a phone must not create a second account from another device," backed by the `users.phone_e164` unique constraint as the ultimate guarantee even under race conditions.

---

## 18. Advertisement Architecture

Rewarded ad completion → `verify-ad-reward` (replay-proofed via unique `ad_network_txn_id`) → `create-participation` (consumes the verified event exactly once, in the same transaction that allocates the number). Scratch Card and rewarded ad are both presentation/gating layers only — neither determines the actual participation number, which is already persisted by the time either is shown.

This pass uses Google's public test AdMob App/Ad Unit IDs; swapping to production IDs and a real AdMob SSV webhook is a config-only change with no architecture change required.

---

## 19–31.

See original brief content (push notifications, scratch card architecture, state management, repository layer, models, error handling, loading/empty/error states, security, scalability, testing, performance, deployment, production checklist) — unchanged from the source document and not repeated here for brevity. Deferred items for this delivery pass are tracked in the approved plan (`C:\Users\DELL\.claude\plans\you-are-the-lead-humming-melody.md`) and `tasks.md`.
