import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/injection_container.dart';
import '../../../app/router/routes.dart';
import '../../../core/services/ads/ads_manager.dart';

/// A user tap on a giveaway (Home, Giveaways, My Giveaways). Every third
/// opening may play the preloaded interstitial first, at the transition;
/// then the details open. Taps while an opening is in progress are ignored.
/// Deep links (notifications) push the route directly and are not counted.
Future<void> openGiveawayFromTap(BuildContext context, String giveawayId) async {
  final ads = sl.isRegistered<AdsManager>() ? sl<AdsManager>() : null;
  if (ads != null && !await ads.giveaways.beforeOpening()) return;
  if (!context.mounted) return;
  await context.push(Routes.giveaway(giveawayId));
}
