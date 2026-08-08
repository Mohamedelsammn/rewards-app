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

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

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
  /// **'WELCOME BACK 👋'**
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
  /// **'No active giveaways right now — check back soon'**
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
  /// **'Success! Opening your card…'**
  String get participationSuccessOpening;

  /// No description provided for @participationTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get participationTryAgain;

  /// No description provided for @scratchCardYourLuckyNumber.
  ///
  /// In en, this message translates to:
  /// **'Your Lucky Number'**
  String get scratchCardYourLuckyNumber;

  /// No description provided for @scratchCardScratchToReveal.
  ///
  /// In en, this message translates to:
  /// **'Scratch the card to reveal your number'**
  String get scratchCardScratchToReveal;

  /// No description provided for @scratchCardViewInMyGiveaways.
  ///
  /// In en, this message translates to:
  /// **'View in My Giveaways'**
  String get scratchCardViewInMyGiveaways;

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
  /// **'Active Campaign'**
  String get adminDashboardActiveCampaign;

  /// No description provided for @adminDashboardNoActiveCampaigns.
  ///
  /// In en, this message translates to:
  /// **'No active campaigns yet. Tap + to create one.'**
  String get adminDashboardNoActiveCampaigns;

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
  /// **'PRIZE DESCRIPTION'**
  String get createGiveawayPrizeDescription;

  /// No description provided for @createGiveawayPrizeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe what the winner will receive.'**
  String get createGiveawayPrizeDescriptionHint;

  /// No description provided for @createGiveawayRules.
  ///
  /// In en, this message translates to:
  /// **'GIVEAWAY DESCRIPTION & RULES'**
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
  /// **'Please set start date, end date, and end time.'**
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

  /// No description provided for @giveawayAnalyticsSelectWinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Winner?'**
  String get giveawayAnalyticsSelectWinnerTitle;

  /// No description provided for @giveawayAnalyticsSelectWinnerBody.
  ///
  /// In en, this message translates to:
  /// **'A winner will be picked at random from all eligible participants. This cannot be undone.'**
  String get giveawayAnalyticsSelectWinnerBody;

  /// No description provided for @giveawayAnalyticsSelectWinnerAction.
  ///
  /// In en, this message translates to:
  /// **'Select Winner'**
  String get giveawayAnalyticsSelectWinnerAction;

  /// No description provided for @giveawayAnalyticsWinnerSelected.
  ///
  /// In en, this message translates to:
  /// **'Winner selected! A notification was sent.'**
  String get giveawayAnalyticsWinnerSelected;

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

  /// No description provided for @giveawayAnalyticsTicketNumber.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{sequence}'**
  String giveawayAnalyticsTicketNumber(int sequence);

  /// No description provided for @giveawayAnalyticsWinnerTicket.
  ///
  /// In en, this message translates to:
  /// **'Winner selected: ticket #{number}'**
  String giveawayAnalyticsWinnerTicket(String number);

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

  /// No description provided for @failureDuplicatePhone.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered.'**
  String get failureDuplicatePhone;

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
