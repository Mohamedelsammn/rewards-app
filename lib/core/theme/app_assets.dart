import 'package:flutter/material.dart';

/// Bundled artwork of the redesign. Backend content usually carries its own
/// `imageUrl`; when it is `null` the app falls back to the matching bundled
/// art (by keyword), and finally to a gradient placeholder.
class AppAssets {
  const AppAssets._();

  static const _root = 'assets/Creative_Rewards_Assets/';

  static const splashHero = 'assets/img/redesign/splash_hero.png';
  static const welcomeHero = 'assets/img/redesign/welcome_hero.png';
  static const signinBackground = 'assets/img/signin-background.png';
  static const otpBackground = 'assets/img/otp-background.png';
  static const passwordBackground = 'assets/img/password-background.png';
  static const homeBackground = 'assets/img/homepage-background.png';
  static const walletBackground = 'assets/img/wallet-background.png';
  static const profileHeader = '${_root}07_profile/profile_header_background.png';
  static const appLogo = 'assets/img/app-logo.png';

  static const numberGeneratorLottie = 'assets/lottie/number-generator.json';
  static const celebrationLottie = 'assets/lottie/Celebration.json';
  static const emptyGiftLottie = 'assets/lottie/empty-gift.json';

  /// Bundled characters 1–9 (avatar ids from `GET /avatars`).
  static String character(int id) {
    final safe = id < 1 || id > 9 ? 1 : id;
    return 'assets/img/redesign/character_${safe == 1 ? '1_clean' : safe}.png';
  }

  static const bundledAvatarIds = [1, 2, 3, 4, 5, 6, 7, 8, 9];
}

/// Known artwork families of the redesign.
enum ArtworkKey { pubg, valorant, instagram, tiktok, facebook, phones }

class CategoryArtwork {
  const CategoryArtwork._();

  static ArtworkKey? match(String text) {
    final value = text.toLowerCase();
    if (value.contains('pubg') || value.contains('ببجي')) return ArtworkKey.pubg;
    // The backend spells it "Valorent".
    if (value.contains('valorant') || value.contains('valorent') || value.contains('فالورانت')) {
      return ArtworkKey.valorant;
    }
    if (value.contains('instagram') || value.contains('إنستغرام') || value.contains('انستجرام')) {
      return ArtworkKey.instagram;
    }
    if (value.contains('tiktok') || value.contains('تيك')) return ArtworkKey.tiktok;
    if (value.contains('facebook') || value.contains('فيسبوك')) return ArtworkKey.facebook;
    if (value.contains('phone') || value.contains('هاتف') || value.contains('هواتف')) {
      return ArtworkKey.phones;
    }
    return null;
  }

  /// Brand colors for a known category family. Only colors: API-driven
  /// categories, products and giveaways always show their backend images.
  static List<Color> gradient(ArtworkKey? key) => switch (key) {
    ArtworkKey.pubg => const [Color(0xff0777ca), Color(0xff91c9f9)],
    ArtworkKey.valorant => const [Color(0xffff4655), Color(0xffe8354b), Color(0xffb91c35)],
    ArtworkKey.instagram => const [Color(0xffdd1883), Color(0xffff7b53)],
    ArtworkKey.tiktok => const [Color(0xff0d1028), Color(0xff4045a1)],
    ArtworkKey.facebook => const [Color(0xff0758dd), Color(0xff26bbff)],
    ArtworkKey.phones => const [Color(0xffcdaff8), Color(0xff90b9fa)],
    null => const [Color(0xff3927ff), Color(0xffb38cff)],
  };
}
