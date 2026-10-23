import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../../../core/utils/safe_emit.dart';

enum LoadStatus { loading, ready, failed }

class CategoriesState extends Equatable {
  const CategoriesState({this.status = LoadStatus.loading, this.categories = const [], this.error});

  final LoadStatus status;
  final List<RewardCategory> categories;
  final Object? error;

  @override
  List<Object?> get props => [status, categories, error];
}

class CategoriesCubit extends Cubit<CategoriesState> with SafeEmit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState());

  final CatalogRepository _repository;

  /// Like Home: the skeleton shows only until the first response, and a
  /// refresh keeps the current list (or empty state) on screen.
  Future<void> load() async {
    final loaded = state.status == LoadStatus.ready;
    if (!loaded) emit(const CategoriesState());
    try {
      emit(CategoriesState(status: LoadStatus.ready, categories: await _repository.categories()));
    } catch (error) {
      // A failed refresh keeps the list (status stays ready) and reports it.
      emit(
        CategoriesState(
          status: loaded ? LoadStatus.ready : LoadStatus.failed,
          categories: state.categories,
          error: error,
        ),
      );
    }
  }
}

class CategoryDetailsState extends Equatable {
  const CategoryDetailsState({
    this.status = LoadStatus.loading,
    this.category,
    this.groupId,
    this.productType,
    this.products = const [],
    this.typedProducts = const {},
    this.productsLoading = false,
    this.error,
  });

  final LoadStatus status;
  final RewardCategory? category;

  /// Selected product group, or `null` when the category has no groups.
  final String? groupId;

  /// Selected game tab; `null` for non-game categories.
  final ProductType? productType;

  /// Products of a non-game category.
  final List<Product> products;

  /// Products of a game, one server-filtered list per tab.
  final Map<ProductType, List<Product>> typedProducts;
  final bool productsLoading;
  final Object? error;

  /// What the grid shows: the selected tab's list for games.
  List<Product> get visibleProducts {
    final type = productType;
    return type == null ? products : typedProducts[type] ?? const [];
  }

  CategoryDetailsState copyWith({
    LoadStatus? status,
    RewardCategory? category,
    String? groupId,
    ProductType? productType,
    List<Product>? products,
    Map<ProductType, List<Product>>? typedProducts,
    bool? productsLoading,
    Object? error,
  }) => CategoryDetailsState(
    status: status ?? this.status,
    category: category ?? this.category,
    groupId: groupId ?? this.groupId,
    productType: productType ?? this.productType,
    products: products ?? this.products,
    typedProducts: typedProducts ?? this.typedProducts,
    productsLoading: productsLoading ?? this.productsLoading,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    category,
    groupId,
    productType,
    products,
    typedProducts,
    productsLoading,
    error,
  ];
}

