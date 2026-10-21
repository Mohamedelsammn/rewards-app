import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../bloc/giveaway_cubits.dart';

/// One row per giveaway step with its progress and action.
class GiveawayStepTile extends StatelessWidget {
  const GiveawayStepTile({
    required this.step,
    required this.progress,
    required this.busy,
    required this.enabled,
    super.key,
  });

  final GiveawayStep step;
  final StepProgress? progress;
  final bool busy;
  final bool enabled;

  Future<void> _complete(BuildContext context) async {
    final cubit = context.read<GiveawayDetailsCubit>();
    String? proof;
    if (step.verification == StepVerification.adminReview) {
      proof = await _askProof(context);
      if (proof == null) return;
    }
    final url = step.url;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    final ok = await cubit.submitStep(step, proofText: proof);
    if (!ok && context.mounted && cubit.state.error != null) {
      showErrorSnackBar(context, cubit.state.error!);
    }
  }

  Future<String?> _askProof(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.giveawayStepProofTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          decoration: InputDecoration(hintText: l10n.giveawayStepProofHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(dialogContext, text);
            },
            child: Text(l10n.giveawayStepSubmit),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = progress?.status;
    final done = progress?.isDone ?? false;
    final (label, color) = switch (status) {
      StepProgressStatus.completed => (l10n.giveawayStepDone, AppColors.success),
      StepProgressStatus.approved => (l10n.giveawayStepApproved, AppColors.success),
      StepProgressStatus.submitted => (l10n.giveawayStepSubmitted, AppColors.warning),
      StepProgressStatus.rejected => (l10n.giveawayStepRejected, AppColors.danger),
      null => (step.required ? '' : l10n.giveawayStepOptional, AppColors.muted),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.listCard,
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: done ? AppColors.success : AppColors.violet,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title.of(context),
                    style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                  if (label.isNotEmpty) Text(label, style: TextStyle(color: color, fontSize: 12)),
                  if (progress?.note?.isNotEmpty ?? false)
                    Text(
                      progress!.note!,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (!done)
              busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: enabled ? () => _complete(context) : null,
                      child: Text(l10n.giveawayStepComplete),
                    ),
          ],
        ),
      ),
    );
  }
}
