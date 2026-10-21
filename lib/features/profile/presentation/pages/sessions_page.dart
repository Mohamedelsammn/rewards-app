import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/auth_entities.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';

/// `GET /auth/sessions`, `DELETE /auth/sessions/:id`, `POST /auth/logout-all`.
class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final _auth = sl<AuthRepository>();
  late Future<List<DeviceSession>> _sessions = _auth.sessions();
  bool _busy = false;

  void _reload() => setState(() => _sessions = _auth.sessions());

  Future<void> _guarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(DeviceSession session) => _guarded(() async {
    await _auth.revokeSession(session.id);
    if (!mounted) return;
    showAppSnackBar(context, context.l10n.sessionsRevoked);
    _reload();
  });

  Future<void> _logoutAll() async {
    final l10n = context.l10n;
    final session = context.read<SessionCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      icon: AppIcons.logout,
      title: l10n.sessionsLogoutAll,
      message: l10n.sessionsLogoutAllMessage,
      confirmLabel: l10n.sessionsRevoke,
      destructive: true,
    );
    if (!confirmed) return;
    await _guarded(() async {
      await _auth.logoutAll();
      await session.endLocally();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: FutureBuilder<List<DeviceSession>>(
          future: _sessions,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <DeviceSession>[];
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SecondaryHeader(title: l10n.sessionsTitle, subtitle: l10n.sessionsSubtitle),
                  const SizedBox(height: 20),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Padding(padding: EdgeInsets.all(40), child: LoadingView())
                  else if (snapshot.hasError)
                    ErrorStateView(error: snapshot.error!, onRetry: _reload)
                  else ...[
                    for (final session in items)
                      _SessionTile(
                        session: session,
                        onRevoke: session.current || _busy ? null : () => _revoke(session),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _logoutAll,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(AppIcons.logout),
                      label: Text(l10n.sessionsLogoutAll),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onRevoke});

  final DeviceSession session;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lastUsed = session.lastUsedAt ?? session.createdAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: const Icon(LucideIcons.smartphone, color: AppColors.violet),
        title: Text(
          session.deviceName?.isNotEmpty ?? false
              ? session.deviceName!
              : l10n.sessionsUnknownDevice,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          session.current
              ? l10n.sessionsCurrent
              : lastUsed == null
              ? ''
              : l10n.sessionsLastUsed(Formatters.dateTime(context, lastUsed)),
        ),
        trailing: session.current
            ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
            : TextButton(onPressed: onRevoke, child: Text(l10n.sessionsRevoke)),
      ),
    );
  }
}
