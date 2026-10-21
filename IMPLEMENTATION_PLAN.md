# Creative Rewards — Mobile Redesign & VPS-Ready Demo: Implementation Plan

> Status: **PLANNING ONLY — implementation not approved yet.**
> Companion checklist: [`TASKS.md`](TASKS.md).
> Audience: the coding agent(s) who will implement the redesign. Every requirement below is meant to be executable without re-interpreting the product brief.
> Repository root: `D:\creative_hub\rewards app\app\rewardsapp` (Flutter 3.44.8, Dart ^3.12.2, app version `1.1.1+5`, package `com.creativehub.rewardsapp`).
> Planning date: 2026-10-19.

Legacy documents `implementation-plan.md`, `DESIGN.md` and `docs/*` describe the **current** Supabase giveaway app. They remain valid history. Where they conflict with this file, this file wins for the redesign. (Windows file names are case-insensitive. `TASKS.md` replaces the old `tasks.md` roadmap, which can still be read from git with `git show HEAD:tasks.md`.)

---

## Table of contents

1. Executive Summary
2. Current Repository Audit
3. Current Backend and Integration Inventory
4. Redesign Objectives
5. Scope and Non-Scope
6. Complete Existing Screen Inventory
7. Target Screen Inventory
8. Exact User Registration Flow
9. Returning User and Login Flow
10. Navigation Architecture
11. Visual Reference Mapping
12. Design System Specification
13. Asset Generation Capability Assessment
14. Asset Inventory and Generation Strategy
15. Demo Data Architecture
16. Mock Repository Contracts
17. Future VPS Repository Architecture
18. Authentication Demo Design
19. Home Screen Specification
20. Categories Specification
21. Product Redemption Specification
22. Wallet Specification
23. Profile Specification
24. Giveaway Participation Specification
25. Orders Specification
26. Notifications Specification
27. Referral Specification
28. Localization and RTL
29. Responsive Layout
30. Animation and Performance
31. Security and Demo Isolation
32. Automated Testing
33. Visual Regression Testing
34. Risks and Dependencies
35. Backend Migration Readiness
36. Phase-by-Phase Implementation Strategy
37. Acceptance Criteria
38. Definition of Done
- Appendix A — Unresolved Decisions (D-01 … D-16)
- Appendix B — Per-screen specification sheets (S01 … S38)

---

## 1. Executive Summary

Creative Rewards is currently an **anonymous-identity giveaway app** backed by Supabase. A user browses giveaways, registers a name and phone number on their first entry, gets a server-allocated 4–6 digit participation number, and can be celebrated as a winner. The same binary also contains an **in-app Admin area** for creating giveaways, managing categories and picking winners. There are **no points, wallet, catalog, orders, email accounts, characters or referrals** in the codebase today.

The redesign turns the app into a **points-and-rewards app with free giveaways**:

- A new email-based onboarding: **Welcome → Email → OTP → Create Password → Choose Character → Home**.
- A four-tab shell: **Home · Categories · Wallet · Profile**. The Profile tab icon is the user's selected character.
- A points-redemption catalog (categories → products → redeem → order).
- The existing giveaway number-generation flow is kept. Giveaway prizes are **never** bought with points.

The backend will move to a **new VPS API** that does not exist yet. So this phase delivers a **fully interactive demo** that runs entirely on on-device mock repositories behind backend-agnostic contracts. Switching to the VPS later means swapping the data-source implementations registered in dependency injection. Screens and cubits must not change.

Key architectural moves:

1. Add a compile-time `DATA_MODE` (`demo` | `api`) next to the existing `APP_ENV`. A startup guard makes a **production + demo** build refuse to start, and the demo OTP verifier cannot even be constructed outside demo mode.
2. New contracts live in `lib/domain/repositories/`. Demo implementations go in `lib/data/demo/`, backed by one persisted `DemoStore`. Placeholder "backend unavailable" implementations go in `lib/data/api/`. The legacy Supabase repositories in `lib/shared/repositories/` are not touched (the in-app Admin area still uses them).
3. A new design system lives in `lib/core/theme/rewards_*.dart` plus `lib/shared/ui/`. It is kept separate from the legacy `AppColors` / `AppTheme` so the Admin area does not regress.
4. The splash screen is redesigned to match `design_references/splash-page.png`; initialization and session restoration remain functional.

The plan has **16 phases (0–15)**, **38 target surfaces** and **174 actionable tasks (plus 16 phase gates)** in `TASKS.md`. Some decisions are needed before or during implementation. They are collected in **Appendix A**. The most important are D-01 (fate of the in-app Admin area), D-04 (how points are earned in production), D-09 (third-party brand imagery licensing) and D-10 (whether "followers/likes" products are allowed under platform terms).

---

## 2. Current Repository Audit

### 2.1 Layout (as found)

```
lib/
  main.dart                      Firebase + DI + LiquidGlass init, MaterialApp(home: SplashPage)
  config/env.dart                SUPABASE_URL / SUPABASE_ANON_KEY / APP_ENV (dev|prod) via --dart-define
  firebase_options.dart          Android Firebase project rewards-app-87115
  core/
    config/app_config.dart       CONTACT_EMAIL, PRIVACY_POLICY_URL, TERMS_URL, DATA_DELETION_URL, ADMIN_CONTACT_PHONE
    di/injection.dart            get_it manual registration (no codegen); initialises Supabase + Hive
    error/failure.dart, result.dart   Failure hierarchy + Result<T> (Success/Error, fold)
    localization/locale_controller.dart  ValueNotifier<Locale>, persisted in secure storage
    network/supabase_client_provider.dart
    theme/ app_colors, app_spacing (AppSpacing/AppRadius), app_typography, app_theme, app_icons (Lucide), app_visuals
    utils/phone_util.dart
  features/                       (presentation only; BLoC/Cubit per feature)
    splash, role_selection, user_home, giveaway_details, participation, number_reveal,
    my_giveaways, notifications, settings (settings + edit_profile), legal, winner_celebration,
    admin_auth, admin_dashboard (shell + dashboard), admin_analysis, admin_settings,
    categories (admin category management), create_giveaway, giveaway_analytics (+ wheel, winners)
  services/
    ads/ (AdService: UMP consent, banner, app-open, interstitial, rewarded; AdFrequencyController; AdConstants)
    cache/ (Hive CacheService with TTL; CacheKeys)
    notification_service.dart (FCM; token persisted to Supabase)
    secure_storage_service.dart (identity, last role, language, anon refresh token)
    user_identity_service.dart (anonymous session restore/verify)
    reward_frame_entitlement_store.dart (device-local cosmetic frame flag)
  shared/
    models/ Giveaway, GiveawayCategory, GiveawayRequirement, Participation, UserProfile, Winner, EligibleParticipant, NotificationItem
    repositories/ Auth, User, Category, Giveaway, Participation, Winner, Notification, Storage  (concrete Supabase classes, no interfaces)
    utils/notification_routing.dart
    widgets/ ad_banner, app_bottom_nav (Liquid Glass), user_tab_scaffold, app_network_image, hero_back_button,
             language_picker, participation_growth_chart, participation_reward_frame, primary_gradient_button, settings_section
  l10n/ app_en.arb, app_ar.arb (~312 keys), generated/ (flutter gen-l10n, nullable-getter: false)
assets/ fonts/ (Plus Jakarta Sans, Manrope variable TTFs), img/ (app-logo.png 1254², profile.png 512²),
        lottie/ (splash.json, number-generator.json, empty-gift.json, Celebration.json)
test/  ~50 files: cubit tests (bloc_test/mocktail), widget tests, 1 golden test (role selection en/ar), responsive regression tests
test_driver/ ad_smoke_main.dart, ui_layout_main.dart
supabase/ migrations, edge functions (prepare/cancel rewarded frame, verify-ad-reward), verification SQL
legal/ static GitHub-Pages legal site (privacy, terms, delete-account); website/ (Astro)
.github/workflows/ ci.yml (pub get, dart format check, flutter analyze, flutter test --coverage, web build), deploy-website.yml
design_references/ 11 PNGs (1024×1536 phone mockups)
```

### 2.2 Conventions to follow

| Topic | Convention found | Rule for the redesign |
|---|---|---|
| State management | `flutter_bloc` Cubits + `equatable` states, one `bloc/` folder per feature | Same. New cubits per feature, with no business logic in widgets. |
| DI | `get_it` manual registration in `core/di/injection.dart` | Same, split into mode-specific registration functions (§15.6). |
| Errors | `Result<T>` + `Failure` subclasses, mapped to l10n in UI | Same. Add new Failure subclasses (§16.3). |
| Navigation | Imperative `Navigator.push(MaterialPageRoute)`, no router package | Keep Navigator 1.0. Add a small `AppRoutes` helper file for typed push functions. No GoRouter (D-13). |
| Icons | `lucide_icons_flutter` through `AppIcons` | Same. Add new glyphs to `AppIcons`. |
| Fonts | Plus Jakarta Sans (headings), Manrope (body), bundled | Same, plus an Arabic fallback font (D-12). |
| Localisation | ARB + gen-l10n, `AppLocalizations.of(context)` | Same. Every new user-visible string goes into the ARB files. |
| Comments | Heavy explanatory doc comments | Match that density on non-obvious logic (env guard, demo isolation, ledger). |
| Lints | `flutter_lints` + `analysis_options.yaml`; CI enforces `dart format` | New code must pass `dart format --set-exit-if-changed` and `flutter analyze`. |

### 2.3 Repository state warnings (must be resolved in Phase 0)

- The working tree has **~120 uncommitted changes and untracked files** (ads, categories, notifications, number reveal, Android package move to `com.creativehub`, etc.). The redesign must **not** start on top of an uncommitted tree. The user commits or stashes it and tags a baseline (`AUD-001`).
- Root-level build/test logs (`*.log`, `hs_err_pid*.log`, `replay_pid*.log` ≈ 2 MB) and `artifacts/` are clutter. They are left alone (not in scope). Do not commit new logs.
- The only existing golden (`test/golden/role_selection_*.png`) is currently **modified with failure diffs** in `test/golden/failures/`. Re-baseline the goldens before the redesign so failures can be attributed (`AUD-002`).

---

## 3. Current Backend and Integration Inventory

| Integration | Where | Used by | Redesign treatment |
|---|---|---|---|
| **Supabase** (auth: anonymous + admin email/password; Postgres + RLS; Edge Functions `register-or-link-user`, `create-participation`, admin sign-up, select-winner, rewarded-frame SSV; Storage bucket `giveaway-images`; Realtime on `giveaways` + `notifications`) | `core/di`, `core/network`, `shared/repositories/*`, `user_identity_service`, `notification_service`, `user_home_shell`, `user_home_cubit`, admin features | Everything today | **Not used by any new demo flow.** Supabase stays initialised only where the in-app Admin area is still enabled (D-01). New features must not import `supabase_flutter`. A test enforces this (`API-008`). |
| **Firebase Core + Messaging (FCM)** | `main.dart`, `notification_service.dart`, `google-services.json` (untracked) | Winner push notifications; token saved to Supabase `user_devices` | Firebase init stays best-effort. In demo mode the token-persistence half is replaced by a no-op `PushTokenSink`, and push taps still route through `notification_routing`. In api mode the token goes to the VPS (contract only). |
| **Google Mobile Ads + UMP** | `services/ads/*`, `ad_banner.dart`, `user_home_shell.dart`, `participation_flow_page.dart`, `settings_page.dart` | Banner in user dock, app-open, interstitial (stubbed `false`), rewarded ad for a **cosmetic** participation frame; UMP consent + "Privacy choices" row | Kept. Test ad unit IDs in non-release builds (already enforced by `AdConstants.testAds`). The banner slot stays in the shell (D-05). The "Privacy choices" row moves to Account Settings (S28). The rewarded ad stays **optional and cosmetic** (§24.4). |
| **Hive** (`CacheService`, box `app_cache_v1`) | `services/cache` | TTL caches for giveaways/participations, ad counters, frame entitlements | Reused. Demo data gets its **own** box `demo_store_v1` so clearing caches never deletes demo state, and the reverse. |
| **flutter_secure_storage** (`SecureStorageService`) | identity, last role, language, anon refresh token | Session/identity | Reused for the language preference (unchanged key `cached_language_code`). A new key `demo_session_v1` holds the demo session. In future, api tokens use keys namespaced `api_*`. **`clearAll()` must never be called on sign-out**, because it would wipe the language preference. |
| **url_launcher** | legal links, WhatsApp | | Reused: store listing fallback, legal URLs, mailto. |
| **lottie / confetti** | legacy splash, number reveal, empty gift, celebration | | The redesigned demo splash uses extracted gift artwork. Legacy animations remain available for the older flow. |
| **liquid_glass_widgets** | user + admin bottom nav, `main.dart` wrap | | Admin keeps it. The new user shell uses a flat custom nav (§10.3) that matches the reference. The package stays a dependency while Admin exists. |
| **image_picker, fl_chart** | Admin create giveaway, analytics | | Untouched. |
| Legal site (`legal/`) | GitHub Pages | Privacy/Terms/Delete-account | Describes the **old** Supabase processing. Updating it is a **launch blocker** for any production release of the redesign (§31.6, D-14). |

New packages to add **during implementation** (not now): `in_app_review` (store listing / in-app review), `share_plus` (referral share sheet), `integration_test` (SDK, dev). Nothing else is required. `crypto` already exists transitively but is not needed, because no password hashing happens on the device (§18.4).

---

## 4. Redesign Objectives

1. **Visual fidelity**: reproduce the 10 implementable references (all except the splash reference) as real Flutter widgets, with no flattened screenshot backgrounds.
2. **Exact onboarding order**: Welcome → Email → OTP → Create Password → Choose Character → Home.
3. **Four-tab shell** with a character-avatar Profile tab.
4. **Every interactive element does something meaningful** in demo mode: a local action, navigation, an external destination, or an explicit "available when the service launches" message.
5. **Backend-agnostic architecture**: UI → Cubit → repository contract → (Demo | future VPS) implementation.
6. **Safety**: no arbitrary-OTP acceptance and no demo data in production, enforced by code and tests.
7. **Preserve** the splash visuals, the giveaway number-generation concept, the cosmetic rewarded-frame semantics, ads/consent compliance, Arabic/English with RTL, and the legal screens.
8. **Accessible and responsive** at 320–430 dp widths, text scale up to 2.0, Arabic RTL.

---

## 5. Scope and Non-Scope

### In scope (implementation phase, after approval)
- New user-facing flows and screens S02–S38 (§7), the new design system, demo data layer, contracts, DI split, environment guard.
- Restyling and re-wiring existing user screens (giveaway details, participation, number reveal, my giveaways, notifications, legal, edit profile, winner celebration) onto contracts.
- Asset pipeline and the asset generation/collection described in §13–14.
- Tests: unit, widget, golden, integration, emulator screenshots.

### Out of scope
- **Any backend**: no VPS API, no database, no Supabase schema changes, no edge functions, no mock HTTP server.
- **Admin Dashboard** (separate project). The in-app Admin area is neither redesigned nor extended (D-01).
- Real payments, real fulfilment, real email sending, real referral rewards.
- Changing package ID, signing configs, version name/code, AdMob unit IDs, or Firebase project.
- Production VPS implementation and production backend changes.
- Website (`website/`) and legal HTML content changes. Those are flagged as launch blockers only.

---

## 6. Complete Existing Screen Inventory

Audited from the code (routes are imperative `MaterialPageRoute`s; there is no route table). **24 screens + 4 dialogs/sheets = 28 surfaces.**

