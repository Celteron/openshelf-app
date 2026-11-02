import 'package:flutter/foundation.dart';
import 'package:openreads/domain/models/enums.dart';

/// What a user-defined statistic measures (spec 005, FR-05-01). [code] is
/// stored, so renaming a value never breaks a saved tile.
enum StatMeasure {
  books('books'),
  pagesRead('pages_read'),
  readingTime('reading_time'),
  averageRating('average_rating'),
  spending('spending');

  final String code;
  const StatMeasure(this.code);
}

/// How a statistic is grouped (FR-05-02); none means a single number.
enum StatGrouping {
  month('month', isTime: true),
  year('year', isTime: true),
  status('status'),
  format('format'),
  genre('genre'),
  author('author'),
  location('location'),
  receivedAs('received_as'),
  tag('tag');

  final String code;
  final bool isTime;
  const StatGrouping(this.code, {this.isTime = false});
}

/// How a statistic is drawn (FR-05-05).
enum StatChart {
  number('number'),
  bar('bar'),
  line('line'),
  donut('donut');

  final String code;
  const StatChart(this.code);
}

/// The period a statistic covers (FR-05-03).
sealed class StatPeriod {
  const StatPeriod();

  String get code;

  static StatPeriod? tryParse(Object? code) {
    if (code == 'all') return const StatAllTime();
    if (code is String && code.startsWith('year:')) {
      final year = int.tryParse(code.substring(5));
      if (year != null) return StatYear(year);
    }
    return null;
  }
}

class StatAllTime extends StatPeriod {
  const StatAllTime();

  @override
  String get code => 'all';

  @override
  bool operator ==(Object other) => other is StatAllTime;

  @override
  int get hashCode => (StatAllTime).hashCode;
}

class StatYear extends StatPeriod {
  final int year;
  const StatYear(this.year);

  @override
  String get code => 'year:$year';

  @override
  bool operator ==(Object other) => other is StatYear && other.year == year;

  @override
  int get hashCode => year.hashCode;
}

/// One tile of the user-defined statistics (spec 005, T5-01): a typed,
/// immutable definition that is stored as JSON and validated when read back.
@immutable
class StatDefinition {
  final StatMeasure measure;

  /// `null`: a single number.
  final StatGrouping? grouping;
  final StatPeriod period;
  final StatChart chart;

  /// Optional filters (FR-05-04); empty means "all".
  final Set<BookStatus> statuses;
  final Set<BookFormat> formats;
  final Set<int> tagIds;

  const StatDefinition({
    required this.measure,
    this.grouping,
    required this.period,
    required this.chart,
    this.statuses = const {},
    this.formats = const {},
    this.tagIds = const {},
  });

  /// The charts that fit [grouping]: a number without grouping, bars or
  /// lines over time, bars or a donut over categories. A book counts once
  /// per tag, so slices would add up to more than the whole: tags get bars
  /// only.
  static List<StatChart> chartsFor(StatGrouping? grouping) =>
      switch (grouping) {
        null => const [StatChart.number],
        StatGrouping(isTime: true) => const [StatChart.bar, StatChart.line],
        StatGrouping.tag => const [StatChart.bar],
        StatGrouping() => const [StatChart.bar, StatChart.donut],
      };

  Map<String, Object?> toJson() => {
    'measure': measure.code,
    if (grouping != null) 'grouping': grouping!.code,
    'period': period.code,
    'chart': chart.code,
    if (statuses.isNotEmpty) 'statuses': [for (final s in statuses) s.name],
    if (formats.isNotEmpty) 'formats': [for (final f in formats) f.name],
    if (tagIds.isNotEmpty) 'tags': tagIds.toList(),
  };

  factory StatDefinition.fromJson(Map<String, Object?> json) =>
      tryFromJson(json) ??
      (throw FormatException('Invalid statistic definition: $json'));

  /// Reads a stored definition; `null` when a required code is unknown or
  /// the chart does not fit the grouping. Unknown filter values are dropped.
  static StatDefinition? tryFromJson(Map<String, Object?> json) {
    T? byCode<T>(List<T> values, String Function(T) code, Object? value) {
      for (final v in values) {
        if (code(v) == value) return v;
      }
      return null;
    }

    Set<T> named<T extends Enum>(List<T> values, Object? list) => {
      if (list is List)
        for (final item in list)
          if (byCode(values, (T v) => v.name, item) case final v?) v,
    };

    final measure = byCode(StatMeasure.values, (m) => m.code, json['measure']);
    final rawGrouping = json['grouping'];
    final grouping = rawGrouping == null
        ? null
        : byCode(StatGrouping.values, (g) => g.code, rawGrouping);
    final period = StatPeriod.tryParse(json['period']);
    final chart = byCode(StatChart.values, (c) => c.code, json['chart']);
    if (measure == null ||
        (rawGrouping != null && grouping == null) ||
        period == null ||
        chart == null ||
        !chartsFor(grouping).contains(chart)) {
      return null;
    }
    final tags = json['tags'];
    return StatDefinition(
      measure: measure,
      grouping: grouping,
      period: period,
      chart: chart,
      statuses: named(BookStatus.values, json['statuses']),
      formats: named(BookFormat.values, json['formats']),
      tagIds: {
        if (tags is List)
          for (final t in tags)
            if (t is int) t,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StatDefinition &&
      other.measure == measure &&
      other.grouping == grouping &&
      other.period == period &&
      other.chart == chart &&
      setEquals(other.statuses, statuses) &&
      setEquals(other.formats, formats) &&
      setEquals(other.tagIds, tagIds);

  @override
  int get hashCode => Object.hash(
    measure,
    grouping,
    period,
    chart,
    Object.hashAllUnordered(statuses),
    Object.hashAllUnordered(formats),
    Object.hashAllUnordered(tagIds),
  );
}
