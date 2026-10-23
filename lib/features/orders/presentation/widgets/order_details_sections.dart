import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/order_entities.dart';
import 'order_widgets.dart';

/// Sections of Order Details, after the "Order Details" reference: product
/// hero, cost + status, order id, account details and the status history.

/// Semantic colors and icon of an order status.
({Color foreground, Color background, IconData icon}) orderStatusStyle(OrderStatus status) =>
    switch (status) {
      OrderStatus.pending => (
        foreground: const Color(0xffa95f00),
        background: const Color(0xfffff2d9),
        icon: LucideIcons.clock,
      ),
      OrderStatus.processing => (
        foreground: AppColors.violet,
        background: AppColors.tint,
        icon: LucideIcons.loaderCircle,
      ),
      OrderStatus.shipped => (
        foreground: const Color(0xff1e6fe8),
        background: const Color(0xffe6f0ff),
        icon: LucideIcons.truck,
      ),
      OrderStatus.delivered => (
        foreground: const Color(0xff0e8a82),
        background: const Color(0xffdff6f3),
        icon: LucideIcons.packageCheck,
      ),
      OrderStatus.completed => (
        foreground: const Color(0xff0a8f4a),
        background: const Color(0xffe3f7ec),
        icon: LucideIcons.check,
      ),
      OrderStatus.rejected || OrderStatus.cancelled => (
        foreground: AppColors.dangerText,
        background: AppColors.dangerSurface,
        icon: LucideIcons.x,
      ),
      OrderStatus.failed => (
        foreground: AppColors.dangerText,
        background: AppColors.dangerSurface,
        icon: LucideIcons.triangleAlert,
      ),
    };

String orderStepDescription(BuildContext context, OrderStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    OrderStatus.pending => l10n.orderStepPending,
    OrderStatus.processing => l10n.orderStepProcessing,
    OrderStatus.shipped => l10n.orderStepShipped,
    OrderStatus.delivered => l10n.orderStepDelivered,
    OrderStatus.completed => l10n.orderStepCompleted,
    OrderStatus.rejected => l10n.orderStepRejected,
    OrderStatus.cancelled => l10n.orderStepCancelled,
    OrderStatus.failed => l10n.orderStepFailed,
  };
}

const _cardRadius = 24.0;

BoxDecoration _card() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(_cardRadius),
  boxShadow: AppShadows.listCard,
);

Future<void> _copy(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) showAppSnackBar(context, context.l10n.commonCopied);
}

/// Square icon tile used at the start of the summary cards.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color, required this.background});

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
    child: Icon(icon, color: color, size: 22),
  );
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value, this.background = AppColors.tint});

  final String value;
  final Color background;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _copy(context, value),
      child: Tooltip(
        message: context.l10n.commonCopy,
        child: const SizedBox.square(
          dimension: 44,
          child: Icon(LucideIcons.copy, size: 19, color: AppColors.ink),
        ),
      ),
    ),
  );
}

