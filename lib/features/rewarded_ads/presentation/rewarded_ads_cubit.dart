import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/services/ad_diagnostics.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/utils/safe_emit.dart';
import '../domain/ad_reward_entities.dart';

enum EarnPhase {
  loading,
  disabled,
  ready,
  watching,
  verifying,
  credited,
  notCredited,
  stillPending,
  failed,
}

class EarnState extends Equatable {
  const EarnState({
    this.phase = EarnPhase.loading,
    this.status,
    this.creditedPoints = 0,
    this.outcome,
    this.rejectReason,
    this.error,
    this.pendingSessionId,
  });

  final EarnPhase phase;
  final AdRewardStatus? status;
  final int creditedPoints;
  final RewardedAdOutcome? outcome;
  final String? rejectReason;
  final Object? error;

  /// A watched ad whose claim is not confirmed yet (uncertain network,
  /// COOLDOWN): [RewardedAdsCubit.reconcile] claims the same session again.
  final String? pendingSessionId;

  bool get busy => phase == EarnPhase.watching || phase == EarnPhase.verifying;

  EarnState copyWith({
    EarnPhase? phase,
    AdRewardStatus? status,
    int? creditedPoints,
    RewardedAdOutcome? outcome,
    String? rejectReason,
    Object? error,
    String? pendingSessionId,
  }) => EarnState(
    phase: phase ?? this.phase,
    status: status ?? this.status,
    creditedPoints: creditedPoints ?? this.creditedPoints,
    outcome: outcome,
    rejectReason: rejectReason,
    error: error,
    pendingSessionId: pendingSessionId,
  );

  @override
  List<Object?> get props => [
    phase,
    status,
    creditedPoints,
    outcome,
    rejectReason,
    error,
    pendingSessionId,
  ];
}

/// Sessions whose ad was watched (reward earned) but whose claim is not
/// confirmed, kept for this app session so reopening the page claims them
/// again with the same id. Cleared on sign-out.
class PendingAdSessions {
  final _ids = <String>[];

  List<String> get ids => List.unmodifiable(_ids);

  void add(String id) {
    if (!_ids.contains(id)) _ids.add(id);
  }

  void remove(String id) => _ids.remove(id);

  /// Sign-out: these sessions belong to the previous account.
  void clear() => _ids.clear();
}

/// Earn Points with rewarded ads, client-reported completion
/// (FLUTTER_ADS-1.md): status → one-time session → ad → on
/// `onUserEarnedReward` only, `POST /ad-rewards/claims { sessionId }`. The
/// server credits and returns `CREDITED`; the wallet is then reloaded. The
/// app never adds points itself. Claims are idempotent server-side, so an
/// uncertain claim is retried with the same session id, never a new one.
class RewardedAdsCubit extends Cubit<EarnState> with SafeEmit<EarnState> {
  RewardedAdsCubit({
    required this._repository,
    required this._presenter,
    required this._deviceId,
    required this._featureEnabled,
    required this.onCredited,
    this._pending,
    this.claimRetryDelays = const [Duration(seconds: 1), Duration(seconds: 3)],
  }) : super(const EarnState());

  final AdRewardsRepository _repository;
  final RewardedAdPresenter _presenter;
  final Future<String> Function() _deviceId;
  final bool _featureEnabled;
  final PendingAdSessions? _pending;
  final void Function() onCredited;

  /// Waits between automatic retries of an uncertain claim (bounded).
  final List<Duration> claimRetryDelays;

  /// Upper bound of one claim request.
  static const _requestLimit = Duration(seconds: 15);

  /// Sessions being claimed now: a duplicate trigger never starts a second
  /// claim of the same session.
  final _claiming = <String>{};

  Future<void> loadStatus() async {
    if (!_featureEnabled) {
      emit(const EarnState(phase: EarnPhase.disabled));
      return;
    }
    try {
      final status = await _repository.status(await _deviceId());
      adLog(
        'status enabled=${status.enabled} verification=${status.verification} '
        'remaining=${status.remainingToday} nextAvailableAt=${status.nextAvailableAt}',
      );
      if (!status.isClientReported) {
        // Another contract (e.g. the old SSV one): never claim against it.
        adLog('unsupported verification mode ${status.verification}');
      }
      emit(
        EarnState(
          phase: status.enabled && status.isClientReported ? EarnPhase.ready : EarnPhase.disabled,
          status: status,
        ),
      );
    } catch (error) {
      adLog('status failed ${adDescribeError(error)}');
      emit(state.copyWith(phase: EarnPhase.failed, error: error));
      return;
    }
    // A reward from an earlier visit whose claim was not confirmed.
    final pending = _pending?.ids ?? const <String>[];
    if (pending.isNotEmpty && state.phase == EarnPhase.ready) {
      await _claim(pending.last, quiet: true);
    }
  }

