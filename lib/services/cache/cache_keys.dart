/// Cache key + TTL policy, one place to see the classification from the
/// brief: static / semi-static / frequently-changing / user-specific /
/// server-authoritative (never cached).
class CacheKeys {
  const CacheKeys._();

  static const String giveawayList = 'giveaways:list';
  static String giveawayDetails(String id) => 'giveaway:$id';
  static const String myParticipations = 'participations:mine';

  /// Giveaway list changes when admins publish/edit -- short TTL so a newly
  /// published giveaway shows up quickly without polling.
  static const Duration giveawayListTtl = Duration(minutes: 2);

  /// A single giveaway's static fields (title, prize, rules) rarely change
  /// after publish; participant_count is the only fast-moving field, and a
  /// slightly-stale count on the details screen is an acceptable tradeoff
  /// for not re-fetching on every navigation.
  static const Duration giveawayDetailsTtl = Duration(minutes: 5);

  /// User-specific, changes only when the user (this device) participates.
  static const Duration myParticipationsTtl = Duration(minutes: 3);
}
