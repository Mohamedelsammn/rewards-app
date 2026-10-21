# Creative Rewards demo redesign status

## Current implementation

The Flutter demo launches with `--dart-define=DATA_MODE=demo`. Its local repository retains onboarding, session restoration, selected character, points, redemptions, giveaway entries, orders, and notifications. OTP accepts a six-digit demo code; it does not send or verify email. Production authentication and fulfillment remain pending VPS integration.

The onboarding flow is Splash → Welcome → Email → OTP → Password → Character → Home. Returning users can open Login from Welcome. Home, Categories, Wallet, and Profile share a persistent custom navigation bar. The Profile edit pencil opens the existing edit flow. Language selection uses the existing persisted `LocaleController` in a modal sheet. Sign Out requires confirmation.

## Visual refinement

All approved `design_references` images were compared with the Flutter implementation and previous emulator captures. The new My Giveaways, My Orders, and Notifications references supersede older secondary-page styling. Those pages now use pastel backgrounds, circular back controls, decorative artwork, rounded cards, repository data, and compact actions. Orders filters query actual repository statuses, and demo orders retain their no-fulfillment status. My Giveaways keeps the generated ticket number and copy action. Notifications use stored timestamps when available and show “Earlier” for old records without one.

The custom bottom navigation no longer draws a selected underline and shows a larger circular image of the selected character. Profile now has an integrated portrait frame, two statistics dividers, the retained header pencil, streamlined settings, a red Sign Out button, and confirmation dialog. The edit grid uses a clean first portrait so its selection mark follows the saved character. Login was rebuilt with the established onboarding artwork and field style. There is no separate returning-user Login reference in `design_references`; `signin-page.png` shows the email onboarding step.

Welcome spacing was adjusted to prevent overflow at 393×852 dp. The earlier Email, OTP, Password, Character, Home, Categories, and Wallet redesign work remains in place. Remaining visual differences from the generated phone mockups are recorded in [the final report](final-ui-ux-refinement-report.md).

## Verification

- `flutter analyze --no-pub`: no issues on the final code.
- `flutter test --no-pub`: 355 passed on the final code.
- `flutter build apk --release --no-pub --dart-define=DATA_MODE=demo`: passed on the final code, producing `build/app/outputs/flutter-apk/app-release.apk` (61.4 MB).
- Android emulator at 1080×2424 px: Home, Categories, Wallet, Profile, language sheet, Sign Out dialog, My Orders (empty and populated), My Giveaways (populated), Notifications, and the returning-user Login were rendered during redesign and QA. Captures are under `docs/screenshots/final-qa-*.png`; older onboarding captures remain under `docs/screenshots/redesign-*.png`.
- Widget tests cover the compact 320 dp bottom bar, 360×808 and 393×852 dp Home, compact Welcome, keyboard inset on Login, language switching, sign-out cancellation/confirmation, order filtering, giveaway navigation, and repository rules.

## Known limits

The release APK is a demo build, not a production-ready rewards service. The reference images are generated mockups without source layout measurements. Exact pixel correspondence cannot be claimed. The old and new artwork collections contain some composite illustrations, so the Email/OTP/Password crops and secondary header art remain approximate. The emulator account used for secondary-screen QA contained 60 UC demo orders and one AirPods ticket; the reference’s 180 UC and two example ticket numbers were not substituted for repository data. Complete accessibility, iOS, and all nine onboarding-screen re-captures remain open. Kluster review was unavailable because the exposed connection returned a sign-in error; Flutter checks do not replace that review.
