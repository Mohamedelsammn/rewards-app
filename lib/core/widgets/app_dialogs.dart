import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The redesign's rounded confirmation dialog (sign-out style).
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  String? cancelLabel,
}) async {
  final accent = destructive ? AppColors.danger : AppColors.violet;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.sheet,
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
                color: destructive ? AppColors.dangerIconSurface : AppColors.tint,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 18),
            Text(title, style: AppTypography.sheetTitle),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(cancelLabel ?? dialogContext.l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: destructive ? AppColors.dangerButton : AppColors.violet,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(confirmLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result == true;
}

/// Simple informational dialog with a single OK action.
Future<void> showAppInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    backgroundColor: AppColors.sheet,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: Text(dialogContext.l10n.commonOk),
      ),
    ],
  ),
);

/// Shows [builder] as a rounded, lavender-white dialog card with a soft
/// fade + scale entrance (instant when animations are disabled). Content is
/// scrollable on short screens and kept inside the safe area.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: AppColors.dialogBarrier,
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 240),
  pageBuilder: (dialogContext, _, _) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: AppColors.sheet,
            borderRadius: BorderRadius.circular(30),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: SingleChildScrollView(child: builder(dialogContext)),
          ),
        ),
      ),
    ),
  ),
  transitionBuilder: (_, animation, _, child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: .94, end: 1).animate(curved),
        child: child,
      ),
    );
  },
);
