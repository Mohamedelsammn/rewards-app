import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../../notifications/presentation/widgets/unread_notification_button.dart';
import '../../../wallet/presentation/bloc/wallet_cubit.dart';
import '../../../wallet/presentation/widgets/wallet_balance_text.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_actions.dart';

/// Profile tab: header with the character, counters and the menu.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<SessionCubit, AppUser?>((cubit) => cubit.state.user);
    final unread = context.watch<UnreadCountCubit>().state;
    if (user == null) return const SizedBox.shrink();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: RefreshIndicator(
        onRefresh: context.read<WalletCubit>().load,
        child: ListView(
          key: const PageStorageKey('profile'),
          padding: EdgeInsets.zero,
          children: [
            ProfileHeader(user: user),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
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
                        _Stat.widget(
                          const WalletBalanceText(style: _Stat.numberStyle),
                          l10n.profilePoints,
                        ),
                        const _StatDivider(),
                        _Stat('${user.stats.giveaways}', l10n.profileGiveaways),
                        const _StatDivider(),
                        _Stat('${user.stats.orders}', l10n.profileOrders),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MenuRow(
                    AppIcons.gift,
                    l10n.profileMyGiveaways,
                    () => context.push(Routes.myGiveaways),
                  ),
                  _MenuRow(
                    LucideIcons.shoppingBag,
                    l10n.profileMyOrders,
                    () => context.push(Routes.orders),
                  ),
                  _MenuRow(
                    AppIcons.bell,
                    l10n.profileNotifications,
                    () => context.push(Routes.notifications),
                    unreadCount: unread,
                  ),
                  _MenuRow(
                    AppIcons.language,
                    l10n.profileLanguage,
                    () => showLanguageSheet(context),
                  ),
                  _MenuRow(
                    LucideIcons.settings,
                    l10n.profileSettings,
                    () => context.push(Routes.settings),
                  ),
                  _MenuRow(
                    AppIcons.info,
                    l10n.profileAbout,
                    () => context.push(Routes.info(InfoKind.about)),
                  ),
                  _MenuRow(
                    AppIcons.privacy,
                    l10n.profilePrivacy,
                    () => context.push(Routes.info(InfoKind.privacy)),
                  ),
                  _MenuRow(
                    AppIcons.document,
                    l10n.profileTerms,
                    () => context.push(Routes.info(InfoKind.terms)),
                  ),
                  const SizedBox(height: 12),
                  const SignOutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(String this.number, this.label) : value = null;

  /// A live value (e.g. the wallet balance with its loading state).
  const _Stat.widget(Widget this.value, this.label) : number = null;

  final String? number;
  final Widget? value;
  final String label;

  static const numberStyle = TextStyle(
    color: AppColors.violet,
    fontSize: 25,
    fontWeight: FontWeight.w800,
  );

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: value ?? Text(number!, style: numberStyle),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 46,
    child: VerticalDivider(width: 1, thickness: 1, color: Color(0xffdddafa)),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, this.onTap, {this.unreadCount = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Icon(icon, color: AppColors.ink),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unreadCount > 0) ...[
            UnreadBadge(count: unreadCount, key: const ValueKey('profile-unread-badge')),
            const SizedBox(width: 5),
          ],
          const Icon(AppIcons.next, color: AppColors.muted),
        ],
      ),
      onTap: onTap,
    ),
  );
}
