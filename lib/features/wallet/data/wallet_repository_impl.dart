import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/cursor_page.dart';
import '../domain/wallet_entities.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Wallet> wallet() async =>
      parseWallet(Map<String, dynamic>.from((await _api.get('/wallet'))['wallet'] as Map));

  @override
  Future<CursorPage<WalletTransaction>> transactions({String? cursor}) async => CursorPage.fromJson(
    await _api.get(
      '/wallet/transactions',
      query: {'cursor': cursor, 'limit': AppConstants.pageSize},
    ),
    parseWalletTransaction,
  );
}

Wallet parseWallet(Map<String, dynamic> json) => Wallet(
  balance: parseInt(json['balance']),
  lifetimeEarned: parseInt(json['lifetimeEarned']),
  lifetimeSpent: parseInt(json['lifetimeSpent']),
  updatedAt: parseDate(json['updatedAt']),
);

WalletTransaction parseWalletTransaction(Map<String, dynamic> json) {
  final reference = json['reference'] is Map ? json['reference'] as Map : const {};
  return WalletTransaction(
    id: '${json['id']}',
    type: walletTransactionTypeFrom(json['type'] as String?),
    amount: parseInt(json['amount']),
    balanceAfter: parseInt(json['balanceAfter']),
    referenceType: reference['type'] as String?,
    referenceId: reference['id'] as String?,
    note: json['note'] as String?,
    createdAt: parseDate(json['createdAt']),
  );
}
