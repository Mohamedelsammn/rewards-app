# State Synchronization & Session Restoration — Root Cause Analysis & Fix Plan

Investigation performed before any code changes, per the task's Phase 0 requirement. Covers
authentication/session management, app bootstrap, role selection, User/Admin cubit lifecycles,
realtime subscriptions, and the Hive cache layer.

## How the app is actually wired (relevant facts)

- `UserHomeShell` and `AdminShell` each host their three tabs in an `IndexedStack`, built from a
  `static const` widget list. This means **all three tabs' `BlocProvider`s (and therefore their
  Cubits) are created once, eagerly, when the shell first mounts, and kept alive for the entire
  time the shell is on screen** — switching tabs never recreates them. This is correct and
  intentional (it's what makes tab state/scroll position survive switching), but it also means a
  write that happens in a *different* part of the tree (a pushed route, or a sibling tab) does
  not automatically reach an already-mounted sibling Cubit unless something explicitly tells it to.
- `ParticipationRepository.createParticipation()` and `GiveawayRepository.createGiveaway()`
  already invalidate their own Hive cache entries on success. That part of the pipeline is
  correct. The gap is downstream of the cache: invalidating a Hive entry does **not** push new
  data into a Cubit that already loaded once and is just sitting in `state.loaded` — nothing was
  telling those already-mounted Cubits to re-fetch.
- A previous pass added Supabase Realtime subscriptions to `MyGiveawaysCubit` and
  `GiveawayAnalyticsCubit`. Realtime is correct and necessary for cross-device sync, but it is a
  network round-trip (client → Postgres → logical replication → Realtime server → WebSocket back
  to the client). For an operation the *same device* just performed and already has a confirmed
  success response for, waiting on that round trip is unnecessary latency and, per this task's
  explicit guidance, the wrong primary mechanism — local operations should update local state
  immediately, with realtime reserved for changes originating elsewhere.
- `AdminDashboardCubit.load()` fetches **every** giveaway the admin owns
  (`getMyAdminGiveaways()`, always live/uncached by design) but then throws away everything except
  the `active` subset before exposing it as `activeCampaigns` — `finishedCount` is kept only as an
  `int`, never as a list. There was no realtime or local-stream subscription on this cubit at all
  before this pass.
- `SplashCubit.bootstrap()` only ever routes to `SplashDestination.userHome` when
  `cachedLastRole == 'user'`. There is no `'admin'` branch, and — separately —
  `AdminAuthCubit`/`AdminAuthPage` never call `SecureStorageService.saveLastRole('admin')` on a
  successful sign-in/sign-up. So even a change to `SplashCubit` alone would have nothing to read.
  `AdminProfilePage`'s sign-out also never calls `clearLastRole()` (unlike the User-side
  `SettingsPage`, which already does), so an explicit admin sign-out would leave a stale
  `'admin'` role cached.

## Bug 1 — My Giveaways doesn't show a new participation without a manual refresh

**Root cause:** `MyGiveawaysCubit` is created once at `UserHomeShell` mount and kept alive by the
`IndexedStack`. `ParticipationCubit` (in a *different*, pushed route) creates the participation and
invalidates the Hive cache, but nothing tells the already-mounted `MyGiveawaysCubit` to re-fetch.
The existing Realtime subscription *should* eventually catch the `participations` INSERT and
reload, but that's a network round trip for an action this exact device just performed and already
knows succeeded — not "immediate," and not what the task asks for as the primary mechanism.

**Affected files:** `lib/shared/repositories/participation_repository.dart`,
`lib/features/my_giveaways/presentation/bloc/my_giveaways_cubit.dart`.

**Fix:** Add a broadcast stream to `ParticipationRepository`
(`Stream<Participation> get participationCreated`) that fires the moment `createParticipation()`
gets a confirmed success response (right after the existing cache invalidation). `MyGiveawaysCubit`
subscribes to it and calls `load(forceRefresh: true)` immediately — no debounce, since it's a
single deterministic local event, not a burst. The existing Realtime subscription is left in place
unchanged, so cross-device/background updates still work exactly as before.

