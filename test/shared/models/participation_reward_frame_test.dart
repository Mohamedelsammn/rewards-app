import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/shared/models/participation.dart';
import 'package:rewardsapp/shared/widgets/participation_reward_frame.dart';
import 'package:flutter/material.dart';

void main() {
  test('legacy server SSV columns do not grant the local cosmetic frame', () {
    final participation = Participation.fromJson({
      'id': 'p1',
      'giveaway_id': 'g1',
      'participation_sequence': 1,
      'participation_number': 2468,
      'created_at': '2026-10-12T10:00:00Z',
      'scratch_revealed_at': null,
      'ad_reward_event_id': 'event-verified',
    });
    expect(participation.formattedNumber, '2468');
    expect(participation.rewardedFrameUnlocked, isFalse);
  });

  test('server JSON cannot grant a local cosmetic entitlement', () {
    final participation = Participation.fromJson({
      'id': 'p2',
      'giveaway_id': 'g1',
      'participation_sequence': 2,
      'participation_number': 1357,
      'created_at': '2026-10-12T10:00:00Z',
      'scratch_revealed_at': null,
      'ad_reward_event_id': 'legacy-event-is-ignored',
      'rewardedFrameUnlocked': true,
    });
    expect(participation.rewardedFrameUnlocked, isFalse);
  });

  testWidgets('verified entitlement renders a visible gold frame around the number', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ParticipationRewardFrame(enabled: true, child: Text('2468'))),
      ),
    );
    expect(find.text('2468'), findsOneWidget);
    final framed = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decoration = framed.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
  });
}
