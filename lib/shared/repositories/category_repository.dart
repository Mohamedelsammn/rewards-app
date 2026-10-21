import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../models/giveaway_category.dart';

class CategoryRepository {
  CategoryRepository(this._client);
  final SupabaseClient _client;

  Future<bool> canManage() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final row = await _client.from('admin_users').select('role').eq('id', uid).maybeSingle();
      return row?['role'] == 'super_admin';
    } catch (_) {
      return false;
    }
  }

  Future<Result<List<GiveawayCategory>>> getCategories({bool management = false}) async {
    try {
      var query = _client.from('giveaway_categories').select();
      if (!management) query = query.eq('is_active', true);
      final rows = await query
          .order('sort_order', ascending: true)
          .order('name_en', ascending: true)
          .order('id', ascending: true);
      return Result.success(rows.map(GiveawayCategory.fromJson).toList());
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  Future<Result<void>> save(GiveawayCategory category, {bool create = false}) async {
    try {
      if (create) {
        await _client.from('giveaway_categories').insert(category.toJson());
      } else {
        await _client
            .from('giveaway_categories')
            .update(category.toJson())
            .eq('id', category.id)
            .select()
            .single();
      }
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }
}