**Why safe:** Purely additive — a new `Stream` on an existing repository (same Repository pattern,
no new architecture), one new `StreamSubscription` in an existing Cubit, cancelled in `close()`.
No existing method signature changes, no cache behavior changes.

**How tested:** Cubit test asserting `load(forceRefresh: true)` runs when
`participationCreated` emits, without needing any Realtime plumbing in the test.

## Bug 2 — Admin Analysis tab doesn't reflect a just-created giveaway

**Root cause:** Same shape as Bug 1, on the Admin side, in the *other* direction than expected.
`AdminDashboardPage`'s own FAB already explicitly reloads `AdminDashboardCubit` after a successful
`CreateGiveawayPage` push+pop — that path already worked. The sibling **Analysis tab**
(`AdminAnalysisCubit`), kept alive in the same `AdminShell` `IndexedStack`, has no such call and no
Realtime subscription at all, so switching to it after creating a giveaway shows stale totals until
a manual pull-to-refresh.

**Affected files:** `lib/shared/repositories/giveaway_repository.dart`,
`lib/shared/repositories/winner_repository.dart`,
`lib/features/admin_dashboard/presentation/bloc/admin_dashboard_cubit.dart`,
`lib/features/admin_dashboard/presentation/admin_dashboard_page.dart`,
`lib/features/admin_analysis/presentation/bloc/admin_analysis_cubit.dart`.

**Fix:** Same broadcast-stream pattern: `GiveawayRepository.giveawayCreated` and
`WinnerRepository.winnerSelected` streams, fired on confirmed success. Both
`AdminDashboardCubit` and `AdminAnalysisCubit` subscribe to both streams and reload. The FAB's
now-redundant manual `.load()` call is removed (the cubit reloading itself via the stream is the
single source of truth, avoiding a duplicate network request). Both cubits additionally get a
Realtime subscription to `giveaways` (INSERT+UPDATE, filtered to `created_by = eq.<adminId>`) for
genuine cross-device admin sync (e.g. the admin signed in on a second device), matching the
pattern already used for `giveaway_analytics`/`my_giveaways`.

**Why safe:** Same reasoning as Bug 1 — additive streams, no changed method signatures. Removing
the FAB's manual reload is safe because the stream now covers exactly that case (and more).

**How tested:** Cubit tests for both `AdminDashboardCubit` and `AdminAnalysisCubit` asserting a
reload on `giveawayCreated`/`winnerSelected` events, plus a realtime-lifecycle test mirroring the
existing pattern used for `GiveawayAnalyticsCubit`/`MyGiveawaysCubit`.

## Bug 3 — A giveaway disappears from Admin Home once it ends

**Root cause:** Not a deletion, not a cache bug, not a query filtering the database — confirmed
live that `fn_select_winner` only ever sets `status = 'ended'` and never deletes anything, and
`getMyAdminGiveaways()` fetches every giveaway the admin owns regardless of status. The bug is
purely client-side: `AdminDashboardCubit.load()` computes `active` and immediately discards
everything that isn't, so an ended giveaway has no card to render on Admin Home even though the
underlying data (and the per-giveaway Analytics screen) is fully intact.

**Affected files:** `lib/features/admin_dashboard/presentation/bloc/admin_dashboard_state.dart`,
`admin_dashboard_cubit.dart`, `admin_dashboard_page.dart`.

**Fix:** Expose a second list, `endedCampaigns`, alongside the existing `activeCampaigns`. Add an
"Ended Campaigns" section to Admin Home below Active Campaigns, reusing the same card component
(generalized to accept a status and show an Active/Ended badge, mirroring the badge pattern already
used on the User-side My Giveaways cards and Giveaway Analytics) — tapping through to the same
existing `GiveawayAnalyticsPage`, which already shows full winner details. No new screen.

**Why safe:** Additive state field, additive UI section using the existing card's visual language.
Nothing is hidden or removed; `activeCampaigns` keeps its exact previous meaning for any other
code that reads it.

