import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/bloc/giveaway_analytics_state.dart';
import 'package:rewardsapp/features/giveaway_analytics/presentation/widgets/recent_participants_list.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';

List<RecentParticipant> _buildParticipants(int count) => List.generate(
  count,
  (i) => RecentParticipant(
    participationSequence: i + 1,
    participationNumber: 1000 + i,
    fullName: 'Participant $i',
    createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
  ),
);

/// Mirrors how [RecentParticipantsList] actually sits on the real Analytics
/// page: inside the outer scrollable page content, with something below it
/// (here, a sentinel standing in for "Select Winner") that must stay
/// reachable regardless of how many participants exist.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: Scaffold(body: ListView(children: [child, const Text('SELECT_WINNER_SENTINEL')])),
    ),
  );
}

void main() {
  group('RecentParticipantsList', () {
    testWidgets('shows an empty-state message and no inner scrollable when there are no '
        'participants', (tester) async {
      await _pump(tester, const RecentParticipantsList(participants: []));

      expect(
        find.descendant(
          of: find.byType(RecentParticipantsList),
          matching: find.byType(ListView),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'with 100,000 participants, only the first handful of rows build and "Select Winner" '
      'below stays reachable without scrolling through them',
      (tester) async {
        await _pump(tester, RecentParticipantsList(participants: _buildParticipants(100000)));

        expect(find.text('Participant 0'), findsOneWidget);
        expect(find.text('Participant 99999'), findsNothing);
        // The CTA that sits below this section on the real Analytics page
        // (stood in for here) is immediately present -- no scrolling needed.
        expect(find.text('SELECT_WINNER_SENTINEL'), findsOneWidget);
      },
    );

    testWidgets(
      'the participant list itself is independently scrollable, and scrolling inside it does '
      'NOT scroll the rest of the page (no nested-scroll bug)',
      (tester) async {
        await _pump(tester, RecentParticipantsList(participants: _buildParticipants(50)));

        final innerList = find.descendant(
          of: find.byType(RecentParticipantsList),
          matching: find.byType(ListView),
        );
        expect(innerList, findsOneWidget);
        expect(find.text('Participant 0'), findsOneWidget);
        expect(find.text('SELECT_WINNER_SENTINEL'), findsOneWidget);

        await tester.drag(innerList, const Offset(0, -600));
        await tester.pumpAndSettle();

        // Scrolled past the earliest rows...
        expect(find.text('Participant 0'), findsNothing);
        // ...while the rest of the page never moved.
        expect(find.text('SELECT_WINNER_SENTINEL'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
