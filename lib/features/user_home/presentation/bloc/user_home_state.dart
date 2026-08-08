import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/models/giveaway.dart';

enum UserHomeStatus { initial, loading, loaded, error }

class UserHomeState extends Equatable {
  const UserHomeState({
    this.status = UserHomeStatus.initial,
    this.allGiveaways = const [],
    this.searchQuery = '',
    this.failure,
  });

  final UserHomeStatus status;
  final List<Giveaway> allGiveaways;
  final String searchQuery;
  final Failure? failure;

  List<Giveaway> get filteredGiveaways {
    if (searchQuery.trim().isEmpty) return allGiveaways;
    final q = searchQuery.trim().toLowerCase();
    return allGiveaways.where((g) => g.title.toLowerCase().contains(q)).toList();
  }

  Giveaway? get featured => allGiveaways.isEmpty ? null : allGiveaways.first;
  List<Giveaway> get popular => allGiveaways.skip(1).take(6).toList();

  UserHomeState copyWith({
    UserHomeStatus? status,
    List<Giveaway>? allGiveaways,
    String? searchQuery,
    Failure? failure,
  }) {
    return UserHomeState(
      status: status ?? this.status,
      allGiveaways: allGiveaways ?? this.allGiveaways,
      searchQuery: searchQuery ?? this.searchQuery,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, allGiveaways, searchQuery, failure];
}
