import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/l10n/app_localizations.dart';

String statMeasureLabel(AppLocalizations l10n, StatMeasure measure) =>
    switch (measure) {
      StatMeasure.books => l10n.statMeasureBooks,
      StatMeasure.pagesRead => l10n.statMeasurePagesRead,
      StatMeasure.readingTime => l10n.statMeasureReadingTime,
      StatMeasure.averageRating => l10n.statMeasureAverageRating,
      StatMeasure.spending => l10n.statMeasureSpending,
    };

String statGroupingLabel(AppLocalizations l10n, StatGrouping grouping) =>
    switch (grouping) {
      StatGrouping.month => l10n.statGroupMonth,
      StatGrouping.year => l10n.statGroupYear,
      StatGrouping.status => l10n.statGroupStatus,
      StatGrouping.format => l10n.statGroupFormat,
      StatGrouping.genre => l10n.statGroupGenre,
      StatGrouping.author => l10n.statGroupAuthor,
      StatGrouping.location => l10n.statGroupLocation,
      StatGrouping.receivedAs => l10n.statGroupReceivedAs,
      StatGrouping.tag => l10n.statGroupTag,
    };

String statChartLabel(AppLocalizations l10n, StatChart chart) =>
    switch (chart) {
      StatChart.number => l10n.statChartNumber,
      StatChart.bar => l10n.statChartBar,
      StatChart.line => l10n.statChartLine,
      StatChart.donut => l10n.statChartDonut,
    };

String statPresetTitle(AppLocalizations l10n, StatPreset preset, int year) =>
    switch (preset) {
      StatPreset.pagesPerMonth => l10n.statPresetPagesPerMonth(year),
      StatPreset.booksByGenre => l10n.statPresetBooksByGenre,
      StatPreset.spendingPerYear => l10n.statPresetSpendingPerYear,
      StatPreset.readingTimePerMonth => l10n.statPresetReadingTimePerMonth(
        year,
      ),
      StatPreset.booksByFormat => l10n.statPresetBooksByFormat,
    };

/// A title for a tile the user did not name.
String statAutoTitle(AppLocalizations l10n, StatDefinition definition) {
  final measure = statMeasureLabel(l10n, definition.measure);
  final grouping = definition.grouping;
  return grouping == null
      ? measure
      : l10n.statAutoTitle(measure, statGroupingLabel(l10n, grouping));
}
