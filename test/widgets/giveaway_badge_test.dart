import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/localization/l10n.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/core/theme/app_colors.dart';
import 'package:rewardsapp/core/theme/app_theme.dart';
import 'package:rewardsapp/features/giveaways/domain/entities/giveaway_entities.dart';
import 'package:rewardsapp/features/giveaways/presentation/widgets/giveaway_visuals.dart';

final _now = DateTime.utc(2026, 10, 22, 12);

Giveaway _giveaway(
  GiveawayStatus status, {
  int participants = 0,
  int? maxParticipants,
  DateTime? endsAt,
}) => Giveaway(
  id: 'g1',
  title: const LocalizedText(en: 'Win an iPhone 15 Pro', ar: 'اربح آيفون 15 برو'),
  status: status,
  participants: participants,
  maxParticipants: maxParticipants,
  startsAt: DateTime.utc(2026, 10, 20),
  endsAt: endsAt ?? DateTime.utc(2026, 10, 30),
);

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('status mapping', () {
    GiveawayBadgeState state(Giveaway g) => giveawayBadgeState(g, now: _now);

    test('the server status decides', () {
      expect(state(_giveaway(GiveawayStatus.active)), GiveawayBadgeState.active);
      expect(state(_giveaway(GiveawayStatus.upcoming)), GiveawayBadgeState.comingSoon);
      for (final status in [
        GiveawayStatus.ended,
        GiveawayStatus.winnersSelected,
        GiveawayStatus.completed,
        GiveawayStatus.cancelled,
      ]) {
        expect(state(_giveaway(status)), GiveawayBadgeState.ended, reason: '$status');
      }
    });

    test('an active giveaway at capacity is full; unlimited never is', () {
      expect(
        state(_giveaway(GiveawayStatus.active, participants: 1000, maxParticipants: 1000)),
        GiveawayBadgeState.full,
      );
      expect(
        state(_giveaway(GiveawayStatus.active, participants: 999, maxParticipants: 1000)),
        GiveawayBadgeState.active,
      );
      expect(
        state(_giveaway(GiveawayStatus.active, participants: 50000)),
        GiveawayBadgeState.active,
      );
      // Capacity does not override a finished giveaway.
      expect(
        state(_giveaway(GiveawayStatus.ended, participants: 10, maxParticipants: 10)),
        GiveawayBadgeState.ended,
      );
    });

    test('still ACTIVE after endsAt reads as ended', () {
      expect(
        state(_giveaway(GiveawayStatus.active, endsAt: _now.subtract(const Duration(minutes: 1)))),
        GiveawayBadgeState.ended,
      );
    });
  });

  group('badge', () {
    final cases = {
      GiveawayBadgeState.active: (_giveaway(GiveawayStatus.active), 'Active'),
      GiveawayBadgeState.comingSoon: (_giveaway(GiveawayStatus.upcoming), 'Coming Soon'),
      GiveawayBadgeState.ended: (_giveaway(GiveawayStatus.ended), 'Ended'),
      GiveawayBadgeState.full: (
        _giveaway(GiveawayStatus.active, participants: 5, maxParticipants: 5),
        'Full',
      ),
    };
    const colors = {
      GiveawayBadgeState.active: AppColors.giveawayBadgeActive,
      GiveawayBadgeState.comingSoon: AppColors.giveawayBadgeSoon,
      GiveawayBadgeState.ended: AppColors.giveawayBadgeEnded,
      GiveawayBadgeState.full: AppColors.giveawayBadgeFull,
    };

    for (final MapEntry(key: state, value: (giveaway, label)) in cases.entries) {
      testWidgets('${state.name}: label and color', (tester) async {
        await tester.pumpWidget(_app(GiveawayStatusBadge(giveaway: giveaway, now: _now)));
        expect(find.byKey(ValueKey('giveaway-badge-${state.name}')), findsOneWidget);
        final text = tester.widget<Text>(find.text(label));
        expect(text.style!.color, colors[state]);
      });
    }

    testWidgets('keeps the pill height of the old badge', (tester) async {
      await tester.pumpWidget(
        _app(GiveawayStatusBadge(giveaway: _giveaway(GiveawayStatus.active), now: _now)),
      );
      final size = tester.getSize(find.byKey(const ValueKey('giveaway-badge-active')));
      // 4 + 4 vertical padding around a 12 px row (icon slot / 10.5 px text).
      expect(size.height, lessThanOrEqualTo(24));
    });

    testWidgets('Arabic labels', (tester) async {
      const ar = {
        GiveawayBadgeState.active: 'نشط',
        GiveawayBadgeState.comingSoon: 'قريبًا',
        GiveawayBadgeState.ended: 'انتهى',
        GiveawayBadgeState.full: 'مكتمل',
      };
      for (final MapEntry(key: state, value: (giveaway, _)) in cases.entries) {
        await tester.pumpWidget(
          _app(
            GiveawayStatusBadge(giveaway: giveaway, now: _now),
            locale: const Locale('ar'),
          ),
        );
        expect(find.text(ar[state]!), findsOneWidget, reason: state.name);
      }
    });
  });

  group('card', () {
    Future<void> pumpCard(WidgetTester tester, Giveaway giveaway, {Locale? locale}) =>
        tester.pumpWidget(
          _app(
            SizedBox(
              width: 180,
              height: 243,
              child: GiveawayCard(giveaway: giveaway, index: 0, onTap: () {}),
            ),
            locale: locale ?? const Locale('en'),
          ),
        );

    testWidgets('shows the dynamic badge instead of the static one', (tester) async {
      await pumpCard(tester, _giveaway(GiveawayStatus.upcoming));
      expect(find.byKey(const ValueKey('giveaway-badge-comingSoon')), findsOneWidget);
      expect(find.text('Giveaway'), findsNothing);
    });

    testWidgets('badge sits at the top start corner, mirrored in Arabic', (tester) async {
      await pumpCard(tester, _giveaway(GiveawayStatus.active));
      final card = tester.getRect(find.byType(GiveawayCard));
      final en = tester.getRect(find.byKey(const ValueKey('giveaway-badge-active')));
      expect(en.left - card.left, 10);
      expect(en.top - card.top, 10);

      await pumpCard(tester, _giveaway(GiveawayStatus.active), locale: const Locale('ar'));
      final ar = tester.getRect(find.byKey(const ValueKey('giveaway-badge-active')));
      expect(card.right - ar.right, 10);
      expect(find.text('نشط'), findsOneWidget);
    });
  });
}
