import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../models/notification_item.dart';

/// Reads/updates `public.notifications` for the current user. RLS
/// (`notifications_select_own` / `notifications_update_own`, both scoped to
/// `user_id = fn_current_user_id()`) is the actual isolation boundary --
/// this repository adds no client-side filtering of its own, it just
/// exercises the existing policies. This is the read side of the same
/// notification records `NotificationService`/FCM pushes are a delivery
/// channel for; no separate notification architecture.
class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  static const int _pageSize = 50;

  Future<Result<List<NotificationItem>>> getMyNotifications() async {
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(_pageSize);
      return Result.success(
        (rows as List)
            .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<int>> getUnreadCount() async {
    try {
      final rows = await _client.from('notifications').select('id').eq('is_read', false);
      return Result.success((rows as List).length);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<void>> markAllAsRead() async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('is_read', false);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }
}
