import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/secure_storage_service.dart';
import '../../../../services/user_identity_service.dart';
import '../../../../shared/repositories/auth_repository.dart';
import 'splash_state.dart';

/// Bootstraps the app: restores/verifies the anonymous identity (best-effort
/// -- public browsing works via RLS even without one, so a failure here
/// never blocks navigation), then restores whichever role (User or Admin)
/// was last active on this device so a restart/reload never bounces a
/// returning user back through Role Selection (implementation-plan.md §6,
/// tasks.md T06-02, and the state-sync/session-restoration fix pass -- see
/// docs/fixes/state-sync-and-session-restoration.md).
///
/// [UserIdentityService.restoreAndVerify] does more than the old bare
/// `ensureAnonymousSession()` call: if this device has a cached identity
/// but the current session is no longer linked to it (a genuinely lost
/// session -- see that class's doc comment), it clears the stale cache so
/// the check below correctly falls through to Role Selection instead of
/// auto-skipping into a User Home that would silently show no data.
///
/// `ensureAnonymousSession()` (run as part of the line above) only ever
/// *mints* a session when none exists at all -- if Supabase already
/// restored a persisted Admin (email/password) session, it's returned
/// untouched, so running the identity-restore step unconditionally here
/// never clobbers a persisted Admin session.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(
    this._userIdentityService,
    this._secureStorage,
    this._authRepository, {
    this._minVisibleDuration = const Duration(seconds: 3),
  }) : super(const SplashState());

  final UserIdentityService _userIdentityService;
  final SecureStorageService _secureStorage;
  final AuthRepository _authRepository;

  /// The splash's Lottie animation needs real time on screen to actually
  /// play. [_resolveDestination] below is usually much faster than this
  /// (local storage reads), so it's allowed to run to completion in the
  /// background and navigation is only held back until at least this long
  /// has elapsed since [bootstrap] started -- never a blind delay added on
  /// top of however long it takes.
  final Duration _minVisibleDuration;

  Future<void> bootstrap() async {
    final stopwatch = Stopwatch()..start();
    final destination = await _resolveDestination();

    final remaining = _minVisibleDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    emit(SplashState(destination: destination));
  }

  Future<SplashDestination> _resolveDestination() async {
    await _userIdentityService.restoreAndVerify();

    final lastRole = await _secureStorage.cachedLastRole;

    if (lastRole == 'admin') {
      // A real (non-anonymous) session still active means Supabase already
      // restored this admin's persisted sign-in -- safe to skip straight
      // back into AdminShell. Otherwise the session genuinely expired/was
      // lost, so the stale role is cleared (never silently re-shown on the
      // next launch) and the admin falls through to Role Selection to sign
      // in again, per "only show Role Selection when... session is invalid
      // and role cannot be restored."
      final session = _authRepository.currentSession;
      if (session != null && !session.user.isAnonymous) {
        return SplashDestination.adminShell;
      }
      await _secureStorage.clearLastRole();
      return SplashDestination.roleSelection;
    }

    final cachedUserId = await _secureStorage.cachedUserId;
    if (lastRole == 'user' && cachedUserId != null) {
      return SplashDestination.userHome;
    }
    return SplashDestination.roleSelection;
  }
}
