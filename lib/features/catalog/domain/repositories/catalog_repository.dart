import '../entities/catalog_entities.dart';

abstract interface class CatalogRepository {
  Future<List<RewardCategory>> categories();

  /// RewardCategory with its product groups.
  Future<RewardCategory> category(String id);

  /// Published products; [productType] filters on the server (game tabs).
  Future<List<Product>> products(String categoryId, {String? groupId, ProductType? productType});

  /// Product with its fulfilment fields.
  Future<Product> product(String id);
}
