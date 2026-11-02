/// Domain-level enumerations shared by the data layer, domain services, and
/// the presentation layer.
///
/// These are persisted by Drift via `textEnum<T>()`, which stores each value's
/// `.name` string in a TEXT column.
library;

enum BookStatus { unread, reading, read, dnf, wishlist, reReading }

enum BookFormat { hardcover, paperback, ebook, audiobook }

enum LocationType { room, shelf, compartment }

enum MetadataSource { dnb, googleBooks, openLibrary, manual }

enum NoteKind { note, quote }

/// How a book came into the library. Stored as [code], an integer pinned per
/// value (one byte at most in SQLite), so reordering or adding values never
/// changes what existing rows mean. Exports use [name].
enum ReceivedAs {
  purchase(0),
  gift(1),
  loan(2),
  reviewCopy(3),
  other(4);

  final int code;
  const ReceivedAs(this.code);

  /// Unknown codes (e.g. from a newer app version) read as [other].
  static ReceivedAs fromCode(int code) =>
      values.firstWhere((r) => r.code == code, orElse: () => ReceivedAs.other);
}
