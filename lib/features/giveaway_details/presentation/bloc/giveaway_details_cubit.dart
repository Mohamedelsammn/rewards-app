import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/participation_repository.dart';
import 'giveaway_details_state.dart';

class GiveawayDetailsCubit extends Cubit<GiveawayDetailsState> {
  GiveawayDetailsCubit(this._giveawayRepository, this._participationRepository)
    : super(const GiveawayDetailsState());

  final GiveawayRepository _giveawayRepository;
  final ParticipationRepository _participationRepository;

  Future<void> load(String giveawayId, {bool forceRefresh = false}) async {
    emit(state.copyWith(status: GiveawayDetailsStatus.loading));

    final giveawayResult = await _giveawayRepository.getGiveawayById(
      giveawayId,
      forceRefresh: forceRefresh,
    );

    await giveawayResult.fold(
      (failure) async =>
          emit(state.copyWith(status: GiveawayDetailsStatus.error, failure: failure)),
      (giveaway) async {
        final requirementsResult = await _giveawayRepository.getRequirements(giveawayId);
        final participationResult = await _participationRepository.getMyParticipationForGiveaway(
          giveawayId,
        );

        emit(
          state.copyWith(
            status: GiveawayDetailsStatus.loaded,
            giveaway: giveaway,
            requirements: requirementsResult.fold((_) => const [], (r) => r),
            alreadyJoined: participationResult.fold((_) => false, (p) => p != null),
            myParticipationNumber: participationResult.fold(
              (_) => null,
              (p) => p?.participationNumber,
            ),
          ),
        );
      },
    );
  }

  /// Called after a successful participation so the CTA flips to "You're
  /// in!" without a full reload.
  void markJoined(int participationNumber) {
    emit(state.copyWith(alreadyJoined: true, myParticipationNumber: participationNumber));
  }
}
