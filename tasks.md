# Creative Rewards Redesign — Execution Checklist

Companion to [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) (referenced below as **Plan §n**). The screen ids S01–S38, decisions D-01–D-16 and risks R-01–R-13 are defined there.

> **Status: IN PROGRESS.** A separate local redesign demo has been implemented and verified in part; the checklist below remains largely open. See `docs/redesign-demo-status.md` for current evidence and gaps.
> This file replaces the legacy `tasks.md` roadmap (Windows file names are case-insensitive). The old content is still available with `git show HEAD:tasks.md`.

## Conventions
- **Priority**: P0 = required for the demo to function or be safe. P1 = required for reference fidelity or completeness. P2 = polish or optional.
- **Phase**: 0–15 as in Plan §36. A task may start only after its dependencies are checked **and** the previous phase's `GATE` is checked.
- **Verification** shorthands: `analyze` = `flutter analyze` with 0 issues; `format` = `dart format --output=none --set-exit-if-changed .`; `test:<path>` = `flutter test <path>` green; `golden` = golden test in `test/golden/redesign/`; `emu` = manual check on the Android emulator in demo mode with notes added to the PR.
- When you tick a box, append ` — verified <date>: <one-line evidence>`.
- Global rules that apply to **every** task: no Supabase imports in new feature code; every string goes through the ARB files (en + ar); directional layout only (`EdgeInsetsDirectional` and friends); no dead buttons; never call `SecureStorageService.clearAll()`; do not change the package id, signing, version or AdMob ids. Redesign the splash to match the new reference.

---

## Phase 0 — Repository Audit

### AUD-001 — Commit and tag the current baseline
- [ ] Ask the user to commit or stash the ~120 uncommitted changes, then create tag `pre-redesign-baseline`. Do not do this without the user's approval (Plan §2.3, R-01).
- **Priority:** P0 · **Phase:** 0 · **Depends on:** —
- **Files:** git only
- **Expected result:** `git status` is clean on a redesign branch (`feature/redesign-demo`) created from the tag.
- **Acceptance:** The tag exists and the branch is clean.
- **Verify:** `git status`, `git tag -l pre-redesign-baseline`.

### AUD-002 — Record baseline analyze, test and golden state
- [ ] Run `flutter pub get`, `analyze`, `format`, `flutter test`. Record the pass/fail counts in the PR description. Re-baseline `test/golden/goldens/role_selection_*.png` if the existing failures in `test/golden/failures/` are only stale images (confirm by viewing the diff images first).
- **Priority:** P0 · **Phase:** 0 · **Depends on:** AUD-001
- **Files:** `test/golden/**`
- **Expected result:** A known-green baseline, or a documented list of pre-existing failures.
- **Acceptance:** Every failure is either fixed as a stale golden or listed with a reason.
- **Verify:** Test output attached to the PR.

### AUD-003 — Verify the screen and route inventory
- [ ] Walk every `MaterialPageRoute`/`push` in `lib/` (`grep -rn "MaterialPageRoute\|showModalBottomSheet\|showDialog" lib`) and confirm Plan §6 lists E01–E28 completely. Add anything that is missing to Plan §6.
- **Priority:** P0 · **Phase:** 0 · **Depends on:** AUD-001
- **Files:** `IMPLEMENTATION_PLAN.md` §6 (only if something is missing)
- **Expected result:** The inventory matches the code.
- **Acceptance:** Every push/dialog site maps to an E-id.
- **Verify:** The grep output is reviewed against §6.

### AUD-004 — Capture splash and current-UI baseline screenshots
- [ ] On the emulator, record the first 3 s of the splash (screenshots at 0.5 s / 1.5 s / 2.5 s) and one screenshot of each current user screen (E01–E19). Save them to `docs/screenshots/baseline/`.
- **Priority:** P0 · **Phase:** 0 · **Depends on:** AUD-001
- **Files:** `docs/screenshots/baseline/*.png`
- **Expected result:** A reference set for redesigned splash and other visual comparisons.
- **Acceptance:** The splash frames and E01–E19 screenshots exist.
- **Verify:** Files are present.

### AUD-005 — Resolve or accept the default for each blocking decision
- [ ] Present D-01, D-03, D-04, D-05, D-07, D-09, D-10 and D-12 to the user. Record each answer, or "default accepted", in Plan Appendix A.
- **Priority:** P0 · **Phase:** 0 · **Depends on:** —
- **Files:** `IMPLEMENTATION_PLAN.md` Appendix A
- **Expected result:** Every decision has an owner-confirmed value.
- **Acceptance:** No blank rows in Appendix A.
- **Verify:** Review of the Appendix A diff.

### GATE-0 — Audit complete
- [ ] AUD-001 to AUD-005 are done. The baseline is known. Decisions are recorded.

---

## Phase 1 — Architecture Preparation

### ARCH-001 — AppEnvironment with DATA_MODE and production guard
- [ ] Create `AppEnvironment` (`DataMode {demo, api}`, `AppFlavorEnv {dev, prod}`, `isDemo`, `isMisconfigured`, `fromDefines()`) as specified in Plan §15.1. In dev, unknown `DATA_MODE` values fall back to demo. In prod, an unknown value counts as misconfigured.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** GATE-0
- **Files:** `lib/core/config/app_environment.dart`, `test/core/config/app_environment_test.dart`
- **Expected result:** A single injectable source of truth for the mode.
- **Acceptance:** All four combinations behave as in the table. No other file calls `String.fromEnvironment('DATA_MODE')`.
- **Verify:** `test:test/core/config/`; `grep -rn "DATA_MODE" lib` returns only this file.

### ARCH-002 — Misconfigured-build blocker (S38) and startup wiring
- [ ] Add a standalone `MisconfiguredBuildApp` widget. In `main.dart`, build `AppEnvironment` first. If it is misconfigured, call `runApp(MisconfiguredBuildApp())` and skip DI, Firebase and ads.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-001
- **Files:** `lib/features/misconfigured/misconfigured_build_app.dart`, `lib/main.dart`
- **Expected result:** A prod+demo build cannot reach any demo code.
- **Acceptance:** The widget test renders the blocker. No `getIt` registrations exist in that path.
- **Verify:** `test:test/features/misconfigured/`.

### ARCH-003 — Core value models: LocalizedText, ImageRef, Clock
- [ ] Implement `LocalizedText` (with en fallback), sealed `ImageRef` (`asset`/`url` plus a JSON parse that also accepts `asset:` URI strings), and `Clock` (`SystemClock`, `FixedClock`).
- **Priority:** P0 · **Phase:** 1 · **Depends on:** GATE-0
- **Files:** `lib/domain/models/localized_text.dart`, `lib/domain/models/image_ref.dart`, `lib/core/utils/clock.dart`, tests
- **Expected result:** Primitive types that all other models use.
- **Acceptance:** Unit tests cover fallback, parsing and equality.
- **Verify:** `test:test/domain/models/`.

### ARCH-004 — Account and character models
- [ ] Add `AppUser`, `Character`, `AuthSession`, `OtpTicket`, `OtpPurpose`, `OtpRequestReceipt` and `SessionRestore` (sealed: none / expired(email) / active(session)).
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-003
- **Files:** `lib/domain/models/{app_user,character,auth_session,otp,session_restore}.dart`
- **Expected result:** Equatable and immutable models with `copyWith`. No password field anywhere.
- **Acceptance:** `grep -rni "password" lib/domain/models` finds nothing.
- **Verify:** Unit tests plus the grep.

### ARCH-005 — Catalog models
- [ ] Add `Category`, `ProductGroup`, `RewardProduct`, `ProductAvailability` and `CatalogSearchResult`, with the fields listed in Plan §16.1.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-003
- **Files:** `lib/domain/models/{category,reward_product,catalog_search_result}.dart`
- **Expected result:** Catalog data is fully expressible without widget constants.
- **Acceptance:** Gradients are stored as hex strings and parsed by a tested helper.
- **Verify:** Unit tests.

### ARCH-006 — Wallet and ledger models
- [ ] Add `WalletBalance`, `PointsTransaction` and `PointsReason` (`demoGrant`, `redemption`, `redemptionRefund`, `referralReward`, `adjustment`).
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-003
- **Files:** `lib/domain/models/{wallet_balance,points_transaction}.dart`
- **Expected result:** Ledger primitives.
- **Acceptance:** A balance helper `sumLedger()` is unit-tested, including negative and refund cases.
- **Verify:** Unit tests.

### ARCH-007 — Order models
- [ ] Add `RedemptionOrder`, `OrderStatus`, `OrderStatusEvent` and the product snapshot.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-005
- **Files:** `lib/domain/models/redemption_order.dart`
- **Expected result:** Orders keep a snapshot of the product at redemption time.
- **Acceptance:** JSON round-trip tests pass.
- **Verify:** Unit tests.

### ARCH-008 — Giveaway entry, display status and referral models
- [ ] Add a `GiveawayDisplayStatus` extension on the existing `Giveaway` (scheduled→upcoming, active→available, ended/archived→ended); `GiveawayEntry {participation, giveaway, isDemo}`; `WinCelebration`; `Referral`. Fix number formatting so it is digit-width aware: add `formatParticipationNumber(int, width)` and use it in place of the hard-coded `padLeft(4)` (in `Participation.formattedNumber`, `NumberRevealPage`, `GiveawayDetailsCta`, `EligibleParticipant`, `Winner`). The existing default width of 4 is preserved.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-003
- **Files:** `lib/domain/models/{giveaway_display,giveaway_entry,referral}.dart`, `lib/shared/models/participation.dart`, call sites
- **Expected result:** Existing models are reused and the number formatting is correct for widths 4–6.
- **Acceptance:** Existing tests are still green. New tests cover widths 4, 5 and 6.
- **Verify:** `flutter test`.

### ARCH-009 — New Failure types and l10n mapping
- [ ] Append the failures from Plan §16.3 to `failure.dart`. Extend the failure→message helper. Add EN/AR ARB strings for each.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** GATE-0
- **Files:** `lib/core/error/failure.dart`, failure-message helper (locate it with `grep -rn "failureNoInternet" lib`), `lib/l10n/app_*.arb`
- **Expected result:** Every new failure has a localised message.
- **Acceptance:** A test iterates all failure types and asserts a non-empty message in both locales.
- **Verify:** `test:test/core/error/`.

### API-001 — Prepare VPS-ready repository contracts
- [ ] Define the backend-independent interfaces exactly as in Plan §16.2: `OtpVerifier`, `AuthGateway`, `SessionRepository`, `AccountRepository`, `CharacterRepository`, `CatalogRepository`, `WalletRepository`, `OrderRepository`, `GiveawayFeedRepository`, `GiveawayEntryRepository`, `InboxRepository`, `ReferralRepository`, `PushTokenSink`.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-004 to ARCH-008
- **Files:** `lib/domain/repositories/*.dart`
- **Expected result:** Contracts with no imports from `supabase_flutter`, `http`, `hive` or `lib/data/**`.
- **Acceptance:** Mock repositories can later be replaced without changing screen layouts. The import check passes.
- **Verify:** `grep -rn "import" lib/domain/repositories` shows only `domain`, `core/error` and `shared/models` imports.

### ARCH-010 — Shared contract test suites
- [ ] For each contract, write `test/contracts/<name>_contract.dart` exposing `void run<Name>Contract(Factory create)`. Each suite covers the behaviours in Plan §15–§27 (balance consistency, redemption idempotency, entry uniqueness, inbox unread counts, and so on).
- **Priority:** P0 · **Phase:** 1 · **Depends on:** API-001
- **Files:** `test/contracts/*.dart`
- **Expected result:** Reusable suites that the demo implementations run now and the HTTP implementations run later.
- **Acceptance:** Every contract method is exercised at least once.
- **Verify:** The suites are invoked by the demo implementation tests (ARCH-013 to ARCH-019).

### ARCH-011 — DemoStore persistence layer
- [ ] Implement `DemoStore` on the Hive box `demo_store_v1`: collections, `transaction()` with a single `putAll`, a `changes` stream, `reset()`, schema version with wipe-on-mismatch, and the construction guard (throws unless demo).
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-001, ARCH-003
- **Files:** `lib/data/demo/demo_store.dart`, `test/data/demo/demo_store_test.dart`
- **Expected result:** A single persisted source for user-generated demo state, separate from `app_cache_v1`.
- **Acceptance:** Tests cover transaction atomicity (an exception mid-transaction leaves no partial writes), persistence across re-open, reset, and the guard throwing in api/prod.
- **Verify:** `test:test/data/demo/` using a Hive temp dir.

