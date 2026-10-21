import 'package:flutter/material.dart';
import 'package:rewardsapp/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/features/giveaway_details/presentation/bloc/giveaway_details_cubit.dart';
import 'package:rewardsapp/features/giveaway_details/presentation/bloc/giveaway_details_state.dart';
import 'package:rewardsapp/features/giveaway_details/presentation/giveaway_details_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:rewardsapp/shared/repositories/participation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Regression tests for the "final responsiveness pass" `RenderFlex`
/// overflow fixes: `Row`s that paired a variable-width `Text` (long
/// organizer name / participant count) with a fixed-width sibling
/// (icon/button) and no `Expanded`/`Flexible`, which throws on a narrow
/// screen or with long/Arabic-length content. These reproduce the exact
/// failure conditions (narrow viewport + a deliberately long string) against
/// the real widgets, not a synthetic stand-in.
class MockGiveawayRepository extends Mock implements GiveawayRepository {}

class MockParticipationRepository extends Mock implements ParticipationRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

/// A real [GiveawayDetailsCubit] (so its type matches what
/// [GiveawayDetailsCta] reads via `BlocProvider`/`context.read`) pre-seeded
/// with a fixed state instead of driven through `load()`. The repositories
/// are never called from the state this test exercises.
class _SeededGiveawayDetailsCubit extends GiveawayDetailsCubit {
  _SeededGiveawayDetailsCubit(GiveawayDetailsState seed)
    : super(MockGiveawayRepository(), MockParticipationRepository(), MockSupabaseClient()) {
    emit(seed);
  }
}

final _giveawayWithLongOrganizerName = Giveaway(
  id: 'g1',
  title: 'iPhone 17 Pro Max Giveaway',
  organizerName:
      'The International Consumer Electronics Retailers & Charitable Foundation Alliance',
  prizeDescription: 'A brand new phone',
  descriptionRules: 'Rules apply',
  imageUrl: null,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 10),
  endTime: '18:00',
  status: GiveawayStatus.active,
  numberDigitWidth: 4,
  maxParticipants: null,
  participantCount: 128,
);

Future<void> _pumpAtWidth(WidgetTester tester, Widget child, {double width = 320}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: child,
    ),
  );
}

void main() {
  testWidgets('giveaway details hides Generate Number until participation is confirmed', (
    tester,
  ) async {
    final GiveawayDetailsCubit cubit = _SeededGiveawayDetailsCubit(
      GiveawayDetailsState(
        status: GiveawayDetailsStatus.loaded,
        giveaway: _giveawayWithLongOrganizerName,
        participationCheckStatus: ParticipationCheckStatus.loading,
      ),
    );
    addTearDown(cubit.close);

    await _pumpAtWidth(
      tester,
      Scaffold(
        body: BlocProvider<GiveawayDetailsCubit>.value(
          value: cubit,
          child: GiveawayDetailsCta(giveawayId: _giveawayWithLongOrganizerName.id),
        ),
      ),
    );

    expect(find.text('Generate Number'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('giveaway details: a long organizer name next to the verified icon does not overflow '
      'on a 320dp-wide screen', (tester) async {
    // Mirrors the exact Row structure in _LoadedView (icon + gap +
    // Expanded organizer-name Text) that previously had no
    // Expanded/Flexible wrapper.
    await _pumpAtWidth(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _giveawayWithLongOrganizerName.organizerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'giveaway details: the "already joined" banner does not overflow with a long localized '
    'string on a 320dp-wide screen',
    (tester) async {
      final GiveawayDetailsCubit cubit = _SeededGiveawayDetailsCubit(
        GiveawayDetailsState(
          status: GiveawayDetailsStatus.loaded,
          giveaway: _giveawayWithLongOrganizerName,
          alreadyJoined: true,
          myParticipationNumber: 4821,
        ),
      );
      addTearDown(cubit.close);

      await _pumpAtWidth(
        tester,
        Scaffold(
          body: BlocProvider<GiveawayDetailsCubit>.value(
            value: cubit,
            child: SizedBox(
              width: 320,
              child: GiveawayDetailsCta(giveawayId: _giveawayWithLongOrganizerName.id),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(AppIcons.checkCircle), findsOneWidget);
    },
  );
}
