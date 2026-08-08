// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'روارد جيف أواي';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonDismiss => 'إغلاق';

  @override
  String get commonSomethingWrong => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get commonRequired => 'مطلوب';

  @override
  String get roleSelectionWelcome => 'أهلاً بك 👋';

  @override
  String get roleSelectionChooseHow => 'اختر كيف تريد المتابعة.';

  @override
  String get roleSelectionContinueAsUser => 'المتابعة كمستخدم';

  @override
  String get roleSelectionContinueAsUserSubtitle => 'انضم إلى السحوبات المثيرة واربح جوائز رائعة.';

  @override
  String get roleSelectionContinueAsAdmin => 'المتابعة كمسؤول';

  @override
  String get roleSelectionContinueAsAdminSubtitle => 'أنشئ وأدر حملات السحب على الجوائز.';

  @override
  String get roleSelectionSwitchAnytime => 'يمكنك تبديل دورك في أي وقت.';

  @override
  String get userHomeWelcomeBack => 'مرحباً بعودتك 👋';

  @override
  String get userHomeGuest => 'زائر';

  @override
  String get userHomeSearchHint => 'ابحث عن سحوبات…';

  @override
  String get userHomePopularGiveaways => 'السحوبات الأكثر رواجاً';

  @override
  String get userHomeAllGiveaways => 'جميع السحوبات';

  @override
  String get userHomeFeaturedGiveaway => 'سحب مميز';

  @override
  String userHomeJoinedCount(int count) {
    return '$count مشارك';
  }

  @override
  String get userHomeViewDetails => 'عرض التفاصيل';

  @override
  String get userHomeNoActiveGiveaways => 'لا توجد سحوبات نشطة الآن — تحقق لاحقاً';

  @override
  String get userHomeCouldNotLoad => 'تعذّر تحميل السحوبات.';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusEnded => 'منتهٍ';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusScheduled => 'مجدوَل';

  @override
  String get statusArchived => 'مؤرشف';

  @override
  String get giveawayDetailsAboutPrize => 'عن هذه الجائزة';

  @override
  String get giveawayDetailsHowToParticipate => 'كيفية المشاركة';

  @override
  String get giveawayDetailsRules => 'القواعد';

  @override
  String get giveawayDetailsGenerateNumber => 'إنشاء رقمي';

  @override
  String get giveawayDetailsNotActive => 'السحب غير نشط';

  @override
  String get giveawayDetailsYoureIn => 'أنت مشارك بالفعل!';

  @override
  String giveawayDetailsYoureInWithNumber(String number) {
    return 'أنت مشارك بالفعل! ‎#$number';
  }

  @override
  String get giveawayDetailsCouldNotLoad => 'تعذّر تحميل هذا السحب.';

  @override
  String get giveawayDetailsEnded => 'انتهى';

  @override
  String giveawayDetailsHoursLeft(int hours) {
    return 'باقي $hours ساعة';
  }

  @override
  String giveawayDetailsDaysHoursLeft(int days, int hours) {
    return 'باقي $days يوم و$hours ساعة';
  }

  @override
  String get registrationTitle => 'إنشاء حسابك';

  @override
  String get registrationSubtitle => 'أدخل بياناتك لبدء المشاركة.';

  @override
  String get registrationFullNameLabel => 'الاسم الكامل';

  @override
  String get registrationFullNameHint => 'مثال: سارة أحمد';

  @override
  String get registrationFullNameError => 'أدخل اسمك الكامل';

  @override
  String get registrationCountryLabel => 'الدولة';

  @override
  String get registrationPhoneLabel => 'رقم الهاتف';

  @override
  String get registrationPhoneHint => '٥٥٥ ٠٠٠ ٠٠٠٠';

  @override
  String get registrationPhoneRequiredError => 'أدخل رقم هاتفك';

  @override
  String get registrationPhoneInvalidError => 'أدخل رقم هاتف صحيح';

  @override
  String get registrationContinue => 'متابعة';

  @override
  String get registrationAgreeTerms => 'بالمتابعة، أنت توافق على سياسة الخصوصية والشروط والأحكام.';

  @override
  String get participationJoinGiveaway => 'الانضمام إلى السحب';

  @override
  String get participationGeneratingNumber => 'جارٍ إنشاء رقمك…';

  @override
  String get participationSuccessOpening => 'تم بنجاح! جارٍ فتح بطاقتك…';

  @override
  String get participationTryAgain => 'حاول مرة أخرى';

  @override
  String get scratchCardYourLuckyNumber => 'رقم حظك';

  @override
  String get scratchCardScratchToReveal => 'اخدش البطاقة للكشف عن رقمك';

  @override
  String get scratchCardViewInMyGiveaways => 'عرضه في سحوباتي';

  @override
  String get myGiveawaysTitle => 'سحوباتي';

  @override
  String get myGiveawaysEmpty => 'لم تنضم إلى أي سحب بعد';

  @override
  String get myGiveawaysCouldNotLoad => 'تعذّر تحميل سحوباتك.';

  @override
  String get myGiveawaysGiveawayFallback => 'سحب';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsTermsConditions => 'الشروط والأحكام';

  @override
  String get settingsSignOut => 'تسجيل الخروج';

  @override
  String get settingsSignOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get settingsSignOutConfirmBody =>
      'ستعود إلى شاشة اختيار الدور. سحوباتك وسجلّك المحفوظ سيبقيان على هذا الجهاز.';

  @override
  String get settingsAboutBody =>
      'يتيح لك تطبيق Reward Giveaway الانضمام إلى سحوبات الجوائز المثيرة وإدارتها. تم بناؤه باستخدام Flutter وSupabase.';

  @override
  String get adminAuthTitle => 'المسؤول';

  @override
  String get adminAuthCreateAccount => 'إنشاء حساب مسؤول';

  @override
  String get adminAuthSignInTitle => 'تسجيل دخول المسؤول';

  @override
  String get adminAuthSignUpSubtitle => 'سجّل حساب مسؤول جديد لإدارة حملات السحب.';

  @override
  String get adminAuthSignInSubtitle => 'سجّل الدخول لإدارة حملات السحب.';

  @override
  String get adminAuthSignIn => 'تسجيل الدخول';

  @override
  String get adminAuthSignUp => 'إنشاء حساب';

  @override
  String get adminAuthFullNameLabel => 'الاسم الكامل';

  @override
  String get adminAuthFullNameError => 'أدخل اسمك الكامل';

  @override
  String get adminAuthEmailLabel => 'البريد الإلكتروني';

  @override
  String get adminAuthEmailError => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get adminAuthPasswordLabel => 'كلمة المرور';

  @override
  String get adminAuthPasswordEmptyError => 'أدخل كلمة المرور';

  @override
  String get adminAuthPasswordLengthError => 'يجب ألا تقل كلمة المرور عن 8 أحرف';

  @override
  String get adminAuthConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get adminAuthPasswordsNoMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get adminAuthAccessCodeLabel => 'رمز دخول المسؤول';

  @override
  String get adminAuthAccessCodeError => 'أدخل رمز دخول المسؤول';

  @override
  String get adminAuthCreateAccountButton => 'إنشاء الحساب';

  @override
  String get adminAuthSignInButton => 'تسجيل الدخول';

  @override
  String get adminDashboardGoodDay => 'يوم سعيد 👋';

  @override
  String get adminDashboardAdministrator => 'المسؤول';

  @override
  String get adminDashboardActiveGiveaways => 'السحوبات النشطة';

  @override
  String get adminDashboardTotalParticipants => 'إجمالي المشاركين';

  @override
  String get adminDashboardFinished => 'المنتهية';

  @override
  String get adminDashboardWinnersSelected => 'الفائزون المختارون';

  @override
  String get adminDashboardActiveCampaign => 'الحملة النشطة';

  @override
  String get adminDashboardNoActiveCampaigns => 'لا توجد حملات نشطة بعد. اضغط + لإنشاء واحدة.';

  @override
  String get adminDashboardViewAnalytics => 'عرض التحليلات';

  @override
  String get adminDashboardCouldNotLoad => 'تعذّر تحميل لوحة التحكم.';

  @override
  String adminDashboardParticipantsCount(int count) {
    return '$count مشارك';
  }

  @override
  String get adminGiveawaysTitle => 'السحوبات';

  @override
  String get adminGiveawaysEmpty => 'لا توجد سحوبات بعد.';

  @override
  String adminGiveawaysParticipantsCount(int count) {
    return '$count مشارك';
  }

  @override
  String get createGiveawayTitle => 'إنشاء سحب';

  @override
  String get createGiveawayGiveawayTitle => 'عنوان السحب';

  @override
  String get createGiveawayGiveawayTitleHint => 'مثال: آيفون 17 برو ماكس';

  @override
  String get createGiveawayOrganizerName => 'اسم الجهة المنظمة';

  @override
  String get createGiveawayOrganizerNameHint => 'مثال: شركة التقنية المتحدة';

  @override
  String get createGiveawayPrizeDescription => 'وصف الجائزة';

  @override
  String get createGiveawayPrizeDescriptionHint => 'صف بإيجاز ما سيحصل عليه الفائز.';

  @override
  String get createGiveawayRules => 'وصف السحب وقواعده';

  @override
  String get createGiveawayRulesHint => 'اذكر جميع الشروط والأحكام والتفاصيل الإضافية.';

  @override
  String get createGiveawayImage => 'صورة السحب';

  @override
  String get createGiveawayTapToBrowse => 'اضغط للاختيار من الجهاز';

  @override
  String get createGiveawayImageSizeHint => 'JPG أو PNG أو GIF بحد أقصى 5 ميجابايت';

  @override
  String get createGiveawayImageTooLarge => 'يجب ألا يتجاوز حجم الصورة 5 ميجابايت.';

  @override
  String get createGiveawayStartDate => 'تاريخ البدء';

  @override
  String get createGiveawayEndDate => 'تاريخ الانتهاء';

  @override
  String get createGiveawayEndTime => 'وقت الانتهاء';

  @override
  String get createGiveawayDatePlaceholder => 'شهر/يوم/سنة';

  @override
  String get createGiveawayTimePlaceholder => '--:--';

  @override
  String get createGiveawayMissingDates => 'يرجى تحديد تاريخ البدء وتاريخ الانتهاء ووقت الانتهاء.';

  @override
  String get createGiveawayEndBeforeStart =>
      'يجب أن يكون تاريخ الانتهاء بعد تاريخ البدء أو مساوياً له.';

  @override
  String get createGiveawayPublish => 'نشر السحب';

  @override
  String get giveawayAnalyticsTitle => 'تحليلات السحب';

  @override
  String get giveawayAnalyticsSelectWinnerTitle => 'اختيار فائز؟';

  @override
  String get giveawayAnalyticsSelectWinnerBody =>
      'سيتم اختيار فائز عشوائياً من بين جميع المشاركين المؤهلين. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get giveawayAnalyticsSelectWinnerAction => 'اختيار الفائز';

  @override
  String get giveawayAnalyticsWinnerSelected => 'تم اختيار الفائز! تم إرسال إشعار.';

  @override
  String get giveawayAnalyticsTotalJoined => 'إجمالي المنضمين';

  @override
  String get giveawayAnalyticsActiveToday => 'نشط اليوم';

  @override
  String get giveawayAnalyticsParticipationGrowth => 'نمو المشاركة';

  @override
  String get giveawayAnalyticsRecentParticipants => 'المشاركون الأخيرون';

  @override
  String get giveawayAnalyticsNoParticipants => 'لا يوجد مشاركون بعد.';

  @override
  String giveawayAnalyticsTicketNumber(int sequence) {
    return 'التذكرة رقم $sequence';
  }

  @override
  String giveawayAnalyticsWinnerTicket(String number) {
    return 'تم اختيار الفائز: التذكرة رقم $number';
  }

  @override
  String get giveawayAnalyticsJustNow => 'الآن';

  @override
  String giveawayAnalyticsMinsAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String giveawayAnalyticsHoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String giveawayAnalyticsDaysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get adminProfileTitle => 'الملف الشخصي للمسؤول';

  @override
  String get adminProfileAdministrator => 'المسؤول';

  @override
  String get winnerCelebrationTitle => 'فائز';

  @override
  String get winnerCelebrationCongratulations => 'تهانينا! لقد فزت بـ:';

  @override
  String get winnerCelebrationViewPrize => 'عرض الجائزة';

  @override
  String get winnerCelebrationDismiss => 'إغلاق';

  @override
  String get winnerCelebrationYourPrize => 'جائزتك';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get termsConditionsTitle => 'الشروط والأحكام';

  @override
  String legalLastUpdated(String date) {
    return 'آخر تحديث: $date';
  }

  @override
  String get legalContactUs => 'تواصل معنا';

  @override
  String get failureNoInternet => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get failureServer => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get failureUnauthorized => 'غير مصرح لك بالقيام بذلك.';

  @override
  String get failureDuplicatePhone => 'رقم الهاتف هذا مسجّل بالفعل.';

  @override
  String get failureDuplicateParticipation => 'لقد شاركت بالفعل في هذا السحب.';

  @override
  String get failureGiveawayFull => 'وصل هذا السحب إلى الحد الأقصى للمشاركين.';

  @override
  String get failureGiveawayEnded => 'لم يعد هذا السحب نشطاً.';

  @override
  String get failureRateLimited => 'محاولات كثيرة جداً. يرجى الانتظار قليلاً ثم المحاولة مرة أخرى.';
}
