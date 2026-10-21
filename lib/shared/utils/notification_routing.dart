import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../features/giveaway_details/presentation/giveaway_details_page.dart';
import '../../features/winner_celebration/presentation/winner_celebration_page.dart';
import '../../services/secure_storage_service.dart';
import '../repositories/winner_repository.dart';

/// Routes a tapped notification to the right screen based on its `type`.
///
/// Shared by both notification entry points -- an FCM push tap
/// (`UserHomeShell.onNotificationTapped`) and an in-app tap from
/// [NotificationsPage] -- so there is exactly one notification-routing
/// implementation, not two that could drift apart.
///
/// The payload only ever selects *where to navigate*; it is never used to
/// decide *what happened*. A `winner_announcement` (or unknown/empty type)
/// tap always re-runs the server-authoritative pending-winner check via
/// [checkForPendingWinnerAndCelebrate] -- it never trusts the payload's own
/// claim that the user won.
Future<void> routeNotificationTap(BuildContext context, Map<String, dynamic> data) async {
  final type = data['type'] as String?;
  switch (type) {
    case 'giveaway_reminder':
      final giveawayId = data['giveawayId'] as String?;
      if (giveawayId != null && context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(settings: giveawayDetailsSettings(giveawayId), builder: (_) => GiveawayDetailsPage(giveawayId: giveawayId)));
      }
    case 'winner_announcement':
    default:
      await checkForPendingWinnerAndCelebrate(context);
  }
}

/// Checked on shell mount (app launch / role re-entry) and whenever a
/// notification is tapped -- the server-side `celebration_acknowledged_at`
/// gate is what actually guarantees exactly-once, this is just when we ask.
Future<void> checkForPendingWinnerAndCelebrate(BuildContext context) async {
  final userId = await getIt<SecureStorageService>().cachedUserId;
  if (userId == null || !context.mounted) return;

  var result = await getIt<WinnerRepository>().getMyPendingWinner(userId);
  if (result.isFailure) {
    // A failure right after a session switch (e.g. the client's auth
    // attachment still settling) must not permanently forfeit the one
    // chance to show this -- the server-side celebration_acknowledged_at
    // gate, not this single request succeeding on the first try, is what
    // actually guarantees exactly-once. One bounded retry is enough to ride
    // out a transient blip without turning this into a polling loop.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    result = await getIt<WinnerRepository>().getMyPendingWinner(userId);
  }

  final winner = result.fold((_) => null, (w) => w);
  if (winner == null || !context.mounted) return;

  // Awaited (not fire-and-forget) so a caller can treat "this call is still
  // running" as "the celebration is still on screen" -- see UserHomeShell's
  // re-entrancy guard, which relies on exactly that to avoid a realtime
  // event and the mount-time/notification-tap checks racing into a second
  // celebration page stacked on top of the first.
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => WinnerCelebrationPage(winner: winner),
    ),
  );
}
