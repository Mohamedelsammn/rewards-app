import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../bloc/wallet_cubit.dart';

/// The points balance. `GET /wallet` wins; until it answers, the signed-in
/// user's `stats.points` from `/me` (the same server balance) is shown, so a
/// known balance appears immediately. Only when neither is known does an
/// inline shimmer take the exact box of the digits (never a made-up "0",
/// never covering the surrounding labels). The value fades in.
class WalletBalanceText extends StatelessWidget {
  const WalletBalanceText({required this.style, super.key});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final wallet = context.select<WalletCubit, int?>((cubit) => cubit.state.wallet?.balance);
    final failed = context.select<WalletCubit, bool>((cubit) => cubit.state.error != null);
    final fromProfile = context.select<SessionCubit, int?>(
      (cubit) => cubit.state.user?.stats.points,
    );
    final balance = wallet ?? fromProfile;
    final Widget child;
    if (balance != null) {
      child = Text(Formatters.points(balance), key: const ValueKey('balance'), style: style);
    } else if (failed) {
      child = Text('—', key: const ValueKey('balance-unknown'), style: style);
    } else {
      child = _InlinePlaceholder(style: style);
    }
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      // Keep the baseline of whichever child is shown (Row baseline layout).
      layoutBuilder: (current, previous) =>
          Stack(alignment: AlignmentDirectional.bottomStart, children: [...previous, ?current]),
      child: child,
    );
  }
}

/// Invisible "000" in the same style reserves the digits' exact box and
/// baseline; the shimmer sits inside the glyph area only.
class _InlinePlaceholder extends StatelessWidget {
  const _InlinePlaceholder({required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 14;
    return Stack(
      key: const ValueKey('balance-skeleton'),
      children: [
        Text('000', style: style.copyWith(color: Colors.transparent)),
        Positioned.fill(
          child: Padding(
            // Digits occupy roughly the middle of the line box.
            padding: EdgeInsets.symmetric(vertical: size * .2, horizontal: size * .04),
            child: Skeleton(child: SkeletonBox(radius: size * .18)),
          ),
        ),
      ],
    );
  }
}
