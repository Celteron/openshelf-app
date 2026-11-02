import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/shelf_partition.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/statistics.dart';

/// The group a value belongs to; the UI turns it into a label.
sealed class StatKey {
  const StatKey();

  Object get _id;

  @override
  bool operator ==(Object other) =>
      other is StatKey && other.runtimeType == runtimeType && other._id == _id;

  @override
  int get hashCode => Object.hash(runtimeType, _id);
}

class StatMonth extends StatKey {
  final int month;
  const StatMonth(this.month);
  @override
  Object get _id => month;
}

class StatYearKey extends StatKey {
  final int year;
  const StatYearKey(this.year);
  @override
  Object get _id => year;
}

class StatStatus extends StatKey {
  final BookStatus status;
  const StatStatus(this.status);
  @override
  Object get _id => status;
}

class StatFormat extends StatKey {
  final BookFormat format;
  const StatFormat(this.format);
  @override
  Object get _id => format;
}

/// A genre or an author.
class StatText extends StatKey {
  final String text;
  const StatText(this.text);
  @override
  Object get _id => text;
}

class StatLocation extends StatKey {
  final int locationId;
  const StatLocation(this.locationId);
  @override
  Object get _id => locationId;
}

class StatReceivedAs extends StatKey {
  final ReceivedAs value;
  const StatReceivedAs(this.value);
  @override
  Object get _id => value;
}

class StatTag extends StatKey {
  final int tagId;
  const StatTag(this.tagId);
  @override
  Object get _id => tagId;
}

class StatEntry {
  final StatKey key;
  final double value;

  /// The books behind [value], for the drill-down (FR-05-07).
  final Set<int> bookIds;

  const StatEntry(this.key, this.value, this.bookIds);
}

sealed class StatResult {
  const StatResult();
}

/// A tile without grouping. [value] is `null` for an average over nothing.
class StatSingle extends StatResult {
  final double? value;
  final Set<int> bookIds;
  const StatSingle(this.value, this.bookIds);
}

class StatSeries extends StatResult {
  final List<StatEntry> entries;
  const StatSeries(this.entries);
}

/// One value a book adds to a statistic, dated for the period and the time
/// groupings.
typedef _Part = ({Book book, DateTime date, double value});

/// Evaluates a [StatDefinition] over the library (spec 005, T5-02).
///
/// Pure: no database, no framework, so every measure × grouping is unit
/// tested (Constitution IV.2). Rules:
/// - Reading measures count readable books (singles and volumes),
///   collection measures (spending; location and received-as groupings) the
///   physical objects (ADR-0003).
/// - Reading time is actual time only: sessions plus time entered by hand.
/// - Reading measures are dated by the finish date (sessions by their start),
///   collection measures by the date received, else added.
/// - A book counts once per tag and once per author.
abstract final class StatQuery {
  static StatResult evaluate(
    StatDefinition definition, {
    required Iterable<Book> books,
    Iterable<ReadingSession> sessions = const [],
    Map<int, Set<int>> tagsByBook = const {},
  }) {
    final shelf = ShelfPartition.of(books);
    final grouping = definition.grouping;
    final physical =
        definition.measure == StatMeasure.spending ||
        grouping == StatGrouping.location ||
        grouping == StatGrouping.receivedAs;
    final pool = [
      for (final b in physical ? shelf.physical : shelf.readable)
        if (_passes(definition, b, tagsByBook[b.id] ?? const {})) b,
    ];

    final year = switch (definition.period) {
      StatYear(:final year) => year,
      StatAllTime() => null,
    };
    final parts = [
      for (final part in _parts(definition.measure, pool, sessions))
        if (year == null || part.date.year == year) part,
    ];
    final average = definition.measure == StatMeasure.averageRating;

    if (grouping == null) {
      final ids = {for (final p in parts) p.book.id};
      final sum = parts.fold<double>(0, (s, p) => s + p.value);
      return StatSingle(
        average ? (parts.isEmpty ? null : sum / parts.length) : sum,
        ids,
      );
    }

    final sums = <StatKey, double>{};
    final counts = <StatKey, int>{};
    final ids = <StatKey, Set<int>>{};
    for (final part in parts) {
      for (final key in _keys(grouping, part, tagsByBook)) {
        sums[key] = (sums[key] ?? 0) + part.value;
        counts[key] = (counts[key] ?? 0) + 1;
        (ids[key] ??= {}).add(part.book.id);
      }
    }
    StatEntry entry(StatKey key) => StatEntry(
      key,
      average ? sums[key]! / counts[key]! : (sums[key] ?? 0),
      ids[key] ?? const {},
    );

    return StatSeries(switch (grouping) {
      // Every month, empty ones too, so a chart has twelve bars.
      StatGrouping.month => [
        for (var m = 1; m <= 12; m++)
          sums.containsKey(StatMonth(m))
              ? entry(StatMonth(m))
              : StatEntry(StatMonth(m), 0, const {}),
      ],
      StatGrouping.year => [
        for (final key
            in sums.keys.cast<StatYearKey>().toList()
              ..sort((a, b) => a.year.compareTo(b.year)))
          entry(key),
      ],
      _ => [
        for (final key in sums.keys) entry(key),
      ]..sort((a, b) => b.value.compareTo(a.value)),
    });
  }

