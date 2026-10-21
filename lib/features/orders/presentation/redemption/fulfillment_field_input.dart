import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';

/// Client-side validation mirroring the server codes `REQUIRED`,
/// `INVALID_FORMAT` and `INVALID_OPTION`. The server re-validates.
String? validateFulfillmentField(BuildContext context, ProductField field, String raw) {
  final l10n = context.l10n;
  final value = raw.trim();
  if (value.isEmpty) return field.required ? l10n.redeemFieldRequired : null;
  final pattern = field.pattern;
  if (pattern != null) {
    try {
      if (!RegExp(pattern).hasMatch(value)) return l10n.redeemFieldInvalid(field.label.of(context));
    } on FormatException {
      // An invalid admin pattern is left to the server.
    }
  }
  return switch (field.type) {
    FieldType.number when !RegExp(r'^[0-9]+$').hasMatch(value) => l10n.redeemInvalidNumber,
    FieldType.url when !_isUrl(value) => l10n.redeemInvalidUrl,
    FieldType.phone when !RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(value) =>
      l10n.redeemInvalidPhone,
    FieldType.email when !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value) =>
      l10n.authInvalidEmail,
    FieldType.select when !field.options.contains(value) => l10n.redeemInvalidOption,
    _ => null,
  };
}

bool _isUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.hasAuthority && (uri.scheme == 'https' || uri.scheme == 'http');
}

/// Maps a server field error code to a localized message.
String serverFieldError(BuildContext context, ProductField field, String code) => switch (code) {
  'REQUIRED' => context.l10n.redeemFieldRequired,
  'INVALID_OPTION' => context.l10n.redeemInvalidOption,
  _ => context.l10n.redeemFieldInvalid(field.label.of(context)),
};

class FulfillmentFieldInput extends StatelessWidget {
  const FulfillmentFieldInput({
    required this.field,
    required this.controller,
    this.serverError,
    super.key,
  });

  final ProductField field;
  final TextEditingController controller;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    final label = field.label.of(context);
    final decoration = InputDecoration(
      labelText: field.required ? label : '$label (${context.l10n.giveawayStepOptional})',
      errorText: serverError,
      prefixIcon: Icon(_icon, color: AppColors.violet, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
    );
    if (field.type == FieldType.select) {
      return DropdownButtonFormField<String>(
        key: ValueKey('fulfillment-${field.key}'),
        initialValue: field.options.contains(controller.text) ? controller.text : null,
        isExpanded: true,
        hint: Text(context.l10n.redeemSelectHint),
        decoration: decoration,
        items: [
          for (final option in field.options)
            DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) => controller.text = value ?? '',
        validator: (value) => validateFulfillmentField(context, field, value ?? ''),
      );
    }
    final ltr = const {FieldType.number, FieldType.url, FieldType.phone, FieldType.email};
    return TextFormField(
      key: ValueKey('fulfillment-${field.key}'),
      controller: controller,
      textDirection: ltr.contains(field.type) ? TextDirection.ltr : null,
      keyboardType: switch (field.type) {
        FieldType.number => TextInputType.number,
        FieldType.phone => TextInputType.phone,
        FieldType.url => TextInputType.url,
        FieldType.email => TextInputType.emailAddress,
        _ => TextInputType.text,
      },
      textInputAction: TextInputAction.next,
      decoration: decoration,
      validator: (value) => validateFulfillmentField(context, field, value ?? ''),
    );
  }

  IconData get _icon => switch (field.type) {
    FieldType.number => LucideIcons.hash,
    FieldType.phone => LucideIcons.phone,
    FieldType.url => LucideIcons.link,
    FieldType.email => LucideIcons.mail,
    FieldType.select => LucideIcons.list,
    FieldType.text => LucideIcons.userRound,
  };
}
