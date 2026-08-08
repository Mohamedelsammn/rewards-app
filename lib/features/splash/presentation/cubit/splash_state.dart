import 'package:equatable/equatable.dart';

enum SplashDestination { roleSelection, userHome }

class SplashState extends Equatable {
  const SplashState({this.destination});

  final SplashDestination? destination;

  bool get isReady => destination != null;

  @override
  List<Object?> get props => [destination];
}
