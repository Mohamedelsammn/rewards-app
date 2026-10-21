import 'package:flutter/material.dart';

/// Color tokens of the Creative Rewards redesign.
class AppColors {
  const AppColors._();

  static const ink = Color(0xff0c123e);
  static const violet = Color(0xff4824fa);
  static const muted = Color(0xff777eaa);
  static const pale = Color(0xfff6f4ff);

  /// [pale] at zero opacity: fade art into the page with this, never with
  /// [Colors.transparent] (transparent black turns the blend gray).
  static const paleClear = Color(0x00f6f4ff);
  static const surface = Color(0xfffaf9ff);
  static const sheet = Color(0xfffbfaff);
  static const white = Colors.white;

  static const headerPoints = Color(0xff4d45ad);
  static const ptsLabel = Color(0xff8857ee);
  static const walletPtsLabel = Color(0xffe5dcff);
  static const walletSubtitle = Color(0xffdbd6ff);

  static const fieldBorder = Color(0xffdedbfc);
  static const otpBorder = Color(0xffddd9fc);
  static const progressInactive = Color(0xffd6cff9);
  static const divider = Color(0xffdddafa);
  static const navBorder = Color(0xffecebfa);
  static const navBackground = Color(0xf8ffffff);
  static const navInactive = Color(0xff74779f);
  static const segmentTrack = Color(0xfff0eff9);
  static const segmentInactiveText = Color(0xff555e91);
  static const chipTrack = Color(0xfff0eef9);
  static const tint = Color(0xffeeeaff);
  static const tintStrong = Color(0xffe9e5ff);
  static const tintSoft = Color(0xfff1eefb);
  static const balanceNote = Color(0xfff0ecff);
  static const avatarRing = Color(0xffe7dcff);
  static const handle = Color(0xffd9d3ed);
  static const selectedTile = Color(0xffede8ff);
  static const circleArrow = Color(0xfff1edff);
  static const backButton = Color(0xffefebff);

  static const success = Color(0xff0cb95f);
  static const warning = Color(0xffd98a00);
  static const danger = Color(0xffd83a53);
  static const dangerText = Color(0xffc82e48);
  static const dangerButton = Color(0xffdb4058);
  static const dangerSurface = Color(0xffffedf0);
  static const dangerBorder = Color(0xffffd7de);
  static const dangerIconSurface = Color(0xffffe9ec);
  static const error = Color(0xffc82e48);
  static const badge = Color(0xffff4c49);
  static const badgeProfile = Color(0xfff23b3b);
  static const star = Color(0xffffce4d);

  /// Profile header: status-bar fill matching the art's top edge, a light
  /// wash that softens the art, and the glass character frame.
  static const profileHeaderTop = Color(0xffb5adfb);
  static const profileHeaderTopClear = Color(0x00b5adfb);
  static const profileHeaderBottom = Color(0xffd4baea);
  static const profileHeaderBottomClear = Color(0x00d4baea);
  static const profileArtWash = Color(0x38ffffff);
  static const profileFrameGlass = Color(0x47ffffff);
  static const profileFrameBorder = Color(0xe6ffffff);
  static const profileEditShadow = Color(0x407a62d8);
  static const profileFrameHaze = Color(0xf2f6f4ff);
  static const profileFrameHazeClear = Color(0x00f6f4ff);
  static const profileEmail = Color(0xff8a8fb4);

  /// Skeleton placeholders and their shimmer highlight.
  /// Home search field: soft lavender glow and placeholder text.
  static const searchGlow = Color(0x147a6fd0);
  static const searchHint = Color(0xff9a98c4);

  static const skeletonBase = Color(0xffe9e5fa);
  static const skeletonHighlight = Color(0xfff8f6ff);

  /// Empty-state halo and the soft lavender behind its icon tile.
  static const emptyHalo = Color(0xffe4dcff);
  static const emptyHaloEdge = Color(0x00e4dcff);

  /// Pastel card backgrounds cycled by the giveaway grid.
  static const giveawayCards = [
    Color(0xffe7e3ff),
    Color(0xffffe1ef),
    Color(0xffdfeeff),
    Color(0xffffe8dc),
  ];
}

class AppGradients {
  const AppGradients._();

  /// Icon tile of [AppEmptyState].
  static const emptyIcon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff6b4dff), Color(0xffa45cf6)],
  );

  static const primaryButton = LinearGradient(colors: [Color(0xff3927ff), Color(0xff6921f2)]);
  static const darkButton = LinearGradient(colors: [Color(0xff080b2e), Color(0xff2c075e)]);
  static const confirmButton = LinearGradient(colors: [Color(0xff4031ff), Color(0xff741af2)]);
  static const headline = LinearGradient(colors: [Color(0xff6921f2), Color(0xffb024ec)]);

  static const splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffe9e5ff), Color(0xffffeaf8), Color(0xffd6d8ff)],
  );

  static const welcome = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffede3ff), Color(0xffffe7f6), Color(0xfff7f6ff)],
  );

  static const character = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffeee9ff), Color(0xfffff5fc), Color(0xffe5ecff)],
  );

  static const notificationIcon = LinearGradient(colors: [Color(0xffcbbaff), Color(0xffeee8ff)]);

  static const categoryDetailScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xaa070c39)],
    stops: [.45, 1],
  );
}

class AppShadows {
  const AppShadows._();

  static const button = [
    BoxShadow(color: Color(0x33552cff), blurRadius: 22, offset: Offset(0, 10)),
  ];
  static const productCard = [BoxShadow(color: Color(0x139493c9), blurRadius: 16)];
  static const listCard = [
    BoxShadow(color: Color(0x0f7765bc), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const notificationCard = [
    BoxShadow(color: Color(0x147661ae), blurRadius: 22, offset: Offset(0, 8)),
  ];
  static const entryCard = [
    BoxShadow(color: Color(0x127965b5), blurRadius: 21, offset: Offset(0, 8)),
  ];
  static const sheet = [BoxShadow(color: Color(0x208073bd), blurRadius: 24, offset: Offset(0, -5))];
  static const redemptionSheet = [BoxShadow(color: Color(0x26806ed8), blurRadius: 30)];
}