| # | Surface | File | Reached from | Data source | Redesign fate |
|---|---|---|---|---|---|
| E01 | Splash (Lottie `splash.json`, min 3 s) | `features/splash/presentation/splash_page.dart` (+ `cubit/splash_cubit.dart`) | app start | SecureStorage, UserIdentityService, AuthRepository | **Keep visuals.** Change destinations only (S01). |
| E02 | Role Selection (User / Admin) | `features/role_selection/presentation/role_selection_page.dart` | Splash, Sign Out | — | **Removed from the user path.** Replaced by Welcome (S02). Fate of the admin entry: D-01. |
| E03 | User Home Shell (3 tabs: Home / My Giveaways / Settings, Liquid Glass nav, banner ad, realtime winner listener) | `features/user_home/presentation/user_home_shell.dart` | Splash, Role Selection | Supabase realtime, AdService, NotificationService | **Superseded** by Main Shell (S10). Deleted after S10 ships (`REM-004`). |
| E04 | User Home (browse grid, search, category chips, pagination) | `features/user_home/presentation/user_home_page.dart` | E03 tab 0 | GiveawayRepository, CategoryRepository | **Superseded** by Home (S11) and All Giveaways (S19). |
| E05 | Giveaway Details (hero, stat chips, requirements, CTA "Generate number") | `features/giveaway_details/presentation/giveaway_details_page.dart` | Home card, My Giveaways, notification | GiveawayRepository, ParticipationRepository | **Restyle + rewire** (S20). |
| E06 | Participation Flow (identity check → registration → optional rewarded-ad choice → create entry) | `features/participation/presentation/pages/participation_flow_page.dart` | E05 CTA | User/Participation/Giveaway repos, AdService | **Rewire** to contracts (S21). Registration step skipped when authenticated (D-07). |
| E07 | Registration Form (name + phone) | `features/participation/presentation/widgets/registration_form.dart` | inside E06 | — | **Not used in the demo flow** (D-07). Kept for api mode if the VPS requires contact info. |
| E08 | Reward Frame Choice dialog | `participation_flow_page.dart` (`RewardFrameChoiceDialog`) | inside E06 | — | **Keep semantics**, restyle (part of S21). |
| E09 | Number Reveal | `features/number_reveal/presentation/number_reveal_page.dart` | E06 success | ParticipationRepository.markNumberRevealed | **Restyle + demo label** (S22). |
| E10 | My Giveaways | `features/my_giveaways/presentation/my_giveaways_page.dart` | E03 tab 1 | ParticipationRepository, realtime | **Restyle + rewire** (S23), reached from Profile. |
| E11 | Notifications | `features/notifications/presentation/notifications_page.dart` | Home bell | NotificationRepository | **Restyle + rewire** (S26). |
| E12 | Settings (profile header, edit profile, ad privacy, language, about dialog, privacy, terms, sign out) | `features/settings/presentation/settings_page.dart` | E03 tab 2 | SecureStorage, AdService | **Superseded** by Profile (S27) + Account Settings (S28). |
| E13 | Edit Profile (name + phone) | `features/settings/presentation/edit_profile_page.dart` | E12 | UserRepository.updateProfile | **Rework** to display name (S29). |
| E14 | Language picker sheet | `shared/widgets/language_picker.dart` | E12 | LocaleController | **Keep logic, restyle** (S30). |
| E15 | About dialog | `settings_page.dart` `_showAbout` | E12 | — | **Becomes a page** (S31). |
| E16 | Sign-out confirm dialog | `settings_page.dart` | E12 | — | **Restyle** (S34). New semantics: clears the demo session. |
| E17 | Privacy Policy | `features/legal/presentation/privacy_policy_page.dart` + `legal_document_page.dart` + `legal_content.dart` | E12 | static en/ar copy | **Restyle + demo notice** (S32). Content update is a launch blocker. |
| E18 | Terms & Conditions | same files | E12 | static | as above (S33). |
| E19 | Winner Celebration | `features/winner_celebration/presentation/winner_celebration_page.dart` | shell mount / realtime / push | WinnerRepository | **Restyle**. Triggered by the demo inbox in demo mode (S35). |
| E20 | Admin Auth (sign in / sign up with access code) | `features/admin_auth/...` | E02 | AuthRepository | **Untouched** (D-01). |
| E21 | Admin Shell | `features/admin_dashboard/presentation/admin_shell.dart` | Splash/E20 | — | Untouched. |
| E22 | Admin Dashboard | `admin_dashboard_page.dart` | E21 | Giveaway repos | Untouched. |
| E23 | Admin Analysis | `features/admin_analysis/...` | E21 | | Untouched. |
| E24 | Admin Profile | `features/admin_settings/...` | E21 | | Untouched. |
| E25 | Category Management | `features/categories/presentation/category_management_page.dart` | E21 | CategoryRepository | Untouched. |
| E26 | Create/Edit Giveaway | `features/create_giveaway/...` | E21 | Giveaway/Storage repos | Untouched. |
| E27 | Giveaway Analytics (+ winner wheel overlay) | `features/giveaway_analytics/...` | E22 | Winner repos | Untouched. |
| E28 | Winners page | `giveaway_analytics/presentation/widgets/winners_page.dart` | E27 | | Untouched. |

Deleted in the working tree already (not to be restored): scratch card, admin giveaways list.

---

## 7. Target Screen Inventory

**38 planned surfaces** (S01–S38). Full spec sheets are in **Appendix B**. "Ref" = design reference file.

| ID | Surface | Ref | New/Existing | Primary contract(s) |
|---|---|---|---|---|
| S01 | Redesigned Splash | `splash-page.png` | E01 replaced in demo mode | SessionRepository |
| S02 | Welcome | `welcome-page.png` | new | — |
| S03 | Login | none (extends auth style) | new | AuthGateway |
| S04 | Forgot Password (email) | none (reuses S06 layout) | new | OtpVerifier |
| S05 | Reset Password (new password, reset mode of S08) | none | new | AuthGateway |
| S06 | Email Entry | `signin-page.png` | new | RegistrationCubit |
| S07 | OTP Verification | `otp-page.png` | new | OtpVerifier |
| S08 | Create Password | `create-password-page.png` | new | AuthGateway |
| S09 | Choose Character (onboarding + change mode) | `character-page.png` | new | CharacterRepository, AccountRepository |
| S10 | Main Shell + bottom navigation | nav bars in home/category/wallet/profile refs | new (replaces E03) | AccountRepository (avatar) |
| S11 | Home (+ inline search results) | `home-page.png` | new (replaces E04) | Wallet, Catalog, GiveawayFeed, Inbox |
| S12 | Categories (+ filter) | `category-page.png` | new | CatalogRepository |
| S13 | Category Details | `categoryDetails -page.png` | new | CatalogRepository, WalletRepository |
| S14 | Redeem Sheet (product details + confirmation) | none (extends S13 card) | new | Catalog, Wallet |
| S15 | Redemption Result (success / insufficient / failure) | none | new | OrderRepository |
| S16 | Wallet | `wallet-page.png` | new | WalletRepository, InboxRepository |
| S17 | Earn Hub ("Fast, Earn") | none | new | — (navigation hub) |
| S18 | Refer a Friend | none | new | ReferralRepository |
| S19 | All Giveaways (see all + status filter) | none (reuses S11 cards) | new | GiveawayFeedRepository |
| S20 | Giveaway Details | none (restyle of E05) | existing | GiveawayFeed, GiveawayEntry |
| S21 | Participation Flow (+ reward-frame choice) | none | existing E06/E08 | GiveawayEntryRepository, AdService |
| S22 | Number Reveal | none | existing E09 | GiveawayEntryRepository |
| S23 | My Giveaways | none | existing E10 | GiveawayEntryRepository |
| S24 | My Orders | none | new | OrderRepository |
| S25 | Order Details | none | new | OrderRepository |
| S26 | Notifications | none | existing E11 | InboxRepository |
| S27 | Profile | `profile-page.png` | new (replaces E12) | Account, Wallet, Entry, Order, Inbox |
| S28 | Account Settings (gear) | none | new | AdService, DemoStore (reset) |
| S29 | Edit Profile (display name) | none | existing E13 reworked | AccountRepository |
| S30 | Language sheet | none | existing E14 | LocaleController |
| S31 | About | none | new page (was dialog) | package info constants |
| S32 | Privacy Policy | none | existing E17 | static content |
| S33 | Terms & Conditions | none | existing E18 | static content |
| S34 | Sign-out confirmation | none | existing E16 | SessionRepository |
| S35 | Winner Celebration | none | existing E19 | InboxRepository / GiveawayEntryRepository |
| S36 | Session Expired | none | new | SessionRepository |
| S37 | Demo Tools (demo builds only) | none | new | DemoStore |
| S38 | Misconfigured Build blocker | none | new | AppEnvironment |

Shared state components (not counted as screens): skeleton loaders, `EmptyState`, `ErrorState`, `OfflineBanner`, `UnavailableNotice`, `DemoBanner`.

---

## 8. Exact User Registration Flow

```
S01 Splash ──(no session)──▶ S02 Welcome
S02 ──Get Started──▶ S06 Email ──Send Code──▶ S07 OTP ──valid──▶ S08 Create Password ──Create Account──▶ S09 Choose Character ──Continue──▶ S10/S11 Home
S02 ──Login──▶ S03 Login (§9)
```

Rules (non-negotiable):

1. The order is exactly as above. No extra pages are inserted. Character selection always comes **after** password creation. OTP is never skipped.
2. The flow is orchestrated by **`RegistrationCubit`** (`lib/features/auth/presentation/bloc/registration_cubit.dart`). It is provided above the four onboarding routes with a `BlocProvider.value` passed on each push. State:
   ```dart
   enum RegistrationStep { email, otp, password, character, done }
   class RegistrationState { RegistrationStep step; String email; bool otpVerified; OtpTicket? ticket;
     DateTime? resendAvailableAt; String? selectedCharacterId; RegistrationStatus status; Failure? failure; }
   ```
   It holds the email in memory only. It **never holds the password** in state: the password goes straight from the field controller to `AuthGateway.register` and is not kept anywhere.
3. **Progress indicator** (refs show a segmented bar with a dot marking the current step): 4 segments = Email (1), OTP (2), Password (3), Character (4). Welcome has none.
4. **Back behaviour**: back on S07 returns to S06 with the email kept. Editing the email resets `otpVerified`. Back on S08 returns to S07 (still verified; the code is not asked for again within the ticket lifetime of 10 min, otherwise it is). **Back on S09 is blocked**: the account already exists. Show a localised hint "Choose a character to finish" (snackbar) instead of popping. Android system back on S09 → same hint.
5. **Account creation happens at S08** (`AuthGateway.register(email, password, otpTicket)`). It returns an `AuthSession` with `user.characterId == null`. From that moment the session is persisted, and a relaunch routes to S09 (incomplete onboarding, §9.3).
6. **S09 Continue** → `AccountRepository.setCharacter(id)` → `SessionController` marks onboarding complete → `pushAndRemoveUntil(MainShell)`.
7. Email validation (local): trimmed, lower-cased, regex `^[^\s@]+@[^\s@]+\.[^\s@]{2,}$`, max 254 chars. Error strings are localised.
8. Email already registered (demo: an account with that email exists in the `DemoStore`): S06 shows an inline message "This email already has an account" with a **Log in instead** action → S03 pre-filled. (The real VPS may prefer not to disclose this. The contract returns `EmailAlreadyRegisteredFailure` either way, and the UI handles it.)

---

## 9. Returning User and Login Flow

### 9.1 Splash routing (S01, `SplashCubit._resolveDestination`)

```
if AppEnvironment.misconfigured            → S38 (blocking)
if lastRole == 'admin' && D-01 keeps admin → existing admin logic (unchanged)
session = await SessionRepository.restore()
  SessionRestore.none                       → S02 Welcome
  SessionRestore.expired                    → S36 Session Expired (→ S03 with email prefilled)
  SessionRestore.active(user.characterId==null) → S09 (onboarding mode, back blocked)
  SessionRestore.active(complete)           → S10 MainShell (Home tab)
```
`SplashDestination` gains `welcome`, `characterOnboarding`, `main`, `sessionExpired`, `misconfigured`. `roleSelection` and `userHome` are no longer returned for the user path. The 3-second minimum visible duration is **unchanged** and nothing adds time on top of it.

### 9.2 Login (S03)
- Fields: email, password (show/hide). Links: "Forgot password?" → S04. Footer: "New here? **Get started**" → S06.
- Demo semantics (§18.4): the email must belong to an account in `DemoStore`. The seeded `demo@example.com` always exists. The password must be **non-empty** and satisfy the format rules. The demo **does not verify the password value**, because none was stored. A visible `DemoBanner` says so ("Demo mode: passwords are not checked").
- Unknown email → `AccountNotFoundFailure` → inline error with a "Create an account" action.
- Success → session persisted → routing as in 9.1 (S09 if no character, else MainShell).

### 9.3 Incomplete onboarding
An account with no `characterId` always lands on S09 in onboarding mode, whether it came from a relaunch or a login.

### 9.4 Password recovery (S04 → S07 → S05)
S04 (email) → `OtpVerifier.requestCode(email, OtpPurpose.passwordReset)` → S07 in reset mode (same widget, different title "Reset your password") → S05 = S08 widget in `mode: reset` (button "Save password") → `AuthGateway.resetPassword(email, newPassword, ticket)`. In demo this succeeds with no storage. Snackbar "Password updated" → S03 with the email prefilled. The progress indicator is hidden in reset mode.

### 9.5 Session persistence and expiry
- Demo session record (secure storage key `demo_session_v1`): `{sessionId: uuid v4, userId, issuedAt, expiresAt = issuedAt + 30 days}`. Restored at the splash.
- Expired → S36: "Your session has expired. Please log in again." → S03 (email prefilled). The demo data (orders, entries) remains.
- Demo Tools (S37) has "Expire session now" so testers can reproduce it.
- `SessionController` (a `ValueNotifier<SessionState>`) is the single source of auth state. Any repository returning `SessionExpiredFailure` calls `SessionController.markExpired()`. A root-level listener in `RewardsApp` then pushes S36 and clears the stack.

### 9.6 Logout (S34)
Confirm dialog → `SessionRepository.signOut()`. This deletes only `demo_session_v1`, invalidates the push token in api mode, and resets in-memory cubits by clearing the stack. It **keeps**: the language preference, ad consent state, `DemoStore` account data (so logging back in restores orders and entries). Then `pushAndRemoveUntil(WelcomePage)`.

---

## 10. Navigation Architecture

### 10.1 Root
- `MaterialApp.home` stays `SplashPage`. Locale handling is unchanged (`ValueListenableBuilder<Locale>`).
- New `lib/core/routing/app_routes.dart`: static typed helpers (`AppRoutes.toWelcome(context)`, `toCategoryDetails(context, categoryId)`, …). This keeps route construction in one place and avoids scattered `MaterialPageRoute`s. Each helper uses `MaterialPageRoute`, or a `PageRouteBuilder` with the shared transition (§30).
- `navigatorKey` (global) is added to `MaterialApp` so the session-expiry listener and push-notification routing can navigate without a widget context.

### 10.2 Main Shell (S10) — `lib/features/shell/presentation/main_shell.dart`
- `IndexedStack` of 4 tab roots: `HomePage`, `CategoriesPage`, `WalletPage`, `ProfilePage`. Tab state and scroll position are preserved (`PageStorageKey` per scroll view).
- Detail screens (S13, S20, S24, …) push on the **root** navigator and cover the bottom bar, matching the category-details reference, which has no nav bar.
- `MainShellController` (a ChangeNotifier provided via `InheritedNotifier`/`Provider`-free `context.read` through a `BlocProvider<ShellCubit>`) exposes `selectTab(ShellTab tab)`. It is used by Wallet → "Place an Order" (switches to Categories) and by the profile stats.
- **Android back** (`PopScope(canPop: false)` on the shell): if the current tab ≠ Home, switch to Home. If on Home, allow the system to background the app (`SystemNavigator.pop()`). Nested pushed routes pop normally.
- Banner ad slot: `UserTabScaffold`-style dock = `[AdaptiveAdBanner (if D-05 keeps it), RewardsBottomNav]`, hidden while the keyboard is open (the existing behaviour).
- Lifecycle duties moved from `UserHomeShell`: `AdService.startUserSession`/`endUserSession`, a notification-tap subscription, and the winner-celebration check (through `InboxRepository.watch()` in demo mode instead of Supabase realtime).

### 10.3 Bottom navigation — `lib/shared/ui/rewards_bottom_nav.dart`
- Flat white surface (`#FFFFFF` at 96% over the page), top hairline `#EEEAF8`, height 72 + bottom safe area, radius 0 (the refs show a full-width bar).
- 4 items, **with labels** (refs show labels): Home (`LucideIcons.house`), Categories (`layoutGrid`), Wallet (`wallet`), Profile (**character avatar**, 40 dp circle, white 2 dp ring; selected adds a 2 dp primary ring).
- Selected: icon filled/primary `#4318FF`, label primary w600, plus a 28×3 dp rounded underline indicator under the label (category ref). Unselected: icon `#8A86A6`, label `#8A86A6` w500. Label 12 sp.
- Label for tab 1: "Home". The refs alternate between "Home" and "Explore". Decision D-15 defaults to **Home** (spec section 7 lists "Home / Explore").
- Profile tab semantic label: "Profile". The avatar image is decorative (`excludeSemantics`).
- RTL: the item order mirrors automatically (Row in Directionality).
- Do **not** reuse `AppBottomNav` (Liquid Glass, icon-only). It stays for Admin.

