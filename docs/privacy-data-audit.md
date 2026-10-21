# Creative Rewards App privacy and data audit

Audit date: 12 October 2026  
Scope: checked-in Flutter/Dart source, Android configuration, local legal copy, and Supabase migrations. No participant records were queried.

## Evidence and limits

The repository contains the app source and migrations, but the connected Supabase account currently exposes only a project named **Life Coach** (`cdqopwusqbsmmuxpgszr`), which is unrelated to this application. The app project's live schema, deployed migration history, Edge Functions, RLS policies, and retention behavior therefore could not be independently verified. The app's Supabase URL/project reference is supplied through `--dart-define`; no production database credentials were read. Findings below describe checked-in code, not confirmed live deployment.

The public Google Play listing for package `com.creativehub.rewardsapp` was opened during this audit. It identifies the developer as **عبدالرحمن محمد رمضان**, lists a support email and phone, and links the developer website to `creativerewardapp.tech`. The app owner has separately confirmed `mohamed.elsamman.dev@gmail.com` as the website's privacy/support/deletion contact and says the legal operator name is not confirmed. The site uses the owner-confirmed email and does not state a company or personal legal name. The Play listing's different support email is a contact mismatch to align. The same listing currently says **“No data collected”** and **“No data shared,”** and says account information can be deleted from account settings. Those statements conflict with the reviewed code described below. The site must describe the source accurately; the Play Console Data safety and deletion declarations and the in-app deletion capability need correction/verification before the listing can be considered aligned.

The source uses one shared Supabase client. Its configured project URL and anon key come from build-time defines in `lib/config/env.dart`. The anon key is client configuration, not a service-role secret. No service-role key was found in the reviewed client source.

## Participant identity and information

- Participants use Supabase anonymous Auth sessions. On first registration they submit full name, phone number, and country code. There is no participant email/password login and no phone OTP verification in the registration flow.
- `fn_register_or_link_user` is called through `UserRepository.registerOrLink`; the source comments say a phone is bound to the first successfully registered device identity, and a different device cannot recover that identity by re-entering the phone number. This makes the participant identity persistent and device-bound, not account-free.
- A linked participant profile has an internal ID, full name, E.164 phone number, and country code. Name, phone, country, internal user ID, and the Supabase anonymous refresh token are cached using `flutter_secure_storage`. The Supabase SDK separately persists its session. Language and last-used app role are also cached.
- Participants can edit their name, phone, and country through the Settings profile screen. Phone uniqueness and input validation are enforced by server RPCs according to repository comments.
- The Edge Function `create-participation` is the write path for giveaway entry. The app retrieves the authenticated device's entries from `participations`; each entry includes giveaway ID, server participation number/sequence, creation time, and optionally a reveal timestamp. The flow checks for an existing entry and the migration's server function is idempotent, so repeat requests return the existing participation rather than allocating a second one.
- “My Giveaways” reads entries scoped to the current authenticated identity, caches results by Supabase auth UID, and subscribes to relevant realtime changes. The code does not look up participant entries by phone number.
- Existing legal text and app source indicate organizers/admins can choose a winner and winner announcements can be shown in-app and through notifications. Winner names/participation details may therefore be disclosed in the app as part of results; exact fields displayed should be rechecked against the deployed details screen before publication.

## Admin identities

Admins are separate from participants. They use Supabase email/password Auth and a server-side `admin_users` authorization check; admin registration also uses an invitation/access-code flow. The participant account-deletion RPC explicitly rejects identities without a linked `user_devices` record, so it is not an admin deletion mechanism. No verified self-service admin account deletion workflow was found.

## Notifications and other processors

