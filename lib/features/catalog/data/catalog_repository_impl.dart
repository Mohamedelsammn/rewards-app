import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../domain/entities/catalog_entities.dart';
import '../domain/repositories/catalog_repository.dart';
import 'catalog_models.dart';

/// Catalog routes are public; the server hides unpublished items and
/// social-media categories while `features.socialProducts` is off.
class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<RewardCategory>> categories() async {
    final items = parseList(
      (await _api.get('/categories', auth: false))['items'],
      CatalogModels.category,
    );
    return items..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<RewardCategory> category(String id) async => CatalogModels.category(
    Map<String, dynamic>.from((await _api.get('/categories/$id', auth: false))['category'] as Map),
  );

  @override
  Future<List<Product>> products(
    String categoryId, {
    String? groupId,
    ProductType? productType,
  }) async {
    final items = parseList(
      (await _api.get(
        '/categories/$categoryId/products',
        auth: false,
        query: {'groupId': groupId, 'productType': productType?.apiValue},
      ))['items'],
      CatalogModels.product,
    );
    // A server that ignored the filter must not put every product in both
    // game tabs: keep only the requested type (by the returned field).
    return productType == null
        ? items
        : [
            for (final p in items)
              if (p.productType == productType) p,
          ];
  }

  @override
  Future<Product> product(String id) async => CatalogModels.product(
    Map<String, dynamic>.from((await _api.get('/products/$id', auth: false))['product'] as Map),
  );
}
