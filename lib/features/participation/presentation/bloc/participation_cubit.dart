import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/participation_repository.dart';
import '../../../../shared/repositories/user_repository.dart';
import 'participation_state.dart';

/// Server-authoritative participation followed by an optional ad transition.
class ParticipationCubit extends Cubit<ParticipationState> {
  ParticipationCubit({
    required this.giveawayId,
    required this._secureStorage,
    required this._userRepository,
    required this._participationRepository,
    required this._giveawayRepository,
    this.showRewardedAd = _noRewardedAd,
  }) : super(const ParticipationState());

  final String giveawayId;
  final SecureStorageService _secureStorage;
  final UserRepository _userRepository;
  final ParticipationRepository _participationRepository;
  final GiveawayRepository _giveawayRepository;
  final Future<bool> Function() showRewardedAd;
  bool _creating = false;
  bool _started = false;
  bool _choiceHandled = false;
  bool _rewardEarnedForAttempt = false;

  static Future<bool> _noRewardedAd() async => false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    emit(state.copyWith(step: ParticipationStep.checkingIdentity));
    final cachedUserId = await _secureStorage.cachedUserId;
    if (isClosed) return;
    if (cachedUserId != null) {
      await _checkEligibilityAndParticipation();
    } else {
      emit(state.copyWith(step: ParticipationStep.needsRegistration));
    }
  }

  Future<void> submitRegistration({
    required String fullName,
    required String phone,
    required String countryCode,
  }) async {
    if (state.step == ParticipationStep.submittingRegistration || _creating || _isComplete) {
      return;
    }
    emit(state.copyWith(step: ParticipationStep.submittingRegistration));

    final result = await _userRepository.registerOrLink(
      fullName: fullName,
      phone: phone,
      countryCode: countryCode,
    );
    if (isClosed) return;

    await result.fold(
      (failure) async => emit(state.copyWith(step: ParticipationStep.failure, failure: failure)),
      (profile) async {
        await _secureStorage.saveIdentity(
          userId: profile.id,
          fullName: profile.fullName,
          phone: profile.phoneE164,
          countryCode: profile.countryCode,
        );
        await _checkEligibilityAndParticipation();
      },
    );
  }

  bool get _isComplete =>
      state.step == ParticipationStep.success ||
      state.step == ParticipationStep.participationCreated ||
      state.step == ParticipationStep.alreadyParticipating;

  Future<void> _checkEligibilityAndParticipation() async {
    if (_creating || isClosed || _isComplete) return;
    _creating = true;
    var resumePendingReward = false;
    try {
      emit(state.copyWith(step: ParticipationStep.creatingParticipation));

      final existing = await _participationRepository.getMyParticipationForGiveaway(giveawayId);
      if (isClosed) return;
      final existingFailure = existing.fold((failure) => failure, (_) => null);
      if (existingFailure != null) {
        emit(state.copyWith(step: ParticipationStep.failure, failure: existingFailure));
        return;
      }
      final existingParticipation = existing.fold((_) => null, (p) => p);
      if (existingParticipation != null) {
        final hasPendingReward = _participationRepository.hasPendingRewardFrame(giveawayId);
        var frameUnlocked = existingParticipation.rewardedFrameUnlocked;
        if (hasPendingReward) {
          try {
            await _participationRepository.attachRewardFrameToParticipation(
              giveawayId: giveawayId,
              participationId: existingParticipation.id,
            );
            frameUnlocked = _participationRepository.hasRewardFrameEntitlement(
              giveawayId: giveawayId,
              participationId: existingParticipation.id,
            );
          } catch (_) {
            // Local cosmetic persistence cannot block an existing entry.
          }
        }
        emit(
          state.copyWith(
            step: ParticipationStep.alreadyParticipating,
            participationId: existingParticipation.id,
            participationNumber: existingParticipation.participationNumber,
            rewardedFrameUnlocked: frameUnlocked,
          ),
        );
        return;
      }

      final eligibility = await _giveawayRepository.getGiveawayById(giveawayId, forceRefresh: true);
      final failure = eligibility.fold(
        (f) => f,
        (g) => g.isJoinable ? null : const GiveawayEndedFailure(),
      );
      if (isClosed) return;
      if (failure != null) {
        emit(state.copyWith(step: ParticipationStep.failure, failure: failure));
        return;
      }

      resumePendingReward = _participationRepository.hasPendingRewardFrame(giveawayId);
      if (resumePendingReward) {
        _rewardEarnedForAttempt = true;
      } else {
        emit(state.copyWith(step: ParticipationStep.readyToJoin));
      }
    } finally {
      _creating = false;
    }
    // A prior explicit opt-in may have earned the local cosmetic reward
    // before a transient participation request failure. Resume that attempt
    // without prompting or showing a second ad.
    if (!isClosed && resumePendingReward) await _join();
  }

  Future<void> joinWithoutAd() => _join();

  Future<void> joinWithRewardedAd() async {
    if (_choiceHandled || _creating || isClosed || state.step != ParticipationStep.readyToJoin) {
      return;
    }
    _choiceHandled = true;
    _creating = true;
    var clientReportedReward = false;
    try {
      emit(state.copyWith(step: ParticipationStep.showingRewardedAd));
      try {
        clientReportedReward = await showRewardedAd();
      } catch (_) {
        clientReportedReward = false;
      }
      if (clientReportedReward && !isClosed) {
        // This is only a device-local cosmetic flag. It is not cryptographic
        // proof of an AdMob reward and never affects participation eligibility.
        try {
          await _participationRepository.markRewardFrameEarned(giveawayId);
          _rewardEarnedForAttempt = true;
        } catch (_) {
          _rewardEarnedForAttempt = false;
        }
      }
    } finally {
      _creating = false;
    }
    if (!isClosed) await _join();
  }

  Future<void> _join() async {
    if (_creating || isClosed || _isComplete) return;
    _choiceHandled = true;
    _creating = true;
    try {
      emit(state.copyWith(step: ParticipationStep.creatingParticipation));

      final createResult = await _participationRepository.createParticipation(
        giveawayId: giveawayId,
      );
      if (isClosed) return;

      await createResult.fold(
        (failure) async {
          // A locally cached identity that the server no longer recognizes
          // (e.g. the on-device session was genuinely lost -- see
          // UserIdentityService) surfaces here as UnauthorizedFailure. Left
          // alone, retry() would keep resubmitting the same doomed call
          // forever. Clearing the stale cache makes the *next* attempt fall
          // through start()/retry()'s existing `cachedUserId == null` branch
          // into needsRegistration instead -- a clean recovery, not a
          // security bypass: registering still goes through the full
          // server-side identity flow.
          if (failure is UnauthorizedFailure) {
            await _secureStorage.clearIdentity();
          }
          if (isClosed) return;
          emit(state.copyWith(step: ParticipationStep.failure, failure: failure));
        },
        (participation) async {
          try {
            await _giveawayRepository.invalidateAfterParticipation(giveawayId);
          } catch (_) {
            // A cache write cannot turn a confirmed backend entry into a failed entry.
          }
          if (isClosed) return;
          var frameUnlocked = participation.rewardedFrameUnlocked;
          if (_rewardEarnedForAttempt) {
            try {
              await _participationRepository.attachRewardFrameToParticipation(
                giveawayId: giveawayId,
                participationId: participation.id,
              );
              frameUnlocked = true;
            } catch (_) {
              // The participation is already safely created. A cosmetic
              // cache failure must not invalidate the real server response.
            }
          }
          if (isClosed) return;
          emit(
            state.copyWith(
              step: ParticipationStep.participationCreated,
              participationId: participation.id,
              participationNumber: participation.participationNumber,
              rewardedFrameUnlocked: frameUnlocked,
            ),
          );
          if (isClosed) return;
          emit(state.copyWith(step: ParticipationStep.success));
        },
      );
    } finally {
      _creating = false;
    }
  }

  Future<void> retry() async {
    if (state.step == ParticipationStep.failure) {
      final cachedUserId = await _secureStorage.cachedUserId;
      if (isClosed) return;
      if (cachedUserId != null) {
        await _checkEligibilityAndParticipation();
        // Retry the already chosen participation path without showing a
        // second ad prompt after a transient backend failure.
        if (!isClosed && state.step == ParticipationStep.readyToJoin) {
          await _join();
        }
      } else {
        emit(state.copyWith(step: ParticipationStep.needsRegistration));
      }
    }
  }
}
