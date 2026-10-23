import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/catalog/data/catalog_repository_impl.dart';
import 'package:rewardsapp/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rewardsapp/features/catalog/presentation/bloc/catalog_cubits.dart';
import 'package:rewardsapp/features/home/data/home_repository_impl.dart';

import '../../helpers/fake_api.dart';

/// docs/FLUTTER_INTEGRATION-6.md §7: the server alone hides social-media
/// categories while `features.socialProducts` is off. Once it returns them,
/// the app must show them as they are (no client-side kind or flag filter).
const _instagram = {
  'id': 's1',
  'kind': 'SOCIAL_MEDIA',
  'name': {'ar': 'إنستغرام', 'en': 'Instagram'},
  'description': {'ar': '', 'en': ''},
  'homeImageUrl': 'https://x.test/ig.webp',
  'bannerImageUrl': null,
  'sortOrder': 2,
  'status': 'PUBLISHED',
};

const _pubg = {
  'id': 'g1',
  'kind': 'GAME',
  'name': {'en': 'PUBG Mobile'},
  'sortOrder': 0,
};

const _followers = {
  'id': 'p1',
  'categoryId': 's1',
  'name': {'en': '1000 Followers'},
  'pointsPrice': 500,
  'productType': null,
};

FakeResponse _serve(String path, Map<String, dynamic> query) => switch (path) {
  '/categories' => const FakeResponse(200, {
    'items': [_instagram, _pubg],
  }),
  '/categories/s1' => const FakeResponse(200, {
    'category': {..._instagram, 'groups': <Object>[]},
  }),
  '/categories/s1/products' => const FakeResponse(200, {
    'items': [_followers],
  }),
  '/home' => const FakeResponse(200, {
    'categories': [_pubg, _instagram],
    'featuredProducts': [_followers],
    'giveaways': <Object>[],
  }),
  '/search' => const FakeResponse(200, {
    'categories': [_instagram],
    'products': [_followers],
    'giveaways': <Object>[],
  }),
  _ => apiError(404, 'NOT_FOUND'),
};

void main() {
  late FakeApi api;

  setUp(() => api = FakeApi((options) => _serve(options.path, options.queryParameters)));

  test('categories list keeps SOCIAL_MEDIA next to games', () async {
    final categories = await CatalogRepositoryImpl(api.client).categories();
    expect(
      [for (final c in categories) (c.id, c.kind)],
      [('g1', CategoryKind.game), ('s1', CategoryKind.socialMedia)],
    );
  });

  test('Home and search pass social-media categories and products through', () async {
    final repository = HomeRepositoryImpl(api.client);
    final home = await repository.home();
    expect(home.categories.map((c) => c.kind), contains(CategoryKind.socialMedia));
    expect(home.featuredProducts.single.id, 'p1');

    final results = await repository.search('instagram');
    expect(results.categories.single.kind, CategoryKind.socialMedia);
    expect(results.featuredProducts.single.categoryId, 's1');
  });

  test('a social-media category loads one unfiltered list, without tabs', () async {
    final cubit = CategoryDetailsCubit(CatalogRepositoryImpl(api.client), categoryId: 's1');
    await cubit.load();

    expect(cubit.state.status, LoadStatus.ready);
    expect(cubit.state.category?.kind, CategoryKind.socialMedia);
    expect(cubit.state.productType, isNull);
    expect(cubit.state.visibleProducts.map((p) => p.id), ['p1']);
    final productCalls = api.adapter.requests.where((r) => r.path == '/categories/s1/products');
    expect(productCalls.single.queryParameters, isEmpty);
    await cubit.close();
  });
}
