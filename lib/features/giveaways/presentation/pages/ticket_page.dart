import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';

class TicketArgs {
  const TicketArgs({required this.title, required this.number});

  final String title;

  /// Server-assigned, zero-padded participation number. Shown as-is (LTR).
  final String number;
}

/// Number reveal with the bundled Lottie animation.
class TicketPage extends StatefulWidget {
  const TicketPage({required this.args, super.key});

  final TicketArgs args;

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  Timer? _revealTimer;
  bool _started = false;
  bool _revealed = false;
  bool _lottieStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _revealed = true;
    } else {
      _revealTimer = Timer(const Duration(milliseconds: 1350), () {
        if (mounted) setState(() => _revealed = true);
      });
    }
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(title: Text(l10n.ticketTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 220,
                  child: reduceMotion
                      ? const Icon(AppIcons.gift, size: 100, color: AppColors.violet)
                      : Lottie.asset(
                          AppAssets.numberGeneratorLottie,
                          controller: _animation,
                          onLoaded: (_) {
                            if (!_lottieStarted && mounted) {
                              _lottieStarted = true;
                              _animation.forward();
                            }
                          },
                          errorBuilder: (_, _, _) =>
                              const Icon(AppIcons.gift, size: 100, color: AppColors.violet),
                        ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.args.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
                  transitionBuilder: (child, value) => FadeTransition(
                    opacity: value,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .88, end: 1).animate(value),
                      child: child,
                    ),
                  ),
                  child: _revealed
                      ? Column(
                          key: const ValueKey('ticket-revealed'),
                          children: [
                            SelectableText(
                              widget.args.number,
                              key: const ValueKey('saved-ticket-number'),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: AppColors.violet,
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: widget.args.number));
                                if (context.mounted) showAppSnackBar(context, l10n.ticketCopied);
                              },
                              icon: const Icon(LucideIcons.copy, size: 18),
                              label: Text(l10n.ticketCopy),
                            ),
                          ],
                        )
                      : Text(
                          key: const ValueKey('ticket-generating'),
                          l10n.ticketPreparing,
                          style: const TextStyle(color: AppColors.muted, fontSize: 18),
                        ),
                ),
                const SizedBox(height: 16),
                Text(l10n.ticketNote, textAlign: TextAlign.center),
                const SizedBox(height: 28),
                if (_revealed)
                  GradientButton(l10n.commonContinue, onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
