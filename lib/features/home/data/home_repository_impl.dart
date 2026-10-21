import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../../catalog/data/catalog_models.dart';
import '../../giveaways/data/giveaway_models.dart';
import '../domain/home_feed.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<HomeFeed> home() async {
    final json = await _api.get('/home', auth: false);
    return HomeFeed(
      categories: parseList(json['categories'], CatalogModels.category),
      featuredProducts: parseList(json['featuredProducts'], CatalogModels.product),
      giveaways: parseList(json['giveaways'], GiveawayModels.giveaway),
    );
  }

  @override
  Future<HomeFeed> search(String query) async {
    final json = await _api.get(
      '/search',
      auth: false,
      query: {'q': query, 'types': 'categories,products,giveaways', 'limit': 20},
    );
    return HomeFeed(
      categories: parseList(json['categories'], CatalogModels.category),
      featuredProducts: parseList(json['products'], CatalogModels.product),
      giveaways: parseList(json['giveaways'], GiveawayModels.giveaway),
    );
  }
}
