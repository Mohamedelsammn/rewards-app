import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/secure_storage_service.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/participation_repository.dart';
import '../../../../shared/repositories/user_repository.dart';
import 'participation_state.dart';

/// Drives the full flow end to end: check local identity -> Registration
/// (if needed) -> create-participation -> hand-off to Scratch Card
/// (implementation-plan.md §3, tasks.md T09-05).
///
/// V1 has no AdMob/advertisement system (explicit, permanent product
/// decision) -- there is deliberately no ad-gating step anywhere in this
/// class. Participation is a single direct server call once identity is
/// confirmed.
class ParticipationCubit extends Cubit<ParticipationState> {
  ParticipationCubit({
    required this.giveawayId,
    required SecureStorageService secureStorage,
    required UserRepository userRepository,
    required ParticipationRepository participationRepository,
    required GiveawayRepository giveawayRepository,
  }) : _secureStorage = secureStorage,
       _userRepository = userRepository,
       _participationRepository = participationRepository,
       _giveawayRepository = giveawayRepository,
       super(const ParticipationState());

  final String giveawayId;
  final SecureStorageService _secureStorage;
  final UserRepository _userRepository;
  final ParticipationRepository _participationRepository;
  final GiveawayRepository _giveawayRepository;

  Future<void> start() async {
    emit(state.copyWith(step: ParticipationStep.checkingIdentity));
    final cachedUserId = await _secureStorage.cachedUserId;
    if (cachedUserId != null) {
      await _createParticipation();
    } else {
      emit(state.copyWith(step: ParticipationStep.needsRegistration));
    }
  }

  Future<void> submitRegistration({
    required String fullName,
    required String phone,
    required String countryCode,
  }) async {
    emit(state.copyWith(step: ParticipationStep.submittingRegistration));

    final result = await _userRepository.registerOrLink(
      fullName: fullName,
      phone: phone,
      countryCode: countryCode,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(step: ParticipationStep.failure, failure: failure)),
      (profile) async {
        await _secureStorage.saveIdentity(userId: profile.id, fullName: profile.fullName);
        await _createParticipation();
      },
    );
  }

  Future<void> _createParticipation() async {
    emit(state.copyWith(step: ParticipationStep.creatingParticipation));

    final createResult = await _participationRepository.createParticipation(giveawayId: giveawayId);

    await createResult.fold(
      (failure) async => emit(state.copyWith(step: ParticipationStep.failure, failure: failure)),
      (participation) async {
        await _giveawayRepository.invalidateAfterParticipation(giveawayId);
        emit(
          state.copyWith(
            step: ParticipationStep.success,
            participationId: participation.id,
            participationNumber: participation.participationNumber,
          ),
        );
      },
    );
  }

  Future<void> retry() async {
    if (state.step == ParticipationStep.failure) {
      final cachedUserId = await _secureStorage.cachedUserId;
      if (cachedUserId != null) {
        await _createParticipation();
      } else {
        emit(state.copyWith(step: ParticipationStep.needsRegistration));
      }
    }
  }
}
