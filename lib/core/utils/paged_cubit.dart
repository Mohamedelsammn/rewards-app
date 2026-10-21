import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/app_exception.dart';
import 'cursor_page.dart';
import 'paged_list_state.dart';

/// Base cubit for cursor-paginated lists with a filter. Subclasses only
/// provide [fetch]. Requests for a stale filter are discarded.
abstract class PagedCubit<T, F> extends Cubit<PagedListState<T, F>> {
  PagedCubit(F initialFilter) : super(PagedListState<T, F>(filter: initialFilter));

  Future<CursorPage<T>> fetch(F filter, String? cursor);

  int _generation = 0;

  Future<void> refresh() => _load(state.filter, append: false);

  Future<void> setFilter(F filter) {
    if (filter == state.filter && state.status == PagedStatus.ready) return Future.value();
    emit(PagedListState<T, F>(filter: filter));
    return _load(filter, append: false);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.status != PagedStatus.ready) return;
    emit(state.copyWith(loadingMore: true));
    await _load(state.filter, append: true);
  }

  Future<void> _load(F filter, {required bool append}) async {
    final generation = ++_generation;
    try {
      final page = await fetch(filter, append ? state.nextCursor : null);
      if (isClosed || generation != _generation) return;
      emit(state.withPage(page, append: append));
    } on AppException catch (error) {
      if (isClosed || generation != _generation) return;
      // A corrupted cursor means the list changed: reload from the start.
      if (error.code == 'INVALID_CURSOR' && append) return _load(filter, append: false);
      emit(
        state.copyWith(
          status: append ? PagedStatus.ready : PagedStatus.failed,
          error: error,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          status: append ? PagedStatus.ready : PagedStatus.failed,
          error: error,
          loadingMore: false,
        ),
      );
    }
  }
}
