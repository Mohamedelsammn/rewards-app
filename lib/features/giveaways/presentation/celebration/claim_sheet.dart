import 'package:flutter/material.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/error_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/sheet_frame.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../../domain/repositories/giveaways_repository.dart';

/// `POST /me/winnings/:id/claim { contact }`. Returns the updated winning.
Future<Winning?> showClaimSheet(BuildContext context, Winning winning) =>
    showModalBottomSheet<Winning>(
      context: context,
      // Above the shell's bottom navigation bar.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClaimSheet(winning: winning),
    );

class _ClaimSheet extends StatefulWidget {
  const _ClaimSheet({required this.winning});

  final Winning winning;

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  final _contact = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final contact = _contact.text.trim();
    if (contact.length < 3 || contact.length > 500) {
      setState(() => _error = l10n.claimInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final claimed = await sl<GiveawaysRepository>().claim(widget.winning.id, contact);
      if (!mounted) return;
      showAppSnackBar(context, l10n.claimDone);
      Navigator.pop(context, claimed);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SheetFrame(
        title: l10n.celebrationClaim,
        children: [
          TextField(
            controller: _contact,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(hintText: l10n.claimHint, errorText: _error),
          ),
          const SizedBox(height: 16),
          GradientButton(l10n.claimSubmit, busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
