import '../../../core/config/app_config.dart';

/// One titled section of a legal document.
class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}

/// Real Privacy Policy / Terms & Conditions copy for this app, in English
/// and Arabic. Not routed through the ARB pipeline: legal text this long
/// doesn't belong as flat ARB entries, but it is still real, locale-specific
/// content selected by the active app locale (see the two legal pages),
/// which is what the localization requirement is actually after -- no
/// English leaking into the Arabic reading of these two screens.
///
/// [AppConfig.contactEmail] / [AppConfig.dataDeletionUrl] are placeholders
/// (see that file's doc comment) interpolated directly into the copy below;
/// nothing here names a real company, address, or jurisdiction, per the
/// explicit instruction not to invent a legal entity.
class LegalContent {
  const LegalContent._();

  static List<LegalSection> privacyPolicy(String languageCode) =>
      languageCode == 'ar' ? _privacyAr : _privacyEn;

  static List<LegalSection> termsConditions(String languageCode) =>
      languageCode == 'ar' ? _termsAr : _termsEn;

  static final _privacyEn = <LegalSection>[
    const LegalSection(
      'Overview',
      'This Privacy Policy explains what information the Reward Giveaway app '
          'collects, why it is collected, and how it is used. By using the app '
          'you agree to the practices described here.',
    ),
    const LegalSection(
      'Information We Collect',
      'When you register as a participant, we collect your full name, '
          'country, and phone number. Your phone number is used to prevent the '
          'same person from entering a single giveaway more than once and is '
          'never shown publicly. We also store a device identifier and, if you '
          'allow notifications, a push-notification token, so we can tell you '
          'when a giveaway you joined has a winner. When you take part in a '
          'giveaway we record your participation number and timestamp. This '
          'version of the app contains no advertising or ad-tracking SDKs, so '
          'no advertising identifiers or ad-interaction data are collected.',
    ),
    const LegalSection(
      'How We Use Your Information',
      'We use the information above to operate giveaways: creating your '
          'participant record, generating and displaying your participation '
          'number, selecting and announcing winners, and sending you '
          'notifications about giveaways you have joined. We do not use your '
          'information for advertising, and we do not sell it to third '
          'parties.',
    ),
    const LegalSection(
      'How Your Identity Is Kept',
      'The app uses an anonymous, device-scoped session to connect your '
          'device to your participant record, secured by server-side access '
          'rules so that only your device can read or act on your own data. A '
          'small identity cache (your name and an internal identifier) is '
          'stored securely on your device so you do not need to re-register '
          'every time you open the app.',
    ),
    const LegalSection(
      'Sharing With Service Providers',
      'We use Supabase to host our database, authentication, file storage, '
          'and server-side functions, and (once configured) Firebase Cloud '
          'Messaging to deliver push notifications. These providers process '
          'data on our behalf under their own security and privacy commitments '
          'and do not use your data for their own purposes. We do not share '
          'your information with advertisers or data brokers.',
    ),
    const LegalSection(
      'Data Retention',
      'We keep your participant record and participation history for as '
          'long as it is needed to operate the giveaways you have joined and '
          'to prevent fraud, or until you request deletion.',
    ),
    LegalSection(
      'Your Rights',
      'You can request access to, correction of, or deletion of your data '
          '${AppConfig.hasDataDeletionUrl ? 'at ${AppConfig.dataDeletionUrl} or ' : ''}'
          'by emailing ${AppConfig.contactEmail}. We will respond within a '
          'reasonable time and delete data we are not legally required to '
          'keep.',
    ),
    const LegalSection(
      "Children's Privacy",
      'The app is not directed at children and we do not knowingly collect '
          'personal information from children. If you believe a child has '
          'provided us with personal information, please contact us so we can '
          'remove it.',
    ),
    const LegalSection(
      'Security',
      'We apply industry-standard safeguards, including server-side access '
          'rules that restrict every record to the device and account it '
          'belongs to, and encrypted storage for your locally cached identity. '
          'No method of transmission or storage is perfectly secure, so we '
          'cannot guarantee absolute security.',
    ),
    LegalSection(
      'Changes to This Policy',
      'We may update this policy from time to time; the date at the top of '
          'this screen reflects the most recent revision. Material changes '
          'will be highlighted in the app.'
          '${AppConfig.hasPrivacyPolicyUrl ? ' The latest version is always available at ${AppConfig.privacyPolicyUrl}.' : ''}',
    ),
    LegalSection(
      'Contact Us',
      'Questions about this policy can be sent to ${AppConfig.contactEmail}.',
    ),
  ];

