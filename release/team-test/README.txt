Creative Rewards v1.1.1 (5) - Team test build
=============================================

File: Creative-Rewards-v1.1.1-Team-Test.apk
SHA-256: cef0c0a80d43919e37a977efed6f24910e34e3d568c46849091c8778dfc6733c
Signed with the production release key (SHA-256 347fd97c...c075a8).

For private testing on team phones only. Do not upload to Google Play.

What is different from a store build
- Built with --dart-define=ADS_TEST_MODE=true: every ad is a Google
  test ad ("Test Ad" label). No real ad impressions or revenue.
    App Open ................ ca-app-pub-3940256099942544/9257395921
    Interstitial (giveaways)  ca-app-pub-3940256099942544/1033173712
    Join Giveaway rewarded .. ca-app-pub-3940256099942544/5224354917
    Earn Points rewarded .... ca-app-pub-3940256099942544/5224354917
- Everything else is the normal release app.

IMPORTANT: it uses the LIVE backend
  https://rewards-api.creativevpnapp.com/api/v1
Accounts, orders, giveaway entries and Earn Points credits made with this
build are real production data. Earn Points credits real points (the test
ad unit is on the backend allowlist), within the normal daily limit and
cooldown.

Install: allow "Install unknown apps" for your file manager or browser,
then open the APK. If an older build signed with a different key is
installed, uninstall it first.