### ARCH-012 — Demo seed data
- [ ] Encode the seed exactly as in Plan §15.3: 9 characters, 6 categories with groups and products, 6 giveaways with relative dates, requirements, the preloaded `demo@example.com` account history (balance 6,000, 2 orders), 3 inbox items, and the "taken numbers" sets. All text is `LocalizedText` en + ar. Image refs point at the Plan §14.2 asset paths.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-005 to ARCH-008
- **Files:** `lib/data/demo/seed/{demo_characters,demo_catalog,demo_giveaways,demo_account,demo_inbox}.dart`
- **Expected result:** Realistic, coherent mock data in one place.
- **Acceptance:** A test asserts there are no empty `ar` strings, prices are positive, the slugs are unique, the referenced asset paths exist (after Phase 3; skipped until then via a tag), and the preloaded balance is 6,000.
- **Verify:** `test:test/data/demo/seed_test.dart`.

### ARCH-013 — Demo auth, session and account repositories
- [ ] Implement `DemoAuthGateway`, `DemoSessionRepository` (secure storage key `demo_session_v1`, 30-day expiry, `expireNow`), `DemoAccountRepository` and `DemoCharacterRepository`, following Plan §16.4 and §18. New accounts get the +6,000 `demoGrant`. The password is never stored.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-011, ARCH-012, ARCH-010
- **Files:** `lib/data/demo/demo_{auth_gateway,session_repository,account_repository,character_repository}.dart`, tests
- **Expected result:** A working local account lifecycle.
- **Acceptance:** The contract suites pass. After registration, a scan of the Hive box and of secure storage finds no password value.
- **Verify:** `test:test/data/demo/`.

### ARCH-014 — DemoOtpVerifier
- [ ] Implement as in Plan §18.2: any `^\d{6}$` code is accepted (after normalising Arabic-Indic digits); `000000` returns expired; 30 s resend; rate limit of 5 requests per 10 minutes; 10-minute ticket; the constructor guard.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-001, ARCH-004
- **Files:** `lib/data/demo/demo_otp_verifier.dart`, `test/data/demo/demo_otp_verifier_test.dart`
- **Expected result:** Realistic demo OTP behaviour.
- **Acceptance:** Table tests (`123456` ok, `٤٧٣٩٢١` ok, `12345` invalid, `12a456` invalid, `000000` expired, rate limit) pass. The constructor throws for prod or api environments.
- **Verify:** Tests.

### ARCH-015 — Demo catalog repository with search
- [ ] Implement `DemoCatalogRepository` over the seed, with `DemoLatency` (0 in tests). Search is case- and diacritic-insensitive over en and ar titles, subtitles and denominations.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-012
- **Files:** `lib/data/demo/demo_catalog_repository.dart`, `lib/data/demo/demo_latency.dart`, tests
- **Expected result:** A queryable mock catalog.
- **Acceptance:** The contract suite passes, and searching "uc" or "يو سي" finds the PUBG products.
- **Verify:** Tests.

### ARCH-016 — Demo wallet and order repositories with atomic redemption
- [ ] Implement `DemoWalletRepository` (balance derived from the ledger, `watchBalance` emits on change) and `DemoOrderRepository.redeem` (one transaction: re-check the balance, write the ledger entry, the order and the inbox item; `requestId` idempotency; `InsufficientPointsFailure`, `ProductUnavailableFailure`, `InvalidAccountIdentifierFailure`).
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-011, ARCH-015
- **Files:** `lib/data/demo/demo_{wallet,order}_repository.dart`, tests
- **Expected result:** A consistent points economy.
- **Acceptance:** Tests: redeem 1,200 from 6,000 leaves 4,800 and 1 order; redeem 10,000 fails with nothing written; the same `requestId` twice produces 1 order; 2 different requests submitted concurrently cannot overdraw.
- **Verify:** Tests.

### ARCH-017 — Demo giveaway feed and entry repositories
- [ ] Implement `DemoGiveawayRepository` (implements both `GiveawayFeedRepository` and `GiveawayEntryRepository`) as in Plan §24.3: eligibility order, secure random unique numbers within the digit width, participant overlay, inbox item, cosmetic-frame passthrough to `RewardFrameEntitlementStore` (keyed by the demo user id), and pending-win celebration records.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-011, ARCH-012
- **Files:** `lib/data/demo/demo_giveaway_repository.dart`, `lib/services/reward_frame_entitlement_store.dart` (accept a user-id provider), tests
- **Expected result:** Local participation that follows the product rules.
- **Acceptance:** Tests: 1,000 entries across fake users are unique and within range; duplicate, full, ended and not-started each return the correct failure; the ledger is untouched.
- **Verify:** Tests.

### ARCH-018 — Demo inbox repository
- [ ] Implement `DemoInboxRepository` (seed plus generated items, unread stream, mark read and mark all read).
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-011
- **Files:** `lib/data/demo/demo_inbox_repository.dart`, tests
- **Expected result:** Working notifications data.
- **Acceptance:** The contract suite passes.
- **Verify:** Tests.

### ARCH-019 — Demo referral repository and push sink
- [ ] Implement `DemoReferralRepository` (deterministic `CR-XXXXXX` code, the Play URL `https://play.google.com/store/apps/details?id=com.creativehub.rewardsapp`, `invitedCount` 0, localised message) and `NoopPushTokenSink`.
- **Priority:** P1 · **Phase:** 1 · **Depends on:** ARCH-011
- **Files:** `lib/data/demo/demo_referral_repository.dart`, `lib/data/demo/noop_push_token_sink.dart`, tests
- **Expected result:** Referral data with no point grants.
- **Acceptance:** The code is stable for a given user id. A test confirms the ledger has no `referralReward` entry ever.
- **Verify:** Tests.

### ARCH-020 — API-mode placeholders (no backend)
- [ ] Add the `ApiClient` interface (transport only, **no URLs and no endpoints**), the `ApiSessionStore` contract, and `Unavailable*Repository` for every contract (methods return `BackendUnavailableFailure`; streams emit an initial empty value).
- **Priority:** P0 · **Phase:** 1 · **Depends on:** API-001
- **Files:** `lib/data/api/api_client.dart`, `lib/data/api/api_session_store.dart`, `lib/data/api/unavailable/*.dart`
- **Expected result:** An api-mode build runs and shows unavailable states instead of crashing.
- **Acceptance:** No string literal resembling a URL or path exists under `lib/data/api/`.
- **Verify:** Unit tests; `grep -rnE "https?://|/api/" lib/data/api` is empty.

### ARCH-021 — Split dependency injection by mode
- [ ] Refactor `configureDependencies({AppEnvironment? environment})` into `_registerCore`, `_registerDemo` (inside `lib/data/demo/demo_module.dart`), `_registerApi` and `_registerLegacySupabase` (gated by D-01), as in Plan §15.6. `NotificationService` uses `PushTokenSink` in demo mode, so it no longer depends on Supabase there.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-013 to ARCH-020
- **Files:** `lib/core/di/injection.dart`, `lib/data/demo/demo_module.dart`, `lib/services/notification_service.dart`, `lib/main.dart`
- **Expected result:** Demo mode starts without initialising Supabase (unless D-01 says otherwise).
- **Acceptance:** A test calls `configureDependencies` for demo and for api and checks the registered implementation type of each contract. The app still launches.
- **Verify:** `test:test/core/di/injection_test.dart`; `emu` launch.

### ARCH-022 — SessionController and root navigator key
- [ ] Add `SessionController` (a `ValueNotifier<SessionState>` with `markExpired`, `signedIn` and `signedOut`), a global `navigatorKey` on `MaterialApp`, and a root listener that routes to S36 on expiry.
- **Priority:** P0 · **Phase:** 1 · **Depends on:** ARCH-013
- **Files:** `lib/core/session/session_controller.dart`, `lib/main.dart`
- **Expected result:** One source of auth state.
- **Acceptance:** Unit tests cover the transitions. A widget test shows that expiry pushes the S36 placeholder.
- **Verify:** Tests.

### ARCH-023 — AppRoutes helper
- [ ] Create typed route helpers (`toWelcome`, `toEmailEntry`, `toOtp`, `toCreatePassword`, `toCharacter`, `toMainShell`, `toCategoryDetails`, `toGiveawayDetails`, `toOrderDetails`, …) using a shared `RewardsPageRoute`.
- **Priority:** P1 · **Phase:** 1 · **Depends on:** ARCH-022
- **Files:** `lib/core/routing/app_routes.dart`, `lib/core/routing/rewards_page_route.dart`
- **Expected result:** One place where routes are constructed.
- **Acceptance:** New features use `AppRoutes` and not raw `MaterialPageRoute` (enforced by the architecture test in TEST-010).
- **Verify:** grep.

### GATE-1 — Architecture ready
- [ ] analyze and format are clean; all contract, demo and isolation tests are green; the app still launches with the old UI in demo mode, or a temporary placeholder home is shown and documented.

---

## Phase 2 — Design System

### DS-001 — Colour and gradient tokens
- [ ] Create `RewardsColors` with every token and gradient in Plan §12.1, plus the status-colour mapping helper.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** GATE-1
- **Files:** `lib/core/theme/rewards_colors.dart`
- **Expected result:** No hex literal is needed in feature code.
- **Acceptance:** The architecture test (TEST-010) flags `Color(0x` in `lib/features/{auth,shell,home,catalog,wallet,profile,orders,referral}/`.
- **Verify:** Test.

### DS-002 — Typography and Arabic font fallback
- [ ] Create `RewardsText` (Plan §12.2). Bundle the Arabic font chosen in D-12 (default IBM Plex Sans Arabic, weights 400/500/600/700, with the OFL licence file) under `assets/fonts/` and register it in pubspec. Apply `fontFamilyFallback`.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-001, AUD-005
- **Files:** `lib/core/theme/rewards_typography.dart`, `assets/fonts/IBMPlexSansArabic-*.ttf`, `assets/fonts/IBMPlexSansArabic-OFL.txt`, `pubspec.yaml`
- **Expected result:** Consistent Latin and Arabic typography.
- **Acceptance:** A golden of an Arabic sample shows the bundled font, not the system fallback.
- **Verify:** `golden`.

### DS-003 — Spacing, radius, shadow, motion and size tokens
- [ ] Create `RSpace`, `RRadius`, `RShadow`, `RMotion` (reduced-motion aware via `RMotion.of(context)`) and `RSize`.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** GATE-1
- **Files:** `lib/core/theme/rewards_tokens.dart`
- **Expected result:** Token-only layout values.
- **Acceptance:** `RMotion.of` returns zero durations when `disableAnimations` is set (unit test).
- **Verify:** Test.

### DS-004 — RewardsTheme and theme scoping
- [ ] Build `RewardsTheme.light` (`ThemeData`: colour scheme, input decoration theme, text theme, snackbar, bottom sheet, dialog). `MaterialApp.theme` switches to it. Admin entry points wrap their subtree in `Theme(data: AppTheme.light)` so the Admin area looks exactly as before.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-001 to DS-003
- **Files:** `lib/core/theme/rewards_theme.dart`, `lib/main.dart`, `lib/features/admin_dashboard/presentation/admin_shell.dart`, `lib/features/admin_auth/presentation/admin_auth_page.dart`
- **Expected result:** The new theme applies to the user app and the Admin area is visually unchanged.
- **Acceptance:** The existing admin widget tests pass, and an admin screenshot matches the AUD-004 baseline (if admin was captured).
- **Verify:** `flutter test test/widgets/admin_*`.

### DS-005 — Buttons
- [ ] Build `PrimaryPillButton`, `DarkPillButton`, `SecondaryButton` and `TextLink` (loading, disabled, trailing directional arrow, press scale, minimum height, semantics).
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-004
- **Files:** `lib/shared/ui/buttons.dart`, `test/widgets/redesign/ui/buttons_test.dart`
- **Expected result:** CTA styles that match the references.
- **Acceptance:** Tests show a disabled button never fires, the loading state blocks taps, and the arrow flips in RTL. Goldens exist in en and ar.
- **Verify:** Tests plus `golden`.

### DS-006 — RewardsTextField
- [ ] Build the field from Plan §12.4 (icon, floating label, password toggle with semantics, error, autofill hints, pill/search variant).
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-004
- **Files:** `lib/shared/ui/rewards_text_field.dart`, test
- **Expected result:** The single input component for all forms.
- **Acceptance:** The toggle changes `obscureText` and its semantics label. The error renders. Golden.
- **Verify:** Tests.

### DS-007 — OtpCodeInput
- [ ] Build six boxes backed by one hidden `TextField`: paste support, `AutofillHints.oneTimeCode`, digits only, Arabic-Indic normalisation, always LTR, error shake (reduced-motion aware), `onCompleted`.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-004
- **Files:** `lib/shared/ui/otp_code_input.dart`, test
- **Expected result:** Robust OTP entry.
- **Acceptance:** Tests cover pasting "473921", entering Arabic digits, backspace across boxes, and LTR order under an RTL locale.
- **Verify:** Tests.