  static final _privacyAr = <LegalSection>[
    const LegalSection(
      'نظرة عامة',
      'توضح سياسة الخصوصية هذه ما هي المعلومات التي يجمعها تطبيق Reward '
          'Giveaway، ولماذا يتم جمعها، وكيفية استخدامها. باستخدامك للتطبيق فإنك '
          'توافق على الممارسات الموضحة هنا.',
    ),
    const LegalSection(
      'المعلومات التي نجمعها',
      'عند التسجيل كمشارك، نقوم بجمع اسمك الكامل ودولتك ورقم هاتفك. يُستخدم '
          'رقم هاتفك لمنع الشخص نفسه من المشاركة في نفس السحب أكثر من مرة، ولا '
          'يُعرض علنًا أبدًا. كما نخزّن معرّف الجهاز، وإذا سمحت بالإشعارات، رمز '
          'إشعارات الدفع (push token)، حتى نتمكن من إعلامك عند وجود فائز في '
          'سحب انضممت إليه. عند مشاركتك في سحب، نسجّل رقم مشاركتك وتوقيت '
          'إنشائها. لا تحتوي هذه النسخة من التطبيق على أي حزم إعلانات أو تتبع '
          'إعلاني، لذلك لا يتم جمع أي معرّفات إعلانية أو بيانات تفاعل إعلاني.',
    ),
    const LegalSection(
      'كيفية استخدام معلوماتك',
      'نستخدم المعلومات المذكورة أعلاه لتشغيل السحوبات: إنشاء سجل المشارك '
          'الخاص بك، وإنشاء وعرض رقم مشاركتك، واختيار الفائزين والإعلان عنهم، '
          'وإرسال إشعارات لك بخصوص السحوبات التي انضممت إليها. لا نستخدم '
          'معلوماتك لأغراض إعلانية، ولا نبيعها لأي طرف ثالث.',
    ),
    const LegalSection(
      'كيفية الحفاظ على هويتك',
      'يستخدم التطبيق جلسة مجهولة مرتبطة بالجهاز لربط جهازك بسجل مشاركتك، '
          'ويتم تأمينها بقواعد وصول من جانب الخادم بحيث لا يمكن لأي جهاز غير '
          'جهازك قراءة بياناتك أو التصرف بها. كما يتم تخزين نسخة صغيرة من '
          'هويتك (اسمك ومعرّف داخلي) بشكل آمن على جهازك حتى لا تحتاج لإعادة '
          'التسجيل في كل مرة تفتح فيها التطبيق.',
    ),
    const LegalSection(
      'المشاركة مع مزوّدي الخدمة',
      'نستخدم Supabase لاستضافة قاعدة بياناتنا ونظام المصادقة وتخزين الملفات '
          'والدوال الخادمية، وعند تفعيله، نستخدم Firebase Cloud Messaging '
          'لإرسال الإشعارات. يعالج هؤلاء المزوّدون البيانات نيابة عنا بموجب '
          'التزاماتهم الخاصة بالأمان والخصوصية، ولا يستخدمون بياناتك لأغراضهم '
          'الخاصة. لا نشارك معلوماتك مع المعلنين أو وسطاء البيانات.',
    ),
    const LegalSection(
      'الاحتفاظ بالبيانات',
      'نحتفظ بسجل مشاركتك وتاريخ مشاركاتك طالما كان ذلك ضروريًا لتشغيل '
          'السحوبات التي انضممت إليها ومنع الاحتيال، أو حتى تطلب حذفها.',
    ),
    LegalSection(
      'حقوقك',
      'يمكنك طلب الوصول إلى بياناتك أو تصحيحها أو حذفها '
          '${AppConfig.hasDataDeletionUrl ? 'عبر ${AppConfig.dataDeletionUrl} أو ' : ''}'
          'عبر مراسلتنا على ${AppConfig.contactEmail}. سنرد خلال وقت معقول '
          'ونحذف البيانات التي لسنا ملزمين قانونًا بالاحتفاظ بها.',
    ),
    const LegalSection(
      'خصوصية الأطفال',
      'التطبيق غير موجّه للأطفال، ولا نقوم عن قصد بجمع معلومات شخصية من '
          'الأطفال. إذا كنت تعتقد أن طفلاً قد زوّدنا بمعلومات شخصية، يرجى '
          'التواصل معنا لإزالتها.',
    ),
    const LegalSection(
      'الأمان',
      'نطبّق إجراءات حماية بمعايير الصناعة، بما في ذلك قواعد وصول من جانب '
          'الخادم تقصر كل سجل على الجهاز والحساب الذي يخصه، وتخزين مشفّر '
          'لهويتك المخزنة محليًا. لا توجد وسيلة نقل أو تخزين آمنة بشكل مطلق، '
          'لذا لا يمكننا ضمان الأمان الكامل.',
    ),
    LegalSection(
      'التغييرات على هذه السياسة',
      'قد نقوم بتحديث هذه السياسة من وقت لآخر؛ يعكس التاريخ أعلى هذه الشاشة '
          'آخر مراجعة. سيتم إبراز أي تغييرات جوهرية داخل التطبيق.'
          '${AppConfig.hasPrivacyPolicyUrl ? ' النسخة الأحدث متوفرة دائمًا على ${AppConfig.privacyPolicyUrl}.' : ''}',
    ),
    LegalSection(
      'تواصل معنا',
      'يمكن إرسال أي استفسارات حول هذه السياسة إلى ${AppConfig.contactEmail}.',
    ),
  ];

