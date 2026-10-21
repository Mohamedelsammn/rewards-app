# UI modernization and banner layout verification

This task changes presentation only. No database migration, production-record edit, ad frequency change, application-ID change, signing change, splash change or number-reveal animation change was made. Existing unrelated uncommitted work was retained. Kluster remains waived under the owner's earlier explicit instruction.

## Root cause and layout correction

The user shell placed the banner in the body of an overlaid `GlassScaffold`, followed by a manually calculated `AppBottomNav.footprint`. The navigation widget separately owned 20dp top/bottom outer padding and the scaffold separately applied system safe-area positioning. The banner added 8dp above and below itself. Individual Home, My Giveaways and Settings scroll views also reserved navigation footprints. These independent reservations separated the banner from the visible pill and left unnecessary scrolling space. An overlay's estimated footprint was being used to position a sibling rather than measuring them together.

Native screenshot validation also exposed the second cause: the requested adaptive size was **411x128**, but `BannerAd.getPlatformAdSize()` returned **411x64** after loading. Using the requested height left a visible gap inside the platform-view allocation even after widget adjacency was fixed. AdService now reads the resolved SDK dimensions after each load/refresh and exposes them to AdaptiveAdBanner. Null/error responses safely fall back to the requested size. Identity/session guards reject stale size responses. No cropping, negative offset or device-specific ad height is used.

`UserTabScaffold` now hosts a normal Material `Scaffold`. Its `bottomNavigationBar` is one intrinsically measured, minimum-height Column: adaptive banner, existing AppBottomNav, then a single system SafeArea. The body and navigation retain glass rendering contexts independently; the native AdWidget is a sibling outside the custom glass shader/filter layer. There is no fixed inter-component spacer, negative margin, device-specific offset or estimated banner height. The loaded banner reserves exactly its SDK size. Pending, unavailable and failed banners reserve zero height.

AppBottomNav's docked placement removes only its outer top padding and retains the existing 20dp bottom breathing room. Its 58dp pill, icons, colors, selected-state shape, animations, routes and gesture behavior remain intact. Admin navigation's default placement is unchanged. Body pages no longer pad for an overlaid bar. The whole bottom dock is Offstage while the keyboard is open; the banner remains mounted and is reused when the keyboard closes. The ad service continues to own one banner across tabs.

AdaptiveAdBanner retains the same AdWidget instance in a RepaintBoundary for the lifetime of each BannerAd, so tab rebuilds do not rebuild the native platform-view widget. A different BannerAd receives a distinct ObjectKey, preventing an old native view from being reused for a replacement ad. Width changes immediately notify the view to unmount the disposed banner while its replacement loads. Tests assert widget-instance and State identity across all three tabs, absence of a glass-filter ancestor, and replacement lifecycle after resizing. These measures preserve lifecycle and isolate painting; they have not fully resolved the native drawing issue described below.

## UI and shared design system

- Lucide (`lucide_icons_flutter` pinned to 3.1.24) is the primary content icon family. `AppIcons` centralizes symbols for search, notifications, categories, people, timing, settings rows, profile, legal pages, back/forward navigation and admin/registration controls. Existing bottom-navigation glyphs are deliberately retained.
- Category strings resolve through one safe mapping. Legacy phone/headphone/controller/watch/home emoji and named keys render as vector icons without changing existing Supabase records. Unknown or missing keys use the grid icon. Catalog data and permissions are unchanged.
- Home retains its lazy two-column phone grid and bounded/paginated repository. Header hierarchy, 48dp notification target, search outline/focus treatment, chip dimensions, card typography and participant alignment are refined. Ended cards show one status label; useful active/upcoming timing uses vector icons. Images keep bounded decoding and caching.
- Settings uses a compact horizontal avatar/profile card with wrapping text. Shared settings sections have subtle surface shadows, directional dividers, consistent icon containers, 60dp minimum rows, wrapping labels, matching chevrons and ink feedback. The hidden privacy-choice row no longer leaves a stray divider. Profile, sign-out, language, About and existing legal navigation are preserved.
- `AppVisuals` provides shared surface/shadow, radius, icon, status-color, touch-target and short-motion tokens alongside the existing AppSpacing/AppTypography/AppColors architecture. No expensive content blur or new looping animations were introduced. Existing native chip selection and Material tap feedback are retained.

