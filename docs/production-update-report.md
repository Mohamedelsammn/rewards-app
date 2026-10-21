# Rewards App production update report

Date: 2026-10-11. The existing dirty development workspace was retained. The project was audited and an ordered plan written before implementation. The attached Home image guided the redesign; its sample products/counts and bottom navigation were not copied into production data. The attached text file supplied ad IDs, not additional development instructions. Kluster's connection was unavailable; the owner explicitly waived Kluster for this task. No Kluster security approval is claimed.

## A. Application Development Status

### Implemented

**Home:** one lazily built, responsive two-column phone grid replaces Featured, Popular and All sections. Cards use real cached images, rounded white surfaces, subtle shadows, title, organizer, actual participant count, effective status and timing. Header name/notification behavior is retained. There is no Home location selector; country selection remains in registration/profile. There was no functioning favorites feature or verified-organizer field, so neither unsupported icon was added. Existing `AppBottomNav` implementation, icons, shape, selected indicator, styling, animations and routes remain unchanged. The shell reserves its footprint and places a stable banner above it.

Search is a 300ms debounced, trimmed, literal Unicode title filter on Supabase, with clear action and localized empty results. Equivalent queries and tab switches avoid new requests. Search/category changes discard stale page responses. Browsing requests 24 records per page, ordered by creation time and ID; load-more is guarded, supports retry, and deduplicates IDs. Realtime count/status changes patch visible rows where possible. Slivers render visible cards lazily. Thumbnail decode width is bounded; detail images retain their existing defaults. Tablet widths can use three columns. No synthetic production giveaways/counts were introduced.

**Categories:** a shared Supabase catalog supplies English/Arabic names, optional icons, ordering and active status. All is a permanent local UI filter; the catalog itself is not hardcoded in Flutter. Nullable giveaway assignments preserve uncategorized existing records under All. Active categories are publicly readable. Only the existing database-verified `super_admin` role can manage the shared catalog; ordinary verified admins can assign active categories to their own campaigns. Fake client metadata cannot grant this role. The interface supports create/edit/enable/disable/order, and no hard-delete action/grant was introduced. Both current admins are ordinary admins; no real account was promoted. A trusted owner must provision an intended catalog manager separately.

**Admin scheduling/editing:** the existing create form retains its fields and adds category selection and precise start time. An owned non-ended giveaway can be edited from analytics. Existing images remain when not replaced. End must be strictly after start. Flutter converts device-local choices to UTC; display converts back to device local time. Optional UTC fields coexist with the legacy date/time fields, and a trigger keeps old-client writes compatible. Existing rows were not backfilled, deleted or recategorized. Their fallback dates retain the server's UTC interpretation. Editing preserves server status, number width and owner rather than reopening a campaign that ended during form editing.

Scheduled cards/details are visible before opening time, with localized start timing and a disabled participation CTA. Details rebuild at start/end boundaries, including seeded/offline data. The server checks `clock_timestamp()` at participation time, so changing the client clock cannot permit early/late entry. A started scheduled campaign can accept an eligible entry immediately without waiting for cron. The existing five-minute active cron updates materialized statuses and calls the existing winner function on expiry; winner selection and notifications were not rewritten. Drafts no longer auto-publish merely because a date arrived.

**Advertising:** official `google_mobile_ads 9.1.0` is integrated through one DI-owned service, consent gate, navigator observer and frequency controller. SDK initialization is single-flight even when sessions change. Each format has guarded loading, disposal and capped exponential retry. Fullscreen exclusion prevents overlap; critical participation/reveal/celebration flows suppress automatic ads. No ad failure blocks normal app usage. UMP privacy choices appear in Settings when required. Non-personalized requests and a PG content cap are configured; audience-specific declarations still require owner review.

| Format | Implemented behavior |
| --- | --- |
| Adaptive banner | Service-owned, reused across tabs at the same width, horizontal safe-area protection, above the unchanged navigation, no reserved height after failure |
| App Open | Initialized after the preserved splash; eligible later cold starts only during an early ready window; background returns require at least 30 seconds away; four-hour stale-ad rejection; ten-minute App Open cap plus global cooldown |
| Interstitial | Opportunity at genuine details entries 3, 6, 9, ...; missing/unshowable ad never delays navigation or queues a later surprise |
| Rewarded | Explicit Watch Ad choice, separate free continuation, result waits for dismissal, earned callback recorded independently, close/failure safely continues the normal entry |

The global automatic-fullscreen cooldown is 90 seconds. An eligible third entry is an opportunity, not a guaranteed impression: consent, availability, cooldown and critical-flow restrictions can suppress it. Reopening the same giveaway after leaving counts again. Rebuilds, scrolling, search, filtering, resume and route replacement do not add an entry. The route observer counts Home, My Giveaways and notification entry paths consistently. The entry counter is persisted to Hive.

The exact owner IDs remain configured:

