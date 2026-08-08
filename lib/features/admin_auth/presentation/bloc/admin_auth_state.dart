import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

enum AdminAuthStatus { idle, submitting, success, error }

class AdminAuthState extends Equatable {
  const AdminAuthState({this.status = AdminAuthStatus.idle, this.failure});

  final AdminAuthStatus status;
  final Failure? failure;

  AdminAuthState copyWith({AdminAuthStatus? status, Failure? failure}) {
    return AdminAuthState(status: status ?? this.status, failure: failure);
  }

  @override
  List<Object?> get props => [status, failure];
}
