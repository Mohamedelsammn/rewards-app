import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../wallet/presentation/bloc/wallet_cubit.dart';
import '../../domain/order_entities.dart';
import '../bloc/orders_cubits.dart';
import '../widgets/order_widgets.dart';

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
    body: SafeArea(
      child: BlocConsumer<OrderDetailsCubit, OrderDetailsState>(
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
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Align(alignment: AlignmentDirectional.centerStart, child: CircleBackButton()),
                const SizedBox(height: 28),
                if (order == null && state.loading) const LoadingView(),
                if (order == null && state.error != null)
                  ErrorStateView(error: state.error!, onRetry: cubit.load),
                if (order != null) ..._details(context, order, state),
              ],
            ),
          );
        },
      ),
    ),
  );

  List<Widget> _details(BuildContext context, Order order, OrderDetailsState state) {
    final l10n = context.l10n;
    return [
      Text(order.productName.of(context), style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 12),
      Text(l10n.orderNumber(order.orderNumber), style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 8),
      Row(
        children: [
          Text(
            l10n.pointsAmount(Formatters.points(order.pointsCost)),
            style: const TextStyle(
              color: AppColors.violet,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          OrderStatusChip(status: order.status),
        ],
      ),
      if (order.status.isUnsuccessful) ...[
        const SizedBox(height: 10),
        _note(l10n.orderRefunded(Formatters.points(order.pointsCost)), success: true),
      ],
      if (order.statusReason?.isNotEmpty ?? false) ...[
        const SizedBox(height: 10),
        _note('${l10n.orderReason}: ${order.statusReason}'),
      ],
      if (order.deliveredCode?.isNotEmpty ?? false) ...[
        _sectionTitle(l10n.orderDeliveredCode),
        _CopyRow(value: order.deliveredCode!),
      ],
      if (order.trackingInfo?.isNotEmpty ?? false) ...[
        _sectionTitle(l10n.orderTracking),
        _CopyRow(value: order.trackingInfo!),
      ],
      if (order.fields.isNotEmpty) ...[
        _sectionTitle(l10n.orderSubmittedDetails),
        for (final entry in order.fields.entries)
          _InfoRow(
            label: order.fieldLabels[entry.key]?.of(context) ?? entry.key,
            value: entry.value,
          ),
      ],
      if (order.timeline.isNotEmpty) ...[
        _sectionTitle(l10n.orderTimeline),
        for (final step in order.timeline)
          _InfoRow(
            label: orderStatusLabel(context, step.status),
            value: step.at == null ? '' : Formatters.dateTime(context, step.at!),
          ),
      ],
      if (order.cancellable) ...[
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: state.cancelling ? null : () => _cancel(context),
          icon: state.cancelling
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.circleX, color: AppColors.danger),
          label: Text(l10n.orderCancel, style: const TextStyle(color: AppColors.dangerText)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppColors.dangerBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    ];
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );

  Widget _note(String text, {bool success = false}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: success ? const Color(0xffe3f7ec) : AppColors.tintSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        Expanded(
          child: SelectableText(
            value,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: AppColors.violet,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: context.l10n.commonCopy,
          icon: const Icon(LucideIcons.copy, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) showAppSnackBar(context, context.l10n.commonCopied);
          },
        ),
      ],
    ),
  );
}
