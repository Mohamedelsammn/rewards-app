import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/error/failure.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/user_home/presentation/bloc/user_home_cubit.dart';
import 'package:rewardsapp/features/user_home/presentation/bloc/user_home_state.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/models/giveaway_category.dart';
import 'package:rewardsapp/shared/repositories/category_repository.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Repo extends Mock implements GiveawayRepository {}

class Categories extends Mock implements CategoryRepository {}

class Client extends Mock implements SupabaseClient {}

Giveaway row(int i) => Giveaway(
  id: '$i',
  title: 'Giveaway $i',
  organizerName: 'Organizer',
  prizeDescription: '',
  descriptionRules: '',
  imageUrl: null,
  startDate: DateTime(2026),
  endDate: DateTime(2030),
  endTime: '18:00',
  status: GiveawayStatus.active,
  numberDigitWidth: 4,
  maxParticipants: null,
  participantCount: i,
);
void main() {
  late Repo repo;
  late Categories categories;
  late UserHomeCubit cubit;
  setUp(() {
    repo = Repo();
    categories = Categories();
    when(
      () => repo.getBrowsePage(
        page: any(named: 'page'),
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Result.success([]));
    cubit = UserHomeCubit(repo, Client(), categories: categories);
  });
  tearDown(() => cubit.close());
  test('first page is bounded; loadMore deduplicates and stops on final page', () async {
    when(
      () => repo.getBrowsePage(),
    ).thenAnswer((_) async => Result.success(List.generate(24, row)));
    when(
      () => repo.getBrowsePage(page: 1),
    ).thenAnswer((_) async => Result.success([row(23), row(24)]));
    await cubit.load();
    expect(cubit.state.hasMore, true);
    await Future.wait([cubit.loadMore(), cubit.loadMore()]);
    expect(cubit.state.allGiveaways.length, 25);
    expect(cubit.state.hasMore, false);
    verify(() => repo.getBrowsePage(page: 1)).called(1);
  });
  test('debounces Arabic title input and skips equivalent queries', () async {
    cubit.onSearchChanged('ه');
    cubit.onSearchChanged('هاتف');
    await Future<void>.delayed(const Duration(milliseconds: 340));
    expect(cubit.state.searchQuery, 'هاتف');
    verify(() => repo.getBrowsePage(query: 'هاتف')).called(1);
    cubit.onSearchChanged(' هاتف ');
    await Future<void>.delayed(const Duration(milliseconds: 340));
    verifyNever(() => repo.getBrowsePage(query: 'هاتف'));
  });
  test('stale response cannot replace a newer category selection', () async {
    final old = Completer<Result<List<Giveaway>>>();
    when(() => repo.getBrowsePage()).thenAnswer((_) => old.future);
    final loading = cubit.load();
    cubit.selectCategory('phones');
    await Future<void>.delayed(Duration.zero);
    old.complete(Result.success([row(0)]));
    await loading;
    expect(cubit.state.categoryId, 'phones');
    expect(cubit.state.allGiveaways, isEmpty);
    verify(() => repo.getBrowsePage(categoryId: 'phones')).called(1);
  });
  test('All clears the category filter and clear search resets query', () async {
    cubit.selectCategory('phones');
    await Future<void>.delayed(Duration.zero);
    cubit.selectCategory(null);
    await Future<void>.delayed(Duration.zero);
    cubit.onSearchChanged('Phone');
    await Future<void>.delayed(const Duration(milliseconds: 340));
    cubit.clearSearch();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.categoryId, null);
    expect(cubit.state.searchQuery, '');
  });
  test('pagination failure preserves loaded rows and can retry', () async {
    when(
      () => repo.getBrowsePage(),
    ).thenAnswer((_) async => Result.success(List.generate(24, row)));
    when(
      () => repo.getBrowsePage(page: 1),
    ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.allGiveaways.length, 24);
    expect(cubit.state.failure, isA<NetworkFailure>());
    when(() => repo.getBrowsePage(page: 1)).thenAnswer((_) async => const Result.success([]));
    await cubit.loadMore();
    expect(cubit.state.hasMore, false);
    expect(cubit.state.failure, null);
  });
  test('disabled/removed selected category returns to All', () async {
    cubit.selectCategory('inactive');
    await Future<void>.delayed(Duration.zero);
    when(() => categories.getCategories()).thenAnswer(
      (_) async => const Result.success([
        GiveawayCategory(id: 'phones', nameEn: 'Phones', nameAr: 'الهواتف'),
      ]),
    );
    await cubit.loadCategories();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.categoryId, null);
    expect(cubit.state.categories.length, 1);
  });
  test('cold failure shows recoverable error', () async {
    when(
      () => repo.getBrowsePage(),
    ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
    await cubit.load();
    expect(cubit.state.status, UserHomeStatus.error);
  });
  test('closing while a page is pending discards its response', () async {
    final pending = Completer<Result<List<Giveaway>>>();
    when(() => repo.getBrowsePage()).thenAnswer((_) => pending.future);
    final loading = cubit.load();
    await cubit.close();
    pending.complete(Result.success([row(1)]));
    await loading;
  });
}
