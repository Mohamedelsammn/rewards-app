import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/home_feed.dart';

enum HomeStatus { loading, ready, failed }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.feed = const HomeFeed(),
    this.error,
    this.query = '',
    this.searching = false,
    this.results,
    this.searchError,
  });

  final HomeStatus status;
  final HomeFeed feed;
  final Object? error;
  final String query;
  final bool searching;

  /// Server search results; `null` while no query is active.
  final HomeFeed? results;
  final Object? searchError;

  bool get isSearching => query.trim().isNotEmpty;

  HomeState copyWith({
    HomeStatus? status,
    HomeFeed? feed,
    Object? error,
    String? query,
    bool? searching,
    HomeFeed? results,
    Object? searchError,
    bool clearResults = false,
  }) => HomeState(
    status: status ?? this.status,
    feed: feed ?? this.feed,
    error: error,
    query: query ?? this.query,
    searching: searching ?? this.searching,
    results: clearResults ? null : results ?? this.results,
    searchError: searchError,
  );

  @override
  List<Object?> get props => [status, feed, error, query, searching, results, searchError];
}

/// `GET /home` plus debounced `GET /search`.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository, {this.debounce = const Duration(milliseconds: 350)})
    : super(const HomeState());

  final HomeRepository _repository;
  final Duration debounce;
  Timer? _debounceTimer;
  int _searchToken = 0;

  Future<void> load() async {
    if (state.feed.isEmpty) emit(state.copyWith(status: HomeStatus.loading));
    try {
      emit(state.copyWith(status: HomeStatus.ready, feed: await _repository.home()));
    } catch (error) {
      emit(state.copyWith(status: HomeStatus.failed, error: error));
    }
  }

  void search(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchToken++;
      emit(state.copyWith(query: '', searching: false, clearResults: true));
      return;
    }
    emit(state.copyWith(query: query, searching: true));
    _debounceTimer = Timer(debounce, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    final token = ++_searchToken;
    try {
      final results = await _repository.search(query.length > 60 ? query.substring(0, 60) : query);
      if (isClosed || token != _searchToken) return;
      emit(state.copyWith(searching: false, results: results));
    } catch (error) {
      if (isClosed || token != _searchToken) return;
      emit(state.copyWith(searching: false, searchError: error, clearResults: true));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
