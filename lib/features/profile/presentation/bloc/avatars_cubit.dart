import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_assets.dart';
import '../../domain/profile_repository.dart';

/// Selectable characters. Starts with the bundled 1–9 so onboarding works
/// offline, then follows the server's active list when it loads.
class AvatarsCubit extends Cubit<List<Avatar>> {
  AvatarsCubit(this._repository)
    : super([for (final id in AppAssets.bundledAvatarIds) Avatar(id: id)]);

  final ProfileRepository _repository;

  Future<void> load() async {
    try {
      final avatars = await _repository.avatars();
      final usable = [
        for (final avatar in avatars)
          if (avatar.imageUrl != null || AppAssets.bundledAvatarIds.contains(avatar.id)) avatar,
      ];
      if (usable.isNotEmpty) emit(usable);
    } catch (_) {
      // Keep the bundled characters.
    }
  }
}
