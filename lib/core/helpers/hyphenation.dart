/// Syllable breaks for the long German words of the interface.
///
/// Flutter wraps a word that is wider than its line at an arbitrary letter
/// ("Lesegeschw|indigkeit"), and soft hyphens would break at syllables but
/// draw no hyphen. So the interface breaks such words itself, from this list
/// (see `HyphenatedText`). Syllables are separated by "-"; the lookup ignores
/// case. A test fails when a new German string brings a long word that is
/// missing here.
library;

const germanHyphenationWords = <String>[
  'Lese-ge-schwin-dig-keit',
  'Lese-fort-schritt',
  'Lese-sit-zun-gen',
  'Lese-zeit-raum',
  'Lese-ka-len-der',
  'Re-zen-si-ons-ex-em-plar',
  'wie-der-her-ge-stellt',
  'wie-der-her-stell-bar',
  'wie-der-her-stel-len',
  'Durch-schnitt-li-che',
  'Durch-schnitt',
  'Durch-schnit-te',
  'Durch-schnitts-be-wer-tung',
  'Er-schei-nungs-jahr',
  'ver-voll-stän-di-gen',
  'Hin-ter-grund-bild',
  'fehl-ge-schla-gen',
  'Zwi-schen-ab-la-ge',
  'un-wi-der-ruf-lich',
  'Stan-dard-for-mat',
  'Stan-dard-sta-tus',
  'zu-rück-set-zen',
  'Zu-rück-ge-ge-ben',
  'Ein-kaufs-lis-te',
  'Ein-stel-lun-gen',
  'Text-er-ken-nung',
  'Ras-ter-an-sicht',
  'Lis-ten-an-sicht',
  'De-tail-lier-tes',
  'Voll-stän-di-ges',
  'ab-ge-schlos-sen',
  'fo-to-gra-fie-ren',
  'nach-schla-gen',
  'Län-gen-an-ga-be',
  'Über-sprun-gen',
  'Über-sprin-gen',
  'Ak-tu-a-li-siert',
  'Dank-sa-gun-gen',
  'Be-schrei-bung',
  'Sys-tem-far-ben',
  'aus-ge-schöpft',
  'aus-ge-blen-det',
  'Im-port-for-mat',
  'tat-säch-li-che',
  'Han-dy-wech-sel',
  'nach-ein-an-der',
  'Hin-zu-ge-füg-te',
  'Bi-blio-thek',
  'Sta-tis-ti-ken',
  'Wunsch-lis-te',
  'Be-wer-tun-gen',
];

/// Letters before a break and after it, so that no line ends or starts with a
/// lone letter ("Lesegeschwindigkei-" / "t").
const _minBefore = 2;
const _minAfter = 3;

const _letters = 'A-Za-zÄÖÜäöüß';
final _word = RegExp('^([^$_letters]*)([$_letters]+)(.*)\$');

final Map<String, List<int>> _syllableEnds = {
  for (final entry in germanHyphenationWords)
    entry.replaceAll('-', '').toLowerCase(): _ends(entry),
};

/// Where each syllable of [hyphenated] ends, as an index into the plain word.
List<int> _ends(String hyphenated) {
  final ends = <int>[];
  var length = 0;
  final parts = hyphenated.split('-');
  for (final part in parts.take(parts.length - 1)) {
    length += part.length;
    ends.add(length);
  }
  return ends;
}

/// The indices in [word] at which it may be broken (the first part is
/// `word.substring(0, index)`). Empty for words that are not in the list.
/// Punctuation around the word is ignored.
List<int> hyphenationPoints(String word) {
  final match = _word.firstMatch(word);
  if (match == null) return const [];
  final lead = match[1]!.length;
  final core = match[2]!;
  final ends = _syllableEnds[core.toLowerCase()];
  if (ends == null) return const [];
  final tail = word.length - lead - core.length;
  return [
    for (final end in ends)
      if (end >= _minBefore && core.length - end + tail >= _minAfter)
        lead + end,
  ];
}

/// Breaks [text] into lines of at most [maxWidth], hyphenating a word only
/// when it is wider than a whole line. [measure] gives a string's width.
///
/// A word that does not fit the rest of the line moves to the next one when
/// it fits there. A word wider than any line is split at its latest syllable
/// that fits, with a hyphen. A word without usable break points is left whole
/// for the text engine to wrap.
List<String> breakIntoLines(
  String text,
  double maxWidth,
  double Function(String) measure,
) {
  final lines = <String>[];
  var current = '';
  for (final word in text.split(' ')) {
    final candidate = current.isEmpty ? word : '$current $word';
    if (measure(candidate) <= maxWidth) {
      current = candidate;
      continue;
    }
    if (current.isNotEmpty && measure(word) <= maxWidth) {
      lines.add(current);
      current = word;
      continue;
    }

    final points = hyphenationPoints(word);
    var start = 0;
    while (measure(word.substring(start)) > maxWidth) {
      final prefix = current.isEmpty ? '' : '$current ';
      int? best;
      for (final p in points) {
        if (p - start < _minBefore) continue;
        if (measure('$prefix${word.substring(start, p)}-') <= maxWidth) {
          best = p;
        }
      }
      if (best == null) {
        // Nothing fits: leave the rest to the text engine.
        if (current.isEmpty) break;
        lines.add(current);
        current = '';
        continue;
      }
      lines.add('$prefix${word.substring(start, best)}-');
      current = '';
      start = best;
    }
    current = current.isEmpty
        ? word.substring(start)
        : '$current ${word.substring(start)}';
  }
  lines.add(current);
  return lines;
}