  static bool _passes(StatDefinition d, Book book, Set<int> tags) =>
      (d.statuses.isEmpty || d.statuses.contains(book.status)) &&
      (d.formats.isEmpty || d.formats.contains(book.format)) &&
      (d.tagIds.isEmpty || d.tagIds.any(tags.contains));

  static DateTime _added(Book book) => book.receivedAt ?? book.createdAt;

  static Iterable<_Part> _parts(
    StatMeasure measure,
    List<Book> pool,
    Iterable<ReadingSession> sessions,
  ) sync* {
    switch (measure) {
      case StatMeasure.books:
        for (final b in pool) {
          yield (book: b, date: _added(b), value: 1);
        }
      case StatMeasure.pagesRead:
        for (final b in pool) {
          final pages = b.pageCount ?? 0;
          if (b.status == BookStatus.read && pages > 0) {
            yield (
              book: b,
              date: BookStatistics.finishedOn(b),
              value: pages.toDouble(),
            );
          }
        }
      case StatMeasure.readingTime:
        final byId = {for (final b in pool) b.id: b};
        for (final s in sessions) {
          final book = byId[s.bookId];
          if (book != null && s.durationSeconds > 0) {
            yield (
              book: book,
              date: s.startedAt,
              value: s.durationSeconds.toDouble(),
            );
          }
        }
        for (final b in pool) {
          final manual = b.readingSeconds ?? 0;
          if (manual > 0) {
            yield (
              book: b,
              date: BookStatistics.finishedOn(b),
              value: manual.toDouble(),
            );
          }
        }
      case StatMeasure.averageRating:
        for (final b in pool) {
          if (b.rating > 0) {
            yield (
              book: b,
              date: BookStatistics.finishedOn(b),
              value: b.rating,
            );
          }
        }
      case StatMeasure.spending:
        for (final b in pool) {
          final cents = b.priceCents ?? 0;
          if (cents > 0) {
            yield (book: b, date: _added(b), value: cents.toDouble());
          }
        }
    }
  }

  static Iterable<StatKey> _keys(
    StatGrouping grouping,
    _Part part,
    Map<int, Set<int>> tagsByBook,
  ) sync* {
    final book = part.book;
    switch (grouping) {
      case StatGrouping.month:
        yield StatMonth(part.date.month);
      case StatGrouping.year:
        yield StatYearKey(part.date.year);
      case StatGrouping.status:
        yield StatStatus(book.status);
      case StatGrouping.format:
        if (book.format case final format?) yield StatFormat(format);
      case StatGrouping.genre:
        final genre = book.genre?.trim() ?? '';
        if (genre.isNotEmpty) yield StatText(genre);
      case StatGrouping.author:
        for (final author in {for (final a in book.authors) a.trim()}) {
          if (author.isNotEmpty) yield StatText(author);
        }
      case StatGrouping.location:
        if (book.locationId case final id?) yield StatLocation(id);
      case StatGrouping.receivedAs:
        if (book.receivedAs case final how?) yield StatReceivedAs(how);
      case StatGrouping.tag:
        for (final tag in tagsByBook[book.id] ?? const <int>{}) {
          yield StatTag(tag);
        }
    }
  }
}
