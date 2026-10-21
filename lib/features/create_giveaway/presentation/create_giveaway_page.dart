import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../../shared/models/giveaway.dart';
import '../../../shared/models/giveaway_category.dart';
import '../../../shared/repositories/category_repository.dart';
import 'bloc/create_giveaway_cubit.dart';
import 'bloc/create_giveaway_state.dart';

class CreateGiveawayPage extends StatelessWidget {
  const CreateGiveawayPage({super.key, this.giveaway});
  final Giveaway? giveaway;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateGiveawayCubit(getIt(), getIt(), getIt()),
      child: _CreateGiveawayView(giveaway: giveaway),
    );
  }
}

class _CreateGiveawayView extends StatefulWidget {
  const _CreateGiveawayView({this.giveaway});
  final Giveaway? giveaway;

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
  TimeOfDay? _startTime;
  String? _categoryId;
  List<GiveawayCategory> _categories = [];
  bool _categoriesLoading = true;
  bool _categoriesFailed = false;
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    final g = widget.giveaway;
    if (g != null) {
      _titleController.text = g.title;
      _organizerController.text = g.organizerName;
      _prizeController.text = g.prizeDescription;
      _rulesController.text = g.descriptionRules;
      _startDate = g.startsAt;
      _endDate = g.endsAt;
      _startTime = TimeOfDay.fromDateTime(g.startsAt);
      _endTime = TimeOfDay.fromDateTime(g.endsAt);
      _categoryId = g.categoryId;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!getIt.isRegistered<CategoryRepository>()) {
      setState(() => _categoriesLoading = false);
      return;
    }
    final result = await getIt<CategoryRepository>().getCategories();
    if (!mounted) return;
    setState(() {
      _categoriesLoading = false;
      result.fold((_) => _categoriesFailed = true, (rows) {
        _categories = rows;
        _categoriesFailed = false;
      });
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) setState(() => _startTime = picked);
  }

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
    final firstDate = widget.giveaway == null
        ? now.subtract(const Duration(days: 1))
        : DateTime(2000);
    final lastDate = now.add(const Duration(days: 3650));
    final current = isStart ? _startDate : _endDate;
    final initialDate = current == null
        ? now
        : current.isBefore(firstDate)
        ? firstDate
        : current.isAfter(lastDate)
        ? lastDate
        : current;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
    if (picked == null || !mounted) return;
    setState(() => _endTime = picked);
  }

  void _submit() {
    setState(() => _attemptedSubmit = true);
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null || _endTime == null || _startTime == null) {
      return;
    }
    final startsAt = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endsAt = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
    if (!endsAt.isAfter(startsAt)) {
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
      categoryId: _categoryId,
      startsAt: startsAt,
      endsAt: endsAt,
      editingId: widget.giveaway?.id,
      existingImageUrl: widget.giveaway?.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.giveaway == null ? l10n.createGiveawayTitle : l10n.createGiveawayEditTitle,
        ),
      ),
      body: BlocConsumer<CreateGiveawayCubit, CreateGiveawayState>(
        listener: (context, state) {
          if (state.status == CreateGiveawayStatus.success) {
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final isSubmitting = state.status == CreateGiveawayStatus.submitting;
          final scheduleLocked =
              widget.giveaway != null &&
              (widget.giveaway!.effectiveStatus == GiveawayStatus.active ||
                  widget.giveaway!.effectiveStatus == GiveawayStatus.ended ||
                  widget.giveaway!.participantCount > 0);
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
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(hintText: l10n.createGiveawayGiveawayTitleHint),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commonRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.categorySelect.toUpperCase(), style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  if (_categoriesLoading)
                    const SizedBox(height: 56, child: Center(child: LinearProgressIndicator()))
                  else if (_categoriesFailed)
                    TextButton(onPressed: _loadCategories, child: Text(l10n.browseCategoriesRetry))
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _categories.any((c) => c.id == _categoryId)
                          ? _categoryId
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: l10n.categorySelect,
                        prefixIcon: const Icon(AppIcons.categories),
                      ),
                      items: [
                        DropdownMenuItem(value: '', child: Text(l10n.categoryUncategorized)),
                        ..._categories.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.label(Localizations.localeOf(context).languageCode),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (id) => setState(() => _categoryId = id == '' ? null : id),
                    ),
                  if (_categoryId != null && !_categories.any((c) => c.id == _categoryId))
                    Text(l10n.categoryInactiveKept, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.createGiveawayOrganizerName, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _organizerController,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(hintText: l10n.createGiveawayOrganizerNameHint),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commonRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.createGiveawayPrizeDescription, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  // Optional -- no validator. Giveaway Details hides each
                  // section gracefully (no empty box, no literal "null")
                  // when left blank; see _LoadedView's `if` guards there.
                  TextFormField(
                    controller: _prizeController,
                    maxLines: 2,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(hintText: l10n.createGiveawayPrizeDescriptionHint),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.createGiveawayRules, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _rulesController,
                    maxLines: 4,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(hintText: l10n.createGiveawayRulesHint),
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
                                const Icon(AppIcons.upload, color: AppColors.primary, size: 32),
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
                  Text(l10n.adminDashboardScheduleSection, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.scheduleLocalTime, style: AppTypography.labelSm),
                  if (scheduleLocked) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.adminScheduleEditLocked,
                      style: AppTypography.labelSm.copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 380;
                      final fieldWidth = wide
                          ? (constraints.maxWidth - AppSpacing.sm) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.md,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: _DatePickerField(
                              label: l10n.createGiveawayStartDate,
                              value: _startDate,
                              errorText: _attemptedSubmit && _startDate == null
                                  ? l10n.commonRequired
                                  : null,
                              enabled: !isSubmitting && !scheduleLocked,
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _TimePickerField(
                              label: l10n.scheduleStartTime,
                              value: _startTime,
                              placeholder: l10n.createGiveawayTimePlaceholder,
                              errorText: _attemptedSubmit && _startTime == null
                                  ? l10n.commonRequired
                                  : null,
                              enabled: !isSubmitting && !scheduleLocked,
                              onTap: _pickStartTime,
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _DatePickerField(
                              label: l10n.createGiveawayEndDate,
                              value: _endDate,
                              errorText: _attemptedSubmit && _endDate == null
                                  ? l10n.commonRequired
                                  : null,
                              enabled: !isSubmitting && !scheduleLocked,
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _TimePickerField(
                              label: l10n.createGiveawayEndTime,
                              value: _endTime,
                              placeholder: l10n.createGiveawayTimePlaceholder,
                              errorText: _attemptedSubmit && _endTime == null
                                  ? l10n.commonRequired
                                  : null,
                              enabled: !isSubmitting && !scheduleLocked,
                              onTap: _pickEndTime,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_attemptedSubmit &&
                      _startDate != null &&
                      _endDate != null &&
                      _startTime != null &&
                      _endTime != null &&
                      !DateTime(
                        _endDate!.year,
                        _endDate!.month,
                        _endDate!.day,
                        _endTime!.hour,
                        _endTime!.minute,
                      ).isAfter(
                        DateTime(
                          _startDate!.year,
                          _startDate!.month,
                          _startDate!.day,
                          _startTime!.hour,
                          _startTime!.minute,
                        ),
                      )) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.scheduleInvalidDates,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                    ),
                  ],
                  if (state.status == CreateGiveawayStatus.error) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.failure?.localize(l10n) ?? l10n.commonSomethingWrong,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryGradientButton(
                    label: widget.giveaway == null
                        ? l10n.createGiveawayPublish
                        : l10n.createGiveawayEditTitle,
                    icon: AppIcons.publish,
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
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: enabled ? onTap : null,
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(AppIcons.calendar, size: 18),
              errorText: errorText,
              enabled: enabled,
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

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    required this.enabled,
    this.errorText,
  });

  final String label;
  final TimeOfDay? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.labelSm),
      const SizedBox(height: AppSpacing.xs),
      InkWell(
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: const Icon(AppIcons.clock, size: 18),
            errorText: errorText,
            enabled: enabled,
          ),
          child: Text(value?.format(context) ?? placeholder, style: AppTypography.bodyMd),
        ),
      ),
    ],
  );
}
