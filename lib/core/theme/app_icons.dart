import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One vector family. Legacy category emoji remain valid database values.
class AppIcons {
  const AppIcons._();
  static const bell = LucideIcons.bell;
  static const search = LucideIcons.search;
  static const close = LucideIcons.x;
  static const categories = LucideIcons.layoutGrid;
  static const gift = LucideIcons.gift;
  static const participants = LucideIcons.users;
  static const clock = LucideIcons.clock3;
  static const calendar = LucideIcons.calendarDays;
  static const language = LucideIcons.languages;
  static const info = LucideIcons.info;
  static const privacy = LucideIcons.shieldCheck;
  static const document = LucideIcons.fileText;
  static const profile = LucideIcons.userRound;
  static const edit = LucideIcons.pencil;
  static const next = LucideIcons.chevronRightDir;
  static const back = LucideIcons.arrowLeftDir;
  static const logout = LucideIcons.logOut;
  static const check = LucideIcons.check;
  static const verified = LucideIcons.badgeCheck;
  static const trophy = LucideIcons.trophy;
  static const error = LucideIcons.circleAlert;
  static const wifiOff = LucideIcons.wifiOff;
  static const add = LucideIcons.plus;
  static const camera = LucideIcons.camera;
  static const share = LucideIcons.share2;
  static const userPlus = LucideIcons.userPlus;
  static const checkCircle = LucideIcons.circleCheck;
  static const dot = LucideIcons.circle;
  static const chart = LucideIcons.chartNoAxesCombined;
  static const campaign = LucideIcons.megaphone;
  static const play = LucideIcons.circlePlay;
  static const upload = LucideIcons.cloudUpload;
  static const publish = LucideIcons.rocket;
  static const mail = LucideIcons.mail;
  static const lock = LucideIcons.lockKeyhole;
  static const eye = LucideIcons.eye;
  static const eyeOff = LucideIcons.eyeOff;
  static const keyIcon = LucideIcons.keyRound;
  static const message = LucideIcons.messageCircle;
  static const forward = LucideIcons.arrowRightDir;

  static IconData category(String? value) => switch (value?.trim().toLowerCase()) {
    'phone' || 'phones' || 'smartphone' || '📱' => LucideIcons.smartphone,
    'electronics' || 'headphones' || '🎧' => LucideIcons.headphones,
    'gaming' || 'gamepad' || 'gamepad-2' || '🎮' => LucideIcons.gamepad2,
    'accessories' || 'watch' || '⌚' || '⌚️' => LucideIcons.watch,
    'home' || 'house' || 'home-appliances' || '🏠' => LucideIcons.house,
    'laptop' || '💻' => LucideIcons.laptop,
    'camera' || '📷' => LucideIcons.camera,
    'gift' || '🎁' => LucideIcons.gift,
    _ => LucideIcons.layoutGrid,
  };
}
