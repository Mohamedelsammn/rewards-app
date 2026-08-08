import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'legal_document_page.dart';
import 'legal_content.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LegalDocumentPage(
      title: l10n.privacyPolicyTitle,
      sections: LegalContent.privacyPolicy(Localizations.localeOf(context).languageCode),
    );
  }
}

/// Kept as a distinct class (rather than reusing [PrivacyPolicyPage] with a
/// bool flag) so each screen's back-button label / route name reads clearly
/// in navigation stacks and tests.
class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LegalDocumentPage(
      title: l10n.termsConditionsTitle,
      sections: LegalContent.termsConditions(Localizations.localeOf(context).languageCode),
      backgroundColor: AppColors.surface,
    );
  }
}
