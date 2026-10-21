import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum SessionStatus { unknown, authenticated, unauthenticated, offline }

class SessionState extends Equatable {
  const SessionState({this.status = SessionStatus.unknown, this.user, this.endReason});

  final SessionStatus status;
  final AppUser? user;

  /// Set when the session ended without the user signing out.
  final SessionEndReason? endReason;

  bool get isAuthenticated => status == SessionStatus.authenticated && user != null;

  @override
  List<Object?> get props => [status, user, endReason];
}

/// App-wide authentication state. The router redirects on it.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth, {this._beforeSignOut}) : super(const SessionState());

  final AuthRepository _auth;
  final Future<void> Function()? _beforeSignOut;

  Future<void> restore() async {
    if (!await _auth.hasStoredSession()) {
      emit(const SessionState(status: SessionStatus.unauthenticated));
      return;
    }
    try {
      emit(SessionState(status: SessionStatus.authenticated, user: await _auth.restoreSession()));
    } on AppException catch (error) {
      if (error.isConnectivity || (error.statusCode ?? 0) >= 500) {
        emit(const SessionState(status: SessionStatus.offline));
        return;
      }
      await _auth.clearLocalSession();
      emit(
        SessionState(
          status: SessionStatus.unauthenticated,
          endReason: error.code == 'ACCOUNT_SUSPENDED'
              ? SessionEndReason.suspended
              : SessionEndReason.refreshRejected,
        ),
      );
    }
  }

  void signedIn(AppUser user) =>
      emit(SessionState(status: SessionStatus.authenticated, user: user));

  void userUpdated(AppUser user) {
    if (state.isAuthenticated) emit(SessionState(status: SessionStatus.authenticated, user: user));
  }

  /// Keeps the profile counters in sync after server-side changes.
  void updateStats({int? points, int? giveaways, int? orders}) {
    final user = state.user;
    if (!state.isAuthenticated || user == null) return;
    userUpdated(
      user.copyWith(
        stats: UserStats(
          points: points ?? user.stats.points,
          giveaways: giveaways ?? user.stats.giveaways,
          orders: orders ?? user.stats.orders,
        ),
      ),
    );
  }

  /// Called by the network layer when the refresh token was rejected.
  void sessionEnded(SessionEndReason reason) {
    if (state.status == SessionStatus.unauthenticated) return;
    emit(SessionState(status: SessionStatus.unauthenticated, endReason: reason));
  }

  Future<void> signOut() async {
    try {
      await _beforeSignOut?.call();
    } finally {
      await _auth.logout();
      emit(const SessionState(status: SessionStatus.unauthenticated));
    }
  }

  /// After account deletion or "log out of all devices".
  Future<void> endLocally() async {
    await _auth.clearLocalSession();
    emit(const SessionState(status: SessionStatus.unauthenticated));
  }

  void acknowledgeEndReason() {
    if (state.endReason != null) emit(SessionState(status: state.status, user: state.user));
  }
}