| Setting | Value |
| --- | --- |
| App ID | `ca-app-pub-6633902647647422~7562449689` |
| Banner | `ca-app-pub-6633902647647422/8835913618` |
| App Open | `ca-app-pub-6633902647647422/7426718311` |
| Interstitial | `ca-app-pub-6633902647647422/7522831942` |
| Rewarded | `ca-app-pub-6633902647647422/6209750271` |

Debug/profile builds use official Google demo units. An explicit `ADS_TEST_MODE=true` can mark a release QA build; the candidate build does not set it. Native testing did not request owner production ad units.

**Participation integrity:** registration/identity and fresh eligibility checks precede an optional ad offer. Existing entries are retrieved without another ad/insert. Continue Without Ad, declined/unavailable ads, closed ads and show/load failures all preserve the same free entry and odds. No local number generation, extra entry, fabricated reward UUID or client-side winner selection was added. The server allocator runs under the existing giveaway lock and returns the existing record on duplicate requests, including after expiry/full capacity. Duplicate button taps and closing while awaiting an ad are guarded. Cache failure cannot hide a confirmed backend entry. The existing number-reveal animation is unchanged.

Google's SDK reward callback is used for the optional ad result; it is not represented as a signed server reward credit. The old simplified `verify-ad-reward` endpoint is not called. A future valuable reward would require separate verified server-side verification and policy review.

**Localization/privacy:** new UI and timing/category/ad messages have English/Arabic ARB entries and RTL support. In-app EN/AR privacy copy and the existing privacy HTML source now disclose Google ads/UMP, identifiers/IP-derived location, interactions/diagnostics, privacy choices and optional free entry. No website/legal page was published, no URL was invented, and existing legal navigation/build configuration was retained.

### Supabase deployment and verification

Live project: `gaarpeebmixvruxeetks`. Applied migrations, independently confirmed in `supabase_migrations.schema_migrations`:

| Version | Migration | Result |
| --- | --- | --- |
| `20261011181138` | `categories_and_utc_scheduling` | Applied; central catalog, nullable relationship/UTC fields, RLS, indexes, legacy synchronization, exact server eligibility and idempotency |
| `20261011184508` | `browse_title_search_index` | Applied; `pg_trgm` and published-catalog title GIN index for substring search |

The interval constraint is intentionally NOT VALID for historical rows, preserving existing records; it still checks new/changed rows. The trigger validates new scheduling changes. Service-role-only allocation/sequence/winner boundaries remain in force. The categories realtime publication was added; old tables/policies/contracts were retained.

`supabase/verification/categories_scheduling_checks.sql` was executed successfully against the live schema inside a transaction and rolled back. It covers future/expired entries, invalid intervals, scheduled participation without cron delay, idempotency, ordinary-admin/fake-metadata denial, super-admin create/edit/disable, owner assignment, cross-admin time-change denial, participant number-change/allocation denial, inactive visibility, anonymous create/allocation denial and category-delete denial. Synthetic privileged accounts existed only inside the rolled-back transaction.

Verified counts remained: 2 giveaways, 3 participant profiles, 3 entries, 2 winners, 2 admins. The 6 new catalog rows are the intentional new data. No verification giveaway remained. No real account, winner or participation was deleted, changed or reset by these checks.

Security advisors were reviewed, not reported as universally clean. Existing warnings include callable SECURITY DEFINER helpers, policies supporting anonymous Auth sessions, and disabled leaked-password protection. The four private operational tables deliberately have RLS with no client policies. The new catalog's authorization was explicitly tested. Review [SECURITY DEFINER exposure](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable), [anonymous-session policies](https://supabase.com/docs/guides/database/database-advisors?queryGroups=lint&lint=0012_auth_allow_anonymous_sign_ins), and [password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) in the project's broader hardening work. Performance advisors reported unused-index information; no indexes were dropped based on a tiny live dataset.

### Executed quality checks

- `flutter analyze --no-pub`: **No issues found** on the final application changes.
- `flutter test --no-pub`: **280 tests passed**, including the existing regression suite and new Home, repository, UTC scheduling, category management, ad lifecycle/frequency and optional-participation tests.
- SDK/UMP tests mock native channels and use Google test units. Tests include single initialization across session changes, consent denial, third-entry route counting/same-ID reopen, no double-counting/replacement/resume counts, App Open visibility/cooldown/exclusion, rewarded callback/dismissal/show-failure, banner reuse/failure/disposal, stale callbacks, free participation, existing entry reuse and closure while awaiting ads.
- Responsive Home tests cover English/Arabic at 320, 360, 393 and 700dp. Existing navigation, splash, registration/profile, analytics/wheel, notifications and reveal-related regression tests remain in the suite. Existing larger-text responsive tests also pass.
- Live SQL checks: **passed and rolled back**; applied migration names and title index verified separately.

Android emulator testing used Android 17/API 37, `emulator-5554`, 1080x2424 at density 420. The preexisting debug certificate matched the QA APK, so installation used an in-place update without clearing/uninstalling app data. The physical Android 10 device was not modified or tested.

