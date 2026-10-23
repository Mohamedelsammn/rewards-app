/// Splits backend rules text into display items without adding or dropping
/// content: one item per non-empty line; a single paragraph is split after
/// sentence-ending punctuation (Latin and Arabic). List markers already
/// present ("1.", "-", "•") are removed because the UI numbers the items.
List<String> splitGiveawayRules(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  final lines = trimmed
      .split(RegExp(r'\r?\n'))
      .map(_stripMarker)
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.length > 1) return lines;
  return trimmed
      .split(RegExp(r'(?<=[.!?؟؛])\s+'))
      .map((sentence) => sentence.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
}

String _stripMarker(String line) =>
    line.trim().replaceFirst(RegExp(r'^(\d+[.)]|[-•*–])\s*'), '').trim();
