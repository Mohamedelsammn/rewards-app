import 'package:flutter/material.dart';

import '../error/app_exception.dart';
import '../localization/error_messages.dart';
import '../localization/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// White rounded card with a centered message (redesign `_emptyCard`).
class EmptyCard extends StatelessWidget {
  const EmptyCard(this.message, {this.icon, super.key});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
    child: Column(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.violet, size: 36),
          const SizedBox(height: 12),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
      ],
    ),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({this.padding = const EdgeInsets.all(40), super.key});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: const Center(child: CircularProgressIndicator(color: AppColors.violet)),
  );
}

/// Error card with a localized message, the support `requestId` when the
/// server returned one, and a retry action.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is AppException && (error as AppException).isConnectivity;
    final requestId = error is AppException ? (error as AppException).requestId : null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(offline ? AppIcons.wifiOff : AppIcons.error, color: AppColors.violet, size: 38),
          const SizedBox(height: 12),
          Text(
            errorMessage(context, error),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (requestId != null) ...[
            const SizedBox(height: 6),
            SelectableText(
              context.l10n.errorReference(requestId),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.tonal(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
        ],
      ),
    );
  }
}

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showErrorSnackBar(BuildContext context, Object error) =>
    showAppSnackBar(context, errorMessage(context, error));
