import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/stat_definition.dart';

/// Tile definitions of user-defined statistics (spec 005, T5-01).
void main() {
  group('JSON round trip', () {
    test('a full definition survives encode and decode', () {
      const definition = StatDefinition(
        measure: StatMeasure.pagesRead,
        grouping: StatGrouping.month,
        period: StatYear(2026),
        chart: StatChart.bar,
        statuses: {BookStatus.read},
        formats: {BookFormat.hardcover},
        tagIds: {3, 7},
      );

      final decoded = StatDefinition.fromJson(definition.toJson());

      expect(decoded, definition);
    });

    test('a single number over all time', () {
      const definition = StatDefinition(
        measure: StatMeasure.books,
        period: StatAllTime(),
        chart: StatChart.number,
      );
      expect(StatDefinition.fromJson(definition.toJson()), definition);
    });

    test('codes are stable strings, not enum names', () {
      const definition = StatDefinition(
        measure: StatMeasure.readingTime,
        grouping: StatGrouping.receivedAs,
        period: StatAllTime(),
        chart: StatChart.donut,
      );
      final json = definition.toJson();
      expect(json['measure'], 'reading_time');
      expect(json['grouping'], 'received_as');
      expect(json['period'], 'all');
    });
  });

  group('defensive decoding', () {
    test('unknown codes or broken JSON give null, never a crash', () {
      expect(StatDefinition.tryFromJson({'measure': 'nope'}), isNull);
      expect(StatDefinition.tryFromJson({'measure': 'books'}), isNull);
      expect(StatDefinition.tryFromJson(const {}), isNull);
      expect(
        StatDefinition.tryFromJson({
          'measure': 'books',
          'period': 'year:abc',
          'chart': 'bar',
        }),
        isNull,
      );
    });

    test('unknown filter values are dropped, the tile stays', () {
      final decoded = StatDefinition.tryFromJson({
        'measure': 'books',
        'period': 'all',
        'chart': 'number',
        'statuses': ['read', 'nope'],
      });
      expect(decoded?.statuses, {BookStatus.read});
    });
  });

  group('chart choices (FR-05-05)', () {
    test('a single number has no chart but the number', () {
      expect(StatDefinition.chartsFor(null), [StatChart.number]);
    });

    test('time groupings offer bars and lines', () {
      expect(StatDefinition.chartsFor(StatGrouping.month), [
        StatChart.bar,
        StatChart.line,
      ]);
    });

    test('categories offer bars and a donut, tags only bars', () {
      expect(StatDefinition.chartsFor(StatGrouping.genre), [
        StatChart.bar,
        StatChart.donut,
      ]);
      expect(StatDefinition.chartsFor(StatGrouping.tag), [StatChart.bar]);
    });

    test('a definition with a chart that does not fit is invalid', () {
      expect(
        StatDefinition.tryFromJson({
          'measure': 'books',
          'grouping': 'tag',
          'period': 'all',
          'chart': 'donut',
        }),
        isNull,
      );
    });
  });

  group('editing (builder)', () {
    const base = StatDefinition(
      measure: StatMeasure.books,
      grouping: StatGrouping.genre,
      period: StatAllTime(),
      chart: StatChart.donut,
    );

    test('a new grouping keeps a fitting chart, else takes the first', () {
      expect(base.withGrouping(StatGrouping.author).chart, StatChart.donut);
      expect(base.withGrouping(StatGrouping.month).chart, StatChart.bar);
      expect(base.withGrouping(StatGrouping.tag).chart, StatChart.bar);
      final single = base.withGrouping(null);
      expect(single.grouping, isNull);
      expect(single.chart, StatChart.number);
    });

    test('copyWith changes only what it is given', () {
      final edited = base.copyWith(
        measure: StatMeasure.spending,
        period: const StatYear(2025),
        statuses: {BookStatus.read},
      );
      expect(edited.measure, StatMeasure.spending);
      expect(edited.period, const StatYear(2025));
      expect(edited.statuses, {BookStatus.read});
      expect(edited.grouping, StatGrouping.genre);
      expect(edited.chart, StatChart.donut);
    });
  });

  group('presets (spec 005, 4.3)', () {
    test('every preset is a valid definition that survives storage', () {
      for (final preset in StatPreset.values) {
        final definition = preset.definition(2026);
        expect(
          StatDefinition.tryFromJson(definition.toJson()),
          definition,
          reason: preset.name,
        );
      }
    });

    test('time presets cover the given year, collection ones all time', () {
      expect(
        StatPreset.pagesPerMonth.definition(2026).period,
        const StatYear(2026),
      );
      expect(
        StatPreset.booksByGenre.definition(2026).period,
        const StatAllTime(),
      );
    });
  });
}
