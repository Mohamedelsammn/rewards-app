import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/app/di/injection_container.dart';
import 'package:rewardsapp/app/shell/app_bottom_bar.dart';
import 'package:rewardsapp/app/shell/nav_glyph.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/core/utils/cursor_page.dart';
import 'package:rewardsapp/features/auth/domain/entities/app_user.dart';
import 'package:rewardsapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardsapp/features/auth/presentation/bloc/session_cubit.dart';
import 'package:rewardsapp/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rewardsapp/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:rewardsapp/features/catalog/presentation/pages/categories_page.dart';
import 'package:rewardsapp/features/home/domain/home_feed.dart';
import 'package:rewardsapp/features/home/presentation/pages/home_page.dart';
import 'package:rewardsapp/features/notifications/domain/notification_entities.dart';
import 'package:rewardsapp/features/notifications/presentation/bloc/unread_count_cubit.dart';
import 'package:rewardsapp/features/notifications/presentation/widgets/unread_notification_button.dart';
import 'package:rewardsapp/features/profile/presentation/widgets/profile_header.dart';
import 'package:rewardsapp/features/wallet/domain/wallet_entities.dart';
import 'package:rewardsapp/features/wallet/presentation/bloc/wallet_cubit.dart';

const _user = AppUser(
  id: 'u1',
  email: 'ahmed@example.com',
  name: 'Ahmed',
  language: 'en',
  status: 'ACTIVE',
  avatarId: 4,
);

/// Each call to home()/categories() returns the next pending completer.
class _Home implements HomeRepository {
  final calls = <Completer<HomeFeed>>[];

  @override
  Future<HomeFeed> home() {
    final completer = Completer<HomeFeed>();
    calls.add(completer);
    return completer.future;
  }

  @override
  Future<HomeFeed> search(String query) async => const HomeFeed();
}

class _Catalog implements CatalogRepository {
  final calls = <Completer<List<RewardCategory>>>[];

  @override
  Future<List<RewardCategory>> categories() {
    final completer = Completer<List<RewardCategory>>();
    calls.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Wallet implements WalletRepository {
  @override
  Future<Wallet> wallet() async => const Wallet(balance: 0);

  @override
  Future<CursorPage<WalletTransaction>> transactions({String? cursor}) async =>
      const CursorPage(items: []);
}

class _Notifications implements NotificationsRepository {
  @override
  Future<int> unreadCount() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Auth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MultiBlocProvider(
  providers: [
    BlocProvider<SessionCubit>.value(value: SessionCubit(_Auth())..signedIn(_user)),
    // Loaded like the app does on start; an unloaded wallet shows a skeleton.
    BlocProvider<WalletCubit>.value(value: WalletCubit(_Wallet())..load()),
    BlocProvider<UnreadCountCubit>.value(value: UnreadCountCubit(_Notifications())),
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
    home: Scaffold(body: child),
  ),
);

AppLocalizations _l10n(WidgetTester tester, Type type) =>
    AppLocalizations.of(tester.element(find.byType(type)));

void main() {
  late _Home home;
  late _Catalog catalog;

  setUp(() async {
    await sl.reset();
    home = _Home();
    catalog = _Catalog();
    sl
      ..registerSingleton<HomeRepository>(home)
      ..registerSingleton<CatalogRepository>(catalog);
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2400);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
  });

  group('Home', () {
    testWidgets('shows a skeleton (no spinner) until the feed arrives, then the empty state', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const HomePage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('home-skeleton')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The live header stays visible while loading.
      expect(find.text(_l10n(tester, HomePage).homeYourPoints), findsOneWidget);

      home.calls.single.complete(const HomeFeed());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('home-skeleton')), findsNothing);
      expect(find.byKey(const ValueKey('home-empty')), findsOneWidget);
      expect(find.text(_l10n(tester, HomePage).homeEmptyTitle), findsOneWidget);
    });

    testWidgets('pull-to-refresh keeps the current content instead of the skeleton', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const HomePage()));
      home.calls.single.complete(const HomeFeed());
      await tester.pumpAndSettle();

