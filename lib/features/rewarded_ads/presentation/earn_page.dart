import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/injection_container.dart';
import '../../../core/localization/error_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/security/secure_token_storage.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../app_config/presentation/app_config_cubit.dart';
import '../../wallet/presentation/bloc/wallet_cubit.dart';
import 'rewarded_ads_cubit.dart';

/// "Fast, Earn": rewarded videos with AdMob server-side verification. The
/// whole flow respects `adRewards.enabled` from `/app-config` and the
/// server status; when disabled it shows a "coming soon" state.
class EarnPage extends StatelessWidget {
  const EarnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.read<AppConfigCubit>().state.config;
    final wallet = context.read<WalletCubit>();
    return BlocProvider(
      create: (_) => RewardedAdsCubit(
        repository: sl(),
        presenter: sl(),
        deviceId: sl<SecureTokenStorage>().installationId,
        featureEnabled: config.adRewardsEnabled,
        onCredited: wallet.load,
      )..loadStatus(),
      child: const _EarnView(),
    );
  }
}

class _EarnView extends StatefulWidget {
  const _EarnView();

  @override
  State<_EarnView> createState() => _EarnViewState();
}

class _EarnViewState extends State<_EarnView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-render the cooldown countdown every second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (context.read<RewardedAdsCubit>().state.status?.inCooldown ?? false)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.earnTitle)),
      body: BlocBuilder<RewardedAdsCubit, EarnState>(
        builder: (context, state) {
          final cubit = context.read<RewardedAdsCubit>();
          if (state.phase == EarnPhase.loading) return const LoadingView();
          if (state.phase == EarnPhase.disabled) {
            return _message(
              context,
              icon: Icons.card_giftcard,
              title: l10n.earnUnavailable,
              body: l10n.earnUnavailableBody,
            );
          }
          if (state.status == null && state.phase == EarnPhase.failed) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorStateView(error: state.error!, onRetry: cubit.loadStatus),
            );
          }
          final status = state.status!;
          final cooldown = status.inCooldown
              ? status.nextAvailableAt!.difference(DateTime.now()).inSeconds
              : 0;
          final exhausted = status.remainingToday <= 0;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.card_giftcard, color: AppColors.violet, size: 80),
              const SizedBox(height: 22),
              Text(
                l10n.earnHeadline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.earnBody(status.pointsPerCompletedAd),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.earnRemaining(status.remainingToday),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.violet, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 28),
              GradientButton(
                exhausted
                    ? l10n.earnDailyLimit
                    : cooldown > 0
                    ? l10n.earnCooldown(Formatters.countdown(cooldown))
                    : state.phase == EarnPhase.verifying
                    ? l10n.earnVerifying
                    : l10n.earnWatch,
                icon: Icons.play_arrow_rounded,
                leadingIcon: true,
                busy: state.busy,
                onPressed: exhausted || cooldown > 0 ? null : cubit.watch,
              ),
              const SizedBox(height: 18),
              if (_feedback(context, state) case final text?)
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: state.phase == EarnPhase.credited ? AppColors.success : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String? _feedback(BuildContext context, EarnState state) {
    final l10n = context.l10n;
    return switch (state.phase) {
      EarnPhase.verifying => l10n.earnVerifying,
      EarnPhase.credited => l10n.earnCredited(Formatters.points(state.creditedPoints)),
      EarnPhase.stillPending => l10n.earnPendingLong,
      EarnPhase.failed when state.error != null => errorMessage(context, state.error!),
      EarnPhase.notCredited => switch (state.outcome) {
        RewardedAdOutcome.dismissedEarly => l10n.earnDismissedEarly,
        RewardedAdOutcome.unsupported => l10n.earnUnsupported,
        RewardedAdOutcome.failedToLoad || RewardedAdOutcome.failedToShow => l10n.earnAdFailed,
        _ => switch (state.rejectReason) {
          'DAILY_LIMIT_REACHED' => l10n.errDailyLimit,
          'DEVICE_LIMIT_REACHED' => l10n.errDeviceLimit,
          'FEATURE_DISABLED' => l10n.errFeatureDisabled,
          'EXPIRED' => l10n.earnExpired,
          _ => l10n.earnRejected,
        },
      },
      _ => null,
    };
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Icon(icon, color: AppColors.violet, size: 80),
      const SizedBox(height: 22),
      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 14),
      Text(
        body,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted, fontSize: 16),
      ),
    ],
  );
}
