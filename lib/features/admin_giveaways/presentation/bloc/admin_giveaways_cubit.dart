import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/repositories/giveaway_repository.dart';
import 'admin_giveaways_state.dart';

class AdminGiveawaysCubit extends Cubit<AdminGiveawaysState> {
  AdminGiveawaysCubit(this._repository) : super(const AdminGiveawaysState());

  final GiveawayRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AdminGiveawaysStatus.loading));
    final result = await _repository.getGiveaways(forceRefresh: true);
    result.fold(
      (failure) => emit(state.copyWith(status: AdminGiveawaysStatus.error, failure: failure)),
      (giveaways) =>
          emit(state.copyWith(status: AdminGiveawaysStatus.loaded, giveaways: giveaways)),
    );
  }
}
