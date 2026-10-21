import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/wallet_entities.dart';

class WalletState extends Equatable {
  const WalletState({this.wallet, this.loading = false, this.error});

  final Wallet? wallet;
  final bool loading;
  final Object? error;

  int get balance => wallet?.balance ?? 0;

  @override
  List<Object?> get props => [wallet, loading, error];
}

/// App-scoped balance. `GET /wallet` is the only balance source; responses
/// of orders, cancellations and ad claims update it via [setBalance] and a
/// background refresh. The device never computes balances.
class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repository) : super(const WalletState());

  final WalletRepository _repository;
  Future<void>? _inFlight;

  Future<void> load() => _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    emit(WalletState(wallet: state.wallet, loading: true));
    try {
      emit(WalletState(wallet: await _repository.wallet()));
    } catch (error) {
      emit(WalletState(wallet: state.wallet, error: error));
    }
  }

  /// Applies a server-reported balance immediately, then re-syncs totals.
  void setBalance(int balance) {
    final current = state.wallet;
    emit(
      WalletState(
        wallet: Wallet(
          balance: balance,
          lifetimeEarned: current?.lifetimeEarned ?? 0,
          lifetimeSpent: current?.lifetimeSpent ?? 0,
          updatedAt: DateTime.now(),
        ),
      ),
    );
    load();
  }

  void clear() => emit(const WalletState());
}
