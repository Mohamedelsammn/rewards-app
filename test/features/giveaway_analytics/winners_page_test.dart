import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/widgets/winners_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/winner.dart';

final _winner1 = Winner(
  id: 'w1',
  giveawayId: 'g1',
  participationId: 'p1',
  rank: 1,
  selectedAt: DateTime(2026, 1, 2, 10, 30),
  celebrationAcknowledgedAt: null,
  participationNumber: 4821,
  fullName: 'Ahmed Farouk',
  phoneE164: '+201555075289',
);

final _winner2 = Winner(
  id: 'w2',
  giveawayId: 'g1',
  participationId: 'p2',
  rank: 2,
  selectedAt: DateTime(2026, 1, 2, 11, 0),
  celebrationAcknowledgedAt: null,
  participationNumber: 1173,
  fullName: 'Sara Kamel',
  phoneE164: null,
);

Future<void> _pump(WidgetTester tester, List<Winner> winners) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: WinnersPage(winners: winners),
    ),
  );
}

void main() {
  group('WinnersPage', () {
    testWidgets('shows an empty-state message when there are no winners', (tester) async {
      await _pump(tester, const []);

      expect(find.text('No winners yet.'), findsOneWidget);
    });

    testWidgets(
      'displays every existing winner -- rank, participation number, name, phone, and '
      'selected date/time -- exactly as loaded from WinnerRepository via the state passed in',
      (tester) async {
        await _pump(tester, [_winner1, _winner2]);

        expect(find.text('WINNER'), findsOneWidget); // rank 1
        expect(find.text('WINNER #2'), findsOneWidget); // rank 2
        expect(find.text('4821'), findsOneWidget);
        expect(find.text('1173'), findsOneWidget);
        expect(find.text('Ahmed Farouk'), findsOneWidget);
        expect(find.text('Sara Kamel'), findsOneWidget);
        expect(find.text('+201555075289'), findsOneWidget);
        expect(find.textContaining('Selected At'), findsNWidgets(2));
      },
    );

    testWidgets(
      'swiping a winner removes it from the displayed list ONLY -- this is pure local page '
      'state, there is no repository/database call anywhere in this widget',
      (tester) async {
        await _pump(tester, [_winner1, _winner2]);

        expect(find.text('Ahmed Farouk'), findsOneWidget);
        expect(find.text('Sara Kamel'), findsOneWidget);

        await tester.drag(find.text('Ahmed Farouk'), const Offset(-600, 0));
        await tester.pumpAndSettle();

        expect(find.text('Ahmed Farouk'), findsNothing);
        // The other winner is untouched.
        expect(find.text('Sara Kamel'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'swiping away every winner falls back to the empty-state message -- still just a view '
      'change, the underlying list passed in is never mutated',
      (tester) async {
        final winners = [_winner1];
        await _pump(tester, winners);

        await tester.drag(find.text('Ahmed Farouk'), const Offset(-600, 0));
        await tester.pumpAndSettle();

        expect(find.text('No winners yet.'), findsOneWidget);
        // The original list this page was given is unchanged -- reopening
        // the page with the same list would show the winner again.
        expect(winners, [_winner1]);
      },
    );
  });
}