## Modified files

New production files:

- `lib/core/theme/app_icons.dart`
- `lib/core/theme/app_visuals.dart`
- `lib/shared/widgets/user_tab_scaffold.dart`

Updated production files:

- `pubspec.yaml`, `pubspec.lock` (one icon dependency; application version unchanged)
- `lib/shared/widgets/app_bottom_nav.dart`, `ad_banner.dart`, `settings_section.dart`, `hero_back_button.dart`, `language_picker.dart`
- `lib/services/ads/ad_service.dart` (resolved native banner dimensions and width-change notification; fullscreen rules unchanged)
- `lib/features/user_home/presentation/user_home_shell.dart`, `user_home_page.dart`
- `lib/features/settings/presentation/settings_page.dart`, `edit_profile_page.dart`
- `lib/features/my_giveaways/presentation/my_giveaways_page.dart`
- `lib/features/giveaway_details/presentation/giveaway_details_page.dart`
- `lib/features/admin_settings/presentation/admin_profile_page.dart`
- `lib/features/categories/presentation/category_management_page.dart`
- `lib/features/admin_auth/presentation/admin_auth_page.dart`
- `lib/features/admin_analysis/presentation/admin_analysis_page.dart`
- `lib/features/admin_dashboard/presentation/admin_dashboard_page.dart`
- `lib/features/create_giveaway/presentation/create_giveaway_page.dart`
- `lib/features/notifications/presentation/notifications_page.dart`
- `lib/features/participation/presentation/widgets/registration_form.dart`

Tests and QA:

- New `test/widgets/user_tab_scaffold_test.dart`, `app_icons_test.dart`
- Updated `test/widgets/settings_page_test.dart`, `user_home_page_test.dart`, `hero_back_button_test.dart`, `responsive_layout_regression_test.dart`, `admin_profile_page_test.dart`
- New debug-only `test_driver/ui_layout_main.dart`, never referenced by production main; uses real app screens with official Google demo ads and a mock consent context to isolate layout from missing publisher UMP messages
- This report; ignored screenshots/APKs/logs in `artifacts/ui-modernization/`

## Verification

`flutter test --no-pub`: **310 tests passed** on the final implementation (01:51, final log: `ui-modernization-tests.log`). The first regression run identified one old ListTile-specific finder; it was updated to target SettingsRow while retaining the language-navigation/persistence assertions. Native screenshot checks led to resolved-size, retained-widget and resize lifecycle regressions. All 14 banner layout tests are included in the final passing suite. No production ad-unit traffic is used for QA.

`flutter analyze --no-pub`: **No issues found** on the final application changes (74.2s, final log: `ui-modernization-analyze.log`). A lint in the standalone QA entrypoint was corrected before the clean analysis.

The layout tests assert the actual rendered AdWidget bottom equals the visible glass pill top, the pill's bottom clearance equals the retained 20dp plus system inset, and the SDK banner consumes precisely its height. They exercise all three tab destinations at 320/360/393/430/600dp in LTR and RTL, no-fill/pending states, one load across switches, and keyboard hiding/restoration without remounting. Home tests also cover 430dp in EN/AR and a single ended status label. Settings tests cover long bilingual profile text at the same widths and retained About/legal/language navigation. Existing ad service/frequency tests continue to run without production requests.

Performance is assessed structurally and through regressions: the banner remains outside scrolling content, one service owns its lifecycle, no banner reload is caused by tab selection, body lists retain lazy rendering and image caching, and lightweight ink/chip/profile transitions use the current Flutter widgets. No physical low-end frame-rate or memory benchmark is claimed.

Existing release/policy requirements remain separate: the owner's UMP messages must be configured and real-app consent verified; legal pages/Data Safety/Play version verification remain outstanding as described in the earlier release report. This task does not publish legal URLs, promote administrators or change production records. The earlier AAB candidate predates this UI follow-up; it must be rebuilt from the updated source before any release. Debug QA APKs are not submission artifacts.

