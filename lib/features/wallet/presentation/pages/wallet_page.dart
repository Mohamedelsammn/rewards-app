import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../app_config/presentation/app_config_cubit.dart';
import '../../../notifications/presentation/widgets/unread_notification_button.dart';
import '../bloc/wallet_cubit.dart';

/// Wallet tab: balance card, "Fast, Earn" and the earn/spend shortcuts.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  Future<void> _openStore(BuildContext context) async {
    final configured = context.read<AppConfigCubit>().state.config.storeUrl;
    final uri = Uri.parse(configured.isEmpty ? AppConstants.playStoreUrl : configured);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) showAppSnackBar(context, context.l10n.walletReviewUnavailable);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: context.read<WalletCubit>().load,
        child: ListView(
          key: const PageStorageKey('wallet'),
          padding: const EdgeInsets.all(20),
          children: [
            PanelTitle(l10n.walletTitle, action: const UnreadNotificationButton()),
            const SizedBox(height: 20),
            const _BalanceCard(),
            const SizedBox(height: 18),
            _FastEarnButton(onTap: () => context.push(Routes.earn)),
            const SizedBox(height: 30),
            _ActionRow(
              icon: LucideIcons.shoppingCart,
              title: l10n.walletPlaceOrder,
              subtitle: l10n.walletPlaceOrderSubtitle,
              onTap: () => context.go(Routes.categories),
              iconBackground: const Color(0xfff0e6ff),
              iconColor: const Color(0xff6b2cff),
            ),
            _ActionRow(
              icon: LucideIcons.history,
              title: l10n.walletHistory,
              subtitle: l10n.walletHistorySubtitle,
              onTap: () => context.push(Routes.transactions),
              iconBackground: const Color(0xffe6f0ff),
              iconColor: const Color(0xff2c6bff),
            ),
            _ActionRow(
              icon: LucideIcons.star,
              title: l10n.walletReview,
              subtitle: l10n.walletReviewSubtitle,
              onTap: () => _openStore(context),
              iconBackground: const Color(0xfffff4df),
              iconColor: const Color(0xffffb126),
            ),
            _ActionRow(
              icon: LucideIcons.users,
              title: l10n.walletRefer,
              subtitle: l10n.walletReferSubtitle,
              onTap: () => context.push(Routes.refer),
              iconBackground: const Color(0xfffde6f8),
              iconColor: const Color(0xffdf2bbf),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final balance = context.select<WalletCubit, int>((cubit) => cubit.state.balance);
    return Semantics(
      label:
          '${l10n.walletPoints} ${l10n.walletBalance} ${l10n.pointsAmount(Formatters.points(balance))}',
      excludeSemantics: true,
      child: Container(
        height: 264,
        padding: const EdgeInsets.fromLTRB(26, 32, 26, 36),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          image: const DecorationImage(
            image: AssetImage(AppAssets.walletBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.walletPoints,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              l10n.walletBalance,
              style: const TextStyle(
                color: AppColors.walletSubtitle,
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
                    Formatters.points(balance),
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
                      color: AppColors.walletPtsLabel,
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
    );
  }
}

class _FastEarnButton extends StatelessWidget {
  const _FastEarnButton({required this.onTap});

  final VoidCallback onTap;

  @override
  // The shadow sits outside the Material so it is not clipped to a rectangle.
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(36),
      boxShadow: AppShadows.button,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(36),
      child: Ink(
        height: 62,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: BorderRadius.circular(36),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.gift, color: Colors.white, size: 29),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.walletFastEarn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              PositionedDirectional(
                end: 22,
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? LucideIcons.arrowLeft
                      : LucideIcons.arrowRight,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.iconBackground,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Padding(
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
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(AppIcons.next, color: AppColors.muted),
            ],
          ),
        ),
      ),
    ),
  );
}
