import '../../../core/constants/app_constants.dart';
import '../../../core/localization/localized_text.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../../catalog/domain/entities/catalog_entities.dart';
import '../domain/order_entities.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<OrderWithBalance> create({
    required String productId,
    required Map<String, String> fields,
    required int expectedPointsPrice,
    required String idempotencyKey,
  }) async => _withBalance(
    await _api.post(
      '/orders',
      headers: {'Idempotency-Key': idempotencyKey},
      body: {'productId': productId, 'fields': fields, 'expectedPointsPrice': expectedPointsPrice},
    ),
  );

  @override
  Future<CursorPage<Order>> orders({OrderStatusGroup? group, String? cursor}) async =>
      CursorPage.fromJson(
        await _api.get(
          '/orders',
          query: {'statusGroup': group?.apiValue, 'cursor': cursor, 'limit': AppConstants.pageSize},
        ),
        parseOrder,
      );

  @override
  Future<Order> order(String id) async =>
      parseOrder(Map<String, dynamic>.from((await _api.get('/orders/$id'))['order'] as Map));

  @override
  Future<OrderWithBalance> cancel(String id) async =>
      _withBalance(await _api.post('/orders/$id/cancel'));

  OrderWithBalance _withBalance(Map<String, dynamic> json) => OrderWithBalance(
    order: parseOrder(Map<String, dynamic>.from(json['order'] as Map)),
    balance: parseInt(json['balance']),
  );
}

Order parseOrder(Map<String, dynamic> json) {
  final product = json['product'] is Map ? json['product'] as Map : const {};
  final category = product['category'] is Map ? product['category'] as Map : const {};
  final labels = <String, LocalizedText>{
    for (final field in product['fields'] is List ? product['fields'] as List : const [])
      if (field is Map) '${field['key']}': LocalizedText.fromJson(field['label']),
  };
  final values = json['fields'] is Map ? json['fields'] as Map : const {};
  return Order(
    id: '${json['id']}',
    orderNumber: json['orderNumber'] as String? ?? '',
    status: orderStatusFrom(json['status'] as String?),
    pointsCost: parseInt(json['pointsCost']),
    productId: product['id'] as String?,
    productName: LocalizedText.fromJson(product['name']),
    productImageUrl: product['imageUrl'] as String?,
    categoryName: LocalizedText.fromJson(category['name']),
    categoryKind: categoryKindFrom(category['kind'] as String?),
    fieldLabels: labels,
    fields: {for (final entry in values.entries) '${entry.key}': '${entry.value}'},
    statusReason: json['statusReason'] as String?,
    trackingInfo: json['trackingInfo'] as String?,
    deliveredCode: json['deliveredCode'] as String?,
    timeline: parseList(
      json['timeline'],
      (item) => OrderTimelineEntry(
        status: orderStatusFrom(item['status'] as String?),
        reason: item['reason'] as String?,
        at: parseDate(item['at']),
      ),
    ),
    createdAt: parseDate(json['createdAt']),
    updatedAt: parseDate(json['updatedAt']),
  );
}
