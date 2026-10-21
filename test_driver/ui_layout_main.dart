// Debug-only native layout QA. Production main never imports this entrypoint.
// It uses the real screens/repositories and Google demo units, with a mock
// consent context to isolate geometry from the owner's missing UMP messages.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:rewardsapp/core/di/injection.dart';
import 'package:rewardsapp/main.dart' show RewardsApp;
import 'package:rewardsapp/services/ads/ad_constants.dart';
import 'package:rewardsapp/services/ads/ad_service.dart';

class _LayoutAds extends AdService {
  _LayoutAds(super.cache);
  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    ready = true;
    notifyListeners();
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    await ensureBanner((view.physicalSize.width / view.devicePixelRatio).floor());
  }
}

Future<void> main() async {
  if (!kDebugMode || !AdConstants.testAds) throw StateError('Debug Google demo ads only');
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([configureDependencies(), LiquidGlassWidgets.initialize()]);
  await getIt.unregister<AdService>();
  final ads = _LayoutAds(getIt());
  ads.addListener(
    () => debugPrint(
      'LAYOUT_QA banner=${ads.bannerLoaded} requested=${ads.banner?.size.width}x${ads.banner?.size.height} resolved=${ads.bannerSize?.width}x${ads.bannerSize?.height}',
    ),
  );
  getIt.registerSingleton<AdService>(ads);
  runApp(
    LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const RewardsApp()),
  );
}
