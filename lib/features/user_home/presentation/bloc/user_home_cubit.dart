import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/repositories/giveaway_repository.dart';
import '../../../../shared/repositories/category_repository.dart';
import '../../../../shared/models/giveaway.dart';
import 'user_home_state.dart';

class UserHomeCubit extends Cubit<UserHomeState> {
  UserHomeCubit(this._repository, this._client, {this._categories}) : super(const UserHomeState());
  final GiveawayRepository _repository;
  final SupabaseClient _client;
  final CategoryRepository? _categories;
  Timer? _debounce;
  Timer? _reloadDebounce;
  RealtimeChannel? _channel;
  int _generation = 0;
  int _page = 0;

  Future<void> load({bool forceRefresh = false}) async {
    final generation = ++_generation;
    _page = 0;
    emit(
      state.copyWith(
        status: UserHomeStatus.loading,
        allGiveaways: state.allGiveaways,
        loadingMore: false,
        hasMore: false,
      ),
    );
    final result = await _repository.getBrowsePage(
      query: state.searchQuery,
      categoryId: state.categoryId,
    );
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => emit(state.copyWith(status: UserHomeStatus.error, failure: failure)),
      (rows) => emit(
        state.copyWith(
          status: UserHomeStatus.loaded,
          allGiveaways: rows,
          hasMore: rows.length == GiveawayRepository.browsePageSize,
        ),
      ),
    );
  }

  Future<void> loadCategories() async {
    if (_categories == null) {
      emit(state.copyWith(categoriesLoading: false));
      return;
    }
    emit(state.copyWith(categoriesLoading: state.categories.isEmpty, clearCategoryFailure: true));
    final result = await _categories.getCategories();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(categoriesLoading: false, categoryFailure: failure)),
      (rows) {
        final removed = state.categoryId != null && !rows.any((c) => c.id == state.categoryId);
        emit(
          UserHomeState(
            status: state.status,
            allGiveaways: state.allGiveaways,
            searchQuery: state.searchQuery,
            categories: rows,
            categoryId: removed ? null : state.categoryId,
            hasMore: state.hasMore,
            loadingMore: state.loadingMore,
            failure: state.failure,
            categoriesLoading: false,
          ),
        );
        if (removed) unawaited(load());
      },
    );
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.status != UserHomeStatus.loaded) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    final result = await _repository.getBrowsePage(
      page: _page + 1,
      query: state.searchQuery,
      categoryId: state.categoryId,
    );
    if (isClosed || generation != _generation) return;
    result.fold((failure) => emit(state.copyWith(loadingMore: false, failure: failure)), (rows) {
      _page++;
      final known = state.allGiveaways.map((g) => g.id).toSet();
      emit(
        state.copyWith(
          loadingMore: false,
          allGiveaways: [...state.allGiveaways, ...rows.where((g) => known.add(g.id))],
          hasMore: rows.length == GiveawayRepository.browsePageSize,
        ),
      );
    });
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (isClosed || state.searchQuery == query.trim()) return;
      emit(state.copyWith(searchQuery: query.trim()));
      unawaited(load());
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    if (state.searchQuery.isEmpty) return;
    emit(state.copyWith(searchQuery: ''));
    unawaited(load());
  }

  void selectCategory(String? id) {
    if (state.categoryId == id) return;
    emit(state.copyWith(categoryId: id, clearCategory: id == null));
    unawaited(load());
  }

  void subscribeToRealtime() {
    if (_channel != null) return;
    _channel = _client
        .channel('user-home-browse')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'giveaways',
          callback: (payload) {
            // Count/status patches do not change pagination or trigger a full refetch.
            if (payload.eventType == PostgresChangeEvent.update) {
              final id = payload.newRecord['id'];
              final index = state.allGiveaways.indexWhere((g) => g.id == id);
              if (index >= 0 &&
                  payload.newRecord['title'] == state.allGiveaways[index].title &&
                  payload.newRecord['category_id'] == state.allGiveaways[index].categoryId &&
                  ['active', 'scheduled', 'ended'].contains(payload.newRecord['status'])) {
                try {
                  final next = List<Giveaway>.of(state.allGiveaways);
                  next[index] = Giveaway.fromJson(payload.newRecord);
                  emit(state.copyWith(allGiveaways: next));
                  return;
                } catch (_) {}
              }
            }
            _reloadDebounce?.cancel();
            _reloadDebounce = Timer(const Duration(seconds: 2), () {
              if (!isClosed) load();
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'giveaway_categories',
          callback: (_) => loadCategories(),
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    _generation++;
    _debounce?.cancel();
    _reloadDebounce?.cancel();
    if (_channel != null) unawaited(_client.removeChannel(_channel!));
    return super.close();
  }
}
