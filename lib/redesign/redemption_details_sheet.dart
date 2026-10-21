import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'demo_repository.dart';

const _ink = Color(0xff0c123e);
const _violet = Color(0xff4824fa);
const _muted = Color(0xff777eaa);

String? validateDemoFulfillmentField(
  DemoFulfillmentField field,
  String value, {
  bool arabic = false,
}) {
  final text = value.trim();
  if (text.isEmpty) return arabic ? 'هذا الحقل مطلوب' : 'This field is required';
  if (field.minLength != null && text.length < field.minLength!) {
    return arabic
        ? 'أدخل ${field.minLength} أحرف على الأقل'
        : 'Enter at least ${field.minLength} characters';
  }
  if (field.maxLength != null && text.length > field.maxLength!) {
    return arabic
        ? 'الحد الأقصى ${field.maxLength} حرفًا'
        : 'Use at most ${field.maxLength} characters';
  }
  if (field.pattern != null && !RegExp(field.pattern!).hasMatch(text)) {
    return arabic ? 'تحقق من صيغة ${field.labelAr}' : 'Check the ${field.label} format';
  }
  if (field.type == DemoFieldType.url) {
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasAuthority || !{'https', 'http'}.contains(uri.scheme)) {
      return arabic ? 'أدخل رابطًا صالحًا' : 'Enter a valid URL';
    }
  }
  if (field.type == DemoFieldType.phone && !RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(text)) {
    return arabic ? 'أدخل رقم هاتف صالحًا' : 'Enter a valid phone number';
  }
  if (field.type == DemoFieldType.number && !RegExp(r'^[0-9]+$').hasMatch(text)) {
    return arabic ? 'استخدم الأرقام فقط' : 'Use digits only';
  }
  return null;
}

Future<Map<String, String>?> showRedemptionDetailsSheet(
  BuildContext context, {
  required DemoProduct product,
  required int balance,
  required String imagePath,
}) => showModalBottomSheet<Map<String, String>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  showDragHandle: false,
  builder: (_) => _RedemptionDetailsSheet(product: product, balance: balance, imagePath: imagePath),
);

class _RedemptionDetailsSheet extends StatefulWidget {
  const _RedemptionDetailsSheet({
    required this.product,
    required this.balance,
    required this.imagePath,
  });
  final DemoProduct product;
  final int balance;
  final String imagePath;

  @override
  State<_RedemptionDetailsSheet> createState() => _RedemptionDetailsSheetState();
}

class _RedemptionDetailsSheetState extends State<_RedemptionDetailsSheet> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final field in widget.product.fulfillmentFields) {
      controllers[field.key] = TextEditingController();
      if (field.confirmEntry) controllers['${field.key}_confirm'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final motion = MediaQuery.of(context).disableAnimations;
    final fields = widget.product.fulfillmentFields;
    return AnimatedPadding(
      duration: motion ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
        decoration: const BoxDecoration(
          color: Color(0xfffbfaff),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Color(0x26806ed8), blurRadius: 30)],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xffd9d3ed),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    arabic ? 'تفاصيل الاستبدال' : 'Redemption details',
                    style: const TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          widget.imagePath,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.title,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${widget.product.points} PTS',
                              style: const TextStyle(
                                color: _violet,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xfff0ecff),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      arabic
                          ? 'الرصيد: ${widget.balance} PTS  •  بعد الاستبدال: ${widget.balance - widget.product.points} PTS'
                          : 'Balance: ${widget.balance} PTS  •  After: ${widget.balance - widget.product.points} PTS',
                      style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final field in fields) ...[
                    _field(field, arabic),
                    if (field.confirmEntry) _field(field, arabic, confirm: true),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    arabic
                        ? 'هذا طلب تجريبي. لن يتم تسليم منتج فعلي.'
                        : 'This is a demo order. No product will be delivered.',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff4031ff), Color(0xff741af2)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: FilledButton(
                      onPressed: widget.balance < widget.product.points
                          ? null
                          : () {
                              if (!formKey.currentState!.validate()) return;
                              Navigator.of(context).pop({
                                for (final field in fields)
                                  field.key: controllers[field.key]!.text.trim(),
                              });
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: const Color(0xffbbb5dd),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(
                        arabic ? 'تأكيد الاستبدال' : 'Confirm redemption',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(DemoFulfillmentField field, bool arabic, {bool confirm = false}) {
    final controller = controllers[confirm ? '${field.key}_confirm' : field.key]!;
    final label = confirm
        ? (arabic ? 'تأكيد ${field.labelAr}' : 'Confirm ${field.label}')
        : (arabic ? field.labelAr : field.label);
    final keyboardType = switch (field.type) {
      DemoFieldType.number => TextInputType.number,
      DemoFieldType.phone => TextInputType.phone,
      DemoFieldType.url => TextInputType.url,
      _ => TextInputType.text,
    };
    return TextFormField(
      key: ValueKey('fulfillment-${field.key}${confirm ? '-confirm' : ''}'),
      controller: controller,
      textDirection: field.type == DemoFieldType.number || field.type == DemoFieldType.url
          ? TextDirection.ltr
          : null,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      maxLength: field.maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: confirm ? null : (arabic ? field.hintAr : field.hint),
        prefixIcon: Icon(
          switch (field.type) {
            DemoFieldType.number => LucideIcons.hash,
            DemoFieldType.phone => LucideIcons.phone,
            DemoFieldType.url => LucideIcons.link,
            _ => LucideIcons.userRound,
          },
          color: _violet,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffdddafa)),
        ),
      ),
      validator: (value) {
        if (confirm) {
          return value?.trim() == controllers[field.key]!.text.trim()
              ? null
              : (arabic ? 'القيمتان غير متطابقتين' : 'Values do not match');
        }
        return validateDemoFulfillmentField(field, value ?? '', arabic: arabic);
      },
    );
  }
}