  static final _termsEn = <LegalSection>[
    const LegalSection(
      'Acceptance of Terms',
      'By creating a participant record or an administrator account in the '
          'Reward Giveaway app, you agree to these Terms & Conditions. If you '
          'do not agree, please do not use the app.',
    ),
    const LegalSection(
      'Eligibility',
      'You are responsible for confirming that participating in giveaways is '
          'permitted under the laws that apply to you. Each giveaway allows one '
          'entry per phone number; entries found to be duplicated, automated, '
          'or otherwise fraudulent may be removed, and no purchase is ever '
          'necessary to enter or win.',
    ),
    const LegalSection(
      'How Giveaways Work',
      'When you join an active giveaway, the app generates a unique '
          'participation number tied to your entry. When a giveaway ends, its '
          'organizer selects a winner either at random from eligible entries '
          'or manually, as described for that giveaway. Winners are announced '
          'in the app and, where enabled, by notification.',
    ),
    const LegalSection(
      'Prizes',
      'Prizes are as described in each giveaway listing and are provided at '
          'the discretion of that giveaway\'s organizer. Prize delivery, '
          'fulfillment, and any related arrangements happen outside the app '
          'and are the organizer\'s responsibility. Prizes cannot be '
          'exchanged for cash unless the listing says otherwise.',
    ),
    const LegalSection(
      'Your Conduct',
      'You agree not to create multiple identities or devices to gain extra '
          'entries, not to interfere with the fair operation of a giveaway, '
          'and not to attempt to reverse engineer, disrupt, or gain '
          'unauthorized access to the app or its backend services.',
    ),
    const LegalSection(
      'Giveaway Content',
      'Giveaways are created and described by their organizers. While we '
          'take reasonable steps to keep the platform trustworthy, we are not '
          'responsible for the accuracy of a specific giveaway\'s description '
          'or for an organizer\'s failure to deliver a prize.',
    ),
    const LegalSection(
      'Intellectual Property',
      'The app\'s design, branding, and code are protected by applicable '
          'intellectual property laws. Giveaway images and descriptions '
          'remain the property of their respective organizers.',
    ),
    const LegalSection(
      'Disclaimer & Limitation of Liability',
      'The app is provided "as is," without warranties of any kind, to the '
          'fullest extent permitted by law. We are not liable for indirect, '
          'incidental, or consequential damages arising from your use of the '
          'app or participation in a giveaway.',
    ),
    const LegalSection(
      'Suspension & Termination',
      'We may suspend or remove access for anyone found to be violating '
          'these terms, including fraudulent entries or abusive behavior '
          'toward the platform or other participants.',
    ),
    const LegalSection(
      'Changes to These Terms',
      'We may update these terms from time to time; the date at the top of '
          'this screen reflects the most recent revision. Continuing to use '
          'the app after a change means you accept the updated terms.',
    ),
    LegalSection(
      'Contact Us',
      'Questions about these terms can be sent to ${AppConfig.contactEmail}.',
    ),
  ];

