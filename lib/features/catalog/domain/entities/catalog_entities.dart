import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_text.dart';

enum CategoryKind { game, socialMedia, physicalGoods, other }

CategoryKind categoryKindFrom(String? value) => switch (value) {
  'GAME' => CategoryKind.game,
  'SOCIAL_MEDIA' => CategoryKind.socialMedia,
  'PHYSICAL_GOODS' => CategoryKind.physicalGoods,
  _ => CategoryKind.other,
};

class ProductGroup extends Equatable {
  const ProductGroup({required this.id, required this.name});

  final String id;
  final LocalizedText name;

  @override
  List<Object?> get props => [id, name];
}

class RewardCategory extends Equatable {
  const RewardCategory({
    required this.id,
    required this.kind,
    required this.name,
    this.description = const LocalizedText(),
    this.homeImageUrl,
    this.bannerImageUrl,
    this.sortOrder = 0,
    this.groups = const [],
  });

  final String id;
  final CategoryKind kind;
  final LocalizedText name;
  final LocalizedText description;

  /// Home rail tiles and category cards.
  final String? homeImageUrl;

  /// Wide hero of the details page. Never filled from [homeImageUrl]: when
  /// `null` the hero shows a branded placeholder.
  final String? bannerImageUrl;
  final int sortOrder;

  bool get isGame => kind == CategoryKind.game;

  /// Only filled by `GET /categories/:id`.
  final List<ProductGroup> groups;

  @override
  List<Object?> get props => [
    id,
    kind,
    name,
    description,
    homeImageUrl,
    bannerImageUrl,
    sortOrder,
    groups,
  ];
}

/// Product tab of a game: `TOP_UP` (UC, diamonds, credits) or `ITEM_SKIN`
/// (skins, outfits, bundles). Legacy products have no type and appear in
/// neither game tab.
enum ProductType {
  topUp('TOP_UP'),
  itemSkin('ITEM_SKIN');

  const ProductType(this.apiValue);

  /// Value of the `productType` field and query parameter.
  final String apiValue;
}

ProductType? productTypeFrom(String? value) => switch (value) {
  'TOP_UP' => ProductType.topUp,
  'ITEM_SKIN' => ProductType.itemSkin,
  _ => null,
};

enum FieldType { text, number, url, phone, email, select }

FieldType fieldTypeFrom(String? value) => switch (value) {
  'NUMBER' => FieldType.number,
  'URL' => FieldType.url,
  'PHONE' => FieldType.phone,
  'EMAIL' => FieldType.email,
  'SELECT' => FieldType.select,
  _ => FieldType.text,
};

/// A fulfilment field the user must fill before redeeming (Player ID,
/// username, profile URL, shipping details, …). Defined by the admin.
class ProductField extends Equatable {
  const ProductField({
    required this.key,
    required this.label,
    required this.type,
    this.required = true,
    this.pattern,
    this.options = const [],
  });

  final String key;
  final LocalizedText label;
  final FieldType type;
  final bool required;
  final String? pattern;
  final List<String> options;

  @override
  List<Object?> get props => [key, label, type, required, pattern, options];
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.pointsPrice,
    this.groupId,
    this.productType,
    this.description = const LocalizedText(),
    this.deliveryNote = const LocalizedText(),
    this.imageUrl,
    this.priceVersion = 1,
    this.inStock = true,
    this.stock,
    this.featured = false,
    this.fields = const [],
  });

  final String id;
  final String categoryId;
  final String? groupId;
  final ProductType? productType;
  final LocalizedText name;
  final LocalizedText description;
  final LocalizedText deliveryNote;
  final String? imageUrl;

  /// Current price of the product, always from the server.
  final int pointsPrice;
  final int priceVersion;
  final bool inStock;
  final int? stock;
  final bool featured;

  /// Only filled by `GET /products/:id`.
  final List<ProductField> fields;

  @override
  List<Object?> get props => [
    id,
    productType,
    pointsPrice,
    priceVersion,
    inStock,
    stock,
    fields,
    name,
  ];
}
