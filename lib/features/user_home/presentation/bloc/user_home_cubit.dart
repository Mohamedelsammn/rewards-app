import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/repositories/giveaway_repository.dart';
import 'user_home_state.dart';

/// Implemented as a Cubit rather than a full event-driven Bloc -- there's
/// no branching event graph here (fetch / refresh / search are all direct
/// calls), so a Cubit is the simpler, equally testable choice. Search is
/// debounced ~300ms per tasks.md T08-04, done with a plain Timer rather than
/// a stream transformer package since there's only one debounced input.
class UserHomeCubit extends Cubit<UserHomeState> {
  UserHomeCubit(this._repository) : super(const UserHomeState());

  final GiveawayRepository _repository;
  Timer? _debounce;

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(status: UserHomeStatus.loading));
    final result = await _repository.getGiveaways(forceRefresh: forceRefresh);
    result.fold(
      (failure) => emit(state.copyWith(status: UserHomeStatus.error, failure: failure)),
      (giveaways) => emit(state.copyWith(status: UserHomeStatus.loaded, allGiveaways: giveaways)),
    );
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      emit(state.copyWith(searchQuery: query));
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
