import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';

/// Six visible cells backed by one invisible field, so paste and SMS/email
/// autofill work. Always laid out left-to-right.
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    required this.controller,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      height: 76,
      child: Stack(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => Row(
              children: List.generate(
                6,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .85),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: index == value.text.length ? AppColors.violet : AppColors.otpBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      index < value.text.length ? value.text[index] : '',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: .01,
              child: Semantics(
                label: context.l10n.otpCodeLabel,
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
