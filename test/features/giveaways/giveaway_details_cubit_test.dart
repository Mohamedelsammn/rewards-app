import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/localization/localized_text.dart';
import 'package:rewardsapp/features/giveaways/domain/entities/giveaway_entities.dart';
import 'package:rewardsapp/features/giveaways/domain/repositories/giveaways_repository.dart';
import 'package:rewardsapp/features/giveaways/presentation/bloc/giveaway_cubits.dart';

const _step = GiveawayStep(
  id: 's1',
  kind: 'FOLLOW',
  title: LocalizedText(en: 'Follow us'),
  verification: StepVerification.adminReview,
  required: true,
  sortOrder: 0,
);

const _giveaway = Giveaway(
  id: 'g1',
  title: LocalizedText(en: 'iPhone giveaway'),
  status: GiveawayStatus.active,
  steps: [_step],
);

class _Repository implements GiveawaysRepository {
  final proofs = <String?>[];
  int entries = 0;
  bool stepsDone = false;

  @override
  Future<GiveawayDetails> details(String id) async => GiveawayDetails(
    giveaway: _giveaway,
    progress: stepsDone
        ? const {'s1': StepProgress(stepId: 's1', status: StepProgressStatus.submitted)}
        : const {},
  );

  @override
  Future<StepProgress> submitStep({
    required String giveawayId,
    required String stepId,
    String? proofText,
  }) async {
    proofs.add(proofText);
    stepsDone = true;
    return StepProgress(stepId: stepId, status: StepProgressStatus.submitted);
  }

  @override
  Future<GiveawayEntry> enter(String giveawayId) async {
    entries++;
    if (!stepsDone) {
      throw const AppException(code: 'STEPS_INCOMPLETE', statusCode: 409);
    }
    return const GiveawayEntry(
      id: 'e1',
      giveawayId: 'g1',
      participationNumber: '000042',
      active: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('required steps gate the entry; the number comes from the server', () async {
    final repository = _Repository();
    final cubit = GiveawayDetailsCubit(repository, 'g1');
    await cubit.load();
    expect(cubit.state.details?.remainingRequiredSteps, [_step]);

    expect(await cubit.enter(), isNull);
    // The page reports the refusal; the reload has refreshed the steps.
    expect((cubit.state.error! as AppException).code, 'STEPS_INCOMPLETE');
    expect(cubit.state.details?.remainingRequiredSteps, [_step]);

    expect(await cubit.submitStep(_step, proofText: '@ahmed'), isTrue);
    expect(repository.proofs, ['@ahmed']);
    expect(cubit.state.details?.remainingRequiredSteps, isEmpty);

    final entry = await cubit.enter();
    expect(entry?.participationNumber, '000042');
    expect(cubit.state.details?.entry?.participationNumber, '000042');
    expect(repository.entries, 2);
  });
}