### 10.4 Push-notification and in-app notification routing
`shared/utils/notification_routing.dart` is generalised to route by `type`: `giveaway` → S20, `winner_announcement` → S35, `order_status` → S25, `referral` → S18, `generic` → S26. The legacy Supabase winner lookup moves behind `GiveawayEntryRepository.pendingWinCelebration()`.

---

## 11. Visual Reference Mapping

All references are 1024×1536 renders of a phone (~650 px screen width ≈ 393 dp; scale factor ≈ 1.65 px/dp). Colours were sampled from the PNGs and are approximate. Refine them by eye during the golden pass.

| Reference | Screen | Implement in Flutter (code) | Needs raster asset |
|---|---|---|---|
| `splash-page.png` | S01 | Implement the new gift, points, and progress composition with real Flutter text and a decorative illustration. | Supplied reference; locally extracted or generated artwork |
| `welcome-page.png` | S02 | Pastel gradient bg + blurred blobs, 2-line headline (navy "Your Rewards" / violet→purple gradient text "Journey Starts Here"), body copy, dark pill CTA `#0E0E1F` with arrow, "Already have an account? **Login**" (violet `#8704FA`) | **USER**: 3D hero cluster (bag, coin, gift, crown, coupon, card) `onboarding_welcome_hero` |
| `signin-page.png` | S06 | Circular white back button 56 dp, 4-step progress bar, headline "What's your **email?**" (accent `#411EFB`), subtitle grey `#7C7898`, input 64 dp radius 22 white 80% with mail icon, primary pill CTA `#3822FB` 64 dp radius 32 with trailing arrow | **AGENT**: envelope + coins + paper plane `auth_email_hero` |
| `otp-page.png` | S07 | Headline "Check your **email**", "We've sent a 6-digit code to" + bold email, 6 boxes 52×64 dp radius 16 white, underlined link "Resend code in 00:28" (primary) | **AGENT**: open envelope with code card `auth_otp_hero` |
| `create-password-page.png` | S08 | Headline "Create a **password**", two fields with lock icon + eye toggle + floating label, 3 rule rows with green check circles `#22C55E`, primary CTA "Create Account →" | **AGENT**: purple padlock on clouds `auth_password_hero` |
| `character-page.png` | S09 | Back arrow (hidden in onboarding mode per §8.4), progress bar, headline "Choose Your Character", subtitle, 3×3 grid of rounded tiles (radius 22, pastel bg per character), selected = 2.5 dp primary border + 36 dp check badge top-end, page dots (decorative, see note), primary CTA "Continue →" | **AGENT**: 9 character portraits (§14.2) |
| `home-page.png` | S11 | Pastel aurora header (lavender/pink/blue), "Your Points" (violet `#5B3DF5` 26 sp w600), balance 76 sp w800 primary `#3A1FF0`, "PTS" 34 sp w700 lavender `#A77BF9`, bell in white 52 dp circle + red dot `#FF3B30`; search pill 56 dp white 85% + shadow; "Available Rewards" 24 sp w800 navy `#0A0E2F`, horizontal tiles (image 140×148 radius 18 + title 15 sp w700 + subtitle 12 sp grey); section "Giveaways" (the ref shows "Rewards"; renamed per brief) 2-col pastel cards (lavender `#EEEAFE`, pink `#FCE7F3`, blue `#E6EEFF`, peach `#FDEBDD`) with product image, title, subtitle, white 44 dp chevron circle | **AGENT**: category tiles; giveaway prize images |
| `category-page.png` | S12 | Title "Categories" 34 sp w800, search icon; full-width banners radius 22, aspect ≈ 3.8:1 (min 96 dp), gradient per category, title 24 sp w800 white, subtitle 15 sp white 90%, artwork on the end side | **AGENT** (brand-neutral) + **USER** (licensed logos, D-09) |
| `categoryDetails -page.png` | S13 | Hero ≈ 290 dp with artwork and dark-to-transparent scrim, back + heart buttons, app icon tile 120 dp radius 26, title 30 sp w800 white, subtitle; overlapping sheet radius 28 `#F5F4FD`; segmented control 48 dp (active `#6C33FA` pill, inactive `#ECEAFD`); 2-col product cards (image well lavender gradient, radius 20) with denomination 22 sp w800, price "1,200 PTS" 20 sp w700 violet `#8B4CF7`, Redeem button 48 dp radius 16 `#6430F6` | **AGENT**: hero art, UC tier images |
| `wallet-page.png` | S16 | "Your Rewards" 26 sp w700, bell + badge; balance card radius 32, 210 dp, gradient `#4F49FC → #8D67FC → #C77DF5 → #F3A0E8`, "POINTS" white w700 26 sp / "BALANCE" white 70%, amount 80 sp w800 white, "PTS" 36 sp white 60%, translucent crown glyph; "Fast, Earn" CTA 72 dp radius 36 `#5032FC` with gift icon + chevron; 3 action rows 96 dp radius 24 white 75% with 64 dp icon tile (lavender `#EFE6FD` cart, amber `#FDF3E5` star, pink `#FEE9FC` users) | Crown: **CODE** (CustomPainter) unless the **USER** supplies art (D-06) |
| `profile-page.png` | S27 | Pastel decorative header (coins, crown, gamepad, heart), avatar 168 dp rounded-square radius 44 with white 4 dp ring, edit badge 56 dp white circle + pencil; name 30 sp w800, email 16 sp grey; stats strip (3 columns, dividers, value 32 sp w800 primary, label 16 sp grey) in a white 70% card radius 24; menu rows 64 dp radius 18 white 75% with outline icon 26 dp, title 18 sp, trailing value/badge/chevron | **USER/AGENT**: `profile_header_decor` |

Deviations from the references that are **required by the brief** (do not "fix" them back):
- Profile: the Wallet row is **removed**, a **Sign Out** row is **added**, and the back arrow is hidden (Profile is a tab root).
- Home: the section title is "Giveaways" (the ref says "Rewards"), and cards get a status chip.
- Wallet rows: the subtitles are changed for policy compliance (§22.4).
- Character page dots: the ref shows 3 page dots under the grid, implying more characters. The brief fixes **9 characters**, so the dots are omitted (D-16).

---

## 12. Design System Specification

New files (do not modify `app_colors.dart` / `app_theme.dart`, which Admin uses):

```
lib/core/theme/rewards_colors.dart      RewardsColors (+ gradients)
lib/core/theme/rewards_typography.dart  RewardsText
lib/core/theme/rewards_tokens.dart      RSpace, RRadius, RShadow, RMotion, RSize
lib/core/theme/rewards_theme.dart       ThemeData for the redesigned app (MaterialApp.theme switches to it; Admin routes wrap in Theme(data: AppTheme.light))
lib/shared/ui/                          reusable components (below)
```

### 12.1 Colour tokens

| Token | Hex | Use |
|---|---|---|
| `primary` | `#3B22F6` | Primary CTAs, active states, OTP accents |
| `primaryDeep` | `#2A12D9` | Pressed state |
| `violet` | `#6430F6` | Category-detail Redeem, segmented active |
| `purple` | `#8B4CF7` | PTS prices, secondary accent |
| `lavender` | `#A77BF9` | "PTS" label on Home |
| `lavender50` | `#F5F3FE` | Sheet/screen bg tint |
| `lavender100` | `#EEEAFE` | Card well, inactive segment `#ECEAFD` |
| `pink` | `#F3A0E8` / `pink50 #FCE7F3` | Gradients, referral tint |
| `blue` | `#6E8BFF` / `blue50 #E6EEFF` | Aurora bg, card tint |
| `peach50` | `#FDEBDD` | Card tint |
| `amber50` | `#FDF3E5`, `amber #F5B72E` | Review row, coins |
| `navy` | `#0A0E2F` | Headlines |
| `ink` | `#1B1B2F` | Body text |
| `muted` | `#7C7898` | Subtitles |
| `hint` | `#A9A6BF` | Placeholders |
| `stroke` | `#ECE8F7` | Borders/dividers |
| `surface` | `#FFFFFF` | Cards (often at 75–85% opacity over aurora) |
| `ctaDark` | `#0E0E1F` | Welcome CTA |
| `success` | `#22C55E` | Rules, completed |
| `warning` | `#F59E0B` | Processing, upcoming |
| `danger` | `#FF3B30` | Badges, errors, sign out |
| `info` | `#246BEB` | Upcoming chip (reuse `AppVisuals.upcoming`) |
| `ended` | `#757986` | Ended chip |

Gradients: `auroraBackground` (radial blobs: lavender `#DCD3FF` @ top-start, pink `#F9D5F3` @ top-end, blue `#D6E0FF` @ mid-start, on `#F7F5FF`), `walletCard` (linear 135°: `#4F49FC, #8D67FC, #C77DF5, #F3A0E8`), `headlineAccent` (`#3B22F6 → #8704FA`, for gradient text), `categoryGradient(List<Color>)` built from catalog data (backend-managed).

Status colour mapping: Available → `success`; Upcoming → `info`; Ended → `ended`; Order pending → `warning`; processing → `primary`; completed → `success`; failed/refunded → `danger`.

### 12.2 Typography (`RewardsText`)
Headings use Plus Jakarta Sans and body uses Manrope. Arabic falls back to the bundled Arabic font (D-12, default **IBM Plex Sans Arabic**, OFL) through `fontFamilyFallback`.

| Style | Size/Line | Weight | Letter spacing |
|---|---|---|---|
| `display` (balances) | 76/80 | 800 | −2% |
| `h1` (screen titles: Categories, Choose Your Character) | 32/38 | 800 | −1.5% |
| `h2` (auth headlines) | 30/36 | 800 | −1% |
| `h3` (section titles) | 22/28 | 800 | −0.5% |
| `title` (card/row titles) | 17/22 | 700 | 0 |
| `body` | 15/22 | 500 | 0 |
| `bodyMuted` | 15/22 | 500, `muted` | 0 |
| `label` (buttons) | 17/22 | 700 | 0 |
| `caption` | 12/16 | 600 | +1% |
| `price` | 18/22 | 700, `purple` | 0 |

The balance uses `FittedBox(fit: BoxFit.scaleDown)` so 6–7 digits never overflow at 320 dp.

### 12.3 Spacing, radius, shadow, motion
- `RSpace`: 4, 8, 12, 16, 20 (screen gutter), 24, 32, 40, 48.
- `RRadius`: chip 12, field 22, tile 18, card 24, sheet 28, button 32 (pill), avatar 44, full.
- `RShadow.soft`: `0 8 24 rgba(59,34,246,0.08)`. `RShadow.cta`: `0 10 24 rgba(59,34,246,0.30)`. `RShadow.card`: `0 4 16 rgba(17,12,46,0.06)`.
- `RMotion`: fast 150 ms, normal 250 ms, slow 400 ms. Curve `Curves.easeOutCubic`. All animation durations collapse to zero when `MediaQuery.disableAnimations` is set.
- `RSize`: touch target ≥ 48, CTA height 60 (64 on auth), field 64, nav 72, icon 24, OTP box 52×64 (shrinks to 44×56 below 360 dp).

### 12.4 Components (`lib/shared/ui/`)

| Component | File | Notes |
|---|---|---|
| `PrimaryPillButton` | `buttons.dart` | Filled `primary`, CTA shadow, trailing arrow icon (mirrors in RTL), `isLoading`, disabled at 40% opacity, min height 60 |
| `DarkPillButton` | `buttons.dart` | `ctaDark` variant (Welcome) |
| `SecondaryButton` / `TextLink` | `buttons.dart` | Outline or underlined link |
| `CircleIconButton` | `circle_icon_button.dart` | 52 dp white circle, optional red dot badge or count badge |
| `RewardsTextField` | `rewards_text_field.dart` | Leading icon, floating label, password toggle with semantics "Show password"/"Hide password", error text, `autofillHints` |
| `OtpCodeInput` | `otp_code_input.dart` | 6 boxes backed by **one** hidden `TextField` (paste-friendly, `AutofillHints.oneTimeCode`, digits only, normalises Arabic-Indic digits ٠-٩ to 0-9) |
| `StepProgress` | `step_progress.dart` | 4 segments + current dot; semantics "Step 2 of 4" |
| `AuroraBackground` | `aurora_background.dart` | Static `CustomPainter` with radial gradients, **no BackdropFilter**, wrapped in `RepaintBoundary` |
| `GlassCard` | `cards.dart` | White 75–85% + 1 dp white border + soft shadow (no blur) |
| `MenuRow` | `menu_row.dart` | Icon, title, optional trailing value/badge, chevron (directional) |
| `ActionRow` | `action_row.dart` | Wallet rows: tinted icon tile + title + subtitle + chevron |
| `StatStrip` | `stat_strip.dart` | 3 tappable stats with dividers |
| `CategoryBanner` / `CategoryTile` | `category_widgets.dart` | Data-driven gradient + `AppImage` |
| `ProductCard` | `product_card.dart` | Image well, denomination, price, Redeem button; disabled "Out of stock" |
| `GiveawayCard` | `giveaway_card.dart` | Pastel tint, image, title, subtitle, chevron, `StatusChip` |
| `StatusChip` | `status_chip.dart` | Available/Upcoming/Ended/order statuses |
| `SegmentedTabs` | `segmented_tabs.dart` | Pill segmented control, keyboard/semantics as tabs |
| `PointsBalanceCard` + `CrownPainter` | `points_balance_card.dart` | Wallet card |
| `PointsHeader` | `points_header.dart` | Home header (no card, per brief) |
| `CharacterTile` / `CharacterAvatar` | `character_widgets.dart` | Grid tile with selection; avatar for nav/profile |
| `AppImage` | `app_image.dart` | Resolves `ImageRef` (asset or network via `cached_network_image`), sized decode (`cacheWidth`), shimmer placeholder, branded fallback |
| `Skeleton` | `skeleton.dart` | Pulse (static when reduced motion) |
| `EmptyState` / `ErrorState` / `OfflineBanner` / `UnavailableNotice` | `states.dart` | Illustration + title + body + optional action |
| `RewardsSheet` / `RewardsDialog` | `sheets.dart` | Radius 28, drag handle, safe-area aware |
| `DemoBanner` / `DemoChip` | `demo_badge.dart` | Rendered only when `AppEnvironment.isDemo` |
| `showRewardsSnack` | `feedback.dart` | Floating snackbar, success/error/info variants |

---

## 13. Asset Generation Capability Assessment

Inspected on 2026-10-19 in this environment. Tool schemas were inspected. **No generation call was made** (planning-only phase, and generation consumes paid credits).

| Capability | Available? | Tool / method | Notes / constraints |
|---|---|---|---|
| AI raster image generation | **Yes (conditional)** | Figma MCP `generate_image` (models: `gemini-3.1-flash-lite-image` default, `gemini-3.1-flash-image`, `gpt-image-2.5-sunburst`) | **Paid**: consumes Figma AI credits per call. Needs a Figma design file (`create_new_file` first). Output is placed in Figma; full-resolution `image.url` is downloadable via `curl`. Max 2048 px; the model picks the nearest supported aspect ratio. **Requires explicit user approval per batch.** Transparency support is unverified, so it must be tested in `ASSET-001`. |
| AI generation via Weave | Possibly | Figma MCP `weave_find_model` / `weave_run_model` | Cost-gated (quote → user approval). Not inspected further. Fallback only. |
| Background removal | **Yes (conditional)** | Adobe MCP `image_remove_background` (transparent PNG cutout) | Requires `adobe_mandatory_init` and a fetchable image URI (upload via `asset_add_file`). Account limits are unverified. |
| Smart crop / resize | Yes | Adobe `image_crop_and_resize`; **local Python PIL 10.1** | PIL is preferred for deterministic resizing. |
| Generative expand / fill | Yes (Adobe) | `image_generative_expand`, `image_fill_area` | Useful for widening category banners to 3.8:1. |
| Vectorise raster → SVG | Yes (Adobe) | `image_vectorize` | The app has no `flutter_svg`. Not needed. |
| SVG authoring | Yes | Hand-written by the agent | Only useful for icons/shapes. Prefer Lucide icons and `CustomPainter` in Flutter instead. |
| Transparent PNG export | Yes | PIL (RGBA) | |
| WebP encode (incl. alpha) | **Yes** | PIL `features.check('webp') == True` | Chosen delivery format for bundled raster art. |
| Image optimisation | Partial | PIL quality/method settings | `pngquant`, `cwebp`, ImageMagick are **not installed** (`convert` resolves to Windows `convert.exe`, which is not ImageMagick). |
| Local AI background removal | **No** | `rembg` not installed | Use Adobe, or generate on a flat chroma background and key it out with PIL as a last resort (lower quality). |
| Lottie authoring | No | LottieFiles MCP requires authorisation (not connected) | Reuse the existing 4 Lottie files. |
| Hugging Face / Google Drive MCP | No | Need OAuth in claude.ai connector settings | Not required. |

