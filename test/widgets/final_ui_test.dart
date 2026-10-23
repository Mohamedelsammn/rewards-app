import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/app/di/injection_container.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/core/utils/cursor_page.dart';
import 'package:rewardsapp/core/utils/paged_list_state.dart';
import 'package:rewardsapp/core/widgets/app_image.dart';
import 'package:rewardsapp/core/widgets/paged_list_view.dart';
import 'package:rewardsapp/core/widgets/skeleton.dart';
import 'package:rewardsapp/features/auth/domain/entities/app_user.dart';
import 'package:rewardsapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardsapp/features/auth/presentation/bloc/session_cubit.dart';
import 'package:rewardsapp/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rewardsapp/features/catalog/presentation/widgets/category_visuals.dart';
import 'package:rewardsapp/features/giveaways/domain/entities/giveaway_entities.dart';
import 'package:rewardsapp/features/giveaways/domain/repositories/giveaways_repository.dart';
import 'package:rewardsapp/features/giveaways/presentation/giveaway_rules.dart';
import 'package:rewardsapp/features/giveaways/presentation/pages/giveaway_details_page.dart';
import 'package:rewardsapp/features/giveaways/presentation/widgets/giveaway_visuals.dart';
import 'package:rewardsapp/features/wallet/domain/wallet_entities.dart';
import 'package:rewardsapp/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:rewardsapp/features/wallet/presentation/widgets/insufficient_points_dialog.dart';
import 'package:rewardsapp/features/wallet/presentation/widgets/wallet_balance_text.dart';

