import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/safe_emit.dart';

class OtpState extends Equatable {
  const OtpState({
    this.secondsLeft = 60,
    this.verifying = false,
    this.resending = false,
    this.verification,
    this.error,
    this.resent = false,
  });

  final int secondsLeft;
  final bool verifying;
  final bool resending;
  final OtpVerification? verification;
  final Object? error;

  /// True right after a successful resend, for a one-off confirmation.
  final bool resent;

  /// Too many attempts / locked: a new code is required before verifying.
  bool get needsNewCode =>
      error is AppException &&
      const {'OTP_ATTEMPTS_EXCEEDED', 'OTP_EXPIRED'}.contains((error as AppException).code);

  OtpState copyWith({
    int? secondsLeft,
    bool? verifying,
    bool? resending,
    OtpVerification? verification,
    Object? error,
    bool clearError = false,
    bool resent = false,
  }) => OtpState(
    secondsLeft: secondsLeft ?? this.secondsLeft,
    verifying: verifying ?? this.verifying,
    resending: resending ?? this.resending,
    verification: verification ?? this.verification,
    error: clearError ? null : error ?? this.error,
    resent: resent,
  );

  @override
  List<Object?> get props => [secondsLeft, verifying, resending, verification, error, resent];
}

/// Verifies the 6-digit code and runs the server-driven resend countdown.
class OtpCubit extends Cubit<OtpState> with SafeEmit<OtpState> {
  OtpCubit(
    this._auth, {
    required this.email,
    required this.purpose,
    required this.language,
    int resendAfter = 60,
  }) : super(OtpState(secondsLeft: resendAfter)) {
    _startCountdown(resendAfter);
  }

  final AuthRepository _auth;
  final String email;
  final OtpPurpose purpose;
  final String language;
  Timer? _timer;

  void _startCountdown(int seconds) {
    _timer?.cancel();
    emit(state.copyWith(secondsLeft: seconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;
      if (state.secondsLeft <= 1) {
        _timer?.cancel();
        emit(state.copyWith(secondsLeft: 0));
      } else {
        emit(state.copyWith(secondsLeft: state.secondsLeft - 1));
      }
    });
  }

  void clearError() => emit(state.copyWith(clearError: true));

  Future<void> verify(String code) async {
    if (state.verifying || state.verification != null) return;
    emit(state.copyWith(verifying: true, clearError: true));
    try {
      final verification = await _auth.verifyOtp(email: email, purpose: purpose, code: code);
      emit(state.copyWith(verifying: false, verification: verification));
    } catch (error) {
      emit(state.copyWith(verifying: false, error: error));
    }
  }

  Future<void> resend() async {
    if (state.resending || state.secondsLeft > 0) return;
    emit(state.copyWith(resending: true, clearError: true));
    try {
      final result = await _auth.sendOtp(email: email, purpose: purpose, language: language);
      emit(state.copyWith(resending: false, resent: true));
      _startCountdown(result.resendAfter);
    } on AppException catch (error) {
      emit(state.copyWith(resending: false, error: error));
      final retry = error.retryAfterSeconds;
      if (error.code == 'OTP_RESEND_COOLDOWN' && retry != null) _startCountdown(retry);
    } catch (error) {
      emit(state.copyWith(resending: false, error: error));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
