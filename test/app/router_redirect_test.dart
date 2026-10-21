import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/app/router/app_router.dart';
import 'package:rewardsapp/app/router/routes.dart';
import 'package:rewardsapp/features/app_config/domain/app_config.dart';
import 'package:rewardsapp/features/app_config/presentation/app_config_cubit.dart';
import 'package:rewardsapp/features/auth/domain/entities/app_user.dart';
import 'package:rewardsapp/features/auth/presentation/bloc/session_cubit.dart';

const _user = AppUser(id: 'u1', email: 'a@b.co', name: 'A', language: 'en', status: 'ACTIVE');
const _ready = AppConfigState(status: AppConfigStatus.ready);
const _signedIn = SessionState(status: SessionStatus.authenticated, user: _user);
const _signedOut = SessionState(status: SessionStatus.unauthenticated);

String? redirect(
  String location, {
  AppConfigState config = _ready,
  bool update = false,
  SessionState session = _signedIn,
}) => resolveRedirect(location: location, config: config, updateRequired: update, session: session);

void main() {
  test('config loading or failing blocks every route', () {
    expect(redirect(Routes.home, config: const AppConfigState()), Routes.splash);
    expect(redirect(Routes.splash, config: const AppConfigState()), isNull);
    expect(
      redirect(Routes.wallet, config: const AppConfigState(status: AppConfigStatus.failed)),
      Routes.offline,
    );
  });

  test('maintenance and forced update take precedence over the session', () {
    const maintenance = AppConfigState(
      status: AppConfigStatus.ready,
      config: AppConfig(maintenance: true),
    );
    expect(redirect(Routes.home, config: maintenance), Routes.maintenance);
    expect(redirect(Routes.login, config: maintenance, session: _signedOut), Routes.maintenance);
    expect(redirect(Routes.home, update: true), Routes.update);
  });

  test('session states', () {
    expect(redirect(Routes.home, session: const SessionState()), Routes.splash);
    expect(
      redirect(Routes.home, session: const SessionState(status: SessionStatus.offline)),
      Routes.offline,
    );
    expect(redirect(Routes.home, session: _signedOut), Routes.welcome);
    expect(redirect(Routes.registerOtp, session: _signedOut), isNull);
    expect(redirect(Routes.order('o1'), session: _signedOut), Routes.welcome);
  });

  test('signed-in users leave auth and startup screens', () {
    expect(redirect(Routes.splash), Routes.home);
    expect(redirect(Routes.login), Routes.home);
    expect(redirect(Routes.offline), Routes.home);
    expect(redirect(Routes.order('o1')), isNull);
    expect(redirect(Routes.profile), isNull);
  });
}
