import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/storage_repository.dart';
import 'create_giveaway_state.dart';

class CreateGiveawayCubit extends Cubit<CreateGiveawayState> {
  CreateGiveawayCubit(this._giveawayRepository, this._storageRepository, this._client)
    : super(const CreateGiveawayState());

  final GiveawayRepository _giveawayRepository;
  final StorageRepository _storageRepository;
  final SupabaseClient _client;

  Future<void> publish({
    required String title,
    required String organizerName,
    required String prizeDescription,
    required String descriptionRules,
    required DateTime startDate,
    required DateTime endDate,
    required String endTime,
    Uint8List? imageBytes,
    String? imageExtension,
    String? categoryId,
    DateTime? startsAt,
    DateTime? endsAt,
    String? editingId,
    String? existingImageUrl,
  }) async {
    if (state.status == CreateGiveawayStatus.submitting) return;
    if (startsAt != null && endsAt != null && !endsAt.isAfter(startsAt)) {
      emit(
        state.copyWith(
          status: CreateGiveawayStatus.error,
          failure: const InvalidGiveawayScheduleFailure(),
        ),
      );
      return;
    }
    emit(state.copyWith(status: CreateGiveawayStatus.submitting));

    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) {
      emit(
        state.copyWith(
          status: CreateGiveawayStatus.error,
          failure: const UnauthorizedFailure('Your admin session expired. Please sign in again.'),
        ),
      );
      return;
    }

    String? imageUrl = existingImageUrl;
    if (imageBytes != null && imageExtension != null) {
      final uploadResult = await _storageRepository.uploadGiveawayImage(
        bytes: imageBytes,
        fileExtension: imageExtension,
      );
      final uploadFailed = uploadResult.fold((failure) => failure, (_) => null);
      if (uploadFailed != null) {
        emit(state.copyWith(status: CreateGiveawayStatus.error, failure: uploadFailed));
        return;
      }
      imageUrl = uploadResult.fold((_) => null, (url) => url);
    }

    final result = await _giveawayRepository.createGiveaway(
      title: title,
      organizerName: organizerName,
      prizeDescription: prizeDescription,
      descriptionRules: descriptionRules,
      imageUrl: imageUrl,
      startDate: startDate,
      endDate: endDate,
      endTime: endTime,
      createdByAdminId: adminId,
      categoryId: categoryId,
      startsAt: startsAt,
      endsAt: endsAt,
      editingId: editingId,
    );

    result.fold(
      (failure) => emit(state.copyWith(status: CreateGiveawayStatus.error, failure: failure)),
      (_) => emit(state.copyWith(status: CreateGiveawayStatus.success)),
    );
  }
}
