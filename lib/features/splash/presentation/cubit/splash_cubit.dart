import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/secure_storage_service.dart';
import '../../../../shared/repositories/auth_repository.dart';
import 'splash_state.dart';

/// Bootstraps the app: attempts the anonymous session (best-effort -- public
/// browsing works via RLS even without one, so a failure here never blocks
/// navigation), then decides whether to skip straight back into User Home
/// for a returning user or send a first-time/role-switching user through
/// Role Selection (implementation-plan.md §6, tasks.md T06-02).
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._authRepository, this._secureStorage) : super(const SplashState());

  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;

  Future<void> bootstrap() async {
    await _authRepository.ensureAnonymousSession();

    final lastRole = await _secureStorage.cachedLastRole;
    final cachedUserId = await _secureStorage.cachedUserId;

    if (lastRole == 'user' && cachedUserId != null) {
      emit(const SplashState(destination: SplashDestination.userHome));
    } else {
      emit(const SplashState(destination: SplashDestination.roleSelection));
    }
  }
}
