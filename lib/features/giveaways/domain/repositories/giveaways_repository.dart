import '../../../../core/utils/cursor_page.dart';
import '../entities/giveaway_entities.dart';

abstract interface class GiveawaysRepository {
  Future<CursorPage<Giveaway>> giveaways({
    required GiveawayListFilter filter,
    String? query,
    String? cursor,
  });

  Future<GiveawayDetails> details(String id);

  Future<StepProgress> submitStep({
    required String giveawayId,
    required String stepId,
    String? proofText,
  });

  /// Creates the entry, or returns the existing one (the server never
  /// assigns a second number).
  Future<GiveawayEntry> enter(String giveawayId);

  /// `null` until winners are announced (`404`).
  Future<List<GiveawayWinner>?> results(String giveawayId);

  Future<CursorPage<GiveawayEntry>> myEntries({EntryResult? result, String? cursor});

  Future<List<Winning>> pendingCelebrations();

  Future<void> acknowledgeCelebration(String winningId);

  Future<Winning> claim(String winningId, String contact);
}