The real app reached its preserved role selector and Home, rendering the 2 real ended campaigns, actual images/counts, dynamic categories, header/notifications and unchanged navigation. Native UMP reported a publisher configuration error: no forms exist for the supplied owner App ID. Production consent was not bypassed; ad requests stayed disabled.

A separate debug-only `test_driver/ad_smoke_main.dart` exercised official Google demo units with a mocked consent context, no Supabase initialization and no participation creation. Native Banner, App Open, Interstitial and Rewarded ads loaded and displayed. App Open/Interstitial/Rewarded dismissal events and the Rewarded earned callback were recorded. This verifies native rendering/callbacks, not production UMP account setup or all real-app integration paths. The QA entrypoint is not referenced by the production build.

Evidence is retained under ignored `artifacts/qa/`, including Home/ad screenshots and `native-ad-smoke-events.txt`. The ordinary application is restored on the emulator after this standalone QA test.

Performance findings: bounded 24-row network pages, lazy visible-card construction, cached/size-bounded thumbnails, guarded paging, debounced search and stable banner ownership are implemented and tested. The live catalog has only 2 campaigns, so no large-production-catalog load benchmark, physical low-end frame-rate/memory measurement, or long-duration device run is claimed. Native debug timing is not a release performance benchmark. Notification token retrieval was observed; actual remote FCM delivery was not independently tested.

### Release artifact

Final candidate: `artifacts/rewards-app-1.1.0+3-candidate.aab`, also generated at `build/app/outputs/bundle/release/app-release.aab`. Size: **68,930,203 bytes (65.74 MiB)**. Version name/code: **1.1.0 / 3**. SHA-256: `2c9b57a0af8c373ca2f6a4e89fbab14f1a565c8b76575dc80f98bb588bcf0db5`.

`bundletool 1.18.3 validate` succeeded. The decoded final manifest confirms `com.creativehub.rewardsapp`, `debuggable=false`, minimum SDK 24, target SDK 36 and the exact owner AdMob App ID. All four owner unit IDs, the correct Supabase URL and Firebase project are present in the ARM64 Dart binary. Google demo ad units and the standalone QA entrypoint marker are absent. Embedded JWT inspection found the intended anon role and no service-role credential. Native ABIs are ARM64, ARMv7 and x86_64. This inspection is targeted release verification, not a guarantee against every possible secret format.

Release certificate SHA-256: `34:7F:D9:7C:FC:4A:96:0C:22:F4:B4:60:4C:FA:F5:2A:10:DC:68:F9:5F:00:61:63:F0:C8:44:76:6C:C0:75:A8`. It matches both the existing keystore's public certificate and the prior local AAB. It is not the debug certificate. `jarsigner` reports “jar verified”; it also reports self-signed/untrusted-chain, no-timestamp, POSIX-attribute and JarInputStream entry-order warnings. The same warnings occur for the prior local AAB. They are retained in the evidence rather than described as a warning-free signing check; Play Console upload acceptance was not tested.

The prior AAB is backed up under `artifacts/previous/`. No signing password/private key was printed, changed or replaced. The final release build ran independently after a transient shared Flutter-cache conflict during a parallel attempt. Flutter analysis and all 280 tests passed before this final build. Native dependency compilation emitted deprecation warnings; the final build succeeded.

Build configuration uses `lib/main.dart`, `APP_ENV=prod`, the existing Supabase project URL and existing anon client key. The application ID/namespace, Firebase project, upload key and signing alias/passwords are unchanged. Public legal URL defines are left unset because no verified new URLs are available; embedded pages remain usable.

### Changed files

See [the complete file inventory](production-update-files.md). It distinguishes this task's source changes, generated localization, QA files, incidental formatting and preexisting user work.

## B. Remaining Google Play and Website Requirements

**Verdict: development implemented and automated checks passed; Google Play submission readiness is not verified.** A successful technical AAB does not resolve the AdMob privacy configuration error, unavailable Console declarations or unverified public legal URLs.

**Highest uploaded Google Play versionCode: Not independently verified.** Check code 3 against all uploaded tracks/drafts before upload and rebuild if necessary. Compare the upload certificate in Play App Integrity. No Play submission was performed.

Configure/publish applicable AdMob privacy messages, then repeat real-app consent and ad tests. Review audience/age flags, rewarded/giveaway policy, Data Safety, advertising-ID/SDK-added permissions, deletion/retention and admin deletion handling. Provision an intended shared-category manager through trusted database administration if required. Complete physical/low-end and notification delivery QA.

No future-domain website was built. Prepare, review and verify Privacy Policy, Terms, Account/Data Deletion and Contact/Support on the owner's future domain before assigning real URLs in the app or Play Console. Local legal source includes stale deletion-page wording that must be corrected before publication. The separate [Google Play and website requirements report](google-play-and-website-requirements.md) gives the specific requirements and evidence gaps.
