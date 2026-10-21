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
  // Maps a file extension to the MIME type registered in the giveaway-images
  // bucket's allowed_mime_types allow-list. "jpg" must map to "image/jpeg"
  // (not the literal "image/jpg", which the bucket rejects with a 400).
  static const _mimeTypesByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
  };

  Future<Result<String>> uploadGiveawayImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    final mimeType = _mimeTypesByExtension[ext];
    if (mimeType == null) {
      return const Result.failure(ValidationFailure('Only JPG, PNG, or GIF images are allowed.'));
    }
    if (bytes.length > maxBytes) {
      return const Result.failure(ValidationFailure('Image must be 5MB or smaller.'));
    }

    final path = '${const Uuid().v4()}.$ext';
    try {
      await _client.storage
          .from('giveaway-images')
          .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeType));
      return Result.success(_client.storage.from('giveaway-images').getPublicUrl(path));
    } on StorageException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  /// Best-effort cleanup of a deleted giveaway's uploaded image. Called
  /// AFTER the giveaway's database records are already gone (the source of
  /// truth for "was this giveaway deleted") -- Storage isn't part of the
  /// same Postgres transaction, so a failure here is a non-fatal, silently
  /// swallowed orphaned-file miss, never a reason to report the delete
  /// itself as failed.
  Future<void> deleteGiveawayImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    final segments = Uri.parse(imageUrl).pathSegments;
    final bucketIndex = segments.indexOf('giveaway-images');
    if (bucketIndex == -1 || bucketIndex == segments.length - 1) return;
    final path = segments.sublist(bucketIndex + 1).join('/');

    try {
      await _client.storage.from('giveaway-images').remove([path]);
    } catch (_) {
      // Non-fatal -- see doc comment above.
    }
  }
}