**Conclusion.** Raster artwork *can* be generated in this environment, but only through paid, approval-gated cloud tools. Default workflow (`ASSET-001` verifies it end-to-end on one character before anything is batch-generated):

1. Create one Figma file "Creative Rewards — Asset Generation".
2. Generate with the **style-lock prompt** (§14.5) at 1024×1024 (characters, products) or 2048×(aspect) (banners and heroes).
3. Download via `image.url` into `C:\Users\DELL\AppData\Local\Temp\claude\…\scratchpad\assets_raw\` (never directly into `assets/`).
4. Cut out the background with Adobe `image_remove_background` if the model did not return alpha.
5. Use a PIL script (`tool/assets/process_assets.py`, created in `ASSET-003`) to trim, pad, resize to the target dimensions plus 2× variants, export WebP (q=82, method=6, alpha kept) and write a manifest check.
6. Review the results against the references as a contact sheet before committing.

If credits or approval are unavailable, the agent **must not** substitute low-quality placeholders as "final". Instead it ships the prompt pack (§14.5) for external generation and uses the explicit `AppImage` fallback (a gradient plus a Lucide glyph, labelled `placeholder` in the manifest) until the real art arrives.

---

## 14. Asset Inventory and Generation Strategy

### 14.1 Directory layout and registration

```
assets/
  images/
    characters/      char_01_hoodie_boy.webp … char_09_bunny_girl.webp      (bundled, permanent)
    illustrations/   onboarding_welcome_hero.webp, auth_email_hero.webp, auth_otp_hero.webp,
                     auth_password_hero.webp, profile_header_decor.webp,
                     empty_orders.webp, empty_giveaways.webp, empty_notifications.webp,
                     empty_search.webp, state_offline.webp, state_error.webp
    categories/      <slug>_banner.webp, <slug>_tile.webp, <slug>_hero.webp, <slug>_icon.webp   (DEMO SEED of backend-managed content)
    products/        <categorySlug>_<sku>.webp                                                  (DEMO SEED)
    giveaways/       gw_<slug>.webp                                                             (DEMO SEED)
  icons/             (reserved; Lucide covers current needs)
  animations/        (move nothing — existing lottie/ stays at assets/lottie/ to avoid churn)
  img/, lottie/, fonts/   (existing, unchanged)
