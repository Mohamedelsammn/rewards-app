import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../../notifications/presentation/widgets/unread_notification_button.dart';
import '../../../wallet/presentation/bloc/wallet_cubit.dart';
import '../widgets/character_avatar.dart';
import '../widgets/profile_actions.dart';

/// Profile tab: header with the character, counters and the menu.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<SessionCubit, AppUser?>((cubit) => cubit.state.user);
    final balance = context.select<WalletCubit, int>((cubit) => cubit.state.balance);
    final unread = context.watch<UnreadCountCubit>().state;
    final topInset = MediaQuery.paddingOf(context).top;
    if (user == null) return const SizedBox.shrink();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: RefreshIndicator(
        onRefresh: context.read<WalletCubit>().load,
        child: ListView(
          key: const PageStorageKey('profile'),
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 258 + topInset,
              child: Stack(
                children: [
                  Positioned.fill(
                    bottom: 45,
                    child: Image.asset(AppAssets.profileHeader, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 101,
                      decoration: const BoxDecoration(
                        color: AppColors.pale,
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
                              child: CharacterImage(
                                avatarId: user.avatarId,
                                imageUrl: user.avatarImageUrl,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                            PositionedDirectional(
                              bottom: 4,
                              end: 0,
                              child: IconButton.filled(
                                tooltip: l10n.profileEditTooltip,
                                onPressed: () => context.push(Routes.editProfile),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.violet,
                                ),
                                icon: const Icon(AppIcons.edit, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: topInset + 8,
                    end: 12,
                    child: const UnreadNotificationButton(),
                  ),
                  Positioned(
                    top: 174 + topInset,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: AppColors.muted),
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
                        _Stat(Formatters.points(balance), l10n.profilePoints),
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
  const _Stat(this.number, this.label);

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.violet,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
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
