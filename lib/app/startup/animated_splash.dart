import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/localization/l10n.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Becomes true once the splash intro has played (or right away with reduced
/// motion, or after a short safety timeout). The router keeps the start-up
/// splash until then, so even a fast start shows the brand moment and then
/// transitions instead of cutting.
final splashIntroDone = ValueNotifier<bool>(false);

/// Animated "Play · Earn · Redeem" splash. A 2.2 s intro plays once:
/// a gamepad tile pops in (play), gold coins fly out onto an orbit (earn),
/// the tile turns into a gift (redeem) and the name reveals letter by
/// letter. If start-up is still running afterwards, a cheap idle loop keeps
/// the scene alive (orbiting coins, floating tile, pulsing dots). Navigation
/// never waits for it: the router leaves this page as soon as it can.
/// With reduced motion the final composition is shown without animation.
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _started = false;
  Timer? _safety;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Decode the next screens' header art now, so Home/Wallet/Profile show it
    // on their first frame instead of popping in after the splash.
    for (final asset in const [
      AppAssets.homeBackground,
      AppAssets.walletBackground,
      AppAssets.profileHeader,
    ]) {
      precacheImage(AssetImage(asset), context);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      splashIntroDone.value = true;
    } else {
      // Start the clock once the first frame is actually on screen: a cold
      // start's first frames can stall, and the intro must not play unseen.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        _safety = Timer(const Duration(milliseconds: 2600), () => splashIntroDone.value = true);
        _intro.forward().whenComplete(() {
          splashIntroDone.value = true;
          if (mounted) _idle.repeat();
        });
      });
    }
  }

  @override
  void dispose() {
    _safety?.cancel();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    // The body's constraints are loose: fill the screen, or the gradient
    // shrinks to the content's width.
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.splash),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stage = math.min(constraints.maxWidth * .74, constraints.maxHeight * .42);
            return SizedBox(
              width: constraints.maxWidth,
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  RepaintBoundary(
                    child: SizedBox.square(
                      dimension: stage,
                      child: _Stage(intro: _intro, idle: _idle, size: stage),
                    ),
                  ),
                  SizedBox(height: stage * .12),
                  _Title(intro: _intro),
                  const SizedBox(height: 10),
                  _Tagline(intro: _intro, text: context.l10n.splashTagline),
                  const Spacer(flex: 2),
                  _PulsingDots(idle: _idle),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Eased progress of [intro] within [begin, end].
double _phase(
  Animation<double> intro,
  double begin,
  double end, [
  Curve curve = Curves.easeOutCubic,
]) => curve.transform(((intro.value - begin) / (end - begin)).clamp(0.0, 1.0));

class _Stage extends StatelessWidget {
  const _Stage({required this.intro, required this.idle, required this.size});

  final Animation<double> intro;
  final Animation<double> idle;
  final double size;

  static const _coinAngles = [-150.0, -30.0, 90.0];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([intro, idle]),
    builder: (context, _) {
      final center = size / 2;
      final tile = size * .34;
      final coin = size * .15;
      final radius = size * .38;
      final appear = _phase(intro, 0, .3, Curves.easeOutBack);
      final earn = _phase(intro, .25, .6);
      final redeem = _phase(intro, .5, .8, Curves.easeInOutCubic);
      final drift = idle.value * 2 * math.pi;
      final float = math.sin(drift) * size * .015;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Halo, orbit ring and particles in one cheap painter.
          Positioned.fill(
            child: CustomPaint(
              painter: _OrbitPainter(ring: earn, particles: earn, rotation: drift * .25),
            ),
          ),
          // Coins fly out of the tile onto the orbit, then circle slowly.
          for (var i = 0; i < _coinAngles.length; i++)
            () {
              final delay = i * .08;
              final t = ((earn - delay) / (1 - delay)).clamp(0.0, 1.0);
              final angle = _coinAngles[i] * math.pi / 180 + drift * .18;
              final r = radius * Curves.easeOutBack.transform(t);
              return Positioned(
                left: center + math.cos(angle) * r - coin / 2,
                top: center + math.sin(angle) * r - coin / 2 + float * (i.isEven ? 1 : -1),
                child: Opacity(
                  opacity: t,
                  child: Transform(
                    alignment: Alignment.center,
                    // A coin "flip" while it travels.
                    transform: Matrix4.diagonal3Values(math.cos((1 - t) * math.pi).abs(), 1, 1),
                    child: _Coin(size: coin),
                  ),
                ),
              );
            }(),
          // The tile: gamepad (play) turning into a gift (redeem).
          Positioned(
            left: center - tile / 2,
            top: center - tile / 2 + float,
            child: Opacity(
              opacity: appear.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: (.6 + .4 * appear) * (1 - .12 * math.sin(redeem * math.pi)),
                child: Transform.rotate(
                  angle: math.sin(redeem * math.pi) * .18,
                  child: _MorphTile(size: tile, redeem: redeem),
                ),
              ),
            ),
          ),
          // Sparkles once the gift appears.
          Positioned(
            left: center + tile * .42,
            top: center - tile * .78,
            child: Opacity(
              opacity: redeem,
              child: Icon(Icons.auto_awesome, color: AppColors.star, size: size * .08),
            ),
          ),
          Positioned(
            left: center - tile * .8,
            top: center + tile * .42,
            child: Opacity(
              opacity: redeem,
              child: Icon(Icons.auto_awesome, color: AppColors.violet, size: size * .06),
            ),
          ),
        ],
      );
    },
  );
}

