// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Reward Giveaway';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get commonRequired => 'Required';

  @override
  String get roleSelectionWelcome => 'Welcome 👋';

  @override
  String get roleSelectionChooseHow => 'Choose how you\'d like to continue.';

  @override
  String get roleSelectionContinueAsUser => 'Continue as User';

  @override
  String get roleSelectionContinueAsUserSubtitle =>
      'Join exciting giveaways and win amazing prizes.';

  @override
  String get roleSelectionContinueAsAdmin => 'Continue as Admin';

  @override
  String get roleSelectionContinueAsAdminSubtitle => 'Create and manage giveaway campaigns.';

  @override
  String get roleSelectionSwitchAnytime => 'YOU CAN SWITCH YOUR ROLE ANYTIME.';

  @override
  String get userHomeWelcomeBack => 'WELCOME BACK 👋';

  @override
  String get userHomeGuest => 'Guest';

  @override
  String get userHomeSearchHint => 'Search giveaways…';

  @override
  String get userHomePopularGiveaways => 'Popular Giveaways';

  @override
  String get userHomeAllGiveaways => 'All Giveaways';

  @override
  String get userHomeFeaturedGiveaway => 'Featured Giveaway';

  @override
  String userHomeJoinedCount(int count) {
    return '$count joined';
  }

  @override
  String get userHomeViewDetails => 'View Details';

  @override
  String get userHomeNoActiveGiveaways => 'No active giveaways right now — check back soon';

  @override
  String get userHomeCouldNotLoad => 'Couldn\'t load giveaways.';

  @override
  String get statusActive => 'Active';

  @override
  String get statusEnded => 'Ended';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusArchived => 'Archived';

  @override
  String get giveawayDetailsAboutPrize => 'About this prize';

  @override
  String get giveawayDetailsHowToParticipate => 'How to Participate';

  @override
  String get giveawayDetailsRules => 'Rules';

  @override
  String get giveawayDetailsGenerateNumber => 'Generate My Number';

  @override
  String get giveawayDetailsNotActive => 'Giveaway Not Active';

  @override
  String get giveawayDetailsYoureIn => 'You\'re in!';

  @override
  String giveawayDetailsYoureInWithNumber(String number) {
    return 'You\'re in! #$number';
  }

  @override
  String get giveawayDetailsCouldNotLoad => 'Couldn\'t load this giveaway.';

  @override
  String get giveawayDetailsEnded => 'Ended';

  @override
  String giveawayDetailsHoursLeft(int hours) {
    return '$hours h left';
  }

  @override
  String giveawayDetailsDaysHoursLeft(int days, int hours) {
    return '$days d $hours h left';
  }

  @override
  String get registrationTitle => 'Create Your Account';

  @override
  String get registrationSubtitle => 'Enter your information to start participating.';

  @override
  String get registrationFullNameLabel => 'FULL NAME';

  @override
  String get registrationFullNameHint => 'Jane Doe';

  @override
  String get registrationFullNameError => 'Enter your full name';

  @override
  String get registrationCountryLabel => 'COUNTRY';

  @override
  String get registrationPhoneLabel => 'PHONE NUMBER';

  @override
  String get registrationPhoneHint => '(555) 000-0000';

  @override
  String get registrationPhoneRequiredError => 'Enter your phone number';

  @override
  String get registrationPhoneInvalidError => 'Enter a valid phone number';

  @override
  String get registrationContinue => 'CONTINUE';

  @override
  String get registrationAgreeTerms => 'By continuing you agree to our Privacy Policy and Terms.';

  @override
  String get participationJoinGiveaway => 'Join Giveaway';

  @override
  String get participationGeneratingNumber => 'Generating your number…';

  @override
  String get participationSuccessOpening => 'Success! Opening your card…';

  @override
  String get participationTryAgain => 'Try Again';

  @override
  String get scratchCardYourLuckyNumber => 'Your Lucky Number';

  @override
  String get scratchCardScratchToReveal => 'Scratch the card to reveal your number';

  @override
  String get scratchCardViewInMyGiveaways => 'View in My Giveaways';

  @override
  String get myGiveawaysTitle => 'My Giveaways';

  @override
  String get myGiveawaysEmpty => 'You haven\'t joined any giveaways yet';

  @override
  String get myGiveawaysCouldNotLoad => 'Couldn\'t load your giveaways.';

  @override
  String get myGiveawaysGiveawayFallback => 'Giveaway';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsConditions => 'Terms & Conditions';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutConfirmTitle => 'Sign Out?';

  @override
  String get settingsSignOutConfirmBody =>
      'You\'ll return to the role selection screen. Your saved giveaways and history stay on this device.';

  @override
  String get settingsAboutBody =>
      'Reward Giveaway lets you join and manage exciting prize giveaways. Built with Flutter and Supabase.';

  @override
  String get adminAuthTitle => 'Admin';

  @override
  String get adminAuthCreateAccount => 'Create Admin Account';

  @override
  String get adminAuthSignInTitle => 'Admin Sign In';

  @override
  String get adminAuthSignUpSubtitle =>
      'Register a new admin account to manage giveaway campaigns.';

  @override
  String get adminAuthSignInSubtitle => 'Sign in to manage giveaway campaigns.';

  @override
  String get adminAuthSignIn => 'Sign In';

  @override
  String get adminAuthSignUp => 'Sign Up';

  @override
  String get adminAuthFullNameLabel => 'FULL NAME';

  @override
  String get adminAuthFullNameError => 'Enter your full name';

  @override
  String get adminAuthEmailLabel => 'EMAIL';

  @override
  String get adminAuthEmailError => 'Enter a valid email';

  @override
  String get adminAuthPasswordLabel => 'PASSWORD';

  @override
  String get adminAuthPasswordEmptyError => 'Enter your password';

  @override
  String get adminAuthPasswordLengthError => 'Password must be at least 8 characters';

  @override
  String get adminAuthConfirmPasswordLabel => 'CONFIRM PASSWORD';

  @override
  String get adminAuthPasswordsNoMatch => 'Passwords do not match';

  @override
  String get adminAuthAccessCodeLabel => 'ADMIN ACCESS CODE';

  @override
  String get adminAuthAccessCodeError => 'Enter your admin access code';

  @override
  String get adminAuthCreateAccountButton => 'CREATE ACCOUNT';

  @override
  String get adminAuthSignInButton => 'SIGN IN';

  @override
  String get adminDashboardGoodDay => 'Good day 👋';

  @override
  String get adminDashboardAdministrator => 'Administrator';

  @override
  String get adminDashboardActiveGiveaways => 'ACTIVE GIVEAWAYS';

  @override
  String get adminDashboardTotalParticipants => 'TOTAL PARTICIPANTS';

  @override
  String get adminDashboardFinished => 'FINISHED';

  @override
  String get adminDashboardWinnersSelected => 'WINNERS SELECTED';

  @override
  String get adminDashboardActiveCampaign => 'Active Campaign';

  @override
  String get adminDashboardNoActiveCampaigns => 'No active campaigns yet. Tap + to create one.';

  @override
  String get adminDashboardViewAnalytics => 'View Analytics';

  @override
  String get adminDashboardCouldNotLoad => 'Couldn\'t load dashboard.';

  @override
  String adminDashboardParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String get adminGiveawaysTitle => 'Giveaways';

  @override
  String get adminGiveawaysEmpty => 'No giveaways yet.';

  @override
  String adminGiveawaysParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String get createGiveawayTitle => 'Create Giveaway';

  @override
  String get createGiveawayGiveawayTitle => 'GIVEAWAY TITLE';

  @override
  String get createGiveawayGiveawayTitleHint => 'e.g. iPhone 17 Pro Max';

  @override
  String get createGiveawayOrganizerName => 'ORGANIZER NAME';

  @override
  String get createGiveawayOrganizerNameHint => 'e.g. TechCorp Inc.';

  @override
  String get createGiveawayPrizeDescription => 'PRIZE DESCRIPTION';

  @override
  String get createGiveawayPrizeDescriptionHint => 'Briefly describe what the winner will receive.';

  @override
  String get createGiveawayRules => 'GIVEAWAY DESCRIPTION & RULES';

  @override
  String get createGiveawayRulesHint => 'Detail the full terms, conditions, and extra info.';

  @override
  String get createGiveawayImage => 'GIVEAWAY IMAGE';

  @override
  String get createGiveawayTapToBrowse => 'Tap to browse from device';

  @override
  String get createGiveawayImageSizeHint => 'JPG, PNG, GIF up to 5MB';

  @override
  String get createGiveawayImageTooLarge => 'Image must be 5MB or smaller.';

  @override
  String get createGiveawayStartDate => 'START DATE';

  @override
  String get createGiveawayEndDate => 'END DATE';

  @override
  String get createGiveawayEndTime => 'END TIME';

  @override
  String get createGiveawayDatePlaceholder => 'mm/dd/yyyy';

  @override
  String get createGiveawayTimePlaceholder => '--:--';

  @override
  String get createGiveawayMissingDates => 'Please set start date, end date, and end time.';

  @override
  String get createGiveawayEndBeforeStart => 'End date must be on or after the start date.';

  @override
  String get createGiveawayPublish => 'Publish Giveaway';

  @override
  String get giveawayAnalyticsTitle => 'Giveaway Analytics';

  @override
  String get giveawayAnalyticsSelectWinnerTitle => 'Select Winner?';

  @override
  String get giveawayAnalyticsSelectWinnerBody =>
      'A winner will be picked at random from all eligible participants. This cannot be undone.';

  @override
  String get giveawayAnalyticsSelectWinnerAction => 'Select Winner';

  @override
  String get giveawayAnalyticsWinnerSelected => 'Winner selected! A notification was sent.';

  @override
  String get giveawayAnalyticsTotalJoined => 'Total Joined';

  @override
  String get giveawayAnalyticsActiveToday => 'Active Today';

  @override
  String get giveawayAnalyticsParticipationGrowth => 'Participation Growth';

  @override
  String get giveawayAnalyticsRecentParticipants => 'Recent Participants';

  @override
  String get giveawayAnalyticsNoParticipants => 'No participants yet.';

  @override
  String giveawayAnalyticsTicketNumber(int sequence) {
    return 'Ticket #$sequence';
  }

  @override
  String giveawayAnalyticsWinnerTicket(String number) {
    return 'Winner selected: ticket #$number';
  }

  @override
  String get giveawayAnalyticsJustNow => 'Just now';

  @override
  String giveawayAnalyticsMinsAgo(int count) {
    return '$count mins ago';
  }

  @override
  String giveawayAnalyticsHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String giveawayAnalyticsDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get adminProfileTitle => 'Admin Profile';

  @override
  String get adminProfileAdministrator => 'Administrator';

  @override
  String get winnerCelebrationTitle => 'WINNER';

  @override
  String get winnerCelebrationCongratulations => 'Congratulations! You\'ve won:';

  @override
  String get winnerCelebrationViewPrize => 'View Prize';

  @override
  String get winnerCelebrationDismiss => 'Dismiss';

  @override
  String get winnerCelebrationYourPrize => 'Your prize';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsConditionsTitle => 'Terms & Conditions';

  @override
  String legalLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get legalContactUs => 'Contact us';

  @override
  String get failureNoInternet => 'No internet connection.';

  @override
  String get failureServer => 'Something went wrong. Please try again.';

  @override
  String get failureUnauthorized => 'You are not authorized to do that.';

  @override
  String get failureDuplicatePhone => 'This phone number is already registered.';

  @override
  String get failureDuplicateParticipation => 'You\'ve already joined this giveaway.';

  @override
  String get failureGiveawayFull => 'This giveaway has reached its participant limit.';

  @override
  String get failureGiveawayEnded => 'This giveaway is no longer active.';

  @override
  String get failureRateLimited => 'Too many attempts. Please wait a moment and try again.';
}
