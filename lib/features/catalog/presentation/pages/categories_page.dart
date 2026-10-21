import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection_container.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/headers.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/catalog_cubits.dart';
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
                  return const LoadingView();
                }
                if (state.status == LoadStatus.failed && state.categories.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [ErrorStateView(error: state.error!, onRetry: cubit.load)],
                  );
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: state.categories.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(20),
                          children: [EmptyCard(l10n.categoriesEmpty)],
                        )
                      : ListView.separated(
                          key: const PageStorageKey('categories'),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: state.categories.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final category = state.categories[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () =>
                                  context.push(Routes.category(category.id), extra: category),
                              child: CategoryBanner(category: category, height: 102),
                            );
                          },
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
