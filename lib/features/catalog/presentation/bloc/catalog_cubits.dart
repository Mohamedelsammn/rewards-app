import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';

enum LoadStatus { loading, ready, failed }

class CategoriesState extends Equatable {
  const CategoriesState({this.status = LoadStatus.loading, this.categories = const [], this.error});

  final LoadStatus status;
  final List<RewardCategory> categories;
  final Object? error;

  @override
  List<Object?> get props => [status, categories, error];
}

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState());

  final CatalogRepository _repository;

  Future<void> load() async {
    if (state.categories.isEmpty) emit(const CategoriesState());
    try {
      emit(CategoriesState(status: LoadStatus.ready, categories: await _repository.categories()));
    } catch (error) {
      emit(CategoriesState(status: LoadStatus.failed, categories: state.categories, error: error));
    }
  }
}

class CategoryDetailsState extends Equatable {
  const CategoryDetailsState({
    this.status = LoadStatus.loading,
    this.category,
    this.groupId,
    this.products = const [],
    this.productsLoading = false,
    this.error,
  });

  final LoadStatus status;
  final RewardCategory? category;

  /// Selected product group, or `null` when the category has no groups.
  final String? groupId;
  final List<Product> products;
  final bool productsLoading;
  final Object? error;

  CategoryDetailsState copyWith({
    LoadStatus? status,
    RewardCategory? category,
    String? groupId,
    List<Product>? products,
    bool? productsLoading,
    Object? error,
  }) => CategoryDetailsState(
    status: status ?? this.status,
    category: category ?? this.category,
    groupId: groupId ?? this.groupId,
    products: products ?? this.products,
    productsLoading: productsLoading ?? this.productsLoading,
    error: error,
  );

  @override
  List<Object?> get props => [status, category, groupId, products, productsLoading, error];
}

/// `GET /categories/:id` (groups) + `GET /categories/:id/products?groupId=`.
class CategoryDetailsCubit extends Cubit<CategoryDetailsState> {
  CategoryDetailsCubit(this._repository, {required this.categoryId, RewardCategory? preview})
    : super(CategoryDetailsState(category: preview));

  final CatalogRepository _repository;
  final String categoryId;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final category = await _repository.category(categoryId);
      final groupId = category.groups.isEmpty ? null : (state.groupId ?? category.groups.first.id);
      final products = await _repository.products(categoryId, groupId: groupId);
      emit(
        CategoryDetailsState(
          status: LoadStatus.ready,
          category: category,
          groupId: groupId,
          products: products,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: LoadStatus.failed, error: error));
    }
  }

  Future<void> selectGroup(String groupId) async {
    if (groupId == state.groupId || state.productsLoading) return;
    emit(state.copyWith(groupId: groupId, productsLoading: true));
    try {
      final products = await _repository.products(categoryId, groupId: groupId);
      if (state.groupId != groupId) return;
      emit(state.copyWith(products: products, productsLoading: false));
    } catch (error) {
      emit(state.copyWith(productsLoading: false, error: error));
    }
  }
}
