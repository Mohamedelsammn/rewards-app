import 'package:equatable/equatable.dart';

import 'cursor_page.dart';

enum PagedStatus { loading, ready, failed }

/// Accumulated state of a cursor-paginated list.
class PagedListState<T, F> extends Equatable {
  const PagedListState({
    required this.filter,
    this.status = PagedStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.error,
  });

  final F filter;
  final PagedStatus status;
  final List<T> items;
  final String? nextCursor;
  final bool loadingMore;
  final Object? error;

  bool get hasMore => nextCursor != null;

  PagedListState<T, F> copyWith({
    F? filter,
    PagedStatus? status,
    List<T>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
    Object? error,
  }) => PagedListState<T, F>(
    filter: filter ?? this.filter,
    status: status ?? this.status,
    items: items ?? this.items,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
  );

  PagedListState<T, F> withPage(CursorPage<T> page, {required bool append}) => PagedListState(
    filter: filter,
    status: PagedStatus.ready,
    items: append ? [...items, ...page.items] : page.items,
    nextCursor: page.nextCursor,
  );

  @override
  List<Object?> get props => [filter, status, items, nextCursor, loadingMore, error];
}
