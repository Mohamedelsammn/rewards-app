import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';

/// Password field with its own show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.autofillHints = const [AutofillHints.newPassword],
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.controller,
    obscureText: !_visible,
    textInputAction: widget.textInputAction,
    autofillHints: widget.autofillHints,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _visible ? context.l10n.hidePassword : context.l10n.showPassword,
        onPressed: () => setState(() => _visible = !_visible),
        icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      ),
    ),
  );
}

/// The three live password rules of the redesign.
class PasswordRules extends StatelessWidget {
  const PasswordRules({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _rule(l10n.passwordRuleLength, Validators.passwordLength(password)),
        _rule(l10n.passwordRuleLettersNumbers, Validators.passwordHasLettersAndNumbers(password)),
        _rule(l10n.passwordRuleStrong, Validators.passwordIsStrong(password)),
      ],
    );
  }

  Widget _rule(String label, bool satisfied) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle : Icons.circle_outlined,
          color: satisfied ? AppColors.success : AppColors.muted,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 15)),
        ),
      ],
    ),
  );
}
