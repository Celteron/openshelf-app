import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openreads/core/helpers/price.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/services/stat_query.dart';
import 'package:openreads/features/common/format_count.dart';
import 'package:openreads/features/common/format_duration.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Opens the books behind a value (FR-05-07).
typedef StatBooksCallback = void Function(String label, Set<int> bookIds);

/// Draws one user-defined statistic (spec 005, FR-05-05): a number, bars or
/// a line over time, rows of bars or a donut over categories.
///
/// Every value leads to its books through [onBooks]; narrow targets (twelve
/// bars, small slices) open a sheet of full-height rows instead.
class StatTileView extends StatelessWidget {
  /// Prefix of the keys inside the tile.
  final String id;
  final String title;
  final StatDefinition definition;
  final StatResult result;

  /// The names behind tag and location keys.
  final StatLibrary library;
  final StatBooksCallback? onBooks;

  /// E.g. the tile menu.
  final Widget? trailing;

  /// Category rows and donut slices shown before the rest is grouped.
  static const maxCategories = 8;

  const StatTileView({
    super.key,
    required this.id,
    required this.title,
    required this.definition,
    required this.result,
    this.library = const StatLibrary(),
    this.onBooks,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    key: const ValueKey('stat-tile-title'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _body(context),
            ),
            if (definition.grouping == StatGrouping.tag)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.statTagsCountTwice,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final label = _StatLabels(context, definition.measure, library);
    return switch (result) {
      StatSingle(:final value, :final bookIds) => _Number(
        id: id,
        text: label.value(value),
        semantics: '$title: ${label.value(value)}',
        onTap: onBooks == null || bookIds.isEmpty
            ? null
            : () => onBooks!(title, bookIds),
      ),
      StatSeries(:final entries)
          when entries.isEmpty || entries.every((e) => e.value == 0) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(AppLocalizations.of(context).statNoData),
        ),
      StatSeries(:final entries) => switch (definition.chart) {
        StatChart.donut => _Donut(
          id: id,
          entries: _withOther(context, entries),
          label: label,
          onBooks: onBooks,
        ),
        StatChart.line ||
        StatChart.bar when definition.grouping?.isTime ?? false => _TimeChart(
          id: id,
          title: title,
          line: definition.chart == StatChart.line,
          entries: entries,
          label: label,
          onBooks: onBooks,
        ),
        _ => _CategoryRows(
          id: id,
          title: title,
          entries: entries,
          label: label,
          onBooks: onBooks,
        ),
      },
    };
  }

  /// The largest slices, the rest merged into "Other" (FR-05-05).
  static List<(String?, StatEntry)> _withOther(
    BuildContext context,
    List<StatEntry> entries,
  ) {
    final sorted = [...entries]..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length <= maxCategories) {
      return [for (final e in sorted) (null, e)];
    }
    final rest = sorted.skip(maxCategories - 1);
    return [
      for (final e in sorted.take(maxCategories - 1)) (null, e),
      (
        AppLocalizations.of(context).statOther,
        StatEntry(rest.first.key, rest.fold(0, (sum, e) => sum + e.value), {
          for (final e in rest) ...e.bookIds,
        }),
      ),
    ];
  }
}

/// Turns keys and values into text for one measure.
class _StatLabels {
  final BuildContext context;
  final StatMeasure measure;
  final StatLibrary library;

  _StatLabels(this.context, this.measure, this.library);

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  String key(StatKey key) {
    final l10n = AppLocalizations.of(context);
    return switch (key) {
      StatMonth(:final month) => DateFormat.MMMM(
        _locale,
      ).format(DateTime(2000, month)),
      StatYearKey(:final year) => '$year',
      StatStatus(:final status) => statusLabel(l10n, status),
      StatFormat(:final format) => formatLabel(l10n, format),
      StatText(:final text) => text,
      StatLocation(:final locationId) =>
        library.locationNames[locationId] ?? '–',
      StatReceivedAs(:final value) => receivedAsLabel(l10n, value),
      StatTag(:final tagId) => library.tagNames[tagId] ?? '–',
    };
  }

  /// A short key for a chart axis.
  String axis(StatKey key) => switch (key) {
    StatMonth(:final month) => '$month',
    StatYearKey(:final year) => '$year',
    _ => this.key(key),
  };

  String value(double? value) {
    if (value == null) return '–';
    return switch (measure) {
      StatMeasure.books ||
      StatMeasure.pagesRead => formatCount(context, value.round()),
      StatMeasure.readingTime => formatDurationSeconds(
        AppLocalizations.of(context),
        value.round(),
      ),
      StatMeasure.averageRating => NumberFormat('0.0', _locale).format(value),
      StatMeasure.spending => formatPriceCents(value.round(), _locale),
    };
  }

  String summary(String title, Iterable<StatEntry> entries) =>
      '$title: ${[for (final e in entries) '${key(e.key)} ${value(e.value)}'].join(', ')}';
}

class _Number extends StatelessWidget {
  final String id;
  final String text;
  final String semantics;
  final VoidCallback? onTap;