### DS-008 — StepProgress
- [ ] Build the 4-segment progress bar with a current-step dot and the semantics "Step n of 4".
- **Priority:** P1 · **Phase:** 2 · **Depends on:** DS-004
- **Files:** `lib/shared/ui/step_progress.dart`
- **Expected result:** Matches the auth references.
- **Acceptance:** Golden for steps 1–4 in en and ar.
- **Verify:** `golden`.

### DS-009 — CircleIconButton with badges
- [ ] Build the 52 dp white circle button with an optional dot or count badge (capped at "9+"), a tooltip and semantics that include the unread count.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-004
- **Files:** `lib/shared/ui/circle_icon_button.dart`
- **Expected result:** Bell, back and gear buttons.
- **Acceptance:** Semantics read, for example, "Notifications, 2 unread".
- **Verify:** Widget test.

### DS-010 — AuroraBackground
- [ ] Draw the pastel radial-blob background with a `CustomPainter` inside a `RepaintBoundary`, with no `BackdropFilter`. Provide variants for auth, home, profile and plain.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-001
- **Files:** `lib/shared/ui/aurora_background.dart`
- **Expected result:** The reference ambience at low cost.
- **Acceptance:** Golden. No `BackdropFilter` in the file.
- **Verify:** `golden` plus grep.

### DS-011 — Cards and rows
- [ ] Build `GlassCard`, `MenuRow` (trailing value, badge, chevron, danger variant), `ActionRow` (tinted icon tile) and `StatStrip` (tappable, wraps at large text scale).
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-004
- **Files:** `lib/shared/ui/{cards,menu_row,action_row,stat_strip}.dart`
- **Expected result:** The building blocks for the Profile and Wallet screens.
- **Acceptance:** Goldens at text scale 1.0 and 2.0. Chevrons mirror in RTL.
- **Verify:** `golden`.

### DS-012 — CategoryBanner and CategoryTile
- [ ] Build data-driven gradient banners (aspect ratio 3.8:1, minimum height 96 dp, text at the start, art at the end, dark-text variant) and the rail tile.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-017
- **Files:** `lib/shared/ui/category_widgets.dart`
- **Expected result:** Matches `category-page.png` and the home rail.
- **Acceptance:** Golden using the seed categories in en and ar.
- **Verify:** `golden`.

### DS-013 — ProductCard, GiveawayCard and StatusChip
- [ ] Build `ProductCard` (image well, denomination, price, Redeem button, out-of-stock state), `GiveawayCard` (tint, chevron, status chip) and `StatusChip` (giveaway and order statuses).
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-017
- **Files:** `lib/shared/ui/{product_card,giveaway_card,status_chip}.dart`
- **Expected result:** Matches the category-details and home references.
- **Acceptance:** Goldens for every status.
- **Verify:** `golden`.

### DS-014 — SegmentedTabs
- [ ] Build the pill segmented control with tab semantics and keyboard focus, hidden when there is a single group.
- **Priority:** P1 · **Phase:** 2 · **Depends on:** DS-004
- **Files:** `lib/shared/ui/segmented_tabs.dart`
- **Expected result:** Matches the category-details reference.
- **Acceptance:** Selection callback test. Golden in RTL.
- **Verify:** Tests.

### DS-015 — PointsBalanceCard and CrownPainter; PointsHeader
- [ ] Build the wallet gradient card with the crown painter and the Home `PointsHeader` (no card). Both include an animated count-up and `FittedBox` scaling.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-001, DS-003
- **Files:** `lib/shared/ui/{points_balance_card,points_header}.dart`
- **Expected result:** Matches the wallet and home references.
- **Acceptance:** A balance of 9,999,999 does not overflow at 320 dp (test).
- **Verify:** Test plus `golden`.

### DS-016 — CharacterTile and CharacterAvatar
- [ ] Build the selectable tile (pastel background from data, 2.5 dp primary border and check badge when selected, semantics "Character n, selected") and the avatar (nav size 40 and profile size 168 variants, with ring).
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-017
- **Files:** `lib/shared/ui/character_widgets.dart`
- **Expected result:** Matches the character and profile references.
- **Acceptance:** Golden for the selected and unselected states.
- **Verify:** `golden`.

### DS-017 — AppImage
- [ ] Build the `ImageRef` renderer: asset or network via `cached_network_image`, `cacheWidth` decode sizing, shimmer placeholder, gradient-plus-glyph fallback, fade-in that respects reduced motion.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** ARCH-003, DS-001
- **Files:** `lib/shared/ui/app_image.dart`
- **Expected result:** Catalog widgets work with both bundled and remote images.
- **Acceptance:** Tests: an asset renders; a network error shows the fallback (fake HTTP overrides); null shows the fallback.
- **Verify:** Tests.

### DS-018 — State components
- [ ] Build `Skeleton`, `EmptyState`, `ErrorState` (with retry), `OfflineBanner` and `UnavailableNotice`.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-005
- **Files:** `lib/shared/ui/{skeleton,states}.dart`
- **Expected result:** Consistent loading, empty and error UI.
- **Acceptance:** Goldens. `ErrorState` retry fires its callback.
- **Verify:** Tests.

### DS-019 — Sheets, dialogs and feedback
- [ ] Build `RewardsSheet`, `RewardsDialog` (danger action variant) and `showRewardsSnack` (success, error, info).
- **Priority:** P0 · **Phase:** 2 · **Depends on:** DS-005
- **Files:** `lib/shared/ui/{sheets,feedback}.dart`
- **Expected result:** Unified modal patterns.
- **Acceptance:** Keyboard-safe sheet test at 320×568.
- **Verify:** Test.

### DS-020 — DemoBanner and DemoChip
- [ ] Build the demo indicators. They render nothing unless `AppEnvironment.isDemo`.
- **Priority:** P0 · **Phase:** 2 · **Depends on:** ARCH-001
- **Files:** `lib/shared/ui/demo_badge.dart`
- **Expected result:** Demo content is clearly marked.
- **Acceptance:** The test shows the indicator under demo and nothing under api.
- **Verify:** Test.

### DS-021 — Component gallery and component goldens
- [ ] Add a debug-only `ComponentGalleryPage`, reachable from Demo Tools later, plus one golden file per component group in en and ar.
- **Priority:** P2 · **Phase:** 2 · **Depends on:** DS-005 to DS-020
- **Files:** `lib/features/demo_tools/presentation/component_gallery_page.dart`, `test/golden/redesign/components_*`
- **Expected result:** A visual catalogue for review.
- **Acceptance:** Goldens are committed.
- **Verify:** `golden`.

### GATE-2 — Design system ready
- [ ] All components exist, are tested and have en and ar goldens. analyze and format are clean.

---

## Phase 3 — Asset Pipeline

### ASSET-001 — Verify image generation capability
- [ ] Run an end-to-end trial on **one** character (char_01), with the user's explicit approval of the credit cost: create a Figma file, call `generate_image` with the style lock from Plan §14.5, download `image.url` into the scratchpad, cut out the background (try the model's own alpha first, then Adobe `image_remove_background` after `adobe_mandatory_init`), process with PIL into a 512 px WebP with alpha. Record which steps worked, which model, the cost and the quality in Plan §13.
- **Priority:** P0 · **Phase:** 3 · **Depends on:** GATE-2
- **Files:** `IMPLEMENTATION_PLAN.md` §13 (results), scratchpad only for raw files
- **Expected result:** A verified workflow, or a documented failure.
- **Acceptance:** Capabilities are verified and the unavailable tools are documented. Nothing is batch-generated before this passes.
- **Verify:** Updated §13 table plus a contact-sheet screenshot.

### ASSET-002 — Prepare category artwork
- [ ] Generate brand-neutral banner (1520×400), tile (400×428) and hero (1290×780) images for pubg_mobile, valorant, instagram, tiktok, facebook and phones using Plan §14.5 prompts, **or** integrate the licensed brand art supplied by the user (D-09). Keep the text-safe region (left 55%) free of objects.
- **Priority:** P1 · **Phase:** 3 · **Depends on:** ASSET-001, ASSET-003
- **Files:** `assets/images/categories/*`
- **Expected result:** 18 consistent category images.
- **Acceptance:** Category artwork is consistent, optimised and registered. No official logo or character appears unless it was licensed and supplied by the user.
- **Verify:** Contact sheet reviewed by the user; `test:test/architecture/assets_test.dart`.

### ASSET-003 — Asset directories, registration and processing script
- [ ] Create the directories from Plan §14.1, register them in `pubspec.yaml`, and write `tool/assets/process_assets.py` (trim, pad, resize, WebP q82 with alpha, manifest check) and `tool/assets/compare_sheet.py` (side-by-side comparison against the references). Raw inputs stay in the scratchpad.
- **Priority:** P0 · **Phase:** 3 · **Depends on:** GATE-2
- **Files:** `pubspec.yaml`, `tool/assets/*.py`, `assets/images/**/.gitkeep`
- **Expected result:** A repeatable pipeline.
- **Acceptance:** The script processes a sample image to the exact target size. `flutter pub get` succeeds.
- **Verify:** Run the script on a test image.

### ASSET-004 — Nine consistent characters
- [ ] Generate char_02 to char_09 with the approved char_01 prompt structure (Plan §14.2 descriptions), then cut out, process and register them. Reject any image whose style drifts.
- **Priority:** P0 · **Phase:** 3 · **Depends on:** ASSET-001, ASSET-003
- **Files:** `assets/images/characters/char_0[1-9]_*.webp`
- **Expected result:** Nine visually consistent avatars at 512×512 with alpha.
- **Acceptance:** The user approves the 3×3 contact sheet. Each file is ≤ 120 KB.
- **Verify:** Contact sheet plus the size test.

### ASSET-005 — Product images
- [ ] Generate the 6 UC tier images (in increasing quantity), 3 VP images, 3 neutral "growth" images and 3 generic phone images (Plan §14.2).
- **Priority:** P1 · **Phase:** 3 · **Depends on:** ASSET-001, ASSET-003
- **Files:** `assets/images/products/*`
- **Expected result:** Product grid art.
- **Acceptance:** The tiers are visually ordered by quantity, the backgrounds are transparent, and each file is ≤ 80 KB.
- **Verify:** Contact sheet.

### ASSET-006 — Giveaway prize images
- [ ] Generate 6 generic product renders (earbuds, smartphone, console, coffee machine, smartwatch, headphones) at 640×640 with alpha.
- **Priority:** P1 · **Phase:** 3 · **Depends on:** ASSET-001, ASSET-003
- **Files:** `assets/images/giveaways/gw_*.webp`
- **Expected result:** Home grid art without brand-design copying.
- **Acceptance:** No logos. Each file is ≤ 100 KB.
- **Verify:** Contact sheet.

### ASSET-007 — Auth illustrations
- [ ] Generate `auth_email_hero`, `auth_otp_hero` and `auth_password_hero` in the same 3D pastel style as the references.
- **Priority:** P1 · **Phase:** 3 · **Depends on:** ASSET-001, ASSET-003
- **Files:** `assets/images/illustrations/auth_*.webp`
- **Expected result:** Illustrations for the email, OTP and password screens.
- **Acceptance:** They sit comfortably on the aurora background with alpha. Each file is ≤ 150 KB.
- **Verify:** Emulator screenshot.

### ASSET-008 — Empty and error state illustrations
- [ ] Generate the 6 state illustrations (orders, giveaways, notifications, search, offline, error).
- **Priority:** P1 · **Phase:** 3 · **Depends on:** ASSET-001, ASSET-003
- **Files:** `assets/images/illustrations/{empty_*,state_*}.webp`
- **Expected result:** Consistent empty and error states.
- **Acceptance:** They are all used by `EmptyState` and `ErrorState` call sites (grep).
- **Verify:** Contact sheet.

### ASSET-009 — Profile header decoration
- [ ] Use the user-supplied `profile_header_decor` or, as a fallback, generate it (a centre void for the avatar).
- **Priority:** P2 · **Phase:** 3 · **Depends on:** ASSET-010 or ASSET-001
- **Files:** `assets/images/illustrations/profile_header_decor.webp`
- **Expected result:** A header that matches the profile reference.
- **Acceptance:** The avatar never overlaps a decorative object at 320 or 430 dp.
- **Verify:** `emu` at both widths.

### ASSET-010 — Collect user-supplied assets
- [ ] Ask the user for: `onboarding_welcome_hero`; optionally `profile_header_decor` and wallet art (D-06); licensed brand kits, if any (D-09). Record the licence or source for each in the manifest table (Plan §14.2).
- **Priority:** P0 · **Phase:** 3 · **Depends on:** GATE-2
- **Files:** `assets/images/illustrations/*`, Plan §14.2
- **Expected result:** User art integrated, or the fallback is explicitly recorded.
- **Acceptance:** Every USER row has a status: received, pending (with the fallback named), or declined.
- **Verify:** Review of the manifest diff.

