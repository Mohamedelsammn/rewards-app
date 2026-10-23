// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'كريتيف ريواردز';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get commonDone => 'تم';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonSeeAll => 'عرض الكل';

  @override
  String get commonCopy => 'نسخ';

  @override
  String get commonCopied => 'تم النسخ';

  @override
  String get commonLoadMore => 'تحميل المزيد';

  @override
  String get commonLoading => 'جارٍ التحميل';

  @override
  String get commonGotIt => 'حسنًا';

  @override
  String get refreshFailed => 'تعذّر التحديث. يتم عرض آخر محتوى تم تحميله.';

  @override
  String pointsAmount(String points) {
    return '$points PTS';
  }

  @override
  String onboardingStep(int step, int total) {
    return 'الخطوة $step من $total';
  }

  @override
  String errorReference(String id) {
    return 'المرجع: $id';
  }

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get errUnknown => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errServer => 'الخدمة تواجه مشكلة. حاول مرة أخرى بعد قليل.';

  @override
  String get errNetwork => 'لا يوجد اتصال بالإنترنت. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get errTimeout => 'استغرق الطلب وقتًا طويلًا. حاول مرة أخرى.';

  @override
  String get errInvalidCredentials => 'البريد أو كلمة المرور غير صحيحة';

  @override
  String get errSessionExpired => 'انتهت جلستك. سجّل الدخول مرة أخرى.';

  @override
  String get errAccountSuspended => 'هذا الحساب موقوف. تواصل مع الدعم للمساعدة.';

  @override
  String get errFeatureDisabled => 'هذه الميزة غير متاحة حاليًا.';

  @override
  String get errNotFound => 'هذا العنصر لم يعد متاحًا.';

  @override
  String get errEmailTaken => 'هذا البريد مسجل بالفعل.';

  @override
  String get errInsufficientPoints => 'نقاطك غير كافية لهذه المكافأة.';

  @override
  String get errOutOfStock => 'نفدت كمية هذه المكافأة.';

  @override
  String get errPriceChanged => 'تغيّر سعر هذه المكافأة.';

  @override
  String get errInvalidTransition => 'لم يعد بالإمكان تعديل هذا الطلب.';

  @override
  String get errRequestInProgress => 'طلبك قيد المعالجة. يرجى الانتظار.';

  @override
  String get errPreviousAttemptUncertain =>
      'تعذّر تأكيد طلبك السابق. تحقّق من «طلباتي» قبل الإرسال مرة أخرى.';

  @override
  String get errGiveawayNotStarted => 'لم يبدأ هذا السحب بعد.';

  @override
  String get errGiveawayEnded => 'انتهى هذا السحب.';

  @override
  String get errGiveawayNotActive => 'هذا السحب غير متاح حاليًا.';

  @override
  String get errGiveawayFull => 'اكتمل عدد المشاركين في هذا السحب.';

  @override
  String get errStepsIncomplete => 'أكمل الخطوات المطلوبة أولًا.';

  @override
  String get errClaimNotAllowed => 'لم يعد بالإمكان المطالبة بهذه الجائزة.';

  @override
  String get errValidation => 'تحقق من البيانات التي أدخلتها.';

  @override
  String get errOtpInvalid => 'الرمز غير صحيح.';

  @override
  String get errOtpExpired => 'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.';

  @override
  String get errOtpAttemptsExceeded => 'محاولات خاطئة كثيرة. اطلب رمزًا جديدًا.';

  @override
  String get errOtpVerificationInvalid => 'انتهى التحقق من بريدك. يرجى البدء من جديد.';

  @override
  String errOtpResendCooldown(int seconds) {
    return 'انتظر $seconds ثانية قبل طلب رمز آخر.';
  }

  @override
  String get errOtpSendLimit => 'تم طلب رموز كثيرة. حاول لاحقًا.';

  @override
  String get errOtpLocked => 'التحقق مقفل مؤقتًا. حاول بعد ساعة أو سجّل الدخول بكلمة المرور.';

  @override
  String get errEmailNotConfigured => 'إرسال البريد غير متاح حاليًا. حاول لاحقًا.';

  @override
  String get errInvalidPassword => 'كلمة المرور غير صحيحة.';

  @override
  String get errInvalidAvatar => 'اختر شخصية أخرى.';

  @override
  String get errProofRequired => 'أضف إثباتًا قصيرًا لإرسال هذه الخطوة.';

  @override
  String get errRateLimited => 'محاولات كثيرة. انتظر قليلًا.';

  @override
  String get errDailyLimit => 'وصلت إلى حد اليوم. عد غدًا.';

  @override
  String get errDeviceLimit => 'وصل هذا الجهاز إلى حد اليوم.';

  @override
  String errCooldown(int seconds) {
    return 'انتظر $seconds ثانية قبل الإعلان التالي.';
  }

  @override
  String get errTooManyPending => 'لديك مكافآت فيديو غير مكتملة. حاول بعد بضع دقائق.';

  @override
  String get errAdSessionNotFound => 'لم يتم العثور على هذه المكافأة. لم تُضف أي نقاط.';

  @override
  String get errAdSessionNotOwned => 'هذه المكافأة تخص حسابًا آخر.';

  @override
  String get errAccountInactive => 'لا يمكن لحسابك كسب المكافآت حاليًا.';

  @override
  String get errAdUnitNotAllowed => 'الفيديو بمكافأة غير متاح حاليًا. لم تُضف أي نقاط.';

  @override
  String get errNumberAllocation => 'تعذر تخصيص رقمك. حاول مرة أخرى.';

  @override
  String get errInvalidCursor => 'تغيّرت القائمة. اسحب للتحديث.';

  @override
  String get splashTagline => 'العب · شارك · استمتع';

  @override
  String get maintenanceTitle => 'سنعود قريبًا';

  @override
  String get maintenanceBody => 'كريتيف ريواردز قيد الصيانة. حاول مرة أخرى قريبًا.';

  @override
  String get updateTitle => 'التحديث مطلوب';

  @override
  String get updateBody => 'يرجى تحديث كريتيف ريواردز لمتابعة استخدامه.';

  @override
  String get updateButton => 'حدّث الآن';

  @override
  String get offlineTitle => 'تعذر الاتصال';

  @override
  String get offlineBody => 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';

  @override
  String get serviceUnavailableTitle => 'الخدمة غير متصلة';

  @override
  String get serviceUnavailableBody => 'كريتيف ريواردز غير متاح حتى يتم توصيل الخدمة.';

  @override
  String get serviceInsecureBody => 'لا يمكن لهذا الإصدار استخدام اتصال غير آمن.';

  @override
  String get welcomeTitleTop => 'رحلتك مع المكافآت';

  @override
  String get welcomeTitleBottom => 'تبدأ هنا';

  @override
  String get welcomeSubtitle => 'برنامج ولاء ومسابقات مجانية بسهولة.';

  @override
  String get welcomeGetStarted => 'ابدأ الآن';

  @override
  String get welcomeHaveAccount => 'لديك حساب؟ ';

  @override
  String get welcomeLogin => 'سجّل الدخول';

  @override
  String get authInvalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get emailTitleStart => 'ما بريدك ';

  @override
  String get emailTitleAccent => 'الإلكتروني؟';

  @override
  String get emailSubtitle => 'سنرسل رمز تحقق لتأكيد حسابك.';

  @override
  String get emailSendCode => 'أرسل الرمز';

  @override
  String get emailLoginInstead => 'لديك حساب؟ سجّل الدخول';

  @override
  String get otpTitleStart => 'تحقق من ';

  @override
  String get otpTitleAccent => 'بريدك';

  @override
  String get otpSentTo => 'أرسلنا رمزًا من ٦ أرقام إلى';

  @override
  String otpResendIn(String time) {
    return 'إعادة الإرسال خلال $time';
  }

  @override
  String get otpResend => 'إعادة إرسال الرمز';

  @override
  String get otpResent => 'تم إرسال رمز جديد.';

  @override
  String get otpEnterSix => 'أدخل ستة أرقام';

  @override
  String otpAttemptsLeft(int count) {
    return 'المحاولات المتبقية: $count';
  }

  @override
  String get otpSpamHint =>
      'لم يصلك الرمز؟ تحقق من البريد غير المرغوب ثم أعد الإرسال بعد انتهاء العد.';

  @override
  String get otpCodeLabel => 'رمز التحقق المكوّن من ٦ أرقام';

  @override
  String get passwordTitleStart => 'أنشئ ';

  @override
  String get passwordTitleAccent => 'كلمة مرور';

  @override
  String get passwordResetTitleStart => 'إعادة تعيين ';

  @override
  String get passwordResetTitleAccent => 'كلمة المرور';

  @override
  String get passwordSubtitle => 'اختر كلمة مرور آمنة لحسابك.';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordConfirmLabel => 'تأكيد كلمة المرور';

  @override
  String get passwordRuleLength => '٨ أحرف على الأقل';

  @override
  String get passwordRuleLettersNumbers => 'حروف وأرقام';

  @override
  String get passwordRuleStrong => 'استخدم كلمة مرور قوية';

  @override
  String get passwordTooWeak => 'استخدم ١٠ أحرف أو أكثر مع أحرف كبيرة وصغيرة وأرقام';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordSave => 'حفظ كلمة المرور';

  @override
  String get passwordResetDone => 'تم تحديث كلمة المرور. سجّل الدخول بكلمة المرور الجديدة.';

  @override
  String get characterTitle => 'اختر شخصيتك';

  @override
  String get characterSubtitle => 'اختر شخصية تمثلك في التطبيق.';

  @override
  String characterOption(int number) {
    return 'الشخصية $number';
  }

  @override
  String get loginTitle => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لمتابعة رحلتك مع المكافآت.';

  @override
  String get loginEmailHint => 'البريد الإلكتروني';

  @override
  String get loginPasswordHint => 'كلمة المرور';

  @override
  String get loginForgot => 'نسيت كلمة المرور؟';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginBusy => 'جارٍ الدخول...';

  @override
  String get loginInvalidInput => 'أدخل بريدًا إلكترونيًا وكلمة مرور صالحين';

  @override
  String get loginEnterEmailFirst => 'أدخل بريدك أولًا';

  @override
  String get loginCreateAccount => 'جديد هنا؟ أنشئ حسابًا';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCategories => 'الفئات';

  @override
  String get navWallet => 'المحفظة';

  @override
  String get navProfile => 'الملف';

  @override
  String get notificationsTooltip => 'الإشعارات';

  @override
  String get homeYourPoints => 'نقاطك';

  @override
  String get homeSearchHint => 'ابحث عن المكافآت والسحوبات...';

  @override
  String get homeAvailableRewards => 'المكافآت المتاحة';

  @override
  String get homeFeaturedRewards => 'مكافآت مميزة';

  @override
  String get homeGiveaways => 'السحوبات';

  @override
  String get homeNoResults => 'لم يتم العثور على مكافآت';

  @override
  String get homeNoResultsBody => 'جرّب اسمًا آخر أو تحقّق من الكتابة.';

  @override
  String get homeEmpty => 'مكافآت جديدة في الطريق. عد قريبًا.';

  @override
  String get homeEmptyTitle => 'المكافآت في الطريق';

  @override
  String get homeEmptyBody => 'نجهّز لك مكافآت وسحوبات جديدة. اسحب للتحديث أو عد قريبًا.';

  @override
  String get homeClearSearch => 'مسح البحث';

  @override
  String get giveawayAvailable => 'متاح';

  @override
  String get giveawayUpcoming => 'قريبًا';

  @override
  String get giveawayEnded => 'انتهى';

  @override
  String get giveawayWinnersSelected => 'تم إعلان الفائزين';

  @override
  String get giveawayCancelled => 'أُلغي';

  @override
  String giveawayEndsOn(String date) {
    return 'ينتهي $date';
  }

  @override
  String giveawayStartsOn(String date) {
    return 'يبدأ $date';
  }

  @override
  String giveawayParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مشارك',
      many: '$count مشاركًا',
      few: '$count مشاركين',
      two: 'مشاركان',
      one: 'مشارك واحد',
      zero: 'لا مشاركين بعد',
    );
    return '$_temp0';
  }

  @override
  String get categoriesTitle => 'الفئات';

  @override
  String get categoriesEmpty => 'لا توجد فئات بعد. عد قريبًا.';

  @override
  String get categoriesEmptyTitle => 'لا توجد فئات بعد';

  @override
  String get categoriesEmptyBody => 'ستظهر فئات المكافآت هنا فور إضافتها.';

  @override
  String get categoryProductsEmpty => 'لا توجد مكافآت في هذه الفئة بعد.';

  @override
  String get productTabTopUps => 'شحن الشدات';

  @override
  String get productTabItemsSkins => 'العناصر والسكنات';

  @override
  String get productTopUpsEmpty => 'لا توجد عمليات شحن متاحة بعد.';

  @override
  String get productItemsSkinsEmpty => 'لا توجد عناصر أو سكنات متاحة بعد.';

  @override
  String get productRedeem => 'استبدل';

  @override
  String get productOutOfStock => 'نفدت الكمية';

  @override
  String get redeemTitle => 'تفاصيل الاستبدال';

  @override
  String redeemBalanceLine(String balance, String after) {
    return 'الرصيد: $balance PTS  •  بعد الاستبدال: $after PTS';
  }

  @override
  String get redeemConfirm => 'تأكيد الاستبدال';

  @override
  String get redeemReviewTitle => 'تحقّق من بياناتك';

  @override
  String redeemReviewBody(String product, String points) {
    return 'سيتم إرسال $product مقابل $points إلى:';
  }

  @override
  String get redeemReviewEdit => 'تعديل';

  @override
  String get redeemAccountDetailsMissing =>
      'لا يمكن استبدال هذه المكافأة حاليًا: بيانات الحساب المطلوبة غير مُعدّة بعد. حاول لاحقًا.';

  @override
  String get redeemFieldRequired => 'هذا الحقل مطلوب';

  @override
  String redeemFieldInvalid(String label) {
    return 'تحقق من صيغة $label';
  }

  @override
  String get redeemInvalidNumber => 'استخدم الأرقام فقط';

  @override
  String get redeemInvalidUrl => 'أدخل رابطًا صالحًا';

  @override
  String get redeemInvalidPhone => 'أدخل رقم هاتف صالحًا';

  @override
  String get redeemInvalidOption => 'اختر أحد الخيارات';

  @override
  String get redeemSelectHint => 'اختر خيارًا';

  @override
  String get redeemPrivacyNote => 'لن نطلب منك أبدًا كلمات المرور أو رموز التحقق.';

  @override
  String get redeemPointsNote => 'تُخصم النقاط عند التأكيد وتُعاد إذا تعذر إكمال الطلب.';

  @override
  String get redeemSuccessTitle => 'تم إرسال الطلب';

  @override
  String redeemSuccessBody(String points) {
    return 'تم خصم $points PTS. تابع طلبك في طلباتي.';
  }

  @override
  String get redeemViewOrders => 'عرض طلباتي';

  @override
  String get redeemInsufficientTitle => 'النقاط غير كافية';

  @override
  String get redeemInsufficientTitleCaps => 'النقاط غير كافية';

  @override
  String redeemInsufficientBody(String balance, String required) {
    return 'لديك $balance PTS. تحتاج هذه المكافأة إلى $required PTS.';
  }

  @override
  String get redeemInsufficientMessage => 'تحتاج إلى نقاط أكثر لاستبدال هذه المكافأة.';

  @override
  String get redeemYourBalance => 'رصيدك';

  @override
  String get redeemRequired => 'المطلوب';

  @override
  String get redeemMissing => 'المتبقي';

  @override
  String get redeemEarnPoints => 'اكسب نقاطًا';

  @override
  String get redeemPriceChangedTitle => 'تغيّر السعر';

  @override
  String redeemPriceChangedBody(String points) {
    return 'أصبحت تكلفة هذه المكافأة $points PTS. هل تريد المتابعة؟';
  }

  @override
  String redeemConfirmNewPrice(String points) {
    return 'استبدل مقابل $points PTS';
  }

  @override
  String get walletTitle => 'مكافآتك';

  @override
  String get walletPoints => 'النقاط';

  @override
  String get walletBalance => 'الرصيد';

  @override
  String get walletFastEarn => 'اكسب تذاكر';

  @override
  String get walletPlaceOrder => 'تصفح المكافآت';

  @override
  String get walletPlaceOrderSubtitle => 'تصفح المكافآت لاستبدالها';

  @override
  String get walletReview => 'اكتب تقييمًا';

  @override
  String get walletReviewSubtitle => 'افتح صفحة التطبيق في المتجر';

  @override
  String get walletReviewUnavailable => 'صفحة المتجر غير متاحة';

  @override
  String get walletRefer => 'ادع صديقًا';

  @override
  String get walletReferSubtitle => 'شارك التطبيق مع أصدقائك';

  @override
  String get walletHistory => 'سجل النقاط';

  @override
  String get walletHistorySubtitle => 'النقاط المكتسبة والمستخدمة والمستردة';

  @override
  String get transactionsTitle => 'سجل النقاط';

  @override
  String get transactionsSubtitle => 'كل تغيير في رصيدك';

  @override
  String get transactionsEmpty => 'لا يوجد نشاط للنقاط بعد';

  @override
  String get txSignupBonus => 'مكافأة الترحيب';

  @override
  String get txAdReward => 'إعلان بمكافأة';

  @override
  String get txRedemption => 'استبدال مكافأة';

  @override
  String get txRefund => 'استرداد';

  @override
  String get txAdminCredit => 'نقاط مضافة';

  @override
  String get txAdminDebit => 'تعديل النقاط';

  @override
  String get txOther => 'تحديث الرصيد';

  @override
  String txBalanceAfter(String points) {
    return 'الرصيد $points PTS';
  }

  @override
  String get earnTitle => 'اكسب تذاكر';

  @override
  String get earnHeadline => 'شاهد واجمع تذاكر';

  @override
  String earnBody(int points) {
    return 'شاهد فيديو قصيرًا لتجمع $points تذكرة. التذاكر للاستخدام داخل التطبيق فقط ولا يمكن استبدالها بمنتجات أو تحويلها إلى نقاط.';
  }

  @override
  String earnRemaining(int count) {
    return 'المتبقي اليوم: $count';
  }

  @override
  String get earnWatch => 'شاهد الإعلان';

  @override
  String get earnVerifying => 'جارٍ التحقق من مكافأتك…';

  @override
  String earnCredited(String points) {
    return 'تمت إضافة $points تذكرة';
  }

  @override
  String get earnRejected => 'لم تُحتسب هذه المشاهدة.';

  @override
  String get earnExpired => 'انتهت جلسة المكافأة. حاول مرة أخرى.';

  @override
  String get earnPendingLong => 'تعذّر تأكيد مكافأتك بعد. اضغط تحقق مرة أخرى.';

  @override
  String get earnCheckAgain => 'تحقق مرة أخرى';

  @override
  String get earnDismissedEarly => 'شاهد الفيديو كاملًا لتحصل على التذاكر.';

  @override
  String get earnAdFailed => 'لا يتوفر فيديو حاليًا. حاول لاحقًا.';

  @override
  String get earnUnavailable => 'جمع التذاكر عبر الفيديو قريبًا';

  @override
  String get earnUnavailableBody => 'سنخبرك عندما يصبح بإمكانك جمع التذاكر بمشاهدة الفيديو.';

  @override
  String earnCooldown(String time) {
    return 'الفيديو التالي متاح خلال $time';
  }

  @override
  String get earnDailyLimit => 'وصلت إلى حد اليوم. عد غدًا.';

  @override
  String get earnUnsupported => 'الفيديو بمكافأة متاح على أندرويد.';

  @override
  String get joinAdTitle => 'شاهد إعلانًا للمشاركة';

  @override
  String get joinAdBody => 'يجب مشاهدة إعلان قصير قبل إكمال المشاركة في هذا السحب.';

  @override
  String get joinAdWatch => 'مشاهدة الإعلان';

  @override
  String get joinAdSkipped => 'شاهد الفيديو كاملًا للمشاركة.';

  @override
  String get joinAdFailed => 'تعذّر عرض الفيديو. حاول مرة أخرى.';

  @override
  String get referTitle => 'ادع صديقًا';

  @override
  String get referHeadline => 'ادع أصدقاءك إلى كريتيف ريواردز';

  @override
  String get referBody => 'شارك رابط التطبيق مع أصدقائك. مكافآت الإحالة غير متاحة بعد.';

  @override
  String get referCopy => 'نسخ رابط التطبيق';

  @override
  String get referCopied => 'تم نسخ الرابط';

  @override
  String get profilePoints => 'نقاط';

  @override
  String get profileGiveaways => 'سحوبات';

  @override
  String get profileOrders => 'طلبات';

  @override
  String get profileMyGiveaways => 'سحوباتي';

  @override
  String get profileMyOrders => 'طلباتي';

  @override
  String get profileNotifications => 'الإشعارات';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileSettings => 'إعدادات الحساب';

  @override
  String get profileAbout => 'حول التطبيق';

  @override
  String get profilePrivacy => 'سياسة الخصوصية';

  @override
  String get profileTerms => 'الشروط والأحكام';

  @override
  String get profileSignOut => 'تسجيل الخروج';

  @override
  String get profileEditTooltip => 'تعديل الملف';

  @override
  String get signOutTitle => 'تسجيل الخروج؟';

  @override
  String get signOutMessage => 'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟';

  @override
  String get languageTitle => 'اختر اللغة';

  @override
  String get editProfileTitle => 'تعديل الملف';

  @override
  String get editProfileName => 'الاسم الظاهر';

  @override
  String get editProfileNameInvalid => 'استخدم من ٢ إلى ٦٠ حرفًا';

  @override
  String get editProfileSaved => 'تم تحديث الملف';

  @override
  String get settingsTitle => 'إعدادات الحساب';

  @override
  String get settingsSubtitle => 'الأمان والتفضيلات';

  @override
  String get settingsChangePassword => 'تغيير كلمة المرور';

  @override
  String get settingsSessions => 'الأجهزة المسجّل دخولها';

  @override
  String get settingsNotifications => 'تفضيلات الإشعارات';

  @override
  String get settingsAdPrivacy => 'خيارات خصوصية الإعلانات';

  @override
  String get settingsDeleteAccount => 'حذف الحساب';

  @override
  String settingsVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get changePasswordCurrent => 'كلمة المرور الحالية';

  @override
  String get changePasswordNew => 'كلمة المرور الجديدة';

  @override
  String get changePasswordDone => 'تم تغيير كلمة المرور. تم تسجيل الخروج من الأجهزة الأخرى.';

  @override
  String get sessionsTitle => 'الأجهزة المسجّل دخولها';

  @override
  String get sessionsSubtitle => 'الأجهزة المسجّل دخولها إلى حسابك';

  @override
  String get sessionsCurrent => 'هذا الجهاز';

  @override
  String sessionsLastUsed(String date) {
    return 'آخر نشاط $date';
  }

  @override
  String get sessionsRevoke => 'تسجيل الخروج';

  @override
  String get sessionsRevoked => 'تم تسجيل خروج الجهاز';

  @override
  String get sessionsLogoutAll => 'تسجيل الخروج من كل الأجهزة';

  @override
  String get sessionsLogoutAllMessage =>
      'ستحتاج إلى تسجيل الدخول مجددًا على كل الأجهزة، بما فيها هذا الجهاز.';

  @override
  String get sessionsUnknownDevice => 'جهاز غير معروف';

  @override
  String get notificationPrefsTitle => 'تفضيلات الإشعارات';

  @override
  String get notificationPrefsSubtitle => 'اختر ما نُعلمك به';

  @override
  String get prefOrders => 'تحديثات الطلبات';

  @override
  String get prefOrdersSubtitle => 'المعالجة والتسليم والاسترداد';

  @override
  String get prefGiveaways => 'نتائج السحوبات';

  @override
  String get prefGiveawaysSubtitle => 'الفائزون ونتائج السحب';

  @override
  String get prefAnnouncements => 'الإعلانات';

  @override
  String get prefAnnouncementsSubtitle => 'مكافآت وعروض جديدة';

  @override
  String get deleteAccountTitle => 'حذف الحساب';

  @override
  String get deleteAccountBody =>
      'يُحذف حسابك بعد فترة سماح مدتها ١٤ يومًا. يؤدي تسجيل الدخول خلالها إلى إلغاء الطلب. تُحذف النقاط والطلبات والمشاركات مع الحساب.';

  @override
  String get deleteAccountPassword => 'أكّد بكلمة المرور';

  @override
  String get deleteAccountButton => 'احذف حسابي';

  @override
  String get deleteAccountConfirmTitle => 'حذف حسابك؟';

  @override
  String get deleteAccountConfirmMessage => 'لا يمكن التراجع عن ذلك بعد انتهاء فترة السماح.';

  @override
  String deleteAccountDone(int days) {
    return 'تم طلب الحذف. سيُحذف حسابك خلال $days يومًا.';
  }

  @override
  String get aboutTitle => 'حول التطبيق';

  @override
  String get aboutBody =>
      'يتيح لك كريتيف ريواردز استبدال النقاط بالمكافآت والمشاركة في السحوبات المجانية.';

  @override
  String get privacyTitle => 'سياسة الخصوصية';

  @override
  String get termsTitle => 'الشروط والأحكام';

  @override
  String get legalUnavailable => 'سيتوفر هذا المستند قريبًا.';

  @override
  String get legalOpen => 'فتح المستند';

  @override
  String get ordersTitle => 'طلباتي';

  @override
  String get ordersSubtitle => 'تابع طلباتك وأدرها';

  @override
  String get ordersAll => 'الكل';

  @override
  String get ordersInProgress => 'قيد التنفيذ';

  @override
  String get ordersCompleted => 'مكتملة';

  @override
  String get ordersUnsuccessful => 'غير ناجحة';

  @override
  String get ordersEmpty => 'لا توجد طلبات بعد';

  @override
  String get ordersEmptyFiltered => 'لا توجد طلبات في هذه الحالة';

  @override
  String orderNumber(String number) {
    return 'طلب رقم $number';
  }

  @override
  String get orderPending => 'قيد الانتظار';

  @override
  String get orderProcessing => 'قيد المعالجة';

  @override
  String get orderShipped => 'تم الشحن';

  @override
  String get orderDelivered => 'تم التسليم';

  @override
  String get orderCompleted => 'مكتمل';

  @override
  String get orderRejected => 'مرفوض';

  @override
  String get orderCancelled => 'ملغي';

  @override
  String get orderFailed => 'فشل';

  @override
  String get orderDetailsTitle => 'تفاصيل الطلب';

  @override
  String get orderSubmittedDetails => 'بياناتك';

  @override
  String get orderDeliveredCode => 'رمزك';

  @override
  String get orderTracking => 'التتبع';

  @override
  String get orderReason => 'السبب';

  @override
  String get orderTimeline => 'سجل الحالة';

  @override
  String get orderIdLabel => 'رقم الطلب';

  @override
  String get orderCost => 'التكلفة';

  @override
  String get orderStatusTitle => 'الحالة';

  @override
  String get orderAccountDetails => 'بيانات الحساب';

  @override
  String get orderStatusHistory => 'سجل الحالة';

  @override
  String get orderRedeemAgain => 'استبدال مرة أخرى';

  @override
  String get orderOpenLink => 'فتح الرابط';

  @override
  String get orderStepPending => 'تم تقديم طلبك.';

  @override
  String get orderStepProcessing => 'نعمل على تجهيز طلبك.';

  @override
  String get orderStepShipped => 'طلبك في الطريق.';

  @override
  String get orderStepDelivered => 'تم تسليم طلبك.';

  @override
  String get orderStepCompleted => 'اكتمل طلبك بنجاح.';

  @override
  String get orderStepRejected => 'تم رفض طلبك.';

  @override
  String get orderStepCancelled => 'تم إلغاء طلبك.';

  @override
  String get orderStepFailed => 'تعذّر إتمام طلبك.';

  @override
  String orderRefunded(String points) {
    return 'تمت إعادة $points PTS إلى محفظتك.';
  }

  @override
  String get orderCancel => 'إلغاء الطلب';

  @override
  String get orderCancelTitle => 'إلغاء هذا الطلب؟';

  @override
  String get orderCancelMessage => 'ستُعاد نقاطك إلى محفظتك.';

  @override
  String get orderCancelDone => 'تم إلغاء الطلب وإعادة النقاط.';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات بعد';

  @override
  String get notificationsMarkAll => 'تحديد الكل كمقروء';

  @override
  String get notifNow => 'الآن';

  @override
  String notifMinutes(int count) {
    return 'قبل $count د';
  }

  @override
  String notifHours(int count) {
    return 'قبل $count س';
  }

  @override
  String get notifYesterday => 'أمس';

  @override
  String get notifEarlier => 'سابقًا';

  @override
  String get notificationOpen => 'فتح';

  @override
  String get giveawaysTitle => 'السحوبات';

  @override
  String get giveawaysSubtitle => 'شارك في سحوبات مجانية واربح جوائز';

  @override
  String get giveawaysEmpty => 'لا توجد سحوبات هنا بعد';

  @override
  String get giveawayDetailsTitle => 'تفاصيل السحب';

  @override
  String get giveawayBadge => 'سحب';

  @override
  String get giveawayBadgeActive => 'نشط';

  @override
  String get giveawayBadgeComingSoon => 'قريبًا';

  @override
  String get giveawayBadgeEnded => 'انتهى';

  @override
  String get giveawayBadgeFull => 'مكتمل';

  @override
  String get giveawayAboutTitle => 'عن هذا السحب';

  @override
  String giveawayOrganizer(String name) {
    return 'بواسطة $name';
  }

  @override
  String get giveawayPrize => 'الجائزة';

  @override
  String get giveawayRules => 'القواعد';

  @override
  String get giveawaySteps => 'خطوات المشاركة';

  @override
  String get giveawayStepOptional => 'اختياري';

  @override
  String get giveawayStepDone => 'تم';

  @override
  String get giveawayStepSubmitted => 'قيد المراجعة';

  @override
  String get giveawayStepApproved => 'مقبول';

  @override
  String get giveawayStepRejected => 'غير مقبول — حاول مرة أخرى';

  @override
  String get giveawayStepComplete => 'إكمال';

  @override
  String get giveawayStepProofTitle => 'إرسال إثبات';

  @override
  String get giveawayStepProofHint => 'اسم المستخدم أو ملاحظة قصيرة';

  @override
  String get giveawayStepSubmit => 'إرسال';

  @override
  String get giveawayJoin => 'شارك في السحب';

  @override
  String get giveawayViewTicket => 'اعرض رقمك';

  @override
  String get giveawayClosed => 'انتهى هذا السحب';

  @override
  String get giveawayFull => 'اكتمل عدد المشاركين';

  @override
  String get giveawayDisqualified => 'تم استبعاد مشاركتك';

  @override
  String get giveawayFreeNote => 'المشاركة مجانية. لا تُخصم أي نقاط.';

  @override
  String get giveawayResults => 'الفائزون';

  @override
  String giveawayWinnerRow(int rank, String number) {
    return '#$rank · الرقم $number';
  }

  @override
  String get giveawayCompleteSteps => 'أكمل الخطوات المطلوبة للمشاركة';

  @override
  String get giveawaySignInToJoin => 'سجّل الدخول للمشاركة';

  @override
  String get ticketTitle => 'تذكرتك';

  @override
  String get ticketPreparing => 'جارٍ تجهيز تذكرتك…';

  @override
  String get ticketCopy => 'نسخ التذكرة';

  @override
  String get ticketCopied => 'تم نسخ رقم التذكرة';

  @override
  String get ticketNote => 'احتفظ بهذا الرقم. يُعلن الفائزون بعد انتهاء السحب.';

  @override
  String get myGiveawaysTitle => 'سحوباتي';

  @override
  String get myGiveawaysSubtitle => 'تعرّف على السحوبات التي شاركت فيها';

  @override
  String get myGiveawaysEmpty => 'لم تشارك في أي سحب بعد';

  @override
  String get resultAll => 'الكل';

  @override
  String get resultPending => 'بانتظار السحب';

  @override
  String get resultWon => 'لقد فزت!';

  @override
  String get resultNotSelected => 'لم يتم اختيارك';

  @override
  String get entryDisqualified => 'مستبعد';

  @override
  String get celebrationTitle => 'مبروك!';

  @override
  String celebrationBody(String prize) {
    return 'لقد فزت بـ $prize';
  }

  @override
  String celebrationNumber(String number) {
    return 'الرقم الفائز $number';
  }

  @override
  String get celebrationClaim => 'اطلب جائزتك';

  @override
  String get celebrationLater => 'لاحقًا';

  @override
  String get claimHint => 'رقم الهاتف والمدينة أو وسيلة تواصل أخرى';

  @override
  String get claimInvalid => 'أدخل من ٣ إلى ٥٠٠ حرف';

  @override
  String get claimSubmit => 'إرسال';

  @override
  String get claimDone => 'شكرًا! سنتواصل معك لتسليم جائزتك.';

  @override
  String claimDeadline(String date) {
    return 'اطلبها قبل $date';
  }

  @override
  String walletTickets(int count) {
    return 'تذاكرك: $count (غير قابلة للاستبدال)';
  }
}
