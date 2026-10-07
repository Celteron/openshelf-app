/// How the library list is laid out (Openreads `DisplayType`).
enum LibraryDisplayType {
  list,
  compactList,
  grid,
  detailedGrid;

  bool get isGrid => this == grid || this == detailedGrid;

  static LibraryDisplayType parse(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => LibraryDisplayType.list,
  );
}

/// Whether ratings are drawn as stars or as a number (Openreads `RatingType`).
enum RatingDisplay {
  bar,
  number;

  static RatingDisplay parse(String? name) =>
      values.firstWhere((v) => v.name == name, orElse: () => RatingDisplay.bar);
}
