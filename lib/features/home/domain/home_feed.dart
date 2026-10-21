import 'package:equatable/equatable.dart';

import '../../catalog/domain/entities/catalog_entities.dart';
import '../../giveaways/domain/entities/giveaway_entities.dart';

/// `GET /home`: the Home screen's categories rail, featured rewards and
/// giveaways grid in one request.
class HomeFeed extends Equatable {
  const HomeFeed({
    this.categories = const [],
    this.featuredProducts = const [],
    this.giveaways = const [],
  });

  final List<RewardCategory> categories;
  final List<Product> featuredProducts;
  final List<Giveaway> giveaways;

  bool get isEmpty => categories.isEmpty && featuredProducts.isEmpty && giveaways.isEmpty;

  @override
  List<Object?> get props => [categories, featuredProducts, giveaways];
}

abstract interface class HomeRepository {
  Future<HomeFeed> home();

  /// `GET /search` across categories, products and giveaways.
  Future<HomeFeed> search(String query);
}
