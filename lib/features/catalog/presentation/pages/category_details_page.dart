import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/selectors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../orders/presentation/redemption/redeem_flow.dart';
import '../../domain/entities/catalog_entities.dart';
import '../bloc/catalog_cubits.dart';
import '../widgets/category_visuals.dart';
import '../widgets/product_card.dart';
import '../widgets/product_grid_skeleton.dart';

class CategoryDetailsPage extends StatelessWidget {
  const CategoryDetailsPage({required this.categoryId, this.preview, super.key});

  final String categoryId;
  final RewardCategory? preview;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        CategoryDetailsCubit(sl(), categoryId: categoryId, preview: preview, snapshots: sl())
          ..open(),
    child: const _CategoryDetailsView(),
  );
}

class _CategoryDetailsView extends StatelessWidget {
  const _CategoryDetailsView();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
      builder: (context, state) {
        final cubit = context.read<CategoryDetailsCubit>();
        final category = state.category;
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Hero(category: category)),
              if (state.status == LoadStatus.ready && state.error != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(child: RefreshErrorBanner(onRetry: cubit.load)),
                ),
              if (category != null && category.groups.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: SegmentedTabs<String>(
                      options: [
                        for (final group in category.groups)
                          SelectorOption(group.id, group.name.of(context)),
                      ],
                      selected: state.groupId ?? category.groups.first.id,
                      onChanged: cubit.selectGroup,
                    ),
                  ),
                ),
              if (category != null && category.isGame)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: SegmentedTabs<ProductType>(
                      key: const ValueKey('product-type-tabs'),
                      options: [
                        SelectorOption(ProductType.topUp, context.l10n.productTabTopUps),
                        SelectorOption(ProductType.itemSkin, context.l10n.productTabItemsSkins),
                      ],
                      selected: state.productType ?? ProductType.topUp,
                      onChanged: cubit.selectProductType,
                    ),
                  ),
                ),
              ..._body(context, state),
            ],
          ),
        );
      },
    ),
  );

  List<Widget> _body(BuildContext context, CategoryDetailsState state) {
    final cubit = context.read<CategoryDetailsCubit>();
    if (state.status == LoadStatus.loading || state.productsLoading) {
      return const [SliverToBoxAdapter(child: ProductGridSkeleton())];
    }
    if (state.status == LoadStatus.failed) {
      return [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: ErrorStateView(error: state.error!, onRetry: cubit.load),
          ),
        ),
      ];
    }
    final products = state.visibleProducts;
    if (products.isEmpty) {
      final l10n = context.l10n;
      return [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: EmptyCard(switch (state.productType) {
              ProductType.topUp => l10n.productTopUpsEmpty,
              ProductType.itemSkin => l10n.productItemsSkinsEmpty,
              null => l10n.categoryProductsEmpty,
            }),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid.builder(
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .68,
          ),
          itemBuilder: (_, index) => ProductCard(
            product: products[index],
            category: state.category,
            onRedeem: () => startRedemption(
              context,
              product: products[index],
              category: state.category,
              onFinished: cubit.load,
            ),
          ),
        ),
      ),
    ];
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.category});

  final RewardCategory? category;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: const BoxDecoration(gradient: AppGradients.categoryDetailScrim),
            // The category's banner only: never the home image or a bundled
            // stand-in. Without one, the brand gradient fills the hero.
            child: category?.bannerImageUrl == null
                ? DecoratedBox(
                    key: const ValueKey('category-banner-placeholder'),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: categoryGradient(category),
                      ),
                    ),
                  )
                // Decoded at screen width: banners are uploaded much wider.
                : AppImage(
                    url: category!.bannerImageUrl,
                    cacheWidth:
                        (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                  ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton.filledTonal(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ),
        if (category != null)
          PositionedDirectional(
            start: 22,
            end: 22,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category!.name.of(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!category!.description.isEmpty)
                  Text(
                    category!.description.of(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