  Future<void> watch() async {
    final status = state.status;
    if (state.busy || status == null || !status.enabled || !status.isClientReported) return;
    emit(state.copyWith(phase: EarnPhase.watching));
    final started = DateTime.now();
    final AdSession session;
    try {
      // Before the ad: no session, no ad.
      session = await _repository.createSession(
        deviceId: await _deviceId(),
        adUnitId: _presenter.adUnitId,
      );
      adLog('session created id=${session.id} expiresAt=${session.expiresAt}');
    } catch (error) {
      adLog('session failed ${adDescribeError(error)}');
      emit(state.copyWith(phase: EarnPhase.failed, error: error));
      await _refreshStatus();
      return;
    }
    final outcome = await _presenter.show();
    adLog('ad outcome=${outcome.name} after ${_since(started)}');
    if (isClosed) return;
    if (outcome != RewardedAdOutcome.completed) {
      // Skipped, failed or unavailable: no claim. The session expires.
      emit(state.copyWith(phase: EarnPhase.notCredited, outcome: outcome));
      await _refreshStatus();
      return;
    }
    // Reward earned: the claim is owed until the server answers.
    _pending?.add(session.id);
    emit(state.copyWith(phase: EarnPhase.verifying, pendingSessionId: session.id));
    await _claim(session.id, quiet: false);
  }

  /// "Check again": claims the same session once more.
  Future<void> reconcile() async {
    final id = state.pendingSessionId;
    if (id == null || state.busy) return;
    emit(state.copyWith(phase: EarnPhase.verifying, pendingSessionId: id));
    await _claim(id, quiet: false);
  }

  Future<void> _claim(String sessionId, {required bool quiet}) async {
    if (!_claiming.add(sessionId)) return;
    final started = DateTime.now();
    try {
      for (var attempt = 0; ; attempt++) {
        try {
          final claim = await _repository.claim(sessionId).timeout(_requestLimit);
          adLog(
            'claim id=$sessionId status=${claim.session.status.name} '
            'points=${claim.session.points} after ${_since(started)}',
          );
          if (isClosed) return;
          _settle(sessionId, claim, quiet: quiet);
          await _refreshStatus();
          return;
        } catch (error) {
          final uncertain = _isUncertain(error);
          adLog('claim id=$sessionId #$attempt failed ${adDescribeError(error)}');
          if (uncertain && attempt < claimRetryDelays.length) {
            await Future<void>.delayed(claimRetryDelays[attempt]);
            if (isClosed) return;
            continue;
          }
          _claimFailed(sessionId, error, uncertain: uncertain, quiet: quiet);
          await _refreshStatus();
          return;
        }
      }
    } finally {
      _claiming.remove(sessionId);
    }
  }

  /// The server answered the claim.
  void _settle(String sessionId, AdClaim claim, {required bool quiet}) {
    final session = claim.session;
    if (session.id != sessionId) {
      // Not this attempt's answer: credit nothing, allow a new check.
      if (!quiet) {
        emit(
          state.copyWith(
            phase: EarnPhase.stillPending,
            pendingSessionId: sessionId,
            error: const AppException(code: AppException.badResponse),
          ),
        );
      }
      return;
    }
    switch (session.status) {
      case AdSessionStatus.credited:
        _pending?.remove(sessionId);
        onCredited(); // GET /wallet; the balance always comes from the server.
        emit(state.copyWith(phase: EarnPhase.credited, creditedPoints: session.points));
      case AdSessionStatus.pending:
        if (!quiet) {
          emit(state.copyWith(phase: EarnPhase.stillPending, pendingSessionId: sessionId));
        }
      case AdSessionStatus.rejected:
      case AdSessionStatus.expired:
        _pending?.remove(sessionId);
        emit(
          state.copyWith(
            phase: EarnPhase.notCredited,
            rejectReason: session.rejectReason ?? session.status.name.toUpperCase(),
          ),
        );
    }
  }

  void _claimFailed(
    String sessionId,
    Object error, {
    required bool uncertain,
    required bool quiet,
  }) {
    final code = error is AppException ? error.code : null;
    // Still claimable with the same id: unknown outcome, or COOLDOWN (the
    // session stays PENDING; retry after details.retryAfter).
    if (uncertain || code == 'COOLDOWN') {
      if (!quiet) {
        emit(
          state.copyWith(
            phase: EarnPhase.stillPending,
            pendingSessionId: sessionId,
            error: code == 'COOLDOWN' ? error : null,
          ),
        );
      }
      return;
    }
    // Final refusal: this session will never be credited.
    _pending?.remove(sessionId);
    if (quiet) return;
    if (code == 'SESSION_EXPIRED') {
      emit(state.copyWith(phase: EarnPhase.notCredited, rejectReason: 'EXPIRED'));
      return;
    }
    emit(state.copyWith(phase: EarnPhase.failed, error: error));
  }

  /// Network errors, timeouts and 5xx: the claim may or may not have been
  /// applied; the same session id can be retried safely.
  static bool _isUncertain(Object error) {
    if (error is TimeoutException) return true;
    if (error is! AppException) return false;
    return error.isConnectivity || (error.statusCode ?? 0) >= 500;
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _repository.status(await _deviceId());
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: state.phase,
            status: status,
            creditedPoints: state.creditedPoints,
            outcome: state.outcome,
            rejectReason: state.rejectReason,
            error: state.error,
            pendingSessionId: state.pendingSessionId,
          ),
        );
      }
    } catch (_) {
      // The last known status stays visible.
    }
  }

  static String _since(DateTime start) => '${DateTime.now().difference(start).inMilliseconds} ms';
}