### ASSET-011 — Prompt pack fallback when generation is unavailable
- [ ] If ASSET-001 fails, or credits are not approved, finalise the prompt pack in Plan §14.5 with the exact per-asset prompts and sizes, hand it to the user, and mark each placeholder asset `placeholder` in the manifest. `AppImage` fallbacks are used meanwhile.
- **Priority:** P0 (conditional) · **Phase:** 3 · **Depends on:** ASSET-001
- **Files:** Plan §14.5, §14.2
- **Expected result:** No placeholder is presented as final artwork.
- **Acceptance:** Every placeholder row is flagged.
- **Verify:** Manifest review.

### ASSET-012 — Optimisation and asset budget test
- [ ] Add `test/architecture/assets_test.dart`: every pubspec asset directory exists; each seed `ImageRef.asset` path exists; the total size of `assets/images/**` is ≤ 6 MB; file names match `^[a-z0-9_]+\.webp$`.
- **Priority:** P0 · **Phase:** 3 · **Depends on:** ASSET-003
- **Files:** `test/architecture/assets_test.dart`
- **Expected result:** An enforced asset hygiene check.
- **Acceptance:** The test is green.
- **Verify:** `test:test/architecture/`.

### ASSET-013 — Fallback behaviour verification
- [ ] With an asset temporarily renamed in a test bundle, and with network failures injected, confirm that the catalog and giveaway widgets show the branded fallback rather than a broken image.
- **Priority:** P1 · **Phase:** 3 · **Depends on:** DS-017
- **Files:** `test/widgets/redesign/ui/app_image_fallback_test.dart`
- **Expected result:** Graceful image failures.
- **Acceptance:** The test is green.
- **Verify:** Test.

### GATE-3 — Assets ready
- [ ] The manifest is complete (final or flagged placeholder), the budget test is green and the user has approved the contact sheets.

---

## Phase 4 — Navigation and App Shell

### NAV-001 — Splash destination update (no visual change)
- [ ] Extend `SplashDestination` and `_resolveDestination` as in Plan §9.1 using `SessionRepository`. Keep `_SplashBody` byte-identical and keep the 3 s minimum. Keep the admin branch according to D-01.
- **Priority:** P0 · **Phase:** 4 · **Depends on:** GATE-3, ARCH-022
- **Files:** `lib/features/splash/presentation/cubit/{splash_cubit,splash_state}.dart`, `splash_page.dart` (the listener switch only), `test/features/splash/splash_cubit_test.dart`
- **Expected result:** New routing behind the same splash.
- **Acceptance:** `git diff` shows no change to `_SplashBody`. Cubit tests cover all destinations. Splash frames match AUD-004.
- **Verify:** Tests; `emu` frame comparison.

### NAV-002 — Session-aware routing glue
- [ ] Wire the destinations to pages: welcome → S02, characterOnboarding → S09 (onboarding), main → S10, sessionExpired → S36, misconfigured → S38. Clear the stack correctly every time.
- **Priority:** P0 · **Phase:** 4 · **Depends on:** NAV-001
- **Files:** `splash_page.dart`, `lib/core/routing/app_routes.dart`
- **Expected result:** Correct entry points.
- **Acceptance:** Widget tests show that pressing back from each entry point exits the app rather than returning to the splash.
- **Verify:** Tests.

### NAV-003 — MainShell with four tabs
- [ ] Create `MainShell` (an `IndexedStack` of Home, Categories, Wallet and Profile placeholders until their phases land) with `PageStorageKey`s, and app-scoped cubits (`CurrentUserCubit`, `WalletCubit`, `InboxCubit`, `OrdersCubit`, `EntriesCubit`) provided above it.
- **Priority:** P0 · **Phase:** 4 · **Depends on:** NAV-002
- **Files:** `lib/features/shell/presentation/main_shell.dart`, `lib/features/shell/presentation/bloc/*`
- **Expected result:** A four-tab app frame.
- **Acceptance:** Tab state and scroll position are preserved across switches (widget test).
- **Verify:** Test.

### NAV-004 — RewardsBottomNav with character avatar tab
- [ ] Build the flat nav from Plan §10.3 with labels and an underline indicator. The fourth item is the selected character's `CharacterAvatar` (it updates from `CurrentUserCubit`). Do not reuse `AppBottomNav`.
- **Priority:** P0 · **Phase:** 4 · **Depends on:** NAV-003, DS-016
- **Files:** `lib/shared/ui/rewards_bottom_nav.dart`, test
- **Expected result:** Navigation that matches the references.
- **Acceptance:** Changing the character updates the nav avatar without a restart. The semantic labels are Home, Categories, Wallet and Profile. The order mirrors in RTL. Goldens.
- **Verify:** Tests plus `golden`.

### NAV-005 — ShellCubit for programmatic tab switching
- [ ] Add `selectTab(ShellTab)` so children can switch tabs, and a helper that pops to the shell root and then selects a tab.
- **Priority:** P0 · **Phase:** 4 · **Depends on:** NAV-003
- **Files:** `lib/features/shell/presentation/bloc/shell_cubit.dart`
- **Expected result:** Cross-tab navigation (Wallet → Categories, Orders empty state → Categories).
- **Acceptance:** Unit plus widget tests.
- **Verify:** Tests.

### NAV-006 — Android back handling
- [ ] Use `PopScope` on the shell: from a non-Home tab, back goes to Home; from Home, the app is backgrounded. Pushed routes pop normally.
- **Priority:** P0 · **Phase:** 4 · **Depends on:** NAV-003
- **Files:** `main_shell.dart`
- **Expected result:** Predictable back behaviour.
- **Acceptance:** Widget tests simulate system back (`tester.binding.handlePopRoute()`).
- **Verify:** Tests.

### NAV-007 — Banner ad slot per D-05
- [ ] Dock `AdaptiveAdBanner` above the nav when D-05 keeps it, hide it when the keyboard is open, and move the `AdService.startUserSession` and `endUserSession` lifecycle from `UserHomeShell`. Goldens disable ads.
- **Priority:** P1 · **Phase:** 4 · **Depends on:** NAV-004
- **Files:** `main_shell.dart`, `lib/shared/widgets/ad_banner.dart` (unchanged API)
- **Expected result:** Ad behaviour is preserved.
- **Acceptance:** `test/widgets/shell_material_ancestor_test.dart` and its equivalents still pass. No ad loads in tests.
- **Verify:** Tests; `emu` shows a test banner.

### NAV-008 — Notification routing in the new shell
- [ ] Generalise `notification_routing.dart` to route by type (Plan §10.4) using contracts. Subscribe to `NotificationService.onNotificationTapped` and to the inbox celebration check in `MainShell`.
- **Priority:** P1 · **Phase:** 4 · **Depends on:** NAV-003, ARCH-018
- **Files:** `lib/shared/utils/notification_routing.dart`, `test/shared/notification_routing_test.dart`
- **Expected result:** Every notification type has a destination.
- **Acceptance:** A table test of type to route passes.
- **Verify:** Test.

### NAV-009 — Admin entry handling per D-01
- [ ] Implement the D-01 outcome. Default: no admin entry in demo builds; Role Selection is no longer reachable from the user path; the admin restore branch only runs when the legacy module is registered.
- **Priority:** P1 · **Phase:** 4 · **Depends on:** NAV-001, AUD-005
- **Files:** `splash_cubit.dart`, `lib/core/di/injection.dart`
- **Expected result:** Admin access is deliberate, not accidental.
- **Acceptance:** Tests cover lastRole=admin under demo (goes to Welcome) and under api with legacy enabled (goes to AdminShell).
- **Verify:** Tests.

### GATE-4 — Shell ready
- [ ] The splash matches its new reference, routing and tab tests are green, and the avatar tab works.

---

## Phase 5 — Registration and Authentication Demo

### AUTH-001 — Implement demo registration coordinator
- [ ] Create `RegistrationCubit`, which supports Email → OTP → Password → Character → Home with the state, back rules and no-password-in-state guarantee from Plan §8.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** GATE-4
- **Files:** `lib/features/auth/presentation/bloc/registration_cubit.dart`, `registration_state.dart`, test
- **Expected result:** One orchestrator for onboarding.
- **Acceptance:** All steps navigate in the required order. Changing the email resets OTP verification. Back is blocked at the character step.
- **Verify:** bloc_test plus widget and integration tests (AUTH-015).

### AUTH-002 — Implement demo-only OTP validation
- [ ] Wire `OtpVerifier` (ARCH-014) into the OTP step, with the DemoBanner hint and the `000000` expired demonstration.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** AUTH-001, ARCH-014
- **Files:** `registration_cubit.dart`, `otp_page.dart`
- **Expected result:** Any 6-digit code works in the explicit demo environment.
- **Acceptance:** Demo OTP works. A production OTP bypass is impossible (AUTH-014).
- **Verify:** Environment isolation tests.

### AUTH-003 — Welcome page (S02)
- [ ] Build it per Plan Appendix B S02 and the welcome reference.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** AUTH-001, DS-005, DS-010
- **Files:** `lib/features/auth/presentation/welcome_page.dart`, test, goldens
- **Expected result:** Matches `welcome-page.png`.
- **Acceptance:** Get Started → S06; Login → S03; goldens in en and ar at 320 and 393.
- **Verify:** Tests; `emu` comparison.

### AUTH-004 — Email entry page (S06)
- [ ] Build it per S06: validation, the already-registered branch, rate-limit feedback, keyboard safety.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** AUTH-001, DS-006, DS-008
- **Files:** `email_entry_page.dart`, test, goldens
- **Expected result:** Matches `signin-page.png`.
- **Acceptance:** Invalid emails are blocked with a message. A valid email goes to S07 showing the same address. A registered email offers "Log in instead".
- **Verify:** Tests.

### AUTH-005 — OTP page (S07) with resend timer
- [ ] Build it per S07: auto-verify, a Verify button, a countdown from 00:30, resend, error states, reset mode.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** AUTH-002, DS-007
- **Files:** `otp_page.dart`, test, goldens
- **Expected result:** Matches `otp-page.png`.
- **Acceptance:** The countdown reaches 0 and resend restarts it (fakeAsync). The timer is cancelled on dispose (no pending timers in tests).
- **Verify:** Tests.

### AUTH-006 — Create password page (S08) with rules
- [ ] Build it per S08 and Plan §18.3 (live rules, confirm match, toggles, common-password list, register and reset modes).
- **Priority:** P0 · **Phase:** 5 · **Depends on:** AUTH-001, DS-006
- **Files:** `create_password_page.dart`, `lib/features/auth/domain/password_rules.dart`, `common_passwords.dart`, tests
- **Expected result:** Matches `create-password-page.png`.
- **Acceptance:** The rule table tests pass. The CTA is enabled only when all rules pass and the fields match.
- **Verify:** Tests.

### AUTH-007 — Choose Character page (S09)
- [ ] Build it per S09 in onboarding and change modes, with back blocked in onboarding and image precaching.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** AUTH-001, DS-016, ASSET-004
- **Files:** `lib/features/character/presentation/choose_character_page.dart`, `bloc/character_cubit.dart`, tests, goldens
- **Expected result:** Matches `character-page.png` with 9 characters.
- **Acceptance:** The selection persists across a relaunch and shows in the nav avatar and profile header.
- **Verify:** Tests plus integration.

### AUTH-008 — Account creation and session persistence
- [ ] At "Create Account", call `AuthGateway.register`, persist the session, set the SessionController, and route to S09. Clear and dispose the password controllers.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** AUTH-006, ARCH-013
- **Files:** `registration_cubit.dart`, `create_password_page.dart`
- **Expected result:** An account exists with the +6,000 demo grant.
- **Acceptance:** A test inspects the DemoStore box and secure storage and finds no password value. The balance is 6,000.
- **Verify:** Tests.

### AUTH-009 — Login page (S03)
- [ ] Build it per S03 with `LoginCubit`, the demo semantics (password not checked; banner shown) and failure handling.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** ARCH-013, DS-006
- **Files:** `login_page.dart`, `bloc/login_cubit.dart`, tests
- **Expected result:** A working returning-user login.
- **Acceptance:** `demo@example.com` logs in and lands on Home with balance 6,000 and 2 orders. An unknown email shows a "Create account" action.
- **Verify:** Tests.

### AUTH-010 — Forgot and reset password flow (S04 → S07 → S05)
- [ ] Build it with `PasswordResetCubit` and the reset modes of S07 and S08.
- **Priority:** P1 · **Phase:** 5 · **Depends on:** AUTH-005, AUTH-006
- **Files:** `forgot_password_page.dart`, `bloc/password_reset_cubit.dart`, tests
- **Expected result:** A complete recovery demo.
- **Acceptance:** The flow ends on Login with the email prefilled and a snackbar.
- **Verify:** Widget flow test.