**How tested:** Cubit test asserting an ended giveaway appears in `endedCampaigns` and not in
`activeCampaigns`. Widget-level assertion that the "Ended Campaigns" section renders and is
reachable.

## Bug 4 — Role (User/Admin) not restored after app restart

**Root cause:** Two separate gaps. (a) `AdminAuthCubit`/`AdminAuthPage` never call
`saveLastRole('admin')` on successful sign-in/sign-up — nothing is ever persisted for the admin
case, only for User (`RoleSelectionPage._continueAsUser`). (b) Even if it were persisted,
`SplashCubit.bootstrap()` has no branch that checks for `'admin'` at all — it only ever routes to
`userHome` or falls through to `roleSelection`.

**Affected files:** `lib/features/splash/presentation/cubit/splash_cubit.dart`,
`lib/features/splash/presentation/cubit/splash_state.dart`,
`lib/features/splash/presentation/splash_page.dart`,
`lib/features/admin_auth/presentation/admin_auth_page.dart`.

**Fix:** `AdminAuthPage`'s success listener now also calls
`getIt<SecureStorageService>().saveLastRole('admin')` before navigating (mirrors the User side).
`SplashState` gains `SplashDestination.adminShell`; `SplashCubit.bootstrap()` gains an explicit
`lastRole == 'admin'` branch that checks `AuthRepository.currentSession` is non-null and
non-anonymous (i.e. a real admin session, not the shared anonymous one) before routing to
`AdminShell` — if the session is gone/invalid, the stale `'admin'` role is cleared and the app
falls through to Role Selection, satisfying "only show Role Selection when... session is invalid
and role cannot be restored." `SplashPage` gains the matching `AdminShell` branch.

**Why safe:** `ensureAnonymousSession()` (called unconditionally at the top of
`UserIdentityService.restoreAndVerify()`, which Splash always runs first) only acts when there is
**no** session at all — if Supabase already restored an admin session, it's returned as-is,
untouched. So running the identity-restore step before checking for an admin role is safe and
doesn't clobber a persisted admin session.

**How tested:** `SplashCubit` tests for: admin role + valid session → `adminShell`; admin role +
no/anonymous session → `roleSelection` (and the stale role is cleared); user role (existing
behavior, unchanged); no role → `roleSelection`.

## Bug 5 (audit, no code bug found) — Sign-out semantics

Reviewed both sign-out paths against the requirement ("participation history and anonymous
identity must survive a User sign-out; Admin sign-out must not touch the User's data"):

- **User sign-out** (`SettingsPage._signOut`) already only calls
  `SecureStorageService.clearLastRole()` — it does not touch `cachedUserId`/identity, does not sign
  out of Supabase Auth (the anonymous session is the RLS identity chain participation history
  depends on), and does invalidate the FCM token server-side. This already matches the
  requirement; no change needed.
- **Admin sign-out** (`AdminProfilePage._signOut`) only called `AuthRepository.signOut()`
  (`_client.auth.signOut()`), which destroys the admin's own email/password session — it has zero
  interaction with `cachedAnonymousRefreshToken`, `cachedUserId`, or any User-side data, so it
  cannot regress User identity/history. The gap here was purely the missing `clearLastRole()` call
  (folded into Bug 4's fix), not a data-safety issue.

No changes were needed beyond adding the missing `clearLastRole()` call to Admin sign-out.

## Realtime & cache audit (Phase 6/7)

- No duplicate-subscription risk found in the existing `GiveawayAnalyticsCubit`/`MyGiveawaysCubit`/
  `UserHomeShell` realtime code — each already guards re-subscription (`if (_channel != null)
  return`) and tears its channel(s) down in `close()`/`dispose()`. The new Admin subscriptions
  added in this pass follow the identical guard/dispose pattern.
- No cache entry is ever globally cleared anywhere in this pass — every invalidation introduced
  is a single targeted key (`myParticipations(uid)`, `giveawayList`, `giveawayDetails(id)`), and
  all of it reuses `CacheService.invalidate`, which already existed.
- No polling was introduced anywhere. Every new "immediate update" path is a local, in-process
  broadcast stream fired directly by the confirmed-success code path — not a timer.
