import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/domain/entities/app_user.dart';
import '../domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<AppUser> me() async =>
      AuthModels.user(Map<String, dynamic>.from((await _api.get('/me'))['user'] as Map));

  @override
  Future<AppUser> updateProfile({String? name, int? avatarId, String? language}) async {
    final json = await _api.patch(
      '/me',
      body: {'name': ?name, 'avatarId': ?avatarId, 'language': ?language},
    );
    return AuthModels.user(Map<String, dynamic>.from(json['user'] as Map));
  }

  @override
  Future<List<Avatar>> avatars() async {
    final json = await _api.get('/avatars', auth: false);
    return parseList(
      json['items'],
      (item) => Avatar(id: parseInt(item['id']), imageUrl: item['imageUrl'] as String?),
    );
  }

  @override
  Future<int> requestAccountDeletion(String password) async {
    final json = await _api.delete('/me', body: {'password': password});
    return parseInt(json['graceDays'], 14);
  }
}
