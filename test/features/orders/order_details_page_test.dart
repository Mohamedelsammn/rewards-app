import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewardsapp/app/di/injection_container.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/core/utils/cursor_page.dart';
import 'package:rewardsapp/core/widgets/app_image.dart';
import 'package:rewardsapp/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rewardsapp/features/orders/domain/order_entities.dart';
import 'package:rewardsapp/features/orders/presentation/pages/order_details_page.dart';
import 'package:rewardsapp/features/orders/presentation/pages/orders_page.dart';

final _t0 = DateTime(2026, 10, 22, 3, 34);

Order _order({
  OrderStatus status = OrderStatus.completed,
  List<OrderStatus> history = const [OrderStatus.pending, OrderStatus.completed],
  Map<String, String> fields = const {'playerId': 'samman125'},
  String? reason,
  String? categoryId = 'pubg',
}) => Order(
  id: 'o6',
  orderNumber: 'CR-2026-000006',
  status: status,
  pointsCost: 20,
  productName: const LocalizedText(en: '60 UC', ar: '60 شدة'),
  productImageUrl: 'https://x.test/uc.png',
  categoryId: categoryId,
  categoryName: const LocalizedText(en: 'PUBG Mobile', ar: 'ببجي'),
  categoryKind: CategoryKind.game,
  fieldLabels: const {
    'playerId': LocalizedText(en: 'PUBG Player ID', ar: 'معرّف لاعب ببجي'),
    'profile': LocalizedText(en: 'Profile URL', ar: 'رابط الحساب'),
  },
  fields: fields,
  statusReason: reason,
  timeline: [
    for (final (i, s) in history.indexed)
      OrderTimelineEntry(
        status: s,
        at: _t0.add(Duration(minutes: i)),
        reason: i == history.length - 1 ? reason : null,
      ),
  ],
);

class _Orders implements OrdersRepository {
  _Orders(this.answer);

  Object answer;
  int detailCalls = 0;
  Completer<void>? gate;

  @override
  Future<Order> order(String id) async {
    detailCalls++;
    await gate?.future;
    if (answer is Order) return answer as Order;
    throw answer;
  }

