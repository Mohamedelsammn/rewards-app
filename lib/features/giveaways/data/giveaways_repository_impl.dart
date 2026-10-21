import '../../../core/error/app_exception.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../domain/entities/giveaway_entities.dart';
import '../domain/repositories/giveaways_repository.dart';
import 'giveaway_models.dart';

class GiveawaysRepositoryImpl implements GiveawaysRepository {
  const GiveawaysRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<CursorPage<Giveaway>> giveaways({
    required GiveawayListFilter filter,
    String? query,
    String? cursor,
  }) async => CursorPage.fromJson(
    await _api.get(
      '/giveaways',
      auth: false,
      query: {
        'status': filter.apiValue,
        'q': query,
        'cursor': cursor,
        'limit': AppConstants.pageSize,
      },
    ),
    GiveawayModels.giveaway,
  );

  /// Optional auth: the bearer token (when present) adds `me`.
  @override
  Future<GiveawayDetails> details(String id) async =>
      GiveawayModels.details(await _api.get('/giveaways/$id'));

  @override
  Future<StepProgress> submitStep({
    required String giveawayId,
    required String stepId,
    String? proofText,
  }) async {
    final json = await _api.post(
      '/giveaways/$giveawayId/steps/$stepId/progress',
      body: {'proofText': ?proofText},
    );
    return GiveawayModels.progress(stepId, Map<String, dynamic>.from(json['progress'] as Map));
  }

  @override
  Future<GiveawayEntry> enter(String giveawayId) async => GiveawayModels.entry(
    Map<String, dynamic>.from((await _api.post('/giveaways/$giveawayId/entries'))['entry'] as Map),
  );

  @override
  Future<List<GiveawayWinner>?> results(String giveawayId) async {
    try {
      final json = await _api.get('/giveaways/$giveawayId/results', auth: false);
      return parseList(json['winners'], GiveawayModels.winner);
    } on AppException catch (error) {
      if (error.code == 'NOT_FOUND') return null;
      rethrow;
    }
  }

  @override
  Future<CursorPage<GiveawayEntry>> myEntries({EntryResult? result, String? cursor}) async =>
      CursorPage.fromJson(
        await _api.get(
          '/me/entries',
          query: {
            'result': switch (result) {
              EntryResult.pending => 'PENDING',
              EntryResult.won => 'WON',
              EntryResult.notSelected => 'NOT_SELECTED',
              null => null,
            },
            'cursor': cursor,
            'limit': AppConstants.pageSize,
          },
        ),
        GiveawayModels.entry,
      );

  @override
  Future<List<Winning>> pendingCelebrations() async => parseList(
    (await _api.get('/me/winnings/pending-celebration'))['items'],
    GiveawayModels.winning,
  );

  @override
  Future<void> acknowledgeCelebration(String winningId) =>
      _api.post('/me/winnings/$winningId/acknowledge-celebration');

  @override
  Future<Winning> claim(String winningId, String contact) async => GiveawayModels.winning(
    Map<String, dynamic>.from(
      (await _api.post('/me/winnings/$winningId/claim', body: {'contact': contact}))['winning']
          as Map,
    ),
  );
}
