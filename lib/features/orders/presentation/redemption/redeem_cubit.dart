import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_exception.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../domain/order_entities.dart';
import '../../../../core/utils/safe_emit.dart';

enum RedeemStatus { loadingProduct, ready, submitting, priceChanged, success, failure }

class RedeemState extends Equatable {
  const RedeemState({
    this.status = RedeemStatus.loadingProduct,
    this.product,
    this.result,
    this.error,
    this.detailsLoaded = false,
  });

  final RedeemStatus status;

  /// True once `GET /products/:id` returned the fulfilment fields.
  final bool detailsLoaded;

  /// Product with its fulfilment fields and the price the user confirms.
  final Product? product;
  final OrderWithBalance? result;
  final Object? error;

  Map<String, String> get fieldErrors =>
      error is AppException ? (error as AppException).fieldErrors : const {};

  RedeemState copyWith({
    RedeemStatus? status,
    Product? product,
    OrderWithBalance? result,
    Object? error,
    bool? detailsLoaded,
  }) => RedeemState(
    status: status ?? this.status,
    product: product ?? this.product,
    result: result ?? this.result,
    error: error,
    detailsLoaded: detailsLoaded ?? this.detailsLoaded,
  );

  @override
  List<Object?> get props => [status, product, result, error, detailsLoaded];
}

/// Redemption of one product: loads its fields, creates the order with an
/// idempotency key and handles `PRICE_CHANGED`. Never touches balances
/// locally; the server's `balance` is reported back through [RedeemState.result].
class RedeemCubit extends Cubit<RedeemState> with SafeEmit<RedeemState> {
  RedeemCubit(this._catalog, this._orders, {required this.productId, Product? preview})
    : super(RedeemState(product: preview));

  final CatalogRepository _catalog;
  final OrdersRepository _orders;
  final String productId;

  /// Code of the refusal to send a changed order while an earlier attempt's
  /// outcome is unknown (see [submit]).
  static const previousAttemptUncertain = 'PREVIOUS_ATTEMPT_UNCERTAIN';

  /// The attempt whose outcome is unknown (network error, timeout, 5xx,
  /// REQUEST_IN_PROGRESS): its key and exact payload. A retry must send
  /// both unchanged so the server replays it instead of creating a second
  /// order; the same key with a different body would be refused (409).
  _Attempt? _uncertain;

  Future<void> loadProduct() async {
    emit(state.copyWith(status: RedeemStatus.loadingProduct));
    try {
      emit(
        RedeemState(
          status: RedeemStatus.ready,
          product: await _catalog.product(productId),
          detailsLoaded: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: RedeemStatus.failure, error: error));
    }
  }

  Future<void> submit(Map<String, String> fields) async {
    final product = state.product;
    if (product == null || state.status == RedeemStatus.submitting) return;
    final payload = _Attempt(
      key: const Uuid().v4(),
      productId: product.id,
      fields: Map.unmodifiable(fields),
      price: product.pointsPrice,
    );
    final uncertain = _uncertain;
    final _Attempt attempt;
    if (uncertain == null) {
      attempt = payload;
    } else if (uncertain.samePayload(payload)) {
      attempt = uncertain; // Identical retry: same key, same body.
    } else {
      // Changed after an unknown outcome: the first order may exist. Don't
      // send it under the old key (409) or silently under a new one (a
      // possible duplicate); ask the user to check first. Their next confirm
      // is an explicit new attempt.
      _uncertain = null;
      emit(
        state.copyWith(
          status: RedeemStatus.failure,
          error: const AppException(code: previousAttemptUncertain),
        ),
      );
      return;
    }
    emit(state.copyWith(status: RedeemStatus.submitting));
    try {
      final result = await _orders.create(
        productId: attempt.productId,
        fields: attempt.fields,
        expectedPointsPrice: attempt.price,
        idempotencyKey: attempt.key,
      );
      _uncertain = null;
      emit(state.copyWith(status: RedeemStatus.success, result: result));
    } on AppException catch (error) {
      if (error.code == 'PRICE_CHANGED') {
        // A new price is a new decision: the next confirmation uses a new key.
        _uncertain = null;
        final newPrice = error.details['pointsPrice'];
        emit(
          state.copyWith(
            status: RedeemStatus.priceChanged,
            product: newPrice is num ? _withPrice(product, newPrice.toInt()) : product,
            error: error,
          ),
        );
        return;
      }
      // Keep the attempt only when the outcome is unknown, so a retry
      // replays it instead of creating a second order.
      final unknown =
          error.isConnectivity ||
          (error.statusCode ?? 0) >= 500 ||
          error.code == 'REQUEST_IN_PROGRESS';
      _uncertain = unknown ? attempt : null;
      emit(state.copyWith(status: RedeemStatus.failure, error: error));
    } catch (error) {
      // Unexpected (e.g. an unreadable response): the order may exist.
      _uncertain = attempt;
      emit(state.copyWith(status: RedeemStatus.failure, error: error));
    }
  }

  void acknowledgeError() {
    if (state.product != null) emit(state.copyWith(status: RedeemStatus.ready));
  }

  Product _withPrice(Product product, int price) => Product(
    id: product.id,
    categoryId: product.categoryId,
    groupId: product.groupId,
    name: product.name,
    description: product.description,
    deliveryNote: product.deliveryNote,
    imageUrl: product.imageUrl,
    pointsPrice: price,
    priceVersion: product.priceVersion + 1,
    inStock: product.inStock,
    stock: product.stock,
    featured: product.featured,
    fields: product.fields,
  );
}

/// One order request: its idempotency key and exact body.
class _Attempt {
  const _Attempt({
    required this.key,
    required this.productId,
    required this.fields,
    required this.price,
  });

  final String key;
  final String productId;
  final Map<String, String> fields;
  final int price;

  bool samePayload(_Attempt other) =>
      productId == other.productId &&
      price == other.price &&
      fields.length == other.fields.length &&
      fields.entries.every((e) => other.fields[e.key] == e.value);
}
