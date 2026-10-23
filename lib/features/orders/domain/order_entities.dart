import 'package:equatable/equatable.dart';

import '../../../core/localization/localized_text.dart';
import '../../../core/utils/cursor_page.dart';
import '../../catalog/domain/entities/catalog_entities.dart';

enum OrderStatus { pending, processing, shipped, delivered, completed, rejected, cancelled, failed }

OrderStatus orderStatusFrom(String? value) => switch (value) {
  'PROCESSING' => OrderStatus.processing,
  'SHIPPED' => OrderStatus.shipped,
  'DELIVERED' => OrderStatus.delivered,
  'COMPLETED' => OrderStatus.completed,
  'REJECTED' => OrderStatus.rejected,
  'CANCELLED' => OrderStatus.cancelled,
  'FAILED' => OrderStatus.failed,
  _ => OrderStatus.pending,
};

extension OrderStatusX on OrderStatus {
  bool get isUnsuccessful =>
      this == OrderStatus.rejected || this == OrderStatus.cancelled || this == OrderStatus.failed;
}

/// `statusGroup` filter of `GET /orders`; `null` lists every order.
enum OrderStatusGroup {
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  unsuccessful('UNSUCCESSFUL');

  const OrderStatusGroup(this.apiValue);

  final String apiValue;
}

class OrderTimelineEntry extends Equatable {
  const OrderTimelineEntry({required this.status, this.reason, this.at});

  final OrderStatus status;
  final String? reason;
  final DateTime? at;

  @override
  List<Object?> get props => [status, reason, at];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.pointsCost,
    required this.productName,
    this.productId,
    this.productImageUrl,
    this.categoryId,
    this.categoryName = const LocalizedText(),
    this.categoryKind = CategoryKind.other,
    this.fieldLabels = const {},
    this.fields = const {},
    this.statusReason,
    this.trackingInfo,
    this.deliveredCode,
    this.timeline = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;

  /// Points actually deducted when the order was created (frozen).
  final int pointsCost;
  final String? productId;
  final LocalizedText productName;
  final String? productImageUrl;

  /// `product.category.id`: "Redeem again" opens this category.
  final String? categoryId;
  final LocalizedText categoryName;
  final CategoryKind categoryKind;
  final Map<String, LocalizedText> fieldLabels;

  /// Submitted fulfilment values (order details only).
  final Map<String, String> fields;
  final String? statusReason;
  final String? trackingInfo;
  final String? deliveredCode;
  final List<OrderTimelineEntry> timeline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get cancellable => status == OrderStatus.pending;

  @override
  List<Object?> get props => [id, status, pointsCost, deliveredCode, timeline, updatedAt];
}

/// Result of operations that change the wallet: the order plus the balance
/// right after the operation.
class OrderWithBalance extends Equatable {
  const OrderWithBalance({required this.order, required this.balance});

  final Order order;
  final int balance;

  @override
  List<Object?> get props => [order, balance];
}

abstract interface class OrdersRepository {
  /// `POST /orders`. [idempotencyKey] must be reused for retries of the same
  /// confirmation and replaced after a price change.
  Future<OrderWithBalance> create({
    required String productId,
    required Map<String, String> fields,
    required int expectedPointsPrice,
    required String idempotencyKey,
  });

  Future<CursorPage<Order>> orders({OrderStatusGroup? group, String? cursor});

  Future<Order> order(String id);

  Future<OrderWithBalance> cancel(String id);
}
