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

  /// App name shown on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Reward Giveaway'**
  String get appName;

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

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonSomethingWrong;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @roleSelectionWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome 👋'**
  String get roleSelectionWelcome;

  /// No description provided for @roleSelectionChooseHow.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to continue.'**
  String get roleSelectionChooseHow;

  /// No description provided for @roleSelectionContinueAsUser.
  ///
  /// In en, this message translates to:
  /// **'Continue as User'**
  String get roleSelectionContinueAsUser;

  /// No description provided for @roleSelectionContinueAsUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join exciting giveaways and win amazing prizes.'**
  String get roleSelectionContinueAsUserSubtitle;

  /// No description provided for @roleSelectionContinueAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Continue as Admin'**
  String get roleSelectionContinueAsAdmin;

  /// No description provided for @roleSelectionContinueAsAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage giveaway campaigns.'**
  String get roleSelectionContinueAsAdminSubtitle;

  /// No description provided for @roleSelectionSwitchAnytime.
  ///
  /// In en, this message translates to:
  /// **'YOU CAN SWITCH YOUR ROLE ANYTIME.'**
  String get roleSelectionSwitchAnytime;

  /// No description provided for @userHomeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back 👋'**
  String get userHomeWelcomeBack;

  /// No description provided for @userHomeGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get userHomeGuest;

  /// No description provided for @userHomeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search giveaways…'**
  String get userHomeSearchHint;

  /// No description provided for @userHomePopularGiveaways.
  ///
  /// In en, this message translates to:
  /// **'Popular Giveaways'**
  String get userHomePopularGiveaways;

  /// No description provided for @userHomeAllGiveaways.
  ///
  /// In en, this message translates to:
  /// **'All Giveaways'**
  String get userHomeAllGiveaways;

  /// No description provided for @userHomeFeaturedGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Featured Giveaway'**
  String get userHomeFeaturedGiveaway;

  /// No description provided for @userHomeJoinedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} joined'**
  String userHomeJoinedCount(int count);

  /// No description provided for @userHomeViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get userHomeViewDetails;

  /// No description provided for @userHomeNoActiveGiveaways.
  ///
  /// In en, this message translates to:
  /// **'No active giveaways right now'**
  String get userHomeNoActiveGiveaways;

  /// No description provided for @userHomeCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load giveaways.'**
  String get userHomeCouldNotLoad;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @giveawayDetailsAboutPrize.
  ///
  /// In en, this message translates to:
  /// **'About this prize'**
  String get giveawayDetailsAboutPrize;

  /// No description provided for @giveawayDetailsHowToParticipate.
  ///
  /// In en, this message translates to:
  /// **'How to Participate'**
  String get giveawayDetailsHowToParticipate;

  /// No description provided for @giveawayDetailsRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get giveawayDetailsRules;

  /// No description provided for @giveawayDetailsGenerateNumber.
  ///
  /// In en, this message translates to:
  /// **'Generate My Number'**
  String get giveawayDetailsGenerateNumber;

  /// No description provided for @giveawayDetailsNotActive.
  ///
  /// In en, this message translates to:
  /// **'Giveaway Not Active'**
  String get giveawayDetailsNotActive;

  /// No description provided for @giveawayDetailsYoureIn.
  ///
  /// In en, this message translates to:
  /// **'You\'re in!'**
  String get giveawayDetailsYoureIn;

  /// No description provided for @giveawayDetailsYoureInWithNumber.
  ///
  /// In en, this message translates to:
  /// **'You\'re in! #{number}'**
  String giveawayDetailsYoureInWithNumber(String number);

  /// No description provided for @giveawayDetailsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this giveaway.'**
  String get giveawayDetailsCouldNotLoad;

  /// No description provided for @giveawayDetailsEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get giveawayDetailsEnded;

  /// No description provided for @giveawayDetailsHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours} h left'**
  String giveawayDetailsHoursLeft(int hours);

  /// No description provided for @giveawayDetailsDaysHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} d {hours} h left'**
  String giveawayDetailsDaysHoursLeft(int days, int hours);

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get registrationTitle;

  /// No description provided for @registrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your information to start participating.'**
  String get registrationSubtitle;

  /// No description provided for @registrationFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get registrationFullNameLabel;

  /// No description provided for @registrationFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Jane Doe'**
  String get registrationFullNameHint;

  /// No description provided for @registrationFullNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get registrationFullNameError;

  /// No description provided for @registrationCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'COUNTRY'**
  String get registrationCountryLabel;

  /// No description provided for @registrationPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get registrationPhoneLabel;

  /// No description provided for @registrationPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'(555) 000-0000'**
  String get registrationPhoneHint;

  /// No description provided for @registrationPhoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get registrationPhoneRequiredError;

  /// No description provided for @registrationPhoneInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get registrationPhoneInvalidError;

  /// No description provided for @registrationContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get registrationContinue;

  /// No description provided for @registrationAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Privacy Policy and Terms.'**
  String get registrationAgreeTerms;

  /// No description provided for @participationJoinGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Join Giveaway'**
  String get participationJoinGiveaway;

  /// No description provided for @participationGeneratingNumber.
  ///
  /// In en, this message translates to:
  /// **'Generating your number…'**
  String get participationGeneratingNumber;

  /// No description provided for @participationSuccessOpening.
  ///
  /// In en, this message translates to:
  /// **'Success! Revealing your code…'**
  String get participationSuccessOpening;

  /// No description provided for @participationTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get participationTryAgain;

  /// No description provided for @numberRevealTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Participation Code'**
  String get numberRevealTitle;

  /// No description provided for @numberRevealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generated just for you'**
  String get numberRevealSubtitle;

  /// No description provided for @numberRevealViewInMyGiveaways.
  ///
  /// In en, this message translates to:
  /// **'View in My Giveaways'**
  String get numberRevealViewInMyGiveaways;

  /// No description provided for @myGiveawaysTitle.
  ///
  /// In en, this message translates to:
  /// **'My Giveaways'**
  String get myGiveawaysTitle;

  /// No description provided for @myGiveawaysEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any giveaways yet'**
  String get myGiveawaysEmpty;

  /// No description provided for @myGiveawaysCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your giveaways.'**
  String get myGiveawaysCouldNotLoad;

  /// No description provided for @myGiveawaysGiveawayFallback.
  ///
  /// In en, this message translates to:
  /// **'Giveaway'**
  String get myGiveawaysGiveawayFallback;

  /// No description provided for @myGiveawaysWinner.
  ///
  /// In en, this message translates to:
  /// **'You Won This Giveaway!'**
  String get myGiveawaysWinner;

  /// No description provided for @myGiveawaysNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected as the winner this time'**
  String get myGiveawaysNotSelected;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up — no notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notifications.'**
  String get notificationsCouldNotLoad;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get settingsTermsConditions;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll return to the role selection screen. Your saved giveaways and history stay on this device.'**
  String get settingsSignOutConfirmBody;

  /// No description provided for @settingsAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Reward Giveaway lets you join and manage exciting prize giveaways. Built with Flutter and Supabase.'**
  String get settingsAboutBody;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionInformation.
  ///
  /// In en, this message translates to:
  /// **'INFORMATION'**
  String get settingsSectionInformation;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settingsSectionAccount;

  /// No description provided for @settingsGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join a giveaway to create your profile'**
  String get settingsGuestSubtitle;

  /// No description provided for @adminAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminAuthTitle;

  /// No description provided for @adminAuthCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Admin Account'**
  String get adminAuthCreateAccount;

  /// No description provided for @adminAuthSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Sign In'**
  String get adminAuthSignInTitle;

  /// No description provided for @adminAuthSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register a new admin account to manage giveaway campaigns.'**
  String get adminAuthSignUpSubtitle;

  /// No description provided for @adminAuthSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage giveaway campaigns.'**
  String get adminAuthSignInSubtitle;

  /// No description provided for @adminAuthSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get adminAuthSignIn;

  /// No description provided for @adminAuthSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get adminAuthSignUp;

  /// No description provided for @adminAuthFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get adminAuthFullNameLabel;

  /// No description provided for @adminAuthFullNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get adminAuthFullNameError;

  /// No description provided for @adminAuthFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get adminAuthFullNameHint;

  /// No description provided for @adminAuthEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get adminAuthEmailLabel;

  /// No description provided for @adminAuthEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get adminAuthEmailError;

  /// No description provided for @adminAuthEmailHint.
  ///
  /// In en, this message translates to:
  /// **'example@gmail.com'**
  String get adminAuthEmailHint;

  /// No description provided for @adminAuthPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get adminAuthPasswordLabel;

  /// No description provided for @adminAuthPasswordEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get adminAuthPasswordEmptyError;

  /// No description provided for @adminAuthPasswordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get adminAuthPasswordLengthError;

  /// No description provided for @adminAuthPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get adminAuthPasswordHint;

  /// No description provided for @adminAuthPasswordRequirementHelper.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get adminAuthPasswordRequirementHelper;

  /// No description provided for @adminAuthConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get adminAuthConfirmPasswordLabel;

  /// No description provided for @adminAuthPasswordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get adminAuthPasswordsNoMatch;

  /// No description provided for @adminAuthAccessCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'ADMIN ACCESS CODE'**
  String get adminAuthAccessCodeLabel;

  /// No description provided for @adminAuthAccessCodeError.
  ///
  /// In en, this message translates to:
  /// **'Enter your admin access code'**
  String get adminAuthAccessCodeError;

  /// No description provided for @adminAuthAccessCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the access code provided to you'**
  String get adminAuthAccessCodeHint;

  /// No description provided for @adminAuthCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get adminAuthCreateAccountButton;

  /// No description provided for @adminAuthSignInButton.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get adminAuthSignInButton;

  /// No description provided for @adminAuthNoAccessCodeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an Admin Access Code?'**
  String get adminAuthNoAccessCodeQuestion;

  /// No description provided for @adminAuthContactWhatsAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us on WhatsApp to request access.'**
  String get adminAuthContactWhatsAppSubtitle;

  /// No description provided for @adminAuthWhatsAppPrefilledMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, I would like to join your giveaways. I need an Admin Access Code to create an admin account.'**
  String get adminAuthWhatsAppPrefilledMessage;

  /// No description provided for @adminAuthWhatsAppOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Please try again.'**
  String get adminAuthWhatsAppOpenFailed;

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @adminDashboardGoodDay.
  ///
  /// In en, this message translates to:
  /// **'Good day 👋'**
  String get adminDashboardGoodDay;

  /// No description provided for @adminDashboardAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminDashboardAdministrator;

  /// No description provided for @adminDashboardActiveGiveaways.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE GIVEAWAYS'**
  String get adminDashboardActiveGiveaways;

  /// No description provided for @adminDashboardTotalParticipants.
  ///
  /// In en, this message translates to:
  /// **'TOTAL PARTICIPANTS'**
  String get adminDashboardTotalParticipants;

  /// No description provided for @adminDashboardFinished.
  ///
  /// In en, this message translates to:
  /// **'FINISHED'**
  String get adminDashboardFinished;

  /// No description provided for @adminDashboardWinnersSelected.
  ///
  /// In en, this message translates to:
  /// **'WINNERS SELECTED'**
  String get adminDashboardWinnersSelected;

  /// No description provided for @adminDashboardActiveCampaign.
  ///
  /// In en, this message translates to:
  /// **'Active Campaigns'**
  String get adminDashboardActiveCampaign;

  /// No description provided for @adminDashboardNoActiveCampaigns.
  ///
  /// In en, this message translates to:
  /// **'No active campaigns yet. Tap + to create one.'**
  String get adminDashboardNoActiveCampaigns;

  /// No description provided for @adminDashboardEndedCampaign.
  ///
  /// In en, this message translates to:
  /// **'Ended Campaigns'**
  String get adminDashboardEndedCampaign;

  /// No description provided for @adminDashboardViewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get adminDashboardViewAnalytics;

  /// No description provided for @adminDashboardCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load dashboard.'**
  String get adminDashboardCouldNotLoad;

  /// No description provided for @adminDashboardParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String adminDashboardParticipantsCount(int count);

  /// No description provided for @adminGiveawaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Giveaways'**
  String get adminGiveawaysTitle;

  /// No description provided for @adminGiveawaysEmpty.
  ///
  /// In en, this message translates to:
  /// **'No giveaways yet.'**
  String get adminGiveawaysEmpty;

  /// No description provided for @adminGiveawaysParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String adminGiveawaysParticipantsCount(int count);

  /// No description provided for @createGiveawayTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Giveaway'**
  String get createGiveawayTitle;

  /// No description provided for @createGiveawayGiveawayTitle.
  ///
  /// In en, this message translates to:
  /// **'GIVEAWAY TITLE'**
  String get createGiveawayGiveawayTitle;

  /// No description provided for @createGiveawayGiveawayTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone 17 Pro Max'**
  String get createGiveawayGiveawayTitleHint;

  /// No description provided for @createGiveawayOrganizerName.
  ///
  /// In en, this message translates to:
  /// **'ORGANIZER NAME'**
  String get createGiveawayOrganizerName;

  /// No description provided for @createGiveawayOrganizerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. TechCorp Inc.'**
  String get createGiveawayOrganizerNameHint;

  /// No description provided for @createGiveawayPrizeDescription.
  ///
  /// In en, this message translates to:
  /// **'PRIZE DESCRIPTION (OPTIONAL)'**
  String get createGiveawayPrizeDescription;

  /// No description provided for @createGiveawayPrizeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe what the winner will receive.'**
  String get createGiveawayPrizeDescriptionHint;

  /// No description provided for @createGiveawayRules.
  ///
  /// In en, this message translates to:
  /// **'GIVEAWAY DESCRIPTION & RULES (OPTIONAL)'**
  String get createGiveawayRules;

  /// No description provided for @createGiveawayRulesHint.
  ///
  /// In en, this message translates to:
  /// **'Detail the full terms, conditions, and extra info.'**
  String get createGiveawayRulesHint;

  /// No description provided for @createGiveawayImage.
  ///
  /// In en, this message translates to:
  /// **'GIVEAWAY IMAGE'**
  String get createGiveawayImage;

  /// No description provided for @createGiveawayTapToBrowse.
  ///
  /// In en, this message translates to:
  /// **'Tap to browse from device'**
  String get createGiveawayTapToBrowse;

  /// No description provided for @createGiveawayImageSizeHint.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG, GIF up to 5MB'**
  String get createGiveawayImageSizeHint;

  /// No description provided for @createGiveawayImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image must be 5MB or smaller.'**
  String get createGiveawayImageTooLarge;

  /// No description provided for @createGiveawayStartDate.
  ///
  /// In en, this message translates to:
  /// **'START DATE'**
  String get createGiveawayStartDate;

  /// No description provided for @createGiveawayEndDate.
  ///
  /// In en, this message translates to:
  /// **'END DATE'**
  String get createGiveawayEndDate;

  /// No description provided for @createGiveawayEndTime.
  ///
  /// In en, this message translates to:
  /// **'END TIME'**
  String get createGiveawayEndTime;

  /// No description provided for @createGiveawayDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'mm/dd/yyyy'**
  String get createGiveawayDatePlaceholder;

  /// No description provided for @createGiveawayTimePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'--:--'**
  String get createGiveawayTimePlaceholder;

  /// No description provided for @createGiveawayMissingDates.
  ///
  /// In en, this message translates to:
  /// **'Please set the start date and time, and the end date and time.'**
  String get createGiveawayMissingDates;

  /// No description provided for @createGiveawayEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be on or after the start date.'**
  String get createGiveawayEndBeforeStart;

  /// No description provided for @createGiveawayPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish Giveaway'**
  String get createGiveawayPublish;

  /// No description provided for @giveawayAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Giveaway Analytics'**
  String get giveawayAnalyticsTitle;

  /// No description provided for @giveawayAnalyticsSelectParticipantTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Participant'**
  String get giveawayAnalyticsSelectParticipantTitle;

  /// No description provided for @giveawayAnalyticsConfirmWinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Winner'**
  String get giveawayAnalyticsConfirmWinnerTitle;

  /// No description provided for @giveawayAnalyticsConfirmWinnerBody.
  ///
  /// In en, this message translates to:
  /// **'Select participant {code} ({name}) as the winner?'**
  String giveawayAnalyticsConfirmWinnerBody(String code, String name);

  /// No description provided for @giveawayAnalyticsSelectWinnerAction.
  ///
  /// In en, this message translates to:
  /// **'Select Winner'**
  String get giveawayAnalyticsSelectWinnerAction;

  /// No description provided for @giveawayAnalyticsSelectAnotherWinnerAction.
  ///
  /// In en, this message translates to:
  /// **'Select Another Winner'**
  String get giveawayAnalyticsSelectAnotherWinnerAction;

  /// No description provided for @giveawayAnalyticsWinnerSelected.
  ///
  /// In en, this message translates to:
  /// **'Winner selected! A notification was sent.'**
  String get giveawayAnalyticsWinnerSelected;

  /// No description provided for @giveawayAnalyticsNoEligibleParticipants.
  ///
  /// In en, this message translates to:
  /// **'Every participant has already won.'**
  String get giveawayAnalyticsNoEligibleParticipants;

  /// No description provided for @giveawayAnalyticsTotalJoined.
  ///
  /// In en, this message translates to:
  /// **'Total Joined'**
  String get giveawayAnalyticsTotalJoined;

  /// No description provided for @giveawayAnalyticsActiveToday.
  ///
  /// In en, this message translates to:
  /// **'Active Today'**
  String get giveawayAnalyticsActiveToday;

  /// No description provided for @giveawayAnalyticsParticipationGrowth.
  ///
  /// In en, this message translates to:
  /// **'Participation Growth'**
  String get giveawayAnalyticsParticipationGrowth;

  /// No description provided for @giveawayAnalyticsRecentParticipants.
  ///
  /// In en, this message translates to:
  /// **'Recent Participants'**
  String get giveawayAnalyticsRecentParticipants;

  /// No description provided for @giveawayAnalyticsNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'No participants yet.'**
  String get giveawayAnalyticsNoParticipants;

  /// No description provided for @giveawayAnalyticsParticipationCode.
  ///
  /// In en, this message translates to:
  /// **'Code {code}'**
  String giveawayAnalyticsParticipationCode(String code);

  /// No description provided for @giveawayAnalyticsWinnersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get giveawayAnalyticsWinnersSectionTitle;

  /// No description provided for @giveawayAnalyticsViewWinners.
  ///
  /// In en, this message translates to:
  /// **'View Winner'**
  String get giveawayAnalyticsViewWinners;

  /// No description provided for @giveawayAnalyticsNoWinners.
  ///
  /// In en, this message translates to:
  /// **'No winners yet.'**
  String get giveawayAnalyticsNoWinners;

  /// No description provided for @giveawayAnalyticsRemoveFromView.
  ///
  /// In en, this message translates to:
  /// **'Remove from view'**
  String get giveawayAnalyticsRemoveFromView;

  /// No description provided for @giveawayAnalyticsWinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get giveawayAnalyticsWinnerLabel;

  /// No description provided for @giveawayAnalyticsWinnerRank.
  ///
  /// In en, this message translates to:
  /// **'Winner #{rank}'**
  String giveawayAnalyticsWinnerRank(int rank);

  /// No description provided for @giveawayAnalyticsSelectedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected At'**
  String get giveawayAnalyticsSelectedAtLabel;

  /// No description provided for @giveawayAnalyticsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get giveawayAnalyticsJustNow;

  /// No description provided for @giveawayAnalyticsMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} mins ago'**
  String giveawayAnalyticsMinsAgo(int count);

  /// No description provided for @giveawayAnalyticsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String giveawayAnalyticsHoursAgo(int count);

  /// No description provided for @giveawayAnalyticsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String giveawayAnalyticsDaysAgo(int count);

  /// No description provided for @giveawayAnalyticsChooseParticipantTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose participant'**
  String get giveawayAnalyticsChooseParticipantTooltip;

  /// No description provided for @giveawayAnalyticsPendingSelection.
  ///
  /// In en, this message translates to:
  /// **'Manually targeting {code} · {name}'**
  String giveawayAnalyticsPendingSelection(String code, String name);

  /// No description provided for @giveawayAnalyticsClearSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get giveawayAnalyticsClearSelectionTooltip;

  /// No description provided for @giveawayAnalyticsSelecting.
  ///
  /// In en, this message translates to:
  /// **'Selecting winner…'**
  String get giveawayAnalyticsSelecting;

  /// No description provided for @giveawayAnalyticsWheelErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t select a winner'**
  String get giveawayAnalyticsWheelErrorTitle;

  /// No description provided for @giveawayAnalyticsWheelDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get giveawayAnalyticsWheelDoneAction;

  /// No description provided for @giveawayAnalyticsDeleteGiveawayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete giveaway'**
  String get giveawayAnalyticsDeleteGiveawayTooltip;

  /// No description provided for @giveawayAnalyticsDeleteGiveawayTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Giveaway?'**
  String get giveawayAnalyticsDeleteGiveawayTitle;

  /// No description provided for @giveawayAnalyticsDeleteGiveawayBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this giveaway and all of its giveaway-specific data, including participants and winners. This action cannot be undone.'**
  String get giveawayAnalyticsDeleteGiveawayBody;

  /// No description provided for @giveawayAnalyticsGiveawayDeleted.
  ///
  /// In en, this message translates to:
  /// **'Giveaway deleted.'**
  String get giveawayAnalyticsGiveawayDeleted;

  /// No description provided for @adminProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Profile'**
  String get adminProfileTitle;

  /// No description provided for @adminProfileAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminProfileAdministrator;

  /// No description provided for @adminProfileSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll return to the role selection screen.'**
  String get adminProfileSignOutConfirmBody;

  /// No description provided for @adminAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get adminAnalysisTitle;

  /// No description provided for @adminAnalysisTotalGiveaways.
  ///
  /// In en, this message translates to:
  /// **'TOTAL GIVEAWAYS'**
  String get adminAnalysisTotalGiveaways;

  /// No description provided for @adminAnalysisActiveGiveaways.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get adminAnalysisActiveGiveaways;

  /// No description provided for @adminAnalysisFinishedGiveaways.
  ///
  /// In en, this message translates to:
  /// **'FINISHED'**
  String get adminAnalysisFinishedGiveaways;

  /// No description provided for @adminAnalysisTotalParticipants.
  ///
  /// In en, this message translates to:
  /// **'TOTAL PARTICIPANTS'**
  String get adminAnalysisTotalParticipants;

  /// No description provided for @adminAnalysisTotalWinners.
  ///
  /// In en, this message translates to:
  /// **'WINNERS SELECTED'**
  String get adminAnalysisTotalWinners;

  /// No description provided for @adminAnalysisGrowthTrend.
  ///
  /// In en, this message translates to:
  /// **'Participation Growth (Last 7 Days)'**
  String get adminAnalysisGrowthTrend;

  /// No description provided for @adminAnalysisCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load analysis.'**
  String get adminAnalysisCouldNotLoad;

  /// No description provided for @adminAnalysisNoData.
  ///
  /// In en, this message translates to:
  /// **'No giveaways yet — create one to see analysis here.'**
  String get adminAnalysisNoData;

  /// No description provided for @winnerCelebrationTitle.
  ///
  /// In en, this message translates to:
  /// **'WINNER'**
  String get winnerCelebrationTitle;

  /// No description provided for @winnerCelebrationCongratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve won:'**
  String get winnerCelebrationCongratulations;

  /// No description provided for @winnerCelebrationViewPrize.
  ///
  /// In en, this message translates to:
  /// **'View Prize'**
  String get winnerCelebrationViewPrize;

  /// No description provided for @winnerCelebrationDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get winnerCelebrationDismiss;

  /// No description provided for @winnerCelebrationYourPrize.
  ///
  /// In en, this message translates to:
  /// **'Your prize'**
  String get winnerCelebrationYourPrize;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @termsConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditionsTitle;

  /// No description provided for @legalLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String legalLastUpdated(String date);

  /// No description provided for @legalContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get legalContactUs;

  /// No description provided for @failureNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get failureNoInternet;

  /// No description provided for @failureServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get failureServer;

  /// No description provided for @failureUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to do that.'**
  String get failureUnauthorized;

  /// No description provided for @failurePhoneAlreadyRegisteredElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered on another device.'**
  String get failurePhoneAlreadyRegisteredElsewhere;

  /// No description provided for @failurePhoneAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already used by another account.'**
  String get failurePhoneAlreadyInUse;

  /// No description provided for @failureDuplicateParticipation.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already joined this giveaway.'**
  String get failureDuplicateParticipation;

  /// No description provided for @failureGiveawayFull.
  ///
  /// In en, this message translates to:
  /// **'This giveaway has reached its participant limit.'**
  String get failureGiveawayFull;

  /// No description provided for @failureGiveawayEnded.
  ///
  /// In en, this message translates to:
  /// **'This giveaway is no longer active.'**
  String get failureGiveawayEnded;

  /// No description provided for @failureRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get failureRateLimited;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your name and phone number up to date.'**
  String get editProfileSubtitle;

  /// No description provided for @editProfileSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSaveAction;

  /// No description provided for @editProfileUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get editProfileUpdateSuccess;

  /// No description provided for @browseAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get browseAll;

  /// No description provided for @browseClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get browseClearSearch;

  /// No description provided for @browseUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get browseUpcoming;

  /// No description provided for @browseEndingSoon.
  ///
  /// In en, this message translates to:
  /// **'Ending Soon'**
  String get browseEndingSoon;

  /// No description provided for @browseStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get browseStartsIn;

  /// No description provided for @browseDayShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get browseDayShort;

  /// No description provided for @browseHourShort.
  ///
  /// In en, this message translates to:
  /// **'h left'**
  String get browseHourShort;

  /// No description provided for @browseJoined.
  ///
  /// In en, this message translates to:
  /// **'joined'**
  String get browseJoined;

  /// No description provided for @browseNoGiveaways.
  ///
  /// In en, this message translates to:
  /// **'No giveaways found'**
  String get browseNoGiveaways;

  /// No description provided for @browseSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get browseSearchResults;

  /// No description provided for @browseLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get browseLoadMore;

  /// No description provided for @browseCategoriesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry loading categories'**
  String get browseCategoriesRetry;

  /// No description provided for @browseUpcomingMessage.
  ///
  /// In en, this message translates to:
  /// **'Starts on {date}. Participation opens at the scheduled time.'**
  String browseUpcomingMessage(String date);

  /// No description provided for @categoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get categoryManagement;

  /// No description provided for @categoryCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get categoryCreate;

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get categoryEdit;

  /// No description provided for @categorySelect.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get categorySelect;

  /// No description provided for @categoryNameEn.
  ///
  /// In en, this message translates to:
  /// **'English name'**
  String get categoryNameEn;

  /// No description provided for @categoryNameAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic name'**
  String get categoryNameAr;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Optional emoji icon'**
  String get categoryIcon;

  /// No description provided for @categoryOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get categoryOrder;

  /// No description provided for @categoryEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get categoryEnabled;

  /// No description provided for @categoryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get categoryDisabled;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value'**
  String get categoryRequired;

  /// No description provided for @categorySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get categorySave;

  /// No description provided for @categoryUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Category management requires a super administrator.'**
  String get categoryUnauthorized;

  /// No description provided for @categoryUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get categoryUncategorized;

  /// No description provided for @categoryInactiveKept.
  ///
  /// In en, this message translates to:
  /// **'The existing inactive category is kept until you select a replacement.'**
  String get categoryInactiveKept;

  /// No description provided for @categoryEditGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Edit giveaway'**
  String get categoryEditGiveaway;

  /// No description provided for @scheduleStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get scheduleStartTime;

  /// No description provided for @scheduleLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Times use this device\'s local timezone and are saved in UTC.'**
  String get scheduleLocalTime;

  /// No description provided for @adsPrivacyChoices.
  ///
  /// In en, this message translates to:
  /// **'Advertising privacy choices'**
  String get adsPrivacyChoices;

  /// No description provided for @scheduleInvalidDates.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get scheduleInvalidDates;

  /// No description provided for @adminDashboardScheduleSection.
  ///
  /// In en, this message translates to:
  /// **'GIVEAWAY SCHEDULE'**
  String get adminDashboardScheduleSection;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminNoFilteredGiveaways.
  ///
  /// In en, this message translates to:
  /// **'No giveaways in this group yet.'**
  String get adminNoFilteredGiveaways;

  /// No description provided for @createGiveawayEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Giveaway'**
  String get createGiveawayEditTitle;

  /// No description provided for @adminScheduleEditLocked.
  ///
  /// In en, this message translates to:
  /// **'This schedule cannot be changed after a giveaway starts or receives participants.'**
  String get adminScheduleEditLocked;

  /// No description provided for @rewardFrameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Make your entry special!'**
  String get rewardFrameDialogTitle;

  /// No description provided for @rewardFrameDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to get a special frame around your participation number in the app.'**
  String get rewardFrameDialogDescription;

  /// No description provided for @rewardFrameWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get rewardFrameWatchAd;
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
