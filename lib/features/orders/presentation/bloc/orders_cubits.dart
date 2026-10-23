import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/cursor_page.dart';
import '../../../../core/utils/paged_cubit.dart';
import '../../domain/order_entities.dart';
import '../../../../core/utils/safe_emit.dart';

/// Filter value of My Orders; `all` sends no `statusGroup`.
enum OrdersFilter { all, inProgress, completed, unsuccessful }

class OrdersCubit extends PagedCubit<Order, OrdersFilter> {
  OrdersCubit(this._repository) : super(OrdersFilter.all);

  final OrdersRepository _repository;

  @override
  Future<CursorPage<Order>> fetch(OrdersFilter filter, String? cursor) => _repository.orders(
    group: switch (filter) {
      OrdersFilter.all => null,
      OrdersFilter.inProgress => OrderStatusGroup.inProgress,
      OrdersFilter.completed => OrderStatusGroup.completed,
      OrdersFilter.unsuccessful => OrderStatusGroup.unsuccessful,
    },
    cursor: cursor,
  );
}

class OrderDetailsState extends Equatable {
  const OrderDetailsState({
    this.order,
    this.loading = true,
    this.cancelling = false,
    this.error,
    this.cancelled,
  });

  final Order? order;
  final bool loading;
  final bool cancelling;
  final Object? error;

  /// Set after a successful cancellation with the refunded balance.
  final int? cancelled;

  @override
  List<Object?> get props => [order, loading, cancelling, error, cancelled];
}

class OrderDetailsCubit extends Cubit<OrderDetailsState> with SafeEmit<OrderDetailsState> {
  OrderDetailsCubit(this._repository, this.orderId) : super(const OrderDetailsState());

  final OrdersRepository _repository;
  final String orderId;

  Future<void> load() async {
    emit(OrderDetailsState(order: state.order));
    try {
      emit(OrderDetailsState(order: await _repository.order(orderId), loading: false));
    } catch (error) {
      emit(OrderDetailsState(order: state.order, loading: false, error: error));
    }
  }

  /// `POST /orders/:id/cancel` (only while `PENDING`). The server refunds.
  Future<void> cancel() async {
    if (state.cancelling || !(state.order?.cancellable ?? false)) return;
    emit(OrderDetailsState(order: state.order, loading: false, cancelling: true));
    try {
      final result = await _repository.cancel(orderId);
      emit(OrderDetailsState(order: result.order, loading: false, cancelled: result.balance));
      // Reload for the full timeline and refund details.
      final fresh = await _repository.order(orderId);
      emit(OrderDetailsState(order: fresh, loading: false));
    } catch (error) {
      emit(OrderDetailsState(order: state.order, loading: false, error: error));
    }
  }
}
