// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Creative Rewards';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSave => 'Save';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get refreshFailed => 'Couldn\'t refresh. Showing the last loaded content.';

  @override
  String pointsAmount(String points) {
    return '$points PTS';
  }

  @override
  String onboardingStep(int step, int total) {
    return 'Onboarding step $step of $total';
  }

  @override
  String errorReference(String id) {
    return 'Reference: $id';
  }

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get errUnknown => 'Something went wrong. Please try again.';

  @override
  String get errServer => 'The service is having trouble. Please try again shortly.';

  @override
  String get errNetwork => 'No internet connection. Check your connection and try again.';

  @override
  String get errTimeout => 'The request took too long. Please try again.';

  @override
  String get errInvalidCredentials => 'Incorrect email or password';

  @override
  String get errSessionExpired => 'Your session expired. Please sign in again.';

  @override
  String get errAccountSuspended => 'This account is suspended. Contact support for help.';

  @override
  String get errFeatureDisabled => 'This feature isn\'t available right now.';

  @override
  String get errNotFound => 'This item is no longer available.';

  @override
  String get errEmailTaken => 'This email already has an account.';

  @override
  String get errInsufficientPoints => 'You don\'t have enough points for this reward.';

  @override
  String get errOutOfStock => 'This reward is out of stock.';

  @override
  String get errPriceChanged => 'The price of this reward has changed.';

  @override
  String get errInvalidTransition => 'This order can no longer be changed.';

  @override
  String get errRequestInProgress => 'Your request is still being processed. Please wait.';

  @override
  String get errPreviousAttemptUncertain =>
      'We couldn\'t confirm your previous request. Check My Orders before sending again.';

  @override
  String get errGiveawayNotStarted => 'This giveaway hasn\'t started yet.';

  @override
  String get errGiveawayEnded => 'This giveaway has ended.';

  @override
  String get errGiveawayNotActive => 'This giveaway isn\'t open right now.';

  @override
  String get errGiveawayFull => 'This giveaway is full.';

  @override
  String get errStepsIncomplete => 'Complete the required steps first.';

  @override
  String get errClaimNotAllowed => 'This prize can no longer be claimed.';

  @override
  String get errValidation => 'Check the information you entered.';

  @override
  String get errOtpInvalid => 'The code is incorrect.';

  @override
  String get errOtpExpired => 'This code expired. Request a new one.';

  @override
  String get errOtpAttemptsExceeded => 'Too many wrong attempts. Request a new code.';

  @override
  String get errOtpVerificationInvalid => 'Your email verification expired. Please start again.';

  @override
  String errOtpResendCooldown(int seconds) {
    return 'Please wait $seconds seconds before requesting another code.';
  }

  @override
  String get errOtpSendLimit => 'Too many codes were requested. Try again later.';

  @override
  String get errOtpLocked =>
      'Verification is temporarily locked. Try again in an hour or sign in with your password.';

  @override
  String get errEmailNotConfigured => 'Email delivery is unavailable right now. Try again later.';

  @override
  String get errInvalidPassword => 'The password is incorrect.';

  @override
  String get errInvalidAvatar => 'Choose another character.';

  @override
  String get errProofRequired => 'Add a short proof to submit this step.';

  @override
  String get errRateLimited => 'Too many attempts. Please wait a moment.';

  @override
  String get errDailyLimit => 'You\'ve reached today\'s limit. Come back tomorrow.';

  @override
  String get errDeviceLimit => 'This device reached today\'s limit.';

  @override
  String errCooldown(int seconds) {
    return 'Wait $seconds seconds before the next ad.';
  }

  @override
  String get errTooManyPending => 'You have unfinished video rewards. Try again in a few minutes.';

  @override
  String get errAdSessionNotFound => 'This reward wasn\'t found. No points were added.';

  @override
  String get errAdSessionNotOwned => 'This reward belongs to another account.';

  @override
  String get errAccountInactive => 'Your account can\'t earn rewards right now.';

  @override
  String get errAdUnitNotAllowed =>
      'Rewarded videos aren\'t available right now. No points were added.';

  @override
  String get errNumberAllocation => 'We couldn\'t assign your number. Please try again.';

  @override
  String get errInvalidCursor => 'The list changed. Pull to refresh.';

  @override
  String get splashTagline => 'Play · Earn · Redeem';

  @override
  String get maintenanceTitle => 'We\'ll be right back';

  @override
  String get maintenanceBody => 'Creative Rewards is under maintenance. Please try again soon.';

  @override
  String get updateTitle => 'Update required';

  @override
  String get updateBody => 'Please update Creative Rewards to keep using it.';

  @override
  String get updateButton => 'Update now';

  @override
  String get offlineTitle => 'Can\'t connect';

  @override
  String get offlineBody => 'Check your internet connection and try again.';

  @override
  String get serviceUnavailableTitle => 'Service not connected';

  @override
  String get serviceUnavailableBody =>
      'Creative Rewards is unavailable until the service is connected.';

  @override
  String get serviceInsecureBody => 'This build can\'t use an insecure connection.';

  @override
  String get welcomeTitleTop => 'Your Rewards';

  @override
  String get welcomeTitleBottom => 'Journey Starts Here';

  @override
  String get welcomeSubtitle => 'Play, earn, and redeem amazing rewards with ease.';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get welcomeHaveAccount => 'Already have an account? ';

  @override
  String get welcomeLogin => 'Login';

  @override
  String get authInvalidEmail => 'Enter a valid email address';

  @override
  String get emailTitleStart => 'What’s your ';

  @override
  String get emailTitleAccent => 'email?';

  @override
  String get emailSubtitle => 'We’ll send you a verification code to confirm your account.';

  @override
  String get emailSendCode => 'Send Code';

  @override
  String get emailLoginInstead => 'Already have an account? Log in';

  @override
  String get otpTitleStart => 'Check your ';

  @override
  String get otpTitleAccent => 'email';

  @override
  String get otpSentTo => 'We’ve sent a 6-digit code to';

  @override
  String otpResendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpResent => 'A new code was sent.';

  @override
  String get otpEnterSix => 'Enter six digits';

  @override
  String otpAttemptsLeft(int count) {
    return '$count attempts left';
  }

  @override
  String get otpSpamHint =>
      'Didn’t get it? Check your spam folder, then resend after the countdown.';

  @override
  String get otpCodeLabel => '6-digit verification code';

  @override
  String get passwordTitleStart => 'Create a ';

  @override
  String get passwordTitleAccent => 'password';

  @override
  String get passwordResetTitleStart => 'Reset ';

  @override
  String get passwordResetTitleAccent => 'password';

  @override
  String get passwordSubtitle => 'Set a secure password for your account.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordConfirmLabel => 'Confirm password';

  @override
  String get passwordRuleLength => 'At least 8 characters';

  @override
  String get passwordRuleLettersNumbers => 'Include letters and numbers';

  @override
  String get passwordRuleStrong => 'Use a strong password';

  @override
  String get passwordTooWeak => 'Use 10 or more characters with uppercase, lowercase, and numbers';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordSave => 'Save Password';

  @override
  String get passwordResetDone => 'Password updated. Sign in with your new password.';

  @override
  String get characterTitle => 'Choose Your Character';

  @override
  String get characterSubtitle => 'Pick a character to represent you in the app.';

  @override
  String characterOption(int number) {
    return 'Character $number';
  }

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue your rewards journey.';

  @override
  String get loginEmailHint => 'Email address';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginForgot => 'Forgot password?';

  @override
  String get loginButton => 'Login';

  @override
  String get loginBusy => 'Signing in...';

  @override
  String get loginInvalidInput => 'Enter a valid email and password';

  @override
  String get loginEnterEmailFirst => 'Enter your email first';

  @override
  String get loginCreateAccount => 'New here? Create an account';

  @override
  String get navHome => 'Home';

  @override
  String get navCategories => 'Categories';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navProfile => 'Profile';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get homeYourPoints => 'Your Points';

  @override
  String get homeSearchHint => 'Search rewards, giveaways...';

  @override
  String get homeAvailableRewards => 'Available Rewards';

  @override
  String get homeFeaturedRewards => 'Featured Rewards';

  @override
  String get homeGiveaways => 'Giveaways';

  @override
  String get homeNoResults => 'No rewards found';

  @override
  String get homeNoResultsBody => 'Try a different name or check the spelling.';

  @override
  String get homeEmpty => 'New rewards are on the way. Check back soon.';

  @override
  String get homeEmptyTitle => 'Rewards are on the way';

  @override
  String get homeEmptyBody =>
      'We\'re preparing new rewards and giveaways for you. Pull down to refresh or check back soon.';

  @override
  String get homeClearSearch => 'Clear search';

  @override
  String get giveawayAvailable => 'Available';

  @override
  String get giveawayUpcoming => 'Coming soon';

  @override
  String get giveawayEnded => 'Ended';

  @override
  String get giveawayWinnersSelected => 'Winners announced';

  @override
  String get giveawayCancelled => 'Cancelled';

  @override
  String giveawayEndsOn(String date) {
    return 'Ends $date';
  }

  @override
  String giveawayStartsOn(String date) {
    return 'Starts $date';
  }

  @override
  String giveawayParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '1 participant',
      zero: 'No participants yet',
    );
    return '$_temp0';
  }

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesEmpty => 'No categories yet. Check back soon.';

  @override
  String get categoriesEmptyTitle => 'No categories yet';

  @override
  String get categoriesEmptyBody => 'Reward categories will appear here as soon as they\'re added.';

  @override
  String get categoryProductsEmpty => 'No rewards in this category yet.';

  @override
  String get productTabTopUps => 'UC Top-Ups';

  @override
  String get productTabItemsSkins => 'Items & Skins';

  @override
  String get productTopUpsEmpty => 'No top-ups available yet.';

  @override
  String get productItemsSkinsEmpty => 'No items or skins available yet.';

  @override
  String get productRedeem => 'Redeem';

  @override
  String get productOutOfStock => 'Out of stock';

  @override
  String get redeemTitle => 'Redemption details';

  @override
  String redeemBalanceLine(String balance, String after) {
    return 'Balance: $balance PTS  •  After: $after PTS';
  }

  @override
  String get redeemConfirm => 'Confirm redemption';

  @override
  String get redeemReviewTitle => 'Check your details';

  @override
  String redeemReviewBody(String product, String points) {
    return '$product for $points will be sent to:';
  }

  @override
  String get redeemReviewEdit => 'Edit';

  @override
  String get redeemAccountDetailsMissing =>
      'This reward can\'t be redeemed yet: its account details aren\'t set up. Please try again later.';

  @override
  String get redeemFieldRequired => 'This field is required';

  @override
  String redeemFieldInvalid(String label) {
    return 'Check the $label format';
  }

  @override
  String get redeemInvalidNumber => 'Use digits only';

  @override
  String get redeemInvalidUrl => 'Enter a valid URL';

  @override
  String get redeemInvalidPhone => 'Enter a valid phone number';

  @override
  String get redeemInvalidOption => 'Choose one of the options';

  @override
  String get redeemSelectHint => 'Choose an option';

  @override
  String get redeemPrivacyNote => 'We will never ask for your passwords or verification codes.';

  @override
  String get redeemPointsNote =>
      'Points are deducted when you confirm and refunded if the order can\'t be completed.';

  @override
  String get redeemSuccessTitle => 'Order placed';

  @override
  String redeemSuccessBody(String points) {
    return '$points PTS were deducted. Track your order in My Orders.';
  }

  @override
  String get redeemViewOrders => 'View my orders';

  @override
  String get redeemInsufficientTitle => 'Not enough points';

  @override
  String get redeemInsufficientTitleCaps => 'Not Enough Points';

  @override
  String redeemInsufficientBody(String balance, String required) {
    return 'You have $balance PTS. This reward needs $required PTS.';
  }

  @override
  String get redeemInsufficientMessage => 'You need more points to redeem this reward.';

  @override
  String get redeemYourBalance => 'Your balance';

  @override
  String get redeemRequired => 'Required';

  @override
  String get redeemMissing => 'Missing';

  @override
  String get redeemEarnPoints => 'Earn points';

  @override
  String get redeemPriceChangedTitle => 'Price changed';

  @override
  String redeemPriceChangedBody(String points) {
    return 'This reward now costs $points PTS. Do you want to continue?';
  }

  @override
  String redeemConfirmNewPrice(String points) {
    return 'Redeem for $points PTS';
  }

  @override
  String get walletTitle => 'Your Rewards';

  @override
  String get walletPoints => 'POINTS';

  @override
  String get walletBalance => 'BALANCE';

  @override
  String get walletFastEarn => 'Fast, Earn';

  @override
  String get walletPlaceOrder => 'Place an Order';

  @override
  String get walletPlaceOrderSubtitle => 'Browse rewards to redeem';

  @override
  String get walletReview => 'Write a Review';

  @override
  String get walletReviewSubtitle => 'Open the app store listing';

  @override
  String get walletReviewUnavailable => 'Store listing unavailable';

  @override
  String get walletRefer => 'Refer a Friend';

  @override
  String get walletReferSubtitle => 'Share Creative Rewards';

  @override
  String get walletHistory => 'Points History';

  @override
  String get walletHistorySubtitle => 'Earned, spent and refunded points';

  @override
  String get transactionsTitle => 'Points History';

  @override
  String get transactionsSubtitle => 'Every change to your balance';

  @override
  String get transactionsEmpty => 'No points activity yet';

  @override
  String get txSignupBonus => 'Welcome bonus';

  @override
  String get txAdReward => 'Rewarded ad';

  @override
  String get txRedemption => 'Reward redeemed';

  @override
  String get txRefund => 'Refund';

  @override
  String get txAdminCredit => 'Points added';

  @override
  String get txAdminDebit => 'Points adjusted';

  @override
  String get txOther => 'Balance update';

  @override
  String txBalanceAfter(String points) {
    return 'Balance $points PTS';
  }

  @override
  String get earnTitle => 'Earn points';

  @override
  String get earnHeadline => 'Watch & earn';

  @override
  String earnBody(int points) {
    return 'Watch a short video to earn $points points. Points are added once the reward is confirmed.';
  }

  @override
  String earnRemaining(int count) {
    return '$count left today';
  }

  @override
  String get earnWatch => 'Watch ad';

  @override
  String get earnVerifying => 'Verifying your reward…';

  @override
  String earnCredited(String points) {
    return '+$points PTS added to your wallet';
  }

  @override
  String get earnRejected => 'This view wasn\'t rewarded.';

  @override
  String get earnExpired => 'The reward session expired. Please try again.';

  @override
  String get earnPendingLong => 'We couldn\'t confirm your reward yet. Tap Check again.';

  @override
  String get earnCheckAgain => 'Check again';

  @override
  String get earnDismissedEarly => 'Watch the full video to earn points.';

  @override
  String get earnAdFailed => 'No video is available right now. Try again later.';

  @override
  String get earnUnavailable => 'Earning with videos is coming soon';

  @override
  String get earnUnavailableBody =>
      'We\'ll let you know when you can earn points by watching videos. You can still redeem points and join giveaways.';

  @override
  String earnCooldown(String time) {
    return 'Next video available in $time';
  }

  @override
  String get earnDailyLimit => 'You\'ve reached today\'s limit. Come back tomorrow.';

  @override
  String get earnUnsupported => 'Rewarded videos are available on Android.';

  @override
  String get joinAdTitle => 'Watch an Ad to Join';

  @override
  String get joinAdBody => 'Watch a short advertisement to continue joining this giveaway.';

  @override
  String get joinAdWatch => 'Watch Ad';

  @override
  String get joinAdSkipped => 'Watch the full video to join.';

  @override
  String get joinAdFailed => 'The video couldn\'t be shown. Please try again.';

  @override
  String get referTitle => 'Refer a Friend';

  @override
  String get referHeadline => 'Invite friends to Creative Rewards';

  @override
  String get referBody =>
      'Share the app link with your friends. Referral rewards aren\'t available yet.';

  @override
  String get referCopy => 'Copy app link';

  @override
  String get referCopied => 'Link copied';

  @override
  String get profilePoints => 'Points';

  @override
  String get profileGiveaways => 'Giveaways';

  @override
  String get profileOrders => 'Orders';

  @override
  String get profileMyGiveaways => 'My Giveaways';

  @override
  String get profileMyOrders => 'My Orders';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileSettings => 'Account Settings';

  @override
  String get profileAbout => 'About';

  @override
  String get profilePrivacy => 'Privacy Policy';

  @override
  String get profileTerms => 'Terms & Conditions';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileEditTooltip => 'Edit profile';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutMessage => 'Are you sure you want to sign out of your account?';

  @override
  String get languageTitle => 'Choose Language';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileName => 'Display name';

  @override
  String get editProfileNameInvalid => 'Use 2–60 characters';

  @override
  String get editProfileSaved => 'Profile updated';

  @override
  String get settingsTitle => 'Account Settings';

  @override
  String get settingsSubtitle => 'Security and preferences';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsSessions => 'Signed-in devices';

  @override
  String get settingsNotifications => 'Notification preferences';

  @override
  String get settingsAdPrivacy => 'Ad privacy choices';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrent => 'Current password';

  @override
  String get changePasswordNew => 'New password';

  @override
  String get changePasswordDone => 'Password changed. Other devices were signed out.';

  @override
  String get sessionsTitle => 'Signed-in devices';

  @override
  String get sessionsSubtitle => 'Devices signed in to your account';

  @override
  String get sessionsCurrent => 'This device';

  @override
  String sessionsLastUsed(String date) {
    return 'Last active $date';
  }

  @override
  String get sessionsRevoke => 'Sign out';

  @override
  String get sessionsRevoked => 'Device signed out';

  @override
  String get sessionsLogoutAll => 'Sign out of all devices';

  @override
  String get sessionsLogoutAllMessage =>
      'You\'ll need to sign in again on every device, including this one.';

  @override
  String get sessionsUnknownDevice => 'Unknown device';

  @override
  String get notificationPrefsTitle => 'Notification preferences';

  @override
  String get notificationPrefsSubtitle => 'Choose what we notify you about';

  @override
  String get prefOrders => 'Order updates';

  @override
  String get prefOrdersSubtitle => 'Processing, delivery and refunds';

  @override
  String get prefGiveaways => 'Giveaway results';

  @override
  String get prefGiveawaysSubtitle => 'Winners and draw results';

  @override
  String get prefAnnouncements => 'Announcements';

  @override
  String get prefAnnouncementsSubtitle => 'New rewards and offers';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountBody =>
      'Your account is deleted after a 14-day grace period. Signing in again during that time cancels the request. Points, orders and entries are removed with the account.';

  @override
  String get deleteAccountPassword => 'Confirm with your password';

  @override
  String get deleteAccountButton => 'Delete my account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmMessage => 'This can\'t be undone after the grace period.';

  @override
  String deleteAccountDone(int days) {
    return 'Deletion requested. Your account will be removed in $days days.';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody =>
      'Creative Rewards lets you redeem points for rewards and join free giveaways.';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get termsTitle => 'Terms & Conditions';

  @override
  String get legalUnavailable => 'This document will be available soon.';

  @override
  String get legalOpen => 'Open document';

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get ordersSubtitle => 'Track and manage your orders';

  @override
  String get ordersAll => 'All';

  @override
  String get ordersInProgress => 'In progress';

  @override
  String get ordersCompleted => 'Completed';

  @override
  String get ordersUnsuccessful => 'Unsuccessful';

  @override
  String get ordersEmpty => 'No orders yet';

  @override
  String get ordersEmptyFiltered => 'No orders in this status';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get orderPending => 'Pending';

  @override
  String get orderProcessing => 'Processing';

  @override
  String get orderShipped => 'Shipped';

  @override
  String get orderDelivered => 'Delivered';

  @override
  String get orderCompleted => 'Completed';

  @override
  String get orderRejected => 'Rejected';

  @override
  String get orderCancelled => 'Cancelled';

  @override
  String get orderFailed => 'Failed';

  @override
  String get orderDetailsTitle => 'Order details';

  @override
  String get orderSubmittedDetails => 'Your details';

  @override
  String get orderDeliveredCode => 'Your code';

  @override
  String get orderTracking => 'Tracking';

  @override
  String get orderReason => 'Reason';

  @override
  String get orderTimeline => 'Status history';

  @override
  String get orderIdLabel => 'Order ID';

  @override
  String get orderCost => 'Cost';

  @override
  String get orderStatusTitle => 'Status';

  @override
  String get orderAccountDetails => 'Account details';

  @override
  String get orderStatusHistory => 'Status history';

  @override
  String get orderRedeemAgain => 'Redeem again';

  @override
  String get orderOpenLink => 'Open link';

  @override
  String get orderStepPending => 'Your order has been placed.';

  @override
  String get orderStepProcessing => 'We\'re processing your order.';

  @override
  String get orderStepShipped => 'Your order is on the way.';

  @override
  String get orderStepDelivered => 'Your order has been delivered.';

  @override
  String get orderStepCompleted => 'Your order has been completed successfully.';

  @override
  String get orderStepRejected => 'Your order was rejected.';

  @override
  String get orderStepCancelled => 'Your order was cancelled.';

  @override
  String get orderStepFailed => 'Your order couldn\'t be completed.';

  @override
  String orderRefunded(String points) {
    return '$points PTS were refunded to your wallet.';
  }

  @override
  String get orderCancel => 'Cancel order';

  @override
  String get orderCancelTitle => 'Cancel this order?';

  @override
  String get orderCancelMessage => 'Your points will be refunded to your wallet.';

  @override
  String get orderCancelDone => 'Order cancelled. Points refunded.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsMarkAll => 'Mark all as read';

  @override
  String get notifNow => 'Now';

  @override
  String notifMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String notifHours(int count) {
    return '${count}h ago';
  }

  @override
  String get notifYesterday => 'Yesterday';

  @override
  String get notifEarlier => 'Earlier';

  @override
  String get notificationOpen => 'Open';

  @override
  String get giveawaysTitle => 'Giveaways';

  @override
  String get giveawaysSubtitle => 'Join free giveaways and win prizes';

  @override
  String get giveawaysEmpty => 'No giveaways here yet';

  @override
  String get giveawayDetailsTitle => 'Giveaway Details';

  @override
  String get giveawayBadge => 'Giveaway';

  @override
  String get giveawayBadgeActive => 'Active';

  @override
  String get giveawayBadgeComingSoon => 'Coming Soon';

  @override
  String get giveawayBadgeEnded => 'Ended';

  @override
  String get giveawayBadgeFull => 'Full';

  @override
  String get giveawayAboutTitle => 'About This Giveaway';

  @override
  String giveawayOrganizer(String name) {
    return 'By $name';
  }

  @override
  String get giveawayPrize => 'Prize';

  @override
  String get giveawayRules => 'Rules';

  @override
  String get giveawaySteps => 'Steps to join';

  @override
  String get giveawayStepOptional => 'Optional';

  @override
  String get giveawayStepDone => 'Done';

  @override
  String get giveawayStepSubmitted => 'Under review';

  @override
  String get giveawayStepApproved => 'Approved';

  @override
  String get giveawayStepRejected => 'Not approved — try again';

  @override
  String get giveawayStepComplete => 'Complete';

  @override
  String get giveawayStepProofTitle => 'Submit proof';

  @override
  String get giveawayStepProofHint => 'Your username or a short note';

  @override
  String get giveawayStepSubmit => 'Submit';

  @override
  String get giveawayJoin => 'Join Giveaway';

  @override
  String get giveawayViewTicket => 'View your number';

  @override
  String get giveawayClosed => 'This giveaway has ended';

  @override
  String get giveawayFull => 'This giveaway is full';

  @override
  String get giveawayDisqualified => 'Your entry was disqualified';

  @override
  String get giveawayFreeNote => 'Entering is free. Points are never deducted.';

  @override
  String get giveawayResults => 'Winners';

  @override
  String giveawayWinnerRow(int rank, String number) {
    return '#$rank · Number $number';
  }

  @override
  String get giveawayCompleteSteps => 'Complete the required steps to join';

  @override
  String get giveawaySignInToJoin => 'Sign in to join';

  @override
  String get ticketTitle => 'Your Ticket';

  @override
  String get ticketPreparing => 'Preparing your ticket…';

  @override
  String get ticketCopy => 'Copy ticket';

  @override
  String get ticketCopied => 'Ticket number copied';

  @override
  String get ticketNote => 'Keep this number. Winners are announced after the giveaway ends.';

  @override
  String get myGiveawaysTitle => 'My Giveaways';

  @override
  String get myGiveawaysSubtitle => 'Check the giveaways you\'ve joined';

  @override
  String get myGiveawaysEmpty => 'You haven\'t joined a giveaway yet';

  @override
  String get resultAll => 'All';

  @override
  String get resultPending => 'Pending draw';

  @override
  String get resultWon => 'You won!';

  @override
  String get resultNotSelected => 'Not selected';

  @override
  String get entryDisqualified => 'Disqualified';

  @override
  String get celebrationTitle => 'Congratulations!';

  @override
  String celebrationBody(String prize) {
    return 'You won $prize';
  }

  @override
  String celebrationNumber(String number) {
    return 'Winning number $number';
  }

  @override
  String get celebrationClaim => 'Claim your prize';

  @override
  String get celebrationLater => 'Later';

  @override
  String get claimHint => 'Phone number and city, or other contact details';

  @override
  String get claimInvalid => 'Enter 3–500 characters';

  @override
  String get claimSubmit => 'Send';

  @override
  String get claimDone => 'Thanks! We\'ll contact you to deliver your prize.';

  @override
  String claimDeadline(String date) {
    return 'Claim before $date';
  }
}
