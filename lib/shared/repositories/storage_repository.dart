import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';

/// Uploads to the `giveaway-images` bucket (public read; admin-only write,
/// enforced by storage RLS policy -- implementation-plan.md §13).
class StorageRepository {
  StorageRepository(this._client);

  final SupabaseClient _client;

  static const int maxBytes = 5 * 1024 * 1024;
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'gif'};

  Future<Result<String>> uploadGiveawayImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    if (!_allowedExtensions.contains(ext)) {
      return const Result.failure(ValidationFailure('Only JPG, PNG, or GIF images are allowed.'));
    }
    if (bytes.length > maxBytes) {
      return const Result.failure(ValidationFailure('Image must be 5MB or smaller.'));
    }

    final path = '${const Uuid().v4()}.$ext';
    try {
      await _client.storage
          .from('giveaway-images')
          .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$ext'));
      return Result.success(_client.storage.from('giveaway-images').getPublicUrl(path));
    } on StorageException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }
}
