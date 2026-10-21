import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/locale_controller.dart';
import '../core/theme/app_icons.dart';
import 'demo_repository.dart';
import 'redemption_details_sheet.dart';

const ink = Color(0xff0c123e);
const violet = Color(0xff4824fa);
const muted = Color(0xff777eaa);
const pale = Color(0xfff6f4ff);
const designAssetRoot = 'assets/Creative_Rewards_Assets/';

String characterAsset(int id) => 'assets/img/redesign/character_${id == 1 ? '1_clean' : id}.png';

String categoryBanner(String id) =>
    '$designAssetRoot'
    '01_category_banners/category_${switch (id) {
      'battle' => 'pubg_mobile',
      'tactical' => 'valorant',
      'social' => 'instagram',
      'video' => 'tiktok',
      'community' => 'facebook',
      _ => 'phones',
    }}.png';

String categoryTile(String id) =>
    '$designAssetRoot'
    '02_home_categories/home_${switch (id) {
      'battle' => 'pubg_mobile',
      'tactical' => 'valorant',
      'social' => 'instagram',
      _ => 'tiktok',
    }}.png';

String categoryArt(String id) =>
    '$designAssetRoot'
    '08_generated_category_art/art_${switch (id) {
      'battle' => 'pubg',
      'tactical' => 'valorant',
      'social' => 'instagram',
      'video' => 'tiktok',
      'community' => 'facebook',
      _ => 'phones',
    }}.png';

String giveawayArt(String id) =>
    '$designAssetRoot'
    '04_reward_product_art/reward_${switch (id) {
      'earbuds' => 'airpods_pro',
      'smartphone' => 'iphone_15_pro',
      'console' => 'playstation_5',
      _ => 'coffee_machine',
    }}.png';

String productArt(DemoProduct product) {
  if (product.categoryId == 'battle' && product.id.startsWith('credits')) {
    return '${designAssetRoot}05_pubg_uc_packages/pubg_uc_${product.id.substring(7)}.png';
  }
  return categoryArt(product.categoryId);
}

String categoryDetailArt(String id) => switch (id) {
  'battle' => '${designAssetRoot}06_category_details/pubg_generated_banner.png',
  'tactical' => '${designAssetRoot}06_category_details/valorant_generated_banner.png',
  _ => categoryArt(id),
};

String categoryTitle(BuildContext context, DemoCategory category) =>
    tr(context, category.title, switch (category.id) {
      'battle' => 'ببجي موبايل',
      'tactical' => 'فالورانت',
      'social' => 'إنستغرام',
      'video' => 'تيك توك',
      'community' => 'فيسبوك',
      _ => 'هواتف',
    });

String categorySubtitle(BuildContext context, DemoCategory category) =>
    tr(context, category.subtitle, switch (category.id) {
      'battle' => 'شحن شدات',
      'tactical' => 'نقاط ومظاهر',
      'social' => 'متابعون وإعجابات',
      'video' => 'متابعون وتفاعل',
      'community' => 'متابعون ونمو الصفحات',
      _ => 'هواتف وملحقات',
    });

String tr(BuildContext context, String en, String ar) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

Future<void> openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

Future<void> openOnboardingPage(BuildContext context, Widget page) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final direction = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
      reverseTransitionDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final leave = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOutCubic);
        return FadeTransition(
          opacity: Tween<double>(begin: 1, end: .9).animate(leave),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: Offset(-.035 * direction, 0),
            ).animate(leave),
            child: FadeTransition(
              opacity: enter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(.055 * direction, 0),
                  end: Offset.zero,
                ).animate(enter),
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}

void replacePage(BuildContext context, Widget page) => Navigator.of(
  context,
).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => page), (_) => false);

class DemoScope extends InheritedNotifier<RewardsRepository> {
  const DemoScope({required RewardsRepository repository, required super.child, super.key})
    : super(notifier: repository);
  static RewardsRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemoScope>()!.notifier!;
}

class RedesignApp extends StatelessWidget {
  const RedesignApp({required this.repository, required this.localeController, super.key});
  final RewardsRepository repository;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: localeController,
    builder: (_, locale, _) => DemoScope(
      repository: repository,
      child: MaterialApp(
        title: 'Creative Rewards Demo',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: pale,
          fontFamily: 'Plus Jakarta Sans',
          colorScheme: ColorScheme.fromSeed(seedColor: violet, surface: pale),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: ink),
            headlineMedium: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink),
            titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink),
            bodyLarge: TextStyle(fontSize: 16, color: ink),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: .88),
            contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xffdedbfc)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xffdedbfc)),
            ),
          ),
        ),
        home: const DemoSplash(),
      ),
    ),
  );
}

class GradientButton extends StatelessWidget {
  const GradientButton(
    this.label, {
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    this.dark = false,
    this.leadingIcon = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool dark;
  final bool leadingIcon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: dark
          ? const LinearGradient(colors: [Color(0xff080b2e), Color(0xff2c075e)])
          : const LinearGradient(colors: [Color(0xff3927ff), Color(0xff6921f2)]),
      borderRadius: BorderRadius.circular(36),
      boxShadow: const [BoxShadow(color: Color(0x33552cff), blurRadius: 22, offset: Offset(0, 10))],
    ),
    child: SizedBox(
      width: double.infinity,
      height: 62,
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon) ...[Icon(icon, color: Colors.white), const SizedBox(width: 14)],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!leadingIcon) ...[const SizedBox(width: 14), Icon(icon, color: Colors.white)],
          ],
        ),
      ),
    ),
  );
}

class DemoSplash extends StatefulWidget {
  const DemoSplash({super.key});
  @override
  State<DemoSplash> createState() => _DemoSplashState();
}

