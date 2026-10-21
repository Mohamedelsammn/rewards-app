import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../app_config/presentation/app_config_cubit.dart';

/// Referral is not implemented by the API, so this shares the store link
/// only and promises no reward.
class ReferPage extends StatelessWidget {
  const ReferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final configured = context.read<AppConfigCubit>().state.config.storeUrl;
    final link = configured.isEmpty ? AppConstants.playStoreUrl : configured;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.referTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.people_alt_outlined, size: 90, color: AppColors.violet),
          const SizedBox(height: 18),
          Text(
            l10n.referHeadline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.referBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 20),
          SelectableText(
            link,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: AppColors.violet,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            l10n.referCopy,
            icon: Icons.copy,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) showAppSnackBar(context, l10n.referCopied);
            },
          ),
        ],
      ),
    );
  }
}
