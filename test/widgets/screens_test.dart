import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/app/di/injection_container.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/core/utils/cursor_page.dart';
import 'package:rewardsapp/features/auth/domain/entities/app_user.dart';
import 'package:rewardsapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardsapp/features/auth/presentation/bloc/session_cubit.dart';
import 'package:rewardsapp/features/auth/presentation/pages/login_page.dart';
import 'package:rewardsapp/features/home/domain/home_feed.dart';
import 'package:rewardsapp/features/home/presentation/pages/home_page.dart';
import 'package:rewardsapp/features/notifications/domain/notification_entities.dart';
import 'package:rewardsapp/features/notifications/presentation/bloc/unread_count_cubit.dart';
import 'package:rewardsapp/features/wallet/domain/wallet_entities.dart';
import 'package:rewardsapp/features/wallet/presentation/bloc/wallet_cubit.dart';

const _user = AppUser(id: 'u1', email: 'a@b.co', name: 'Ahmed', language: 'en', status: 'ACTIVE');

class _Auth implements AuthRepository {
  String? password;

  @override
  Future<AppUser> login({required String email, required String password}) async {
    this.password = password;
    if (password != 'correct-pass1') {
      throw const AppException(code: 'INVALID_CREDENTIALS', statusCode: 401);
    }
    return _user;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Home implements HomeRepository {
  @override
  Future<HomeFeed> home() async => const HomeFeed();

  @override
  Future<HomeFeed> search(String query) async => const HomeFeed();
}

class _Wallet implements WalletRepository {
  @override
  Future<Wallet> wallet() async => const Wallet(balance: 1200);

  @override
  Future<CursorPage<WalletTransaction>> transactions({String? cursor}) async =>
      const CursorPage(items: []);
}

class _Notifications implements NotificationsRepository {
  @override
  Future<int> unreadCount() async => 3;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget _app(
  Widget child, {
  required SessionCubit session,
  WalletCubit? wallet,
  UnreadCountCubit? unread,
  Locale locale = const Locale('en'),
}) => MultiBlocProvider(
  providers: [
    BlocProvider<SessionCubit>.value(value: session),
    if (wallet != null) BlocProvider<WalletCubit>.value(value: wallet),
    if (unread != null) BlocProvider<UnreadCountCubit>.value(value: unread),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ),
);

void main() {
  late _Auth auth;

  setUp(() async {
    await sl.reset();
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2400);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
    auth = _Auth();
    sl
      ..registerSingleton<AuthRepository>(auth)
      ..registerSingleton<HomeRepository>(_Home());
  });

  testWidgets('login validates input, shows server errors and signs in', (tester) async {
    final session = SessionCubit(auth);
    await tester.pumpWidget(_app(const LoginPage(), session: session));
    final l10n = AppLocalizations.of(tester.element(find.byType(LoginPage)));

    await tester.tap(find.text(l10n.loginButton));
    await tester.pump();
    expect(find.text(l10n.loginInvalidInput), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'A@B.co ');
    await tester.enterText(fields.at(1), 'wrong');
    await tester.ensureVisible(find.text(l10n.loginButton));
    await tester.tap(find.text(l10n.loginButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errInvalidCredentials), findsOneWidget);
    expect(session.state.isAuthenticated, isFalse);

    await tester.enterText(fields.at(1), 'correct-pass1');
    await tester.tap(find.text(l10n.loginButton));
    await tester.pumpAndSettle();
    expect(auth.password, 'correct-pass1');
    expect(session.state.user, _user);
  });

  testWidgets('home shows the balance, unread badge and an empty state', (tester) async {
    final session = SessionCubit(auth)..signedIn(_user);
    final wallet = WalletCubit(_Wallet());
    final unread = UnreadCountCubit(_Notifications());
    await wallet.load();
    await unread.refresh();

    await tester.pumpWidget(
      _app(
        const Scaffold(body: HomePage()),
        session: session,
        wallet: wallet,
        unread: unread,
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(HomePage)));

    expect(find.text('1,200'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(l10n.homeEmpty), findsOneWidget);
  });

  testWidgets('home renders right-to-left in Arabic', (tester) async {
    final session = SessionCubit(auth)..signedIn(_user);
    final wallet = WalletCubit(_Wallet());
    final unread = UnreadCountCubit(_Notifications());
    await tester.pumpWidget(
      _app(
        const Scaffold(body: HomePage()),
        locale: const Locale('ar'),
        session: session,
        wallet: wallet,
        unread: unread,
      ),
    );
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.byType(HomePage))), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
