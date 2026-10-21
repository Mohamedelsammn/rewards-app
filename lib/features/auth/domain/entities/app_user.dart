import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  const UserStats({this.points = 0, this.giveaways = 0, this.orders = 0});

  /// Current balance (same source as `GET /wallet`).
  final int points;

  /// Number of giveaway entries / orders the user created (all statuses).
  final int giveaways;
  final int orders;

  @override
  List<Object?> get props => [points, giveaways, orders];
}

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.language,
    required this.status,
    this.avatarId,
    this.avatarImageUrl,
    this.createdAt,
    this.stats = const UserStats(),
  });

  final String id;
  final String email;
  final String name;
  final String language;
  final String status;

  /// Bundled characters use ids 1–9; `null` when no avatar is selected.
  final int? avatarId;
  final String? avatarImageUrl;
  final DateTime? createdAt;
  final UserStats stats;

  AppUser copyWith({UserStats? stats}) => AppUser(
    id: id,
    email: email,
    name: name,
    language: language,
    status: status,
    avatarId: avatarId,
    avatarImageUrl: avatarImageUrl,
    createdAt: createdAt,
    stats: stats ?? this.stats,
  );

  @override
  List<Object?> get props => [id, email, name, language, status, avatarId, avatarImageUrl, stats];
}
