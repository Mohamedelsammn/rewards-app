import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'legal_content.dart';

/// The date these two documents' content (legal_content.dart) was last
/// revised. Update this alongside any edit to that file's copy.
final DateTime kLegalLastUpdated = DateTime.utc(2026, 8, 8);

/// Shared scrollable layout for the Privacy Policy and Terms & Conditions
/// screens (implementation-plan.md Settings section). Both are simple,
/// read-only documents -- no Bloc/Cubit needed, just static content picked
/// per locale by the caller.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.sections,
    this.backgroundColor = AppColors.surface,
  });

  final String title;
  final List<LegalSection> sections;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final lastUpdated = DateFormat.yMMMMd(locale.toString()).format(kLegalLastUpdated);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(title, style: AppTypography.headlineMd),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPadding,
            AppSpacing.sm,
            AppSpacing.containerPadding,
            AppSpacing.xl,
          ),
          children: [
            Text(
              l10n.legalLastUpdated(lastUpdated),
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final section in sections) ...[
              Text(section.title, style: AppTypography.headlineLgMobile.copyWith(fontSize: 18)),
              const SizedBox(height: AppSpacing.sm),
              Text(section.body, style: AppTypography.bodyMd.copyWith(height: 1.5)),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}