### AUTH-011 — Returning-user routing, including incomplete onboarding
- [ ] Relaunch with a session but no character goes to S09 (onboarding). A complete session goes to Home. No session goes to Welcome.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** NAV-001, AUTH-008
- **Files:** `splash_cubit.dart`, tests
- **Expected result:** Registration is not shown on every launch.
- **Acceptance:** A cubit test covers each case.
- **Verify:** Tests plus integration (AUTH-015).

### AUTH-012 — Session expiry (S36)
- [ ] Build `SessionExpiredPage`. Handle both the restore-time expiry and the runtime `SessionExpiredFailure`. "Log in again" opens S03 with the email prefilled.
- **Priority:** P1 · **Phase:** 5 · **Depends on:** ARCH-022, AUTH-009
- **Files:** `session_expired_page.dart`, tests
- **Expected result:** Expired sessions are handled gracefully.
- **Acceptance:** Using Demo Tools' expire (or a test hook) and then any action routes to S36.
- **Verify:** Tests.

### AUTH-013 — Sign-out core
- [ ] Implement `SessionRepository.signOut()`: delete `demo_session_v1`, invalidate the push sink, and keep the language preference, consent state and DemoStore data. Route to Welcome with the stack cleared.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** ARCH-013
- **Files:** `demo_session_repository.dart`, `lib/core/session/session_controller.dart`
- **Expected result:** A clean logout that keeps preferences.
- **Acceptance:** After sign-out, `cached_language_code` is unchanged and `demo_session_v1` is absent.
- **Verify:** Unit test with a fake secure storage.

### AUTH-014 — Production OTP isolation tests
- [ ] Add the four tests from Plan §31.4: (a) misconfigured detection; (b) the api-mode `OtpVerifier` is not `DemoOtpVerifier`, and `verify('123456')` returns `BackendUnavailableFailure`; (c) the demo verifier constructor throws under prod or api; (d) starting with prod+demo renders S38.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** ARCH-001, ARCH-002, ARCH-014, ARCH-021
- **Files:** `test/security/demo_isolation_test.dart`
- **Expected result:** Arbitrary OTP acceptance is provably impossible outside demo.
- **Acceptance:** All four tests are green.
- **Verify:** `test:test/security/`.

### AUTH-015 — Onboarding integration test
- [ ] Add `integration_test/onboarding_test.dart`: fresh install, the full flow, Home; kill and relaunch, Home; sign out, Welcome; log in, Home with the same character.
- **Priority:** P0 · **Phase:** 5 · **Depends on:** AUTH-001 to AUTH-013
- **Files:** `integration_test/onboarding_test.dart`, `pubspec.yaml` (dev dependency `integration_test: sdk: flutter`)
- **Expected result:** An end-to-end proof of the flow.
- **Acceptance:** The test passes on the emulator.
- **Verify:** `flutter test integration_test/onboarding_test.dart -d emulator-5554`.

### GATE-5 — Auth complete
- [ ] AUTH tests and isolation tests are green; the onboarding integration test passes; Plan §37 items 1–2 are satisfied.

---

## Phase 6 — Home Redesign

### HOME-001 — HomeCubit
- [ ] Combine the app-scoped balance and unread state with categories (CatalogRepository) and giveaways (GiveawayFeedRepository). Each section has independent loading and error state. Search mode uses a 250 ms debounce.
- **Priority:** P0 · **Phase:** 6 · **Depends on:** GATE-5
- **Files:** `lib/features/home/presentation/bloc/{home_cubit,home_state}.dart`, test
- **Expected result:** Home state with sections that fail independently.
- **Acceptance:** A catalog failure still shows the giveaways, and vice versa (test).
- **Verify:** bloc_test.

### HOME-002 — Points header
- [ ] Build `PointsHeader` with the live balance, the bell with an unread dot (→ S26) and balance tap (→ Wallet tab). No points card.
- **Priority:** P0 · **Phase:** 6 · **Depends on:** HOME-001, DS-015, DS-009
- **Files:** `lib/features/home/presentation/home_page.dart`
- **Expected result:** Matches the home reference header.
- **Acceptance:** The balance updates after a redemption without a refresh (verified again in CAT-011).
- **Verify:** Widget test.

### HOME-003 — Search with inline results
- [ ] Implement search mode per Plan §19.3 (category, product and giveaway result sections, empty state, clear).
- **Priority:** P0 · **Phase:** 6 · **Depends on:** HOME-001, ARCH-015
- **Files:** `home_page.dart`, `lib/features/home/presentation/widgets/search_results.dart`, test
- **Expected result:** The mock catalog is filtered.
- **Acceptance:** "uc" shows PUBG products. "zzz" shows the empty state. Clear restores the sections. A product result opens S13 with its Redeem sheet.
- **Verify:** Widget tests.

### HOME-004 — Available Rewards rail
- [ ] Build the horizontal `CategoryTile` list with "See all" (→ Categories tab). A tap opens S13.
- **Priority:** P0 · **Phase:** 6 · **Depends on:** HOME-001, DS-012
- **Files:** `home_page.dart`
- **Expected result:** Matches the reference rail.
- **Acceptance:** Each tile opens the right category.
- **Verify:** Widget test.

### HOME-005 — Giveaways grid with status chips
- [ ] Show the first 4 giveaways in available → upcoming → ended order, with cycling tints and a "See all" link. A tap opens S20.
- **Priority:** P0 · **Phase:** 6 · **Depends on:** HOME-001, DS-013
- **Files:** `home_page.dart`
- **Expected result:** Giveaway prizes, with no points prices.
- **Acceptance:** No PTS text appears on giveaway cards (test). The chips are correct for each status.
- **Verify:** Widget test.

### HOME-006 — All Giveaways page (S19)
- [ ] Build the filter chips (All, Available, Upcoming, Ended), the 2-column grid and per-filter empty states.
- **Priority:** P1 · **Phase:** 6 · **Depends on:** HOME-005
- **Files:** `lib/features/home/presentation/all_giveaways_page.dart`, test
- **Expected result:** Full browse access.
- **Acceptance:** Each filter returns the right seed items.
- **Verify:** Widget test.

### HOME-007 — Home states and refresh
- [ ] Add skeletons, per-section errors with retry, `UnavailableNotice` in api mode, pull-to-refresh and bottom padding that equals the nav footprint.
- **Priority:** P0 · **Phase:** 6 · **Depends on:** HOME-001, DS-018
- **Files:** `home_page.dart`
- **Expected result:** No blank screens.
- **Acceptance:** Tests cover loading, error and unavailable.
- **Verify:** Widget tests.

### HOME-008 — Home goldens and responsive tests
- [ ] Add goldens in en and ar at 320, 393 and 430, and at text scale 2.0.
- **Priority:** P1 · **Phase:** 6 · **Depends on:** HOME-002 to HOME-007
- **Files:** `test/golden/redesign/home_*`
- **Expected result:** Visual baseline.
- **Acceptance:** No overflow errors at any size.
- **Verify:** `golden`.

### GATE-6 — Home complete
- [ ] Plan §37 items 5–6 are satisfied; tests are green; `emu` comparison against `home-page.png` is reviewed.

---

## Phase 7 — Categories and Products

### CAT-001 — Categories page (S12)
- [ ] Build `CategoriesCubit` and the banner list as in Plan §20, fully data-driven.
- **Priority:** P0 · **Phase:** 7 · **Depends on:** GATE-6, DS-012
- **Files:** `lib/features/catalog/presentation/{categories_page.dart,bloc/categories_cubit.dart}`, tests
- **Expected result:** Matches `category-page.png`.
- **Acceptance:** Injecting 2 categories renders 2 banners (no constants in widgets).
- **Verify:** Widget test plus `golden`.

### CAT-002 — Category filter
- [ ] The title-bar search icon toggles an inline field that filters by localised title and subtitle.
- **Priority:** P1 · **Phase:** 7 · **Depends on:** CAT-001
- **Files:** `categories_page.dart`
- **Expected result:** A working search icon.
- **Acceptance:** "tik" leaves only TikTok, and the Arabic query also works.
- **Verify:** Widget test.

### CAT-003 — CategoryDetailsCubit
- [ ] Load the category, products per group, the live balance and favourites (per D-02). Provide `redeem()` with a requestId.
- **Priority:** P0 · **Phase:** 7 · **Depends on:** GATE-6, ARCH-016
- **Files:** `lib/features/catalog/presentation/bloc/category_details_cubit.dart`, test
- **Expected result:** A single source for S13 and S14.
- **Acceptance:** bloc_test covers load, group switch, redeem success, insufficient and unavailable.
- **Verify:** Tests.

### CAT-004 — Category hero
- [ ] Build the hero image, scrim, back and heart buttons, icon tile, title, subtitle and description, as in Plan §21.1.
- **Priority:** P0 · **Phase:** 7 · **Depends on:** CAT-003, DS-017
- **Files:** `lib/features/catalog/presentation/category_details_page.dart`
- **Expected result:** Matches the category-details reference hero.
- **Acceptance:** The heart toggles with a snackbar and persists locally. Back pops.
- **Verify:** Widget test.

### CAT-005 — Segmented tabs and product grid
- [ ] Build the overlapping sheet, `SegmentedTabs` (hidden for a single group), the 2- or 3-column `ProductCard` grid, the balance chip and the out-of-stock state.
- **Priority:** P0 · **Phase:** 7 · **Depends on:** CAT-003, DS-013, DS-014
- **Files:** `category_details_page.dart`
- **Expected result:** Matches the reference grid.
- **Acceptance:** The UC Top-Ups and Items & Skins tabs switch products. Out-of-stock items are disabled.
- **Verify:** Widget test plus `golden` in en and ar.

### CAT-006 — Redeem sheet (S14)
- [ ] Build it per Plan §21.2 (balance before and after, identifier field and validation, demo note, insufficient-points variant with "Browse cheaper rewards" and "Ways to earn").
- **Priority:** P0 · **Phase:** 7 · **Depends on:** CAT-005, DS-019
- **Files:** `lib/features/catalog/presentation/redeem_sheet.dart`, test
- **Expected result:** A clear confirmation step.
- **Acceptance:** Keyboard-safe at 320×568. An invalid identifier blocks confirmation.
- **Verify:** Widget tests.

### CAT-007 — Redemption execution and propagation
- [ ] On confirm, call the cubit's redeem with a per-sheet requestId. While pending, the sheet cannot be dismissed. On success, open S15. The balance and orders update everywhere through streams.
- **Priority:** P0 · **Phase:** 7 · **Depends on:** CAT-006
- **Files:** `redeem_sheet.dart`, `category_details_cubit.dart`
- **Expected result:** A working local redemption.
- **Acceptance:** One order is created and the balance drops by the product cost.
- **Verify:** Widget test plus CAT-011.

### CAT-008 — Redemption result page (S15)
- [ ] Build the success state (confetti, order short id, status, new balance, View order → S25, Back to rewards) and the failure variants with retry using the same requestId.
- **Priority:** P0 · **Phase:** 7 · **Depends on:** CAT-007
- **Files:** `lib/features/catalog/presentation/redemption_result_page.dart`, test
- **Expected result:** A clear outcome page.
- **Acceptance:** Both buttons navigate correctly. Confetti is off with reduced motion.
- **Verify:** Widget tests.

### CAT-009 — Insufficient-points path
- [ ] Ensure that an insufficient balance never calls `redeem`, shows the shortfall ("You need 4,000 more PTS") and offers working alternatives.
- **Priority:** P0 · **Phase:** 7 · **Depends on:** CAT-006
- **Files:** `redeem_sheet.dart`
- **Expected result:** Honest feedback.
- **Acceptance:** A test asserts the repository is not called, plus the shortfall text.
- **Verify:** Test.

### CAT-010 — Double-submit guard
- [ ] Rapid double taps or a retry after a timeout produce exactly one order (requestId idempotency plus UI lock).
- **Priority:** P0 · **Phase:** 7 · **Depends on:** CAT-007
- **Files:** `redeem_sheet.dart`, `demo_order_repository.dart`
- **Expected result:** No duplicate orders.
- **Acceptance:** A widget test taps twice within 50 ms and gets 1 order.
- **Verify:** Test.

### CAT-011 — Redemption consistency integration test
- [ ] Add `integration_test/redemption_test.dart`: redeem 60 UC (6,000 → 4,800). Assert the balance on Home, Wallet, the category chip and the Profile stat, and the order in My Orders. Redeem 660 UC and get insufficient, with nothing changed.
- **Priority:** P0 · **Phase:** 7 · **Depends on:** CAT-001 to CAT-010, PROFILE-006 (an order list placeholder is acceptable until Phase 9; finalise the assertion in Phase 9)
- **Files:** `integration_test/redemption_test.dart`
- **Expected result:** Proof of consistency.
- **Acceptance:** Green on the emulator.
- **Verify:** `flutter test integration_test/redemption_test.dart`.

