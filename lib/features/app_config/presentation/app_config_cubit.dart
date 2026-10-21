import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/app_config.dart';

enum AppConfigStatus { loading, ready, failed }

class AppConfigState extends Equatable {
  const AppConfigState({
    this.status = AppConfigStatus.loading,
    this.config = const AppConfig(),
    this.error,
  });

  final AppConfigStatus status;
  final AppConfig config;
  final Object? error;

  @override
  List<Object?> get props => [status, config, error];
}

/// Loads `/app-config` at startup and on resume. The router blocks the app
/// for maintenance and for versions below `minVersion`.
class AppConfigCubit extends Cubit<AppConfigState> {
  AppConfigCubit(this._repository, {required this.appVersion}) : super(const AppConfigState());

  final AppConfigRepository _repository;
  final String appVersion;

  bool get updateRequired =>
      state.status == AppConfigStatus.ready && state.config.requiresUpdate(appVersion);

  bool get maintenance => state.status == AppConfigStatus.ready && state.config.maintenance;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(AppConfigState(config: state.config));
    try {
      emit(AppConfigState(status: AppConfigStatus.ready, config: await _repository.fetch()));
    } catch (error) {
      // A silent refresh keeps the last good config instead of blocking.
      if (silent && state.status == AppConfigStatus.ready) return;
      emit(AppConfigState(status: AppConfigStatus.failed, config: state.config, error: error));
    }
  }
}