  static final _termsAr = <LegalSection>[
    const LegalSection(
      'قبول الشروط',
      'بإنشائك سجل مشارك أو حساب مسؤول في تطبيق Reward Giveaway، فإنك توافق '
          'على هذه الشروط والأحكام. إذا كنت لا توافق، يرجى عدم استخدام '
          'التطبيق.',
    ),
    const LegalSection(
      'الأهلية',
      'أنت مسؤول عن التأكد من أن المشاركة في السحوبات مسموح بها بموجب '
          'القوانين المطبّقة عليك. يسمح كل سحب بمشاركة واحدة لكل رقم هاتف؛ '
          'وقد تتم إزالة المشاركات المكررة أو الآلية أو الاحتيالية، ولا يُشترط '
          'أي شراء أبدًا للمشاركة أو الفوز.',
    ),
    const LegalSection(
      'كيفية عمل السحوبات',
      'عند انضمامك إلى سحب نشط، ينشئ التطبيق رقم مشاركة فريد مرتبط بمشاركتك. '
          'عند انتهاء السحب، يختار منظّمه فائزًا إما عشوائيًا من بين المشاركات '
          'المؤهلة أو يدويًا، وفق ما هو موضّح لذلك السحب. يُعلن عن الفائزين '
          'داخل التطبيق، وعبر الإشعارات حيثما كانت مفعّلة.',
    ),
    const LegalSection(
      'الجوائز',
      'الجوائز كما هي موضّحة في تفاصيل كل سحب، وتُقدَّم وفق تقدير منظّم ذلك '
          'السحب. يتم تسليم الجائزة وأي ترتيبات متعلقة بها خارج التطبيق وتقع '
          'على مسؤولية المنظّم. لا يمكن استبدال الجوائز بمبالغ نقدية ما لم '
          'يُذكر خلاف ذلك في تفاصيل السحب.',
    ),
    const LegalSection(
      'سلوكك',
      'توافق على عدم إنشاء هويات أو أجهزة متعددة للحصول على مشاركات إضافية، '
          'وعدم التدخل في التشغيل العادل لأي سحب، وعدم محاولة الهندسة العكسية '
          'للتطبيق أو خدماته الخادمية أو تعطيلها أو الوصول غير المصرح به '
          'إليها.',
    ),
    const LegalSection(
      'محتوى السحوبات',
      'يتم إنشاء السحوبات ووصفها من قبل منظّميها. ورغم أننا نتخذ خطوات '
          'معقولة للحفاظ على موثوقية المنصة، فإننا لسنا مسؤولين عن دقة وصف '
          'سحب معين أو عن تقصير منظّمه في تسليم الجائزة.',
    ),
    const LegalSection(
      'الملكية الفكرية',
      'تصميم التطبيق وعلامته وشيفرته البرمجية محمية بموجب قوانين الملكية '
          'الفكرية المعمول بها. تبقى صور ووصف السحوبات ملكًا لمنظّميها '
          'المعنيين.',
    ),
    const LegalSection(
      'إخلاء المسؤولية وتحديدها',
      'يُقدَّم التطبيق "كما هو"، دون أي ضمانات من أي نوع، إلى أقصى حد يسمح به '
          'القانون. لسنا مسؤولين عن أي أضرار غير مباشرة أو عرضية أو تبعية '
          'ناتجة عن استخدامك للتطبيق أو مشاركتك في سحب.',
    ),
    const LegalSection(
      'التعليق والإنهاء',
      'يجوز لنا تعليق أو إزالة وصول أي شخص يثبت انتهاكه لهذه الشروط، بما في '
          'ذلك المشاركات الاحتيالية أو السلوك المسيء تجاه المنصة أو المشاركين '
          'الآخرين.',
    ),
    const LegalSection(
      'التغييرات على هذه الشروط',
      'قد نقوم بتحديث هذه الشروط من وقت لآخر؛ يعكس التاريخ أعلى هذه الشاشة '
          'آخر مراجعة. استمرارك في استخدام التطبيق بعد أي تغيير يعني موافقتك '
          'على الشروط المحدّثة.',
    ),
    LegalSection(
      'تواصل معنا',
      'يمكن إرسال أي استفسارات حول هذه الشروط إلى ${AppConfig.contactEmail}.',
    ),
  ];
}
