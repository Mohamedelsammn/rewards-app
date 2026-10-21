import 'package:equatable/equatable.dart';

enum SubmitStatus { idle, busy, success, failure }

/// State of a single user-triggered request (send code, sign in, save…).
class SubmitState<T> extends Equatable {
  const SubmitState({this.status = SubmitStatus.idle, this.result, this.error});

  final SubmitStatus status;
  final T? result;
  final Object? error;

  bool get busy => status == SubmitStatus.busy;

  SubmitState<T> toBusy() => SubmitState<T>(status: SubmitStatus.busy, result: result);

  @override
  List<Object?> get props => [status, result, error];
}
