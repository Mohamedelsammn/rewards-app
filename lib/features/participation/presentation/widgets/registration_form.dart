import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/phone_util.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';

/// "Create Your Account" -- Full Name, Country, Phone (tasks.md T09-01/T09-02).
/// Validation mirrors the server's fn_normalize_phone exactly (7-15 digits)
/// so a number accepted here is guaranteed to be accepted server-side too.
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key, required this.isSubmitting, required this.onSubmit});

  final bool isSubmitting;
  final void Function(String fullName, String phone, String countryCode) onSubmit;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Country _country = kCountries.first;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final normalized = PhoneUtil.normalize(_phoneController.text, _country.dialCode);
    if (normalized == null) return;
    widget.onSubmit(_nameController.text.trim(), normalized, _country.iso2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.gift, color: AppColors.primary, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.registrationTitle,
            style: AppTypography.headlineMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.registrationSubtitle, style: AppTypography.bodyMd, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.registrationFullNameLabel, style: AppTypography.labelSm),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: l10n.registrationFullNameHint,
              prefixIcon: const Icon(AppIcons.profile),
            ),
            validator: (value) =>
                (value == null || value.trim().length < 2) ? l10n.registrationFullNameError : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.registrationCountryLabel, style: AppTypography.labelSm),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<Country>(
            initialValue: _country,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: kCountries
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      '${c.flagEmoji}  ${c.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (c) => setState(() => _country = c ?? _country),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.registrationPhoneLabel, style: AppTypography.labelSm),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                alignment: Alignment.center,
                child: Text('+${_country.dialCode}', style: AppTypography.bodyMd),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  // Country-aware, not a global maxLength -- a leading trunk
                  // '0' is still allowed to be typed (PhoneUtil.normalize
                  // strips exactly one), so the formatter allows one extra
                  // digit beyond the country's national length.
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_country.maxNationalDigits + 1),
                  ],
                  decoration: InputDecoration(hintText: l10n.registrationPhoneHint),
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.registrationPhoneRequiredError;
                    if (!PhoneUtil.isValidLocalNumber(value, _country.dialCode)) {
                      return l10n.registrationPhoneInvalidError;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryGradientButton(
            label: l10n.registrationContinue,
            icon: AppIcons.forward,
            isLoading: widget.isSubmitting,
            onPressed: widget.isSubmitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.registrationAgreeTerms,
            style: AppTypography.labelSm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
