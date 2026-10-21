import 'package:flutter/material.dart';

import '../utils/paged_list_state.dart';
import 'state_views.dart';

/// Scrollable list that renders a [PagedListState], loads the next page near
/// the end, and supports pull-to-refresh. [header] scrolls with the items.
class PagedListView<T, F> extends StatelessWidget {
  const PagedListView({
    required this.state,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    required this.emptyMessage,
    this.header = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 24),
    super.key,
  });

  final PagedListState<T, F> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final String emptyMessage;
  final List<Widget> header;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification.metrics.extentAfter < 400) onLoadMore();
      return false;
    },
    child: RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ...header,
          if (state.status == PagedStatus.loading)
            const LoadingView()
          else if (state.status == PagedStatus.failed && state.items.isEmpty)
            ErrorStateView(error: state.error!, onRetry: onRefresh)
          else if (state.items.isEmpty)
            EmptyCard(emptyMessage)
          else ...[
            for (final item in state.items) ...[
              itemBuilder(context, item),
              const SizedBox(height: 12),
            ],
            if (state.loadingMore) const LoadingView(padding: EdgeInsets.all(16)),
          ],
        ],
      ),
    ),
  );
}
