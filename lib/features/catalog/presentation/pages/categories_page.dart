import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/catalog_cubits.dart';
import '../widgets/categories_skeleton.dart';
import '../widgets/category_visuals.dart';

/// Categories tab: one wide banner per admin-managed category.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => CategoriesCubit(sl())..load(), child: const _CategoriesView());
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: PanelTitle(l10n.categoriesTitle),
          ),
          Expanded(
            child: BlocBuilder<CategoriesCubit, CategoriesState>(
              builder: (context, state) {
                final cubit = context.read<CategoriesCubit>();
                if (state.status == LoadStatus.loading && state.categories.isEmpty) {
                  return const CategoriesSkeleton();
                }
                if (state.status == LoadStatus.failed && state.categories.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [ErrorStateView(error: state.error!, onRetry: cubit.load)],
                  );
                }
                final banner = state.error != null
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RefreshErrorBanner(onRetry: cubit.load),
                      )
                    : null;
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: state.categories.isEmpty
                      ? ListView(
                          // Scrollable so pull-to-refresh works on the empty state.
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            ?banner,
                            AppEmptyState(
                              key: const ValueKey('categories-empty'),
                              icon: LucideIcons.layoutGrid,
                              accent: LucideIcons.sparkles,
                              title: l10n.categoriesEmptyTitle,
                              message: l10n.categoriesEmptyBody,
                              padding: const EdgeInsets.fromLTRB(12, 56, 12, 24),
                            ),
                          ],
                        )
                      : ListView(
                          key: const PageStorageKey('categories'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          children: [
                            ?banner,
                            for (final category in state.categories) ...[
                              InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () =>
                                    context.push(Routes.category(category.id), extra: category),
                                child: CategoryBanner(category: category, height: 102),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
