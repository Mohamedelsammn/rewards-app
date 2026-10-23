import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/error_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../catalog/presentation/widgets/category_visuals.dart';
import '../../../wallet/presentation/bloc/wallet_cubit.dart';
import 'fulfillment_field_input.dart';
import 'redeem_cubit.dart';

/// Bottom sheet: product summary, balance before/after, the product's
/// fulfilment fields and the confirm button. Pops with the result on success.
class RedemptionSheet extends StatefulWidget {
  const RedemptionSheet({this.category, super.key});

  final RewardCategory? category;

  @override
  State<RedemptionSheet> createState() => _RedemptionSheetState();
}

class _RedemptionSheetState extends State<RedemptionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};

  TextEditingController _controller(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Reviewing the entered account details is shown once per confirm.
  bool _reviewing = false;

  /// Products of these kinds are delivered to the user's own account (game
  /// ID, social profile), so they cannot be fulfilled without a required
  /// field defined by the admin (`product.fields`).
  static const _accountKinds = {CategoryKind.game, CategoryKind.socialMedia};

  bool _missingAccountFields(Product product) =>
      _accountKinds.contains(widget.category?.kind) && !product.fields.any((f) => f.required);

  Map<String, String> _values(Product product) => {
    for (final field in product.fields)
      if (_controller(field.key).text.trim().isNotEmpty)
        field.key: _controller(field.key).text.trim(),
  };

  /// Validates the form; with account fields, shows the entered values for a
  /// last check (Edit goes back to the form); then creates the order.
  Future<void> _confirm(Product product, {bool review = true}) async {
    if (_reviewing || _missingAccountFields(product)) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final values = _values(product);
    if (review && product.fields.isNotEmpty) {
      _reviewing = true;
      final l10n = context.l10n;
      final cost = l10n.pointsAmount(Formatters.points(product.pointsPrice));
      final lines = [
        for (final field in product.fields)
          if (values[field.key] case final value?) '${field.label.of(context)}: $value',
      ];
      final confirmed = await showAppConfirmDialog(
        context,
        icon: Icons.fact_check_outlined,
        title: l10n.redeemReviewTitle,
        message: '${l10n.redeemReviewBody(product.name.of(context), cost)}\n\n${lines.join('\n')}',
        confirmLabel: l10n.redeemConfirm,
        cancelLabel: l10n.redeemReviewEdit,
      );
      _reviewing = false;
      if (!confirmed || !mounted) return;
    }
    if (!mounted) return;
    context.read<RedeemCubit>().submit(values);
  }

  Future<void> _onState(BuildContext context, RedeemState state) async {
    final l10n = context.l10n;
    final cubit = context.read<RedeemCubit>();
    if (state.status == RedeemStatus.success) {
      Navigator.of(context).pop(state.result);
    } else if (state.status == RedeemStatus.priceChanged && state.product != null) {
      final price = Formatters.points(state.product!.pointsPrice);
      final accept = await showAppConfirmDialog(
        context,
        icon: Icons.sell_outlined,
        title: l10n.redeemPriceChangedTitle,
        message: l10n.redeemPriceChangedBody(price),
        confirmLabel: l10n.redeemConfirmNewPrice(price),
      );
      if (!context.mounted) return;
      if (accept) {
        // The details were reviewed already; only the price changed.
        await _confirm(state.product!, review: false);
      } else {
        cubit.acknowledgeError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final motion = MediaQuery.disableAnimationsOf(context);
    return AnimatedPadding(
      duration: motion ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
        decoration: const BoxDecoration(
          color: AppColors.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: AppShadows.redemptionSheet,
        ),
        child: SafeArea(
          top: false,
          child: BlocConsumer<RedeemCubit, RedeemState>(
            listener: _onState,
            builder: (context, state) {
              final product = state.product;
              final balance = context.select<WalletCubit, int>((cubit) => cubit.state.balance);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.handle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.redeemTitle,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (product != null) ..._details(context, product, balance, state),
                      if (state.status == RedeemStatus.loadingProduct)
                        // The fulfilment fields arrive with the product.
                        const Skeleton(
                          child: Column(
                            key: ValueKey('redeem-fields-skeleton'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLine(width: 120, height: 13),
                              SizedBox(height: 10),
                              SkeletonBox(height: 56, radius: 22),
                              SizedBox(height: 16),
                              SkeletonLine(width: 100, height: 13),
                              SizedBox(height: 10),
                              SkeletonBox(height: 56, radius: 22),
                            ],
                          ),
                        ),
                      if (state.status == RedeemStatus.failure && state.fieldErrors.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: !state.detailsLoaded
                              ? ErrorStateView(
                                  error: state.error!,
                                  onRetry: context.read<RedeemCubit>().loadProduct,
                                )
                              : Text(
                                  errorMessage(context, state.error!),
                                  style: const TextStyle(color: AppColors.error),
                                ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _details(BuildContext context, Product product, int balance, RedeemState state) {
    final l10n = context.l10n;
    final busy = state.status == RedeemStatus.submitting;
    final ready = state.detailsLoaded && state.status != RedeemStatus.loadingProduct;
    final insufficient = balance < product.pointsPrice;
    final missingFields = ready && _missingAccountFields(product);
    return [
      Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 68,
              height: 68,
              child: ProductArt(product: product, category: widget.category),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name.of(context),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.pointsAmount(Formatters.points(product.pointsPrice)),
                  style: const TextStyle(
                    color: AppColors.violet,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.balanceNote,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          l10n.redeemBalanceLine(
            Formatters.points(balance),
            Formatters.points(balance - product.pointsPrice),
          ),
          style: TextStyle(
            color: insufficient ? AppColors.error : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (!product.deliveryNote.isEmpty) ...[
        const SizedBox(height: 10),
        Text(product.deliveryNote.of(context), style: const TextStyle(color: AppColors.muted)),
      ],
      const SizedBox(height: 14),
      if (ready)
        for (final field in product.fields) ...[
          FulfillmentFieldInput(
            field: field,
            controller: _controller(field.key),
            serverError: state.fieldErrors[field.key] == null
                ? null
                : serverFieldError(context, field, state.fieldErrors[field.key]!),
          ),
          const SizedBox(height: 12),
        ],
      if (missingFields) ...[
        Text(
          l10n.redeemAccountDetailsMissing,
          key: const ValueKey('redeem-account-fields-missing'),
          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
      ],
      Text(l10n.redeemPointsNote, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(height: 4),
      Text(l10n.redeemPrivacyNote, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(height: 18),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.confirmButton,
          borderRadius: BorderRadius.circular(25),
        ),
        child: FilledButton(
          onPressed: !ready || busy || insufficient || missingFields
              ? null
              : () => _confirm(product),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: const Color(0xffbbb5dd),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Text(
                  insufficient ? l10n.redeemInsufficientTitle : l10n.redeemConfirm,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    ];
  }
}