      await tester.fling(find.byKey(const ValueKey('home-empty')), const Offset(0, 500), 1500);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(home.calls, hasLength(2), reason: 'refresh requested the feed again');
      expect(find.byKey(const ValueKey('home-skeleton')), findsNothing);
      expect(find.byKey(const ValueKey('home-empty')), findsOneWidget);

      home.calls.last.complete(const HomeFeed());
      await tester.pumpAndSettle();
      expect(home.calls, hasLength(2), reason: 'no duplicate requests');
    });

    testWidgets('renders right-to-left in Arabic', (tester) async {
      await tester.pumpWidget(_app(const HomePage(), locale: const Locale('ar')));
      home.calls.single.complete(const HomeFeed());
      await tester.pumpAndSettle();

      final l10n = _l10n(tester, HomePage);
      expect(Directionality.of(tester.element(find.byType(HomePage))), TextDirection.rtl);
      expect(find.text(l10n.homeEmptyTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Categories', () {
    testWidgets('shows banner skeletons, then the empty state', (tester) async {
      await tester.pumpWidget(_app(const CategoriesPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('categories-skeleton')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      catalog.calls.single.complete(const []);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = _l10n(tester, CategoriesPage);
      expect(find.byKey(const ValueKey('categories-skeleton')), findsNothing);
      expect(find.byKey(const ValueKey('categories-empty')), findsOneWidget);
      expect(find.text(l10n.categoriesEmptyTitle), findsOneWidget);
      expect(find.text(l10n.categoriesEmptyBody), findsOneWidget);
    });
  });

  group('Bottom bar', () {
    testWidgets('three painted tabs, avatar unlabeled until selected', (tester) async {
      var selected = -1;
      await tester.pumpWidget(_app(AppBottomBar(currentIndex: 0, onSelect: (i) => selected = i)));
      final l10n = _l10n(tester, AppBottomBar);

      expect(find.byType(NavGlyph), findsNWidgets(3));
      for (final label in [l10n.navHome, l10n.navCategories, l10n.navWallet]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text(l10n.navProfile), findsNothing);
      expect(find.bySemanticsLabel(l10n.navProfile), findsOneWidget);

      await tester.tap(find.text(l10n.navWallet));
      expect(selected, 2);
      await tester.tap(find.byKey(const ValueKey('nav-profile')));
      expect(selected, 3);

      await tester.pumpWidget(_app(AppBottomBar(currentIndex: 3, onSelect: (_) {})));
      expect(find.text(l10n.navProfile), findsOneWidget);
    });

    testWidgets('fits 61 logical px above the inset and mirrors in Arabic', (tester) async {
      await tester.pumpWidget(
        _app(AppBottomBar(currentIndex: 1, onSelect: (_) {}), locale: const Locale('ar')),
      );
      final l10n = _l10n(tester, AppBottomBar);
      expect(find.text(l10n.navCategories), findsOneWidget);
      // The top border is painted inside the bar.
      expect(tester.getSize(find.byType(AppBottomBar)).height, AppBottomBar.height);

      final home = tester.getCenter(find.text(l10n.navHome));
      final wallet = tester.getCenter(find.text(l10n.navWallet));
      expect(home.dx, greaterThan(wallet.dx), reason: 'Home is the rightmost tab in RTL');
      expect(tester.takeException(), isNull);
    });
  });

  group('Profile header', () {
    testWidgets('shows the user, the edit action and no notification bell', (tester) async {
      await tester.pumpWidget(_app(const ProfileHeader(user: _user)));
      final l10n = _l10n(tester, ProfileHeader);

      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('ahmed@example.com'), findsOneWidget);
      expect(find.byTooltip(l10n.profileEditTooltip), findsOneWidget);
      expect(find.byType(UnreadNotificationButton), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('grows with large text instead of clipping the email', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: _app(const ProfileHeader(user: _user), locale: const Locale('ar')),
        ),
      );
      final header = tester.getRect(find.byType(ProfileHeader));
      final email = tester.getRect(find.text('ahmed@example.com'));
      expect(email.bottom, lessThanOrEqualTo(header.bottom));
      expect(tester.takeException(), isNull);
    });
  });
}
