import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/core/utils/cursor_page.dart';
import 'package:rewardsapp/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rewardsapp/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:rewardsapp/features/orders/data/orders_repository_impl.dart';
import 'package:rewardsapp/features/orders/domain/order_entities.dart';
import 'package:rewardsapp/features/orders/presentation/redemption/redeem_cubit.dart';

import '../../helpers/fake_api.dart';

const _product = Product(
  id: 'p1',
  categoryId: 'c1',
  name: LocalizedText(en: '60 UC', ar: '٦٠ شدة'),
  pointsPrice: 400,
);

class _Catalog implements CatalogRepository {
  @override
  Future<Product> product(String id) async => _product;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Records every create() call and answers from a queue.
class _Orders implements OrdersRepository {
  _Orders(this.answers);

  final List<Object> answers;
  final keys = <String>[];
  final prices = <int>[];

  @override
  Future<OrderWithBalance> create({
    required String productId,
    required Map<String, String> fields,
    required int expectedPointsPrice,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    prices.add(expectedPointsPrice);
    final answer = answers.removeAt(0);
    if (answer is AppException) throw answer;
    return answer as OrderWithBalance;
  }

  @override
  Future<CursorPage<Order>> orders({OrderStatusGroup? group, String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<Order> order(String id) => throw UnimplementedError();

  @override
  Future<OrderWithBalance> cancel(String id) => throw UnimplementedError();
}

OrderWithBalance _success() {
  final json = fixture('order_created');
  return OrderWithBalance(
    order: parseOrder(Map<String, dynamic>.from(json['order'] as Map)),
    balance: 700,
  );
}

void main() {
  Future<RedeemCubit> ready(_Orders orders) async {
    final cubit = RedeemCubit(_Catalog(), orders, productId: 'p1');
    await cubit.loadProduct();
    expect(cubit.state.detailsLoaded, isTrue);
    return cubit;
  }

  test('a retry after a network failure reuses the idempotency key', () async {
    final orders = _Orders([const AppException(code: AppException.network), _success()]);
    final cubit = await ready(orders);

    await cubit.submit(const {'playerId': '1'});
    expect(cubit.state.status, RedeemStatus.failure);
    await cubit.submit(const {'playerId': '1'});

    expect(cubit.state.status, RedeemStatus.success);
    expect(cubit.state.result?.balance, 700);
    expect(orders.keys, hasLength(2));
    expect(orders.keys.first, orders.keys.last);
  });

  test('a 5xx keeps the key; a validation error does not', () async {
    final orders = _Orders([
      const AppException(code: 'INTERNAL_ERROR', statusCode: 500),
      const AppException(code: 'VALIDATION_FAILED', statusCode: 422),
      _success(),
    ]);
    final cubit = await ready(orders);

    await cubit.submit(const {});
    await cubit.submit(const {});
    await cubit.submit(const {});

    expect(orders.keys[0], orders.keys[1]);
    expect(orders.keys[2], isNot(orders.keys[1]));
  });

  test('PRICE_CHANGED shows the new price and confirms it with a new key', () async {
    final orders = _Orders([
      const AppException(code: 'PRICE_CHANGED', statusCode: 409, details: {'pointsPrice': 500}),
      _success(),
    ]);
    final cubit = await ready(orders);

    await cubit.submit(const {});
    expect(cubit.state.status, RedeemStatus.priceChanged);
    expect(cubit.state.product?.pointsPrice, 500);

    await cubit.submit(const {});
    expect(orders.prices, [400, 500]);
    expect(orders.keys[0], isNot(orders.keys[1]));
    expect(cubit.state.status, RedeemStatus.success);
  });
}
