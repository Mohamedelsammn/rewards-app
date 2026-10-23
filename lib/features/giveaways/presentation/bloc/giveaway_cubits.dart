import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/cursor_page.dart';
import '../../../../core/utils/paged_cubit.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../../domain/repositories/giveaways_repository.dart';
import '../../../../core/utils/safe_emit.dart';

/// `GET /giveaways?status=AVAILABLE|UPCOMING|ENDED`.
class GiveawaysListCubit extends PagedCubit<Giveaway, GiveawayListFilter> {
  GiveawaysListCubit(this._repository) : super(GiveawayListFilter.available);

  final GiveawaysRepository _repository;

  @override
  Future<CursorPage<Giveaway>> fetch(GiveawayListFilter filter, String? cursor) =>
      _repository.giveaways(filter: filter, cursor: cursor);
}

/// `GET /me/entries?result=`; `null` filter shows every entry.
class MyEntriesCubit extends PagedCubit<GiveawayEntry, EntryResult?> {
  MyEntriesCubit(this._repository) : super(null);

  final GiveawaysRepository _repository;

  @override
  Future<CursorPage<GiveawayEntry>> fetch(EntryResult? filter, String? cursor) =>
      _repository.myEntries(result: filter, cursor: cursor);
}

enum GiveawayDetailsStatus { loading, ready, failed }

class GiveawayDetailsState extends Equatable {
  const GiveawayDetailsState({
    this.status = GiveawayDetailsStatus.loading,
    this.details,
    this.winners,
    this.busyStepId,
    this.entering = false,
    this.error,
  });

  final GiveawayDetailsStatus status;
  final GiveawayDetails? details;
  final List<GiveawayWinner>? winners;
  final String? busyStepId;
  final bool entering;

  /// Load failure (status `failed`) or the last action failure.
  final Object? error;

  GiveawayDetailsState copyWith({
    GiveawayDetailsStatus? status,
    GiveawayDetails? details,
    List<GiveawayWinner>? winners,
    String? busyStepId,
    bool clearBusyStep = false,
    bool? entering,
    Object? error,
  }) => GiveawayDetailsState(
    status: status ?? this.status,
    details: details ?? this.details,
    winners: winners ?? this.winners,
    busyStepId: clearBusyStep ? null : busyStepId ?? this.busyStepId,
    entering: entering ?? this.entering,
    error: error,
  );

  @override
  List<Object?> get props => [status, details, winners, busyStepId, entering, error];
}

/// Giveaway details, step progress and entry. Participation numbers always
/// come from the server; re-joining returns the existing entry.
class GiveawayDetailsCubit extends Cubit<GiveawayDetailsState> with SafeEmit<GiveawayDetailsState> {
  GiveawayDetailsCubit(this._repository, this.giveawayId) : super(const GiveawayDetailsState());

  final GiveawaysRepository _repository;
  final String giveawayId;

  Future<void> load() async {
    if (state.details == null) emit(const GiveawayDetailsState());
    try {
      final details = await _repository.details(giveawayId);
      List<GiveawayWinner>? winners;
      if (details.giveaway.hasResults) {
        try {
          winners = await _repository.results(giveawayId);
        } catch (_) {
          // Results are optional on this screen.
        }
      }
      if (!isClosed) {
        emit(
          GiveawayDetailsState(
            status: GiveawayDetailsStatus.ready,
            details: details,
            winners: winners,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && state.details == null) {
        emit(GiveawayDetailsState(status: GiveawayDetailsStatus.failed, error: error));
      }
    }
  }

  /// Reports a step. Returns false (with [GiveawayDetailsState.error]) on failure.
  Future<bool> submitStep(GiveawayStep step, {String? proofText}) async {
    final details = state.details;
    if (details == null || state.busyStepId != null) return false;
    emit(state.copyWith(busyStepId: step.id));
    try {
      final progress = await _repository.submitStep(
        giveawayId: giveawayId,
        stepId: step.id,
        proofText: proofText,
      );
      emit(
        state.copyWith(
          clearBusyStep: true,
          details: GiveawayDetails(
            giveaway: details.giveaway,
            entry: details.entry,
            progress: {...details.progress, step.id: progress},
          ),
        ),
      );
      return true;
    } catch (error) {
      emit(state.copyWith(clearBusyStep: true, error: error));
      return false;
    }
  }

  /// `POST /giveaways/:id/entries`. Returns the entry or null on failure.
  Future<GiveawayEntry?> enter() async {
    final details = state.details;
    if (details == null || state.entering) return null;
    emit(state.copyWith(entering: true));
    try {
      final entry = await _repository.enter(giveawayId);
      emit(
        state.copyWith(
          entering: false,
          details: GiveawayDetails(
            giveaway: details.giveaway,
            entry: entry,
            progress: details.progress,
          ),
        ),
      );
      return entry;
    } catch (error) {
      emit(state.copyWith(entering: false, error: error));
      // STEPS_INCOMPLETE etc. may mean the local progress is stale. The
      // reload clears the error, so keep it for the page to report.
      await load();
      if (!isClosed) emit(state.copyWith(error: error));
      return null;
    }
  }
}
