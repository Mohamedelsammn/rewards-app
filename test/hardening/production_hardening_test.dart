import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/core/network/auth_interceptor.dart';
import 'package:rewardsapp/core/security/secure_token_storage.dart';
import 'package:rewardsapp/core/services/admob_service.dart';
import 'package:rewardsapp/core/services/ads/fullscreen_ad.dart';
import 'package:rewardsapp/core/services/ads/fullscreen_ad_gate.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/core/utils/cursor_page.dart';
import 'package:rewardsapp/core/utils/paged_list_state.dart';
import 'package:rewardsapp/core/widgets/paged_list_view.dart';
import 'package:rewardsapp/features/app_config/data/app_config_repository_impl.dart';
import 'package:rewardsapp/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rewardsapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rewardsapp/features/auth/domain/entities/app_user.dart';
import 'package:rewardsapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardsapp/features/auth/presentation/bloc/auth_flow_cubits.dart';
import 'package:rewardsapp/features/auth/presentation/bloc/session_cubit.dart';
import 'package:rewardsapp/features/catalog/data/catalog_repository_impl.dart';
import 'package:rewardsapp/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rewardsapp/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:rewardsapp/features/giveaways/domain/entities/giveaway_entities.dart';
import 'package:rewardsapp/features/giveaways/domain/repositories/giveaways_repository.dart';
import 'package:rewardsapp/features/giveaways/presentation/bloc/giveaway_cubits.dart';
import 'package:rewardsapp/features/giveaways/presentation/join_ad/giveaway_join_ads.dart';
import 'package:rewardsapp/features/notifications/domain/notification_entities.dart';
import 'package:rewardsapp/features/notifications/presentation/bloc/unread_count_cubit.dart';
import 'package:rewardsapp/features/orders/data/orders_repository_impl.dart';
import 'package:rewardsapp/features/orders/domain/order_entities.dart';
import 'package:rewardsapp/features/orders/presentation/bloc/orders_cubits.dart';
import 'package:rewardsapp/features/orders/presentation/redemption/redeem_cubit.dart';
import 'package:rewardsapp/features/wallet/domain/wallet_entities.dart';
import 'package:rewardsapp/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:rewardsapp/features/wallet/presentation/pages/wallet_page.dart';

import '../helpers/fake_api.dart';

// ---------------------------------------------------------------- fakes ---

/// Wallet answers held until the test completes them.
class _Wallets implements WalletRepository {
  final pending = <Completer<Wallet>>[];

  @override
  Future<Wallet> wallet() {
    final c = Completer<Wallet>();
    pending.add(c);
    return c.future;
  }

  @override
  Future<CursorPage<WalletTransaction>> transactions({String? cursor}) async =>
      const CursorPage(items: []);
}

class _Unread implements NotificationsRepository {
  final pending = <Completer<int>>[];

  @override
  Future<int> unreadCount() {
    final c = Completer<int>();
    pending.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Secure storage whose reads fail like a backup restored without its keys.
class _BrokenStorage extends FlutterSecureStorage {
  const _BrokenStorage();

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'BAD_DECRYPT');

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'BAD_DECRYPT');
}

/// AuthRepository with a scripted restore.
class _Auth implements AuthRepository {
  _Auth({required this.restore});

  final Future<AppUser> Function() restore;
  int cleared = 0;
  Completer<AppUser>? loginGate;

  @override
  Future<bool> hasStoredSession() async => true;

  @override
  Future<AppUser> restoreSession() => restore();

  @override
  Future<void> clearLocalSession() async => cleared++;

  @override
  Future<AppUser> login({required String email, required String password}) => loginGate!.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _user = AppUser(id: 'u1', email: 'a@b.co', name: 'A', language: 'en', status: 'ACTIVE');

class _Giveaways implements GiveawaysRepository {
  final details$ = Completer<GiveawayDetails>();
  final enter$ = Completer<GiveawayEntry>();

  @override
  Future<GiveawayDetails> details(String id) => details$.future;