class _DemoSplashState extends State<DemoSplash> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final repo = DemoScope.of(context);
    final results = await Future.wait<dynamic>([
      repo.restore(),
      Future<void>.delayed(const Duration(milliseconds: 700)),
    ]);
    if (!mounted) return;
    if (results.first == true) {
      replacePage(context, const DemoShell());
    } else if (repo.pendingEmail != null && repo.pendingStage >= 2) {
      replacePage(context, PasswordPage(email: repo.pendingEmail!));
    } else if (repo.pendingEmail != null && repo.pendingStage == 1) {
      replacePage(context, OtpPage(email: repo.pendingEmail!));
    } else {
      replacePage(context, const WelcomePage());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffe9e5ff), Color(0xffffeaf8), Color(0xffd6d8ff)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Expanded(
              flex: 5,
              child: Image.asset('assets/img/redesign/splash_hero.png', fit: BoxFit.contain),
            ),
            const Text(
              'Creative',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: ink),
            ),
            const Text(
              'Rewards',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: violet),
            ),
            Text(
              tr(context, 'Play · Earn · Redeem', 'العب · اكسب · استبدل'),
              style: const TextStyle(fontSize: 18, color: muted),
            ),
            const Spacer(),
            const SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                minHeight: 6,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
            const SizedBox(height: 55),
          ],
        ),
      ),
    ),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffede3ff), Color(0xffffe7f6), Color(0xfff7f6ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: constraints.maxHeight * .57,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, .82, 1],
                ).createShader(bounds),
                child: Image.asset(
                  'assets/img/redesign/welcome_hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 26),
                child: Column(
                  children: [
                    SizedBox(
                      height: constraints.maxHeight * (constraints.maxHeight < 700 ? .16 : .42),
                    ),
                    Text(
                      tr(context, 'Your Rewards', 'رحلتك مع المكافآت'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: ink),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xff6921f2), Color(0xffb024ec)],
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        tr(context, 'Journey Starts Here', 'تبدأ هنا'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr(
                        context,
                        'Play, earn, and redeem amazing rewards with ease.',
                        'العب واكسب واستبدل مكافآت رائعة بسهولة.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, color: muted),
                    ),
                    const Spacer(),
                    GradientButton(
                      tr(context, 'Get Started', 'ابدأ الآن'),
                      dark: true,
                      onPressed: () => openPage(context, const EmailPage()),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () => openPage(context, const LoginPage()),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: tr(context, 'Already have an account? ', 'لديك حساب؟ '),
                              style: const TextStyle(color: muted),
                            ),
                            TextSpan(
                              text: tr(context, 'Login', 'سجّل الدخول'),
                              style: const TextStyle(color: violet, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({
    required this.image,
    required this.child,
    this.artOnTop = false,
    this.artTopFraction = .28,
    super.key,
  });
  final String image;
  final Widget child;
  final bool artOnTop;
  final double artTopFraction;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xfffaf9ff)),
        Positioned(
          top: artOnTop ? 0 : MediaQuery.sizeOf(context).height * artTopFraction,
          left: 0,
          right: 0,
          height: artOnTop ? MediaQuery.sizeOf(context).height * .64 : null,
          bottom: artOnTop ? null : 0,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: artOnTop
                  ? const [Colors.white, Colors.white, Colors.transparent]
                  : const [Colors.transparent, Colors.white, Colors.white],
              stops: artOnTop ? const [0, .82, 1] : const [0, .18, 1],
            ).createShader(bounds),
            child: Image.asset(image, fit: BoxFit.cover),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 12, 26, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).vertical - 44,
              ),
              child: child,
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthTop extends StatelessWidget {
  const AuthTop({this.step = -1, super.key});
  final int step;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
      ),
      const Spacer(),
      if (step >= 0)
        Hero(
          tag: 'onboarding-progress',
          flightShuttleBuilder: (_, animation, _, fromContext, toContext) {
            final start = ((fromContext.widget as Hero).child as OnboardingProgress).step;
            final end = ((toContext.widget as Hero).child as OnboardingProgress).step;
            return AnimatedBuilder(
              animation: animation,
              builder: (_, _) => OnboardingProgress(
                step: start + (end - start) * Curves.easeInOutCubic.transform(animation.value),
              ),
            );
          },
          child: OnboardingProgress(step: step.toDouble()),
        ),
      const Spacer(),
      const SizedBox(width: 48),
    ],
  );
}

/// The reference uses three narrow capsules separated by two circular marks.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({required this.step, super.key});
  final double step;

  @override
  Widget build(BuildContext context) {
    const inactive = Color(0xffd6cff9);
    final marks = <(double, bool)>[(0, false), (0, true), (1, false), (2, true), (3, false)];
    return Semantics(
      label: tr(
        context,
        'Onboarding step ${step.round() + 1} of 4',
        'الخطوة ${step.round() + 1} من ٤',
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < marks.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(inactive, violet, (step - marks[i].$1 + 1).clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: SizedBox(width: marks[i].$2 ? 8 : 31, height: marks[i].$2 ? 8 : 5),
            ),
          ],
        ],
      ),
    );
  }
}

bool validEmail(String value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

bool passwordHasLettersAndNumbers(String value) =>
    RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);

bool passwordIsStrong(String value) =>
    value.length >= 10 &&
    RegExp(r'[a-z]').hasMatch(value) &&
    RegExp(r'[A-Z]').hasMatch(value) &&
    RegExp(r'\d').hasMatch(value);

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});
  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final controller = TextEditingController();
  String? error;
  bool busy = false;
  bool existing = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthBackdrop(
    image: 'assets/img/signin-background.png',
    artOnTop: true,
    child: Column(
      children: [
        const AuthTop(step: 0),
        SizedBox(height: MediaQuery.sizeOf(context).height * .42),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: tr(context, 'What’s your ', 'ما بريدك ')),
              TextSpan(
                text: tr(context, 'email?', 'الإلكتروني؟'),
                style: const TextStyle(color: violet),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          tr(
            context,
            'We’ll send you a verification code to confirm your account.',
            'سنرسل رمز تحقق لتأكيد حسابك.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 17),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          onChanged: (_) {
            if (existing || error != null) {
              setState(() {
                existing = false;
                error = null;
              });
            }
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.mail_outline),
            hintText: 'name@example.com',
            errorText: error,
          ),
        ),
        const SizedBox(height: 28),
        GradientButton(
          tr(context, 'Send Code', 'أرسل الرمز'),
          onPressed: () async {
            if (busy) return;
            if (!validEmail(controller.text)) {
              setState(
                () => error = tr(
                  context,
                  'Enter a valid email address',
                  'أدخل بريدًا إلكترونيًا صحيحًا',
                ),
              );
              return;
            }
            setState(() => busy = true);
            final email = controller.text.trim().toLowerCase();
            final repo = DemoScope.of(context);
            if (await repo.accountExists(email)) {
              if (!context.mounted) return;
              setState(() {
                existing = true;
                busy = false;
                error = tr(
                  context,
                  'This email already has an account.',
                  'هذا البريد مسجل بالفعل.',
                );
              });
              return;
            }
            await repo.saveOnboarding(email, 1);
            if (!context.mounted) return;
            await openOnboardingPage(context, OtpPage(email: email));
            if (mounted) setState(() => busy = false);
          },
        ),
        if (existing)
          TextButton(
            onPressed: () => openPage(context, const LoginPage()),
            child: Text(tr(context, 'Log in instead', 'سجّل الدخول بدلًا من ذلك')),
          ),
      ],
    ),
  );
}

