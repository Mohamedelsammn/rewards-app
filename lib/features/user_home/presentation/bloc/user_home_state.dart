import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../shared/models/giveaway.dart';
import '../../../../shared/models/giveaway_category.dart';

enum UserHomeStatus { initial, loading, loaded, error }

class UserHomeState extends Equatable {
  const UserHomeState({
    this.status = UserHomeStatus.initial,
    this.allGiveaways = const [],
    this.searchQuery = '',
    this.categories = const [],
    this.categoryId,
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
    this.categoryFailure,
    this.categoriesLoading = true,
  });
  final UserHomeStatus status;
  final List<Giveaway> allGiveaways;
  final String searchQuery;
  final List<GiveawayCategory> categories;
  final String? categoryId;
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;
  final Failure? categoryFailure;
  final bool categoriesLoading;
  List<Giveaway> get filteredGiveaways => allGiveaways;
  UserHomeState copyWith({
    UserHomeStatus? status,
    List<Giveaway>? allGiveaways,
    String? searchQuery,
    List<GiveawayCategory>? categories,
    String? categoryId,
    bool clearCategory = false,
    bool? hasMore,
    bool? loadingMore,
    Failure? failure,
    Failure? categoryFailure,
    bool? categoriesLoading,
    bool clearCategoryFailure = false,
  }) => UserHomeState(
    status: status ?? this.status,
    allGiveaways: allGiveaways ?? this.allGiveaways,
    searchQuery: searchQuery ?? this.searchQuery,
    categories: categories ?? this.categories,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure,
    categoryFailure: clearCategoryFailure ? null : categoryFailure ?? this.categoryFailure,
    categoriesLoading: categoriesLoading ?? this.categoriesLoading,
  );
  @override
  List<Object?> get props => [
    status,
    allGiveaways,
    searchQuery,
    categories,
    categoryId,
    hasMore,
    loadingMore,
    failure,
    categoryFailure,
    categoriesLoading,
  ];
}