/// Last loaded Category Details per category for this app session, so
/// reopening a game shows its products at once instead of a skeleton. Holds
/// public catalog data only, in memory; images are cached by `AppImage`.
class CategorySnapshots {
  CategorySnapshots({this.maxAge = const Duration(minutes: 1), DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Within this age a reopened category is not requested again.
  final Duration maxAge;
  final DateTime Function() _clock;
  final _entries = <String, (DateTime, CategoryDetailsState)>{};
  static const _limit = 20;

  CategoryDetailsState? read(String categoryId) => _entries[categoryId]?.$2;

  bool isFresh(String categoryId) {
    final entry = _entries[categoryId];
    return entry != null && _clock().difference(entry.$1) < maxAge;
  }

  void write(String categoryId, CategoryDetailsState state, {bool touch = true}) {
    final saved = touch ? _clock() : (_entries[categoryId]?.$1 ?? _clock());
    _entries
      ..remove(categoryId)
      ..[categoryId] = (saved, state);
    if (_entries.length > _limit) _entries.remove(_entries.keys.first);
  }
}

typedef _Lists = ({List<Product> products, Map<ProductType, List<Product>> typed});

/// `GET /categories/:id` (groups) + `GET /categories/:id/products?groupId=`.
/// Games show two tabs, each loaded with `productType=` (in parallel), so
/// legacy products without a type appear in neither.
///
/// Loaded content stays on screen during a refresh; a reopened category
/// starts from its [CategorySnapshots] entry.
class CategoryDetailsCubit extends Cubit<CategoryDetailsState> with SafeEmit<CategoryDetailsState> {
  CategoryDetailsCubit(
    this._repository, {
    required this.categoryId,
    RewardCategory? preview,
    CategorySnapshots? snapshots,
  }) : _snapshots = snapshots,
       super(snapshots?.read(categoryId) ?? CategoryDetailsState(category: preview));

  final CatalogRepository _repository;
  final CategorySnapshots? _snapshots;
  final String categoryId;

  /// First load of the page: nothing to request while the snapshot is fresh.
  Future<void> open() async {
    if (_snapshots?.isFresh(categoryId) ?? false) return;
    await load();
  }

  Future<void> load() async {
    final loaded = state.status == LoadStatus.ready;
    if (!loaded) emit(state.copyWith(status: LoadStatus.loading));
    // The products usually don't depend on the answer (no groups, or the
    // group from the last visit): request them alongside the category.
    final guessGroup = state.groupId;
    final guessGame = state.category?.isGame;
    final early = guessGame == null ? null : _quiet(_lists(guessGroup, game: guessGame));
    try {
      final category = await _repository.category(categoryId);
      if (isClosed) return;
      final groups = category.groups;
      final groupId = groups.isEmpty
          ? null
          : (groups.any((g) => g.id == state.groupId) ? state.groupId : groups.first.id);
      final lists = groupId == guessGroup && category.isGame == guessGame
          ? (await early) ?? await _lists(groupId, game: category.isGame)
          : await _lists(groupId, game: category.isGame);
      if (isClosed) return;
      emit(
        CategoryDetailsState(
          status: LoadStatus.ready,
          category: category,
          groupId: groupId,
          productType: category.isGame ? (state.productType ?? ProductType.topUp) : null,
          products: lists.products,
          typedProducts: lists.typed,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      // A failed refresh keeps what is on screen and reports it.
      emit(state.copyWith(status: loaded ? LoadStatus.ready : LoadStatus.failed, error: error));
    }
  }

  /// Both tabs were loaded together; switching needs no request.
  void selectProductType(ProductType type) {
    if (type != state.productType) emit(state.copyWith(productType: type));
  }

  Future<void> selectGroup(String groupId) async {
    if (groupId == state.groupId || state.productsLoading) return;
    emit(state.copyWith(groupId: groupId, productsLoading: true));
    try {
      final lists = await _lists(groupId, game: state.category?.isGame ?? false);
      if (isClosed || state.groupId != groupId) return;
      emit(
        state.copyWith(
          products: lists.products,
          typedProducts: lists.typed,
          productsLoading: false,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(productsLoading: false, error: error));
    }
  }

  @override
  void onChange(Change<CategoryDetailsState> change) {
    super.onChange(change);
    final next = change.nextState;
    if (next.status == LoadStatus.ready && !next.productsLoading && next.error == null) {
      // Only a server answer restarts the freshness window, not a tab switch.
      final answered =
          change.currentState.status != LoadStatus.ready ||
          !identical(change.currentState.category, next.category);
      _snapshots?.write(categoryId, next, touch: answered);
    }
  }

  Future<_Lists> _lists(String? groupId, {required bool game}) async {
    if (!game) {
      return (
        products: await _repository.products(categoryId, groupId: groupId),
        typed: const <ProductType, List<Product>>{},
      );
    }
    final lists = await Future.wait([
      for (final type in ProductType.values)
        _repository.products(categoryId, groupId: groupId, productType: type),
    ]);
    return (
      products: const <Product>[],
      typed: {for (var i = 0; i < ProductType.values.length; i++) ProductType.values[i]: lists[i]},
    );
  }

  /// An early request whose failure is handled by the regular one.
  static Future<_Lists?> _quiet(Future<_Lists> request) =>
      request.then<_Lists?>((lists) => lists, onError: (Object _) => null);
}