class OtpPage extends StatefulWidget {
  const OtpPage({required this.email, this.reset = false, super.key});
  final String email;
  final bool reset;
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final controller = TextEditingController();
  Timer? timer;
  int seconds = 30;
  String? error;
  bool advancing = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && seconds > 0) setState(() => seconds--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthBackdrop(
    image: 'assets/img/otp-background.png',
    child: Column(
      children: [
        const AuthTop(step: 1),
        const SizedBox(height: 50),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: tr(context, 'Check your ', 'تحقق من ')),
              TextSpan(
                text: tr(context, 'email', 'بريدك'),
                style: const TextStyle(color: violet),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          tr(context, 'We’ve sent a 6-digit code to', 'أرسلنا رمزًا من ٦ أرقام إلى'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 17),
        ),
        Text(
          widget.email,
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 34),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: 76,
            child: Stack(
              children: [
                Row(
                  children: List.generate(
                    6,
                    (index) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .85),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: const Color(0xffddd9fc)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          index < controller.text.length ? controller.text[index] : '',
                          style: const TextStyle(
                            color: ink,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: .01,
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                      onChanged: (value) {
                        setState(() => error = null);
                        if (value.length == 6) _continue();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: seconds == 0
              ? () => setState(() {
                  seconds = 30;
                  controller.clear();
                  error = null;
                })
              : null,
          child: Text(
            seconds == 0
                ? tr(context, 'Resend code', 'إعادة إرسال الرمز')
                : '${tr(context, 'Resend in', 'إعادة الإرسال خلال')} 00:${seconds.toString().padLeft(2, '0')}',
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(tr(context, 'Continue', 'متابعة'), onPressed: _continue),
        const SizedBox(height: 280),
      ],
    ),
  );

  Future<void> _continue() async {
    if (advancing) return;
    if (!RegExp(r'^\d{6}$').hasMatch(controller.text)) {
      setState(() => error = tr(context, 'Enter six digits', 'أدخل ستة أرقام'));
      return;
    }
    if (controller.text == '000000') {
      setState(
        () => error = tr(
          context,
          'Code expired. Request a new code.',
          'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.',
        ),
      );
      return;
    }
    advancing = true;
    if (!widget.reset) await DemoScope.of(context).saveOnboarding(widget.email, 2);
    if (!mounted) return;
    await openOnboardingPage(context, PasswordPage(email: widget.email, reset: widget.reset));
    advancing = false;
  }
}

class PasswordPage extends StatefulWidget {
  const PasswordPage({required this.email, this.reset = false, super.key});
  final String email;
  final bool reset;
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool show = false;
  bool showConfirm = false;
  bool advancing = false;
  String? error;
  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthBackdrop(
    image: 'assets/img/password-background.png',
    artTopFraction: 0,
    child: Column(
      children: [
        const AuthTop(step: 2),
        const SizedBox(height: 38),
        Text.rich(
          TextSpan(
            children: widget.reset
                ? [
                    TextSpan(text: tr(context, 'Reset ', 'إعادة تعيين ')),
                    TextSpan(
                      text: tr(context, 'password', 'كلمة المرور'),
                      style: const TextStyle(color: violet),
                    ),
                  ]
                : [
                    TextSpan(text: tr(context, 'Create a ', 'أنشئ ')),
                    TextSpan(
                      text: tr(context, 'password', 'كلمة مرور'),
                      style: const TextStyle(color: violet),
                    ),
                  ],
          ),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          tr(context, 'Set a secure password for your account.', 'اختر كلمة مرور آمنة لحسابك.'),
          style: const TextStyle(color: muted, fontSize: 17),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: password,
          obscureText: !show,
          onChanged: (_) => setState(() => error = null),
          decoration: InputDecoration(
            labelText: tr(context, 'Password', 'كلمة المرور'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => show = !show),
              icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: confirm,
          obscureText: !showConfirm,
          onChanged: (_) => setState(() => error = null),
          decoration: InputDecoration(
            labelText: tr(context, 'Confirm password', 'تأكيد كلمة المرور'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => showConfirm = !showConfirm),
              icon: Icon(showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 20),
        _passwordRule(
          context,
          tr(context, 'At least 8 characters', '٨ أحرف على الأقل'),
          password.text.length >= 8,
        ),
        _passwordRule(
          context,
          tr(context, 'Include letters and numbers', 'حروف وأرقام'),
          passwordHasLettersAndNumbers(password.text),
        ),
        _passwordRule(
          context,
          tr(context, 'Use a strong password', 'استخدم كلمة مرور قوية'),
          passwordIsStrong(password.text),
        ),
        const SizedBox(height: 250),
        GradientButton(
          widget.reset
              ? tr(context, 'Save Password', 'حفظ كلمة المرور')
              : tr(context, 'Continue', 'متابعة'),
          onPressed: _submit,
        ),
      ],
    ),
  );

  Widget _passwordRule(BuildContext context, String label, bool satisfied) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle : Icons.circle_outlined,
          color: satisfied ? const Color(0xff0cb95f) : muted,
          size: 22,
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: ink, fontSize: 15)),
      ],
    ),
  );

  Future<void> _submit() async {
    if (advancing) return;
    if (password.text.length < 8 ||
        !passwordHasLettersAndNumbers(password.text) ||
        !passwordIsStrong(password.text)) {
      setState(
        () => error = tr(
          context,
          'Use 10 or more characters with uppercase, lowercase, and numbers',
          'استخدم ١٠ أحرف أو أكثر مع أحرف كبيرة وصغيرة وأرقام',
        ),
      );
      return;
    }
    if (password.text != confirm.text) {
      setState(() => error = tr(context, 'Passwords do not match', 'كلمتا المرور غير متطابقتين'));
      return;
    }
    setState(() => advancing = true);
    if (widget.reset) {
      final ok = await DemoScope.of(context).resetPassword(widget.email, password.text);
      if (!mounted) return;
      if (ok) {
        replacePage(context, const LoginPage());
      } else {
        setState(() {
          error = tr(context, 'Account not found', 'الحساب غير موجود');
          advancing = false;
        });
      }
    } else {
      await DemoScope.of(context).saveOnboarding(widget.email, 2);
      if (!mounted) return;
      await openOnboardingPage(
        context,
        CharacterPage(email: widget.email, password: password.text),
      );
      if (mounted) setState(() => advancing = false);
    }
  }
}

class CharacterPage extends StatefulWidget {
  const CharacterPage({required this.email, required this.password, super.key});
  final String email;
  final String password;
  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  int selected = 1;
  String? error;
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffeee9ff), Color(0xfffff5fc), Color(0xffe5ecff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const AuthTop(step: 3),
              const SizedBox(height: 35),
              Text(
                tr(context, 'Choose Your Character', 'اختر شخصيتك'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  context,
                  'Pick a character to represent you in the app.',
                  'اختر شخصية تمثلك في التطبيق.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, fontSize: 17),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(4, 5, 8, 8),
                  itemCount: 9,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 13,
                    crossAxisSpacing: 13,
                  ),
                  itemBuilder: (_, index) {
                    final id = index + 1;
                    return InkWell(
                      onTap: () => setState(() => selected = id),
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(21),
                                border: Border.all(
                                  color: selected == id ? violet : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(17),
                                child: Image.asset(characterAsset(id), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          if (selected == id)
                            const Positioned(
                              right: -4,
                              top: -4,
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: violet,
                                child: Icon(Icons.check, color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
              GradientButton(
                tr(context, 'Continue', 'متابعة'),
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await DemoScope.of(
                            context,
                          ).createAccount(widget.email, widget.password, selected);
                          if (context.mounted) replacePage(context, const DemoShell());
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              error = tr(
                                context,
                                'This email already has an account',
                                'هذا البريد مسجل بالفعل',
                              );
                              busy = false;
                            });
                          }
                        }
                      },
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool passwordVisible = false;
  bool busy = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (busy) return;
    if (!validEmail(email.text) || password.text.isEmpty) {
      setState(
        () => error = tr(
          context,
          'Enter a valid email and password',
          'أدخل بريدًا إلكترونيًا وكلمة مرور صالحين',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final ok = await DemoScope.of(context).login(email.text, password.text);
      if (!mounted) return;
      if (ok) {
        replacePage(context, const DemoShell());
      } else {
        setState(
          () =>
              error = tr(context, 'Incorrect email or password', 'البريد أو كلمة المرور غير صحيحة'),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = tr(
            context,
            'Login failed. Please try again.',
            'تعذر تسجيل الدخول. حاول مرة أخرى.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthBackdrop(
    image: 'assets/img/signin-background.png',
    artOnTop: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthTop(),
        SizedBox(height: MediaQuery.sizeOf(context).height * .36),
        Text(
          tr(context, 'Welcome back', 'مرحبًا بعودتك'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          tr(
            context,
            'Sign in to continue your rewards journey.',
            'سجّل الدخول لمتابعة رحلتك مع المكافآت.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 16),
        ),
        const SizedBox(height: 26),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: tr(context, 'Email address', 'البريد الإلكتروني'),
            prefixIcon: const Icon(LucideIcons.mail, color: ink),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: !passwordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            hintText: tr(context, 'Password', 'كلمة المرور'),
            prefixIcon: const Icon(LucideIcons.lockKeyhole, color: ink),
            suffixIcon: IconButton(
              tooltip: tr(
                context,
                passwordVisible ? 'Hide password' : 'Show password',
                passwordVisible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
              ),
              onPressed: () => setState(() => passwordVisible = !passwordVisible),
              icon: Icon(passwordVisible ? LucideIcons.eyeOff : LucideIcons.eye, color: muted),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Color(0xffc82e48))),
        ],
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              if (!validEmail(email.text)) {
                setState(() => error = tr(context, 'Enter your email first', 'أدخل بريدك أولًا'));
                return;
              }
              openPage(context, OtpPage(email: email.text.trim(), reset: true));
            },
            child: Text(tr(context, 'Forgot password?', 'نسيت كلمة المرور؟')),
          ),
        ),
        const SizedBox(height: 6),
        GradientButton(
          tr(context, busy ? 'Signing in...' : 'Login', busy ? 'جارٍ الدخول...' : 'تسجيل الدخول'),
          onPressed: busy ? null : _login,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => openPage(context, const EmailPage()),
          child: Text(tr(context, 'New here? Create an account', 'جديد هنا؟ أنشئ حسابًا')),
        ),
      ],
    ),
  );
}

class DemoShell extends StatefulWidget {
  const DemoShell({super.key});
  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  int tab = 0;
  void changeTab(int value) => setState(() => tab = value);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePanel(onCategories: () => changeTab(1)),
      const CategoriesPanel(),
      WalletPanel(onCategories: () => changeTab(1)),
      ProfilePanel(onWallet: () => changeTab(2)),
    ];
    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xf8ffffff),
            border: Border(top: BorderSide(color: Color(0xffecebfa))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tab(context, 0, LucideIcons.house, 'Home', 'الرئيسية'),
              _tab(context, 1, AppIcons.categories, 'Categories', 'الفئات'),
              _tab(context, 2, LucideIcons.wallet, 'Wallet', 'المحفظة'),
              _tab(context, 3, AppIcons.profile, 'Profile', 'الملف'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, String en, String ar) => Expanded(
    child: InkWell(
      onTap: () => changeTab(index),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (index == 3)
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xffe7dcff)),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                characterAsset(DemoScope.of(context).character),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            )
          else
            SizedBox(
              height: 40,
              child: Center(
                child: Icon(
                  tab == index && index == 0
                      ? Icons.home_rounded
                      : tab == index && index == 1
                      ? Icons.grid_view_rounded
                      : tab == index && index == 2
                      ? Icons.wallet_rounded
                      : icon,
                  color: tab == index ? violet : muted,
                  size: index == 1 ? 28 : 27,
                ),
              ),
            ),
          Text(
            tr(context, en, ar),
            style: TextStyle(
              color: tab == index ? violet : muted,
              fontSize: 12,
              fontWeight: tab == index ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class UnreadNotificationButton extends StatelessWidget {
  const UnreadNotificationButton({this.filled = false, super.key});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final unread = DemoScope.of(context).notifications.where((item) => item['read'] != true).length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: tr(context, 'Notifications', 'الإشعارات'),
          onPressed: () => openPage(context, const NotificationsPage()),
          icon: const Icon(AppIcons.bell),
          style: IconButton.styleFrom(
            backgroundColor: filled ? Colors.white : Colors.transparent,
            foregroundColor: filled ? violet : ink,
          ),
        ),
        if (unread > 0)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xffff4c49), shape: BoxShape.circle),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PanelTitle extends StatelessWidget {
  const PanelTitle(this.title, {this.action, super.key});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
      ?action,
    ],
  );
}

class HomePanel extends StatefulWidget {
  const HomePanel({required this.onCategories, super.key});
  final VoidCallback onCategories;
  @override
  State<HomePanel> createState() => _HomePanelState();
}

class _HomePanelState extends State<HomePanel> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final repo = DemoScope.of(context);
    final filteredCategories = demoCategories
        .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final filteredGiveaways = demoGiveaways
        .where((g) => g.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).width < 360 ? 280 : 270,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/img/homepage-background.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, pale],
                      stops: [.76, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 9, 22, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr(context, 'Your Points', 'نقاطك'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff4d45ad),
                              ),
                            ),
                          ),
                          const UnreadNotificationButton(filled: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${repo.balance}',
                              style: const TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.w800,
                                color: violet,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'PTS',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff8857ee),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(AppIcons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          hintText: tr(
                            context,
                            'Search rewards, giveaways...',
                            'ابحث عن المكافآت والسحوبات...',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'Available Rewards', 'المكافآت المتاحة'),
                    style: const TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: widget.onCategories,
                  child: Text(tr(context, 'See all', 'عرض الكل')),
                ),
              ],
            ),
          ),
          if (filteredCategories.isEmpty && filteredGiveaways.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text(tr(context, 'No rewards found', 'لم يتم العثور على مكافآت')),
            ),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final category = filteredCategories[index];
                return InkWell(
                  onTap: () => openPage(context, CategoryDetailsPage(category: category)),
                  child: SizedBox(
                    width: 93,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            category.id == 'battle' ||
                                    category.id == 'tactical' ||
                                    category.id == 'social' ||
                                    category.id == 'video'
                                ? categoryTile(category.id)
                                : categoryArt(category.id),
                            width: 93,
                            height: 93,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          categoryTitle(context, category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          categorySubtitle(context, category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              tr(context, 'Giveaways', 'السحوبات'),
              style: const TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredGiveaways.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, index) {
                final giveaway = filteredGiveaways[index];
                return InkWell(
                  onTap: () => openPage(context, GiveawayDetailsPage(giveaway: giveaway)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: [
                        const Color(0xffe7e3ff),
                        const Color(0xffffe1ef),
                        const Color(0xffdfeeff),
                        const Color(0xffffe8dc),
                      ][index % 4],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset(giveawayArt(giveaway.id), fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        Text(
                          giveaway.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(giveaway.subtitle, style: const TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class CategoryArtwork extends StatelessWidget {
  const CategoryArtwork({
    required this.category,
    required this.height,
    this.showText = true,
    super.key,
  });
  final DemoCategory category;
  final double height;
  final bool showText;
  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: arabic ? LinearGradient(colors: category.colors.map(Color.new).toList()) : null,
        image: arabic
            ? null
            : DecorationImage(image: AssetImage(categoryBanner(category.id)), fit: BoxFit.cover),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (arabic)
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              width: height * 1.2,
              child: Image.asset(categoryArt(category.id), fit: BoxFit.cover),
            ),
          if (showText && arabic)
            PositionedDirectional(
              start: 22,
              top: 20,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categoryTitle(context, category),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    categorySubtitle(context, category),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class CategoriesPanel extends StatefulWidget {
  const CategoriesPanel({super.key});
  @override
  State<CategoriesPanel> createState() => _CategoriesPanelState();
}

class _CategoriesPanelState extends State<CategoriesPanel> {
  @override
  Widget build(BuildContext context) {
    final categories = demoCategories;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: PanelTitle(tr(context, 'Categories', 'الفئات')),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) => InkWell(
                onTap: () => openPage(context, CategoryDetailsPage(category: categories[index])),
                child: CategoryArtwork(category: categories[index], height: 102),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showSearchDialog(BuildContext context, ValueChanged<String> onChanged) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr(context, 'Search categories', 'البحث في الفئات')),
      content: TextField(controller: controller, autofocus: true, onChanged: onChanged),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(tr(context, 'Done', 'تم')),
        ),
      ],
    ),
  ).then((_) => controller.dispose());
}

class CategoryDetailsPage extends StatefulWidget {
  const CategoryDetailsPage({required this.category, super.key});
  final DemoCategory category;
  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  bool busy = false;
  String group = 'Top-Ups';
  @override
  Widget build(BuildContext context) {
    final products = demoProducts
        .where(
          (p) =>
              p.categoryId == widget.category.id &&
              (widget.category.id != 'battle' || p.group == group),
        )
        .toList();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(categoryDetailArt(widget.category.id)),
                      fit: BoxFit.cover,
                    ),
                  ),
                  foregroundDecoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xaa070c39)],
                      stops: [.45, 1],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 22,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryTitle(context, widget.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        categorySubtitle(context, widget.category),
                        style: const TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.category.id == 'battle')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0eff9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: ['Top-Ups', 'Items & Skins'].map((value) {
                      final selected = group == value;
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: () => setState(() => group = value),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected ? violet : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Text(
                                  value == 'Top-Ups'
                                      ? tr(context, 'UC Top-Ups', 'شحن شدات UC')
                                      : tr(context, 'Items & Skins', 'العناصر والمظاهر'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected ? Colors.white : const Color(0xff555e91),
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .68,
              ),
              itemBuilder: (_, index) {
                final product = products[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x139493c9), blurRadius: 16)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xffe9e5ff),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(productArt(product), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.title,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${product.points} PTS',
                        style: const TextStyle(
                          color: violet,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: busy ? null : () => _redeem(product),
                          child: Text(tr(context, 'Redeem', 'استبدل')),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redeem(DemoProduct product) async {
    final repo = DemoScope.of(context);
    if (busy) return;
    final details = await showRedemptionDetailsSheet(
      context,
      product: product,
      balance: repo.balance,
      imagePath: productArt(product),
    );
    if (details == null || !mounted) return;
    setState(() => busy = true);
    bool ok;
    try {
      ok = await repo.redeem(product, fulfillmentDetails: details);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Could not create the demo order. Try again.',
                'تعذر إنشاء الطلب التجريبي. حاول مرة أخرى.',
              ),
            ),
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          ok
              ? tr(context, 'Demo order created', 'تم إنشاء طلب تجريبي')
              : tr(context, 'Not enough points', 'النقاط غير كافية'),
        ),
        content: Text(
          ok
              ? tr(
                  context,
                  'Your wallet and order history have been updated.',
                  'تم تحديث محفظتك وسجل طلباتك.',
                )
              : tr(context, 'Choose a lower priced reward.', 'اختر مكافأة أقل تكلفة.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(context, 'OK', 'حسنًا')),
          ),
        ],
      ),
    );
  }
}

class WalletPanel extends StatelessWidget {
  const WalletPanel({required this.onCategories, super.key});
  final VoidCallback onCategories;
  @override
  Widget build(BuildContext context) {
    final repo = DemoScope.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PanelTitle(
            tr(context, 'Your Rewards', 'مكافآتك'),
            action: const UnreadNotificationButton(),
          ),
          const SizedBox(height: 20),
          Container(
            height: 264,
            padding: const EdgeInsets.fromLTRB(26, 32, 26, 36),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              image: const DecorationImage(
                image: AssetImage('assets/img/wallet-background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'POINTS', 'النقاط'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  tr(context, 'BALANCE', 'الرصيد'),
                  style: const TextStyle(
                    color: Color(0xffdbd6ff),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${repo.balance}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 59,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'PTS',
                        style: TextStyle(
                          color: Color(0xffe5dcff),
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(36),
            child: Ink(
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xff3927ff), Color(0xff6921f2)]),
                borderRadius: BorderRadius.circular(36),
                boxShadow: const [
                  BoxShadow(color: Color(0x33552cff), blurRadius: 22, offset: Offset(0, 10)),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(36),
                onTap: () => openPage(context, const EarnPage()),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.gift, color: Colors.white, size: 29),
                        const SizedBox(width: 12),
                        Text(
                          tr(context, 'Fast, Earn', 'اكسب بسرعة'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const PositionedDirectional(
                      end: 22,
                      child: Icon(LucideIcons.arrowRight, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _action(
            context,
            LucideIcons.shoppingCart,
            tr(context, 'Place an Order', 'تصفح المكافآت'),
            tr(context, 'Browse rewards to redeem', 'تصفح المكافآت لاستبدالها'),
            onCategories,
            iconBackground: const Color(0xfff0e6ff),
            iconColor: const Color(0xff6b2cff),
          ),
          _action(
            context,
            LucideIcons.star,
            tr(context, 'Write a Review', 'اكتب تقييمًا'),
            tr(context, 'Open the app store listing', 'افتح صفحة التطبيق في المتجر'),
            () async {
              final uri = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.creativehub.rewardsapp',
              );
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tr(context, 'Store listing unavailable', 'صفحة المتجر غير متاحة'),
                    ),
                  ),
                );
              }
            },
            iconBackground: const Color(0xfffff4df),
            iconColor: const Color(0xffffb126),
          ),
          _action(
            context,
            LucideIcons.users,
            tr(context, 'Refer a Friend', 'ادع صديقًا'),
            tr(context, 'Share Creative Rewards', 'شارك التطبيق مع أصدقائك'),
            () => openPage(context, const ReferralPage()),
            iconBackground: const Color(0xfffde6f8),
            iconColor: const Color(0xffdf2bbf),
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    required Color iconBackground,
    required Color iconColor,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white.withValues(alpha: .84),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 29),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(subtitle, style: const TextStyle(color: muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(AppIcons.next, color: muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class EarnPage extends StatelessWidget {
  const EarnPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'Earn points', 'اكسب نقاطًا'))),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard, color: violet, size: 80),
          const SizedBox(height: 22),
          Text(
            tr(context, 'Demo starting balance', 'الرصيد التجريبي الابتدائي'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          Text(
            tr(
              context,
              'New demo accounts receive 6,000 points. More earning options will appear when the real service is available.',
              'تحصل الحسابات التجريبية الجديدة على ٦٠٠٠ نقطة. ستظهر طرق أخرى للكسب عند توفر الخدمة الفعلية.',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});
  @override
  Widget build(BuildContext context) {
    final email = DemoScope.of(context).email ?? '';
    final stableId = email.codeUnits.fold<int>(
      0,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    final code = 'CR-${stableId.toRadixString(36).toUpperCase()}';
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Refer a Friend', 'ادع صديقًا'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.people_alt_outlined, size: 90, color: violet),
            const SizedBox(height: 18),
            Text(
              tr(context, 'Invite friends to Creative Rewards', 'ادع أصدقاءك إلى Creative Rewards'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            SelectableText(
              code,
              style: const TextStyle(color: violet, fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            GradientButton(
              tr(context, 'Copy code', 'نسخ الرمز'),
              icon: Icons.copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(tr(context, 'Code copied', 'تم نسخ الرمز'))));
              },
            ),
            const SizedBox(height: 18),
            Text(
              tr(
                context,
                'Sharing is a demo action. Referral rewards require backend verification.',
                'المشاركة تجريبية. تتطلب مكافآت الإحالة تحققًا من الخادم.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePanel extends StatelessWidget {
  const ProfilePanel({required this.onWallet, super.key});
  final VoidCallback onWallet;
  @override
  Widget build(BuildContext context) {
    final repo = DemoScope.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final unreadCount = repo.notifications.where((item) => item['read'] != true).length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 258 + topInset,
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 45,
                  child: Image.asset(
                    '${designAssetRoot}07_profile/profile_header_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 101,
                    decoration: const BoxDecoration(
                      color: pale,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.elliptical(280, 72),
                        topRight: Radius.elliptical(280, 72),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 22 + topInset,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 156,
                      height: 150,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 142,
                            height: 142,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 4),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(66),
                                topRight: Radius.circular(66),
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              characterAsset(repo.character),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 0,
                            child: IconButton.filled(
                              onPressed: () => openPage(context, const EditProfilePage()),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: violet,
                              ),
                              icon: const Icon(AppIcons.edit, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 174 + topInset,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Text(
                        repo.name,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(repo.email ?? '', style: const TextStyle(color: muted)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _stat('${repo.balance}', tr(context, 'Points', 'نقاط')),
                      const SizedBox(
                        height: 46,
                        child: VerticalDivider(width: 1, thickness: 1, color: Color(0xffdddafa)),
                      ),
                      _stat('${repo.entries.length}', tr(context, 'Giveaways', 'سحوبات')),
                      const SizedBox(
                        height: 46,
                        child: VerticalDivider(width: 1, thickness: 1, color: Color(0xffdddafa)),
                      ),
                      _stat('${repo.orders.length}', tr(context, 'Orders', 'طلبات')),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _row(
                  context,
                  AppIcons.gift,
                  tr(context, 'My Giveaways', 'سحوباتي'),
                  () => openPage(context, const MyGiveawaysPage()),
                ),
                _row(
                  context,
                  LucideIcons.shoppingBag,
                  tr(context, 'My Orders', 'طلباتي'),
                  () => openPage(context, const OrdersPage()),
                ),
                _row(
                  context,
                  AppIcons.bell,
                  tr(context, 'Notifications', 'الإشعارات'),
                  () => openPage(context, const NotificationsPage()),
                  unreadCount: unreadCount,
                ),
                _row(
                  context,
                  AppIcons.language,
                  tr(context, 'Language', 'اللغة'),
                  () => showLanguageSheet(context),
                ),
                _row(
                  context,
                  AppIcons.info,
                  tr(context, 'About', 'حول التطبيق'),
                  () => openPage(context, const InfoPage(title: 'About')),
                ),
                _row(
                  context,
                  AppIcons.privacy,
                  tr(context, 'Privacy Policy', 'سياسة الخصوصية'),
                  () => openPage(context, const InfoPage(title: 'Privacy Policy')),
                ),
                _row(
                  context,
                  AppIcons.document,
                  tr(context, 'Terms & Conditions', 'الشروط والأحكام'),
                  () => openPage(context, const InfoPage(title: 'Terms & Conditions')),
                ),
                const SizedBox(height: 12),
                const SignOutButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String number, String label) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            number,
            style: const TextStyle(color: violet, fontSize: 25, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: muted),
        ),
      ],
    ),
  );
  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    int unreadCount = 0,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Icon(icon, color: ink),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unreadCount > 0) ...[
            Container(
              key: const ValueKey('profile-unread-badge'),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const BoxDecoration(color: Color(0xfff23b3b), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          const Icon(AppIcons.next, color: muted),
        ],
      ),
      onTap: onTap,
    ),
  );
}

Future<void> showLanguageSheet(BuildContext context) async {
  final controller = context.findAncestorWidgetOfExactType<RedesignApp>()?.localeController;
  if (controller == null) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xfffbfaff),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Color(0x208073bd), blurRadius: 24, offset: Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xffd9d3ed),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr(sheetContext, 'Choose Language', 'اختر اللغة'),
              style: const TextStyle(color: ink, fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            for (final option in const [
              (code: 'en', label: 'English'),
              (code: 'ar', label: 'العربية'),
            ]) ...[
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  key: ValueKey('language-${option.code}'),
                  minTileHeight: 58,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  tileColor: controller.value.languageCode == option.code
                      ? const Color(0xffede8ff)
                      : Colors.white,
                  title: Text(
                    option.label,
                    style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
                  ),
                  trailing: controller.value.languageCode == option.code
                      ? const Icon(Icons.check_circle_rounded, color: violet)
                      : const Icon(Icons.circle_outlined, color: muted),
                  onTap: () async {
                    await controller.setLocale(Locale(option.code));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
}

class SignOutButton extends StatefulWidget {
  const SignOutButton({super.key});
  @override
  State<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<SignOutButton> {
  bool busy = false;

  Future<void> _confirm() async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xfffbfaff),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xffffe9ec),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(AppIcons.logout, color: Color(0xffd83a53)),
              ),
              const SizedBox(height: 18),
              Text(
                tr(dialogContext, 'Sign out?', 'تسجيل الخروج؟'),
                style: const TextStyle(color: ink, fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  dialogContext,
                  'Are you sure you want to sign out of your account?',
                  'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
                ),
                style: const TextStyle(color: muted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(tr(dialogContext, 'Cancel', 'إلغاء')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffdb4058),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(tr(dialogContext, 'Sign Out', 'تسجيل الخروج')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await DemoScope.of(context).logout();
      if (mounted) replacePage(context, const WelcomePage());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Could not sign out. Please try again.',
                'تعذر تسجيل الخروج. حاول مرة أخرى.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('profile-sign-out'),
    onTap: busy ? null : _confirm,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xffffedf0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffffd7de)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xffd83a53)),
            )
          else
            const Icon(AppIcons.logout, color: Color(0xffd83a53), size: 21),
          const SizedBox(width: 12),
          Text(
            tr(context, 'Sign Out', 'تسجيل الخروج'),
            style: const TextStyle(
              color: Color(0xffc82e48),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController? name;
  int? character;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    name ??= TextEditingController(text: DemoScope.of(context).name);
    character ??= DemoScope.of(context).character;
  }

  @override
  void dispose() {
    name?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'Edit Profile', 'تعديل الملف'))),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: tr(context, 'Display name', 'الاسم الظاهر')),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (_, index) => InkWell(
                onTap: () => setState(() => character = index + 1),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: character == index + 1 ? violet : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(characterAsset(index + 1), fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          GradientButton(
            tr(context, 'Save', 'حفظ'),
            icon: Icons.check,
            onPressed: () async {
              if (name!.text.trim().isEmpty) return;
              await DemoScope.of(context).updateProfile(name!.text, character!);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});
  @override
  Widget build(BuildContext context) {
    // Language is held by the parent app and persisted by LocaleController.
    final app = context.findAncestorWidgetOfExactType<RedesignApp>()!;
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Language', 'اللغة'))),
      body: ListView(
        children: [
          ListTile(
            title: const Text('English'),
            onTap: () async {
              await app.localeController.setLocale(const Locale('en'));
              if (context.mounted) Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('العربية'),
            onTap: () async {
              await app.localeController.setLocale(const Locale('ar'));
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'Account Settings', 'إعدادات الحساب'))),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(tr(context, 'Sign Out', 'تسجيل الخروج')),
          onTap: () async {
            await DemoScope.of(context).logout();
            if (context.mounted) replacePage(context, const WelcomePage());
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(tr(context, 'Demo account', 'حساب تجريبي')),
          subtitle: Text(
            tr(
              context,
              'Orders and giveaway entries are simulated locally.',
              'الطلبات والمشاركات في السحوبات محاكاة محلية.',
            ),
          ),
        ),
      ],
    ),
  );
}

class InfoPage extends StatelessWidget {
  const InfoPage({required this.title, super.key});
  final String title;
  @override
  Widget build(BuildContext context) {
    final text = switch (title) {
      'About' => tr(
        context,
        'Creative Rewards demo lets you browse rewards and giveaways before the new service launches.',
        'النسخة التجريبية تتيح تصفح المكافآت والسحوبات قبل إطلاق الخدمة الجديدة.',
      ),
      'Privacy Policy' => tr(
        context,
        'Demo account data is stored on this device. The production privacy notice must be reviewed before launch.',
        'تُحفظ بيانات الحساب التجريبي على هذا الجهاز. يجب مراجعة سياسة الخصوصية قبل الإطلاق.',
      ),
      _ => tr(
        context,
        'This demo does not fulfill orders or award real prizes. Production terms must be reviewed before launch.',
        'هذا العرض التجريبي لا ينفذ طلبات أو يمنح جوائز حقيقية. يجب مراجعة الشروط قبل الإطلاق.',
      ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: const TextStyle(fontSize: 17, height: 1.6)),
      ),
    );
  }
}

class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: () => Navigator.of(context).maybePop(),
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xffefebff),
      foregroundColor: ink,
      minimumSize: const Size(48, 48),
    ),
    icon: Icon(
      Directionality.of(context) == TextDirection.rtl ? Icons.arrow_forward : Icons.arrow_back,
    ),
  );
}

class SecondaryHeader extends StatelessWidget {
  const SecondaryHeader({required this.title, required this.subtitle, this.art, super.key});
  final String title;
  final String subtitle;
  final HeaderArt? art;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: art == null ? 132 : 170,
    child: Stack(
      children: [
        if (art != null) PositionedDirectional(top: -12, end: 0, child: art!),
        const PositionedDirectional(top: 0, start: 0, child: CircleBackButton()),
        PositionedDirectional(
          start: 0,
          end: art == null ? 0 : 65,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: ink, fontSize: 31, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: muted, fontSize: 15)),
            ],
          ),
        ),
      ],
    ),
  );
}

