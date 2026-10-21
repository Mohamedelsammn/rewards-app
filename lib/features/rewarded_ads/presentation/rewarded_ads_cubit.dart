import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/admob_service.dart';
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
  });

  final EarnPhase phase;
  final AdRewardStatus? status;
  final int creditedPoints;
  final RewardedAdOutcome? outcome;
  final String? rejectReason;
  final Object? error;

  bool get busy => phase == EarnPhase.watching || phase == EarnPhase.verifying;

  EarnState copyWith({
    EarnPhase? phase,
    AdRewardStatus? status,
    int? creditedPoints,
    RewardedAdOutcome? outcome,
    String? rejectReason,
    Object? error,
  }) => EarnState(
    phase: phase ?? this.phase,
    status: status ?? this.status,
    creditedPoints: creditedPoints ?? this.creditedPoints,
    outcome: outcome,
    rejectReason: rejectReason,
    error: error,
  );

  @override
  List<Object?> get props => [phase, status, creditedPoints, outcome, rejectReason, error];
}

/// AdMob SSV flow (docs/FLUTTER_INTEGRATION-5.md §3.10): status → session →
/// SSV options + show → poll. Points are credited only by Google's signed
/// callback to the server; `onUserEarnedReward` is UX only.
class RewardedAdsCubit extends Cubit<EarnState> {
  RewardedAdsCubit({
    required this._repository,
    required this._presenter,
    required this._deviceId,
    required this._featureEnabled,
    required this.onCredited,
    this.pollInterval = const Duration(seconds: 2),
    this.pollTimeout = const Duration(seconds: 60),
  }) : super(const EarnState());

  final AdRewardsRepository _repository;
  final RewardedAdPresenter _presenter;
  final Future<String> Function() _deviceId;
  final bool _featureEnabled;
  final void Function() onCredited;
  final Duration pollInterval;
  final Duration pollTimeout;

  Future<void> loadStatus() async {
    if (!_featureEnabled) {
      emit(const EarnState(phase: EarnPhase.disabled));
      return;
    }
    try {
      final status = await _repository.status(await _deviceId());
      emit(EarnState(phase: status.enabled ? EarnPhase.ready : EarnPhase.disabled, status: status));
    } catch (error) {
      emit(state.copyWith(phase: EarnPhase.failed, error: error));
    }
  }

  Future<void> watch() async {
    final status = state.status;
    if (state.busy || status == null || !status.enabled) return;
    emit(state.copyWith(phase: EarnPhase.watching));
    try {
      final created = await _repository.createSession(
        deviceId: await _deviceId(),
        adUnitId: _presenter.adUnitId,
      );
      final outcome = await _presenter.show(
        ssvUserId: created.ssv.userId,
        ssvCustomData: created.ssv.customData,
      );
      if (outcome != RewardedAdOutcome.completed) {
        // The session expires on the server; nothing is credited.
        emit(state.copyWith(phase: EarnPhase.notCredited, outcome: outcome));
        await _refreshStatus();
        return;
      }
      emit(state.copyWith(phase: EarnPhase.verifying));
      await _poll(created.session.id);
    } catch (error) {
      emit(state.copyWith(phase: EarnPhase.failed, error: error));
      await _refreshStatus();
    }
  }

  Future<void> _poll(String sessionId) async {
    final deadline = DateTime.now().add(pollTimeout);
    while (!isClosed && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollInterval);
      if (isClosed) return;
      final AdSession session;
      try {
        session = await _repository.session(sessionId);
      } catch (_) {
        continue; // Transient failure while polling: keep trying until the deadline.
      }
      switch (session.status) {
        case AdSessionStatus.credited:
          onCredited();
          emit(state.copyWith(phase: EarnPhase.credited, creditedPoints: session.points));
          await _refreshStatus();
          return;
        case AdSessionStatus.rejected:
        case AdSessionStatus.expired:
          emit(
            state.copyWith(
              phase: EarnPhase.notCredited,
              rejectReason: session.rejectReason ?? session.status.name.toUpperCase(),
            ),
          );
          await _refreshStatus();
          return;
        case AdSessionStatus.pending:
          break;
      }
    }
    if (!isClosed) emit(state.copyWith(phase: EarnPhase.stillPending));
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _repository.status(await _deviceId());
      if (!isClosed) {
        emit(
          state.copyWith(
            status: status,
            outcome: state.outcome,
            rejectReason: state.rejectReason,
            error: state.error,
          ),
        );
      }
    } catch (_) {
      // The last known status stays visible.
    }
  }
}