## Native emulator evidence

Screenshots were captured directly with adb on the Android 17/API 37 emulator, at 1080x2424 and at 840x1890 (density 420: approximately 411dp and 320dp). English and Arabic screens were inspected visually against the owner's original captures. Real Home data comes from the existing repositories; no giveaway, category or participation records were created for these screenshots.

Google demo banner events confirmed requested/resolved sizes of **411x128 / 411x64** and **320x100 / 320x50**. Native loaded-banner captures show the ad directly above the retained navigation pill, with the existing bottom clearance and system gesture area below. The missing-banner capture shows no reserved ad-height gap. Standard docked keyboard insets are covered by widget tests; the emulator's native floating handwriting keyboard was also exercised, but does not produce the same bottom inset as a docked keyboard.

Evidence files (relative to this report):

- [Original Home](../artifacts/ui-modernization/home-before.png) and [original Settings](../artifacts/ui-modernization/settings-before.png).
- [Updated Home](../artifacts/ui-modernization/home-after.png), [Settings](../artifacts/ui-modernization/settings-after.png) and [My Giveaways](../artifacts/ui-modernization/my-giveaways-after.png).
- [Arabic Home](../artifacts/ui-modernization/home-arabic-after.png) and [Arabic Settings](../artifacts/ui-modernization/settings-arabic-after.png).
- [320dp Arabic Home](../artifacts/ui-modernization/home-320-arabic.png), [320dp Arabic Settings](../artifacts/ui-modernization/settings-320-arabic.png) and [320dp English Settings](../artifacts/ui-modernization/settings-320-english.png).
- [Unresolved native drawing issue](../artifacts/ui-modernization/banner-rtl-rendering-issue.png), captured after a tab switch; this is not an ad-load failure.
- [Banner unavailable](../artifacts/ui-modernization/home-without-banner.png) and [floating keyboard](../artifacts/ui-modernization/keyboard-after.png).
- [SDK size events](../artifacts/ui-modernization/native-banner-events.txt).

Native screenshots cover the emulator widths above. The 360/393/430/600dp, failure/no-fill and keyboard-inset matrix was rendered and checked in automated Flutter widget tests, rather than claimed as additional physical devices. No iOS native test, physical-device run or low-end performance benchmark was performed in this follow-up. Publisher UMP configuration remains a separate blocker for verifying real-app consent; the debug-only QA entrypoint uses mocked consent with Google demo ad units and cannot be used for production.

## Remaining issue and delivery verdict

**The original banner spacing defect is corrected, but this update is not yet production-ready.** At 320dp on the API 37 emulator, the native Google demo banner intermittently becomes invisible after a tab or locale change even though its allocated size, native WebView bounds and loaded ad instance remain valid. It returns on a subsequent SDK refresh. This persists after retaining the widget, isolating its repaint layer and separating glass filters. The exact native compositor/SDK cause is not confirmed. The blank slot is documented rather than represented as a passing native test or a no-fill event. Native rendering reliability must be resolved and rechecked before release.

The 411dp captures show loaded banners on all three destinations; final 320dp captures include both a properly drawn banner directly above navigation and the drawing failure. Screenshot evidence therefore verifies spacing and visual changes, not uninterrupted ad rendering in every tested state. Some 411dp screenshots precede the final compositor-isolation refinement, which does not change the component styling.

The final normal entrypoint debug APK built successfully (`flutter build apk --debug --no-pub`, 61.9s) at `artifacts/ui-modernization/rewards-app-debug.apk`. The separate `layout-test-ads.apk` is only a debug QA harness. No release AAB was rebuilt for this UI follow-up. The previous candidate must not be submitted as containing these changes. Existing UMP, legal/Data Safety and Play version verification requirements also remain open.

The normal debug APK was reinstalled successfully over the QA harness without clearing application data. The emulator display override was reset to 1080x2424, the keyboard setting restored to its original value (0), and the UI returned to English. The physical device was not modified.
