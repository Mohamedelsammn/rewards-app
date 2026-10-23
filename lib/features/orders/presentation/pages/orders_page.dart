import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/selectors.dart';
import '../../domain/order_entities.dart';
import '../bloc/orders_cubits.dart';
import '../widgets/order_widgets.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => OrdersCubit(sl())..refresh(), child: const _OrdersView());
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<OrdersCubit>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<OrdersCubit, PagedListState<Order, OrdersFilter>>(
          builder: (context, state) => PagedListView<Order, OrdersFilter>(
            state: state,
            onRefresh: cubit.refresh,
            onLoadMore: cubit.loadMore,
            emptyMessage: state.filter == OrdersFilter.all
                ? l10n.ordersEmpty
                : l10n.ordersEmptyFiltered,
            skeletonRow: const SkeletonRow(
              leadingSize: 78,
              leadingRadius: 18,
              lines: [160, 110, 90],
              trailingWidth: 64,
              trailingHeight: 24,
            ),
            header: [
              SecondaryHeader(
                title: l10n.ordersTitle,
                subtitle: l10n.ordersSubtitle,
                art: const HeaderArt(HeaderArtKind.bag),
              ),
              const SizedBox(height: 24),
              FilterPills<OrdersFilter>(
                options: [
                  SelectorOption(OrdersFilter.all, l10n.ordersAll),
                  SelectorOption(OrdersFilter.inProgress, l10n.ordersInProgress),
                  SelectorOption(OrdersFilter.completed, l10n.ordersCompleted),
                  SelectorOption(OrdersFilter.unsuccessful, l10n.ordersUnsuccessful),
                ],
                selected: state.filter,
                onChanged: cubit.setFilter,
              ),
              const SizedBox(height: 18),
            ],
            itemBuilder: (context, order) => OrderCard(
              order: order,
              onTap: () async {
                await context.push(Routes.order(order.id));
                if (context.mounted) cubit.refresh();
              },
            ),
          ),
        ),
      ),
    );
  }
}