class _MorphTile extends StatelessWidget {
  const _MorphTile({required this.size, required this.redeem});

  final double size;
  final double redeem;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * .3),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(const Color(0xff5b3cff), const Color(0xff8b3cf2), redeem)!,
          Color.lerp(const Color(0xff8b5cf6), const Color(0xffef5fcf), redeem)!,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Color.lerp(const Color(0x556b4dff), const Color(0x55ef5fcf), redeem)!,
          blurRadius: size * .35,
          offset: Offset(0, size * .14),
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 1 - redeem,
          child: Transform.scale(
            scale: 1 - .3 * redeem,
            child: Icon(LucideIcons.gamepad2, color: Colors.white, size: size * .52),
          ),
        ),
        Opacity(
          opacity: redeem,
          child: Transform.scale(
            scale: .7 + .3 * redeem,
            child: Icon(LucideIcons.gift, color: Colors.white, size: size * .5),
          ),
        ),
      ],
    ),
  );
}

class _Coin extends StatelessWidget {
  const _Coin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xffffe08a), Color(0xfff5a524)],
      ),
      border: Border.all(color: const Color(0xfffff3c9), width: size * .07),
      boxShadow: [
        BoxShadow(
          color: const Color(0x40d98a00),
          blurRadius: size * .3,
          offset: Offset(0, size * .12),
        ),
      ],
    ),
    child: Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: .92), size: size * .58),
  );
}

/// Soft halo, a thin orbit ring and a few particles. Repaints only while
/// the scene animates (driven by its parent's AnimatedBuilder values).
class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.ring, required this.particles, required this.rotation});

  final double ring;
  final double particles;
  final double rotation;

  static const _count = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .38;
    canvas.drawCircle(
      center,
      size.width * .5,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: .7), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * .5)),
    );
    if (ring > 0) {
      canvas.drawCircle(
        center,
        radius * (.85 + .15 * ring),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.violet.withValues(alpha: .18 * ring),
      );
    }
    if (particles <= 0) return;
    final dot = Paint();
    for (var i = 0; i < _count; i++) {
      final angle = i * 2 * math.pi / _count + rotation + .4;
      final r = radius * (1.12 + .08 * math.sin(i * 1.7));
      dot.color = (i.isEven ? AppColors.violet : const Color(0xffef5fcf)).withValues(
        alpha: .35 * particles,
      );
      canvas.drawCircle(
        center + Offset(math.cos(angle) * r, math.sin(angle) * r),
        size.width * (i % 3 == 0 ? .014 : .009),
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.ring != ring || old.particles != particles || old.rotation != rotation;
}

/// "Creative Rewards" revealed letter by letter (staggered fade + rise).
class _Title extends StatelessWidget {
  const _Title({required this.intro});

  final Animation<double> intro;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'Creative Rewards',
    excludeSemantics: true,
    child: Directionality(
      // The brand name is Latin in both languages.
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: intro,
        builder: (context, _) => Column(
          children: [
            _word(
              'Creative',
              .55,
              const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            _word(
              'Rewards',
              .65,
              const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w800,
                color: AppColors.violet,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _word(String word, double start, TextStyle style) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < word.length; i++)
        () {
          final t = _phase(intro, start + i * .025, start + i * .025 + .2);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 14),
              child: Text(word[i], style: style),
            ),
          );
        }(),
    ],
  );
}

class _Tagline extends StatelessWidget {
  const _Tagline({required this.intro, required this.text});

  final Animation<double> intro;
  final String text;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: intro,
    builder: (context, child) {
      final t = _phase(intro, .82, 1);
      return Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
      );
    },
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 17, color: AppColors.muted, letterSpacing: .3),
    ),
  );
}

/// Lightweight "still starting" cue: three dots that pulse only while the
/// idle loop runs (after the intro), instead of a spinner.
class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.idle});

  final Animation<double> idle;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: idle,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet.withValues(
                  alpha: idle.isAnimating
                      ? .25 + .55 * (.5 + .5 * math.sin(idle.value * 2 * math.pi * 6 - i * 1.1))
                      : .25,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