enum HeaderArtKind { gift, bag }

class HeaderArt extends StatelessWidget {
  const HeaderArt(this.kind, {super.key});
  final HeaderArtKind kind;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: 154,
      height: 152,
      child: OverflowBox(
        alignment: kind == HeaderArtKind.bag ? Alignment.topLeft : Alignment.center,
        maxWidth: 330,
        maxHeight: 330,
        child: Image.asset(
          'assets/img/redesign/welcome_hero.png',
          width: 330,
          height: 330,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

class CircleArrow extends StatelessWidget {
  const CircleArrow({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: const BoxDecoration(color: Color(0xfff1edff), shape: BoxShape.circle),
    child: Icon(
      Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
      color: ink,
    ),
  );
}

List<Map<String, dynamic>> filteredOrders(List<Map<String, dynamic>> orders, String filter) {
  if (filter == 'All') return orders;
  return orders
      .where((order) => (order['status'] as String? ?? '').toLowerCase() == filter.toLowerCase())
      .toList();
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final orders = filteredOrders(DemoScope.of(context).orders, filter);
    return Scaffold(
      backgroundColor: const Color(0xfffaf9ff),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            SecondaryHeader(
              title: tr(context, 'My Orders', 'طلباتي'),
              subtitle: tr(context, 'Track and manage your orders', 'تابع طلباتك وأدرها'),
              art: const HeaderArt(HeaderArtKind.bag),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                for (final value in const ['All', 'Processing', 'Shipped', 'Delivered']) ...[
                  if (value != 'All') const SizedBox(width: 6),
                  Expanded(
                    child: Material(
                      color: filter == value ? violet : const Color(0xfff0eef9),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        key: ValueKey('order-filter-$value'),
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => setState(() => filter = value),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              switch (value) {
                                'Processing' => tr(context, 'Processing', 'قيد المعالجة'),
                                'Shipped' => tr(context, 'Shipped', 'تم الشحن'),
                                'Delivered' => tr(context, 'Delivered', 'تم التسليم'),
                                _ => tr(context, 'All', 'الكل'),
                              },
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: filter == value ? Colors.white : muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            if (orders.isEmpty)
              _emptyCard(
                context,
                filter == 'All' ? 'No demo orders yet' : 'No $filter orders',
                filter == 'All' ? 'لا توجد طلبات تجريبية بعد' : 'لا توجد طلبات في هذه الحالة',
              )
            else
              for (final order in orders) ...[
                _orderCard(context, order),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, Map<String, dynamic> order) {
    final title = order['title'] as String? ?? '';
    final product = demoProducts.where((candidate) => candidate.title == title).firstOrNull;
    final status = order['status'] as String? ?? 'Demo order';
    final demo = status.toLowerCase().contains('demo');
    return InkWell(
      onTap: () => openPage(context, OrderDetailsPage(order: order)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x0f7765bc), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xffeeeaff),
                borderRadius: BorderRadius.circular(18),
              ),
              child: product == null
                  ? const Icon(LucideIcons.shoppingBag, color: violet, size: 36)
                  : Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(productArt(product), fit: BoxFit.contain),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${order['points']} PTS',
                        style: const TextStyle(
                          color: violet,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${order['id']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1eefb),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      demo ? tr(context, 'Demo order', 'طلب تجريبي') : status,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            const CircleArrow(),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({required this.order, super.key});
  final Map<String, dynamic> order;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Align(alignment: AlignmentDirectional.centerStart, child: CircleBackButton()),
          const SizedBox(height: 28),
          Text(order['title'] as String? ?? '', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 20),
          Text('Order #${order['id']}', textDirection: TextDirection.ltr),
          const SizedBox(height: 8),
          Text(
            '${order['points']} PTS',
            style: const TextStyle(color: violet, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              context,
              'Demo order. No product is shipped or fulfilled.',
              'طلب تجريبي. لن يُشحن أو يُسلّم أي منتج.',
            ),
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    ),
  );
}

Widget _emptyCard(BuildContext context, String en, String ar) => Container(
  padding: const EdgeInsets.all(28),
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
  child: Text(
    tr(context, en, ar),
    textAlign: TextAlign.center,
    style: const TextStyle(color: muted, fontSize: 16),
  ),
);

String notificationAge(BuildContext context, Map<String, dynamic> item) {
  final date = DateTime.tryParse(item['createdAt'] as String? ?? '');
  if (date == null) return tr(context, 'Earlier', 'سابقًا');
  final age = DateTime.now().difference(date);
  if (age.isNegative || age.inMinutes < 1) return tr(context, 'Now', 'الآن');
  if (age.inHours < 1) return tr(context, '${age.inMinutes}m ago', 'قبل ${age.inMinutes} د');
  if (age.inDays < 1) return tr(context, '${age.inHours}h ago', 'قبل ${age.inHours} س');
  if (age.inDays == 1) return tr(context, 'Yesterday', 'أمس');
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = DemoScope.of(context);
    final notifications = repo.notifications;
    return Scaffold(
      backgroundColor: const Color(0xfffaf9ff),
      body: SafeArea(
        child: Stack(
          children: [
            PositionedDirectional(top: -80, end: -95, child: _decorativeCircle(230)),
            PositionedDirectional(bottom: -105, start: -110, child: _decorativeCircle(240)),
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                SecondaryHeader(title: tr(context, 'Notifications', 'الإشعارات'), subtitle: ''),
                const SizedBox(height: 20),
                if (notifications.isEmpty)
                  _emptyCard(context, 'No notifications yet', 'لا توجد إشعارات بعد')
                else
                  for (var index = 0; index < notifications.length; index++) ...[
                    _notificationCard(context, repo, notifications[index], index),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [Color(0xffece7ff), Color(0x00ece7ff)]),
    ),
  );

  Widget _notificationCard(
    BuildContext context,
    RewardsRepository repo,
    Map<String, dynamic> item,
    int index,
  ) {
    final isWelcome = item['title'] == 'Welcome to Creative Rewards';
    final title = isWelcome
        ? tr(context, 'Welcome to Creative Rewards', 'مرحبًا بك في كريتيف ريواردز')
        : item['title'] as String? ?? '';
    final body = isWelcome
        ? tr(
            context,
            '6,000 demo points were added to your wallet.',
            'أُضيفت ٦٬٠٠٠ نقطة تجريبية إلى محفظتك.',
          )
        : item['body'] as String? ?? '';
    return InkWell(
      onTap: () async {
        await repo.readNotification(index);
        if (context.mounted) openPage(context, NotificationDetailsPage(title: title, body: body));
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(color: Color(0x147661ae), blurRadius: 22, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xffcbbaff), Color(0xffeee8ff)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.notifications_rounded, color: violet, size: 40),
                ),
                const PositionedDirectional(
                  top: -8,
                  start: -7,
                  child: Icon(Icons.auto_awesome, color: violet, size: 15),
                ),
                const PositionedDirectional(
                  bottom: -7,
                  end: -6,
                  child: Icon(Icons.auto_awesome, color: Color(0xffffce4d), size: 17),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xffeeeaff),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notificationAge(context, item),
                    style: const TextStyle(color: violet, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                const CircleArrow(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDetailsPage extends StatelessWidget {
  const NotificationDetailsPage({required this.title, required this.body, super.key});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Align(alignment: AlignmentDirectional.centerStart, child: CircleBackButton()),
          const SizedBox(height: 28),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(color: muted, fontSize: 17, height: 1.5)),
        ],
      ),
    ),
  );
}

class GiveawayDetailsPage extends StatefulWidget {
  const GiveawayDetailsPage({required this.giveaway, super.key});
  final DemoGiveaway giveaway;
  @override
  State<GiveawayDetailsPage> createState() => _GiveawayDetailsPageState();
}

class _GiveawayDetailsPageState extends State<GiveawayDetailsPage> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final isUpcoming = widget.giveaway.id == 'coffee';
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Giveaway Details', 'تفاصيل السحب'))),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: const Color(0xffe5e2ff),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Image.asset(giveawayArt(widget.giveaway.id), height: 210, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 26),
          Text(widget.giveaway.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(widget.giveaway.subtitle, style: const TextStyle(color: muted, fontSize: 17)),
          const SizedBox(height: 24),
          Text(
            tr(
              context,
              'Join for a unique demo participation number. This local demo does not enter a real prize draw. Points are never deducted.',
              'شارك للحصول على رقم تجريبي فريد. هذه المشاركة المحلية لا تدخل سحبًا حقيقيًا. لن تُخصم نقاط.',
            ),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 30),
          GradientButton(
            isUpcoming
                ? tr(context, 'Coming soon', 'قريبًا')
                : tr(context, 'Join Giveaway', 'شارك في السحب'),
            onPressed: isUpcoming || busy ? null : _enter,
          ),
        ],
      ),
    );
  }

  Future<void> _enter() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final number = await DemoScope.of(context).enterGiveaway(widget.giveaway);
      if (!mounted) return;
      if (number != null) {
        await openPage(context, NumberRevealPage(title: widget.giveaway.title, number: number));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'This giveaway is unavailable.', '??? ????? ??? ????.')),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'Could not join. Please try again.', '????? ????????. ???? ??? ????.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class NumberRevealPage extends StatefulWidget {
  const NumberRevealPage({required this.title, required this.number, super.key});
  final String title;
  final String number;

  @override
  State<NumberRevealPage> createState() => _NumberRevealPageState();
}

class _NumberRevealPageState extends State<NumberRevealPage> with SingleTickerProviderStateMixin {
  late final AnimationController animation;
  Timer? revealTimer;
  bool started = false;
  bool revealed = false;
  bool lottieStarted = false;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (MediaQuery.of(context).disableAnimations) {
      revealed = true;
    } else {
      revealTimer = Timer(const Duration(milliseconds: 1350), () {
        if (mounted) setState(() => revealed = true);
      });
    }
  }

  @override
  void dispose() {
    revealTimer?.cancel();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: pale,
    appBar: AppBar(title: Text(tr(context, 'Your Ticket', '??????'))),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 220,
                child: MediaQuery.of(context).disableAnimations
                    ? const Icon(AppIcons.gift, size: 100, color: violet)
                    : Lottie.asset(
                        'assets/lottie/number-generator.json',
                        controller: animation,
                        onLoaded: (_) {
                          if (!lottieStarted && mounted) {
                            lottieStarted = true;
                            animation.forward();
                          }
                        },
                        errorBuilder: (_, _, _) =>
                            const Icon(AppIcons.gift, size: 100, color: violet),
                      ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 360),
                transitionBuilder: (child, value) => FadeTransition(
                  opacity: value,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .88, end: 1).animate(value),
                    child: child,
                  ),
                ),
                child: revealed
                    ? Column(
                        key: const ValueKey('ticket-revealed'),
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: SelectableText(
                              widget.number,
                              key: const ValueKey('saved-ticket-number'),
                              style: const TextStyle(
                                color: violet,
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: widget.number));
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr(context, 'Ticket number copied', '?? ??? ??? ???????'),
                                    ),
                                  ),
                                );
                            },
                            icon: const Icon(LucideIcons.copy, size: 18),
                            label: Text(tr(context, 'Copy ticket', '??? ???????')),
                          ),
                        ],
                      )
                    : Text(
                        key: const ValueKey('ticket-generating'),
                        tr(context, 'Preparing your ticket?', '???? ????? ???????'),
                        style: const TextStyle(color: muted, fontSize: 18),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                tr(
                  context,
                  'Demo entry only. This does not enter a real draw.',
                  '?????? ??????? ??? ??? ???? ????? ???????.',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (revealed)
                GradientButton(
                  tr(context, 'Continue', '??????'),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class MyGiveawaysPage extends StatelessWidget {
  const MyGiveawaysPage({super.key});
  @override
  Widget build(BuildContext context) {
    final entries = DemoScope.of(context).entries;
    return Scaffold(
      backgroundColor: const Color(0xfffaf9ff),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            SecondaryHeader(
              title: tr(context, 'My Giveaways', 'سحوباتي'),
              subtitle: tr(
                context,
                "Check the giveaways you've joined",
                'تعرّف على السحوبات التي شاركت فيها',
              ),
              art: const HeaderArt(HeaderArtKind.gift),
            ),
            const SizedBox(height: 26),
            if (entries.isEmpty)
              _emptyCard(context, 'No demo entries yet', 'لا توجد مشاركات تجريبية بعد')
            else
              for (final entry in entries) ...[
                _entryCard(context, entry),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Widget _entryCard(BuildContext context, Map<String, dynamic> entry) {
    final title = entry['title'] as String? ?? '';
    final number = entry['number'] as String? ?? '';
    final giveaway = entry['giveaway'] as String? ?? '';
    return InkWell(
      onTap: () => openPage(context, NumberRevealPage(title: title, number: number)),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(color: Color(0x127965b5), blurRadius: 21, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xffeae5ff),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Image.asset(giveawayArt(giveaway), fit: BoxFit.contain),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, 'Demo participation', 'مشاركة تجريبية'),
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    key: ValueKey('ticket-$number'),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: number));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tr(context, 'Ticket number copied', 'تم نسخ رقم التذكرة'),
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xffeeeaff),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.ticket, color: violet, size: 15),
                          const SizedBox(width: 7),
                          Text(
                            number,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: violet,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            const CircleArrow(),
          ],
        ),
      ),
    );
  }
}
