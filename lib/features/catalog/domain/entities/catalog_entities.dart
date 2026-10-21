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
    this.imageUrl,
    this.sortOrder = 0,
    this.groups = const [],
  });

  final String id;
  final CategoryKind kind;
  final LocalizedText name;
  final LocalizedText description;
  final String? imageUrl;
  final int sortOrder;

  /// Only filled by `GET /categories/:id`.
  final List<ProductGroup> groups;

  @override
  List<Object?> get props => [id, kind, name, description, imageUrl, sortOrder, groups];
}

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
  List<Object?> get props => [id, pointsPrice, priceVersion, inStock, stock, fields, name];
}
