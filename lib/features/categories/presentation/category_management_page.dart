import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/di/injection.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/giveaway_category.dart';
import '../../../shared/repositories/category_repository.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});
  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _repository = getIt<CategoryRepository>();
  List<GiveawayCategory> _rows = [];
  bool _authorized = false;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authorized = await _repository.canManage();
    if (!mounted) return;
    if (!authorized) {
      setState(() {
        _authorized = false;
        _loading = false;
      });
      return;
    }
    final result = await _repository.getCategories(management: true);
    if (!mounted) return;
    setState(() {
      _authorized = true;
      _loading = false;
      result.fold((f) => _error = f.localize(AppLocalizations.of(context)), (rows) {
        _rows = rows;
        _error = null;
      });
    });
  }

  Future<void> _edit([GiveawayCategory? existing]) async {
    final l10n = AppLocalizations.of(context);
    final en = TextEditingController(text: existing?.nameEn);
    final ar = TextEditingController(text: existing?.nameAr);
    final icon = TextEditingController(text: existing?.icon);
    final order = TextEditingController(text: (existing?.sortOrder ?? 0).toString());
    var active = existing?.isActive ?? true;
    var saving = false;
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: Text(existing == null ? l10n.categoryCreate : l10n.categoryEdit),
            content: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: en,
                      maxLength: 80,
                      decoration: InputDecoration(labelText: l10n.categoryNameEn),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l10n.categoryRequired : null,
                    ),
                    TextFormField(
                      controller: ar,
                      maxLength: 80,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(labelText: l10n.categoryNameAr),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l10n.categoryRequired : null,
                    ),
                    TextFormField(
                      controller: icon,
                      maxLength: 16,
                      decoration: InputDecoration(labelText: l10n.categoryIcon),
                    ),
                    TextFormField(
                      controller: order,
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      decoration: InputDecoration(labelText: l10n.categoryOrder),
                      validator: (v) =>
                          int.tryParse(v ?? '') == null ? l10n.categoryRequired : null,
                    ),
                    SwitchListTile(
                      value: active,
                      title: Text(l10n.categoryEnabled),
                      onChanged: saving ? null : (v) => update(() => active = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        update(() => saving = true);
                        final result = await _repository.save(
                          GiveawayCategory(
                            id: existing?.id ?? '',
                            nameEn: en.text,
                            nameAr: ar.text,
                            icon: icon.text.trim().isEmpty ? null : icon.text.trim(),
                            sortOrder: int.parse(order.text),
                            isActive: active,
                          ),
                          create: existing == null,
                        );
                        if (!dialogContext.mounted) return;
                        result.fold((f) {
                          update(() => saving = false);
                          ScaffoldMessenger.of(
                            dialogContext,
                          ).showSnackBar(SnackBar(content: Text(f.localize(l10n))));
                        }, (_) => Navigator.pop(dialogContext));
                      },
                child: Text(l10n.categorySave),
              ),
            ],
          ),
        ),
      ),
    );
    // Dialog routes finish their dismissal animation before controllers are disposed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    en.dispose();
    ar.dispose();
    icon.dispose();
    order.dispose();
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoryManagement)),
      floatingActionButton: _authorized
          ? FloatingActionButton(
              onPressed: () => _edit(),
              tooltip: l10n.categoryCreate,
              child: const Icon(AppIcons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_authorized
          ? Center(child: Text(l10n.categoryUnauthorized))
          : _error != null
          ? Center(
              child: TextButton(onPressed: _load, child: Text(l10n.commonRetry)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: _rows.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(_rows[i].label(Localizations.localeOf(context).languageCode)),
                  subtitle: Text(
                    '${_rows[i].sortOrder} · ${_rows[i].isActive ? l10n.categoryEnabled : l10n.categoryDisabled}',
                  ),
                  leading: Text(_rows[i].icon ?? '•'),
                  trailing: const Icon(AppIcons.edit),
                  onTap: () => _edit(_rows[i]),
                ),
              ),
            ),
    );
  }
}
