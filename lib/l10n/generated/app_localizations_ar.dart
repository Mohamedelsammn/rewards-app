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
  String get commonConfirm => 'تأكيد';

  @override
  String get commonDismiss => 'إغلاق';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonSomethingWrong => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get commonRequired => 'مطلوب';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navDashboard => 'لوحة التحكم';

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
  String get userHomeWelcomeBack => 'مرحبًا بعودتك 👋';

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
  String get participationSuccessOpening => 'تم بنجاح! جارٍ الكشف عن رمزك…';

  @override
  String get participationTryAgain => 'حاول مرة أخرى';

  @override
  String get numberRevealTitle => 'رمز مشاركتك';

  @override
  String get numberRevealSubtitle => 'تم إنشاؤه خصيصًا لك';

  @override
  String get numberRevealViewInMyGiveaways => 'عرضه في سحوباتي';

  @override
  String get myGiveawaysTitle => 'سحوباتي';

  @override
  String get myGiveawaysEmpty => 'لم تنضم إلى أي سحب بعد';

  @override
  String get myGiveawaysCouldNotLoad => 'تعذّر تحميل سحوباتك.';

  @override
  String get myGiveawaysGiveawayFallback => 'سحب';

  @override
  String get myGiveawaysWinner => 'لقد فزت بهذا السحب!';

  @override
  String get myGiveawaysNotSelected => 'لم يتم اختيارك كفائز هذه المرة';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات جديدة حتى الآن.';

  @override
  String get notificationsCouldNotLoad => 'تعذّر تحميل الإشعارات.';

  @override
  String get notificationsMarkAllRead => 'تعليم الكل كمقروء';

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
  String get settingsSectionGeneral => 'عام';

  @override
  String get settingsSectionInformation => 'معلومات';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsGuestSubtitle => 'انضم إلى سحب لإنشاء ملفك الشخصي';

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
  String get adminAuthFullNameHint => 'اسمك الكامل';

  @override
  String get adminAuthEmailLabel => 'البريد الإلكتروني';

  @override
  String get adminAuthEmailError => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get adminAuthEmailHint => 'example@gmail.com';

  @override
  String get adminAuthPasswordLabel => 'كلمة المرور';

  @override
  String get adminAuthPasswordEmptyError => 'أدخل كلمة المرور';

  @override
  String get adminAuthPasswordLengthError => 'يجب ألا تقل كلمة المرور عن 8 أحرف';

  @override
  String get adminAuthPasswordHint => '••••••••';

  @override
  String get adminAuthPasswordRequirementHelper => '8 أحرف على الأقل';

  @override
  String get adminAuthConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get adminAuthPasswordsNoMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get adminAuthAccessCodeLabel => 'رمز دخول المسؤول';

  @override
  String get adminAuthAccessCodeError => 'أدخل رمز دخول المسؤول';

  @override
  String get adminAuthAccessCodeHint => 'أدخل الرمز الذي زُوّدت به';

  @override
  String get adminAuthCreateAccountButton => 'إنشاء الحساب';

  @override
  String get adminAuthSignInButton => 'تسجيل الدخول';

  @override
  String get adminAuthNoAccessCodeQuestion => 'ليس لديك كود دخول المسؤول؟';

  @override
  String get adminAuthContactWhatsAppSubtitle => 'تواصل معنا عبر واتساب لطلب الوصول.';

  @override
  String get adminAuthWhatsAppPrefilledMessage =>
      'مرحباً، أريد الانضمام إلى المسابقات الخاصة بكم وأحتاج إلى كود دخول المسؤول لإنشاء حساب Admin.';

  @override
  String get adminAuthWhatsAppOpenFailed => 'تعذّر فتح واتساب. يُرجى المحاولة مرة أخرى.';

  @override
  String get commonShowPassword => 'إظهار كلمة المرور';

  @override
  String get commonHidePassword => 'إخفاء كلمة المرور';

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
  String get adminDashboardActiveCampaign => 'الحملات النشطة';

  @override
  String get adminDashboardNoActiveCampaigns => 'لا توجد حملات نشطة بعد. اضغط + لإنشاء واحدة.';

  @override
  String get adminDashboardEndedCampaign => 'الحملات المنتهية';

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
  String get createGiveawayPrizeDescription => 'وصف الجائزة (اختياري)';

  @override
  String get createGiveawayPrizeDescriptionHint => 'صف بإيجاز ما سيحصل عليه الفائز.';

  @override
  String get createGiveawayRules => 'وصف السحب وقواعده (اختياري)';

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
  String get createGiveawayMissingDates => 'يرجى تحديد تاريخ ووقت البدء والانتهاء.';

  @override
  String get createGiveawayEndBeforeStart =>
      'يجب أن يكون تاريخ الانتهاء بعد تاريخ البدء أو مساوياً له.';

  @override
  String get createGiveawayPublish => 'نشر السحب';

  @override
  String get giveawayAnalyticsTitle => 'تحليلات السحب';

  @override
  String get giveawayAnalyticsSelectParticipantTitle => 'اختر مشاركًا';

  @override
  String get giveawayAnalyticsConfirmWinnerTitle => 'تأكيد الفائز';

  @override
  String giveawayAnalyticsConfirmWinnerBody(String code, String name) {
    return 'هل تريد اختيار المشارك $code ($name) كفائز؟';
  }

  @override
  String get giveawayAnalyticsSelectWinnerAction => 'اختيار الفائز';

  @override
  String get giveawayAnalyticsSelectAnotherWinnerAction => 'اختيار فائز آخر';

  @override
  String get giveawayAnalyticsWinnerSelected => 'تم اختيار الفائز! تم إرسال إشعار.';

  @override
  String get giveawayAnalyticsNoEligibleParticipants => 'جميع المشاركين فازوا بالفعل.';

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
  String giveawayAnalyticsParticipationCode(String code) {
    return 'الرمز $code';
  }

  @override
  String get giveawayAnalyticsWinnersSectionTitle => 'الفائزون';

  @override
  String get giveawayAnalyticsViewWinners => 'عرض الفائز';

  @override
  String get giveawayAnalyticsNoWinners => 'لا يوجد فائزون بعد.';

  @override
  String get giveawayAnalyticsRemoveFromView => 'إخفاء من العرض';

  @override
  String get giveawayAnalyticsWinnerLabel => 'الفائز';

  @override
  String giveawayAnalyticsWinnerRank(int rank) {
    return 'الفائز رقم $rank';
  }

  @override
  String get giveawayAnalyticsSelectedAtLabel => 'وقت الاختيار';

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
  String get giveawayAnalyticsChooseParticipantTooltip => 'اختيار مشارك';

  @override
  String giveawayAnalyticsPendingSelection(String code, String name) {
    return 'الاستهداف اليدوي: $code · $name';
  }

  @override
  String get giveawayAnalyticsClearSelectionTooltip => 'إلغاء الاختيار';

  @override
  String get giveawayAnalyticsSelecting => 'جارٍ اختيار الفائز…';

  @override
  String get giveawayAnalyticsWheelErrorTitle => 'تعذر اختيار فائز';

  @override
  String get giveawayAnalyticsWheelDoneAction => 'تم';

  @override
  String get giveawayAnalyticsDeleteGiveawayTooltip => 'حذف السحب';

  @override
  String get giveawayAnalyticsDeleteGiveawayTitle => 'حذف السحب؟';

  @override
  String get giveawayAnalyticsDeleteGiveawayBody =>
      'سيؤدي هذا إلى حذف هذا السحب نهائيًا مع كل بياناته الخاصة به، بما في ذلك المشاركين والفائزين. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get giveawayAnalyticsGiveawayDeleted => 'تم حذف السحب.';

  @override
  String get adminProfileTitle => 'الملف الشخصي للمسؤول';

  @override
  String get adminProfileAdministrator => 'المسؤول';

  @override
  String get adminProfileSignOutConfirmBody => 'ستعود إلى شاشة اختيار الدور.';

  @override
  String get adminAnalysisTitle => 'التحليلات';

  @override
  String get adminAnalysisTotalGiveaways => 'إجمالي السحوبات';

  @override
  String get adminAnalysisActiveGiveaways => 'نشطة';

  @override
  String get adminAnalysisFinishedGiveaways => 'منتهية';

  @override
  String get adminAnalysisTotalParticipants => 'إجمالي المشاركين';

  @override
  String get adminAnalysisTotalWinners => 'الفائزون المختارون';

  @override
  String get adminAnalysisGrowthTrend => 'نمو المشاركة (آخر 7 أيام)';

  @override
  String get adminAnalysisCouldNotLoad => 'تعذّر تحميل التحليلات.';

  @override
  String get adminAnalysisNoData => 'لا توجد سحوبات بعد — أنشئ واحدًا لعرض التحليلات هنا.';

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
  String get failurePhoneAlreadyRegisteredElsewhere => 'رقم الهاتف هذا مسجّل بالفعل على جهاز آخر.';

  @override
  String get failurePhoneAlreadyInUse => 'رقم الهاتف هذا مستخدم بالفعل من قبل حساب آخر.';

  @override
  String get failureDuplicateParticipation => 'لقد شاركت بالفعل في هذا السحب.';

  @override
  String get failureGiveawayFull => 'وصل هذا السحب إلى الحد الأقصى للمشاركين.';

  @override
  String get failureGiveawayEnded => 'لم يعد هذا السحب نشطاً.';

  @override
  String get failureRateLimited => 'محاولات كثيرة جداً. يرجى الانتظار قليلاً ثم المحاولة مرة أخرى.';

  @override
  String get settingsEditProfile => 'تعديل الملف الشخصي';

  @override
  String get editProfileTitle => 'تعديل الملف الشخصي';

  @override
  String get editProfileSubtitle => 'حافظ على تحديث اسمك ورقم هاتفك.';

  @override
  String get editProfileSaveAction => 'حفظ التغييرات';

  @override
  String get editProfileUpdateSuccess => 'تم تحديث الملف الشخصي';

  @override
  String get browseAll => 'الكل';

  @override
  String get browseClearSearch => 'مسح البحث';

  @override
  String get browseUpcoming => 'قريبًا';

  @override
  String get browseEndingSoon => 'تنتهي قريبًا';

  @override
  String get browseStartsIn => 'تبدأ';

  @override
  String get browseDayShort => 'ي';

  @override
  String get browseHourShort => 'س متبقية';

  @override
  String get browseJoined => 'مشارك';

  @override
  String get browseNoGiveaways => 'لم يتم العثور على مسابقات';

  @override
  String get browseSearchResults => 'نتائج البحث';

  @override
  String get browseLoadMore => 'تحميل المزيد';

  @override
  String get browseCategoriesRetry => 'إعادة تحميل الفئات';

  @override
  String browseUpcomingMessage(String date) {
    return 'تبدأ في $date. تتاح المشاركة في الموعد المحدد.';
  }

  @override
  String get categoryManagement => 'إدارة الفئات';

  @override
  String get categoryCreate => 'إنشاء فئة';

  @override
  String get categoryEdit => 'تعديل الفئة';

  @override
  String get categorySelect => 'اختر الفئة';

  @override
  String get categoryNameEn => 'الاسم بالإنجليزية';

  @override
  String get categoryNameAr => 'الاسم بالعربية';

  @override
  String get categoryIcon => 'رمز تعبيري اختياري';

  @override
  String get categoryOrder => 'ترتيب العرض';

  @override
  String get categoryEnabled => 'مفعّلة';

  @override
  String get categoryDisabled => 'معطّلة';

  @override
  String get categoryRequired => 'أدخل قيمة صحيحة';

  @override
  String get categorySave => 'حفظ';

  @override
  String get categoryUnauthorized => 'إدارة الفئات تتطلب صلاحية المشرف العام.';

  @override
  String get categoryUncategorized => 'بدون فئة';

  @override
  String get categoryInactiveKept => 'تُحفظ الفئة الحالية غير النشطة حتى تختار بديلًا.';

  @override
  String get categoryEditGiveaway => 'تعديل المسابقة';

  @override
  String get scheduleStartTime => 'وقت البداية';

  @override
  String get scheduleLocalTime =>
      'تُعرض الأوقات بالتوقيت المحلي للجهاز وتُحفظ بالتوقيت العالمي UTC.';

  @override
  String get adsPrivacyChoices => 'خيارات خصوصية الإعلانات';

  @override
  String get scheduleInvalidDates => 'يجب أن يكون وقت الانتهاء بعد وقت البدء.';

  @override
  String get adminDashboardScheduleSection => 'جدول المسابقات';

  @override
  String get adminFilterAll => 'الكل';

  @override
  String get adminNoFilteredGiveaways => 'لا توجد مسابقات ضمن هذه المجموعة حاليًا.';

  @override
  String get createGiveawayEditTitle => 'تعديل المسابقة';

  @override
  String get adminScheduleEditLocked =>
      'لا يمكن تغيير الموعد بعد بدء المسابقة أو تسجيل مشاركين فيها.';

  @override
  String get rewardFrameDialogTitle => 'اجعل مشاركتك مميزة!';

  @override
  String get rewardFrameDialogDescription =>
      'شاهد إعلانًا واحصل على إطار مميز لرقم مشاركتك داخل التطبيق.';

  @override
  String get rewardFrameWatchAd => 'Watch Ad';
}
