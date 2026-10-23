import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/cursor_page.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/paged_cubit.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/wallet_entities.dart';

class TransactionsCubit extends PagedCubit<WalletTransaction, void> {
  TransactionsCubit(this._repository) : super(null);

  final WalletRepository _repository;

  @override
  Future<CursorPage<WalletTransaction>> fetch(void filter, String? cursor) =>
      _repository.transactions(cursor: cursor);
}

/// Points history: `GET /wallet/transactions`.
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TransactionsCubit(sl())..refresh(),
    child: Builder(
      builder: (context) {
        final l10n = context.l10n;
        final cubit = context.read<TransactionsCubit>();
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: BlocBuilder<TransactionsCubit, PagedListState<WalletTransaction, void>>(
              builder: (context, state) => PagedListView<WalletTransaction, void>(
                state: state,
                onRefresh: cubit.refresh,
                onLoadMore: cubit.loadMore,
                emptyMessage: l10n.transactionsEmpty,
                skeletonRow: const SkeletonRow(lines: [150, 100, 80], trailingWidth: 56),
                header: [
                  SecondaryHeader(
                    title: l10n.transactionsTitle,
                    subtitle: l10n.transactionsSubtitle,
                  ),
                  const SizedBox(height: 20),
                ],
                itemBuilder: (context, item) => _TransactionTile(item: item),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final WalletTransaction item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final positive = item.amount >= 0;
    final title = switch (item.type) {
      WalletTransactionType.signupBonus => l10n.txSignupBonus,
      WalletTransactionType.adReward => l10n.txAdReward,
      WalletTransactionType.redemptionDebit => l10n.txRedemption,
      WalletTransactionType.redemptionRefund => l10n.txRefund,
      WalletTransactionType.adminCredit => l10n.txAdminCredit,
      WalletTransactionType.adminDebit => l10n.txAdminDebit,
      WalletTransactionType.other => l10n.txOther,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.listCard,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: positive ? const Color(0xffe3f7ec) : AppColors.tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              positive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              color: positive ? AppColors.success : AppColors.violet,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.note?.isNotEmpty ?? false)
                  Text(
                    item.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                if (item.createdAt != null)
                  Text(
                    Formatters.dateTime(context, item.createdAt!),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${positive ? '+' : '−'}${Formatters.points(item.amount.abs())}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: positive ? AppColors.success : AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l10n.txBalanceAfter(Formatters.points(item.balanceAfter)),
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
