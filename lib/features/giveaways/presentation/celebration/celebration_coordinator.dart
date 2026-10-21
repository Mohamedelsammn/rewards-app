import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../domain/repositories/giveaways_repository.dart';

/// Shows each pending winner celebration once
/// (`GET /me/winnings/pending-celebration`). Runs on start, on resume and on
/// a `WINNER_SELECTED` push. The page acknowledges each celebration.
class CelebrationCoordinator {
  CelebrationCoordinator(this._repository);

  final GiveawaysRepository _repository;
  bool _running = false;

  Future<void> check(BuildContext Function() context) async {
    if (_running) return;
    _running = true;
    try {
      final pending = await _repository.pendingCelebrations();
      for (final winning in pending) {
        final current = context();
        if (!current.mounted) return;
        await current.push(Routes.celebration, extra: winning);
      }
    } catch (_) {
      // Best effort: retried on the next resume.
    } finally {
      _running = false;
    }
  }
}
