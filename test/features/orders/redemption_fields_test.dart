import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/core/utils/cursor_page.dart';
import 'package:rewardsapp/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rewardsapp/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:rewardsapp/features/orders/data/orders_repository_impl.dart';
import 'package:rewardsapp/features/orders/domain/order_entities.dart';
import 'package:rewardsapp/features/orders/presentation/redemption/redeem_cubit.dart';
import 'package:rewardsapp/features/orders/presentation/redemption/redemption_sheet.dart';
import 'package:rewardsapp/features/wallet/domain/wallet_entities.dart';
import 'package:rewardsapp/features/wallet/presentation/bloc/wallet_cubit.dart';

import '../../helpers/fake_api.dart';

/// The PUBG field as the backend defines it (docs: `playerId`, `NUMBER`).
const _playerId = ProductField(
  key: 'playerId',
  label: LocalizedText(en: 'Player ID', ar: 'معرّف اللاعب'),
  type: FieldType.number,
  pattern: r'^[0-9]{5,12}$',
);

Product _product({List<ProductField> fields = const [_playerId]}) => Product(
  id: 'p1',
  categoryId: 'pubg',
  name: const LocalizedText(en: '60 UC', ar: '60 شدة'),
  pointsPrice: 20,
  fields: fields,
);

const _pubg = RewardCategory(
  id: 'pubg',
  kind: CategoryKind.game,
  name: LocalizedText(en: 'PUBG Mobile'),
);

class _Catalog implements CatalogRepository {
  _Catalog(this.item);

  final Product item;

