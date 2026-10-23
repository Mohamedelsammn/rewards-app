import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../app_config/presentation/app_config_cubit.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../wallet/presentation/bloc/wallet_cubit.dart';
import '../../../wallet/presentation/widgets/insufficient_points_dialog.dart';
import '../../domain/order_entities.dart';
import 'redeem_cubit.dart';
import 'redemption_sheet.dart';

/// Opens the redemption sheet for [product] and reports the outcome. The
/// wallet balance shown afterwards is the one returned by the server.
Future<void> startRedemption(
  BuildContext context, {
  required Product product,
  RewardCategory? category,
  VoidCallback? onFinished,
}) async {
  final l10n = context.l10n;
  final wallet = context.read<WalletCubit>();
  final session = context.read<SessionCubit>();
  if (wallet.state.balance < product.pointsPrice) {
    // No link to rewarded ads here: ad rewards are tickets and can never
    // pay for a redemption (AdMob rewarded-ad policy).
    await showInsufficientPointsDialog(
      context,
      balance: wallet.state.balance,
      required: product.pointsPrice,
    );
    return;
  }
  final result = await showModalBottomSheet<OrderWithBalance>(
    context: context,
    // Above the shell's bottom navigation bar.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) =>
          RedeemCubit(sl(), sl(), productId: product.id, preview: product)..loadProduct(),
      child: BlocProvider.value(
        value: wallet,
        child: RedemptionSheet(category: category),
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  wallet.setBalance(result.balance);
  final stats = session.state.user?.stats;
  session.updateStats(points: result.balance, orders: (stats?.orders ?? 0) + 1);
  onFinished?.call();
  final viewOrders = await showAppConfirmDialog(
    context,
    icon: Icons.check_circle_outline,
    title: l10n.redeemSuccessTitle,
    message: l10n.redeemSuccessBody(Formatters.points(result.order.pointsCost)),
    confirmLabel: l10n.redeemViewOrders,
  );
  if (viewOrders && context.mounted) context.push(Routes.order(result.order.id));
}
