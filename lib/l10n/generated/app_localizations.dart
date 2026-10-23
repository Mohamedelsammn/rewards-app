import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Creative Rewards'**
  String get appTitle;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonCopied;

  /// No description provided for @commonLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get commonLoadMore;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. Showing the last loaded content.'**
  String get refreshFailed;

  /// No description provided for @pointsAmount.
  ///
  /// In en, this message translates to:
  /// **'{points} PTS'**
  String pointsAmount(String points);

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Onboarding step {step} of {total}'**
  String onboardingStep(int step, int total);

  /// No description provided for @errorReference.
  ///
  /// In en, this message translates to:
  /// **'Reference: {id}'**
  String errorReference(String id);

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errUnknown;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'The service is having trouble. Please try again shortly.'**
  String get errServer;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errNetwork;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Please try again.'**
  String get errTimeout;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get errInvalidCredentials;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get errSessionExpired;

  /// No description provided for @errAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account is suspended. Contact support for help.'**
  String get errAccountSuspended;

  /// No description provided for @errFeatureDisabled.
  ///
  /// In en, this message translates to:
  /// **'This feature isn\'t available right now.'**
  String get errFeatureDisabled;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get errNotFound;

  /// No description provided for @errEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account.'**
  String get errEmailTaken;

  /// No description provided for @errInsufficientPoints.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough points for this reward.'**
  String get errInsufficientPoints;

  /// No description provided for @errOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'This reward is out of stock.'**
  String get errOutOfStock;

  /// No description provided for @errPriceChanged.
  ///
  /// In en, this message translates to:
  /// **'The price of this reward has changed.'**
  String get errPriceChanged;

  /// No description provided for @errInvalidTransition.
  ///
  /// In en, this message translates to:
  /// **'This order can no longer be changed.'**
  String get errInvalidTransition;

  /// No description provided for @errRequestInProgress.
  ///
  /// In en, this message translates to:
  /// **'Your request is still being processed. Please wait.'**
  String get errRequestInProgress;

  /// No description provided for @errPreviousAttemptUncertain.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm your previous request. Check My Orders before sending again.'**
  String get errPreviousAttemptUncertain;

  /// No description provided for @errGiveawayNotStarted.
  ///
  /// In en, this message translates to:
  /// **'This giveaway hasn\'t started yet.'**
  String get errGiveawayNotStarted;

  /// No description provided for @errGiveawayEnded.
  ///
  /// In en, this message translates to:
  /// **'This giveaway has ended.'**
  String get errGiveawayEnded;

  /// No description provided for @errGiveawayNotActive.
  ///
  /// In en, this message translates to:
  /// **'This giveaway isn\'t open right now.'**
  String get errGiveawayNotActive;

  /// No description provided for @errGiveawayFull.
  ///
  /// In en, this message translates to:
  /// **'This giveaway is full.'**
  String get errGiveawayFull;

  /// No description provided for @errStepsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Complete the required steps first.'**
  String get errStepsIncomplete;

  /// No description provided for @errClaimNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This prize can no longer be claimed.'**
  String get errClaimNotAllowed;

  /// No description provided for @errValidation.
  ///
  /// In en, this message translates to:
  /// **'Check the information you entered.'**
  String get errValidation;

  /// No description provided for @errOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'The code is incorrect.'**
  String get errOtpInvalid;

  /// No description provided for @errOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code expired. Request a new one.'**
  String get errOtpExpired;

  /// No description provided for @errOtpAttemptsExceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Request a new code.'**
  String get errOtpAttemptsExceeded;

  /// No description provided for @errOtpVerificationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Your email verification expired. Please start again.'**
  String get errOtpVerificationInvalid;

  /// No description provided for @errOtpResendCooldown.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before requesting another code.'**
  String errOtpResendCooldown(int seconds);

  /// No description provided for @errOtpSendLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many codes were requested. Try again later.'**
  String get errOtpSendLimit;

  /// No description provided for @errOtpLocked.
  ///
  /// In en, this message translates to:
  /// **'Verification is temporarily locked. Try again in an hour or sign in with your password.'**
  String get errOtpLocked;

  /// No description provided for @errEmailNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Email delivery is unavailable right now. Try again later.'**
  String get errEmailNotConfigured;

  /// No description provided for @errInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is incorrect.'**
  String get errInvalidPassword;

  /// No description provided for @errInvalidAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose another character.'**
  String get errInvalidAvatar;

  /// No description provided for @errProofRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a short proof to submit this step.'**
  String get errProofRequired;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment.'**
  String get errRateLimited;

  /// No description provided for @errDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit. Come back tomorrow.'**
  String get errDailyLimit;

  /// No description provided for @errDeviceLimit.
  ///
  /// In en, this message translates to:
  /// **'This device reached today\'s limit.'**
  String get errDeviceLimit;

  /// No description provided for @errCooldown.
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds} seconds before the next ad.'**
  String errCooldown(int seconds);

  /// No description provided for @errTooManyPending.
  ///
  /// In en, this message translates to:
  /// **'You have unfinished video rewards. Try again in a few minutes.'**
  String get errTooManyPending;

  /// No description provided for @errAdSessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This reward wasn\'t found. No points were added.'**
  String get errAdSessionNotFound;

  /// No description provided for @errAdSessionNotOwned.
  ///
  /// In en, this message translates to:
  /// **'This reward belongs to another account.'**
  String get errAdSessionNotOwned;

  /// No description provided for @errAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'Your account can\'t earn rewards right now.'**
  String get errAccountInactive;

  /// No description provided for @errAdUnitNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Rewarded videos aren\'t available right now. No points were added.'**
  String get errAdUnitNotAllowed;

  /// No description provided for @errNumberAllocation.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t assign your number. Please try again.'**
  String get errNumberAllocation;

  /// No description provided for @errInvalidCursor.
  ///
  /// In en, this message translates to:
  /// **'The list changed. Pull to refresh.'**
  String get errInvalidCursor;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Play · Earn · Redeem'**
  String get splashTagline;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll be right back'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'Creative Rewards is under maintenance. Please try again soon.'**
  String get maintenanceBody;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In en, this message translates to:
  /// **'Please update Creative Rewards to keep using it.'**
  String get updateBody;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateButton;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get offlineBody;

  /// No description provided for @serviceUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Service not connected'**
  String get serviceUnavailableTitle;

  /// No description provided for @serviceUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Creative Rewards is unavailable until the service is connected.'**
  String get serviceUnavailableBody;

  /// No description provided for @serviceInsecureBody.
  ///
  /// In en, this message translates to:
  /// **'This build can\'t use an insecure connection.'**
  String get serviceInsecureBody;

  /// No description provided for @welcomeTitleTop.
  ///
  /// In en, this message translates to:
  /// **'Your Rewards'**
  String get welcomeTitleTop;

  /// No description provided for @welcomeTitleBottom.
  ///
  /// In en, this message translates to:
  /// **'Journey Starts Here'**
  String get welcomeTitleBottom;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play, earn, and redeem amazing rewards with ease.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get welcomeHaveAccount;

  /// No description provided for @welcomeLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get welcomeLogin;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authInvalidEmail;

  /// No description provided for @emailTitleStart.
  ///
  /// In en, this message translates to:
  /// **'What’s your '**
  String get emailTitleStart;

  /// No description provided for @emailTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'email?'**
  String get emailTitleAccent;

  /// No description provided for @emailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll send you a verification code to confirm your account.'**
  String get emailSubtitle;

  /// No description provided for @emailSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get emailSendCode;

  /// No description provided for @emailLoginInstead.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get emailLoginInstead;

  /// No description provided for @otpTitleStart.
  ///
  /// In en, this message translates to:
  /// **'Check your '**
  String get otpTitleStart;

  /// No description provided for @otpTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get otpTitleAccent;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We’ve sent a 6-digit code to'**
  String get otpSentTo;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String otpResendIn(String time);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code was sent.'**
  String get otpResent;

  /// No description provided for @otpEnterSix.
  ///
  /// In en, this message translates to:
  /// **'Enter six digits'**
  String get otpEnterSix;

  /// No description provided for @otpAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts left'**
  String otpAttemptsLeft(int count);

  /// No description provided for @otpSpamHint.
  ///
  /// In en, this message translates to:
  /// **'Didn’t get it? Check your spam folder, then resend after the countdown.'**
  String get otpSpamHint;

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit verification code'**
  String get otpCodeLabel;

  /// No description provided for @passwordTitleStart.
  ///
  /// In en, this message translates to:
  /// **'Create a '**
  String get passwordTitleStart;

  /// No description provided for @passwordTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get passwordTitleAccent;

  /// No description provided for @passwordResetTitleStart.
  ///
  /// In en, this message translates to:
  /// **'Reset '**
  String get passwordResetTitleStart;

  /// No description provided for @passwordResetTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get passwordResetTitleAccent;

  /// No description provided for @passwordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a secure password for your account.'**
  String get passwordSubtitle;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get passwordConfirmLabel;

  /// No description provided for @passwordRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleLettersNumbers.
  ///
  /// In en, this message translates to:
  /// **'Include letters and numbers'**
  String get passwordRuleLettersNumbers;

  /// No description provided for @passwordRuleStrong.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password'**
  String get passwordRuleStrong;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Use 10 or more characters with uppercase, lowercase, and numbers'**
  String get passwordTooWeak;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordSave.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get passwordSave;

  /// No description provided for @passwordResetDone.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in with your new password.'**
  String get passwordResetDone;

  /// No description provided for @characterTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Character'**
  String get characterTitle;

  /// No description provided for @characterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a character to represent you in the app.'**
  String get characterSubtitle;

  /// No description provided for @characterOption.
  ///
  /// In en, this message translates to:
  /// **'Character {number}'**
  String characterOption(int number);

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your rewards journey.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgot;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginBusy.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginBusy;

  /// No description provided for @loginInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email and password'**
  String get loginInvalidInput;

  /// No description provided for @loginEnterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first'**
  String get loginEnterEmailFirst;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get loginCreateAccount;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @homeYourPoints.
  ///
  /// In en, this message translates to:
  /// **'Your Points'**
  String get homeYourPoints;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search rewards, giveaways...'**
  String get homeSearchHint;

  /// No description provided for @homeAvailableRewards.
  ///
  /// In en, this message translates to:
  /// **'Available Rewards'**
  String get homeAvailableRewards;

  /// No description provided for @homeFeaturedRewards.
  ///
  /// In en, this message translates to:
  /// **'Featured Rewards'**
  String get homeFeaturedRewards;

  /// No description provided for @homeGiveaways.
  ///
  /// In en, this message translates to:
  /// **'Giveaways'**
  String get homeGiveaways;

  /// No description provided for @homeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No rewards found'**
  String get homeNoResults;

  /// No description provided for @homeNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or check the spelling.'**
  String get homeNoResultsBody;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'New rewards are on the way. Check back soon.'**
  String get homeEmpty;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards are on the way'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re preparing new rewards and giveaways for you. Pull down to refresh or check back soon.'**
  String get homeEmptyBody;

  /// No description provided for @homeClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get homeClearSearch;

  /// No description provided for @giveawayAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get giveawayAvailable;

  /// No description provided for @giveawayUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get giveawayUpcoming;

  /// No description provided for @giveawayEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get giveawayEnded;

  /// No description provided for @giveawayWinnersSelected.
  ///
  /// In en, this message translates to:
  /// **'Winners announced'**
  String get giveawayWinnersSelected;

  /// No description provided for @giveawayCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get giveawayCancelled;

  /// No description provided for @giveawayEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String giveawayEndsOn(String date);

  /// No description provided for @giveawayStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String giveawayStartsOn(String date);

  /// No description provided for @giveawayParticipants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No participants yet} =1{1 participant} other{{count} participants}}'**
  String giveawayParticipants(int count);

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Check back soon.'**
  String get categoriesEmpty;

  /// No description provided for @categoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoriesEmptyTitle;

  /// No description provided for @categoriesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Reward categories will appear here as soon as they\'re added.'**
  String get categoriesEmptyBody;

  /// No description provided for @categoryProductsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rewards in this category yet.'**
  String get categoryProductsEmpty;

  /// No description provided for @productTabTopUps.
  ///
  /// In en, this message translates to:
  /// **'UC Top-Ups'**
  String get productTabTopUps;

  /// No description provided for @productTabItemsSkins.
  ///
  /// In en, this message translates to:
  /// **'Items & Skins'**
  String get productTabItemsSkins;

  /// No description provided for @productTopUpsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No top-ups available yet.'**
  String get productTopUpsEmpty;

  /// No description provided for @productItemsSkinsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items or skins available yet.'**
  String get productItemsSkinsEmpty;

  /// No description provided for @productRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get productRedeem;

  /// No description provided for @productOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get productOutOfStock;

  /// No description provided for @redeemTitle.
  ///
  /// In en, this message translates to:
  /// **'Redemption details'**
  String get redeemTitle;

  /// No description provided for @redeemBalanceLine.
  ///
  /// In en, this message translates to:
  /// **'Balance: {balance} PTS  •  After: {after} PTS'**
  String redeemBalanceLine(String balance, String after);

  /// No description provided for @redeemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm redemption'**
  String get redeemConfirm;

  /// No description provided for @redeemReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your details'**
  String get redeemReviewTitle;

  /// No description provided for @redeemReviewBody.
  ///
  /// In en, this message translates to:
  /// **'{product} for {points} will be sent to:'**
  String redeemReviewBody(String product, String points);

  /// No description provided for @redeemReviewEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get redeemReviewEdit;

  /// No description provided for @redeemAccountDetailsMissing.
  ///
  /// In en, this message translates to:
  /// **'This reward can\'t be redeemed yet: its account details aren\'t set up. Please try again later.'**
  String get redeemAccountDetailsMissing;

  /// No description provided for @redeemFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get redeemFieldRequired;

  /// No description provided for @redeemFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the {label} format'**
  String redeemFieldInvalid(String label);

  /// No description provided for @redeemInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Use digits only'**
  String get redeemInvalidNumber;

  /// No description provided for @redeemInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL'**
  String get redeemInvalidUrl;

  /// No description provided for @redeemInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get redeemInvalidPhone;

  /// No description provided for @redeemInvalidOption.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the options'**
  String get redeemInvalidOption;

  /// No description provided for @redeemSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an option'**
  String get redeemSelectHint;

  /// No description provided for @redeemPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'We will never ask for your passwords or verification codes.'**
  String get redeemPrivacyNote;

  /// No description provided for @redeemPointsNote.
  ///
  /// In en, this message translates to:
  /// **'Points are deducted when you confirm and refunded if the order can\'t be completed.'**
  String get redeemPointsNote;

  /// No description provided for @redeemSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get redeemSuccessTitle;

  /// No description provided for @redeemSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'{points} PTS were deducted. Track your order in My Orders.'**
  String redeemSuccessBody(String points);

  /// No description provided for @redeemViewOrders.
  ///
  /// In en, this message translates to:
  /// **'View my orders'**
  String get redeemViewOrders;

  /// No description provided for @redeemInsufficientTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough points'**
  String get redeemInsufficientTitle;

  /// No description provided for @redeemInsufficientTitleCaps.
  ///
  /// In en, this message translates to:
  /// **'Not Enough Points'**
  String get redeemInsufficientTitleCaps;

  /// No description provided for @redeemInsufficientBody.
  ///
  /// In en, this message translates to:
  /// **'You have {balance} PTS. This reward needs {required} PTS.'**
  String redeemInsufficientBody(String balance, String required);

  /// No description provided for @redeemInsufficientMessage.
  ///
  /// In en, this message translates to:
  /// **'You need more points to redeem this reward.'**
  String get redeemInsufficientMessage;

  /// No description provided for @redeemYourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get redeemYourBalance;

  /// No description provided for @redeemRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get redeemRequired;

  /// No description provided for @redeemMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get redeemMissing;

  /// No description provided for @redeemEarnPoints.
  ///
  /// In en, this message translates to:
  /// **'Earn points'**
  String get redeemEarnPoints;

  /// No description provided for @redeemPriceChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Price changed'**
  String get redeemPriceChangedTitle;

  /// No description provided for @redeemPriceChangedBody.
  ///
  /// In en, this message translates to:
  /// **'This reward now costs {points} PTS. Do you want to continue?'**
  String redeemPriceChangedBody(String points);

  /// No description provided for @redeemConfirmNewPrice.
  ///
  /// In en, this message translates to:
  /// **'Redeem for {points} PTS'**
  String redeemConfirmNewPrice(String points);

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Rewards'**
  String get walletTitle;

  /// No description provided for @walletPoints.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get walletPoints;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get walletBalance;

  /// No description provided for @walletFastEarn.
  ///
  /// In en, this message translates to:
  /// **'Fast, Earn'**
  String get walletFastEarn;

  /// No description provided for @walletPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place an Order'**
  String get walletPlaceOrder;

  /// No description provided for @walletPlaceOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse rewards to redeem'**
  String get walletPlaceOrderSubtitle;

  /// No description provided for @walletReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get walletReview;

  /// No description provided for @walletReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the app store listing'**
  String get walletReviewSubtitle;

  /// No description provided for @walletReviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store listing unavailable'**
  String get walletReviewUnavailable;

  /// No description provided for @walletRefer.
  ///
  /// In en, this message translates to:
  /// **'Refer a Friend'**
  String get walletRefer;

  /// No description provided for @walletReferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share Creative Rewards'**
  String get walletReferSubtitle;

  /// No description provided for @walletHistory.
  ///
  /// In en, this message translates to:
  /// **'Points History'**
  String get walletHistory;

  /// No description provided for @walletHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earned, spent and refunded points'**
  String get walletHistorySubtitle;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Points History'**
  String get transactionsTitle;

  /// No description provided for @transactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every change to your balance'**
  String get transactionsSubtitle;

  /// No description provided for @transactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No points activity yet'**
  String get transactionsEmpty;

  /// No description provided for @txSignupBonus.
  ///
  /// In en, this message translates to:
  /// **'Welcome bonus'**
  String get txSignupBonus;

  /// No description provided for @txAdReward.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad'**
  String get txAdReward;

  /// No description provided for @txRedemption.
  ///
  /// In en, this message translates to:
  /// **'Reward redeemed'**
  String get txRedemption;

  /// No description provided for @txRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get txRefund;

  /// No description provided for @txAdminCredit.
  ///
  /// In en, this message translates to:
  /// **'Points added'**
  String get txAdminCredit;

  /// No description provided for @txAdminDebit.
  ///
  /// In en, this message translates to:
  /// **'Points adjusted'**
  String get txAdminDebit;

  /// No description provided for @txOther.
  ///
  /// In en, this message translates to:
  /// **'Balance update'**
  String get txOther;

  /// No description provided for @txBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance {points} PTS'**
  String txBalanceAfter(String points);

  /// No description provided for @earnTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn points'**
  String get earnTitle;

  /// No description provided for @earnHeadline.
  ///
  /// In en, this message translates to:
  /// **'Watch & earn'**
  String get earnHeadline;

  /// No description provided for @earnBody.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video to earn {points} points. Points are added once the reward is confirmed.'**
  String earnBody(int points);

  /// No description provided for @earnRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} left today'**
  String earnRemaining(int count);

  /// No description provided for @earnWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get earnWatch;

  /// No description provided for @earnVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying your reward…'**
  String get earnVerifying;

  /// No description provided for @earnCredited.
  ///
  /// In en, this message translates to:
  /// **'+{points} PTS added to your wallet'**
  String earnCredited(String points);

  /// No description provided for @earnRejected.
  ///
  /// In en, this message translates to:
  /// **'This view wasn\'t rewarded.'**
  String get earnRejected;

  /// No description provided for @earnExpired.
  ///
  /// In en, this message translates to:
  /// **'The reward session expired. Please try again.'**
  String get earnExpired;

  /// No description provided for @earnPendingLong.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm your reward yet. Tap Check again.'**
  String get earnPendingLong;

  /// No description provided for @earnCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get earnCheckAgain;

  /// No description provided for @earnDismissedEarly.
  ///
  /// In en, this message translates to:
  /// **'Watch the full video to earn points.'**
  String get earnDismissedEarly;

  /// No description provided for @earnAdFailed.
  ///
  /// In en, this message translates to:
  /// **'No video is available right now. Try again later.'**
  String get earnAdFailed;

  /// No description provided for @earnUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Earning with videos is coming soon'**
  String get earnUnavailable;

  /// No description provided for @earnUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when you can earn points by watching videos. You can still redeem points and join giveaways.'**
  String get earnUnavailableBody;

  /// No description provided for @earnCooldown.
  ///
  /// In en, this message translates to:
  /// **'Next video available in {time}'**
  String earnCooldown(String time);

  /// No description provided for @earnDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit. Come back tomorrow.'**
  String get earnDailyLimit;

  /// No description provided for @earnUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Rewarded videos are available on Android.'**
  String get earnUnsupported;

  /// No description provided for @joinAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch an Ad to Join'**
  String get joinAdTitle;

  /// No description provided for @joinAdBody.
  ///
  /// In en, this message translates to:
  /// **'Watch a short advertisement to continue joining this giveaway.'**
  String get joinAdBody;

  /// No description provided for @joinAdWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get joinAdWatch;

  /// No description provided for @joinAdSkipped.
  ///
  /// In en, this message translates to:
  /// **'Watch the full video to join.'**
  String get joinAdSkipped;

  /// No description provided for @joinAdFailed.
  ///
  /// In en, this message translates to:
  /// **'The video couldn\'t be shown. Please try again.'**
  String get joinAdFailed;

  /// No description provided for @referTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer a Friend'**
  String get referTitle;

  /// No description provided for @referHeadline.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to Creative Rewards'**
  String get referHeadline;

  /// No description provided for @referBody.
  ///
  /// In en, this message translates to:
  /// **'Share the app link with your friends. Referral rewards aren\'t available yet.'**
  String get referBody;

  /// No description provided for @referCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy app link'**
  String get referCopy;

  /// No description provided for @referCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get referCopied;

  /// No description provided for @profilePoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get profilePoints;

  /// No description provided for @profileGiveaways.
  ///
  /// In en, this message translates to:
  /// **'Giveaways'**
  String get profileGiveaways;

  /// No description provided for @profileOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get profileOrders;

  /// No description provided for @profileMyGiveaways.
  ///
  /// In en, this message translates to:
  /// **'My Giveaways'**
  String get profileMyGiveaways;

  /// No description provided for @profileMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get profileMyOrders;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get profileSettings;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacy;

  /// No description provided for @profileTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get profileTerms;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTooltip;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get signOutMessage;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get languageTitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get editProfileName;

  /// No description provided for @editProfileNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 2–60 characters'**
  String get editProfileNameInvalid;

  /// No description provided for @editProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get editProfileSaved;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Security and preferences'**
  String get settingsSubtitle;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsSessions.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get settingsSessions;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get settingsNotifications;

  /// No description provided for @settingsAdPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy choices'**
  String get settingsAdPrivacy;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNew;

  /// No description provided for @changePasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Other devices were signed out.'**
  String get changePasswordDone;

  /// No description provided for @sessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get sessionsTitle;

  /// No description provided for @sessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Devices signed in to your account'**
  String get sessionsSubtitle;

  /// No description provided for @sessionsCurrent.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get sessionsCurrent;

  /// No description provided for @sessionsLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last active {date}'**
  String sessionsLastUsed(String date);

  /// No description provided for @sessionsRevoke.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get sessionsRevoke;

  /// No description provided for @sessionsRevoked.
  ///
  /// In en, this message translates to:
  /// **'Device signed out'**
  String get sessionsRevoked;

  /// No description provided for @sessionsLogoutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices'**
  String get sessionsLogoutAll;

  /// No description provided for @sessionsLogoutAllMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again on every device, including this one.'**
  String get sessionsLogoutAllMessage;

  /// No description provided for @sessionsUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get sessionsUnknownDevice;

  /// No description provided for @notificationPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPrefsTitle;

  /// No description provided for @notificationPrefsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what we notify you about'**
  String get notificationPrefsSubtitle;

  /// No description provided for @prefOrders.
  ///
  /// In en, this message translates to:
  /// **'Order updates'**
  String get prefOrders;

  /// No description provided for @prefOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Processing, delivery and refunds'**
  String get prefOrdersSubtitle;

  /// No description provided for @prefGiveaways.
  ///
  /// In en, this message translates to:
  /// **'Giveaway results'**
  String get prefGiveaways;

  /// No description provided for @prefGiveawaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Winners and draw results'**
  String get prefGiveawaysSubtitle;

  /// No description provided for @prefAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get prefAnnouncements;

  /// No description provided for @prefAnnouncementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New rewards and offers'**
  String get prefAnnouncementsSubtitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is deleted after a 14-day grace period. Signing in again during that time cancels the request. Points, orders and entries are removed with the account.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your password'**
  String get deleteAccountPassword;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone after the grace period.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Deletion requested. Your account will be removed in {days} days.'**
  String deleteAccountDone(int days);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Creative Rewards lets you redeem points for rewards and join free giveaways.'**
  String get aboutBody;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsTitle;

  /// No description provided for @legalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This document will be available soon.'**
  String get legalUnavailable;

  /// No description provided for @legalOpen.
  ///
  /// In en, this message translates to:
  /// **'Open document'**
  String get legalOpen;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get ordersTitle;

  /// No description provided for @ordersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track and manage your orders'**
  String get ordersSubtitle;

  /// No description provided for @ordersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersAll;

  /// No description provided for @ordersInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get ordersInProgress;

  /// No description provided for @ordersCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersCompleted;

  /// No description provided for @ordersUnsuccessful.
  ///
  /// In en, this message translates to:
  /// **'Unsuccessful'**
  String get ordersUnsuccessful;

  /// No description provided for @ordersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmpty;

  /// No description provided for @ordersEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No orders in this status'**
  String get ordersEmptyFiltered;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(String number);

  /// No description provided for @orderPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderPending;

  /// No description provided for @orderProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get orderProcessing;

  /// No description provided for @orderShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderShipped;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderDelivered;

  /// No description provided for @orderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderCompleted;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get orderRejected;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderCancelled;

  /// No description provided for @orderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get orderFailed;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetailsTitle;

  /// No description provided for @orderSubmittedDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get orderSubmittedDetails;

  /// No description provided for @orderDeliveredCode.
  ///
  /// In en, this message translates to:
  /// **'Your code'**
  String get orderDeliveredCode;

  /// No description provided for @orderTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get orderTracking;

  /// No description provided for @orderReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get orderReason;

  /// No description provided for @orderTimeline.
  ///
  /// In en, this message translates to:
  /// **'Status history'**
  String get orderTimeline;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderIdLabel;

  /// No description provided for @orderCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get orderCost;

  /// No description provided for @orderStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatusTitle;

  /// No description provided for @orderAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get orderAccountDetails;

  /// No description provided for @orderStatusHistory.
  ///
  /// In en, this message translates to:
  /// **'Status history'**
  String get orderStatusHistory;

  /// No description provided for @orderRedeemAgain.
  ///
  /// In en, this message translates to:
  /// **'Redeem again'**
  String get orderRedeemAgain;

  /// No description provided for @orderOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get orderOpenLink;

  /// No description provided for @orderStepPending.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed.'**
  String get orderStepPending;

  /// No description provided for @orderStepProcessing.
  ///
  /// In en, this message translates to:
  /// **'We\'re processing your order.'**
  String get orderStepProcessing;

  /// No description provided for @orderStepShipped.
  ///
  /// In en, this message translates to:
  /// **'Your order is on the way.'**
  String get orderStepShipped;

  /// No description provided for @orderStepDelivered.
  ///
  /// In en, this message translates to:
  /// **'Your order has been delivered.'**
  String get orderStepDelivered;

  /// No description provided for @orderStepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your order has been completed successfully.'**
  String get orderStepCompleted;

  /// No description provided for @orderStepRejected.
  ///
  /// In en, this message translates to:
  /// **'Your order was rejected.'**
  String get orderStepRejected;

  /// No description provided for @orderStepCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your order was cancelled.'**
  String get orderStepCancelled;

  /// No description provided for @orderStepFailed.
  ///
  /// In en, this message translates to:
  /// **'Your order couldn\'t be completed.'**
  String get orderStepFailed;

  /// No description provided for @orderRefunded.
  ///
  /// In en, this message translates to:
  /// **'{points} PTS were refunded to your wallet.'**
  String orderRefunded(String points);

  /// No description provided for @orderCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get orderCancel;

  /// No description provided for @orderCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get orderCancelTitle;

  /// No description provided for @orderCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'Your points will be refunded to your wallet.'**
  String get orderCancelMessage;

  /// No description provided for @orderCancelDone.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled. Points refunded.'**
  String get orderCancelDone;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAll;

  /// No description provided for @notifNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get notifNow;

  /// No description provided for @notifMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String notifMinutes(int count);

  /// No description provided for @notifHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String notifHours(int count);

  /// No description provided for @notifYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notifYesterday;

  /// No description provided for @notifEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notifEarlier;

  /// No description provided for @notificationOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationOpen;

  /// No description provided for @giveawaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Giveaways'**
  String get giveawaysTitle;

  /// No description provided for @giveawaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join free giveaways and win prizes'**
  String get giveawaysSubtitle;

  /// No description provided for @giveawaysEmpty.
  ///
  /// In en, this message translates to:
  /// **'No giveaways here yet'**
  String get giveawaysEmpty;

  /// No description provided for @giveawayDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Giveaway Details'**
  String get giveawayDetailsTitle;

  /// No description provided for @giveawayBadge.
  ///
  /// In en, this message translates to:
  /// **'Giveaway'**
  String get giveawayBadge;

  /// No description provided for @giveawayBadgeActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get giveawayBadgeActive;

  /// No description provided for @giveawayBadgeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get giveawayBadgeComingSoon;

  /// No description provided for @giveawayBadgeEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get giveawayBadgeEnded;

  /// No description provided for @giveawayBadgeFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get giveawayBadgeFull;

  /// No description provided for @giveawayAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About This Giveaway'**
  String get giveawayAboutTitle;

  /// No description provided for @giveawayOrganizer.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String giveawayOrganizer(String name);

  /// No description provided for @giveawayPrize.
  ///
  /// In en, this message translates to:
  /// **'Prize'**
  String get giveawayPrize;

  /// No description provided for @giveawayRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get giveawayRules;

  /// No description provided for @giveawaySteps.
  ///
  /// In en, this message translates to:
  /// **'Steps to join'**
  String get giveawaySteps;

  /// No description provided for @giveawayStepOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get giveawayStepOptional;

  /// No description provided for @giveawayStepDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get giveawayStepDone;

  /// No description provided for @giveawayStepSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get giveawayStepSubmitted;

  /// No description provided for @giveawayStepApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get giveawayStepApproved;

  /// No description provided for @giveawayStepRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved — try again'**
  String get giveawayStepRejected;

  /// No description provided for @giveawayStepComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get giveawayStepComplete;

  /// No description provided for @giveawayStepProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit proof'**
  String get giveawayStepProofTitle;

  /// No description provided for @giveawayStepProofHint.
  ///
  /// In en, this message translates to:
  /// **'Your username or a short note'**
  String get giveawayStepProofHint;

  /// No description provided for @giveawayStepSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get giveawayStepSubmit;

  /// No description provided for @giveawayJoin.
  ///
  /// In en, this message translates to:
  /// **'Join Giveaway'**
  String get giveawayJoin;

  /// No description provided for @giveawayViewTicket.
  ///
  /// In en, this message translates to:
  /// **'View your number'**
  String get giveawayViewTicket;

  /// No description provided for @giveawayClosed.
  ///
  /// In en, this message translates to:
  /// **'This giveaway has ended'**
  String get giveawayClosed;

  /// No description provided for @giveawayFull.
  ///
  /// In en, this message translates to:
  /// **'This giveaway is full'**
  String get giveawayFull;

  /// No description provided for @giveawayDisqualified.
  ///
  /// In en, this message translates to:
  /// **'Your entry was disqualified'**
  String get giveawayDisqualified;

  /// No description provided for @giveawayFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Entering is free. Points are never deducted.'**
  String get giveawayFreeNote;

  /// No description provided for @giveawayResults.
  ///
  /// In en, this message translates to:
  /// **'Winners'**
  String get giveawayResults;

  /// No description provided for @giveawayWinnerRow.
  ///
  /// In en, this message translates to:
  /// **'#{rank} · Number {number}'**
  String giveawayWinnerRow(int rank, String number);

  /// No description provided for @giveawayCompleteSteps.
  ///
  /// In en, this message translates to:
  /// **'Complete the required steps to join'**
  String get giveawayCompleteSteps;

  /// No description provided for @giveawaySignInToJoin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join'**
  String get giveawaySignInToJoin;

  /// No description provided for @ticketTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Ticket'**
  String get ticketTitle;

  /// No description provided for @ticketPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your ticket…'**
  String get ticketPreparing;

  /// No description provided for @ticketCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy ticket'**
  String get ticketCopy;

  /// No description provided for @ticketCopied.
  ///
  /// In en, this message translates to:
  /// **'Ticket number copied'**
  String get ticketCopied;

  /// No description provided for @ticketNote.
  ///
  /// In en, this message translates to:
  /// **'Keep this number. Winners are announced after the giveaway ends.'**
  String get ticketNote;

  /// No description provided for @myGiveawaysTitle.
  ///
  /// In en, this message translates to:
  /// **'My Giveaways'**
  String get myGiveawaysTitle;

  /// No description provided for @myGiveawaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the giveaways you\'ve joined'**
  String get myGiveawaysSubtitle;

  /// No description provided for @myGiveawaysEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined a giveaway yet'**
  String get myGiveawaysEmpty;

  /// No description provided for @resultAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get resultAll;

  /// No description provided for @resultPending.
  ///
  /// In en, this message translates to:
  /// **'Pending draw'**
  String get resultPending;

  /// No description provided for @resultWon.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get resultWon;

  /// No description provided for @resultNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get resultNotSelected;

  /// No description provided for @entryDisqualified.
  ///
  /// In en, this message translates to:
  /// **'Disqualified'**
  String get entryDisqualified;

  /// No description provided for @celebrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get celebrationTitle;

  /// No description provided for @celebrationBody.
  ///
  /// In en, this message translates to:
  /// **'You won {prize}'**
  String celebrationBody(String prize);

  /// No description provided for @celebrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Winning number {number}'**
  String celebrationNumber(String number);

  /// No description provided for @celebrationClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim your prize'**
  String get celebrationClaim;

  /// No description provided for @celebrationLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get celebrationLater;

  /// No description provided for @claimHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number and city, or other contact details'**
  String get claimHint;

  /// No description provided for @claimInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 3–500 characters'**
  String get claimInvalid;

  /// No description provided for @claimSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get claimSubmit;

  /// No description provided for @claimDone.
  ///
  /// In en, this message translates to:
  /// **'Thanks! We\'ll contact you to deliver your prize.'**
  String get claimDone;

  /// No description provided for @claimDeadline.
  ///
  /// In en, this message translates to:
  /// **'Claim before {date}'**
  String claimDeadline(String date);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
