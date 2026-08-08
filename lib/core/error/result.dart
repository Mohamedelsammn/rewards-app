import 'failure.dart';

/// Minimal Either-style result wrapper. Repositories return `Result<T>`
/// instead of throwing, so Blocs can pattern-match success/failure without
/// depending on a full functional-programming package for one shape.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = Error<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Error<T>;

  R fold<R>(R Function(Failure failure) onFailure, R Function(T value) onSuccess) {
    final self = this;
    if (self is Success<T>) return onSuccess(self.value);
    if (self is Error<T>) return onFailure(self.failure);
    throw StateError('Unreachable');
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
