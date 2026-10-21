import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_exception.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../domain/order_entities.dart';

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
class RedeemCubit extends Cubit<RedeemState> {
  RedeemCubit(this._catalog, this._orders, {required this.productId, Product? preview})
    : super(RedeemState(product: preview));

  final CatalogRepository _catalog;
  final OrdersRepository _orders;
  final String productId;

  /// One key per confirmation attempt; reused for retries of that attempt.
  String? _idempotencyKey;

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
    _idempotencyKey ??= const Uuid().v4();
    emit(state.copyWith(status: RedeemStatus.submitting));
    try {
      final result = await _orders.create(
        productId: product.id,
        fields: fields,
        expectedPointsPrice: product.pointsPrice,
        idempotencyKey: _idempotencyKey!,
      );
      _idempotencyKey = null;
      emit(state.copyWith(status: RedeemStatus.success, result: result));
    } on AppException catch (error) {
      if (error.code == 'PRICE_CHANGED') {
        // A new price is a new decision: the next confirmation uses a new key.
        _idempotencyKey = null;
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
      // Keep the key only when the outcome is unknown (network/timeout/5xx),
      // so a retry replays instead of creating a second order.
      if (!error.isConnectivity && (error.statusCode ?? 0) < 500) _idempotencyKey = null;
      emit(state.copyWith(status: RedeemStatus.failure, error: error));
    } catch (error) {
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