### GATE-7 — Catalog complete
- [ ] Plan §37 items 7–8 are satisfied and `emu` is compared against `categoryDetails -page.png` and `category-page.png`.

---

## Phase 8 — Wallet

### WALLET-005 — Wallet page layout (S16)
- [ ] Build the header with the bell, `PointsBalanceCard`, the Fast, Earn button and three `ActionRow`s, with the compliant copy from Plan §22.4. No Sign Up or Recent Activity rows.
- **Priority:** P0 · **Phase:** 8 · **Depends on:** GATE-7, DS-011, DS-015
- **Files:** `lib/features/wallet/presentation/{wallet_page.dart,bloc/wallet_page_cubit.dart}`, tests, goldens
- **Expected result:** Matches `wallet-page.png`.
- **Acceptance:** Exactly 3 rows with the compliant subtitles. Goldens in en and ar.
- **Verify:** Widget test plus `golden`.

### WALLET-001 — Implement Place an Order action
- [ ] Navigate from Wallet to Categories via `ShellCubit.selectTab(categories)`.
- **Priority:** P0 · **Phase:** 8 · **Depends on:** WALLET-005, NAV-005
- **Files:** `wallet_page.dart`
- **Expected result:** The Categories tab is shown.
- **Acceptance:** Navigation works in demo mode, and the nav highlights Categories.
- **Verify:** Widget test.

### WALLET-002 — Implement Write a Review action
- [ ] Add the `in_app_review` dependency and a `ReviewLauncher`: `openStoreListing()`, then the `market://` fallback, then the https fallback, then a snackbar. Nothing is credited, and the copy does not imply a reward.
- **Priority:** P1 · **Phase:** 8 · **Depends on:** WALLET-005
- **Files:** `pubspec.yaml`, `lib/services/review_launcher.dart`, `wallet_page.dart`, test (fakes for in_app_review and url_launcher)
- **Expected result:** The Play listing opens.
- **Acceptance:** The correct application listing (`com.creativehub.rewardsapp`) opens on supported Android devices. The failure path shows a snackbar. The ledger is unchanged.
- **Verify:** Unit test with fakes; `emu` (Play Store installed image).

### WALLET-003 — Implement Refer a Friend
- [ ] Add the `share_plus` dependency and build S18 (code card, Copy, Share, invited count, terms note) as in Plan §27.
- **Priority:** P1 · **Phase:** 8 · **Depends on:** WALLET-005, ARCH-019
- **Files:** `pubspec.yaml`, `lib/features/referral/presentation/referral_page.dart`, `bloc/referral_cubit.dart`, tests
- **Expected result:** A working local share and copy flow.
- **Acceptance:** The user can share demo referral information. Copy writes to the clipboard. A share failure shows feedback. No points are granted.
- **Verify:** Widget tests with a fake share platform and a clipboard mock.

### WALLET-004 — Fast, Earn → Earn Hub (S17)
- [ ] Build `EarnHubPage` with only the supported actions (Invite friends, Join free giveaways, Redeem points, and the demo-only Add demo points).
- **Priority:** P0 · **Phase:** 8 · **Depends on:** WALLET-005
- **Files:** `lib/features/wallet/presentation/earn_hub_page.dart`, test
- **Expected result:** The button has meaningful navigation.
- **Acceptance:** Every row navigates. The demo row is absent in api mode. No invented mechanics.
- **Verify:** Widget test.

### WALLET-006 — Wallet bell and badge
- [ ] Bell → S26 with the unread dot from `InboxCubit`.
- **Priority:** P1 · **Phase:** 8 · **Depends on:** WALLET-005
- **Files:** `wallet_page.dart`
- **Expected result:** Consistent notification entry.
- **Acceptance:** The badge clears after "mark all read".
- **Verify:** Widget test.

### WALLET-007 — Wallet tests and goldens
- [ ] Goldens at 320, 393 and 430 in en and ar, and at text scale 2.0. Action tests are consolidated.
- **Priority:** P1 · **Phase:** 8 · **Depends on:** WALLET-001 to WALLET-006
- **Files:** `test/golden/redesign/wallet_*`, `test/widgets/redesign/wallet_page_test.dart`
- **Expected result:** Visual and behavioural baseline.
- **Acceptance:** No overflow.
- **Verify:** `golden`.

### GATE-8 — Wallet complete
- [ ] Plan §37 item 9 is satisfied.

---

## Phase 9 — Profile

### PROFILE-003 — Profile page header and avatar (S27)
- [ ] Build the aurora and decor header, the gear (→ S28), the avatar with edit badge (→ S09 change mode), name and email. No back arrow.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** GATE-8, DS-016
- **Files:** `lib/features/profile/presentation/{profile_page.dart,bloc/profile_cubit.dart}`, tests
- **Expected result:** Matches the profile reference header.
- **Acceptance:** The avatar reflects the current character. Long names ellipsise.
- **Verify:** Widget test plus `golden`.

### PROFILE-004 — Stats strip
- [ ] Show Points, Giveaways (entry count) and Orders (order count). Each is tappable: Wallet tab, S23, S24.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-003, DS-011
- **Files:** `profile_page.dart`
- **Expected result:** Live statistics.
- **Acceptance:** The counts update after an entry or redemption.
- **Verify:** Widget test.

### PROFILE-005 — Profile menu in the exact order
- [ ] Rows: My Giveaways, My Orders, Notifications (count badge), Language (current value), About, Privacy Policy, Terms & Conditions, Sign Out (danger).
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-003, DS-011
- **Files:** `profile_page.dart`
- **Expected result:** The menu from the brief.
- **Acceptance:** A widget test asserts the exact titles and order, and that every row has a non-null handler.
- **Verify:** Test.

### PROFILE-001 — Remove Wallet menu row
- [ ] Make sure no Wallet row exists in Profile (the reference shows one; it is intentionally omitted).
- **Priority:** P1 · **Phase:** 9 · **Depends on:** PROFILE-005
- **Files:** `profile_page.dart`, test
- **Expected result:** The redundant row is gone.
- **Acceptance:** Wallet remains accessible through bottom navigation. A test confirms no Wallet `MenuRow` exists.
- **Verify:** Widget test.

### PROFILE-002 — Implement Sign Out
- [ ] Sign Out row → `RewardsDialog` (S34) → `SessionRepository.signOut()` (AUTH-013) → Welcome with the stack cleared.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-005, AUTH-013
- **Files:** `profile_page.dart`, `lib/features/profile/presentation/widgets/sign_out_dialog.dart`, tests
- **Expected result:** A working demo logout.
- **Acceptance:** Signed-out users cannot reach authenticated demo screens without signing in again (back after sign-out exits the app; relaunch goes to Welcome). The language preference persists.
- **Verify:** Widget plus integration (AUTH-015).

### PROFILE-006 — My Orders (S24)
- [ ] Build `OrdersCubit` (or reuse the app-scoped one) with the list, filters, empty state (→ Categories tab) and DemoChip.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-005, ARCH-016
- **Files:** `lib/features/orders/presentation/{my_orders_page.dart,bloc/orders_cubit.dart}`, tests
- **Expected result:** Demo orders with meaningful statuses.
- **Acceptance:** A newly redeemed order appears at the top as Pending. Filters work.
- **Verify:** Widget tests.

### PROFILE-007 — Order details (S25)
- [ ] Show the snapshot, masked identifier, status timeline, copy id and a "Need help?" mailto.
- **Priority:** P1 · **Phase:** 9 · **Depends on:** PROFILE-006
- **Files:** `lib/features/orders/presentation/order_details_page.dart`, test
- **Expected result:** Full order view.
- **Acceptance:** The identifier is masked except for the last 4 characters. Mailto is launched (fake launcher).
- **Verify:** Widget test.

### PROFILE-008 — My Giveaways restyle on contracts (S23)
- [ ] Rewire `MyGiveawaysCubit` to `GiveawayEntryRepository.watchMyEntries()` and restyle with the new cards and DemoChip. Update the existing tests.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-005, ARCH-017
- **Files:** `lib/features/my_giveaways/presentation/**`, `test/features/my_giveaways/*`, `test/widgets/my_giveaways_page_test.dart`
- **Expected result:** Participation records from demo state.
- **Acceptance:** The preloaded demo account shows 1 ended entry. New entries appear instantly.
- **Verify:** Tests.

### PROFILE-009 — Notifications restyle on contracts (S26)
- [ ] Rewire `NotificationsCubit` to `InboxRepository`, restyle, group into Today and Earlier, add Mark all read, and route by type.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-005, ARCH-018, NAV-008
- **Files:** `lib/features/notifications/presentation/**`, tests
- **Expected result:** A working notifications screen.
- **Acceptance:** Tapping an item marks it read and routes. Badge counts stay in sync across Home, Wallet and Profile.
- **Verify:** Tests.

### PROFILE-010 — Language row and sheet (S30)
- [ ] Restyle `language_picker.dart` as a `RewardsSheet` and show the current language name in the row.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-005
- **Files:** `lib/shared/widgets/language_picker.dart`, `profile_page.dart`
- **Expected result:** Arabic and English switch at runtime.
- **Acceptance:** The switch applies immediately, keeps the current tab and persists across restart and sign-out.
- **Verify:** Widget test plus `emu`.

### PROFILE-011 — About page (S31)
- [ ] Build the page with logo, name, version (`APP_VERSION` define, default `1.1.1`), description, contact mailto and demo notice.
- **Priority:** P1 · **Phase:** 9 · **Depends on:** PROFILE-005
- **Files:** `lib/features/profile/presentation/about_page.dart`, test
- **Expected result:** A working About screen.
- **Acceptance:** It renders in en and ar and mailto works.
- **Verify:** Widget test.

### PROFILE-012 — Privacy Policy and Terms restyle with demo notice (S32, S33)
- [ ] Restyle `legal_document_page.dart` and add the demo notice banner. Keep the existing en/ar content and the `AppConfig` URL buttons.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-005
- **Files:** `lib/features/legal/presentation/*`, tests
- **Expected result:** Legal content opens, clearly labelled.
- **Acceptance:** The banner shows in demo mode. The content is unchanged. D-14 is recorded as a launch blocker.
- **Verify:** Widget tests.

### PROFILE-013 — Account Settings (S28)
- [ ] Rows: Edit profile, Change character, Ad privacy choices (only when `privacyRequired`), Delete demo account and data (with confirm → Welcome), Demo Tools (demo only), version.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** PROFILE-003
- **Files:** `lib/features/profile/presentation/account_settings_page.dart`, tests
- **Expected result:** The settings gear has a destination, and UMP privacy options are preserved.
- **Acceptance:** The privacy row's visibility follows the `AdService` flag. Delete wipes only that account's data.
- **Verify:** Widget tests.

### PROFILE-014 — Edit Profile rework (S29)
- [ ] Rework `edit_profile_page.dart` to a display-name-only form (1–40 characters) using `AccountRepository.updateDisplayName`.
- **Priority:** P1 · **Phase:** 9 · **Depends on:** PROFILE-013
- **Files:** `lib/features/settings/presentation/edit_profile_page.dart` (move to `lib/features/profile/presentation/` if convenient), `test/widgets/edit_profile_page_test.dart`
- **Expected result:** Profile editing is supported.
- **Acceptance:** The header shows the new name immediately.
- **Verify:** Tests.

### PROFILE-015 — Change character from Profile
- [ ] The edit badge and the Account Settings row both open S09 in change mode. Save → pop and snackbar.
- **Priority:** P0 · **Phase:** 9 · **Depends on:** AUTH-007
- **Files:** `profile_page.dart`, `account_settings_page.dart`
- **Expected result:** Character changing works.
- **Acceptance:** The nav avatar and profile avatar both update.
- **Verify:** Widget test.

### PROFILE-016 — Profile goldens and responsive tests
- [ ] Goldens at 320, 393 and 430 in en and ar, and at text scale 2.0 (the stat strip wraps).
- **Priority:** P1 · **Phase:** 9 · **Depends on:** PROFILE-001 to PROFILE-015
- **Files:** `test/golden/redesign/profile_*`
- **Expected result:** Visual baseline.
- **Acceptance:** No overflow.
- **Verify:** `golden`.

### GATE-9 — Profile complete
- [ ] Plan §37 items 3, 10 and 13 are satisfied and `emu` is compared against `profile-page.png`.

---

## Phase 10 — Giveaway Flow

### GIVE-001 — Giveaway details on contracts (S20)
- [ ] Rewire `GiveawayDetailsCubit` to `GiveawayFeedRepository` and `GiveawayEntryRepository`. Restyle the hero, chips, requirements, rules and CTA states. Update `giveaway_details_cubit_test` and `giveaway_details_page_test`.
- **Priority:** P0 · **Phase:** 10 · **Depends on:** GATE-9, ARCH-017
- **Files:** `lib/features/giveaway_details/presentation/**`, tests
- **Expected result:** Details work in demo mode with no Supabase.
- **Acceptance:** Available, upcoming, ended and already-entered all render correctly. No PTS anywhere.
- **Verify:** Tests.

