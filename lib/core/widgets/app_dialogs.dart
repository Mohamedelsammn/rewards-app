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
                    child: Text(dialogContext.l10n.commonCancel),
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
