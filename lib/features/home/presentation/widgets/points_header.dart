import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../notifications/presentation/widgets/unread_notification_button.dart';
import '../../../wallet/presentation/widgets/wallet_balance_text.dart';

/// Home header: pastel art, live balance, bell and the search field.
///
/// Offsets are measured from design_references/home-page.png against the
/// status-bar inset; the art dissolves into the page background through a
/// same-hue fade (never through transparent black, which reads as a gray
/// band).
class PointsHeader extends StatelessWidget {
  const PointsHeader({required this.searchController, required this.onSearch, super.key});

  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  static const _bellTop = 7.0;
  static const _labelTop = 39.5;
  static const _searchHeight = 44.0;
  static const _textStart = 32.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inset = MediaQuery.paddingOf(context).top;
    // Text-dependent offsets grow with the system text scale (values are
    // the reference layout at 1.0): the balance sits 13 below the label's
    // top, the search 29.5 below the balance line.
    final scale = MediaQuery.textScalerOf(context).scale(20) / 20;
    final balanceTop = _labelTop + 13 * scale;
    final searchTop = balanceTop + 87 * scale + 29.5;
    return SizedBox(
      height: inset + searchTop + _searchHeight + 8,
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
                colors: [AppColors.paleClear, AppColors.pale],
                stops: [.62, 1],
              ),
            ),
          ),
          PositionedDirectional(
            top: inset + _bellTop,
            end: 20,
            child: const UnreadNotificationButton(filled: true),
          ),
          PositionedDirectional(
            top: inset + _labelTop,
            start: _textStart,
            end: 76,
            child: Text(
              l10n.homeYourPoints,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.headerPoints,
              ),
            ),
          ),
          PositionedDirectional(
            top: inset + balanceTop,
            start: _textStart,
            end: 20,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const WalletBalanceText(
                    style: TextStyle(
                      fontSize: 69,
                      fontWeight: FontWeight.w800,
                      color: AppColors.violet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PTS',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ptsLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: inset + searchTop,
            start: 19,
            end: 19,
            height: _searchHeight,
            child: _SearchField(controller: searchController, onSearch: onSearch),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: BorderSide.none,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(color: AppColors.searchGlow, blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: onSearch,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 15, color: AppColors.ink),
          decoration: InputDecoration(
            isCollapsed: true,
            filled: true,
            fillColor: Colors.white.withValues(alpha: .9),
            prefixIcon: const Icon(AppIcons.search, size: 20, color: AppColors.muted),
            prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 44),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.homeClearSearch,
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () {
                      controller.clear();
                      onSearch('');
                    },
                  ),
            contentPadding: const EdgeInsetsDirectional.only(end: 16),
            hintText: l10n.homeSearchHint,
            hintStyle: const TextStyle(fontSize: 15, color: AppColors.searchHint),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
          ),
        ),
      ),
    );
  }
}
