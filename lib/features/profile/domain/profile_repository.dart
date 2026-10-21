import 'package:equatable/equatable.dart';

import '../../auth/domain/entities/app_user.dart';

class Avatar extends Equatable {
  const Avatar({required this.id, this.imageUrl});

  final int id;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, imageUrl];
}

abstract interface class ProfileRepository {
  Future<AppUser> me();

  /// `PATCH /me`. Only non-null arguments are sent.
  Future<AppUser> updateProfile({String? name, int? avatarId, String? language});

  Future<List<Avatar>> avatars();

  /// `DELETE /me`; returns the grace period in days.
  Future<int> requestAccountDeletion(String password);
}
