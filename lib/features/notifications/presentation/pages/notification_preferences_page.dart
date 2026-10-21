import 'package:flutter/material.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/notification_entities.dart';

/// `GET/PUT /me/notification-preferences`. Each toggle saves immediately and
/// rolls back on failure.
class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  final _repository = sl<NotificationsRepository>();
  NotificationPreferences? _preferences;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final preferences = await _repository.preferences();
      if (mounted) setState(() => _preferences = preferences);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _save(NotificationPreferences next) async {
    final previous = _preferences;
    setState(() {
      _preferences = next;
      _saving = true;
    });
    try {
      final saved = await _repository.updatePreferences(next);
      if (mounted) setState(() => _preferences = saved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _preferences = previous);
      showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preferences = _preferences;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SecondaryHeader(
              title: l10n.notificationPrefsTitle,
              subtitle: l10n.notificationPrefsSubtitle,
            ),
            const SizedBox(height: 20),
            if (_error != null)
              ErrorStateView(error: _error!, onRetry: _load)
            else if (preferences == null)
              const Padding(padding: EdgeInsets.all(40), child: LoadingView())
            else ...[
              _toggle(
                l10n.prefOrders,
                l10n.prefOrdersSubtitle,
                preferences.orders,
                (value) => _save(preferences.copyWith(orders: value)),
              ),
              _toggle(
                l10n.prefGiveaways,
                l10n.prefGiveawaysSubtitle,
                preferences.giveaways,
                (value) => _save(preferences.copyWith(giveaways: value)),
              ),
              _toggle(
                l10n.prefAnnouncements,
                l10n.prefAnnouncementsSubtitle,
                preferences.announcements,
                (value) => _save(preferences.copyWith(announcements: value)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SwitchListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          activeThumbColor: AppColors.violet,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          value: value,
          onChanged: _saving ? null : onChanged,
        ),
      );
}