  @override
  Future<CursorPage<Order>> orders({OrderStatusGroup? group, String? cursor}) async =>
      CursorPage(items: [answer as Order]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

String? _clipboard;
String? _pushed;

Future<void> _pump(
  WidgetTester tester,
  _Orders repo, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(411, 914),
  String initial = '/order/o6',
}) async {
  tester.view.physicalSize = size * 2.625;
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await sl.reset();
  sl.registerSingleton<OrdersRepository>(repo);
  _pushed = null;
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/orders', builder: (_, _) => const OrdersPage()),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) {
          _pushed = state.pathParameters['id'];
          return OrderDetailsPage(orderId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/category/:id',
        builder: (_, state) => Scaffold(body: Text('CATEGORY ${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Images never load in tests (their shimmer runs forever), so pump a
/// fixed time instead of pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Finder _status(OrderStatus s) => find.byKey(ValueKey('order-status-${s.name}'));

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
}

void main() {
  setUp(() {
    _clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          _clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
  });

  testWidgets('completed: real data, all recorded milestones checked, Redeem again', (
    tester,
  ) async {
    await _pump(
      tester,
      _Orders(
        _order(
          history: const [
            OrderStatus.pending,
            OrderStatus.processing,
            OrderStatus.shipped,
            OrderStatus.delivered,
            OrderStatus.completed,
          ],
        ),
      ),
    );
    expect(find.text('60 UC'), findsOneWidget);
    expect(find.text('PUBG Mobile'), findsOneWidget);
    expect(find.text('20 PTS'), findsOneWidget);
    expect(_status(OrderStatus.completed), findsOneWidget);
    expect(find.text('#CR-2026-000006'), findsOneWidget);
    await _scrollTo(tester, find.text('Pending'));
    for (final label in ['Completed', 'Delivered', 'Shipped', 'Processing', 'Pending']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.byKey(const ValueKey('timeline-current')), findsNothing, reason: 'all done');
    expect(find.text('Oct 22, 2026 03:34'), findsOneWidget, reason: 'server timestamps');
    expect(find.byKey(const ValueKey('order-redeem-again')), findsOneWidget);
    expect(find.byKey(const ValueKey('order-cancel')), findsNothing);
  });

  testWidgets('pending: only Pending recorded, shown as current; Cancel instead', (tester) async {
    await _pump(
      tester,
      _Orders(_order(status: OrderStatus.pending, history: const [OrderStatus.pending])),
    );
    expect(_status(OrderStatus.pending), findsOneWidget);
    await _scrollTo(tester, find.byKey(const ValueKey('timeline-current')));
    for (final label in ['Processing', 'Shipped', 'Delivered', 'Completed']) {
      expect(find.text(label), findsNothing, reason: 'no fabricated $label');
    }
    expect(find.byKey(const ValueKey('order-cancel')), findsOneWidget);
    expect(find.byKey(const ValueKey('order-redeem-again')), findsNothing);
  });

  for (final status in [OrderStatus.processing, OrderStatus.shipped, OrderStatus.delivered]) {
    testWidgets('${status.name}: earlier steps done, ${status.name} current', (tester) async {
      final history = [
        OrderStatus.pending,
        if (status != OrderStatus.processing) OrderStatus.processing,
        if (status == OrderStatus.delivered) OrderStatus.shipped,
        status,
      ];
      await _pump(tester, _Orders(_order(status: status, history: history)));
      expect(_status(status), findsOneWidget);
      await _scrollTo(tester, find.byKey(const ValueKey('timeline-current')));
      expect(find.byKey(const ValueKey('timeline-current')), findsOneWidget);
      expect(find.text('Completed'), findsNothing);
    });
  }

  for (final status in [OrderStatus.cancelled, OrderStatus.rejected, OrderStatus.failed]) {
    testWidgets('${status.name}: red terminal step, refund note, real reason', (tester) async {
      await _pump(
        tester,
        _Orders(
          _order(
            status: status,
            history: [OrderStatus.pending, status],
            reason: 'Out of stock at supplier',
          ),
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(OrderDetailsPage)));
      expect(_status(status), findsOneWidget);
      expect(find.text(l10n.orderRefunded('20')), findsOneWidget);
      await _scrollTo(tester, find.textContaining('Out of stock at supplier'));
      expect(find.text('Completed'), findsNothing);
      expect(find.text('Delivered'), findsNothing);
      expect(find.byKey(const ValueKey('timeline-current')), findsNothing);
    });
  }

  testWidgets('no recorded history: the current status only, no invented time', (tester) async {
    final order = _order(status: OrderStatus.processing, history: const []);
    await _pump(tester, _Orders(order));
    await _scrollTo(tester, find.byKey(const ValueKey('order-status-history')));
    expect(find.textContaining('2026 0'), findsNothing, reason: 'no timestamps');
    expect(find.byKey(const ValueKey('timeline-current')), findsOneWidget);
  });

  testWidgets('account details: every field with its label; copy and open link', (tester) async {
    await _pump(
      tester,
      _Orders(_order(fields: const {'playerId': 'samman125', 'profile': 'https://x.com/samman'})),
    );
    expect(find.text('PUBG Player ID'), findsOneWidget);
    expect(find.text('samman125'), findsOneWidget);
    expect(find.text('Profile URL'), findsOneWidget);
    expect(find.text('https://x.com/samman'), findsOneWidget);
    expect(find.byTooltip('Open link'), findsOneWidget, reason: 'only the URL field');

    final copyButtons = find.descendant(
      of: find.byKey(const ValueKey('order-account-details')),
      matching: find.byTooltip('Copy'),
    );
    await tester.tap(copyButtons.first);
    await tester.pump();
    expect(_clipboard, 'samman125');
  });

  testWidgets('no submitted fields: no empty Account details card', (tester) async {
    await _pump(tester, _Orders(_order(fields: const {})));
    expect(find.byKey(const ValueKey('order-account-details')), findsNothing);
  });

  testWidgets('copy Order ID copies the real number', (tester) async {
    await _pump(tester, _Orders(_order()));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('order-id-card')),
        matching: find.byTooltip('Copy'),
      ),
    );
    await tester.pump();
    expect(_clipboard, 'CR-2026-000006');
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('Redeem again opens the product category (no order is created)', (tester) async {
    final repo = _Orders(_order());
    await _pump(tester, repo);
    await tester.tap(find.byKey(const ValueKey('order-redeem-again')));
    await _settle(tester);
    expect(find.text('CATEGORY pubg'), findsOneWidget);
  });

  testWidgets('Arabic: right-to-left, localized labels, Latin IDs kept LTR', (tester) async {
    await _pump(tester, _Orders(_order()), locale: const Locale('ar'));
    final l10n = AppLocalizations.of(tester.element(find.byType(OrderDetailsPage)));
    expect(find.text(l10n.orderIdLabel), findsOneWidget);
    expect(find.text('معرّف لاعب ببجي'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(l10n.orderIdLabel))), TextDirection.rtl);
    final id = tester.widget<SelectableText>(
      find.widgetWithText(SelectableText, '#CR-2026-000006'),
    );
    expect(id.textDirection, TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text on a small screen: no overflow', (tester) async {
    await _pump(
      tester,
      _Orders(
        _order(
          fields: const {'playerId': 'samman125', 'profile': 'https://x.com/a-very-long-handle'},
          history: const [OrderStatus.pending, OrderStatus.processing, OrderStatus.completed],
        ),
      ),
      textScale: 2,
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    await _scrollTo(tester, find.byKey(const ValueKey('order-status-history')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading skeleton, then an error with Retry', (tester) async {
    final repo = _Orders(const AppException(code: AppException.network))..gate = Completer<void>();
    await _pump(tester, repo);
    expect(find.byKey(const ValueKey('order-details-skeleton')), findsOneWidget);
    repo.gate!.complete();
    await _settle(tester);
    expect(find.byKey(const ValueKey('order-details-skeleton')), findsNothing);
    final l10n = AppLocalizations.of(tester.element(find.byType(OrderDetailsPage)));
    expect(find.text(l10n.commonRetry), findsOneWidget);
    repo
      ..gate = null
      ..answer = _order();
    await tester.tap(find.text(l10n.commonRetry));
    await _settle(tester);
    expect(find.text('#CR-2026-000006'), findsOneWidget);
  });

  testWidgets('My Orders: real data, image fills its square, opens the right order', (
    tester,
  ) async {
    await _pump(tester, _Orders(_order()), initial: '/orders');
    await _settle(tester);
    expect(find.text('60 UC'), findsOneWidget);
    expect(find.text('20 PTS'), findsOneWidget);
    final image = tester.widget<AppImage>(find.byType(AppImage).first);
    expect(image.fit, BoxFit.cover);
    expect(tester.getSize(find.byType(AppImage).first), const Size(78, 78));
    await tester.tap(find.text('60 UC'));
    await _settle(tester);
    expect(_pushed, 'o6');
    expect(find.byType(OrderDetailsPage), findsOneWidget);
  });
}
