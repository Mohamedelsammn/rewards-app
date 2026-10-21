# Remaining Google Play and website requirements

Review date: 2026-10-11. This is a release requirements report, not a compliance certification. No website was built or published. No legal URL was invented or replaced.

## Release identity and version

Application ID and namespace remain `com.creativehub.rewardsapp`. Firebase remains `rewards-app-87115`; Supabase remains `gaarpeebmixvruxeetks`. Existing release signing properties and keystore are unchanged. Local version was `1.0.1+2`; the update is configured as `1.1.0+3`.

**Highest uploaded Google Play versionCode: Not independently verified.**

Before uploading, compare code 3 with every Play track and prior uploaded artifact, including drafts. Increase it and rebuild if necessary. Compare the upload certificate with Play App Integrity. Play App Signing's distribution certificate can differ from the local upload certificate.

## Confirmed AdMob configuration blocker

The Android emulator reached the production UMP endpoint using the owner's exact App ID. It returned: “Publisher misconfiguration ... no form(s) configured for the input app ID.” The application left ad serving disabled; it did not bypass consent.

In AdMob Privacy & messaging, configure and publish the applicable messages for `ca-app-pub-6633902647647422~7562449689`, then repeat regional consent and privacy-options tests. Check EEA/UK/Switzerland and applicable US-region choices with registered test devices. Native demo-ad smoke tests and mocked SDK tests do not establish production consent readiness. See [Google's Flutter UMP setup](https://developers.google.com/admob/flutter/privacy).

Confirm all four owner units are associated with this app, inventory is approved, mediation settings match disclosures, and app-ads.txt requirements are satisfied when the website is prepared. Do not repeatedly request owner production ads for QA.

## Data Safety and advertising declarations

No authenticated Play Console form/export is present in the repository or accessible for this task. The previous declarations could not be independently reviewed or updated in Console. Approval of the existing app does not verify the new SDK disclosures.

Review the following against the actual SDK build and business practices:

| Processing | Review in Play Console |
| --- | --- |
| Mobile Ads IP and derived location | Approximate location, collection/sharing and purposes |
| Device/ad identifiers | Device or other IDs; advertising, analytics, fraud prevention |
| Ad views/taps and launches | App interactions and purposes |
| SDK diagnostics | Crash logs/diagnostics and purposes |
| Participant name, phone, country | Existing personal-information disclosures and required/optional status |
| Supabase anonymous session/profile, entries | Identity, app activity, retention and deletion disclosures |
| FCM device token and notifications | Device identifiers and messaging functionality |
| Admin email/password accounts and prize images | Existing authentication and uploaded-content practices |

Use the [official Mobile Ads data-disclosure guide](https://developers.google.com/admob/android/privacy/play-data-disclosure) for SDK-specific data. Answer collection, sharing, purposes, encryption, optional collection, and deletion questions for the entire app. Non-personalized requests do not mean identifiers or measurement are disabled.

Set the “contains ads” declaration and review the advertising-ID declaration against the merged release manifest. Confirm target audience, content rating, and whether child-directed/under-age-of-consent flags or age screening are required. This update caps ad content at PG and requests non-personalized ads; it does not establish the app's intended age audience. Do not assume these settings alone satisfy children's requirements.

The inspected plugin is `google_mobile_ads 9.1.0`, using Android Mobile Ads `25.4.0` and UMP `4.0.0`. The merged manifest adds `AD_ID`, `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION`, `ACCESS_ADSERVICES_TOPICS`, and `FOREGROUND_SERVICE` compared with the prior local AAB. A WorkManager `SystemForegroundService` is merged by dependencies; no custom foreground-service behavior was introduced. Review applicable Play declarations against actual use and the precise SDK version. No camera, microphone, contacts, precise-location, or phone-state permission was added.

## Rewarded and giveaway policy review

Rewarded ads are an explicit optional choice. Continue Without Ad provides the same normal free entry. Closing an ad, no-fill, or show failure also permits free participation. Ads never grant additional entries or improve winning odds. No signed server reward credit, cash-equivalent reward, or purchasable entry was introduced.

Review the final optional experience against rewarded-inventory rules and applicable giveaway/sweepstakes requirements before publishing. The backend remains authoritative for entry eligibility, numbers and winners. Maintain official giveaway rules, sponsor details, eligible regions/ages, entry period and timezone, prize details, selection/notification process and any required Google non-sponsorship disclosure. This report does not certify jurisdiction-specific giveaway legality.

## Actual identity and deletion model

Participants have a persistent anonymous Supabase Auth session, a `user_devices.auth_uid` binding and a `public.users` profile after registration. Name/phone/country are cached locally. Phone is an unverified unique lookup/registration identifier, not an authentication factor. The server refuses silent cross-device linking of an already-bound phone. My Giveaways uses session-bound RLS, not a publicly supplied phone filter. Profile editing and participant self-deletion already exist and were preserved.

An existing `fn_delete_own_account()` derives the participant identity from `auth.uid()` and removes the participant's application data and current Auth identity. Its existing behavior also removes their winner references and releases allocated numbers. This task did not execute it against a real user or change that behavior. Its full retention/fairness implications should be reviewed separately; the new categories/schedule migration does not delete records.

Admins also have conventional Supabase Auth sign-up/sign-in. Participant-specific deletion does not delete admin accounts. Provide an operational, identity-verified admin deletion-request path, with a documented policy for organizer campaigns and any required retained records. A phone number alone must never authorize a web deletion request or disclosure of participation history.

Because account creation exists in the app, assess the whole product rather than declaring it account-free. Google describes both in-app and external deletion-request paths in its [account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111). Keep the existing participant deletion UI and supply a real external request resource where required.

## Future rewardsapp.tech pages

The domain is reserved for future work. No paths below are proposed as live URLs. Before publishing, prepare and verify:

1. **Privacy Policy:** app/operator identity and contact; participant/admin information; anonymous sessions; Supabase, Firebase and Google ads/UMP; IP-derived location and identifiers; purposes, sharing, consent/privacy choices, retention, deletion, international processing and applicable rights. Publish accurate English/Arabic content and an effective date. Local in-app EN/AR copy and the existing privacy HTML source were updated for AdMob; nothing was published.
2. **Terms and Conditions:** operator/contact, use of the app, organizer responsibilities, complete free-entry rules, eligibility, scheduling timezone, prizes/winners, deletion effects, dispute/support process and appropriate disclosures. Review existing copy before carrying it forward.
3. **Account/Data Deletion:** identify Rewards App and the operator, provide a working request method usable without reinstalling, explain identity verification, data deleted/retained and processing time, and cover both participants and admins. The existing `legal/delete-account.html` still says in-app deletion is unavailable; correct that stale source before publication. Verify the actual backend behavior against every retention claim.
4. **Contact/Support:** working monitored support details, response expectations, giveaway/organizer queries and a privacy/deletion contact route. Verify submitted requests reach the operator; do not silently discard them.

Test public HTTPS accessibility, mobile/RTL readability, links, real request delivery, and absence of login/paywall requirements. Set existing `PRIVACY_POLICY_URL`, `TERMS_URL`, and `DATA_DELETION_URL` build defines only after the pages work. Never submit placeholder URLs. Existing build-time URL fields and embedded policy screens were preserved.

## Submission gates

- Configure AdMob messages; verify consent, privacy choices and ad availability in the real app.
- Finish owner review of audience, giveaway/rewarded policy, SDK data disclosures and retention/deletion behavior.
- Publish and verify the legal/support/deletion resources, then rebuild with the verified legal defines.
- Verify versionCode and upload certificate in Play Console.
- Complete physical-device/low-end performance, notification delivery and production-console acceptance testing. A locally signed AAB alone is not Google Play submission readiness.
