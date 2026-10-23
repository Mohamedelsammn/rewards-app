import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/submit_state.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/safe_emit.dart';

/// Email step: `POST /auth/otp/send`. The response is identical whether or
/// not the email is registered.
class SendCodeCubit extends Cubit<SubmitState<OtpSendResult>>
    with SafeEmit<SubmitState<OtpSendResult>> {
  SendCodeCubit(this._auth) : super(const SubmitState());

  final AuthRepository _auth;

  Future<void> send({
    required String email,
    required OtpPurpose purpose,
    required String language,
  }) async {
    if (state.busy) return;
    emit(state.toBusy());
    try {
      final result = await _auth.sendOtp(email: email, purpose: purpose, language: language);
      emit(SubmitState(status: SubmitStatus.success, result: result));
    } catch (error) {
      emit(SubmitState(status: SubmitStatus.failure, error: error));
    }
  }
}

class LoginCubit extends Cubit<SubmitState<AppUser>> with SafeEmit<SubmitState<AppUser>> {
  LoginCubit(this._auth) : super(const SubmitState());

  final AuthRepository _auth;

  Future<void> login(String email, String password) async {
    if (state.busy) return;
    emit(state.toBusy());
    try {
      final user = await _auth.login(email: email, password: password);
      emit(SubmitState(status: SubmitStatus.success, result: user));
    } catch (error) {
      emit(SubmitState(status: SubmitStatus.failure, error: error));
    }
  }
}

/// Character step: `POST /auth/register` with the email proof.
class RegisterCubit extends Cubit<SubmitState<AppUser>> with SafeEmit<SubmitState<AppUser>> {
  RegisterCubit(this._auth) : super(const SubmitState());

  final AuthRepository _auth;

  Future<void> register({
    required String email,
    required String verificationToken,
    required String password,
    required int avatarId,
    required String language,
  }) async {
    if (state.busy) return;
    emit(state.toBusy());
    try {
      final user = await _auth.register(
        email: email,
        verificationToken: verificationToken,
        password: password,
        avatarId: avatarId,
        language: language,
      );
      emit(SubmitState(status: SubmitStatus.success, result: user));
    } catch (error) {
      emit(SubmitState(status: SubmitStatus.failure, error: error));
    }
  }
}

/// Forgot-password final step: `POST /auth/password/reset`.
class ResetPasswordCubit extends Cubit<SubmitState<void>> with SafeEmit<SubmitState<void>> {
  ResetPasswordCubit(this._auth) : super(const SubmitState());

  final AuthRepository _auth;

  Future<void> reset({
    required String email,
    required String verificationToken,
    required String newPassword,
  }) async {
    if (state.busy) return;
    emit(state.toBusy());
    try {
      await _auth.resetPassword(
        email: email,
        verificationToken: verificationToken,
        newPassword: newPassword,
      );
      emit(const SubmitState(status: SubmitStatus.success));
    } catch (error) {
      emit(SubmitState(status: SubmitStatus.failure, error: error));
    }
  }
}

/// Errors that mean the email proof is gone and the flow must restart.
bool requiresRestart(Object? error) =>
    error is AppException &&
    (error.code == 'OTP_VERIFICATION_INVALID' || error.code == 'OTP_EXPIRED');
