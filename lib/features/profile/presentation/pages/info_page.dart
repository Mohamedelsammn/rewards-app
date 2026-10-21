import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_info.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../app_config/presentation/app_config_cubit.dart';

/// About, Privacy Policy and Terms. Legal documents are hosted at the URLs
/// from `/app-config`; nothing is invented when a URL is not configured.
class InfoPage extends StatelessWidget {
  const InfoPage({required this.kind, super.key});

  final InfoKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = context.read<AppConfigCubit>().state.config;
    final (title, url) = switch (kind) {
      InfoKind.about => (l10n.aboutTitle, ''),
      InfoKind.privacy => (l10n.privacyTitle, config.privacyUrl),
      InfoKind.terms => (l10n.termsTitle, config.termsUrl),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (kind == InfoKind.about) ...[
            Center(
              // The logo file has an opaque black margin and square corners;
              // scale past the margin and clip to the tile's rounded shape.
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: SizedBox.square(
                  dimension: 96,
                  child: Transform.scale(
                    scale: 1.06,
                    child: Image.asset(AppAssets.appLogo, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.aboutBody, style: const TextStyle(fontSize: 17, height: 1.6)),
            const SizedBox(height: 16),
            Text(
              l10n.settingsVersion(sl<AppInfo>().version),
              style: const TextStyle(color: AppColors.muted),
            ),
          ] else if (url.isEmpty)
            Text(l10n.legalUnavailable, style: const TextStyle(fontSize: 17, height: 1.6))
          else ...[
            SelectableText(
              url,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: AppColors.violet, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            GradientButton(
              l10n.legalOpen,
              icon: Icons.open_in_new,
              onPressed: () async {
                final opened = await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && context.mounted) showAppSnackBar(context, l10n.legalUnavailable);
              },
            ),
          ],
        ],
      ),
    );
  }
}
