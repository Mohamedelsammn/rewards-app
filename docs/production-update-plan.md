# Rewards App production update — audit and implementation plan

Audit date: 2026-10-11. The owner's current request overrides older no-ad and scratch-card requirements in implementation-plan.md/tasks.md. Existing uncommitted work is the starting point and must be preserved. Kluster is unavailable; the owner explicitly authorized proceeding without it for this task.

## Verified baseline

- Feature-first Flutter, flutter_bloc Cubits, manual get_it injection, Navigator/MaterialPageRoute, Hive caches, secure-storage identity, ARB English/Arabic localization.
- Home has no location UI already; featured/popular/list sections use a full-table read and client title search with a 300ms debounce. No persistent favorites or verified-organizer database field exists.
- User shell uses IndexedStack and AppBottomNav/GlassTabBar. Preserve AppBottomNav unchanged. Preserve Lottie splash and NumberRevealPage.
- Supabase project gaarpeebmixvruxeetks is accessible. Public schema/RLS, function definitions, cron, foreign keys, indexes and Edge Function source inspected. Categories do not exist. admin_users.role already supports admin/super_admin; currently no super_admin exists. Do not promote anyone automatically.
- Giveaway schedule uses date/date/time without timezone. Enum already has scheduled. fn_update_giveaway_statuses runs every five minutes, activates drafts, ends giveaways and invokes existing winner selection. fn_create_participation locks the giveaway and allocates server-side, but checks only status and raises on existing entries.
- Participation identity: persistent anonymous Supabase Auth session maps through user_devices to users; phone is an unverified unique record identifier, not authentication. Server refuses cross-device phone linking. My Giveaways uses authenticated RLS and identity-scoped cache. Profile editing and server-side deletion exist.
- Android applicationId/namespace com.creativehub.rewardsapp; Firebase rewards-app-87115. Existing key.properties and upload-keystore.jks present; passwords/private keys must never be printed or changed. Local version 1.0.1+2; existing AAB is an old artifact, not this update. Highest uploaded Google Play versionCode: Not independently verified.
- 43 existing test files. In-app EN/AR and hosted privacy policy currently deny advertising. Legal URLs use build-time defines with no defaults. rewardsapp.tech is for future website work, which is out of scope.

## Ordered implementation

1. Home: reference-based white rounded cards, compact responsive two-column lazy grid, searchable title, clear action, horizontal categories, real counts, effective statuses, no unimplemented bookmark/verification claims. Bounded page queries with stale-response guards and failure retry.
2. Categories: additive catalog and nullable FK; active public reads; database role-based super_admin catalog writes; ordinary verified admins may assign active categories to owned giveaways. No category deletion UI or automatic role elevation.
3. Scheduling: additive UTC starts_at/ends_at with backward-compatible legacy field synchronization. Preserve existing rows; derive exact server participation eligibility independently of cron. Preserve winner algorithm and notification flow; update scheduler predicates only. Idempotent participation returns existing number under lock.
4. Ads: official pinned google_mobile_ads, exact owner IDs in release, official test units in debug/profile; UMP gate and privacy choices; singleton service, fullscreen mutex, critical-flow suppression, retry/backoff and disposal. Stable adaptive banner above unchanged navigation. Third genuine route entry counts, including same giveaway reopened; no rebuild/resume counts. Optional rewarded offer, equal free continuation, backend number creation after ad completion/dismissal handling.
5. Localization/tests: add EN/AR strings, Home narrow-width/RTL and paging/search tests; scheduling/authorization SQL rollback checks; frequency/lifecycle/reward tests. Run analyze and complete Flutter suite after major changes.
6. Release: increment local version, preserve signing/Firebase/backend identity, verify certificate without revealing credentials, build release only if technical/policy constraints permit. Separate successful technical build from Play submission readiness.

## Release requirements outside development

Verify Play Console highest versionCode before upload. Review actual Data Safety form, audience/age declarations, AdMob Privacy & messaging configuration and rewarded policy eligibility. Publish verified legal/support/deletion pages on the owner's domain later; do not invent URLs. Device ad/consent and performance QA requires a connected Android device/emulator and Google test ads.
