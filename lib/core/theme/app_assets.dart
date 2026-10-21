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
    if (value.contains('valorant') || value.contains('فالورانت')) return ArtworkKey.valorant;
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

  static String _slug(ArtworkKey key) => switch (key) {
    ArtworkKey.pubg => 'pubg_mobile',
    ArtworkKey.valorant => 'valorant',
    ArtworkKey.instagram => 'instagram',
    ArtworkKey.tiktok => 'tiktok',
    ArtworkKey.facebook => 'facebook',
    ArtworkKey.phones => 'phones',
  };

  /// Wide banner with embedded English title (Categories list, English).
  static String banner(ArtworkKey key) =>
      '${AppAssets._root}01_category_banners/category_${_slug(key)}.png';

  /// Illustration without text (Arabic banners, product fallback).
  static String art(ArtworkKey key) =>
      '${AppAssets._root}08_generated_category_art/art_${switch (key) {
        ArtworkKey.pubg => 'pubg',
        _ => _slug(key),
      }}.png';

  /// Square tile on the Home rail. Only four families have one.
  static String tile(ArtworkKey key) => switch (key) {
    ArtworkKey.pubg ||
    ArtworkKey.valorant ||
    ArtworkKey.instagram ||
    ArtworkKey.tiktok => '${AppAssets._root}02_home_categories/home_${_slug(key)}.png',
    _ => art(key),
  };

  /// Hero image of the category details screen.
  static String detail(ArtworkKey key) => switch (key) {
    ArtworkKey.pubg => '${AppAssets._root}06_category_details/pubg_generated_banner.png',
    ArtworkKey.valorant => '${AppAssets._root}06_category_details/valorant_generated_banner.png',
    _ => art(key),
  };

  static List<Color> gradient(ArtworkKey? key) => switch (key) {
    ArtworkKey.pubg => const [Color(0xff0777ca), Color(0xff91c9f9)],
    ArtworkKey.valorant => const [Color(0xff30217f), Color(0xffef4873)],
    ArtworkKey.instagram => const [Color(0xffdd1883), Color(0xffff7b53)],
    ArtworkKey.tiktok => const [Color(0xff0d1028), Color(0xff4045a1)],
    ArtworkKey.facebook => const [Color(0xff0758dd), Color(0xff26bbff)],
    ArtworkKey.phones => const [Color(0xffcdaff8), Color(0xff90b9fa)],
    null => const [Color(0xff3927ff), Color(0xffb38cff)],
  };

  /// PUBG UC package art, chosen by the denomination in the product name.
  static String? pubgPackage(String productName) {
    final digits = RegExp(r'\d+').firstMatch(productName.replaceAll(',', ''))?.group(0);
    const packs = {'60', '180', '325', '660', '1800', '3850'};
    if (digits == null || !packs.contains(digits)) return null;
    return '${AppAssets._root}05_pubg_uc_packages/pubg_uc_$digits.png';
  }
}

class GiveawayArtwork {
  const GiveawayArtwork._();

  /// Matches prize/title text to the bundled 3D prize renders.
  static String? match(String text) {
    final value = text.toLowerCase();
    final name = switch (value) {
      _ when value.contains('airpod') || value.contains('earbud') => 'airpods_pro',
      _ when value.contains('iphone') || value.contains('phone') || value.contains('آيفون') =>
        'iphone_15_pro',
      _ when value.contains('playstation') || value.contains('ps5') || value.contains('console') =>
        'playstation_5',
      _ when value.contains('coffee') || value.contains('قهوة') => 'coffee_machine',
      _ => null,
    };
    return name == null ? null : '${AppAssets._root}04_reward_product_art/reward_$name.png';
  }
}
