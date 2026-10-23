import 'package:flutter/material.dart';

import '../utils/paged_list_state.dart';
import 'skeleton.dart';
import 'state_views.dart';

/// Scrollable list that renders a [PagedListState], loads the next page near
/// the end, and supports pull-to-refresh. [header] scrolls with the items.
///
/// The first load shows [skeleton] (shaped like the screen's items); loading
/// the next page shows one more [skeletonRow]. A failed refresh keeps the
/// items and shows a [RefreshErrorBanner].
class PagedListView<T, F> extends StatelessWidget {
  const PagedListView({
    required this.state,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    required this.emptyMessage,
    required this.skeletonRow,
    this.skeletonCount = 6,
    this.header = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 24),
    super.key,
  });

  final PagedListState<T, F> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final String emptyMessage;

  /// Placeholder for one item, with the item's real dimensions.
  final Widget skeletonRow;
  final int skeletonCount;
  final List<Widget> header;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification.metrics.extentAfter < 400) onLoadMore();
      return false;
    },
    child: RefreshIndicator(onRefresh: onRefresh, child: _list(context)),
  );

  /// Fixed rows (header, states) first, then the items built lazily: only
  /// rows near the viewport are created, however many pages are loaded.
  Widget _list(BuildContext context) {
    final fixed = <Widget>[
      ...header,
      if (state.status == PagedStatus.loading)
        SkeletonList(row: skeletonRow, count: skeletonCount)
      else if (state.status == PagedStatus.failed && state.items.isEmpty)
        ErrorStateView(error: state.error!, onRetry: onRefresh)
      else if (state.items.isEmpty)
        EmptyCard(emptyMessage)
      else if (state.status == PagedStatus.failed) ...[
        RefreshErrorBanner(onRetry: onRefresh),
        const SizedBox(height: 12),
      ],
    ];
    final showItems = state.status != PagedStatus.loading && state.items.isNotEmpty;
    final items = showItems ? state.items : const [];
    final loadingMore = showItems && state.loadingMore;
    return ListView.builder(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: fixed.length + items.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < fixed.length) return fixed[index];
        final i = index - fixed.length;
        if (i < items.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: itemBuilder(context, items[i] as T),
          );
        }
        return SkeletonList(row: skeletonRow, count: 1);
      },
    );
  }
}
