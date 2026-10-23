import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/app/di/injection_container.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/core/widgets/app_image.dart';
import 'package:rewardsapp/features/catalog/data/catalog_models.dart';
import 'package:rewardsapp/features/catalog/data/catalog_repository_impl.dart';
import 'package:rewardsapp/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rewardsapp/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:rewardsapp/features/catalog/presentation/bloc/catalog_cubits.dart';
import 'package:rewardsapp/features/catalog/presentation/pages/category_details_page.dart';
import 'package:rewardsapp/features/catalog/presentation/widgets/category_visuals.dart';

import '../../helpers/fake_api.dart';

/// docs/FLUTTER_INTEGRATION-6.md §5b: home vs banner images, product types.
const _pubgJson = {
  'id': 'g1',
  'kind': 'GAME',
  'name': {'ar': 'ببجي موبايل', 'en': 'PUBG Mobile'},
  'description': {'ar': '', 'en': ''},
  'imageUrl': 'https://x.test/pubg-home.webp',
  'homeImageUrl': 'https://x.test/pubg-home.webp',
  'bannerImageUrl': 'https://x.test/pubg-banner.webp',
  'sortOrder': 0,
};

Product _product(String id, String name, ProductType? type, {String category = 'g1'}) => Product(
  id: id,
  categoryId: category,
  name: LocalizedText(en: name, ar: name),
  pointsPrice: 1200,
  productType: type,
);

RewardCategory _category({
  CategoryKind kind = CategoryKind.game,
  String? banner,
  List<ProductGroup> groups = const [],
}) => RewardCategory(
  id: 'g1',
  kind: kind,
  name: const LocalizedText(en: 'PUBG Mobile', ar: 'ببجي موبايل'),
  homeImageUrl: 'https://x.test/pubg-home.webp',
  bannerImageUrl: banner,
  groups: groups,
);

/// Answers products per (groupId, productType) and records every call.
class _Catalog implements CatalogRepository {
  _Catalog(this.detail, this.lists);

  RewardCategory detail;
  Map<ProductType?, List<Product>> lists;
  final calls = <(String?, ProductType?)>[];
  int categoryCalls = 0;

  /// When set, `GET /categories/:id` waits for it.
  Completer<void>? gate;
  bool fail = false;

  @override
  Future<RewardCategory> category(String id) async {
    categoryCalls++;
    await gate?.future;
    if (fail) throw StateError('offline');
    return detail;
  }

