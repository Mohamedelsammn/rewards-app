import '../../../core/localization/localized_text.dart';
import '../../../core/utils/cursor_page.dart';
import '../domain/entities/catalog_entities.dart';

class CatalogModels {
  const CatalogModels._();

  static RewardCategory category(Map<String, dynamic> json) => RewardCategory(
    id: '${json['id']}',
    kind: categoryKindFrom(json['kind'] as String?),
    name: LocalizedText.fromJson(json['name']),
    description: LocalizedText.fromJson(json['description']),
    // `imageUrl` is the deprecated alias of `homeImageUrl` (old servers).
    homeImageUrl: _url(json['homeImageUrl']) ?? _url(json['imageUrl']),
    bannerImageUrl: _url(json['bannerImageUrl']),
    sortOrder: parseInt(json['sortOrder']),
    groups: parseList(
      json['groups'],
      (group) => ProductGroup(id: '${group['id']}', name: LocalizedText.fromJson(group['name'])),
    ),
  );

  static Product product(Map<String, dynamic> json) => Product(
    id: '${json['id']}',
    categoryId: '${json['categoryId'] ?? ''}',
    groupId: json['groupId'] as String?,
    productType: productTypeFrom(json['productType'] as String?),
    name: LocalizedText.fromJson(json['name']),
    description: LocalizedText.fromJson(json['description']),
    deliveryNote: LocalizedText.fromJson(json['deliveryNote']),
    imageUrl: json['imageUrl'] as String?,
    pointsPrice: parseInt(json['pointsPrice']),
    priceVersion: parseInt(json['priceVersion'], 1),
    inStock: json['inStock'] != false,
    stock: json['stock'] == null ? null : parseInt(json['stock']),
    featured: json['featured'] == true,
    fields: parseList(json['fields'], field),
  );

  static String? _url(Object? value) => value is String && value.isNotEmpty ? value : null;

  static ProductField field(Map<String, dynamic> json) => ProductField(
    key: '${json['key']}',
    label: LocalizedText.fromJson(json['label']),
    type: fieldTypeFrom(json['type'] as String?),
    required: json['required'] != false,
    pattern: (json['pattern'] as String?)?.isEmpty == true ? null : json['pattern'] as String?,
    options: json['options'] is List
        ? [for (final option in json['options'] as List) '$option']
        : const [],
  );
}
