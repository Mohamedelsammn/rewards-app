import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import 'bloc/create_giveaway_cubit.dart';
import 'bloc/create_giveaway_state.dart';

class CreateGiveawayPage extends StatelessWidget {
  const CreateGiveawayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateGiveawayCubit(getIt(), getIt(), getIt()),
      child: const _CreateGiveawayView(),
    );
  }
}

class _CreateGiveawayView extends StatefulWidget {
  const _CreateGiveawayView();

  @override
  State<_CreateGiveawayView> createState() => _CreateGiveawayViewState();
}

class _CreateGiveawayViewState extends State<_CreateGiveawayView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _organizerController = TextEditingController();
  final _prizeController = TextEditingController();
  final _rulesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  Uint8List? _imageBytes;
  String? _imageExtension;

  @override
  void dispose() {
    _titleController.dispose();
    _organizerController.dispose();
    _prizeController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.createGiveawayImageTooLarge)));
      }
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _imageExtension = picked.name.split('.').last;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());
    if (picked == null) return;
    setState(() => _endTime = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    if (_startDate == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.createGiveawayMissingDates)));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.createGiveawayEndBeforeStart)));
      return;
    }

    final endTimeString =
        '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

    context.read<CreateGiveawayCubit>().publish(
      title: _titleController.text.trim(),
      organizerName: _organizerController.text.trim(),
      prizeDescription: _prizeController.text.trim(),
      descriptionRules: _rulesController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      endTime: endTimeString,
      imageBytes: _imageBytes,
      imageExtension: _imageExtension,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.createGiveawayTitle)),
      body: BlocConsumer<CreateGiveawayCubit, CreateGiveawayState>(
        listener: (context, state) {
          if (state.status == CreateGiveawayStatus.success) {
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final isSubmitting = state.status == CreateGiveawayStatus.submitting;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.createGiveawayGiveawayTitle, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(hintText: l10n.createGiveawayGiveawayTitleHint),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commonRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.createGiveawayOrganizerName, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _organizerController,
                    decoration: InputDecoration(hintText: l10n.createGiveawayOrganizerNameHint),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commonRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.createGiveawayPrizeDescription, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _prizeController,
                    maxLines: 2,
                    decoration: InputDecoration(hintText: l10n.createGiveawayPrizeDescriptionHint),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commonRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.createGiveawayRules, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _rulesController,
                    maxLines: 4,
                    decoration: InputDecoration(hintText: l10n.createGiveawayRulesHint),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commonRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.createGiveawayImage, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        border: Border.all(
                          color: AppColors.outlineVariant,
                          style: BorderStyle.solid,
                        ),
                        image: _imageBytes != null
                            ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _imageBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(l10n.createGiveawayTapToBrowse, style: AppTypography.bodyMd),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.createGiveawayImageSizeHint,
                                  style: AppTypography.labelSm,
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: l10n.createGiveawayStartDate,
                          value: _startDate,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _DatePickerField(
                          label: l10n.createGiveawayEndDate,
                          value: _endDate,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.createGiveawayEndTime, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: _pickEndTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Text(
                        _endTime?.format(context) ?? l10n.createGiveawayTimePlaceholder,
                        style: AppTypography.bodyMd,
                      ),
                    ),
                  ),
                  if (state.status == CreateGiveawayStatus.error) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.failure?.localize(l10n) ?? l10n.commonSomethingWrong,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryGradientButton(
                    label: l10n.createGiveawayPublish,
                    icon: Icons.rocket_launch_rounded,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              value != null
                  ? '${value!.month.toString().padLeft(2, '0')}/${value!.day.toString().padLeft(2, '0')}/${value!.year}'
                  : l10n.createGiveawayDatePlaceholder,
              style: AppTypography.bodyMd,
            ),
          ),
        ),
      ],
    );
  }
}