### GIVE-002 — Participation flow on contracts (S21)
- [ ] Refactor `ParticipationCubit` to depend on the contracts and `SessionRepository`. Skip `needsRegistration` for authenticated users (D-07). Keep the step machine, retry semantics and the `criticalFlows` ad guard.
- **Priority:** P0 · **Phase:** 10 · **Depends on:** GIVE-001
- **Files:** `lib/features/participation/presentation/**`, `test/features/participation/participation_cubit_test.dart`
- **Expected result:** A local demo participation.
- **Acceptance:** The existing test scenarios are ported. New tests cover duplicate, full, ended and not-started.
- **Verify:** Tests.

### GIVE-003 — Demo number generation wiring
- [ ] Connect `enter()` to the reveal. The number respects the digit width. The result returns to S20 as "You're in — #…".
- **Priority:** P0 · **Phase:** 10 · **Depends on:** GIVE-002
- **Files:** `participation_flow_page.dart`, `giveaway_details_page.dart`
- **Expected result:** A locally generated demo participation number.
- **Acceptance:** Widths 4, 5 and 6 are displayed correctly.
- **Verify:** Widget test.

### GIVE-004 — Duplicate, full and ended rules in the UI
- [ ] Map each failure to the existing UX: duplicate leads to the already-participating view; full, ended and not-started show localised errors with the right CTA state.
- **Priority:** P0 · **Phase:** 10 · **Depends on:** GIVE-002
- **Files:** `participation_flow_page.dart`, failure messages
- **Expected result:** Invalid duplicate participation is prevented.
- **Acceptance:** A second attempt on the same giveaway never creates a second entry (test).
- **Verify:** Tests.

### GIVE-005 — Preserve the cosmetic rewarded-frame flow
- [ ] Keep `RewardFrameChoiceDialog`. Continue without ad and Watch ad lead to the identical entry. The frame flag is device-local and keyed by the demo user. Demo makes no SSV edge function calls.
- **Priority:** P0 · **Phase:** 10 · **Depends on:** GIVE-002, ARCH-017
- **Files:** `participation_flow_page.dart`, `participation_cubit.dart`, `reward_frame_entitlement_store.dart`, `test/widgets/reward_frame_choice_dialog_test.dart`
- **Expected result:** The ad is optional and cosmetic.
- **Acceptance:** Tests: the ad path and the no-ad path each create exactly 1 entry; a not-rewarded ad still creates the entry without a frame; the odds are untouched (the number generator is not called twice).
- **Verify:** Tests.

### GIVE-006 — Number reveal restyle (S22)
- [ ] Restyle the page, use digit-width formatting, and add the DemoChip and the caption "Demo entry — not a real competition entry". Buttons: View in My Giveaways, Done.
- **Priority:** P0 · **Phase:** 10 · **Depends on:** GIVE-003
- **Files:** `lib/features/number_reveal/presentation/number_reveal_page.dart`, test
- **Expected result:** It is clear that the number is a demo.
- **Acceptance:** The caption is present in demo and absent in api.
- **Verify:** Widget test.

### GIVE-007 — My Giveaways reflects the entry immediately
- [ ] Rely on the stream. No manual refresh is needed after an entry.
- **Priority:** P0 · **Phase:** 10 · **Depends on:** PROFILE-008, GIVE-003
- **Files:** —
- **Expected result:** The new entry shows instantly.
- **Acceptance:** Integration: enter, go back to Profile, open My Giveaways and see the entry at the top.
- **Verify:** `integration_test/giveaway_test.dart`.

### GIVE-008 — Demo winner simulation and celebration (S35)
- [ ] Demo Tools "Simulate winner announcement" leads to an inbox item and a celebration record. The shell shows S35 once with the DemoChip, then acknowledges it.
- **Priority:** P1 · **Phase:** 10 · **Depends on:** REM-001, NAV-008
- **Files:** `lib/features/winner_celebration/presentation/winner_celebration_page.dart`, `main_shell.dart`
- **Expected result:** The celebration is demonstrable and clearly fake.
- **Acceptance:** It shows exactly once.
- **Verify:** Widget test.

### GIVE-009 — Giveaway versus points separation tests
- [ ] Assert that the ledger is unchanged after an entry, that giveaway widgets never show PTS or Redeem, and that `GiveawayEntryRepository` has no dependency on `WalletRepository`.
- **Priority:** P0 · **Phase:** 10 · **Depends on:** GIVE-002
- **Files:** `test/domain/giveaway_points_separation_test.dart`
- **Expected result:** The separation is enforced.
- **Acceptance:** Green.
- **Verify:** Test.

### GATE-10 — Giveaways complete
- [ ] Plan §37 item 11 is satisfied and `integration_test/giveaway_test.dart` is green.

---

## Phase 11 — Remaining Screens

### REM-001 — Demo Tools page (S37)
- [ ] Add the actions from Plan Appendix B S37, each with a snackbar. The route exists only when `isDemo`. Include a link to the Component Gallery (DS-021).
- **Priority:** P1 · **Phase:** 11 · **Depends on:** GATE-10
- **Files:** `lib/features/demo_tools/presentation/demo_tools_page.dart`, tests
- **Expected result:** Testers can exercise every state.
- **Acceptance:** Each action's effect is verified. The page is unreachable in api mode.
- **Verify:** Widget tests.

### REM-002 — Offline and unavailable states everywhere
- [ ] Every page that loads data handles `NetworkFailure` (`OfflineBanner` plus retry) and `BackendUnavailableFailure` (`UnavailableNotice`).
- **Priority:** P0 · **Phase:** 11 · **Depends on:** GATE-10
- **Files:** all new pages
- **Expected result:** No silent failures.
- **Acceptance:** An api-mode smoke test opens every tab and the major screens without exceptions and shows notices.
- **Verify:** `test/widgets/redesign/api_mode_smoke_test.dart`.

### REM-003 — Retire superseded user screens
- [ ] Remove `UserHomeShell`, `UserHomePage` (and its cubit), `SettingsPage` and the user-path use of `RoleSelectionPage` once nothing references them (keep `RoleSelectionPage` if D-01 keeps admin). Delete or replace their tests, with reasons in the PR.
- **Priority:** P1 · **Phase:** 11 · **Depends on:** GATE-10, NAV-009
- **Files:** `lib/features/user_home/**`, `lib/features/settings/presentation/settings_page.dart`, related tests
- **Expected result:** No dead code paths in the user flow.
- **Acceptance:** analyze is clean, no unused files, and admin tests are green.
- **Verify:** `analyze`; `flutter test`.

### REM-004 — Route audit
- [ ] Re-run the AUD-003 grep and confirm every route maps to S01–S38 or to a retained admin E-id.
- **Priority:** P0 · **Phase:** 11 · **Depends on:** REM-003
- **Files:** PR notes
- **Expected result:** A complete inventory.
- **Acceptance:** No unmapped routes.
- **Verify:** Grep review.

### REM-005 — Dead-button audit
- [ ] List every `onPressed`, `onTap` and `onChanged` in the new features. Each must navigate, act, launch an external target or show an explicit message. Disabled states must be intentional (a documented condition).
- **Priority:** P0 · **Phase:** 11 · **Depends on:** REM-002
- **Files:** `test/architecture/no_dead_buttons_test.dart` (grep for `onPressed: () {}` and `onTap: null` without a condition) plus a manual table in the PR
- **Expected result:** Rule 20 is satisfied.
- **Acceptance:** The test is green and the table is reviewed.
- **Verify:** Test plus review.

### GATE-11 — All screens complete
- [ ] Every screen from S01 to S38 is implemented and the audits are signed off.

---

## Phase 12 — Localization and Accessibility

### L10N-001 — ARB completeness
- [ ] Every new string exists in both ARB files with descriptions. `flutter gen-l10n` produces an empty `untranslated.txt`.
- **Priority:** P0 · **Phase:** 12 · **Depends on:** GATE-11
- **Files:** `lib/l10n/*.arb`, `test/architecture/l10n_test.dart`
- **Expected result:** Full Arabic coverage.
- **Acceptance:** The test asserts `untranslated.txt` is empty and the en and ar key sets are equal.
- **Verify:** Test.

### L10N-002 — Hard-coded string sweep
- [ ] Find `Text('...')` and string literals in the new features (excluding keys and asset paths) and move them to the ARB files.
- **Priority:** P0 · **Phase:** 12 · **Depends on:** L10N-001
- **Files:** new features
- **Expected result:** No English leaks into the Arabic UI.
- **Acceptance:** The architecture test flags `Text\('[A-Za-z]` in the new features.
- **Verify:** Test.

### L10N-003 — Number and date formatting
- [ ] Use central `formatPoints(int, locale)` and `formatDate` helpers, following D-12 for digit style.
- **Priority:** P1 · **Phase:** 12 · **Depends on:** L10N-001
- **Files:** `lib/core/utils/formatters.dart`, tests
- **Expected result:** Consistent numbers.
- **Acceptance:** Unit tests for en and ar.
- **Verify:** Tests.

### L10N-004 — RTL audit
- [ ] Use only directional insets and alignments, mirror chevrons and arrows, keep digit sequences LTR, and put category art on the end side. Add RTL goldens for every screen.
- **Priority:** P0 · **Phase:** 12 · **Depends on:** L10N-001
- **Files:** new features, `test/golden/redesign/*_ar.png`
- **Expected result:** Correct Arabic layout.
- **Acceptance:** `grep -rn "EdgeInsets.only(left\|EdgeInsets.only(right\|Alignment.centerLeft\|Alignment.centerRight" lib/features/<new>` returns nothing.
- **Verify:** Grep plus goldens.

### L10N-005 — Semantics and screen readers
- [ ] Label every icon button, the character tiles, OTP boxes ("Digit 1 of 6"), stats and balance. Decorative images are excluded. Add `meetsGuideline(labeledTapTargetGuideline)` tests.
- **Priority:** P0 · **Phase:** 12 · **Depends on:** GATE-11
- **Files:** new features, `test/a11y/*`
- **Expected result:** Usable with TalkBack.
- **Acceptance:** Guideline tests pass on every new page. TalkBack check on S06, S07, S09, S11 and S27 on the `emu`.
- **Verify:** Tests plus `emu`.

### L10N-006 — Touch targets and contrast
- [ ] Add `androidTapTargetGuideline` and `textContrastGuideline` tests for every new page. Fix failures (the muted text on aurora is the likely one).
- **Priority:** P1 · **Phase:** 12 · **Depends on:** L10N-005
- **Files:** `test/a11y/*`
- **Expected result:** Accessible touch targets and contrast.
- **Acceptance:** Green.
- **Verify:** Tests.

### L10N-007 — Text scaling
- [ ] Verify text scale 1.0, 1.3 and 2.0 on every page with no overflow. The stat strip and nav adapt as in Plan §29.
- **Priority:** P0 · **Phase:** 12 · **Depends on:** GATE-11
- **Files:** `test/widgets/redesign/text_scale_test.dart`
- **Expected result:** Dynamic text support.
- **Acceptance:** No `RenderFlex overflowed` errors.
- **Verify:** Test.

### L10N-008 — Reduced motion
- [ ] Every animation honours `RMotion.of(context)`.
- **Priority:** P1 · **Phase:** 12 · **Depends on:** GATE-11
- **Files:** new features
- **Expected result:** Motion-sensitive users are respected.
- **Acceptance:** A test with `disableAnimations: true` settles in one pump on S11, S07, S15 and S22.
- **Verify:** Test.

### L10N-009 — Responsive width matrix
- [ ] Widget tests at widths 320, 360, 393 and 430 (and 600) for every screen, at heights 568 and 852.
- **Priority:** P0 · **Phase:** 12 · **Depends on:** GATE-11
- **Files:** `test/widgets/redesign/responsive_matrix_test.dart`
- **Expected result:** No overflow or clipping.
- **Acceptance:** Green.
- **Verify:** Test.

### GATE-12 — Localization and accessibility complete
- [ ] Plan §37 item 12 is satisfied.

---

## Phase 13 — Animations and Polish

### POL-001 — Page transitions
- [ ] Use `RewardsPageRoute` (fade plus 4% slide, 250 ms, RTL-aware direction) for all `AppRoutes`.
- **Priority:** P2 · **Phase:** 13 · **Depends on:** GATE-12
- **Files:** `lib/core/routing/rewards_page_route.dart`
- **Expected result:** Cohesive navigation motion.
- **Acceptance:** Zero duration when reduced motion is on.
- **Verify:** Test.

