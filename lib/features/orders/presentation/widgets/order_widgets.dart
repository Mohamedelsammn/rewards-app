import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/headers.dart';
import '../../domain/order_entities.dart';

String orderStatusLabel(BuildContext context, OrderStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    OrderStatus.pending => l10n.orderPending,
    OrderStatus.processing => l10n.orderProcessing,
    OrderStatus.shipped => l10n.orderShipped,
    OrderStatus.delivered => l10n.orderDelivered,
    OrderStatus.completed => l10n.orderCompleted,
    OrderStatus.rejected => l10n.orderRejected,
    OrderStatus.cancelled => l10n.orderCancelled,
    OrderStatus.failed => l10n.orderFailed,
  };
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({required this.status, super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      OrderStatus.completed ||
      OrderStatus.delivered => (const Color(0xffe3f7ec), const Color(0xff0a8f4a)),
      _ when status.isUnsuccessful => (AppColors.dangerSurface, AppColors.dangerText),
      _ => (AppColors.tintSoft, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(
        orderStatusLabel(context, status),
        style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Order row of My Orders.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, required this.onTap, super.key});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.listCard,
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AppImage(
                url: order.productImageUrl,
                fit: BoxFit.contain,
                placeholderIcon: LucideIcons.shoppingBag,
                placeholderColors: const [AppColors.tint, AppColors.tint],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.productName.of(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.pointsAmount(Formatters.points(order.pointsCost)),
                      style: const TextStyle(
                        color: AppColors.violet,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.orderNumber(order.orderNumber),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 7),
                OrderStatusChip(status: order.status),
              ],
            ),
          ),
          const SizedBox(width: 7),
          const CircleArrow(),
        ],
      ),
    ),
  );
}
