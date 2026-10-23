import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/wallet_entities.dart';
import '../../../../core/utils/safe_emit.dart';

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
class WalletCubit extends Cubit<WalletState> with SafeEmit<WalletState> {
  WalletCubit(this._repository) : super(const WalletState());

  final WalletRepository _repository;
  Future<void>? _inFlight;

  /// Bumped by [clear] (sign-out): answers of requests started for an
  /// earlier session are dropped, so one account never sees another's
  /// balance.
  int _generation = 0;

  Future<void> load() {
    final generation = _generation;
    return _inFlight ??= _load(generation).whenComplete(() {
      if (generation == _generation) _inFlight = null;
    });
  }

  Future<void> _load(int generation) async {
    bool current() => !isClosed && generation == _generation;
    emit(WalletState(wallet: state.wallet, loading: true));
    try {
      final wallet = await _repository.wallet();
      if (current()) emit(WalletState(wallet: wallet));
    } catch (error) {
      if (current()) emit(WalletState(wallet: state.wallet, error: error));
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

  void clear() {
    _generation++;
    _inFlight = null;
    emit(const WalletState());
  }
}
