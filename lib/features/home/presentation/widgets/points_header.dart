import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../notifications/presentation/widgets/unread_notification_button.dart';
import '../../../wallet/presentation/bloc/wallet_cubit.dart';

/// Home header: pastel art, live balance, bell and the search field.
class PointsHeader extends StatelessWidget {
  const PointsHeader({required this.searchController, required this.onSearch, super.key});

  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final balance = context.select<WalletCubit, int>((cubit) => cubit.state.balance);
    return SizedBox(
      height: MediaQuery.sizeOf(context).width < 360 ? 280 : 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.homeBackground),
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
                colors: [Colors.transparent, AppColors.pale],
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
                        l10n.homeYourPoints,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headerPoints,
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
                        Formatters.points(balance),
                        style: const TextStyle(
                          fontSize: 58,
                          fontWeight: FontWeight.w800,
                          color: AppColors.violet,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'PTS',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ptsLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) => TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(AppIcons.search),
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.homeClearSearch,
                              icon: const Icon(AppIcons.close),
                              onPressed: () {
                                searchController.clear();
                                onSearch('');
                              },
                            ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      hintText: l10n.homeSearchHint,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