Widget _app(Widget child, {Locale locale = const Locale('en'), WalletCubit? wallet}) {
  final app = MaterialApp(
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
  );
  return wallet == null ? app : BlocProvider<WalletCubit>.value(value: wallet, child: app);
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

const _rules =
    'Participants must have an active account. One entry is allowed per account. The winner '
    'will be selected randomly after the giveaway ends and must claim within 14 days. This is '
    'a test giveaway; no physical prize will be awarded.';

Giveaway _giveaway({GiveawayStatus status = GiveawayStatus.active, String? imageUrl}) => Giveaway(
  id: 'g1',
  title: const LocalizedText(en: 'Win an iPhone 15 Pro', ar: 'اربح آيفون 15 برو'),
  description: const LocalizedText(en: 'Join for free.', ar: 'شارك مجانًا.'),
  prize: const LocalizedText(en: 'iPhone 15 Pro – 256GB', ar: 'آيفون 15 برو'),
  rules: const LocalizedText(en: _rules, ar: 'القاعدة الأولى. القاعدة الثانية.'),
  organizer: 'Creative Hub',
  status: status,
  imageUrl: imageUrl,
  endsAt: DateTime(2026, 10, 24),
);

class _Giveaways implements GiveawaysRepository {
  _Giveaways(this.current);

  GiveawayDetails current;
  final completers = <Completer<GiveawayDetails>>[];
  bool hold = false;

  @override
  Future<GiveawayDetails> details(String id) {
    if (!hold) return Future.value(current);
    final completer = Completer<GiveawayDetails>();
    completers.add(completer);
    return completer.future;
  }

  @override
  Future<List<GiveawayWinner>?> results(String giveawayId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Wallet implements WalletRepository {
  _Wallet({this.balance = 0});

  final int balance;

  @override
  Future<Wallet> wallet() async => Wallet(balance: balance);

  @override
  Future<CursorPage<WalletTransaction>> transactions({String? cursor}) async =>
      const CursorPage(items: []);
}

class _Auth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

AppUser _user({int points = 0}) => AppUser(
  id: 'u1',
  email: 'a@b.co',
  name: 'A',
  language: 'en',
  status: 'ACTIVE',
  stats: UserStats(points: points),
);

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2400);
    view.devicePixelRatio = 2.625;
    addTearDown(view.reset);
  });

  group('rules', () {
    test('a paragraph is split into sentences without losing text', () {
      final rules = splitGiveawayRules(_rules);
      expect(rules, hasLength(4));
      expect(rules.join(' '), _rules);
    });

    test('lines and list markers', () {
      expect(splitGiveawayRules('1. First\n2) Second\n- Third\n\n• Fourth'), [
        'First',
        'Second',
        'Third',
        'Fourth',
      ]);
      expect(splitGiveawayRules('القاعدة الأولى. القاعدة الثانية؟ الأخيرة'), hasLength(3));
      expect(splitGiveawayRules('   '), isEmpty);
    });
  });

  group('Insufficient points dialog', () {
    testWidgets('shows balance, price and shortfall; Got it closes it', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showInsufficientPointsDialog(context, balance: 200, required: 1200),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = _l10n(tester);

      expect(find.text(l10n.redeemInsufficientTitleCaps), findsOneWidget);
      expect(find.text(l10n.pointsAmount('200')), findsOneWidget);
      expect(find.text(l10n.pointsAmount('1,200')), findsOneWidget);
      expect(find.text(l10n.pointsAmount('1,000')), findsOneWidget, reason: 'missing points');
      expect(find.text(l10n.redeemEarnPoints), findsNothing, reason: 'no earn destination given');

      await tester.tap(find.text(l10n.commonGotIt));
      await tester.pumpAndSettle();
      expect(find.byType(InsufficientPointsDialog), findsNothing);
    });

    testWidgets('offers Earn points only when a destination is passed (Arabic)', (tester) async {
      var earned = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showInsufficientPointsDialog(
                  context,
                  balance: 0,
                  required: 1200,
                  onEarnPoints: () => earned++,
                ),
                child: const Text('open'),
              ),
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = _l10n(tester);
      expect(
        Directionality.of(tester.element(find.byType(InsufficientPointsDialog))),
        TextDirection.rtl,
      );
      await tester.tap(find.text(l10n.redeemEarnPoints));
      await tester.pumpAndSettle();
      expect(earned, 1);
      expect(find.byType(InsufficientPointsDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Images never fall back to bundled product art', () {
    testWidgets('a giveaway card without an image shows the neutral placeholder', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SizedBox(
              width: 180,
              height: 243,
              child: GiveawayCard(giveaway: _giveaway(), index: 0, onTap: () {}),
            ),
          ),
        ),
      );
      expect(find.text('Win an iPhone 15 Pro'), findsOneWidget);
      expect(find.byKey(const ValueKey('image-placeholder')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage), findsNothing);
    });

    testWidgets('categories and products without images show no asset art', (tester) async {
      const category = RewardCategory(
        id: 'c1',
        name: LocalizedText(en: 'PUBG Mobile'),
        kind: CategoryKind.game,
      );
      const product = Product(
        id: 'p1',
        categoryId: 'c1',
        name: LocalizedText(en: '60 UC'),
        pointsPrice: 1200,
      );
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: Column(
              children: [
                CategoryBanner(category: category, height: 102),
                SizedBox(
                  height: 93,
                  child: ProductArt(product: product, category: category),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage), findsNothing);
      expect(find.text('PUBG Mobile'), findsOneWidget);
    });

    testWidgets('a loading network image shows a shimmer, not a picture', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: SizedBox(width: 100, height: 100, child: AppImage(url: 'https://x.test/a.png')),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage), findsNothing);
    });
  });

  group('Giveaway Details', () {
    late _Giveaways repository;

    setUp(() async {
      await sl.reset();
      repository = _Giveaways(GiveawayDetails(giveaway: _giveaway()));
      sl.registerSingleton<GiveawaysRepository>(repository);
    });

    testWidgets('skeleton while loading, then the reference sections without Prize', (
      tester,
    ) async {
      repository.hold = true;
      await tester.pumpWidget(_app(const GiveawayDetailsPage(giveawayId: 'g1')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('giveaway-details-skeleton')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      repository.completers.single.complete(GiveawayDetails(giveaway: _giveaway()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final l10n = _l10n(tester);

      expect(find.text('Win an iPhone 15 Pro'), findsOneWidget);
      expect(find.text(l10n.giveawayBadge), findsOneWidget);
      expect(find.byKey(const ValueKey('giveaway-about')), findsOneWidget);
      expect(find.text('Join for free.'), findsOneWidget);
      expect(find.byKey(const ValueKey('giveaway-rules')), findsOneWidget);
      for (final n in ['1', '2', '3', '4']) {
        expect(find.text(n), findsOneWidget);
      }
      // The Prize section is not shown (data stays in the model).
      expect(find.text(l10n.giveawayPrize), findsNothing);
      expect(find.text('iPhone 15 Pro – 256GB'), findsNothing);
      expect(find.text(l10n.giveawayJoin), findsOneWidget);
    });

    testWidgets('CTA follows the backend state', (tester) async {
      repository.current = GiveawayDetails(
        giveaway: _giveaway(),
        entry: const GiveawayEntry(
          id: 'e1',
          giveawayId: 'g1',
          participationNumber: '424869',
          active: true,
        ),
      );
      await tester.pumpWidget(_app(const GiveawayDetailsPage(giveawayId: 'g1')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(_l10n(tester).giveawayViewTicket), findsOneWidget);

      repository.current = GiveawayDetails(giveaway: _giveaway(status: GiveawayStatus.upcoming));
      await tester.pumpWidget(_app(const GiveawayDetailsPage(giveawayId: 'g2', key: ValueKey(2))));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(_l10n(tester).giveawayUpcoming), findsWidgets);

      repository.current = GiveawayDetails(giveaway: _giveaway(status: GiveawayStatus.ended));
      await tester.pumpWidget(_app(const GiveawayDetailsPage(giveawayId: 'g3', key: ValueKey(3))));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(_l10n(tester).giveawayClosed), findsOneWidget);
    });

    testWidgets('renders right-to-left in Arabic without errors', (tester) async {
      await tester.pumpWidget(
        _app(const GiveawayDetailsPage(giveawayId: 'g1'), locale: const Locale('ar')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('اربح آيفون 15 برو'), findsOneWidget);
      expect(find.text('القاعدة الأولى.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Lists and balance', () {
    PagedListView<String, void> list(PagedListState<String, void> state) => PagedListView(
      state: state,
      itemBuilder: (_, item) => Text(item),
      onRefresh: () async {},
      onLoadMore: () {},
      emptyMessage: 'empty',
      skeletonRow: const SkeletonRow(),
    );

    testWidgets('first load shows the screen skeleton', (tester) async {
      await tester.pumpWidget(_app(Scaffold(body: list(const PagedListState(filter: null)))));
      await tester.pump();
      expect(find.byKey(const ValueKey('list-skeleton')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failed refresh keeps items and shows a banner', (tester) async {
      const state = PagedListState<String, void>(
        filter: null,
        status: PagedStatus.failed,
        items: ['Order A', 'Order B'],
        error: AppException(code: AppException.network),
      );
      await tester.pumpWidget(_app(Scaffold(body: list(state))));
      expect(find.text('Order A'), findsOneWidget);
      expect(find.byKey(const ValueKey('refresh-error')), findsOneWidget);
    });

    Widget balanceApp(WalletCubit wallet, SessionCubit session) => _app(
      BlocProvider<SessionCubit>.value(
        value: session,
        // Like the Home header: a scale-down FittedBox around the row.
        child: const Scaffold(
          body: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                WalletBalanceText(style: TextStyle(fontSize: 69)),
                SizedBox(width: 12),
                Text('PTS', style: TextStyle(fontSize: 27)),
              ],
            ),
          ),
        ),
      ),
      wallet: wallet,
    );

    testWidgets('balance from /me shows at once, before /wallet answers', (tester) async {
      final wallet = WalletCubit(_Wallet(balance: 950));
      final session = SessionCubit(_Auth())..signedIn(_user(points: 1200));
      await tester.pumpWidget(balanceApp(wallet, session));
      expect(find.text('1,200'), findsOneWidget);
      expect(find.byKey(const ValueKey('balance-skeleton')), findsNothing);

      await wallet.load();
      await tester.pumpAndSettle();
      expect(find.text('950'), findsOneWidget, reason: '/wallet is the source of truth');
    });

    testWidgets('unknown balance: inline placeholder sized like the digits, never a 0', (
      tester,
    ) async {
      final wallet = WalletCubit(_Wallet());
      final session = SessionCubit(_Auth());
      await tester.pumpWidget(balanceApp(wallet, session));
      final placeholder = find.byKey(const ValueKey('balance-skeleton'));
      expect(placeholder, findsOneWidget);
      expect(find.text('0'), findsNothing);
      // Same box as the real digits; PTS stays beside it, not covered.
      final box = tester.getRect(placeholder);
      final pts = tester.getRect(find.text('PTS'));
      expect(box.right, lessThanOrEqualTo(pts.left));
      expect(box.height, lessThan(120));

      await wallet.load();
      await tester.pumpAndSettle();
      expect(placeholder, findsNothing);
      expect(find.text('0'), findsOneWidget);
    });
  });
}
