/// Cache key + TTL policy, one place to see the classification from the
/// brief: static / semi-static / frequently-changing / user-specific /
/// server-authoritative (never cached).
class CacheKeys {
  const CacheKeys._();

  static const String giveawayList = 'giveaways:list';
  static String giveawayDetails(String id) => 'giveaway:$id';

  /// Scoped by the *current session's* `auth.uid()`, not a flat key. Two
  /// different identities using the same device (e.g. this device's
  /// anonymous session was ever lost/replaced -- see UserIdentityService)
  /// must never read each other's cached participation list; only the
  /// signing-out-and-back-in-as-the-SAME-identity case, where auth.uid()
  /// is unchanged, should ever see this cache reused.
  static String myParticipations(String authUid) => 'participations:mine:$authUid';

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