/// Dark product banner: the order's own product image and category.
class OrderHero extends StatelessWidget {
  const OrderHero({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final category = order.categoryName.of(context);
    return Container(
      key: const ValueKey('order-hero'),
      constraints: const BoxConstraints(minHeight: 104),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardRadius),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [Color(0xff0d1433), Color(0xff1d2552)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // A soft echo of the product art on the trailing side.
          if (order.productImageUrl != null)
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              width: 220,
              child: ExcludeSemantics(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  // Fades in from the start edge: no hard seam.
                  shaderCallback: (bounds) => LinearGradient(
                    begin: AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
                    end: AlignmentDirectional.centerEnd.resolve(Directionality.of(context)),
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: .32),
                    ],
                  ).createShader(bounds),
                  child: AppImage(url: order.productImageUrl, fit: BoxFit.cover),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox.square(
                    dimension: 76,
                    child: AppImage(
                      url: order.productImageUrl,
                      placeholderIcon: LucideIcons.shoppingBag,
                      radius: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName.of(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cost (points actually deducted) and the current status.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = orderStatusStyle(order.status);
    const label = TextStyle(color: AppColors.muted, fontSize: 14);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const _IconTile(
                    icon: LucideIcons.coins,
                    color: Color(0xffe8a10c),
                    background: Color(0xfffff4da),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.orderCost, style: label),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            l10n.pointsAmount(Formatters.points(order.pointsCost)),
                            style: const TextStyle(
                              color: AppColors.violet,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 20, thickness: 1, color: AppColors.divider),
            Expanded(
              child: Row(
                children: [
                  _IconTile(
                    icon: style.icon,
                    color: style.foreground,
                    background: style.background,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.orderStatusTitle, style: label),
                        const SizedBox(height: 4),
                        Container(
                          key: ValueKey('order-status-${order.status.name}'),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: style.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            orderStatusLabel(context, order.status),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: style.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled value with a copy button (order id, delivery code, tracking).
class OrderValueCard extends StatelessWidget {
  const OrderValueCard({
    required this.icon,
    required this.label,
    required this.value,
    this.display,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Shown instead of [value] (e.g. `#CR-…`); [value] is what is copied.
  final String? display;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _card(),
    child: Row(
      children: [
        _IconTile(icon: icon, color: AppColors.violet, background: AppColors.tint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
              const SizedBox(height: 2),
              SelectableText(
                display ?? value,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CopyButton(value: value),
      ],
    ),
  );
}

/// Card with an icon + title header and a body.
class OrderSectionCard extends StatelessWidget {
  const OrderSectionCard({required this.icon, required this.title, required this.child, super.key});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.tint, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.violet, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

/// The submitted fulfilment fields, with the product's own labels.
class OrderAccountDetails extends StatelessWidget {
  const OrderAccountDetails({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) => OrderSectionCard(
    key: const ValueKey('order-account-details'),
    icon: LucideIcons.userRound,
    title: context.l10n.orderAccountDetails,
    child: Column(
      children: [
        for (final (i, entry) in order.fields.entries.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          _FieldRow(
            label: order.fieldLabels[entry.key]?.of(context) ?? entry.key,
            value: entry.value,
          ),
        ],
      ],
    ),
  );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  Uri? get _link {
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasAuthority && (uri.scheme == 'https' || uri.scheme == 'http')
        ? uri
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 10, 12),
      decoration: BoxDecoration(color: AppColors.tintSoft, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
                const SizedBox(height: 2),
                // Identifiers and URLs stay left-to-right in Arabic too.
                SelectableText(
                  value,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (link != null) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => launchUrl(link, mode: LaunchMode.externalApplication),
                child: Tooltip(
                  message: context.l10n.orderOpenLink,
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(LucideIcons.externalLink, size: 19, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          _CopyButton(value: value, background: Colors.white),
        ],
      ),
    );
  }
}

/// The recorded status changes (`order.timeline`), newest first. Only what
/// the server recorded is shown: no future or assumed steps, no invented
/// times. Without history, the current status alone is shown.
class OrderStatusHistory extends StatelessWidget {
  const OrderStatusHistory({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final events = [...order.timeline];
    // Newest first; the server sends them in order of occurrence.
    if (events.every((e) => e.at != null)) {
      events.sort((a, b) => b.at!.compareTo(a.at!));
    } else {
      events.setAll(0, events.reversed.toList());
    }
    final steps = events.isEmpty
        ? [OrderTimelineEntry(status: order.status, reason: order.statusReason)]
        : events;
    return OrderSectionCard(
      key: const ValueKey('order-status-history'),
      icon: LucideIcons.history,
      title: context.l10n.orderStatusHistory,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 16, 16, 4),
        decoration: BoxDecoration(
          color: AppColors.tintSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            for (final (i, step) in steps.indexed)
              _TimelineRow(step: step, latest: i == 0, last: i == steps.length - 1),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.latest, required this.last});

  final OrderTimelineEntry step;

  /// The newest event: the order's current state.
  final bool latest;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final failed = step.status.isUnsuccessful;
    // The newest step of an order still in progress is "current", not done.
    final current = latest && !failed && step.status != OrderStatus.completed;
    final Widget indicator;
    if (failed) {
      indicator = _Dot(
        color: AppColors.danger,
        child: Icon(orderStatusStyle(step.status).icon, size: 16, color: Colors.white),
      );
    } else if (current) {
      indicator = Container(
        key: const ValueKey('timeline-current'),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.violet, width: 3),
        ),
        alignment: Alignment.center,
        child: const _Dot(color: AppColors.violet, size: 10),
      );
    } else {
      indicator = const _Dot(
        color: AppColors.violet,
        child: Icon(LucideIcons.check, size: 16, color: Colors.white),
      );
    }
    final at = step.at;
    final reason = step.reason;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                indicator,
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.violet.withValues(alpha: .35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full width so the time sits at the end (wraps below when tight).
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          orderStatusLabel(context, step.status),
                          style: TextStyle(
                            color: failed ? AppColors.dangerText : AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (at != null)
                          Text(
                            Formatters.dateTime(context, at.toLocal()),
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    orderStepDescription(context, step.status),
                    style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.35),
                  ),
                  if (reason != null && reason.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${context.l10n.orderReason}: $reason',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.child, this.size = 30});

  final Color color;
  final Widget? child;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: child,
  );
}
