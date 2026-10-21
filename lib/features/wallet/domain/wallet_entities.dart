import 'package:equatable/equatable.dart';

import '../../../core/utils/cursor_page.dart';

class Wallet extends Equatable {
  const Wallet({this.balance = 0, this.lifetimeEarned = 0, this.lifetimeSpent = 0, this.updatedAt});

  final int balance;
  final int lifetimeEarned;
  final int lifetimeSpent;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [balance, lifetimeEarned, lifetimeSpent, updatedAt];
}

enum WalletTransactionType {
  signupBonus,
  adReward,
  redemptionDebit,
  redemptionRefund,
  adminCredit,
  adminDebit,
  other,
}

WalletTransactionType walletTransactionTypeFrom(String? value) => switch (value) {
  'SIGNUP_BONUS' => WalletTransactionType.signupBonus,
  'AD_REWARD' => WalletTransactionType.adReward,
  'REDEMPTION_DEBIT' => WalletTransactionType.redemptionDebit,
  'REDEMPTION_REFUND' => WalletTransactionType.redemptionRefund,
  'ADMIN_CREDIT' => WalletTransactionType.adminCredit,
  'ADMIN_DEBIT' => WalletTransactionType.adminDebit,
  _ => WalletTransactionType.other,
};

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.note,
    this.createdAt,
  });

  final String id;
  final WalletTransactionType type;

  /// Signed: debits are negative.
  final int amount;
  final int balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? note;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, type, amount, balanceAfter, referenceId, createdAt];
}

abstract interface class WalletRepository {
  Future<Wallet> wallet();

  Future<CursorPage<WalletTransaction>> transactions({String? cursor});
}
