# Reward Giveaway App — Tasks

Companion file to `implementation-plan.md`. Full original task breakdown (Phases 1–20, T01-01 through T20-07) preserved as the long-term roadmap. Status below reflects the cumulative state after the foundation pass + the Liquid Glass/Admin/Winner-selection follow-up pass.

**Task Granularity Note:** RLS policies are grouped into one task per table (or per closely related table group) rather than one task per individual `CREATE POLICY` statement.

**ID scheme:** `T<phase>-<sequence>`, e.g. `T04-07`.

---

## Delivery-pass status legend
- ✅ Done and verified this pass
- ⏭ Deferred (either explicitly out of scope for this version, or waiting on external prerequisites)
- 🚫 Permanently excluded from this version (product decision, not "not yet")

---

## Phase 1 — Project Setup
- ✅ T01-01 → T01-04
- ⏭ T01-05 CI pipeline skeleton

## Phase 2 — Architecture
- ✅ T02-01 → T02-03, T02-05 (GoRouter replaced with direct Navigator push/pop -- documented simplification, no deep-linking need yet)
- ⏭ T02-04 Base UseCase abstraction (optional layer)

## Phase 3 — Supabase Setup
- ✅ T03-01 → T03-05 (anonymous + admin email/password auth both confirmed live; admin sign-up now also self-service via access code, see Phase 13)

## Phase 4 — Database
- ✅ T04-01 → T04-13, plus `admin_signup_codes` + `rate_limit_hits` tables added in the follow-up pass
- ⏭ T04-14 Local dev seed script (admin/sample data seeded directly via MCP instead)

## Phase 5 — Core Services
- ✅ T05-01 → T05-09, and **T05-07 Giveaway status transition is now done**: `fn_update_giveaway_statuses()` runs every 5 minutes via `pg_cron` (no Edge Function needed)
- ⏭ T05-10 ConnectivityService & crash reporting bootstrap (needs a Sentry/Crashlytics project)

## Phase 6 — Splash & Role Selection
- ✅ T06-01 → T06-05 -- Splash simplified to logo + app name only per follow-up request; Role Selection's Admin path now leads to a combined Sign In/Sign Up page

## Phase 7 — User Flow (Home & Shell)
- ✅ T07-01 → T07-04, T07-06
- 🚫 T07-05 Banner Ad on Home -- ads removed from this version entirely (see Phase 15)
- ✅ User bottom nav upgraded to a Liquid Glass floating pill (`liquid_glass_widgets`), same destinations/behavior

## Phase 8 — Giveaway System
- ✅ T08-01 → T08-05

## Phase 9 — Participation
- ✅ T09-01 → T09-07. The "Rewarded Ad" step now auto-claims the reward locally (no ad SDK -- see Phase 15); `verify-ad-reward`/`create-participation` and the number-allocation guarantees are unchanged and still fully server-side.

## Phase 10 — Scratch Card
- ✅ T10-01 → T10-06 (`Celebration.json`, bottom-anchored, participation-reveal experience)

## Phase 11 — My Giveaways
- ✅ T11-01 → T11-04 -- winner highlight now covered by the top-anchored Winner Celebration overlay (shown once per win on User Home entry, gated by `winners.celebration_acknowledged_at`)

## Phase 12 — Settings
- ✅ T12-01, T12-04, and **Sign Out added** (clears only the last-role flag; anonymous session, cached identity, and Hive cache are deliberately preserved -- see engineering note in `settings_page.dart`)
- ⏭ T12-02 Language switcher, T12-03 Legal page linking (no i18n framework / published legal copy yet)

## Phase 13 — Admin
- ✅ T13-01 → T13-09, all done: Admin Sign In **and Sign Up** (self-service, gated by a bcrypt-hashed access code checked server-side -- selecting "Admin" grants zero privilege on its own), Admin Dashboard, Create Giveaway (with image upload), Admin bottom nav shell, Admin Profile

## Phase 14 — Analytics
- ✅ T14-01 → T14-04: campaign summary, Total Joined/Active Today, Participation Growth chart (`fl_chart`, live daily-bucket aggregation), Recent Participants (ticket # = `participation_sequence`), Select Winner (manual or random via `admin-select-winner`)
- ✅ T14-05 Winners list/announcement surfacing -- winner shown on Analytics immediately, notification row created server-side

## Phase 15 — Advertisements
- 🚫 **All of Phase 15 is permanently excluded from this version** (explicit product decision): no `google_mobile_ads`, no AdMob App ID, no ad SDK anywhere in the app. `verify-ad-reward` still exists server-side (replay-proofed via unique `ad_network_txn_id`) but is invoked with a client-generated UUID instead of a real ad completion. Reintroducing real ads later is a config + `ParticipationCubit.watchAd()` change only -- nothing else in the architecture assumes their absence.

## Phase 16 — Notifications
- 🚫 **FCM/push is permanently excluded from this version** (explicit product decision, no Firebase project). `notifications` rows are still created server-side (e.g. `winner_announcement` on selection) so the data model is push-ready, but nothing delivers a native push or reads this table client-side yet.

## Phase 17 — Security
- ✅ RLS on every table, verified via direct RLS-bypass attempts (blocked with `42501`) for both the participation-number functions and admin self-promotion
- ✅ **T17-03 Rate limiting done**: `fn_check_rate_limit` (sliding window, DB-backed) applied to `register-or-link-user` (10/60s) and `create-participation` (20/60s), both load-tested with a burst script confirming the 429 cutoff
- ⏭ T17-01/T17-02 full formal audit, T17-04 input-fuzz audit -- informal coverage exists (advisor checks + manual RLS-bypass tests after every schema change) but no dedicated audit pass yet

## Phase 18 — Testing
- ✅ 46 tests passing: Bloc/Cubit tests (including Admin Auth sign-up, Admin Giveaways, Create Giveaway), widget tests (ScratchCard, Registration form), SQL tests for RLS + concurrency + rate limiting
- ⏭ Golden tests (T18-07), full end-to-end integration test against a staging Supabase project (T18-05 partial only)

## Phase 19 — Performance
- ✅ T19-01 pagination on Home list (cursor-based)
- ⏭ T19-02 → T19-05 -- deferred (need production-scale data to validate meaningfully)

## Phase 20 — Release
- ⏭ All -- deferred
