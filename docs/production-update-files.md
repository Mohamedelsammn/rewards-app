# Files changed by this update

The workspace already contained extensive uncommitted development work. This inventory identifies this task's edits; it does not attribute the entire `git status` diff to this task. Existing deletions, Android identity/signing changes, artwork and unrelated feature work were not reverted or replaced.

## Configuration and documentation

- `.gitignore` — exclude generated local artifacts.
- `pubspec.yaml` — official Mobile Ads dependency and version 1.1.0+3.
- `pubspec.lock` — resolved Mobile Ads/plugin dependencies.
- `android/app/src/main/AndroidManifest.xml` — owner AdMob App ID and Internet permission.
- `docs/production-update-plan.md` — audit and ordered implementation plan.
- `docs/production-update-files.md` — this inventory.
- `docs/production-update-report.md` — implementation, validation and release report.
- `docs/google-play-and-website-requirements.md` — separate outstanding policy/website requirements.

## Home and data access

- `lib/features/user_home/presentation/user_home_page.dart` — unified responsive lazy grid, search, category chips and real data cards.
- `lib/features/user_home/presentation/user_home_shell.dart` — persistent banner placement and ad session/critical-flow lifecycle.
- `lib/features/user_home/presentation/bloc/user_home_cubit.dart` — bounded pages, debounce, filtering, stale-response protection and realtime updates.
- `lib/features/user_home/presentation/bloc/user_home_state.dart` — categories and pagination state.
- `lib/shared/models/giveaway.dart` — optional category/UTC timestamps and effective status.
- `lib/shared/models/giveaway_category.dart` — new bilingual catalog model.
- `lib/shared/repositories/giveaway_repository.dart` — bounded browse requests, UTC publish/edit and cache invalidation.
- `lib/shared/repositories/category_repository.dart` — new central Supabase catalog access.
- `lib/shared/widgets/app_network_image.dart` — optional bounded thumbnail decode width; other callers retain defaults.

## Administration and scheduling

- `lib/features/categories/presentation/category_management_page.dart` — new authorized create/edit/enable/order interface.
- `lib/features/admin_settings/presentation/admin_profile_page.dart` — permission-based catalog-management entry.
- `lib/features/create_giveaway/presentation/create_giveaway_page.dart` — category selection, precise start/end, edit initialization and validation.
- `lib/features/create_giveaway/presentation/bloc/create_giveaway_cubit.dart` — schedule/category/image persistence and duplicate-submit guard.
- `lib/features/giveaway_analytics/presentation/giveaway_analytics_page.dart` — edit an owned non-ended giveaway.
- `lib/features/giveaway_details/presentation/bloc/giveaway_details_cubit.dart` — start/end boundary timers and closed-state guards.
- `lib/features/giveaway_details/presentation/bloc/giveaway_details_state.dart` — clock revision for boundary rebuilds.
- `lib/features/giveaway_details/presentation/giveaway_details_page.dart` — effective status and disabled localized upcoming CTA.
- `supabase/migrations/20261011181138_categories_and_utc_scheduling.sql` — additive migration, applied to the real project.
- `supabase/migrations/20261011184508_browse_title_search_index.sql` — title-search trigram index and extension, applied to the real project.
- `supabase/verification/categories_scheduling_checks.sql` — executed transactional authorization/scheduling/idempotency checks, rolled back.

## Advertising and participation

- `lib/services/ads/ad_constants.dart` — new owner production IDs and official Google demo IDs for debug/profile/explicit QA.
- `lib/services/ads/ad_frequency_controller.dart` — new persisted-entry frequency and fullscreen exclusion logic.
- `lib/services/ads/ad_service.dart` — new centralized consent/SDK/ad/lifecycle service and route observer.
- `lib/shared/widgets/ad_banner.dart` — new reusable adaptive banner presentation.
- `lib/core/di/injection.dart` — register catalog and ad singletons.
- `lib/main.dart` — shared navigator observer.
- `lib/features/my_giveaways/presentation/my_giveaways_page.dart` — named genuine details-entry routes.
- `lib/shared/utils/notification_routing.dart` — named details routes for notifications.
- `lib/features/participation/presentation/bloc/participation_cubit.dart` — optional pre-entry callback, existing-number retrieval, eligibility and duplicate/closed-state guards.
- `lib/features/participation/presentation/pages/participation_flow_page.dart` — explicit optional ad choice, free continuation and critical-flow exclusion.
- `lib/features/settings/presentation/settings_page.dart` — required UMP privacy-options entry.
- `lib/core/error/failure.dart` — localized invalid-schedule failure.

## Localization and privacy source

- `lib/l10n/app_en.arb`
- `lib/l10n/app_ar.arb`
- `lib/l10n/generated/app_localizations.dart`
- `lib/l10n/generated/app_localizations_en.dart`
- `lib/l10n/generated/app_localizations_ar.dart`
- `lib/features/legal/presentation/legal_content.dart` — in-app English/Arabic AdMob disclosure and choices.
- `legal/privacy-policy.html` — updated existing privacy source; not published.

## Automated and native QA

- `test/features/user_home/user_home_cubit_test.dart` — paging/search/category/race/error tests.
- `test/widgets/user_home_page_test.dart` — grid, real counts, narrow widths and Arabic RTL.
- `test/widgets/responsive_phase8_test.dart` — adapt Home mock to bounded browsing.
- `test/widgets/category_management_page_test.dart` — new authorization, create/edit/disable and bilingual UI tests.
- `test/services/ad_frequency_controller_test.dart` — new navigation frequency, caps and exclusion tests.
- `test/services/ad_service_test.dart` — new mocked SDK/UMP lifecycle and callback tests.
- `test/features/participation/optional_ad_participation_test.dart` — new free-entry/optional-callback/idempotent UI-state tests.
- `test/shared/models/giveaway_schedule_test.dart` — new UTC boundary and legacy fallback tests.
- `test/shared/browse_repository_test.dart` — new local HTTP contract tests for catalog and bounded filtered browsing.
- `test_driver/ad_smoke_main.dart` — new debug-only standalone native demo-ad QA entrypoint; never referenced by production main.

## Incidental formatting or lint-only edits

- `lib/features/splash/presentation/cubit/splash_cubit.dart` — initializing-formal lint only; animation behavior unchanged.
- `lib/shared/repositories/winner_repository.dart` — equivalent null-aware map-entry syntax; winner selection unchanged.
- `lib/features/settings/presentation/edit_profile_page.dart` — formatter only.
- `test/services/user_identity_service_test.dart` — formatter only.
- `test/shared/notification_routing_test.dart` — formatter only.
- `test/shared/repositories/user_repository_test.dart` — formatter only.

`lib/shared/widgets/app_bottom_nav.dart`, splash artwork/page, number-reveal page/animation, signing properties/keystore, Firebase configuration, and the winner-selection function were not edited by this task.

## Generated local evidence

Ignored local outputs include `analyze-production-update.log`, `test-results-production-update.log`, `release-candidate-build.log`, QA build logs and `artifacts/`. These hold the prior AAB backup, candidate AAB, debug QA APKs, bundletool, screenshots, native demo-ad events and manifest/signature verification evidence. They are not source files intended for commit. No signing password, private key or Supabase service-role credential was added.
