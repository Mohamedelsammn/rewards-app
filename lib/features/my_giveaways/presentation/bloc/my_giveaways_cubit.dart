import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/repositories/participation_repository.dart';
import 'my_giveaways_state.dart';

class MyGiveawaysCubit extends Cubit<MyGiveawaysState> {
  MyGiveawaysCubit(this._repository) : super(const MyGiveawaysState());

  final ParticipationRepository _repository;

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(status: MyGiveawaysStatus.loading));
    final result = await _repository.getMyParticipations(forceRefresh: forceRefresh);
    result.fold(
      (failure) => emit(state.copyWith(status: MyGiveawaysStatus.error, failure: failure)),
      (participations) => emit(
        state.copyWith(
          status: participations.isEmpty ? MyGiveawaysStatus.empty : MyGiveawaysStatus.loaded,
          participations: participations,
        ),
      ),
    );
  }
}
