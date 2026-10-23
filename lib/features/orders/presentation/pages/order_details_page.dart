import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../wallet/presentation/bloc/wallet_cubit.dart';
import '../../domain/order_entities.dart';
import '../bloc/orders_cubits.dart';
import '../widgets/order_details_sections.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => OrderDetailsCubit(sl(), orderId)..load(),
    child: const _OrderDetailsView(),
  );
}

class _OrderDetailsView extends StatelessWidget {
  const _OrderDetailsView();

  Future<void> _cancel(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirmDialog(
      context,
      icon: LucideIcons.circleX,
      title: l10n.orderCancelTitle,
      message: l10n.orderCancelMessage,
      confirmLabel: l10n.orderCancel,
      destructive: true,
    );
    if (confirmed && context.mounted) await context.read<OrderDetailsCubit>().cancel();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    body: BlocConsumer<OrderDetailsCubit, OrderDetailsState>(
      listener: (context, state) {
        final balance = state.cancelled;
        if (balance != null) {
          context.read<WalletCubit>().setBalance(balance);
          context.read<SessionCubit>().updateStats(points: balance);
          showAppSnackBar(context, context.l10n.orderCancelDone);
        } else if (state.error != null && state.order != null) {
          showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        final order = state.order;
        final cubit = context.read<OrderDetailsCubit>();
        return Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    children: [
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CircleBackButton(),
                      ),
                      const SizedBox(height: 18),
                      if (order == null && state.loading) const _DetailsSkeleton(),
                      if (order == null && state.error != null)
                        ErrorStateView(error: state.error!, onRetry: cubit.load),
                      if (order != null) ..._sections(context, order),
                    ],
                  ),
                ),
              ),
            ),
            if (order != null) _BottomAction(order: order, state: state, onCancel: _cancel),
          ],
        );
      },
    ),
  );

  List<Widget> _sections(BuildContext context, Order order) {
    final l10n = context.l10n;
    const gap = SizedBox(height: 14);
    return [
      OrderHero(order: order),
      gap,
      OrderSummaryCard(order: order),
      if (order.status.isUnsuccessful) ...[
        const SizedBox(height: 10),
        _Note(l10n.orderRefunded(Formatters.points(order.pointsCost))),
      ],
      gap,
      OrderValueCard(
        key: const ValueKey('order-id-card'),
        icon: LucideIcons.fileText,
        label: l10n.orderIdLabel,
        value: order.orderNumber,
        display: '#${order.orderNumber}',
      ),
      if (order.deliveredCode?.isNotEmpty ?? false) ...[
        gap,
        OrderValueCard(
          icon: LucideIcons.ticket,
          label: l10n.orderDeliveredCode,
          value: order.deliveredCode!,
        ),
      ],
      if (order.trackingInfo?.isNotEmpty ?? false) ...[
        gap,
        OrderValueCard(
          icon: LucideIcons.truck,
          label: l10n.orderTracking,
          value: order.trackingInfo!,
        ),
      ],
      // Only orders with submitted fields have this card.
      if (order.fields.isNotEmpty) ...[gap, OrderAccountDetails(order: order)],
      gap,
      OrderStatusHistory(order: order),
    ];
  }
}

/// Pending orders can be cancelled; others can be redeemed again through
/// the product's category (the regular flow re-checks price, stock, points
/// and account details; nothing is ordered automatically).
class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.order, required this.state, required this.onCancel});

  final Order order;
  final OrderDetailsState state;
  final Future<void> Function(BuildContext context) onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categoryId = order.categoryId;
    final Widget button;
    if (order.cancellable) {
      button = OutlinedButton.icon(
        key: const ValueKey('order-cancel'),
        onPressed: state.cancelling ? null : () => onCancel(context),
        icon: state.cancelling
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(LucideIcons.circleX, color: AppColors.danger),
        label: Text(l10n.orderCancel, style: const TextStyle(color: AppColors.dangerText)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.dangerBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      );
    } else if (categoryId != null && categoryId.isNotEmpty) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.confirmButton,
          borderRadius: BorderRadius.circular(28),
        ),
        child: FilledButton(
          key: const ValueKey('order-redeem-again'),
          onPressed: () => context.push(Routes.category(categoryId)),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shoppingBag, size: 22),
              Expanded(
                child: Text(
                  l10n.orderRedeemAgain,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              // Material arrows mirror themselves in RTL.
              const Icon(Icons.arrow_forward, size: 22),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 12), child: button),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xffe3f7ec),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
    ),
  );
}

/// Placeholder in the layout of the loaded page.
class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) => const Skeleton(
    child: Column(
      key: ValueKey('order-details-skeleton'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBox(height: 104, radius: 24),
        SizedBox(height: 14),
        SkeletonBox(height: 74, radius: 24),
        SizedBox(height: 14),
        SkeletonBox(height: 74, radius: 24),
        SizedBox(height: 14),
        SkeletonBox(height: 140, radius: 24),
        SizedBox(height: 14),
        SkeletonBox(height: 220, radius: 24),
      ],
    ),
  );
}
