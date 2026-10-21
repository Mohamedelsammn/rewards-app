import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/app_config/data/app_config_repository_impl.dart';
import 'package:rewardsapp/features/giveaways/data/giveaways_repository_impl.dart';
import 'package:rewardsapp/features/giveaways/domain/entities/giveaway_entities.dart';
import 'package:rewardsapp/features/home/data/home_repository_impl.dart';
import 'package:rewardsapp/features/notifications/data/notifications_repository_impl.dart';
import 'package:rewardsapp/features/notifications/domain/notification_entities.dart';
import 'package:rewardsapp/features/orders/data/orders_repository_impl.dart';
import 'package:rewardsapp/features/orders/domain/order_entities.dart';
import 'package:rewardsapp/features/rewarded_ads/data/ad_rewards_repository_impl.dart';
import 'package:rewardsapp/features/rewarded_ads/domain/ad_reward_entities.dart';
import 'package:rewardsapp/features/wallet/data/wallet_repository_impl.dart';
import 'package:rewardsapp/features/wallet/domain/wallet_entities.dart';

import '../helpers/fake_api.dart';

/// Parses the real response examples of docs/FLUTTER_INTEGRATION-5.md §5.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FakeApi serve(Map<String, String> routes) => FakeApi((options) {
    final name = routes['${options.method} ${options.path}'];
    return name == null ? apiError(404, 'NOT_FOUND') : FakeResponse(200, fixture(name));
  });

  test('app config', () async {
    final config = await AppConfigRepositoryImpl(
      serve({'GET /app-config': 'app_config'}).client,
    ).fetch();
    expect(config.minVersion, '1.0.0');
    expect(config.maintenance, isFalse);
    expect(config.adRewardsEnabled, isFalse);
    expect(config.socialProductsEnabled, isFalse);
    expect(config.requiresUpdate('1.1.1'), isFalse);
    expect(config.requiresUpdate('0.9.0'), isTrue);
  });

  test('home feed', () async {
    final feed = await HomeRepositoryImpl(serve({'GET /home': 'home'}).client).home();
    expect(feed.categories, isNotEmpty);
    expect(feed.categories.first.name.resolve('en'), isNotEmpty);
  });

  test('wallet and transactions', () async {
    final api = serve({'GET /wallet': 'wallet', 'GET /wallet/transactions': 'wallet_transactions'});
    final repository = WalletRepositoryImpl(api.client);
    final wallet = await repository.wallet();
    expect(wallet.balance, 1200);
    expect(wallet.lifetimeEarned, 1200);

    final page = await repository.transactions();
    expect(page.items, hasLength(4));
    expect(page.nextCursor, isNull);
    expect(page.items.first.type, WalletTransactionType.redemptionRefund);
    expect(page.items.first.amount, 500);
    expect(page.items[1].type, WalletTransactionType.redemptionDebit);
    expect(page.items[1].amount, -500);
    expect(page.items.last.type, WalletTransactionType.adminCredit);
  });

  test('order creation sends the idempotency key and expected price', () async {
    final api = FakeApi((_) => FakeResponse(201, fixture('order_created')));
    final result = await OrdersRepositoryImpl(api.client).create(
      productId: 'p1',
      fields: const {'playerId': '5123456789'},
      expectedPointsPrice: 500,
      idempotencyKey: 'key-123',
    );
    final request = api.adapter.requests.single;
    expect(request.path, '/orders');
    expect(request.headers['Idempotency-Key'], 'key-123');
    expect(request.data, containsPair('expectedPointsPrice', 500));
    expect(result.balance, 700);
    expect(result.order.orderNumber, 'CR-2026-000309');
    expect(result.order.status, OrderStatus.pending);
    expect(result.order.pointsCost, 500);
  });

  test('completed order with delivered code and timeline', () async {
    final api = serve({'GET /orders/o1': 'order_completed'});
    final order = await OrdersRepositoryImpl(api.client).order('o1');
    expect(order.status, OrderStatus.completed);
    expect(order.deliveredCode, 'UC-CODE-1234');
    expect(order.fields['server'], 'Middle East');
    expect(order.fieldLabels['playerId']?.resolve('ar'), 'معرّف اللاعب');
    expect(order.timeline.map((entry) => entry.status), [
      OrderStatus.pending,
      OrderStatus.processing,
      OrderStatus.completed,
    ]);
  });

  test('rewarded ads: status, session with SSV options, credited poll', () async {
    var credited = false;
    final api = FakeApi((options) {
      if (options.path == '/ad-rewards/status') return FakeResponse(200, fixture('ad_status'));
      if (options.method == 'POST') return FakeResponse(201, fixture('ad_session_created'));
      return FakeResponse(200, fixture(credited ? 'ad_session_credited' : 'ad_session_created'));
    });
    final repository = AdRewardsRepositoryImpl(api.client);

    final status = await repository.status('install-1');
    expect(api.adapter.requests.single.queryParameters['deviceId'], 'install-1');
    expect(status.enabled, isTrue);
    expect(status.remainingToday, 9);
    expect(status.cooldownSeconds, 120);

    final created = await repository.createSession(deviceId: 'install-1', adUnitId: 'unit');
    expect(created.session.status, AdSessionStatus.pending);
    expect(created.ssv.customData, created.session.id);
    expect(created.ssv.userId, '022ae672-fd1e-4c32-86ae-64957029f25a');

    credited = true;
    final session = await repository.session(created.session.id);
    expect(session.status, AdSessionStatus.credited);
    expect(session.points, 10);
  });

  test('giveaway details, entries and celebrations', () async {
    final api = serve({
      'GET /giveaways/g1': 'giveaway_details',
      'GET /me/entries': 'my_entries',
      'GET /me/winnings/pending-celebration': 'pending_celebration',
    });
    final repository = GiveawaysRepositoryImpl(api.client);

    final details = await repository.details('g1');
    expect(details.giveaway.status, GiveawayStatus.active);
    expect(details.giveaway.steps.single.verification, StepVerification.adminReview);
    expect(details.entry?.participationNumber, '424869');
    final step = details.giveaway.steps.single;
    expect(details.progress[step.id]?.status, StepProgressStatus.submitted);

    final entries = await repository.myEntries();
    expect(entries.items.single.result, EntryResult.won);
    expect(entries.items.single.giveawayTitle.resolve('en'), 'iPhone giveaway');

    final pending = await repository.pendingCelebrations();
    expect(pending.single.status, WinningStatus.announced);
    expect(pending.single.canClaim, isTrue);
    expect(pending.single.prize.resolve('en'), 'iPhone 16');
  });

  test('notifications', () async {
    final api = serve({'GET /notifications': 'notifications'});
    final page = await NotificationsRepositoryImpl(api.client).notifications();
    expect(page.items.first.type, NotificationType.winnerSelected);
    expect(page.items.first.data['giveawayId'], 'a518620b-467c-4f1f-aaaf-dc1b6c91b0ef');
    expect(page.items[1].type, NotificationType.orderStatus);
    expect(page.items[1].read, isFalse);
  });
}