  @override
  Future<Product> product(String id) async => item;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Orders implements OrdersRepository {
  final requests = <Map<String, String>>[];
  final keys = <String>[];
  Object? error;
  Completer<void>? gate;

  @override
  Future<OrderWithBalance> create({
    required String productId,
    required Map<String, String> fields,
    required int expectedPointsPrice,
    required String idempotencyKey,
  }) async {
    requests.add(Map.of(fields));
    keys.add(idempotencyKey);
    await gate?.future;
    if (error != null) throw error!;
    return OrderWithBalance(
      order: parseOrder(Map<String, dynamic>.from(fixture('order_created')['order'] as Map)),
      balance: 80,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Wallet implements WalletRepository {
  @override
  Future<Wallet> wallet() async => const Wallet(balance: 100);

  @override
  Future<CursorPage<WalletTransaction>> transactions({String? cursor}) async =>
      const CursorPage(items: []);
}

Future<_Orders> _pumpSheet(
  WidgetTester tester, {
  Product? product,
  RewardCategory? category = _pubg,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final orders = _Orders();
  final wallet = WalletCubit(_Wallet());
  await wallet.load();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => RedeemCubit(
                _Catalog(product ?? _product()),
                orders,
                productId: 'p1',
                preview: product ?? _product(),
              )..loadProduct(),
            ),
            BlocProvider.value(value: wallet),
          ],
          child: RedemptionSheet(category: category),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return orders;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(RedemptionSheet)));

Finder get _uid => find.byKey(const ValueKey('fulfillment-playerId'));

Future<void> _tapConfirm(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Confirm redemption').last);
  await tester.tap(find.text('Confirm redemption').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PUBG redeem asks for the Player ID with a number keyboard', (tester) async {
    await _pumpSheet(tester);
    expect(_uid, findsOneWidget);
    expect(find.text('Player ID'), findsOneWidget);
    final field = tester.widget<EditableText>(
      find.descendant(of: _uid, matching: find.byType(EditableText)),
    );
    expect(field.keyboardType, TextInputType.number);
  });

  testWidgets('an empty Player ID cannot be submitted', (tester) async {
    final orders = await _pumpSheet(tester);
    await _tapConfirm(tester);
    expect(find.text(_l10n(tester).redeemFieldRequired), findsOneWidget);
    expect(orders.requests, isEmpty);
  });

  testWidgets('an invalid Player ID shows a validation error', (tester) async {
    final orders = await _pumpSheet(tester);
    await tester.enterText(_uid, '12ab');
    await _tapConfirm(tester);
    expect(find.text(_l10n(tester).redeemFieldInvalid('Player ID')), findsOneWidget);
    expect(orders.requests, isEmpty);
  });

  testWidgets('valid ID → review shows product, cost and ID → order carries the ID', (
    tester,
  ) async {
    final orders = await _pumpSheet(tester);
    await tester.enterText(_uid, '  5123456789  ');
    await _tapConfirm(tester);
    expect(orders.requests, isEmpty, reason: 'nothing is sent before the final confirm');
    expect(find.text('Check your details'), findsOneWidget);
    expect(find.textContaining('60 UC for 20 PTS'), findsOneWidget);
    expect(find.textContaining('Player ID: 5123456789'), findsOneWidget, reason: 'trimmed');

    await tester.tap(find.text('Confirm redemption').last);
    await tester.pumpAndSettle();
    expect(orders.requests, [
      {'playerId': '5123456789'},
    ]);
  });

  testWidgets('Edit goes back to the form; the corrected ID is sent', (tester) async {
    final orders = await _pumpSheet(tester);
    await tester.enterText(_uid, '5123456789');
    await _tapConfirm(tester);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(orders.requests, isEmpty, reason: 'leaving the review creates no order');

    await tester.enterText(_uid, '9988776655');
    await _tapConfirm(tester);
    expect(find.textContaining('Player ID: 9988776655'), findsOneWidget);
    await tester.tap(find.text('Confirm redemption').last);
    await tester.pumpAndSettle();
    expect(orders.requests, [
      {'playerId': '9988776655'},
    ]);
  });

  testWidgets('repeated taps create one order', (tester) async {
    final orders = await _pumpSheet(tester);
    orders.gate = Completer<void>();
    await tester.enterText(_uid, '5123456789');
    await _tapConfirm(tester);
    await tester.tap(find.text('Confirm redemption').last);
    await tester.pump();
    // The sheet's button is busy now; more taps do nothing.
    await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
    await tester.pump();
    orders.gate!.complete();
    await tester.pumpAndSettle();
    expect(orders.requests, hasLength(1));
  });

  testWidgets('a server rejection of the ID is shown on the field', (tester) async {
    final orders = await _pumpSheet(tester);
    orders.error = const AppException(
      code: 'VALIDATION_FAILED',
      statusCode: 422,
      details: {
        'fields': {'playerId': 'INVALID_FORMAT'},
      },
    );
    await tester.enterText(_uid, '5123456789');
    await _tapConfirm(tester);
    await tester.tap(find.text('Confirm redemption').last);
    await tester.pumpAndSettle();
    expect(find.text(_l10n(tester).redeemFieldInvalid('Player ID')), findsOneWidget);
  });

  testWidgets('a game product without account fields is not redeemable', (tester) async {
    final orders = await _pumpSheet(tester, product: _product(fields: const []));
    expect(find.byKey(const ValueKey('redeem-account-fields-missing')), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton).last);
    expect(button.onPressed, isNull);
    expect(orders.requests, isEmpty);
  });

  testWidgets('other products without fields keep the direct confirm', (tester) async {
    final orders = await _pumpSheet(
      tester,
      product: _product(fields: const []),
      category: const RewardCategory(
        id: 'phones',
        kind: CategoryKind.physicalGoods,
        name: LocalizedText(en: 'Phones'),
      ),
    );
    expect(find.byKey(const ValueKey('redeem-account-fields-missing')), findsNothing);
    await _tapConfirm(tester);
    expect(find.text('Check your details'), findsNothing);
    expect(orders.requests, [<String, String>{}]);
  });

  testWidgets('Arabic: localized label, review and missing-fields message', (tester) async {
    final orders = await _pumpSheet(tester, locale: const Locale('ar'));
    final l10n = _l10n(tester);
    expect(find.text('معرّف اللاعب'), findsOneWidget);
    await tester.enterText(_uid, '5123456789');
    await tester.ensureVisible(find.text(l10n.redeemConfirm).last);
    await tester.tap(find.text(l10n.redeemConfirm).last);
    await tester.pumpAndSettle();
    expect(find.text('تحقّق من بياناتك'), findsOneWidget);
    expect(find.textContaining('معرّف اللاعب: 5123456789'), findsOneWidget);
    expect(find.text('تعديل'), findsOneWidget);
    expect(orders.requests, isEmpty);
  });
}
