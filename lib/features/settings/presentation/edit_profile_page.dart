import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import 'package:flutter/services.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_util.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/secure_storage_service.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/widgets/primary_gradient_button.dart';

/// Edit Profile -- name and phone. Routed entirely through
/// [UserRepository.updateProfile] (`fn_update_user_profile`, SECURITY
/// DEFINER), which is the only server-authoritative source of truth for
/// phone-uniqueness; this page never assumes a phone is free just because it
/// "looks" unique client-side. On success, the locally cached identity
/// ([SecureStorageService]) is updated too, so Settings/other cached-identity
/// displays reflect the change immediately without a fresh network read.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Country _country = kCountries.first;
  bool _loading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final storage = getIt<SecureStorageService>();
    final fullName = await storage.cachedFullName;
    final phone = await storage.cachedPhone;
    final countryCode = await storage.cachedCountryCode;

    // Prefer the cached ISO country code (unambiguous); fall back to
    // matching by dial-code prefix for identities cached before this field
    // existed, and finally to the first list entry as a last resort.
    final country = kCountries.firstWhere(
      (c) => c.iso2 == countryCode,
      orElse: () => kCountries.firstWhere(
        (c) => phone != null && phone.startsWith('+${c.dialCode}'),
        orElse: () => kCountries.first,
      ),
    );
    final localNumber = (phone != null && phone.startsWith('+${country.dialCode}'))
        ? phone.substring(country.dialCode.length + 1)
        : (phone ?? '');

    if (!mounted) return;
    setState(() {
      _nameController.text = fullName ?? '';
      _phoneController.text = localNumber;
      _country = country;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final normalized = PhoneUtil.normalize(_phoneController.text, _country.dialCode);
    if (normalized == null) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);

    final result = await getIt<UserRepository>().updateProfile(
      fullName: _nameController.text.trim(),
      phone: normalized,
      countryCode: _country.iso2,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await result.fold(
      (failure) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.localize(l10n)), backgroundColor: AppColors.error),
        );
      },
      (profile) async {
        await getIt<SecureStorageService>().saveIdentity(
          userId: profile.id,
          fullName: profile.fullName,
          phone: profile.phoneE164,
          countryCode: profile.countryCode,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.editProfileUpdateSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.editProfileSubtitle, style: AppTypography.bodyMd),
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
                        validator: (value) => (value == null || value.trim().length < 2)
                            ? l10n.registrationFullNameError
                            : null,
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
                              // Country-aware, not a global maxLength -- see
                              // RegistrationForm's matching field for why
                              // this allows one extra digit (a leading
                              // trunk '0').
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(_country.maxNationalDigits + 1),
                              ],
                              decoration: InputDecoration(hintText: l10n.registrationPhoneHint),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.registrationPhoneRequiredError;
                                }
                                if (!PhoneUtil.isValidLocalNumber(value, _country.dialCode)) {
                                  return l10n.registrationPhoneInvalidError;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryGradientButton(
                        label: l10n.editProfileSaveAction,
                        icon: AppIcons.check,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