```

`pubspec.yaml` registration (implementation step): add each directory explicitly (`assets/images/characters/`, `…/illustrations/`, `…/categories/`, `…/products/`, `…/giveaways/`). Flutter does not recurse.

Naming: `snake_case`, ASCII, `[a-z0-9_]`, with no spaces or brackets. The category slug equals the `Category.slug` in seed data.

### 14.2 Manifest (source: USER = user supplies; AGENT = agent generates; CODE = drawn in Flutter)

| Asset | Source | Size (px, 1×/master) | Ratio | Alpha | Notes |
|---|---|---|---|---|---|
| `onboarding_welcome_hero` | **USER** | 1200×1100 | ~1.1:1 | yes | 3D shopping bag, star coins, gift, crown, coupon, card, orbs (welcome ref) |
| `auth_email_hero` | AGENT | 1200×900 | 4:3 | yes | Lavender 3D envelope, gold star coins, paper plane, sparkles, soft clouds |
| `auth_otp_hero` | AGENT | 1200×1000 | 6:5 | yes | Open envelope with a code card "• • • 8 3 3", coins, plane, heart |
| `auth_password_hero` | AGENT | 1200×900 | 4:3 | yes | Purple 3D padlock on clouds, coins, sparkles |
| `char_01_hoodie_boy` … `char_09_bunny_girl` | AGENT | 1024×1024 master → 512 delivered | 1:1 | yes (bg drawn by tile) | 1 boy, dark tousled hair, purple hoodie · 2 girl, pink hair, white headphones, pink jacket · 3 kid in panda hood · 4 white/silver robot astronaut, blue visor eyes · 5 kid in orange fox-ear hood + sunglasses · 6 kid in green dino hood · 7 kid in brown bear hood · 8 boy, blue backwards cap + sunglasses, denim jacket · 9 girl in white bunny-ear hood. Chest-up, facing camera, same lighting/camera/scale |
| Character tile backgrounds | CODE | — | — | — | Per-character pastel colour stored in seed (`Character.backgroundHex`) |
| `profile_header_decor` | USER (fallback AGENT) | 1290×700 | ~1.85:1 | yes | Coins, crown, gamepad, heart, stars scattered around a centre void for the avatar |
| Wallet crown | CODE (USER override, D-06) | — | — | — | `CrownPainter`, white at 25% opacity |
| Wallet decorative elements | USER (optional) | 1000×600 | — | yes | Only if the user supplies them; otherwise gradients only |
| `pubg_mobile_*`, `valorant_*`, `instagram_*`, `tiktok_*`, `facebook_*`, `phones_*` banner | AGENT (brand-neutral) / USER (licensed brand art) | 1520×400 | 3.8:1 | no (full-bleed, art on the end side, left 55% kept clear for text) | **See D-09.** Agent art must not reproduce official characters, logos or key art |
| same `_tile` | AGENT/USER | 400×428 | ~0.93:1 | no | Home "Available Rewards" rail |
| same `_hero` | AGENT/USER | 1290×780 | ~1.65:1 | no | Category details hero; art on the end side |
| same `_icon` | USER (licensed) / AGENT (generic) | 256×256 | 1:1 | no | Square app-icon tile in the hero |
| Optional extra categories (e.g. `gift_cards`, `accessories`) | AGENT | as above | | | Only if D-08 adds them |
| `pubg_mobile_uc_60/180/325/660/1800/3850` | AGENT | 512×384 | 4:3 | yes | Gold-on-black "currency token" stacks in **increasing quantity**: 1 token, small stack, pile, bigger pile, open chest, big chest with tokens. Must not copy the official UC glyph unless licensed (D-09) |
| `valorant_vp_*` (3) | AGENT | 512×384 | 4:3 | yes | Generic red/white gem-points stacks |
| `social_growth_*` (3 shared by IG/TikTok/FB) | AGENT | 512×384 | 4:3 | yes | Abstract "growth" icons (rocket, heart burst, chart). No platform logos (D-10) |
| `phones_*` (3) | AGENT | 512×512 | 1:1 | yes | **Generic** smartphone renders (no Apple/Samsung design copying) |
| `gw_earbuds`, `gw_smartphone`, `gw_console`, `gw_coffee_machine`, `gw_smartwatch`, `gw_headphones` | AGENT | 640×640 | 1:1 | yes | Generic product renders. Titles in seed may name products (D-09) |
| Empty/error illustrations (6) | AGENT | 720×560 | ~1.3:1 | yes | Same 3D pastel style: empty box with coins (orders), gift with question mark (giveaways), sleeping bell (notifications), magnifier (search), cloud with slash (offline), broken coin (error) |
| Nav/menu/row icons | CODE (Lucide) | — | — | — | `AppIcons` additions |
| Aurora backgrounds, gradients, rules checks, crown | CODE | — | — | — | |
| Splash | **existing** `assets/lottie/splash.json` | — | — | — | Unchanged |

Delivery format: **WebP with alpha**, quality 82. Banners and heroes are delivered at 2× of the largest logical size: banner 361×95 dp × 3 ≈ 1083 px wide minimum, and 1520 is fine. **Total new bundled asset budget: ≤ 6 MB.** It is checked by a test that sums `assets/images/**` file sizes (`ASSET-012`).

### 14.3 Bundled vs backend-managed

| Kind | Demo source | Production source | Widget contract |
|---|---|---|---|
| Characters | bundled | bundled (ids stored server-side) | `Character.image = ImageRef.asset(...)` |
| Onboarding/auth/empty illustrations | bundled | bundled | direct `Image.asset` via `AppImage` |
| Categories, products, giveaways images | bundled seed (`ImageRef.asset`) | Admin-Dashboard URLs (`ImageRef.network`) | **Always** `AppImage(ref)`. Never `Image.asset` directly in catalog widgets |

`ImageRef` (sealed): `AssetImageRef(path)`, `NetworkImageRef(url, {blurHash?})`. JSON form: `{"kind":"asset","path":"..."}` / `{"kind":"url","url":"..."}`. The future DTO mapper turns server URL strings into `NetworkImageRef`.

### 14.4 Cache and fallback
- Network images: `cached_network_image` (already a dependency) through `AppImage`, `memCacheWidth = (logicalWidth * devicePixelRatio).round()`, fade-in 150 ms (0 with reduced motion).
- Fallback: on load error or a null ref, show the category gradient (or `lavender100`) plus a centred Lucide glyph (`gift`, `gamepad2`, `smartphone`). Never show a broken-image icon.
- `precacheImage` for the four auth heroes during splash idle time (no added splash duration). Character images are precached when S09 opens.

### 14.5 Prompt pack (used with Figma `generate_image`, or handed to an external tool)

**Style lock (prepend to every prompt):**
> "Soft 3D render, Pixar-like stylised, glossy clay materials, pastel lavender/violet palette with warm gold accents, soft studio key light from top-left, gentle rim light, subtle ambient occlusion, clean edges, centered composition, isolated on a plain solid #FF00FF background (for keying) unless stated otherwise, no text, no logos, no watermark, high detail, 4k."

**Characters (one prompt per character, identical camera):**
> "[style lock] Chest-up portrait of a cute chibi-proportioned child character, big glossy brown eyes, friendly closed-mouth smile, facing the camera, head occupying 60% of the frame height, shoulders cut at the bottom edge. Character: {DESCRIPTION}. Consistent with a set of 9 avatar characters."

with `{DESCRIPTION}` from the manifest row. Generate char_01 first, approve it, then reuse its exact prompt structure for the other 8. Reject any output that changes the art style.

**Category banner (brand-neutral):**
> "[style lock, but background: full-bleed scene, no keying] Wide 3.8:1 banner artwork. Right 45% of the frame: {SUBJECT}. Left 55%: smooth {GRADIENT} gradient with no objects (space for text). Cinematic lighting."
Subjects: battle-royale soldier in a generic tactical helmet and goggles with a cargo plane in the sky (pubg); masked futuristic agent in dark armour with neon red accents and angular red shapes (valorant); a glossy 3D camera icon shape with a magenta-orange gradient, **not** the Instagram logo (instagram); a glossy 3D music note on a dark neon-cyan/pink background (tiktok); glossy 3D thumbs-up and people icons in blue (facebook); two modern generic smartphones, front and back, purple wallpaper (phones).

**Product tiers (pubg):** "[style lock] {N} glossy black-and-gold hexagonal game-currency tokens embossed with a generic star, arranged as {ARRANGEMENT}, 3/4 top view." Arrangements: 1 tilted token / 3 overlapping / small stack of 6 / pile of 12 / open dark treasure chest overflowing / large chest plus scattered piles.

**Empty states:** "[style lock] Small floating scene: {SCENE}, with 2 gold star coins and soft clouds below."

---

## 15. Demo Data Architecture

### 15.1 Environment (`lib/core/config/app_environment.dart`)

```dart
enum DataMode { demo, api }
enum AppFlavorEnv { dev, prod }   // mirrors existing Env.environmentName

class AppEnvironment {
  const AppEnvironment({required this.dataMode, required this.env});
  factory AppEnvironment.fromDefines() => AppEnvironment(
    dataMode: const String.fromEnvironment('DATA_MODE', defaultValue: 'demo') == 'api' ? DataMode.api : DataMode.demo,
    env: Env.isProduction ? AppFlavorEnv.prod : AppFlavorEnv.dev);
  final DataMode dataMode; final AppFlavorEnv env;
  bool get isDemo => dataMode == DataMode.demo;
  /// A production build must never run the demo data layer.
  bool get isMisconfigured => env == AppFlavorEnv.prod && dataMode == DataMode.demo;
}
```

- Registered in DI as a singleton. Tests construct arbitrary instances (consts cannot be overridden at test time, so **everything** reads the injected instance, never `String.fromEnvironment` directly).
- `main()` → if `isMisconfigured`: `runApp(MisconfiguredBuildApp())` (S38) and **do not** register demo repositories.
- Unknown `DATA_MODE` values (typos) → treated as misconfigured in prod and as demo in dev, with a debug log.

### 15.2 DemoStore (`lib/data/demo/demo_store.dart`)
- One Hive box `demo_store_v1` holding JSON maps keyed by collection: `accounts`, `ledger`, `orders`, `entries`, `inbox`, `referrals`, `meta` (`schemaVersion`, `seededAt`).
- **Seeded** catalog and giveaways are **not persisted**. They come from `DemoSeed` (const Dart data in `lib/data/demo/seed/`) on each launch, so seed edits show up without a reset. **Persisted** state is user-generated only (accounts, ledger, orders, entries, inbox, referral views).
- API: `T read<T>(collection, id)`, `List<T> list(collection, {where})`, `Future<void> transaction(void Function(DemoTx tx))`. The transaction applies all writes in memory, then one `box.putAll` (atomic from the app's perspective). `Stream<DemoChange> changes` is used for reactive UI (balance, badges, entries).
- `Future<void> reset()` (Demo Tools) clears the box and re-seeds the demo account.
- `schemaVersion` mismatch → wipe and reseed, with a debug log.
- Injectable `Clock` (`lib/core/utils/clock.dart`: `DateTime now()`) and `Random` for deterministic tests.

### 15.3 Seed data (`lib/data/demo/seed/`)
- `demo_characters.dart`: the 9 `Character`s (id `char_01`…`char_09`, localised names, asset path, bg hex: `#E9DDFF, #FFD9E8, #DCEBFF, #D9F0FF, #FFE5CC, #DDF5D6, #FFE1E6, #DCE2FF, #FCE3F1`).
- `demo_catalog.dart`: 6 categories (pubg_mobile, valorant, instagram, tiktok, facebook, phones) with localised titles/subtitles/descriptions, gradients (pubg `#0C6AB1→#2B56B8`, valorant `#372587→#E8505B`, instagram `#C51972→#F77737`, tiktok `#101225→#25F4EE` accent, facebook `#0470F8→#1E90FF`, phones `#EAD7FD→#C9D8FF` with dark text), product groups (pubg: "UC Top-Ups", "Items & Skins").
  - Products (clearly mock pricing): pubg UC 60/1,200 · 180/3,200 · 325/5,500 · 660/10,000 · 1800/25,000 · 3850/50,000; Items & Skins: "Skin voucher S" 4,000, "Skin voucher L" 9,000 (one `outOfStock`). Valorant: 475 VP 8,000 · 1000 VP 16,000 · 2050 VP 32,000. Instagram/TikTok/Facebook: 3 placeholder "Package S/M/L" each (2,000/5,000/12,000) **pending D-10**. Phones: "Accessory voucher" 15,000, "Smartphone (demo)" 150,000.
  - Each product: `requiresAccountIdentifier` + localised `identifierLabel` (pubg/valorant "Player ID", social "Profile username", phones "Delivery phone number"), plus a `deliveryNote`.
- `demo_giveaways.dart`: built on the existing `Giveaway` model (re-used, §16.1): Wireless Earbuds Pro (active, ends now+5 d, 4-digit), Flagship Smartphone (active, +12 d), Game Console (active, +2 d, `maxParticipants: 500`, `participantCount: 499`, so "full" is demonstrable after one entry), Coffee Machine (scheduled, starts +3 d), Smartwatch (ended −2 d), Studio Headphones (ended −10 d). Times are relative to `Clock.now()` at seed time and recomputed each launch. Titles are generic by default (D-09). Each has `organizerName: "Creative Rewards (demo)"`, rules text, 2 requirements (display-only).
- `demo_account.dart`: the preloaded account `demo@example.com`, display name "Demo User", `char_01`, ledger: +10,400 "Demo starting balance", −1,200 redemption (60 UC, completed), −3,200 (180 UC, processing) → balance **6,000**; 1 entry in an ended giveaway (not winner); inbox of 3 items.
- New registrations receive a `+6,000 PTS` "Demo starting balance" ledger entry (D-04 default), so redemption success **and** insufficient-points paths are both demonstrable (e.g. 60 UC succeeds; 660 UC fails).

### 15.4 Points consistency (ledger model)
- Balance = Σ `PointsTransaction.delta` for the user. It is **never** stored separately, so it can never drift.
- Transaction reasons: `demoGrant`, `redemption`, `redemptionRefund`, `referralReward` (**api mode only**; the demo never creates it), `adjustment` (api only).
- Redemption = one `DemoStore.transaction`: re-read the balance → if `< cost` → `InsufficientPointsFailure(balance, cost)`; else append ledger(−cost, ref orderId) + insert order(status `pending`) + inbox item "Order placed".
- Idempotency: `redeem()` takes a client `requestId` (uuid v4 from the cubit, created once per confirmation sheet). The store rejects duplicate `requestId`s by returning the existing order. The same contract applies to the VPS.
- Preloaded demo account balance: seed so the balance is **6,000 after history** (grant 10,400; redemptions 1,200 + 3,200). Then Profile shows "Orders 2", and new testers can still redeem.

### 15.5 State ownership

| State | Owner | Persistence |
|---|---|---|
| Session/auth | `SessionController` (+ `SessionRepository`) | secure storage `demo_session_v1` |
| Registration in progress | `RegistrationCubit` (route-scoped) | memory only |
| Current user (name, email, character) | `AccountRepository.watchCurrentUser()` → `CurrentUserCubit` (app-scoped, provided above MainShell) | DemoStore `accounts` |
| Balance | `WalletRepository.watchBalance()` → `WalletCubit` (app-scoped) | derived from ledger |
| Catalog | `CatalogRepository` → per-page cubits | seed |
| Orders | `OrderRepository.watchOrders()` → `OrdersCubit` | DemoStore `orders` |
| Entries | `GiveawayEntryRepository.watchMyEntries()` | DemoStore `entries` |
| Inbox + unread count | `InboxRepository.watch()` / `watchUnreadCount()` → `InboxCubit` (app-scoped) | DemoStore `inbox` |
| Language | `LocaleController` (existing) | secure storage `cached_language_code` |
| Tab index | `ShellCubit` | memory |

App-scoped cubits are created in a `MultiBlocProvider` wrapping `MainShell` and disposed on sign-out (stack cleared → providers dropped).

### 15.6 DI split (`lib/core/di/injection.dart`)

```dart
Future<void> configureDependencies({AppEnvironment? environment}) async {
  final env = environment ?? AppEnvironment.fromDefines();
  getIt.registerSingleton<AppEnvironment>(env);
  if (env.isMisconfigured) return;                  // S38 path, nothing else registered
  await _registerCore();                            // CacheService, SecureStorage, LocaleController, AdService, Clock
  switch (env.dataMode) {
    case DataMode.demo: await _registerDemo();      // DemoStore + Demo* repos + DemoOtpVerifier + NoopPushTokenSink
    case DataMode.api:  _registerApi();             // Unavailable* repos (until VPS) + ApiClient interface
  }
  if (adminEnabled(env)) await _registerLegacySupabase();   // D-01: Supabase + legacy repos for in-app Admin only
}
```
- Demo registration lives in `lib/data/demo/demo_module.dart`, the **only** file that imports demo implementations. Feature code imports only `lib/domain/**`.
- An import-boundary test (`API-008`) fails if any file under `lib/features/{auth,shell,home,catalog,wallet,profile,orders,referral}/` imports `supabase_flutter`, `lib/data/demo/` or `lib/shared/repositories/`.

### 15.7 Demo indicator
- `DemoBanner`: a slim 24 dp pill "DEMO" at the top-end of auth screens and on S15/S22. A `DemoChip` appears on demo entries/orders. Profile → About shows "Demo build — no real rewards, orders or entries."
- App title in the task switcher: `Creative Rewards (Demo)` when `isDemo` (`MaterialApp.title`).

---

## 16. Mock Repository Contracts

All contracts are in `lib/domain/repositories/` and return `Future<Result<T>>` or `Stream<T>`. They are backend-agnostic: no Supabase types, no HTTP types.

### 16.1 Models (`lib/domain/models/`)

| Model | Fields | Notes |
|---|---|---|
| `LocalizedText` | `en`, `ar`; `resolve(languageCode)` falls back to en | All catalog strings |
| `ImageRef` | sealed `AssetImageRef(path)` / `NetworkImageRef(url, blurHash?)` | §14.3 |
| `AppUser` | `id, email, displayName, characterId?, createdAt, emailVerified` | `displayName` defaults to the email local-part (D-03) |
| `Character` | `id, name: LocalizedText, image: ImageRef, backgroundHex, sortOrder` | |
| `Category` | `id, slug, title, subtitle, description: LocalizedText, gradient: List<String hex>, darkText: bool, bannerImage, tileImage, heroImage, iconImage: ImageRef?, groups: List<ProductGroup>, sortOrder, isActive` | |
| `ProductGroup` | `id, title: LocalizedText, sortOrder` | Drives segmented tabs. Hidden when there is only one group |
| `RewardProduct` | `id, categoryId, groupId, title, denomination: LocalizedText, pointsCost: int, image: ImageRef?, availability: ProductAvailability {available, outOfStock, comingSoon}, requiresAccountIdentifier: bool, identifierLabel: LocalizedText?, identifierPattern: String? (regex), deliveryNote: LocalizedText, sortOrder` | |
| `WalletBalance` | `points: int, asOf: DateTime` | |
| `PointsTransaction` | `id, delta, reason: PointsReason, referenceId?, createdAt, label: LocalizedText` | |
| `RedemptionOrder` | `id, requestId, productId, productSnapshot {title, denomination, image, categoryTitle}, pointsCost, accountIdentifier?, status: OrderStatus {pending, processing, completed, failed, refunded}, statusHistory: List<{status, at, note?}>, createdAt, updatedAt, isDemo` | Snapshot keeps history valid if the product changes |
| `Giveaway` | **existing** `lib/shared/models/giveaway.dart` (re-used; plain Equatable). `imageUrl` may hold `asset:` URIs in demo, resolved by `ImageRef.parse` | Maps `effectiveStatus` → `GiveawayDisplayStatus {available, upcoming, ended}` via a new extension in `lib/domain/models/giveaway_display.dart` |
| `GiveawayRequirement`, `Participation`, `NotificationItem` | **existing** models re-used | `Participation` gains no fields. Demo-ness is carried by the repository (`isDemo` flag on a wrapper `GiveawayEntry {participation, giveaway, isDemo}`) |
| `Referral` | `code, shareMessage: LocalizedText, storeUrl, invitedCount, rewardDescription: LocalizedText?, termsNote: LocalizedText` | |
| `OtpTicket` | `email, purpose, verifiedAt, expiresAt, opaqueToken` | Opaque. The VPS token goes here |
| `AuthSession` | `user: AppUser, expiresAt` | Tokens are kept inside the data layer, never in the domain |

### 16.2 Contracts

```dart
abstract interface class OtpVerifier {
  Future<Result<OtpRequestReceipt>> requestCode({required String email, required OtpPurpose purpose}); // receipt: resendAvailableAt, codeLength=6
  Future<Result<OtpTicket>> verify({required String email, required String code, required OtpPurpose purpose});
}
abstract interface class AuthGateway {
  Future<Result<AuthSession>> register({required String email, required String password, required OtpTicket ticket});
  Future<Result<AuthSession>> login({required String email, required String password});
  Future<Result<void>> resetPassword({required String email, required String newPassword, required OtpTicket ticket});
}
abstract interface class SessionRepository {
  Future<SessionRestore> restore();            // none | expired(email) | active(AuthSession)
  Future<void> signOut();
  Future<void> expireNow();                    // demo tools only; api impl throws UnsupportedError
}
abstract interface class AccountRepository {
  Stream<AppUser?> watchCurrentUser();
  Future<Result<AppUser>> setCharacter(String characterId);
  Future<Result<AppUser>> updateDisplayName(String name);
  Future<Result<void>> deleteAccount();        // demo: wipes this account's data; api: server deletion
}
abstract interface class CharacterRepository { Future<Result<List<Character>>> getCharacters(); }
abstract interface class CatalogRepository {
  Future<Result<List<Category>>> getCategories();
  Future<Result<Category>> getCategory(String id);
  Future<Result<List<RewardProduct>>> getProducts(String categoryId, {String? groupId});
  Future<Result<RewardProduct>> getProduct(String productId);
  Future<Result<CatalogSearchResult>> search(String query); // categories + products; giveaways via feed
}
abstract interface class WalletRepository {
  Stream<WalletBalance> watchBalance();
  Future<Result<List<PointsTransaction>>> getTransactions({String? cursor});
}
abstract interface class OrderRepository {
  Future<Result<RedemptionOrder>> redeem({required String productId, required String requestId, String? accountIdentifier});
  Stream<List<RedemptionOrder>> watchOrders();
  Future<Result<RedemptionOrder>> getOrder(String id);
}
abstract interface class GiveawayFeedRepository {
  Future<Result<List<Giveaway>>> getGiveaways({GiveawayDisplayStatus? status, String? query});
  Future<Result<Giveaway>> getGiveaway(String id);
  Future<Result<List<GiveawayRequirement>>> getRequirements(String giveawayId);
}
abstract interface class GiveawayEntryRepository {
  Future<Result<GiveawayEntry?>> getMyEntry(String giveawayId);
  Future<Result<GiveawayEntry>> enter(String giveawayId);          // server/demo allocates the number
  Stream<List<GiveawayEntry>> watchMyEntries();
  Future<void> markNumberRevealed(String entryId);
  Future<Result<WinCelebration?>> pendingWinCelebration();
  Future<void> acknowledgeCelebration(String id);
  // cosmetic frame (device-local, unchanged semantics):
  bool hasPendingRewardFrame(String giveawayId); Future<void> markRewardFrameEarned(String giveawayId);
  Future<void> attachRewardFrame(String giveawayId, String entryId); bool hasRewardFrame(String giveawayId, String entryId);
}
abstract interface class InboxRepository {
  Stream<List<NotificationItem>> watch(); Stream<int> watchUnreadCount();
  Future<Result<void>> markRead(String id); Future<Result<void>> markAllRead();
}
abstract interface class ReferralRepository { Future<Result<Referral>> getMyReferral(); }
abstract interface class PushTokenSink { Future<void> register(String token); Future<void> invalidate(); }
```

### 16.3 New Failures (`lib/core/error/failure.dart`, append)
`InvalidOtpFailure`, `OtpExpiredFailure`, `OtpRateLimitedFailure` (reuse `RateLimitedFailure` if suitable), `EmailAlreadyRegisteredFailure`, `AccountNotFoundFailure`, `InvalidCredentialsFailure`, `WeakPasswordFailure`, `SessionExpiredFailure`, `InsufficientPointsFailure(balance, required)`, `ProductUnavailableFailure`, `InvalidAccountIdentifierFailure`, `BackendUnavailableFailure` (api-mode stubs), `DemoOnlyActionFailure`. Each maps to an ARB string through the existing `failure → l10n` helper pattern.

### 16.4 Demo implementation behaviour summary

| Repo | Demo behaviour |
|---|---|
| `DemoOtpVerifier` | §18.2 |
| `DemoAuthGateway` | register: rejects an existing email; creates `AppUser`, a +6,000 grant, session. login: email must exist; password format only. reset: success, no storage |
| `DemoSessionRepository` | secure storage `demo_session_v1`, 30-day expiry |
| `DemoCatalogRepository` | seed, optional artificial latency 250–400 ms (`DemoLatency`, 0 in tests), case- and diacritic-insensitive search over en+ar titles |
| `DemoOrderRepository` | ledger transaction (§15.4). Status does **not** auto-advance (D-11 default). Demo Tools can advance it |
| `DemoGiveawayRepository` (feed + entry) | §24 |
| `DemoInboxRepository` | seed + generated items on redemption/entry/status change |
| `DemoReferralRepository` | code `CR-` + 6 base32 chars derived from a deterministic FNV-1a hash of the userId (no crypto dependency); `invitedCount: 0`; share message with the Play URL |

---

## 17. Future VPS Repository Architecture

```
lib/data/api/
  api_client.dart              abstract ApiClient { Future<ApiResponse> send(ApiRequest r); }   // transport-agnostic; NO base URL, NO endpoints
  api_session_store.dart       token persistence contract (secure storage keys api_access_token / api_refresh_token) — implementation deferred
  unavailable/                 Unavailable*Repository: every method returns BackendUnavailableFailure; streams emit an empty/initial value then close
  dto/                         (future) DTO classes + mappers DTO → domain models; one file per entity
  http/                        (future) Http*Repository implementations
```

- **Endpoints, auth headers, response envelopes and error codes are NOT invented.** They are filled in when the VPS API contract is published. The integration checklist (§35) lists what must be supplied.
- Server-authoritative rules that the mobile contracts already assume: OTP issuance/verification and rate limiting; password hashing; session tokens with expiry and refresh; balance = server ledger; **redemption is a single server transaction** keyed by `requestId` (idempotent); participation number allocation and uniqueness; eligibility (active, not full, one per user); referral attribution and rewards; order status transitions; notification creation; character id stored on the user record.
- Each contract has a **shared contract test suite** (`test/contracts/<repo>_contract.dart`, functions taking a factory). It runs against the demo implementation now and against the HTTP implementation later. This is what guarantees "swap without UI changes".
- Data fields the dashboard must manage (for the backend team): §16.1 tables are the authoritative field list (categories, groups, products incl. images/denominations/costs/availability/identifier rules; giveaways incl. images, dates, status, digit width, max participants; orders and statuses; notifications).

---

## 18. Authentication Demo Design

### 18.1 Screens and cubits
`lib/features/auth/presentation/`: `welcome_page.dart`, `email_entry_page.dart`, `otp_page.dart`, `create_password_page.dart` (modes `register`, `reset`), `login_page.dart`, `forgot_password_page.dart`, `session_expired_page.dart`; `bloc/registration_cubit.dart`, `bloc/login_cubit.dart`, `bloc/password_reset_cubit.dart`. `lib/features/character/presentation/choose_character_page.dart` (modes `onboarding`, `change`) + `bloc/character_cubit.dart`.

### 18.2 Demo OTP (`lib/data/demo/demo_otp_verifier.dart`)
- Constructor: `DemoOtpVerifier(AppEnvironment env, Clock clock)`. It **throws `StateError` unless `env.isDemo && !env.isMisconfigured`**. This is the second line of defence after DI.
- `requestCode`: no email is sent. Returns `resendAvailableAt = now + 30 s`. More than 5 requests in 10 min per email → `RateLimitedFailure` (realistic feedback).
- `verify`: trims, normalises Arabic-Indic digits, requires `^\d{6}$` → `OtpTicket(expiresAt: now + 10 min)`. Wrong length or non-digits → `InvalidOtpFailure`. **Any** 6-digit code succeeds, and a reserved code `000000` returns `OtpExpiredFailure` so testers can see the expired state (documented in the S07 DemoBanner tooltip and Demo Tools).
- UI: the S07 DemoBanner says "Demo: any 6-digit code works." The resend link counts down `mm:ss` from 00:30. At 0 it becomes tappable "Resend code" → `requestCode` → snackbar "New code sent (demo)". Auto-submit when 6 digits are entered. The error shake animation is suppressed with reduced motion.

### 18.3 Password rules (S08 / S05)
Rules shown live with check circles (grey → green):
1. "At least 8 characters" — `length ≥ 8` (max 128).
2. "Include letters and numbers" — `[A-Za-z\u0600-\u06FF]` and `\d`.
3. "Use a strong password" — score ≥ 3 out of {length ≥ 12, upper+lower, digit, symbol, not in a small embedded common-password list (`lib/features/auth/domain/common_passwords.dart`, ~100 entries), not containing the email local part}.

The confirm field must match. The CTA is enabled only when all 3 rules pass and the fields match. The error text "Passwords don't match" appears on the confirm field after first blur.

### 18.4 Password handling
- The password exists only in the `TextEditingController` and is passed directly to `AuthGateway.register/login/resetPassword`. **The demo gateway discards it**: it is never logged, persisted, hashed or placed in a cubit state or `Equatable` props. Controllers are cleared and disposed when the page is popped.
- `debugPrint`/logging of auth calls is forbidden in auth files. A test asserts `DemoStore` and secure storage contain no password-like field after registration (`AUTH-008`).
- Passwords are **never** sent to Supabase (the new flow has no Supabase dependency at all).

---

## 19. Home Screen Specification

**S11 `lib/features/home/presentation/home_page.dart`**, `bloc/home_cubit.dart`.

Layout (`CustomScrollView`, `PageStorageKey('home')`, `RefreshIndicator`):
1. `AuroraBackground` behind the full scroll (fixed, not scrolling with content).
2. `PointsHeader` (SafeArea top): row [Column("Your Points", balance + "PTS" baseline-aligned), Spacer, `CircleIconButton(bell, dot: unread > 0)`]. The bell opens S26. Balance from `WalletCubit` with animated count-up on change (disabled with reduced motion). Tapping the balance opens the Wallet tab. **No separate points card** (brief rule).
3. Search field (`RewardsTextField` pill variant, hint "Search rewards, giveaways…"). Typing (debounce 250 ms) puts Home into **search mode**: the sections below are replaced by results: "Categories" (matching chips → S13), "Rewards" (matching products as compact rows → S13 with the product's group selected and its Redeem sheet opened), "Giveaways" (matching cards → S20). No results → `EmptyState(empty_search)` with "Clear search". The clear (×) button restores sections. Search runs through `CatalogRepository.search` + `GiveawayFeedRepository.getGiveaways(query:)`.
4. "Available Rewards" header + horizontal `ListView` of `CategoryTile`s (all active categories, sort order). Tap → S13. A "See all" text button at the header end → Categories tab.
5. "Giveaways" header + "See all" → S19. A 2-column grid of the first 4 giveaways ordered available → upcoming → ended. `GiveawayCard` tints cycle lavender/pink/blue/peach. `StatusChip` at top-start: Available (green dot + "Ends in 2d"), Upcoming ("Starts Oct 22"), Ended. Tap → S20.
6. Bottom padding = nav footprint.

States: initial skeleton (header balance skeleton, 4 tile skeletons, 4 card skeletons); per-section `ErrorState` with retry (a catalog failure does not hide giveaways and vice versa); `BackendUnavailableFailure` → `UnavailableNotice`; pull-to-refresh reloads all.

---

## 20. Categories Specification

**S12 `lib/features/catalog/presentation/categories_page.dart`**, `bloc/categories_cubit.dart`.
- Title "Categories" (h1) and a search icon button. The search toggles an inline field under the title that filters banners by localised title/subtitle (local filter, no repository call). Clear restores.
- `ListView.separated` of `CategoryBanner` (gap 14, gutter 20). Each banner: `DecoratedBox(gradient from Category.gradient)`, `AppImage(bannerImage, fit: cover, alignment: AlignmentDirectional.centerEnd)`, text block at start (title h3 white or navy when `darkText`, subtitle body). Tap → S13. Semantics: button "PUBG Mobile, UC Top-Ups".
- Data only from `CatalogRepository.getCategories()`. **No catalog constants inside widgets.**
- States: 5 banner skeletons; error with retry; empty (no active categories) → `EmptyState` "No categories yet".

---

## 21. Product Redemption Specification

### 21.1 S13 Category Details — `lib/features/catalog/presentation/category_details_page.dart`, `bloc/category_details_cubit.dart`
- `CustomScrollView`: hero `SliverToBoxAdapter` (height `clamp(0.32*screenH, 240, 320)`): `AppImage(heroImage)` cover, a top-to-bottom scrim `#000 0%→35%`, the category gradient as the base layer, SafeArea row [back `CircleIconButton` (translucent white icon only, per ref), Spacer, heart toggle (favourite — **local preference only**, stored in DemoStore `meta.favorites`; snackbar "Saved to favourites"; shown only if D-02 keeps favourites, default **keep, local**)]. Below: `iconImage` tile 120 dp radius 26 + title h1 white + subtitle; description body white 90% max 2 lines.
- Overlapping sheet (`Transform.translate(0,-24)`, radius 28 top, `lavender50`): `SegmentedTabs` when `groups.length > 1`, then a `SliverGrid` of `ProductCard` (2 columns; 3 at ≥ 600 dp; `childAspectRatio` computed from text scale like the existing home grid).
- Balance chip in the sheet header end ("You have 6,000 PTS"). It updates live.
- Out-of-stock product: greyed, button label "Out of stock", disabled.

### 21.2 S14 Redeem Sheet — `lib/features/catalog/presentation/redeem_sheet.dart`
Opened from Redeem (`showModalBottomSheet`, `isScrollControlled`, keyboard-safe):
- Product image, denomination, category title, price; "Your balance: X PTS"; "After redemption: Y PTS" (red and with an "Insufficient points" message if negative).
- If `requiresAccountIdentifier`: a `RewardsTextField(label: identifierLabel)` validated by `identifierPattern` (fallback: non-empty, ≤ 64 chars).
- Delivery note and a "Demo only — no real top-up will be delivered" line (DemoChip).
- Buttons: **Confirm redemption** (disabled if insufficient or invalid) / Cancel. If insufficient: the primary button becomes "Browse cheaper rewards" (pops the sheet and scrolls to the cheapest product) and a text button "Ways to earn" → S17.
- Confirm → `CategoryDetailsCubit.redeem(productId, identifier)` with a per-sheet `requestId`. The button shows loading, and the sheet is non-dismissible during the call (double-tap safe).

### 21.3 S15 Redemption Result — `lib/features/catalog/presentation/redemption_result_page.dart`
- Success: confetti burst (existing `confetti` package, off with reduced motion), check illustration, "Redemption requested", order id short form, status chip Pending, new balance, buttons **View order** (→ S25) / **Back to rewards** (pop to S13).
- Failure variants: `InsufficientPointsFailure` (shown in the sheet, not here), `ProductUnavailableFailure` ("This reward is no longer available"), `BackendUnavailableFailure`, generic. Retry keeps the same `requestId`.

### 21.4 Consistency guarantees
Balance (Home header, Wallet card, S13 chip, Profile stat) all subscribe to `WalletRepository.watchBalance()`, and orders to `watchOrders()`. Acceptance test: redeem → all four balance displays and My Orders update without a manual refresh (`CAT-011`).

---

## 22. Wallet Specification

**S16 `lib/features/wallet/presentation/wallet_page.dart`**, `bloc/wallet_page_cubit.dart` (balance via app-scoped `WalletCubit`).

1. Header row: "Your Rewards" (h3 navy) + bell (`CircleIconButton`, badge dot when unread) → S26.
2. `PointsBalanceCard` (§11 tokens). Semantics: "Points balance, 6,000 points".
3. **Fast, Earn** button (`PrimaryPillButton` large, gift icon leading, chevron trailing) → S17 Earn Hub.
4. Action rows (no Sign Up, no Recent Activity):
   - **Place an Order** → `ShellCubit.selectTab(ShellTab.categories)` (the tab switch makes the Categories tab visible, with no push).
   - **Write a Review** → §22.2.
   - **Refer a Friend** → S18.

### 22.2 Write a Review
- `ReviewLauncher` service (`lib/services/review_launcher.dart`) using `in_app_review`:
  1. Android: `InAppReview.instance.openStoreListing()` (the app is published as `com.creativehub.rewardsapp`). `requestReview()` is **not** used from a button, because Google's quota may silently show nothing (that would be a "silent failure").
  2. Fallback: `url_launcher` `market://details?id=com.creativehub.rewardsapp`, then `https://play.google.com/store/apps/details?id=com.creativehub.rewardsapp`.
  3. All failed, or iOS without an App Store id (D-14) → snackbar "Couldn't open the store. Please try again later."
- **No points, rewards, unlocks or tracking are tied to reviewing.** The UI copy must not suggest rewards (§22.4).

### 22.3 Fast, Earn → S17 Earn Hub (`lib/features/wallet/presentation/earn_hub_page.dart`)
A list of only **actually supported** actions, each with an honest description:
- "Invite friends" → S18 ("Referral rewards will be credited by our servers when the program launches", shown in demo).
- "Join free giveaways" → S19 ("Giveaways are free to enter and don't use points").
- "Redeem your points" → Categories tab.
- Demo builds only: "Add demo points" → S37 (labelled DEMO).

No new earning mechanic is invented. The real production earning model is **D-04** (launch blocker).

### 22.4 Copy compliance (overrides reference subtitles)
| Row | Ref subtitle | Required subtitle (EN) | AR |
|---|---|---|---|
| Place an Order | "Earn points with every order" | "Redeem your points for rewards" | "استبدل نقاطك بالمكافآت" |
| Write a Review | "Earn points by sharing your experience" | "Rate us on Google Play" | "قيّمنا على Google Play" |
| Refer a Friend | "Invite friends and earn points" | "Invite friends to Creative Rewards" (add "and earn points" only once D-04 confirms server-side referral rewards) | "ادعُ أصدقاءك إلى Creative Rewards" |

The reason: Google Play policy prohibits incentivising ratings/reviews, and the brief forbids rewarding reviews. "Earn points with every order" implies a cashback mechanic that does not exist (D-04).

---

## 23. Profile Specification

**S27 `lib/features/profile/presentation/profile_page.dart`**, `bloc/profile_cubit.dart` (combines CurrentUser, Wallet, Entries count, Orders count, Inbox unread).

1. Decorative header: `AuroraBackground` + `profile_header_decor` image (or CODE fallback: just aurora), settings gear `CircleIconButton` at top-end → S28. **No back arrow** (tab root).
2. Avatar: `CharacterAvatar(size: 168, radius 44, ring 4 white)` + edit badge (56 dp white circle, pencil) → S09 change mode. Semantics: "Change character".
3. Display name (h2), email (bodyMuted). Long names ellipsise at 1 line, with a tooltip on long-press.
4. `StatStrip`: Points → Wallet tab; Giveaways (entry count) → S23; Orders (order count) → S24.
5. Menu (`MenuRow`s in a column with 10 dp gaps), in this exact order:
   1. My Giveaways → S23
   2. My Orders → S24
   3. Notifications (red count badge if unread > 0, "9+" cap) → S26
   4. Language (trailing "English"/"العربية") → S30
   5. About → S31
   6. Privacy Policy → S32
   7. Terms & Conditions → S33
   8. Sign Out (danger colour, logout icon, no chevron) → S34

   **The Wallet row is removed** (Wallet has its own tab).
6. S28 Account Settings: Edit profile (S29), Change character (S09), Ad privacy choices (only when `AdService.privacyRequired`, calls `privacyOptions()`; preserves the UMP requirement), Delete account (demo: "Delete demo account & data" with confirmation → `AccountRepository.deleteAccount()` → Welcome; api: server deletion, which Google Play requires, D-14), Demo Tools (S37, demo only), app version (from build constants; no new package).

---

## 24. Giveaway Participation Specification

### 24.1 Separation of concepts
- **Giveaways are free.** Nothing in the giveaway flow reads or writes points. `GiveawayEntryRepository` has no dependency on `WalletRepository`, and a test asserts that the ledger is unchanged after entering (`GIVE-009`).
- **Redeemable products** live only in the catalog. Giveaway prizes never show a PTS price or a Redeem button.

### 24.2 Flow (S20 → S21 → S22 → S23)
1. S20 Details (restyle of E05 on `GiveawayFeedRepository`): hero image, status chip, title, organiser, prize description, time remaining / start time, participants count (and "x spots left" when `maxParticipants` is set), requirements (display-only, external links via url_launcher), rules. CTA states (kept from `GiveawayDetailsCta`): Generate my number (available), "Starts on …" (upcoming, disabled), "This giveaway has ended" (ended), "You're in — #0427" (already entered, gold border if a frame is unlocked).
2. S21 Participation (refactor `ParticipationCubit` to depend on `GiveawayEntryRepository` + `GiveawayFeedRepository` + `SessionRepository` instead of the Supabase repos):
   - Authenticated users skip `needsRegistration` (D-07).
   - `readyToJoin` → `RewardFrameChoiceDialog` (only if `AdService.rewardedAvailable`; otherwise go straight to join): **Continue without ad** gives the identical entry. **Watch ad** shows the rewarded ad and, if rewarded, marks the cosmetic frame. **Either path creates exactly one entry with the same odds.**
   - `enter(giveawayId)` → success → S22.
3. S22 Number Reveal (existing page restyled): number padded to `numberDigitWidth` (fixes the hard-coded `padLeft(4)` in both `NumberRevealPage` and `Participation.formattedNumber` for widths 5–6). Lottie `number-generator.json`, frame if unlocked, and the **DemoChip + caption "Demo entry — not a real competition entry"** in demo mode. Buttons: "View in My Giveaways" (→ S23), "Done" (pop to S20).
4. S23 shows the entry immediately (stream), newest first, with status: Active / Upcoming / Ended — not selected / Ended — winner (demo-simulated only).

### 24.3 Demo number generation (`DemoGiveawayRepository.enter`)
- Preconditions, checked in order: session active (else `SessionExpiredFailure`); giveaway exists; `effectiveStatusAt(clock.now()) == active` (else `GiveawayEndedFailure`, or a new `GiveawayNotStartedFailure` for scheduled); no existing entry for (user, giveaway) (else `DuplicateParticipationFailure`, which the cubit turns into the existing `alreadyParticipating` path); `participantCount < maxParticipants` (else `GiveawayFullFailure`).
- Number: `Random.secure()` uniform in `[0, 10^digitWidth)`, re-drawn until it is not in the giveaway's taken set (seeded "other entrants" numbers + the user's entries). Retries are bounded (1000), then a deterministic scan.
- Persist `{entryId, giveawayId, userId, number, sequence: participantCount+1, createdAt, isDemo: true}`; increment the in-memory participantCount overlay; inbox item "You're in! Your number is 0427".
- No ad call, network call, or points change occurs in the repository.

### 24.4 AdMob preservation rules
- The rewarded ad remains **optional and cosmetic** (a frame around the number). It never creates extra entries, never changes odds, and is never required to enter. In demo builds ads use test unit ids (existing `AdConstants.testAds` for non-release builds).
- The supabase SSV edge functions (`prepare/cancel-rewarded-frame`, `verify-ad-reward`) are **not** called in demo. The device-local `RewardFrameEntitlementStore` is reused, keyed by the demo user id instead of `supabase.auth.currentUser.id` (change its `authUserId` closure to read `SessionController`).
- `AdFrequencyController.criticalFlows` guarding during celebration/participation stays.
- Future VPS: if server-side reward verification is wanted, it must still only affect the cosmetic frame.

### 24.5 Winner celebration (S35)
Demo has no real draws. Demo Tools offers "Simulate winner announcement" for an ended giveaway the user entered. It writes a `winner_announcement` inbox item + `WinCelebration` record. The shell listener shows S35 once, then `acknowledgeCelebration`. S35 shows the DemoChip and the copy "Demo announcement — not a real prize".

---

## 25. Orders Specification

- **S24 My Orders** (`lib/features/orders/presentation/my_orders_page.dart`): list of `OrderCard` (product image, denomination, category, cost "−1,200 PTS", date, status chip, DemoChip). Filter chips: All / In progress (pending+processing) / Completed / Failed. Empty → `EmptyState(empty_orders)` + "Browse rewards" (→ Categories tab, popping to the shell).
- **S25 Order Details**: snapshot info, account identifier (masked except the last 4 characters), status timeline (vertical stepper from `statusHistory`), order id (copy to clipboard), "Need help?" → `mailto:` `AppConfig.contactEmail` with the order id prefilled (existing launcher pattern). Demo: footer "Demo order — nothing will be delivered."
- Statuses: pending → processing → completed, or failed/refunded (refund appends `redemptionRefund` to the ledger). Demo Tools: "Advance latest order status" and "Fail & refund latest order" demonstrate the transitions and generate an inbox item each time.

---

## 26. Notifications Specification

- **S26** (restyle of E11, now on `InboxRepository`): grouped "Today / Earlier", unread dot, icon by type (gift, package, trophy, users, bell). Tap → mark read + `routeNotificationTap(type, data)` (§10.4). "Mark all as read" app-bar action (disabled when none are unread). Empty → `EmptyState(empty_notifications)`.
- Badge sources: Home bell dot, Wallet bell dot, Profile Notifications row count, all from `InboxCubit.unreadCount`.
- Push (FCM): unchanged initialisation. Demo mode uses `NoopPushTokenSink`, so no server registration. Taps on real pushes still route.

---

## 27. Referral Specification

- **S18 Refer a Friend** (`lib/features/referral/presentation/referral_page.dart`): illustration (reuse `auth_email_hero` or the gift Lottie), headline "Invite your friends", code card with a large monospace code `CR-7K2Q9M` + **Copy** (Clipboard → snackbar "Code copied"), **Share** (`share_plus` `Share.share(localisedMessage)`, where the message includes the code and the Play Store URL), "Invited friends: 0", and a terms note "Referral rewards are granted by Creative Rewards servers when the referral program launches. No points are added in this demo."
- Share result `dismissed` gets no feedback. A thrown error → snackbar "Sharing isn't available on this device" (and copy still works).
- **No local points are ever granted for referrals.** No deep-link domain is invented (the store URL only).

---

## 28. Localization and RTL

- All new strings go into `lib/l10n/app_en.arb` + `app_ar.arb` with placeholders/plurals (`{count, plural, …}`). Key prefixes: `welcome*`, `auth*`, `otp*`, `password*`, `character*`, `shell*`, `home*`, `categories*`, `catalog*`, `redeem*`, `wallet*`, `earn*`, `referral*`, `orders*`, `profile*`, `account*`, `demo*`, `state*`. Run `flutter gen-l10n`. `untranslated.txt` must be empty (`L10N-001`).
- Catalog/seed content uses `LocalizedText` (en + ar) and resolves with `Localizations.localeOf(context).languageCode`.
- Numbers: points formatted with `NumberFormat.decimalPattern(locale)`. **Digits**: D-12 default is Western digits in both locales for points, codes and OTP (`NumberFormat('#,##0', 'en')` style), with the Arabic-Indic input normalised. Dates use `DateFormat.yMMMd(locale)`.
- Fonts: Plus Jakarta Sans/Manrope have no Arabic glyphs. Bundle an Arabic font (D-12 default IBM Plex Sans Arabic, OFL, weights 400/500/600/700) and set `fontFamilyFallback: ['IBM Plex Sans Arabic']` in `RewardsText`. Headline letter-spacing is 0 in Arabic.
- RTL: use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional` everywhere. Back/chevron/arrow icons flip via `Directionality` (Lucide `chevronRight` → wrapped in a `DirectionalIcon` helper). Hero/banner art aligns `centerEnd`. The OTP boxes stay **LTR** (`Directionality(textDirection: ltr)` for digit sequences), and so do the referral code and order ids.
- Runtime switch: S30 → `LocaleController.setLocale` (existing, persisted). The whole app rebuilds with no restart, and tab state is preserved (IndexedStack under the same keys).

---

## 29. Responsive Layout

- Target logical widths **320, 360, 393, 430** (+ 600 tablet sanity). Heights 568–932.
- Horizontal gutter `clamp(16, 0.05*w, 24)`.
- Grids: 2 columns < 600 dp, 3 ≥ 600. Card aspect ratio is computed from `MediaQuery.textScalerOf` (pattern from the existing `user_home_page.dart`).
- Auth pages: `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight: viewport)` so the CTA sits at the bottom on tall screens and scrolls on short ones/with the keyboard. The illustration height is `clamp(0.22*h, 140, 300)` and is hidden entirely when `viewInsets.bottom > 0` on heights < 700.
- Character grid: 3 columns always; tile size from width; check badge 28 dp below 360.
- Text scaling: layouts verified at 1.0, 1.3, 2.0. At ≥ 1.5 the stat strip wraps to a vertical list, menu rows grow in height, and nav labels shrink to 1 line with ellipsis.
- Bottom-nav footprint and safe areas handled through `SafeArea` and `MediaQuery.paddingOf`. No hard-coded insets.
- Keyboard: `Scaffold.resizeToAvoidBottomInset: true`. The dock is hidden while the keyboard is open (existing behaviour).

---

## 30. Animation and Performance

- Transitions: the shared `RewardsPageRoute` (fade + 4% slide, 250 ms) for pushes. Tab switches have no transition (IndexedStack). Bottom sheets use the defaults.
- Micro-interactions: button press scale 0.97 (100 ms), character tile select (border + badge scale-in 150 ms), balance count-up (600 ms), OTP error shake (300 ms), redemption confetti, number reveal (existing).
- `MediaQuery.disableAnimations` → durations 0, no confetti, no shake, no count-up.
- Performance rules: no `BackdropFilter` inside scrolling content (existing `AppVisuals` rule); `AuroraBackground` in a `RepaintBoundary`; images decoded at display size (`cacheWidth`); `const` constructors; `ListView.builder`/`SliverGrid` builders; precache auth heroes; avoid rebuilding the whole shell on balance changes (`BlocSelector`).
- Budget: no frame > 16 ms in profile mode on a mid-range emulator during Home scroll and tab switches; cold start to Welcome ≤ splash minimum + 300 ms. Verified in `POL-005`.

---

## 31. Security and Demo Isolation

1. **Compile-time mode** `DATA_MODE` + existing `APP_ENV`. `prod + demo` ⇒ S38 blocking screen; DI registers nothing else.
2. **Construction guard**: `DemoOtpVerifier`, `DemoAuthGateway` and `DemoStore` constructors throw `StateError` unless `env.isDemo && !env.isMisconfigured`.
3. **Import boundary**: only `lib/data/demo/demo_module.dart` imports demo implementations, and only `injection.dart` imports `demo_module.dart`. Enforced by `API-008`.
4. **Tests** (`AUTH-014`): (a) `AppEnvironment(prod, demo).isMisconfigured == true`; (b) `configureDependencies(env: prod+api)` registers `OtpVerifier` that is **not** `DemoOtpVerifier` and `verify('123456')` returns `BackendUnavailableFailure`; (c) constructing `DemoOtpVerifier` with a prod/api env throws; (d) `main` with prod+demo renders S38.
5. **CI**: the release workflow (when added) must pass `--dart-define=APP_ENV=prod --dart-define=DATA_MODE=api`. A script `tool/check_release_defines.dart` (or a CI step) rejects release builds missing `DATA_MODE=api` (`TEST-008`).
6. **Play release blocker**: a demo build must **never** be uploaded to the production Play track. Internal-testing distribution only, and the in-app DEMO markers are visible. The production release of the redesign is blocked until the VPS exists and the legal pages describe the new processing (D-14).
7. **No secrets**: no new keys or tokens in code. The existing Supabase anon key/AdMob ids remain as they are (out of scope).
8. **PII**: the demo stores email + display name on-device only. The account identifiers in orders are masked in the UI. Delete demo account wipes them.
9. **Sign-out** never calls `SecureStorageService.clearAll()`.

---

## 32. Automated Testing

| Layer | What | Location |
|---|---|---|
| Unit | AppEnvironment, DemoOtpVerifier, password rules, email validation, ledger math, redemption transaction + idempotency, number generation uniqueness/range/width, eligibility rules, referral code determinism, LocalizedText fallback, ImageRef parse, failure→l10n mapping | `test/core/…`, `test/data/demo/…`, `test/domain/…` |
| Contract | shared suites per repository, run against demo impls (later HTTP) | `test/contracts/` |
| Cubit (bloc_test + mocktail) | Registration, Login, PasswordReset, Character, Home, Categories, CategoryDetails (redeem success/insufficient/unavailable/double-tap), Wallet, Orders, Profile, Inbox, Participation (refactored: no-ad, ad-rewarded, ad-not-rewarded, duplicate, full, ended), Session | `test/features/<feature>/` |
| Widget | every new page: renders, interactions, navigation targets, disabled states, semantics labels; nav bar avatar reflects the character; back-handling | `test/widgets/redesign/` |
| Golden | per screen × {en, ar} at 393×852; selected screens at 320×640 and text scale 2.0 | `test/golden/redesign/` |
| Integration (`integration_test`) | full onboarding; login/logout/relaunch; redeem → order appears → balance everywhere; giveaway entry → My Giveaways; language switch persists; session expiry | `integration_test/` |
| Architecture | import boundaries, no Supabase in new features, `untranslated.txt` empty, asset budget, every pubspec asset dir exists | `test/architecture/` |

Existing tests touching superseded screens (`user_home_page_test`, `settings_page_test`, `app_bottom_nav_test` for the user shell, `user_tab_scaffold_test`, `responsive_*`, `role_selection_golden_test`, `splash_cubit_test`) are updated, or retired with a written reason in the PR (`TEST-002`). Admin tests stay green.

---

## 33. Visual Regression Testing

1. **Golden infrastructure** (`TEST-003`): `test/flutter_test_config.dart` loads the bundled fonts (Plus Jakarta Sans, Manrope, Arabic fallback) via `FontLoader` so goldens show real typography; `AppImage` uses bundled assets (no network); `DemoLatency.zero`; fixed `Clock` (2026-10-19 10:00 local) so countdowns are stable; animations settled.
2. Goldens are generated on Windows (the dev machine). CI (Linux) runs goldens with a tolerance comparator (≤ 0.5% pixel diff) or tags them `golden` and skips them on CI if the platform differs (decide in `TEST-003`, documented).
3. **Reference comparison** (`TEST-006`): run on an Android emulator (Pixel 7, 1080×2400, 420 dpi ≈ 411 dp, and a small 360 dp device) in demo mode. Capture each of the 10 reference screens with `adb exec-out screencap`. Place them side by side with the reference in `docs/screenshots/redesign/<screen>_compare.png` (PIL script `tool/assets/compare_sheet.py`). Check manually: layout order, proportions within ~10%, colours within the token table, typography hierarchy. Deviations listed in §11 are expected.
4. The redesigned splash is compared visually against `design_references/splash-page.png`.

---

## 34. Risks and Dependencies

| ID | Risk | Impact | Mitigation |
|---|---|---|---|
| R-01 | Large uncommitted working tree | Lost work / unattributable diffs | `AUD-001` commit + tag before any change |
| R-02 | Third-party IP: PUBG, Valorant, Instagram, TikTok, Facebook, Apple, Sony logos/characters/product designs in references | Store rejection, takedown, legal | D-09: agent art brand-neutral; official marks only from user-supplied licensed brand kits; generic product names in demo seed |
| R-03 | Selling followers/likes/engagement may violate Meta/TikTok terms and Play deceptive-behaviour policy | Store rejection | D-10: product decision before production; demo uses neutral "Package" placeholders |
| R-04 | Incentivised reviews prohibited by Google Play | Policy strike | No rewards for reviews; copy changed (§22.4) |
| R-05 | No defined production earning mechanism for points | Product incoherent at launch | D-04 launch blocker; demo grant clearly labelled |
| R-06 | Demo build shipped to production | Fake OTP in prod | §31 guards + tests + CI check |
| R-07 | Paid image generation unavailable / inconsistent style | Missing/poor art | ASSET-001 trial; style lock; prompt pack fallback; explicit placeholders |
| R-08 | Arabic glyph fallback looks inconsistent | Poor AR UX | Bundle Arabic font (D-12) |
| R-09 | Removing Role Selection strands Admin users | Admin can't reach dashboard | D-01 |
| R-10 | Legal pages describe old Supabase processing | Compliance | D-14 launch blocker; demo notice in legal screens |
| R-11 | Existing production users (anonymous Supabase identities, entries) on 1.1.1+5 | Data continuity at VPS cutover | Out of scope here; flagged for the VPS migration plan (§35) |
| R-12 | Golden flakiness across OS | CI noise | §33.2 |
| R-13 | `liquid_glass_widgets` / `LiquidGlassWidgets.wrap` still wraps the whole app | Perf/visual side-effects on the new shell | Keep the wrap (Admin needs it); the new shell doesn't use glass widgets; verify perf in POL-005 |

Dependencies: user-supplied assets (welcome hero, profile decor, optional wallet art, licensed brand kits); approval for paid generation; decisions in Appendix A; new packages `in_app_review`, `share_plus`, `integration_test`; Android emulator availability.

---

## 35. Backend Migration Readiness

VPS integration checklist (to complete when the API exists; **nothing here is implemented now**):

- [ ] API contract document received (base URL per env, auth scheme, error envelope, pagination, rate limits).
- [ ] Map each contract method (§16.2) to an endpoint. Fill `lib/data/api/dto/*` + mappers. Unknown fields are ignored and missing optional fields defaulted.
- [ ] Implement `HttpApiClient` (timeouts, retry on idempotent GETs only, `Accept-Language` from locale, auth header from `ApiSessionStore`, 401 → refresh → `SessionExpiredFailure`).
- [ ] Implement `Http*Repository` for each contract. Run `test/contracts/*` against them with a recorded-fixture `ApiClient` fake.
- [ ] Server-side OTP issuance and verification (`OtpVerifier`). Remove nothing from demo; just register the HTTP impl in `_registerApi()`.
- [ ] Redemption idempotency via `requestId`; server returns the authoritative balance and order.
- [ ] Participation number allocation/eligibility server-side; cosmetic frame semantics unchanged.
- [ ] Referral attribution + server-granted `referralReward` ledger entries; update the §22.4 copy only then.
- [ ] Push token registration via `PushTokenSink`; notification payload `type` values aligned with §10.4.
- [ ] Image URLs → `NetworkImageRef`; CDN cache headers.
- [ ] Account deletion endpoint (Play requirement) wired to S28.
- [ ] Legal pages rewritten for the VPS processing (D-14).
- [ ] Decide migration of existing Supabase users/entries (R-11).
- [ ] Production build: `APP_ENV=prod DATA_MODE=api`; demo assets for backend-managed content may then be removed from the bundle (keep characters/illustrations).
- [ ] Decide retirement of in-app Admin + Supabase dependency (D-01).

---

## 36. Phase-by-Phase Implementation Strategy

Every phase ends with a **gate** (listed in TASKS.md as `GATE-n`): `flutter analyze` clean, `dart format` clean, all tests green, phase acceptance verified, and a short note appended to the PR description. Do not begin the next phase with a red gate.

| Phase | Goal | Key outputs | Gate criteria |
|---|---|---|---|
| 0 Repository Audit | Clean baseline, verified inventory, decisions | baseline tag, baseline test/analyze report, splash reference frame, decisions recorded | Baseline green or known failures documented; D-01/03/04/05/07/09/10/12 answered or defaults accepted |
| 1 Architecture Preparation | Env, models, contracts, DemoStore, demo repos, DI split, session | `lib/domain/**`, `lib/data/demo/**`, `lib/data/api/**`, env guard, S38 | Contract tests green; isolation tests green; app still launches (old UI) in demo mode |
| 2 Design System | Tokens + components | `rewards_*.dart`, `lib/shared/ui/**`, component goldens | All components golden-tested en/ar |
| 3 Asset Pipeline | Real/placeholder assets registered and optimised | `assets/images/**`, pubspec, processing script | Manifest complete; budget test green; no unlabelled placeholders |
| 4 Navigation & Shell | Splash routing, MainShell, nav with avatar, back handling | S01 routing, S10 | Splash frame unchanged; tab/back tests green |
| 5 Registration & Auth | S02–S09, S36, sign-out core | auth feature | Onboarding integration test green; prod OTP isolation tests green |
| 6 Home | S11, S19 | home feature | Home goldens + search tests |
| 7 Categories & Products | S12–S15 | catalog feature | Redemption consistency test green |
| 8 Wallet | S16–S18 | wallet + referral | Wallet action tests green |
| 9 Profile | S23–S34 (profile set) | profile, orders, inbox | Profile menu/sign-out tests green |
| 10 Giveaway Flow | S20–S23, S35 on contracts | refactored participation | Participation tests green; ledger unchanged on entry |
| 11 Remaining Screens | S37, offline/unavailable states, legacy retirement, dead-button audit | | Route audit + dead-button audit signed off |
| 12 Localization & A11y | ARB completeness, RTL, scaling, semantics | | `untranslated.txt` empty; RTL goldens; a11y guideline tests |
| 13 Animation & Polish | transitions, micro-interactions, perf | | Profile-mode budget met |
| 14 Testing & Visual Verification | full suites, emulator comparison | compare sheets | All suites green; comparison reviewed |
| 15 VPS Integration Readiness | contract review, unavailable stubs, checklist | updated §35 checklist | No backend code present; api-mode build shows UnavailableNotice everywhere gracefully |

---

## 37. Acceptance Criteria

1. Fresh install (demo) → Splash (unchanged) → Welcome → Email → OTP (any 6 digits) → Password (rules enforced) → Character (9 options) → Home. Exact order; no extra screens.
2. Relaunch after completing onboarding → Home directly. Relaunch after the password step without a character → Choose Character.
3. The Profile tab icon shows the selected character. Changing the character in Profile updates the nav avatar and profile header immediately.
4. Four tabs only: Home, Categories, Wallet, Profile. Android back: non-Home tab → Home; Home → app backgrounds.
5. Home has no separate points card. The balance, search, Available Rewards rail and Giveaways grid with status chips match the reference layout.
6. Search filters categories, products and giveaways from mock data, with an empty state.
7. Categories are fully data-driven (removing a seed category removes its banner with no widget change).
8. Redeem a 1,200 PTS product with 6,000 PTS → success page → balance 4,800 in Home, Wallet, Category chip and Profile → order "Pending" in My Orders. Redeem 10,000 PTS → insufficient-points feedback, no order, balance unchanged. Double-tapping Confirm creates one order.
9. Wallet: Place an Order → Categories tab; Write a Review → Play listing (or a clear error); Refer a Friend → copy + share work; Fast, Earn → Earn Hub with only supported actions. No Sign Up / Recent Activity rows.
10. Profile menu: exactly My Giveaways, My Orders, Notifications, Language, About, Privacy Policy, Terms & Conditions, Sign Out. No Wallet row. Every row opens a working screen/action.
11. Enter an active giveaway → number of the configured digit width → appears in My Giveaways → re-entering shows "You're in"; ledger unchanged; full/ended/upcoming states correct; the rewarded ad is optional and cosmetic.
12. Arabic switch at runtime: all new screens are RTL, translated, with no clipped text at 320 dp. The language persists across restart and sign-out.
13. Sign Out → Welcome; back cannot return into the app; relaunch → Welcome; Login restores the same orders/entries.
14. A `prod + demo` build shows the blocking screen. A `prod + api` build never accepts an arbitrary OTP (tests).
15. No new-feature file imports Supabase. Every interactive element performs a meaningful action or shows an explicit unavailable message (dead-button audit).
16. Splash visually identical to baseline.
17. `flutter analyze` clean, `dart format` clean, all tests green, goldens and the emulator comparison reviewed.

---

## 38. Definition of Done

A task is done when: the code merges with analyze/format clean; it has tests at the levels the task specifies, all green; its strings are localised en+ar; it is RTL-verified; it works at 320 and 430 dp and text scale 2.0 without overflow; it has semantics labels; no dead interactive elements; the demo/production isolation is intact; the TASKS.md checkbox is ticked with a one-line verification note. A phase is done when its gate passes. The redesign is done when §37 is fully satisfied and the open launch blockers (D-04, D-09, D-10, D-14) are recorded as unresolved or resolved by the product owner.

---

## Appendix A — Unresolved Decisions

Each has a **default** that implementation uses unless the user decides otherwise. ⚠ = launch blocker for production (not for the demo).

| ID | Decision | Default used for the demo |
|---|---|---|
| D-01 | In-app Admin area (Role Selection → Admin Auth → Admin Shell) after Role Selection is removed from the user path | Demo builds: Admin hidden, Supabase not initialised. Admin code untouched. A persisted `lastRole == admin` on an upgraded device still restores AdminShell **only** in api mode (where the legacy Supabase module is registered). Retire when the separate Dashboard ships. |
| D-02 | Heart/favourite on Category Details | Keep as a local-only favourite (no favourites screen); the future API may sync |
| D-03 | Source of the display name (the registration flow has no name step) | Email local-part, editable in S29 Edit Profile |
| D-04 ⚠ | How users earn points in production (none exists today) | Demo grant of 6,000 PTS per new account, labelled "Demo starting balance"; no invented mechanics |
| D-05 | Keep the AdMob banner above the new bottom nav | Keep (existing revenue behaviour). Goldens/comparisons are captured with banners disabled |
| D-06 | Wallet crown/decor art | CODE `CrownPainter`; replaced if the user supplies art |
| D-07 | Name/phone requirement for giveaway entry (old RegistrationForm) | Not required for authenticated users in demo; VPS decides later |
| D-08 | Additional categories beyond the 6 | None |
| D-09 ⚠ | Use of third-party logos/characters/product names (PUBG, Valorant, Instagram, TikTok, Facebook, Apple, PlayStation) | Category **titles** use platform names (needed for the demo's meaning); **artwork is brand-neutral**; logos only from user-supplied licensed kits; giveaway prize titles generic ("Wireless Earbuds Pro") |
| D-10 ⚠ | Whether followers/likes/engagement products are permissible | Placeholder "Package S/M/L" products; flagged |
| D-11 | Demo order status auto-progression | Manual via Demo Tools only |
| D-12 | Arabic font + digit style | IBM Plex Sans Arabic (OFL) fallback; Western digits for points/codes |
| D-13 | Router package | None (keep Navigator 1.0 + `AppRoutes` helpers) |
| D-14 ⚠ | Final legal content/URLs, iOS App Store id, account-deletion process for the VPS | Existing in-app legal text shown with a "Demo build — policy will be updated before launch" notice; iOS review → "store unavailable" message |
| D-15 | First tab label "Home" vs "Explore" | "Home" |
| D-16 | Character page dots (the ref implies paging) | Omitted (exactly 9 characters, one page) |

---

## Appendix B — Per-screen specification sheets

Format per screen: **File** (existing → target) · **Ref** · **Structure** · **Interactions → Destination** · **State** · **Mock data** · **Future API** · **Assets** · **RTL** · **Responsive** · **States (L/E/Err)** · **Tests** · **Acceptance**.

**S01 Splash**
- File: `features/splash/presentation/splash_page.dart` (visuals frozen), `cubit/splash_cubit.dart` (destinations), `cubit/splash_state.dart` (enum).
- Ref: `design_references/splash-page.png`. The demo uses extracted decorative gift artwork and real Flutter text and progress UI.
- Interactions: none → S02/S03-via-S36/S09/S10/S38/AdminShell per §9.1. State: SplashCubit + SessionRepository. Mock: demo session. API: session restore/refresh.
- Assets: existing. RTL: n/a. Responsive: unchanged. States: none (best-effort; restore errors → Welcome).
- Tests: demo splash session restoration, a short minimum display, and visual comparison against the new reference.
- Acceptance: pixel-identical first frames vs the baseline; correct routing.

**S02 Welcome** — target `lib/features/auth/presentation/welcome_page.dart`
- Ref `welcome-page.png`. Structure: `AuroraBackground › SafeArea › LayoutBuilder › Column[ Expanded(AppImage(onboarding_welcome_hero)), headline(2 lines, line 2 gradient text), body, DarkPillButton("Get Started", arrow), Text.rich("Already have an account? " + TextLink("Login")) ]`.
- Interactions: Get Started → S06 (new RegistrationCubit). Login → S03. Android back → exit app.
- State: none. Mock: none. API: none. Assets: USER `onboarding_welcome_hero` (fallback gift Lottie `empty-gift.json` until supplied, labelled placeholder).
- RTL: text centred; arrow flips. Responsive: hero `clamp(0.38h, 200, 420)`.
- States: none. Tests: widget (both actions navigate), golden en/ar, 320 width. Acceptance: matches the ref hierarchy; both buttons work.

**S03 Login** — `login_page.dart`, `bloc/login_cubit.dart`
- Ref none (auth style from S06). Structure: back button, h2 "Welcome **back**", subtitle, `RewardsTextField(email)`, `RewardsTextField(password, toggle)`, `TextLink("Forgot password?")` end-aligned, `PrimaryPillButton("Log In")`, footer link "New here? Get started", DemoBanner.
- Interactions: Log In → AuthGateway.login → S09 or S10 (stack cleared); Forgot → S04; Get started → S06; back → S02.
- State: LoginCubit {idle, submitting, failure}. Mock: DemoStore accounts, `demo@example.com`. API: login endpoint (TBD).
- RTL: fields directional; the email field stays LTR text direction. Responsive: scroll + keyboard safe.
- States: loading on button; errors inline (AccountNotFound with "Create account" action, InvalidCredentials, BackendUnavailable).
- Tests: cubit + widget + integration (logout→login). Acceptance: the seeded and newly registered accounts can log in; unknown email handled.

**S04 Forgot Password** — `forgot_password_page.dart`, `bloc/password_reset_cubit.dart`
- Structure: S06 layout with title "Forgot your **password?**", body "We'll email you a code", email field, "Send Code". No progress bar.
- → S07(reset) → S05 → S03 (snackbar). Mock: DemoOtpVerifier. API: request/verify/reset. Tests: cubit + widget flow. Acceptance: completes end-to-end in demo with clear feedback.

**S05 Reset Password** — `create_password_page.dart` (mode reset)
- Same as S08 with title "Set a new **password**" and button "Save password". → S03. Tests: mode-specific labels and navigation.

**S06 Email Entry** — `email_entry_page.dart`
- Ref `signin-page.png`. Structure: `CircleIconButton(back)`, `StepProgress(1/4)`, `AppImage(auth_email_hero)`, h2 "What's your **email?**", subtitle, `RewardsTextField(email, mail icon, keyboardType email, autofill email, textInputAction send)`, `PrimaryPillButton("Send Code")`.
- Interactions: Send Code (enabled when non-empty) → validate → `requestCode(register)` → S07. Back → S02. Already-registered → inline + "Log in instead" → S03 prefilled.
- State: RegistrationCubit. Mock: DemoOtpVerifier/DemoStore. API: OTP request.
- Assets: AGENT `auth_email_hero`. RTL: the email text field LTR; layout mirrored. Responsive: hero hidden on short screens with the keyboard open.
- States: button loading; field error; rate-limited message. Tests: validation table test, widget nav, golden en/ar 320/393. Acceptance: invalid emails are blocked with a message; valid → OTP shows the same email.

**S07 OTP Verification** — `otp_page.dart`
- Ref `otp-page.png`. Structure: back, `StepProgress(2/4)` (hidden in reset), h2 "Check your **email**", body + bold email, `OtpCodeInput(6)`, resend `TextLink` with countdown, `AppImage(auth_otp_hero)`, DemoBanner ("any 6-digit code works").
- Interactions: auto-verify on 6 digits, plus an explicit `PrimaryPillButton("Verify")` for accessibility (always present; pinned at the bottom, scrolls with the keyboard open). Valid → S08 (or S05). Invalid → shake + error "Enter the 6-digit code". `000000` → "This code has expired. Request a new one." Resend at 0 → new countdown + snackbar.
- State: RegistrationCubit/PasswordResetCubit with `resendAvailableAt` and a `Ticker`-free `Timer.periodic(1s)` in the widget state (cancelled on dispose).
- Assets: AGENT `auth_otp_hero`. RTL: OTP row forced LTR. Responsive: boxes 44×56 at < 360 dp.
- Tests: unit (verifier), widget (paste 6 digits, Arabic digits, countdown with fake async), isolation tests (AUTH-014). Acceptance: any valid 6-digit code passes in demo; countdown works; production cannot use this verifier.

**S08 Create Password** — `create_password_page.dart` (mode register)
- Ref `create-password-page.png`. Structure: back, `StepProgress(3/4)`, h2 "Create a **password**", subtitle, two `RewardsTextField(obscure, toggle)`, `PasswordRules` (3 rows), `AppImage(auth_password_hero)`, `PrimaryPillButton("Create Account")`.
- Interactions: Create Account → register → S09 (pushReplacement chain so back from S09 cannot reach S08). Back → S07.
- State: RegistrationCubit (no password in state). Mock: DemoAuthGateway. API: register.
- Tests: rule evaluation unit tests; widget (button enable logic, toggles, semantics); a test asserting no password persisted. Acceptance: rules update live; the account is created; the password is not stored.

**S09 Choose Character** — `lib/features/character/presentation/choose_character_page.dart`
- Ref `character-page.png`. Structure: [back hidden in onboarding / visible in change mode], `StepProgress(4/4)` (onboarding only), h1 "Choose Your Character", subtitle, `GridView.count(3)` of `CharacterTile`, `PrimaryPillButton("Continue")` (change mode: "Save").
- Interactions: tap tile → select (single); Continue (enabled once selected; onboarding pre-selects none; change mode pre-selects current) → setCharacter → S10 (onboarding) / pop with snackbar (change). System back in onboarding → hint snackbar.
- State: CharacterCubit. Mock: DemoCharacterRepository. API: characters list (or bundled) + set character.
- Assets: AGENT 9 characters. RTL: grid order mirrors (acceptable). Responsive: 3 columns at all widths.
- Tests: selection, persistence across relaunch, nav avatar update, golden. Acceptance: 9 consistent characters; the selection is reflected in the nav bar and profile.

**S10 Main Shell** — `lib/features/shell/presentation/main_shell.dart`, `bloc/shell_cubit.dart`, `lib/shared/ui/rewards_bottom_nav.dart`
- Structure §10.2–10.3. Interactions: tab taps; back handling; notification routing; celebration check.
- Tests: tab state preserved (scroll position), back behaviour, avatar tab, RTL order, banner slot hidden when the keyboard is open. Acceptance: §37.3–4.

**S11 Home** — §19. Ref `home-page.png`. Assets: category tiles, giveaway images. Tests: HomeCubit (loading, partial failures, search), widget (bell → S26, tile → S13, card → S20, see-all), golden en/ar 320/393/430. Acceptance: §37.5–6.

**S12 Categories** — §20. Ref `category-page.png`. Tests: filter, navigation, data-driven test (inject 2 categories → 2 banners). Acceptance: §37.7.

**S13 Category Details** — §21.1. Ref `categoryDetails -page.png`. Tests: tabs switch products; out-of-stock disabled; the balance chip updates live; golden en/ar. Acceptance: grid matches the ref; Redeem opens S14.

**S14 Redeem Sheet** — §21.2. Tests: insufficient path, identifier validation, double-tap, keyboard safe at 320×568. Acceptance: §37.8.

**S15 Redemption Result** — §21.3. Tests: success → View order → S25; failure variants. Acceptance: clear outcome, no dead buttons.

**S16 Wallet** — §22. Ref `wallet-page.png`. Tests: WALLET-001..005. Golden en/ar.

**S17 Earn Hub** — §22.3. Tests: each row navigates; the demo row is hidden in api mode.

**S18 Refer a Friend** — §27. Tests: copy writes to the clipboard (mock `SystemChannels.platform`), share invoked with the localised message (fake `SharePlatform`), no ledger change.

**S19 All Giveaways** — `lib/features/home/presentation/all_giveaways_page.dart`: filter chips All/Available/Upcoming/Ended, 2-col grid, empty per filter. Tests: filters.

**S20 Giveaway Details** — existing file restyled + rewired. Tests: update `giveaway_details_page_test` and `giveaway_details_cubit_test` to contracts; CTA states.

**S21 Participation Flow** — existing files refactored. Tests: update `participation_cubit_test`; no-ad path, ad path, duplicate, full, ended, not-started; ledger unchanged.

**S22 Number Reveal** — existing restyled; digit width; DemoChip. Tests: 4/5/6-digit formatting.

**S23 My Giveaways** — existing restyled on `watchMyEntries`. Tests: update `my_giveaways_page_test`/cubit test.

**S24 My Orders / S25 Order Details** — §25. Tests: filters, timeline, mailto launcher fake, masking.

**S26 Notifications** — §26. Tests: mark read, mark all, routing per type, badge counts.

**S27 Profile** — §23. Ref `profile-page.png`. Tests: exact menu order and absence of Wallet; stats navigation; avatar change; golden en/ar.

**S28 Account Settings** — §23.6. Tests: the privacy-choices row only when required; delete account flow; demo tools hidden in api.

**S29 Edit Profile** — rework of `edit_profile_page.dart` to the display name only (1–40 chars, trimmed). Tests: validation and the header update.

**S30 Language** — existing `language_picker.dart` restyled as `RewardsSheet` with two radio rows (English / العربية). Tests: the switch applies without restart and persists.

**S31 About** — `lib/features/profile/presentation/about_page.dart`: logo (`assets/img/app-logo.png`), app name, version (`const String.fromEnvironment('APP_VERSION', defaultValue: '1.1.1')`, documented; no new package), description, contact email (mailto), demo notice. Tests: renders, mailto.

**S32/S33 Legal** — existing pages restyled; a top `UnavailableNotice`-style banner in demo: "Demo build — this policy describes the current service and will be updated before launch." The hosted-URL buttons still follow `AppConfig.has*Url`. Tests: en/ar content, banner presence in demo.

**S34 Sign-out confirm** — `RewardsDialog` (title, body, Cancel / Sign out danger). Tests: PROFILE-002.

**S35 Winner Celebration** — existing restyled; demo trigger via inbox; acknowledged once. Tests: shows once; DemoChip.

**S36 Session Expired** — `session_expired_page.dart`: illustration `state_error`, title, body, "Log in again" → S03 prefilled. Tests: triggered by `SessionExpiredFailure` and by restore.

**S37 Demo Tools** — `lib/features/demo_tools/presentation/demo_tools_page.dart` (route only registered when `isDemo`): Add 5,000 demo points (ledger `demoGrant`), Advance latest order status, Fail & refund latest order, Simulate winner announcement, Expire session now, Reset all demo data (confirm). Every action shows a snackbar. Tests: each action's effect; the page is unreachable in api mode.

**S38 Misconfigured Build** — `lib/features/misconfigured/misconfigured_build_app.dart`: a standalone `MaterialApp` (no DI), English+Arabic static text "This build is misconfigured and cannot run." and no actions. Tests: AUTH-014(d).
