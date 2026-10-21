import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ads/ad_service.dart';

class AdaptiveAdBanner extends StatefulWidget {
  const AdaptiveAdBanner({super.key, required this.ads});
  final AdService ads;

  @override
  State<AdaptiveAdBanner> createState() => _AdaptiveAdBannerState();
}

class _AdaptiveAdBannerState extends State<AdaptiveAdBanner> {
  BannerAd? _renderedBanner;
  Widget? _adWidget;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.floor();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) widget.ads.ensureBanner(width);
        });
        return ListenableBuilder(
          listenable: widget.ads,
          builder: (context, _) {
            final ads = widget.ads;
            final banner = ads.banner;
            if (!ads.bannerLoaded || banner == null) return const SizedBox.shrink();
            // Keep the native platform view untouched by unrelated tab rebuilds.
            // A genuinely new ad gets its own State and platform-view identity.
            if (!identical(_renderedBanner, banner)) {
              _renderedBanner = banner;
              _adWidget = RepaintBoundary(
                child: AdWidget(key: ObjectKey(banner), ad: banner),
              );
            }
            final size = ads.bannerSize ?? banner.size;
            return Align(
              heightFactor: 1,
              child: SizedBox(
                width: size.width.toDouble(),
                height: size.height.toDouble(),
                child: _adWidget,
              ),
            );
          },
        );
      },
    ),
  );
}