  const _Number({
    required this.id,
    required this.text,
    required this.semantics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: semantics,
    button: onTap != null,
    excludeSemantics: true,
    container: true,
    child: InkWell(
      key: ValueKey('$id-value'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: Theme.of(context).textTheme.displaySmall),
        ),
      ),
    ),
  );
}

/// Bars or a line over months or years. The chart is one tap target that
/// opens the entries as rows (FR-05-07).
class _TimeChart extends StatelessWidget {
  final String id;
  final String title;
  final bool line;
  final List<StatEntry> entries;
  final _StatLabels label;
  final StatBooksCallback? onBooks;

  const _TimeChart({
    required this.id,
    required this.title,
    required this.line,
    required this.entries,
    required this.label,
    required this.onBooks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final maxY = entries.fold<double>(0, (m, e) => math.max(m, e.value));
    final titles = FlTitlesData(
      leftTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            return SideTitleWidget(
              meta: meta,
              child: Text(
                i >= 0 && i < entries.length ? label.axis(entries[i].key) : '',
                style: theme.textTheme.labelSmall,
              ),
            );
          },
        ),
      ),
    );
    final chart = line
        ? LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY == 0 ? 1 : maxY * 1.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: titles,
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (final (i, e) in entries.indexed)
                      FlSpot(i.toDouble(), e.value),
                  ],
                  color: color,
                  barWidth: 3,
                  isCurved: false,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          )
        : BarChart(
            BarChartData(
              maxY: maxY == 0 ? 1 : maxY * 1.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: titles,
              barTouchData: BarTouchData(enabled: false),
              barGroups: [
                for (final (i, e) in entries.indexed)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        width: 12,
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
    return Semantics(
      label: label.summary(title, entries),
      button: onBooks != null,
      excludeSemantics: true,
      container: true,
      child: InkWell(
        key: ValueKey('$id-chart'),
        borderRadius: BorderRadius.circular(8),
        onTap: onBooks == null
            ? null
            : () => _showEntries(context, id, title, entries, label, onBooks!),
        child: SizedBox(height: 160, child: chart),
      ),
    );
  }
}

/// Categories as labelled bar rows, the largest first; each row is a tap
/// target, and beyond [StatTileView.maxCategories] a row opens all of them.
class _CategoryRows extends StatelessWidget {
  final String id;
  final String title;
  final List<StatEntry> entries;
  final _StatLabels label;
  final StatBooksCallback? onBooks;

  const _CategoryRows({
    required this.id,
    required this.title,
    required this.entries,
    required this.label,
    required this.onBooks,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final max = entries.fold<double>(0, (m, e) => math.max(m, e.value));
    final shown = entries.take(StatTileView.maxCategories);
    return Column(
      children: [
        for (final e in shown)
          _BarRow(
            text: label.key(e.key),
            value: label.value(e.value),
            share: max == 0 ? 0 : e.value / max,
            onTap: onBooks == null
                ? null
                : () => onBooks!(label.key(e.key), e.bookIds),
          ),
        if (entries.length > StatTileView.maxCategories)
          ListTile(
            key: ValueKey('$id-all'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.statShowAll(entries.length)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showEntries(context, id, title, entries, label, onBooks),
          ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String text;
  final String value;
  final double share;
  final VoidCallback? onTap;

  const _BarRow({
    required this.text,
    required this.value,
    required this.share,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
                  Text(value),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 6,
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A donut with a legend of full-height rows (the slices are too small to
/// hit reliably).
class _Donut extends StatelessWidget {
  final String id;

  /// A slice and, for "Other", its label.
  final List<(String?, StatEntry)> entries;
  final _StatLabels label;
  final StatBooksCallback? onBooks;

  const _Donut({
    required this.id,
    required this.entries,
    required this.label,
    required this.onBooks,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      scheme.primary,
      scheme.tertiary,
      scheme.secondary,
      scheme.error,
      scheme.primaryContainer,
      scheme.tertiaryContainer,
      scheme.secondaryContainer,
      scheme.outline,
    ];
    String text((String?, StatEntry) slice) =>
        slice.$1 ?? label.key(slice.$2.key);
    return Column(
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 44,
                sectionsSpace: 2,
                startDegreeOffset: -90,
                sections: [
                  for (final (i, slice) in entries.indexed)
                    PieChartSectionData(
                      value: slice.$2.value,
                      color: colors[i % colors.length],
                      radius: 26,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
        ),
        for (final (i, slice) in entries.indexed)
          InkWell(
            key: ValueKey('$id-slice-$i'),
            onTap: onBooks == null
                ? null
                : () => onBooks!(text(slice), slice.$2.bookIds),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text(slice))),
                  Text(label.value(slice.$2.value)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// All entries as rows of full height (FR-05-07).
Future<void> _showEntries(
  BuildContext context,
  String id,
  String title,
  List<StatEntry> entries,
  _StatLabels label,
  StatBooksCallback? onBooks,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final (i, e) in entries.indexed)
            ListTile(
              key: ValueKey('$id-entry-$i'),
              enabled: onBooks != null && e.bookIds.isNotEmpty,
              title: Text(label.key(e.key)),
              trailing: Text(label.value(e.value)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onBooks?.call(label.key(e.key), e.bookIds);
              },
            ),
        ],
      ),
    ),
  ),
);
