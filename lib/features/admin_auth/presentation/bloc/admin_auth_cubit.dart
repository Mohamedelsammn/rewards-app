import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/repositories/auth_repository.dart';
import 'admin_auth_state.dart';

class AdminAuthCubit extends Cubit<AdminAuthState> {
  AdminAuthCubit(this._authRepository) : super(const AdminAuthState());

  final AuthRepository _authRepository;

  /// Clears any error/submitting state left over from switching between
  /// Sign In and Sign Up.
  void reset() => emit(const AdminAuthState());

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(status: AdminAuthStatus.submitting));
    final result = await _authRepository.signInAdmin(email: email, password: password);
    result.fold(
      (failure) => emit(state.copyWith(status: AdminAuthStatus.error, failure: failure)),
      (_) => emit(state.copyWith(status: AdminAuthStatus.success)),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String accessCode,
  }) async {
    emit(state.copyWith(status: AdminAuthStatus.submitting));
    final result = await _authRepository.signUpAdmin(
      email: email,
      password: password,
      fullName: fullName,
      accessCode: accessCode,
    );
    result.fold(
      (failure) => emit(state.copyWith(status: AdminAuthStatus.error, failure: failure)),
      (_) => emit(state.copyWith(status: AdminAuthStatus.success)),
    );
  }
}
