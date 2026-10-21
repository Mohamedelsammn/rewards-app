/// Builds a shuffled wedge label list for [WinnerWheel] that always
/// includes [winnerLabel] exactly once. [decoyLabels] are already-loaded
/// client data (e.g. Recent Participants' codes) -- deduplicated against
/// the winner and capped at [maxDecoys] before shuffling, never a fresh
/// full-participant-list fetch (the actual winner decision is already
/// server-side and final by the time this runs; these are purely decorative
/// wedges). [shuffle] is injectable purely so tests can assert deterministic
/// output -- production callers rely on the default (a real shuffle).
///
/// Returns the label list plus the winner's index within it, which is
/// exactly what [WinnerWheel] needs to know which wedge to land on --
/// whether [winnerLabel] came from a random pick or a manually targeted
/// participant is invisible here, by design (see [WinnerWheel]'s doc
/// comment on why manual mode must never look different).
({List<String> labels, int winningIndex}) buildWheelSegments({
  required String winnerLabel,
  required List<String> decoyLabels,
  int maxDecoys = 9,
  void Function(List<Object?>)? shuffle,
}) {
  final doShuffle = shuffle ?? (list) => list.shuffle();

  final pool = decoyLabels.where((code) => code != winnerLabel).toSet().toList();
  doShuffle(pool);

  final labels = [...pool.take(maxDecoys), winnerLabel];
  doShuffle(labels);

  return (labels: labels, winningIndex: labels.indexOf(winnerLabel));
}