  @override
  Future<GiveawayEntry> enter(String giveawayId) => enter$.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _OrdersHeld implements OrdersRepository {
  final order$ = Completer<Order>();

  @override
  Future<Order> order(String id) => order$.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Records every create() call and answers from a queue.
class _Orders implements OrdersRepository {
  _Orders(this.answers);

  final List<Object> answers;
  final keys = <String>[];
  final bodies = <Map<String, String>>[];

  @override
  Future<OrderWithBalance> create({
    required String productId,
    required Map<String, String> fields,
    required int expectedPointsPrice,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    bodies.add(Map.of(fields));
    final answer = answers.removeAt(0);
    if (answer is AppException) throw answer;
    return answer as OrderWithBalance;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _product = Product(
  id: 'p1',
  categoryId: 'c1',
  name: LocalizedText(en: '60 UC'),
  pointsPrice: 400,
);

class _Catalog implements CatalogRepository {
  @override
  Future<Product> product(String id) async => _product;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

OrderWithBalance _created() => OrderWithBalance(
  order: parseOrder(Map<String, dynamic>.from(fixture('order_created')['order'] as Map)),
  balance: 700,
);

class _HangingLoader implements FullscreenAdLoader {
  final pending = <Completer<FullscreenAd?>>[];

  @override
  Future<FullscreenAd?> load(FullscreenAdFormat format, String adUnitId) {
    final c = Completer<FullscreenAd?>();
    pending.add(c);
    return c.future;
  }
}

class _Ad implements FullscreenAd {
  _Ad({this.hang = false});

  final bool hang;
  bool disposed = false;

  @override
  Future<bool> show() => hang ? Completer<bool>().future : Future.value(true);

  @override
  void dispose() => disposed = true;
}

Widget _localized(Widget child, {double textScale = 1, Size size = const Size(411, 914)}) =>
    MaterialApp(
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    );

void main() {
  // ------------------------------------------------------------- CR-01 ---
  group('CR-01 account isolation', () {
    test('sign-out during a wallet request: the old balance is never shown', () async {
      final repo = _Wallets();
      final cubit = WalletCubit(repo);
      final loading = cubit.load();
      cubit.clear(); // Account A signs out.
      repo.pending.single.complete(const Wallet(balance: 900));
      await loading;
      expect(cubit.state.wallet, isNull);
      await cubit.close();
    });

    test('account B signs in before A\'s wallet answers: only B\'s balance', () async {
      final repo = _Wallets();
      final cubit = WalletCubit(repo);
      final a = cubit.load();
      cubit.clear();
      final b = cubit.load(); // Not joined to A's request.
      expect(repo.pending, hasLength(2));
      repo.pending[1].complete(const Wallet(balance: 50)); // B
      await b;
      repo.pending[0].complete(const Wallet(balance: 900)); // A, late
      await a;
      expect(cubit.state.balance, 50);
      // A third load runs normally (no stuck in-flight request).
      final c = cubit.load();
      repo.pending[2].complete(const Wallet(balance: 60));
      await c;
      expect(cubit.state.balance, 60);
      await cubit.close();
    });

    test('a failed old request does not restore stale data', () async {
      final repo = _Wallets();
      final cubit = WalletCubit(repo);
      final a = cubit.load();
      cubit.clear();
      repo.pending.single.completeError(const AppException(code: 'NETWORK_ERROR'));
      await a;
      expect(cubit.state, const WalletState());
      await cubit.close();
    });

    test('unread badge of the previous account is dropped', () async {
      final repo = _Unread();
      final cubit = UnreadCountCubit(repo);
      final a = cubit.refresh();
      cubit.clear();
      final b = cubit.refresh();
      repo.pending[1].complete(2);
      await b;
      repo.pending[0].complete(17);
      await a;
      expect(cubit.state, 2);
      await cubit.close();
    });
  });

  // ------------------------------------------------------ CR-02 / CR-03 ---
  group('CR-02/03 storage failures and startup', () {
    test('unreadable secure storage: no crash, sign-in requested once', () async {
      final tokens = SecureTokenStorage(const _BrokenStorage());
      expect(await tokens.accessToken, isNull);
      expect(await tokens.languageCode, isNull, reason: 'locale falls back to the device');
      final repo = AuthRepositoryImpl(
        AuthRemoteDataSource(FakeApi((_) => const FakeResponse(200)).client),
        tokens,
      );
      final session = SessionCubit(repo);
      await session.restore();
      expect(session.state.status, SessionStatus.unauthenticated);
      expect(session.state.endReason, SessionEndReason.refreshRejected);
    });

    test('a malformed /me never leaves the splash waiting (offline + Retry)', () async {
      final auth = _Auth(restore: () async => throw TypeError());
      final session = SessionCubit(auth);
      await session.restore();
      expect(session.state.status, SessionStatus.offline);
      expect(auth.cleared, 0, reason: 'a bad response is not a sign-out');
    });

    test('network timeout → offline; rejected session → signed out', () async {
      var session = SessionCubit(
        _Auth(restore: () async => throw const AppException(code: AppException.timeout)),
      );
      await session.restore();
      expect(session.state.status, SessionStatus.offline);

      final auth = _Auth(
        restore: () async =>
            throw const AppException(code: 'INVALID_REFRESH_TOKEN', statusCode: 401),
      );
      session = SessionCubit(auth);
      await session.restore();
      expect(session.state.status, SessionStatus.unauthenticated);
      expect(auth.cleared, 1);
    });

    test('a valid session restores', () async {
      final session = SessionCubit(_Auth(restore: () async => _user));
      await session.restore();
      expect(session.state.isAuthenticated, isTrue);
    });
  });

  // ------------------------------------------------------------- CR-04 ---
  group('CR-04 no emit after close', () {
    test('giveaway details: success and failure after leaving the screen', () async {
      final repo = _Giveaways();
      final cubit = GiveawayDetailsCubit(repo, 'g1');
      final loading = cubit.load();
      await cubit.close();
      repo.details$.complete(
        const GiveawayDetails(
          giveaway: Giveaway(
            id: 'g1',
            title: LocalizedText(en: 'G'),
            status: GiveawayStatus.active,
          ),
        ),
      );
      await expectLater(loading, completes);
    });

    test('login answer after leaving the screen', () async {
      final auth = _Auth(restore: () async => _user)..loginGate = Completer<AppUser>();
      final cubit = LoginCubit(auth);
      final login = cubit.login('a@b.co', 'secret123');
      await cubit.close();
      auth.loginGate!.completeError(const AppException(code: 'INVALID_CREDENTIALS'));
      await expectLater(login, completes);
    });

    test('order details answer after leaving the screen', () async {
      final repo = _OrdersHeld();
      final cubit = OrderDetailsCubit(repo, 'o1');
      final loading = cubit.load();
      await cubit.close();
      repo.order$.completeError(const AppException(code: 'NETWORK_ERROR'));
      await expectLater(loading, completes);
    });
  });

  // ------------------------------------------------------------- CR-06 ---
  test('CR-06 a server ignoring productType cannot fill both tabs', () async {
    final api = FakeApi(
      (_) => const FakeResponse(200, {
        'items': [
          {
            'id': 'a',
            'categoryId': 'g',
            'name': {'en': '60 UC'},
            'pointsPrice': 1,
            'productType': 'TOP_UP',
          },
          {
            'id': 'b',
            'categoryId': 'g',
            'name': {'en': 'Skin'},
            'pointsPrice': 1,
            'productType': 'ITEM_SKIN',
          },
          {
            'id': 'c',
            'categoryId': 'g',
            'name': {'en': 'Old'},
            'pointsPrice': 1,
            'productType': null,
          },
        ],
      }),
    );
    final repo = CatalogRepositoryImpl(api.client);
    expect((await repo.products('g', productType: ProductType.topUp)).map((p) => p.id), ['a']);
    expect((await repo.products('g', productType: ProductType.itemSkin)).map((p) => p.id), ['b']);
    expect((await repo.products('g')).map((p) => p.id), ['a', 'b', 'c'], reason: 'non-game list');
  });

  // ------------------------------------------------------------- CR-07 ---
  testWidgets('CR-07 a long paged history builds only visible rows', (tester) async {
    var built = 0;
    final state = PagedListState<int, Object?>(
      status: PagedStatus.ready,
      items: List.generate(2000, (i) => i),
      filter: null,
    );
    await tester.pumpWidget(
      _localized(
        Scaffold(
          body: PagedListView<int, Object?>(
            state: state,
            onRefresh: () async {},
            onLoadMore: () {},
            emptyMessage: 'empty',
            skeletonRow: const SizedBox(height: 60),
            itemBuilder: (_, i) {
              built++;
              return SizedBox(height: 60, child: Text('row $i'));
            },
          ),
        ),
      ),
    );
    expect(find.text('row 0'), findsOneWidget);
    expect(built, lessThan(60), reason: 'not 2000');
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(find.text('row 0'), findsNothing);
  });

  // ------------------------------------------------------------- CR-08 ---
  test('CR-08 startup requests: 6 s budget and a single retry', () async {
    final api = FakeApi((_) => const FakeResponse(503));
    await expectLater(AppConfigRepositoryImpl(api.client).fetch(), throwsA(isA<AppException>()));
    final configCalls = api.adapter.requests.where((r) => r.path == '/app-config').toList();
    expect(configCalls, hasLength(2), reason: 'one retry instead of two');
    expect(configCalls.first.connectTimeout, const Duration(seconds: 6));
    expect(configCalls.first.receiveTimeout, const Duration(seconds: 6));

    // Normal requests keep the default policy (two retries).
    api.adapter.requests.clear();
    await expectLater(api.client.get('/wallet'), throwsA(isA<AppException>()));
    expect(api.adapter.requests, hasLength(3));
  });

  // ------------------------------------------------------------- CR-09 ---
  group('CR-09 redemption idempotency', () {
    Future<RedeemCubit> ready(_Orders orders) async {
      final cubit = RedeemCubit(_Catalog(), orders, productId: 'p1');
      await cubit.loadProduct();
      return cubit;
    }

    test('timeout, then an identical retry replays the same key and body', () async {
      final orders = _Orders([const AppException(code: AppException.timeout), _created()]);
      final cubit = await ready(orders);
      await cubit.submit({'playerId': '123'});
      expect(cubit.state.status, RedeemStatus.failure);
      await cubit.submit({'playerId': '123'});
      expect(cubit.state.status, RedeemStatus.success);
      expect(orders.keys[0], orders.keys[1]);
    });

    test('timeout, then edited fields: not sent; the next confirm is a new attempt', () async {
      final orders = _Orders([const AppException(code: AppException.network), _created()]);
      final cubit = await ready(orders);
      await cubit.submit({'playerId': '123'});
      await cubit.submit({'playerId': '999'});
      expect(orders.keys, hasLength(1), reason: 'no request under the old key or a silent new one');
      expect((cubit.state.error! as AppException).code, RedeemCubit.previousAttemptUncertain);
      await cubit.submit({'playerId': '999'});
      expect(orders.keys, hasLength(2));
      expect(orders.keys[1], isNot(orders.keys[0]));
      expect(orders.bodies[1], {'playerId': '999'});
    });

    test('a definite refusal (409 reuse, validation) starts fresh next time', () async {
      final orders = _Orders([
        const AppException(code: 'IDEMPOTENCY_KEY_REUSED', statusCode: 409),
        _created(),
      ]);
      final cubit = await ready(orders);
      await cubit.submit({'playerId': '123'});
      await cubit.submit({'playerId': '123'});
      expect(orders.keys[1], isNot(orders.keys[0]));
    });

    test('REQUEST_IN_PROGRESS keeps the attempt (outcome unknown)', () async {
      final orders = _Orders([
        const AppException(code: 'REQUEST_IN_PROGRESS', statusCode: 409),
        _created(),
      ]);
      final cubit = await ready(orders);
      await cubit.submit({'playerId': '123'});
      await cubit.submit({'playerId': '123'});
      expect(orders.keys[1], orders.keys[0]);
    });

    test('a double tap sends one request', () async {
      final orders = _Orders([_created()]);
      final cubit = await ready(orders);
      await Future.wait([
        cubit.submit({'playerId': '1'}),
        cubit.submit({'playerId': '1'}),
      ]);
      expect(orders.keys, hasLength(1));
    });
  });

  // ------------------------------------------------------------- CR-10 ---
  group('CR-10 bounded ad operations', () {
    testWidgets('a load that never completes times out, retries, and a late ad is released', (
      tester,
    ) async {
      {
        final loader = _HangingLoader();
        final slot = PreloadedAdSlot(
          format: FullscreenAdFormat.interstitial,
          adUnitId: 'unit',
          loader: loader,
          maxAge: const Duration(hours: 1),
          loadTimeout: const Duration(seconds: 30),
          retryDelays: const [Duration(seconds: 10)],
        );
        slot.preload();
        await tester.pump(const Duration(seconds: 31));
        expect(slot.isReady, isFalse);
        final late = _Ad();
        loader.pending.first.complete(late);
        await tester.pump();
        expect(late.disposed, isTrue, reason: 'late ad is not leaked');
        await tester.pump(const Duration(seconds: 11));
        expect(loader.pending, hasLength(2), reason: 'retried');
        loader.pending[1].complete(_Ad());
        await tester.pump();
        expect(slot.isReady, isTrue);
        slot.dispose();
      }
    });

    testWidgets('a dismissal that never arrives releases the gate', (tester) async {
      {
        final gate = FullscreenAdGate();
        final ad = _Ad(hang: true);
        bool? result;
        showGated(gate, ad, timeout: const Duration(minutes: 5)).then((r) => result = r);
        await tester.pump(const Duration(minutes: 1));
        expect(gate.showing, isTrue);
        await tester.pump(const Duration(minutes: 5));
        expect(gate.showing, isFalse);
        expect(ad.disposed, isTrue);
        expect(result, isTrue);
        // The gate is usable again.
        expect(gate.allows(Duration.zero), isTrue);
      }
    });

    test('concurrent fullscreen requests: one shows, the other is refused', () async {
      final gate = FullscreenAdGate();
      final first = _Ad(hang: true);
      final second = _Ad();
      unawaited(showGated(gate, first, timeout: const Duration(milliseconds: 50)));
      expect(await showGated(gate, second), isNull);
      expect(second.disposed, isTrue);
    });

    testWidgets('Join: an ad step that never ends frees the button and does not join', (
      tester,
    ) async {
      {
        final join = GiveawayJoinAds(
          show: ({required String adUnitId}) => Completer<RewardedAdOutcome>().future,
          featureEnabled: true,
          adUnitId: 'unit',
          timeout: const Duration(minutes: 6),
        );
        const giveaway = Giveaway(
          id: 'g',
          title: LocalizedText(en: 'G'),
          status: GiveawayStatus.active,
        );
        JoinAdOutcome? outcome;
        join.watch(giveaway).then((o) => outcome = o);
        await tester.pump(const Duration(minutes: 7));
        expect(outcome, JoinAdOutcome.failed);
        // Not stuck: a new attempt runs.
        JoinAdOutcome? second;
        join.watch(giveaway).then((o) => second = o);
        await tester.pump();
        expect(second, isNull, reason: 'running, not refused');
        await tester.pump(const Duration(minutes: 7));
      }
    });
  });

  // ------------------------------------------------------------- CR-12 ---
  group('CR-12 wallet card', () {
    Future<void> pumpWallet(
      WidgetTester tester, {
      double scale = 1,
      Size size = const Size(411, 914),
    }) async {
      tester.view.physicalSize = size * 2.625;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _localized(
          BlocProvider(
            create: (_) => WalletCubit(_StaticWallet()),
            child: BlocProvider(
              create: (_) => UnreadCountCubit(_StaticUnread()),
              child: BlocProvider(
                create: (_) => SessionCubit(_Auth(restore: () async => _user))..signedIn(_user),
                child: const WalletPage(),
              ),
            ),
          ),
          textScale: scale,
          size: size,
        ),
      );
      await tester.pump();
    }

    testWidgets('normal text: the designed 264 px card', (tester) async {
      await pumpWallet(tester);
      expect(tester.takeException(), isNull);
      final card = find.byWidgetPredicate((w) => w is Container && w.constraints?.minHeight == 264);
      expect(tester.getSize(card).height, 264);
    });

    testWidgets('large text and a small screen: grows instead of overflowing', (tester) async {
      await pumpWallet(tester, scale: 2, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      final card = find.byWidgetPredicate((w) => w is Container && w.constraints?.minHeight == 264);
      expect(tester.getSize(card).height, greaterThan(264));
    });
  });
}

class _StaticWallet implements WalletRepository {
  @override
  Future<Wallet> wallet() async => const Wallet(balance: 1200);

  @override
  Future<CursorPage<WalletTransaction>> transactions({String? cursor}) async =>
      const CursorPage(items: []);
}

class _StaticUnread implements NotificationsRepository {
  @override
  Future<int> unreadCount() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