### POL-002 — Micro-interactions
- [ ] Button press scale, tile selection, balance count-up and the OTP shake, per Plan §30.
- **Priority:** P2 · **Phase:** 13 · **Depends on:** GATE-12
- **Files:** `lib/shared/ui/*`
- **Expected result:** A premium feel.
- **Acceptance:** No jank in the profile-mode trace.
- **Verify:** `emu` (profile mode).

### POL-003 — Haptics
- [ ] Light haptic on character select, redemption success and number reveal (the existing medium impact is kept).
- **Priority:** P2 · **Phase:** 13 · **Depends on:** GATE-12
- **Files:** relevant pages
- **Expected result:** Tactile feedback.
- **Acceptance:** No haptic fires on every rebuild (it is triggered by state transitions only).
- **Verify:** Code review.

### POL-004 — Image decode sizing and precache
- [ ] Use `cacheWidth` everywhere and precache the auth heroes and characters (with no added splash time).
- **Priority:** P1 · **Phase:** 13 · **Depends on:** GATE-12
- **Files:** `app_image.dart`, auth pages
- **Expected result:** Lower memory use and no image pop-in.
- **Acceptance:** The DevTools memory view shows no full-resolution decodes of 1520 px banners into small tiles.
- **Verify:** `emu` profile.

### POL-005 — Performance budget check
- [ ] In profile mode on a mid-range emulator, scroll Home, switch tabs, open Category Details and run the onboarding. Record the frame timings.
- **Priority:** P1 · **Phase:** 13 · **Depends on:** POL-001 to POL-004
- **Files:** PR notes
- **Expected result:** Plan §30 budget met.
- **Acceptance:** No sustained frames over 16 ms. Cold start is no more than the splash minimum plus 300 ms.
- **Verify:** DevTools timeline screenshots.

### GATE-13 — Polish complete
- [ ] The performance budget is met.

---

## Phase 14 — Testing and Visual Verification

### TEST-001 — Static checks
- [ ] analyze and format are clean on the whole repository.
- **Priority:** P0 · **Phase:** 14 · **Depends on:** GATE-13
- **Files:** —
- **Expected result:** Clean CI lint.
- **Acceptance:** 0 issues.
- **Verify:** Commands.

### TEST-002 — Existing suite reconciliation
- [ ] Update or retire tests for the superseded screens (Plan §32 list), with a reason for each in the PR. Admin tests stay green.
- **Priority:** P0 · **Phase:** 14 · **Depends on:** REM-003
- **Files:** `test/**`
- **Expected result:** A green full suite.
- **Acceptance:** `flutter test` is green and no test is skipped without a reason.
- **Verify:** `flutter test`.

### TEST-003 — Golden infrastructure
- [ ] Add `test/flutter_test_config.dart` (font loading, fixed Clock, DemoLatency.zero, ads disabled). Decide and document the CI strategy (tolerance comparator or platform tag).
- **Priority:** P0 · **Phase:** 14 · **Depends on:** GATE-13 (start earlier if goldens flake in Phase 2)
- **Files:** `test/flutter_test_config.dart`, `test/golden/redesign/_comparator.dart`
- **Expected result:** Stable goldens with real fonts.
- **Acceptance:** Goldens regenerate deterministically twice in a row.
- **Verify:** Run twice and confirm no diffs.

### TEST-004 — Golden suite completeness
- [ ] Every screen S02–S37 has goldens in en and ar at 393×852. S02, S06, S07, S08, S09, S11, S12, S13, S16 and S27 also have goldens at 320×640 and at text scale 2.0.
- **Priority:** P0 · **Phase:** 14 · **Depends on:** TEST-003
- **Files:** `test/golden/redesign/**`
- **Expected result:** Full visual regression coverage.
- **Acceptance:** A checklist test enumerates the expected golden files.
- **Verify:** `golden`.

### TEST-005 — Integration flows
- [ ] `onboarding_test`, `redemption_test`, `giveaway_test`, `language_test` (switch, relaunch, persists, RTL), `session_test` (expire, S36, login).
- **Priority:** P0 · **Phase:** 14 · **Depends on:** GATE-13
- **Files:** `integration_test/*`
- **Expected result:** The main journeys are proven on a device.
- **Acceptance:** All are green on the emulator.
- **Verify:** `flutter test integration_test -d <emulator>`.

### TEST-006 — Emulator comparison against the references
- [ ] Capture the 10 implementable reference screens in demo mode on a 411 dp and a 360 dp device. Build compare sheets with `tool/assets/compare_sheet.py` into `docs/screenshots/redesign/`. Review them against Plan §11, including the listed intentional deviations.
- **Priority:** P0 · **Phase:** 14 · **Depends on:** TEST-005
- **Files:** `docs/screenshots/redesign/*`
- **Expected result:** Visual fidelity evidence.
- **Acceptance:** The user signs off on each compare sheet.
- **Verify:** Review.

### TEST-007 — Redesigned splash verification
- [ ] Compare the redesigned splash with `design_references/splash-page.png`.
- **Priority:** P0 · **Phase:** 14 · **Depends on:** AUD-004
- **Files:** `docs/screenshots/redesign/splash_compare.png`
- **Expected result:** Rule 5 is proven.
- **Acceptance:** The frames are visually identical.
- **Verify:** Compare sheet.

### TEST-008 — CI updates and release-define check
- [ ] CI runs the unit, widget and architecture tests in demo mode, plus an api-mode smoke run (`--dart-define=DATA_MODE=api`). Add a release check (script or workflow step) that rejects a release build without `DATA_MODE=api` and `APP_ENV=prod`. Do not change the signing configuration.
- **Priority:** P0 · **Phase:** 14 · **Depends on:** TEST-002
- **Files:** `.github/workflows/ci.yml`, `tool/check_release_defines.dart`
- **Expected result:** Demo builds cannot accidentally become production builds.
- **Acceptance:** The CI run is green, and a deliberately wrong release command fails the check.
- **Verify:** CI logs.

### TEST-009 — Acceptance sign-off
- [ ] Walk through Plan §37 items 1–17 and record evidence for each.
- **Priority:** P0 · **Phase:** 14 · **Depends on:** TEST-001 to TEST-008
- **Files:** PR description
- **Expected result:** Documented completion.
- **Acceptance:** Every item has evidence.
- **Verify:** Review.

### TEST-010 — Architecture tests
- [ ] Add `test/architecture/`: import boundaries (no `supabase_flutter`, `lib/data/demo/` or `lib/shared/repositories/` in the new features), no raw `MaterialPageRoute` in the new features, no `Color(0x` literals in the new features, `demo_module.dart` imported only by `injection.dart`.
- **Priority:** P0 · **Phase:** 14 (create it in Phase 1 and extend it per phase) · **Depends on:** ARCH-021
- **Files:** `test/architecture/*.dart`
- **Expected result:** Enforced architecture.
- **Acceptance:** Green.
- **Verify:** Test.

### GATE-14 — Verified
- [ ] All suites are green, the compare sheets are approved and Plan §37 is fully satisfied.

---

## Phase 15 — VPS Integration Readiness

### API-002 — Contract review against the backend data needs
- [ ] Re-read every contract and model against Plan §16–17. Confirm the fields listed for Admin-managed content (categories, products, giveaways, orders, notifications) are complete. Write the result into Plan §17.
- **Priority:** P1 · **Phase:** 15 · **Depends on:** GATE-14
- **Files:** Plan §16–17
- **Expected result:** A handover-ready data contract for the backend team.
- **Acceptance:** No UI-required field is missing from the models.
- **Verify:** Review.

### API-003 — DTO and mapper placeholders (no endpoints)
- [ ] Create empty `lib/data/api/dto/` and `lib/data/api/http/` folders, each with a README comment in a `.dart` library doc (no Markdown files) explaining the mapping rules. Do not invent field names beyond the domain models.
- **Priority:** P2 · **Phase:** 15 · **Depends on:** API-002
- **Files:** `lib/data/api/dto/dto.dart`, `lib/data/api/http/http.dart`
- **Expected result:** Clear integration points.
- **Acceptance:** No URLs or endpoints (the ARCH-020 grep stays empty).
- **Verify:** Grep.

### API-004 — Api-mode full smoke
- [ ] Run the app with `DATA_MODE=api` on the emulator. Every screen shows `UnavailableNotice` gracefully, auth screens explain that sign-up is unavailable, and nothing crashes.
- **Priority:** P0 · **Phase:** 15 · **Depends on:** REM-002
- **Files:** PR notes
- **Expected result:** A safe api placeholder.
- **Acceptance:** No exceptions in the logs.
- **Verify:** `emu`.

### API-005 — Update the VPS integration checklist
- [ ] Refresh the Plan §35 checklist with any new learnings.
- **Priority:** P1 · **Phase:** 15 · **Depends on:** API-002
- **Files:** Plan §35
- **Expected result:** The checklist is current.
- **Acceptance:** Reviewed.
- **Verify:** Diff.

### API-006 — Confirm no backend implementation is included
- [ ] Verify there is no HTTP client implementation, no server code, no Supabase schema change, no new edge function and no mock HTTP server in this branch.
- **Priority:** P0 · **Phase:** 15 · **Depends on:** GATE-14
- **Files:** `git diff pre-redesign-baseline -- supabase/ lib/data/api/`
- **Expected result:** Scope respected.
- **Acceptance:** The diff of `supabase/` is empty and `lib/data/api/` contains only interfaces and unavailable stubs.
- **Verify:** git diff.

### API-007 — Launch blocker register
- [ ] Record the status of each launch blocker in Plan Appendix A: D-04 earning model, D-09 brand licensing, D-10 platform-terms review, D-14 legal, account deletion and iOS id; R-11 user migration. Confirm that the demo is distributed through internal testing only.
- **Priority:** P0 · **Phase:** 15 · **Depends on:** GATE-14
- **Files:** Plan Appendix A, §34
- **Expected result:** The product owner has the full picture.
- **Acceptance:** Every blocker has a status and an owner.
- **Verify:** Review.

### API-008 — Supabase isolation check for the new flows
- [ ] Make sure the TEST-010 import-boundary test covers all new feature folders. In demo mode with D-01 at its default, Supabase is never initialised (assert `getIt.isRegistered<SupabaseClient>() == false`).
- **Priority:** P0 · **Phase:** 15 · **Depends on:** TEST-010
- **Files:** `test/architecture/import_boundaries_test.dart`, `test/core/di/injection_test.dart`
- **Expected result:** The new demo flows do not rely on Supabase.
- **Acceptance:** Green.
- **Verify:** Tests.

### GATE-15 — VPS-ready
- [ ] The contracts are reviewed, the api placeholder is safe, there is no backend code and the blockers are registered. **The demo redesign is done.**

---

## Summary

### Redesign execution update (2026-10-20)

- [x] Located the five supplied backgrounds and 11 reference screenshots; inventoried existing app structure and uncommitted work.
- [x] Updated the splash requirement and asset priority in the plan. The new demo entry point does not initialize Supabase.
- [x] Implemented a navigable local demo slice: onboarding, persistent account and session, Home, Categories, redemption, Wallet, Profile, orders, notifications, and giveaways.
- [x] Extracted nine character tiles and two decorative hero crops. See `docs/redesign-asset-manifest.md` for source and quality limits.
- [x] Verified `flutter analyze` (zero issues) and `flutter test` (340 passed); added three repository tests, a 320 dp tab layout test, and an OTP paste navigation test. Fixed the overflows the layout test exposed.
- [x] Launched the demo on Android emulator, completed onboarding, redeemed a 1,200-point product, and observed the Wallet balance change from 6,000 to 4,800. Captures are in `docs/screenshots/redesign-*-emulator.png`.
- [ ] The reference match is incomplete: category, product, and giveaway art is provisional; only Welcome, Email, Home, and Wallet have emulator captures.
- [ ] The planned Cubit layer, full repository contract split, comprehensive ARB localization, responsive/golden/integration coverage, share sheet, real review fallback, and all remaining phase gates need completion.
- [ ] Production VPS, fulfillment, referral attribution, and verified giveaway actions remain blocked by their server contracts and launch decisions. Legal disclosures need review.


| Phase | Tasks (excluding gates) |
|---|---|
| 0 Audit | 5 |
| 1 Architecture | 24 |
| 2 Design System | 21 |
| 3 Asset Pipeline | 13 |
| 4 Navigation & Shell | 9 |
| 5 Auth | 15 |
| 6 Home | 8 |
| 7 Categories & Products | 11 |
| 8 Wallet | 7 |
| 9 Profile | 16 |
| 10 Giveaways | 9 |
| 11 Remaining | 5 |
| 12 L10n & A11y | 9 |
| 13 Polish | 5 |
| 14 Testing | 10 |
| 15 VPS Readiness | 7 |
| **Total** | **174 actionable tasks + 16 gates** |
