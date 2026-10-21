import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/core/error/result.dart';
import 'package:rewardsapp/features/categories/presentation/category_management_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/giveaway_category.dart';
import 'package:rewardsapp/shared/repositories/category_repository.dart';

class Categories extends Mock implements CategoryRepository {}

const category = GiveawayCategory(id: 'phone', nameEn: 'Phones', nameAr: 'هواتف');

void main() {
  late Categories repository;
  setUpAll(() => registerFallbackValue(category));
  setUp(() async {
    await getIt.reset();
    repository = Categories();
    getIt.registerSingleton<CategoryRepository>(repository);
    when(() => repository.canManage()).thenAnswer((_) async => true);
    when(
      () => repository.getCategories(management: true),
    ).thenAnswer((_) async => const Result.success([category]));
    when(
      () => repository.save(any(), create: any(named: 'create')),
    ).thenAnswer((_) async => const Result.success(null));
  });
  tearDown(() => getIt.reset());
  Future<void> pump(WidgetTester tester, [String language = 'en']) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const CategoryManagementPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ordinary administrators cannot enter catalog management', (tester) async {
    when(() => repository.canManage()).thenAnswer((_) async => false);
    await pump(tester);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Category management requires a super administrator.'), findsOneWidget);
    verifyNever(() => repository.getCategories(management: true));
  });
  for (final language in ['en', 'ar']) {
    testWidgets('catalog uses localized names and direction in $language', (tester) async {
      await pump(tester, language);
      final title = find.text(category.label(language));
      expect(title, findsOneWidget);
      expect(
        Directionality.of(tester.element(title)),
        language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }
  testWidgets('create persists both names and order without a category id supplied by client', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Gaming');
    await tester.enterText(fields.at(1), 'ألعاب');
    await tester.enterText(fields.at(3), '25');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repository.save(captureAny(), create: true)).captured.single
            as GiveawayCategory;
    expect(saved.nameEn, 'Gaming');
    expect(saved.nameAr, 'ألعاب');
    expect(saved.sortOrder, 25);
    expect(saved.toJson().containsKey('id'), false);
  });
  testWidgets('edit can disable a category and preserve its relationship id', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Phones'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Mobile phones');
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repository.save(captureAny(), create: false)).captured.single
            as GiveawayCategory;
    expect(saved.id, category.id);
    expect(saved.isActive, false);
    expect(saved.nameEn, 'Mobile phones');
  });
}