  @override
  Future<List<Product>> products(
    String categoryId, {
    String? groupId,
    ProductType? productType,
  }) async {
    calls.add((groupId, productType));
    return lists[productType] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

extension on CategoryDetailsCubit {
  List<String> get visibleIds => [for (final p in state.visibleProducts) p.id];
}

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
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

void main() {
  group('decoding', () {
    test('category keeps the home image and the banner apart', () {
      final category = CatalogModels.category(Map.of(_pubgJson));
      expect(category.homeImageUrl, 'https://x.test/pubg-home.webp');
      expect(category.bannerImageUrl, 'https://x.test/pubg-banner.webp');
      expect(category.isGame, isTrue);
    });

    test('null images stay null; the banner never falls back to the home image', () {
      final category = CatalogModels.category({
        ..._pubgJson,
        'homeImageUrl': null,
        'imageUrl': null,
        'bannerImageUrl': null,
      });
      expect(category.homeImageUrl, isNull);
      expect(category.bannerImageUrl, isNull);

      final noBanner = CatalogModels.category({..._pubgJson, 'bannerImageUrl': null});
      expect(noBanner.homeImageUrl, isNotNull);
      expect(noBanner.bannerImageUrl, isNull);
    });

    test('legacy imageUrl still decodes as the home image', () {
      final json = Map<String, dynamic>.of(_pubgJson)
        ..remove('homeImageUrl')
        ..remove('bannerImageUrl');
      final category = CatalogModels.category(json);
      expect(category.homeImageUrl, 'https://x.test/pubg-home.webp');
      expect(category.bannerImageUrl, isNull);
    });

    test('product type: TOP_UP, ITEM_SKIN, null and unknown', () {
      Product decode(Object? type) => CatalogModels.product({
        'id': 'p',
        'categoryId': 'g1',
        'name': {'en': '60 UC'},
        'pointsPrice': 90,
        'productType': type,
      });
      expect(decode('TOP_UP').productType, ProductType.topUp);
      expect(decode('ITEM_SKIN').productType, ProductType.itemSkin);
      expect(decode(null).productType, isNull);
      expect(decode('OTHER').productType, isNull);
      expect(decode('TOP_UP').pointsPrice, 90);
    });
  });

  test('repository sends productType (and groupId) as query parameters', () async {
    final api = FakeApi(
      (_) => const FakeResponse(200, {
        'items': [
          {
            'id': 'p1',
            'categoryId': 'g1',
            'name': {'en': '60 UC'},
            'pointsPrice': 90,
            'productType': 'TOP_UP',
          },
        ],
      }),
    );
    final repository = CatalogRepositoryImpl(api.client);
    final topUps = await repository.products('g1', productType: ProductType.topUp);
    await repository.products('g1', groupId: 'grp', productType: ProductType.itemSkin);
    await repository.products('g1');

    expect(topUps.single.productType, ProductType.topUp);
    final queries = [for (final r in api.adapter.requests) r.queryParameters];
    expect(api.adapter.requests.first.path, '/categories/g1/products');
    expect(queries[0], {'productType': 'TOP_UP'});
    expect(queries[1], {'groupId': 'grp', 'productType': 'ITEM_SKIN'});
    expect(queries[2], isEmpty);
  });

  group('CategoryDetailsCubit', () {
    test('a game loads both tabs from the server, untyped products in neither', () async {
      final catalog = _Catalog(_category(), {
        ProductType.topUp: [_product('t1', '60 UC', ProductType.topUp)],
        ProductType.itemSkin: [_product('s1', 'Pharaoh X-Suit', ProductType.itemSkin)],
        null: [_product('l1', 'Legacy', null)],
      });
      final cubit = CategoryDetailsCubit(catalog, categoryId: 'g1');
      await cubit.load();

      expect(
        catalog.calls,
        unorderedEquals([(null, ProductType.topUp), (null, ProductType.itemSkin)]),
      );
      expect(cubit.state.productType, ProductType.topUp);
      expect(cubit.state.visibleProducts.map((p) => p.id), ['t1']);

      cubit.selectProductType(ProductType.itemSkin);
      expect(cubit.state.visibleProducts.map((p) => p.id), ['s1']);
      expect(catalog.calls, hasLength(2), reason: 'switching tabs needs no request');

      // A refresh keeps the selected tab.
      await cubit.load();
      expect(cubit.state.productType, ProductType.itemSkin);
      await cubit.close();
    });

    test('groups and product types are combined', () async {
      const groups = [
        ProductGroup(
          id: 'a',
          name: LocalizedText(en: 'A'),
        ),
        ProductGroup(
          id: 'b',
          name: LocalizedText(en: 'B'),
        ),
      ];
      final catalog = _Catalog(_category(groups: groups), const {});
      final cubit = CategoryDetailsCubit(catalog, categoryId: 'g1');
      await cubit.load();
      await cubit.selectGroup('b');
      expect(catalog.calls, [
        ('a', ProductType.topUp),
        ('a', ProductType.itemSkin),
        ('b', ProductType.topUp),
        ('b', ProductType.itemSkin),
      ]);
      await cubit.close();
    });

    test('non-game categories keep the single unfiltered list', () async {
      final catalog = _Catalog(_category(kind: CategoryKind.physicalGoods), {
        null: [_product('x', 'Phone', null)],
      });
      final cubit = CategoryDetailsCubit(catalog, categoryId: 'g1');
      await cubit.load();
      expect(catalog.calls, [(null, null)]);
      expect(cubit.state.productType, isNull);
      expect(cubit.state.visibleProducts.map((p) => p.id), ['x']);
      await cubit.close();
    });
  });

  group('Category Details page', () {
    setUp(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 2.625;
      addTearDown(view.reset);
    });

    Future<void> pumpPage(
      WidgetTester tester,
      _Catalog catalog, {
      Locale locale = const Locale('en'),
    }) async {
      await sl.reset();
      sl
        ..registerSingleton<CatalogRepository>(catalog)
        ..registerSingleton<CategorySnapshots>(CategorySnapshots());
      await tester.pumpWidget(_app(const CategoryDetailsPage(categoryId: 'g1'), locale: locale));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('two tabs with independent lists and a per-tab empty state', (tester) async {
      final catalog = _Catalog(_category(), {
        ProductType.topUp: [
          _product('t1', '60 UC', ProductType.topUp),
          _product('t2', '180 UC', ProductType.topUp),
        ],
        null: [_product('l1', 'Legacy', null)],
      });
      await pumpPage(tester, catalog);
      final l10n = AppLocalizations.of(tester.element(find.byType(CategoryDetailsPage)));

      expect(find.byKey(const ValueKey('product-type-tabs')), findsOneWidget);
      expect(find.text('UC Top-Ups'), findsOneWidget);
      expect(find.text('Items & Skins'), findsOneWidget);
      expect(find.text('60 UC'), findsOneWidget);
      expect(find.text('180 UC'), findsOneWidget);
      expect(find.text('Legacy'), findsNothing);

      await tester.tap(find.text('Items & Skins'));
      await tester.pump();
      expect(find.text('60 UC'), findsNothing);
      expect(find.text(l10n.productItemsSkinsEmpty), findsOneWidget);

      await tester.tap(find.text('UC Top-Ups'));
      await tester.pump();
      expect(find.text('60 UC'), findsOneWidget);
    });

    testWidgets('hero shows the banner, never the home image', (tester) async {
      await pumpPage(tester, _Catalog(_category(banner: 'https://x.test/pubg-banner.webp'), {}));
      final urls = [
        for (final image in tester.widgetList<AppImage>(find.byType(AppImage))) image.url,
      ];
      expect(urls, contains('https://x.test/pubg-banner.webp'));
      expect(urls, isNot(contains('https://x.test/pubg-home.webp')));
      expect(find.byKey(const ValueKey('category-banner-placeholder')), findsNothing);
    });

    testWidgets('without a banner the hero is a branded placeholder', (tester) async {
      await pumpPage(tester, _Catalog(_category(), {}));
      expect(find.byKey(const ValueKey('category-banner-placeholder')), findsOneWidget);
      expect(
        tester.widgetList<AppImage>(find.byType(AppImage)).where((i) => i.url != null),
        isEmpty,
      );
    });

    testWidgets('non-game categories have no product-type tabs', (tester) async {
      await pumpPage(
        tester,
        _Catalog(_category(kind: CategoryKind.physicalGoods), {
          null: [_product('x', 'Phone', null)],
        }),
      );
      expect(find.byKey(const ValueKey('product-type-tabs')), findsNothing);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('Arabic: localized tabs, right-to-left', (tester) async {
      await pumpPage(
        tester,
        _Catalog(_category(), {
          ProductType.topUp: [_product('t1', '60 UC', ProductType.topUp)],
        }),
        locale: const Locale('ar'),
      );
      final topUps = find.text('شحن الشدات');
      final items = find.text('العناصر والسكنات');
      expect(topUps, findsOneWidget);
      expect(items, findsOneWidget);
      // First tab on the right in RTL.
      expect(tester.getCenter(topUps).dx, greaterThan(tester.getCenter(items).dx));
      await tester.tap(items);
      await tester.pump();
      expect(find.text('لا توجد عناصر أو سكنات متاحة بعد.'), findsOneWidget);
    });
  });

  group('reopening and refreshing', () {
    final topUps = {
      ProductType.topUp: [_product('t1', '60 UC', ProductType.topUp)],
    };

    test('a fresh snapshot reopens instantly without requests', () async {
      final catalog = _Catalog(_category(), topUps);
      final snapshots = CategorySnapshots();
      final first = CategoryDetailsCubit(catalog, categoryId: 'g1', snapshots: snapshots);
      await first.open();
      first.selectProductType(ProductType.itemSkin);
      await first.close();
      final requests = catalog.calls.length + catalog.categoryCalls;

      final second = CategoryDetailsCubit(catalog, categoryId: 'g1', snapshots: snapshots);
      expect(second.state.status, LoadStatus.ready);
      expect(second.state.typedProducts[ProductType.topUp]!.single.id, 't1');
      expect(second.state.productType, ProductType.itemSkin, reason: 'keeps the last tab');
      await second.open();
      expect(catalog.calls.length + catalog.categoryCalls, requests);
      await second.close();
    });

    test('a stale snapshot shows at once and refreshes silently', () async {
      var now = DateTime(2026);
      final snapshots = CategorySnapshots(clock: () => now);
      final catalog = _Catalog(_category(), topUps);
      final first = CategoryDetailsCubit(catalog, categoryId: 'g1', snapshots: snapshots);
      await first.open();
      await first.close();

      now = now.add(const Duration(minutes: 5));
      catalog.lists = {
        ProductType.topUp: [_product('t2', '180 UC', ProductType.topUp)],
      };
      final second = CategoryDetailsCubit(catalog, categoryId: 'g1', snapshots: snapshots);
      final statuses = <LoadStatus>[];
      final sub = second.stream.listen((s) => statuses.add(s.status));
      await second.open();
      expect(statuses, isNot(contains(LoadStatus.loading)), reason: 'no skeleton');
      expect(second.visibleIds, ['t2']);
      await sub.cancel();
      await second.close();
    });

    test('a failed refresh keeps the products and reports the error', () async {
      final catalog = _Catalog(_category(), topUps);
      final cubit = CategoryDetailsCubit(catalog, categoryId: 'g1');
      await cubit.load();
      catalog.fail = true;
      await cubit.load();
      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.error, isNotNull);
      expect(cubit.visibleIds, ['t1']);
      await cubit.close();
    });

    test('leaving before the server answers does not emit after close', () async {
      final catalog = _Catalog(_category(), topUps)..gate = Completer<void>();
      final cubit = CategoryDetailsCubit(catalog, categoryId: 'g1');
      final loading = cubit.load();
      await cubit.close();
      catalog.gate!.complete();
      await expectLater(loading, completes);
    });

    test('with a known game, products are requested alongside the category', () async {
      final catalog = _Catalog(_category(), topUps)..gate = Completer<void>();
      final cubit = CategoryDetailsCubit(catalog, categoryId: 'g1', preview: _category());
      final loading = cubit.load();
      await Future<void>.delayed(Duration.zero);
      expect(catalog.categoryCalls, 1);
      expect(catalog.calls, hasLength(2), reason: 'both tabs already requested');
      catalog.gate!.complete();
      await loading;
      expect(catalog.calls, hasLength(2), reason: 'no second round trip');
      expect(cubit.visibleIds, ['t1']);
      await cubit.close();
    });

    test('a wrong guess (the category has groups) refetches with the group', () async {
      const groups = [
        ProductGroup(
          id: 'a',
          name: LocalizedText(en: 'A'),
        ),
        ProductGroup(
          id: 'b',
          name: LocalizedText(en: 'B'),
        ),
      ];
      final catalog = _Catalog(_category(groups: groups), topUps);
      final cubit = CategoryDetailsCubit(catalog, categoryId: 'g1', preview: _category());
      await cubit.load();
      expect(cubit.state.groupId, 'a');
      expect(catalog.calls.sublist(2), [('a', ProductType.topUp), ('a', ProductType.itemSkin)]);
      await cubit.close();
    });

    testWidgets('pull-to-refresh failure keeps the grid and shows the banner', (tester) async {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 2.625;
      addTearDown(view.reset);
      final catalog = _Catalog(_category(banner: 'https://x.test/b.webp'), topUps);
      await sl.reset();
      sl
        ..registerSingleton<CatalogRepository>(catalog)
        ..registerSingleton<CategorySnapshots>(CategorySnapshots());
      await tester.pumpWidget(_app(const CategoryDetailsPage(categoryId: 'g1')));
      await tester.pump();
      await tester.pump();
      expect(find.text('60 UC'), findsOneWidget);
      // The banner is decoded at the screen's physical width.
      final banner = tester
          .widgetList<AppImage>(find.byType(AppImage))
          .firstWhere((i) => i.url == 'https://x.test/b.webp');
      expect(banner.cacheWidth, 1080);

      catalog.fail = true;
      await tester.element(find.byType(CustomScrollView)).read<CategoryDetailsCubit>().load();
      await tester.pump();
      expect(find.text('60 UC'), findsOneWidget);
      expect(find.byKey(const ValueKey('refresh-error')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-grid-skeleton')), findsNothing);
    });
  });

  testWidgets('Home tile and category banner use the home image', (tester) async {
    final category = _category(banner: 'https://x.test/pubg-banner.webp');
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Column(
            children: [
              CategoryTile(category: category, onTap: () {}),
              CategoryBanner(category: category, height: 102),
            ],
          ),
        ),
      ),
    );
    final urls = [
      for (final image in tester.widgetList<AppImage>(find.byType(AppImage))) image.url,
    ];
    expect(urls, ['https://x.test/pubg-home.webp', 'https://x.test/pubg-home.webp']);
  });
}