- Firebase Core and Firebase Cloud Messaging are present. The app requests notification permission, obtains/refreshes an FCM device token, stores it in `user_devices.fcm_token`, and handles notification taps. The checked-in Firebase config files identify a Firebase project, but this audit did not inspect its console settings, message payload practices, retention, or processor terms.
- Supabase is used for Auth and app data; Storage is used for giveaway images in the app. The full live table layout, backups, database region, retention, and policies remain unverified because the app project is inaccessible through the current connection.
- `google_mobile_ads` is configured with the app owner's production AdMob App ID and Banner, App Open, Interstitial, and Rewarded unit IDs. Non-release/test mode selects Google's official test unit IDs. The service uses `ConsentInformation`/UMP, checks `canRequestAds()`, requests non-personalized ads, and exposes a privacy-options action when required by UMP. This source inspection does not verify the messages configured in the AdMob console or regional behavior on real devices. Google Mobile Ads may process device/ad identifiers, IP-derived and diagnostic/ad-interaction information under Google's terms; non-personalized requests do not mean the SDK processes no device data.
- No Google Analytics package or other analytics provider was identified in `pubspec.yaml` or the reviewed service wiring. Giveaway analytics in the app refers to organizer-facing campaign metrics; the remote implementation and logging/retention could not be verified without the live project and functions.

## Deletion and retention

- `UserRepository.deleteMyAccount()` calls `fn_delete_own_account()` with no user-supplied ID. The checked-in SQL resolves the caller using `auth.uid()`, deletes that participant's winner link, entries, notifications, device rows, profile, related ad-reward events, and Auth identity, and repairs participant-count/number-pool bookkeeping. It is designed not to delete giveaways or other participants.
- The migration header explicitly says this deletion migration was written without live database access and must be applied manually; the paired SQL verification script explicitly says it was not executed. Current live deployment is unverified.
- No UI in the reviewed Flutter source invokes `deleteMyAccount()`. No public automated deletion endpoint exists in the website or app code. The public site should therefore provide a support-request route and must not promise instant or automatic deletion. A support request must not be approved solely because it contains a phone number; the app has no phone OTP proof. The operator needs a documented, safe identity-verification and deletion procedure before publishing.
- The code provides local identity clearing and account deletion logic but no general data-retention schedule, backup expiry duration, or data export workflow. These must not be represented as a fixed number of days without operator confirmation.

## Giveaway scheduling and categories

Checked-in migration `20261011181138_categories_and_utc_scheduling.sql` adds a reusable category catalog, nullable category relation, UTC `starts_at`/`ends_at`, indexes, admin-gated category RLS, and a server-authoritative participation function that checks status and trusted database time. It also defines a service-role-only status updater. The migration seeds category rows, but its checked-in Arabic/icon seed literals display as mojibake in this PowerShell read; verify encoding/content in the deployed database. Neither schema rollout nor scheduled job configuration can be confirmed live.

## Legal facts requiring owner/deployment confirmation

1. The app name and application ID are verified from the request and source, but no legal company/person, registered address, or governing jurisdiction is documented. The public policy must identify the operator without inventing a legal entity.
2. The owner confirmed `mohamed.elsamman.dev@gmail.com` for website privacy, support, and deletion requests. This matches the app source default, but differs from the current Play listing support email `dr.abdellrahman2024@gmail.com`. Align Play Console and app configuration/contact copy before the next release.
3. No app-wide age gate/date-of-birth field was found in the reviewed registration form. Campaign eligibility rules may impose age/country requirements, but each campaign's terms need to supply them. Do not claim verified child-safety/age compliance.
4. Confirm exact public winner fields, live notification behavior, actual data retention/backup windows, Supabase hosting region, Firebase/Google settings, and the deployed account-deletion migration/UI.
5. The live Play listing is available, but its Data safety answers (“No data collected” and “No data shared”) conflict with the code. Its claim that account deletion is available in settings conflicts with the absence of a UI caller for `deleteMyAccount()`. Update and re-verify the declarations and implement/verify the deletion path before claiming store-policy alignment.

## Publication posture

The website copy must describe observed app behavior and distinguish source-code evidence from backend facts that remain unverified. Before publication, confirm operator/support details, review the legal text, verify the app project migration and RLS/function state, and align Google Play Data Safety/account deletion and AdMob consent disclosures with actual console configuration.
