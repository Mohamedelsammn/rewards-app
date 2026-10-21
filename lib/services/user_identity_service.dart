import '../shared/repositories/auth_repository.dart';
import '../shared/repositories/user_repository.dart';
import 'notification_service.dart';
import 'secure_storage_service.dart';

/// Orchestrates the two things that must both be true before the User flow
/// can trust a locally cached identity: (1) a valid Supabase session exists,
/// and (2) that session is still linked to the cached `user_devices` row.
///
/// This exists because Sign Out deliberately does NOT destroy the anonymous
/// Supabase session or the locally cached identity (see [AuthRepository] /
/// [SecureStorageService] doc comments) -- by design, re-entering the User
/// flow should see the exact same identity, participations, and history. But
/// if the on-device session was ever actually lost (app data cleared,
/// reinstall, a session-restore failure, etc.), the cached `cachedUserId`
/// becomes orphaned: it points at a `users` row this session can no longer
/// reach. Without this check, the app would silently keep trying to act as
/// that stale identity and fail every write with a confusing generic
/// "not authorized" error instead of cleanly recognizing "this device needs
/// to register again."
///
/// Call [restoreAndVerify] at every entry point into the User flow (Splash's
/// auto-skip decision and Role Selection's "Continue as User"), so a stale
/// identity is caught and cleared *before* the user is shown a broken
/// My Giveaways screen or hits the dead-end error.
///
/// This is explicitly NOT an account-recovery mechanism -- it never invents
/// or reattaches an identity without server confirmation, it only clears a
/// local cache entry that the server has confirmed is no longer reachable.
/// If the device's session really was lost, the user must register again
/// (and, per the no-OTP security model, a phone already tied to a different
/// live identity will correctly be refused -- see `fn_register_or_link_user`).
class UserIdentityService {
  UserIdentityService(
    this._authRepository,
    this._userRepository,
    this._secureStorage,
    this._notificationService,
  );

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final SecureStorageService _secureStorage;
  final NotificationService _notificationService;

  Future<void> restoreAndVerify() async {
    // Only run the linked-device check once a session is genuinely attached
    // to the client. Skipping it on an unattached session is exactly the
    // same "couldn't check, so don't touch the cache" philosophy as the
    // isCurrentDeviceLinked() failure case below -- an RLS-scoped query run
    // with no real auth.uid() would come back empty and look identical to
    // "this device was unlinked," which would wrongly wipe a perfectly
    // valid identity (see _ensureAttachedAnonymousSession's doc comment).
    final attached = await _ensureAttachedAnonymousSession();
    if (!attached) return;

    final cachedUserId = await _secureStorage.cachedUserId;
    if (cachedUserId == null) return;

    final result = await _userRepository.isCurrentDeviceLinked();
    // A network/server failure means "couldn't check," not "definitely
    // unlinked" -- default to leaving the cache alone so a connectivity
    // blip can never wipe a perfectly valid identity.
    final isLinked = result.fold((_) => true, (linked) => linked);
    if (!isLinked) {
      await _secureStorage.clearIdentity();
      return;
    }

    // The device's identity is confirmed valid and attached at exactly this
    // point -- re-attempt FCM device-token registration here too. This is
    // what actually fixes "no registered token": NotificationService's own
    // one-shot registration attempt in main() runs at cold start, before
    // this method has restored/confirmed the session, so a token fetched
    // there can be silently dropped (no auth.uid() yet) and never retried
    // otherwise. Called on every entry into User mode (app restart AND
    // switching back from Admin on the same device), so it self-heals here
    // regardless of what main() managed to do.
    await _notificationService.registerDeviceToken();
  }

  /// [AuthRepository.ensureAnonymousSession] reports success as soon as it
  /// obtains session data from Supabase, but the underlying GoTrue client
  /// can -- in rare cases -- fetch a valid refreshed session over the
  /// network yet discard it internally without updating its own "current
  /// session," as a guard against a stale refresh overwriting a newer
  /// session if the session changed concurrently. That guard can misfire
  /// right after an Admin-to-User switch on the same device, where the
  /// User's anonymous session is restored immediately after the Admin's was
  /// torn down: [AuthRepository.ensureAnonymousSession] would still resolve
  /// successfully (it returns the session data it fetched), but
  /// `_client.auth.currentSession` would remain unattached, so every
  /// RLS-scoped query right after -- including the linked-device check
  /// above and the winner-celebration check that follows entry into the
  /// User flow -- would silently see no identity at all. This confirms a
  /// session is actually attached to the client before trusting that
  /// restoration really happened, and retries once (a fresh attempt is not
  /// subject to the same race) if it isn't.
  Future<bool> _ensureAttachedAnonymousSession() async {
    final result = await _authRepository.ensureAnonymousSession();
    if (result.isSuccess && _authRepository.currentSession != null) return true;

    final retryResult = await _authRepository.ensureAnonymousSession();
    return retryResult.isSuccess && _authRepository.currentSession != null;
  }
}
