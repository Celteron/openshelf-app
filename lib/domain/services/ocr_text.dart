/// Turns raw OCR output of a book page into text fit for a quote: the hard
/// line breaks of the printed page go, paragraph breaks stay.
String cleanRecognizedText(String raw) {
  final paragraphs = raw
      .replaceAll('\r', '')
      .split(RegExp(r'\n[ \t]*\n+'))
      .map(_joinLines)
      .where((p) => p.isNotEmpty);
  return paragraphs.join('\n\n');
}

String _joinLines(String paragraph) => paragraph
    // "Bei-\nspiel": a word broken at the line end, lower case follows. A
    // capital after the hyphen ("Nord-\nOst") means the hyphen is the
    // word's own, so it stays.
    .replaceAllMapped(
      RegExp(r'(\p{L})-[ \t]*\n[ \t]*(\p{Ll})', unicode: true),
      (m) => '${m[1]}${m[2]}',
    )
    .replaceAll(RegExp(r'[ \t]*\n[ \t]*'), ' ')
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
    .trim();
