import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:openreads/core/helpers/price.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/features/common/format_count.dart';
import 'package:openreads/features/common/format_duration.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/domain/models/statistics.dart';
import 'package:openreads/features/statistics/statistics_books_screen.dart';
import 'package:openreads/features/statistics/statistics_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Statistics dashboard: totals, status breakdown, pages read, top locations
/// and top authors (spec §6.5).
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StatisticsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          if (state is StatisticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StatisticsError) {
            return Center(child: Text(l10n.errorLoadingLibrary));
          }
          if (state is! StatisticsLoaded) {
            return const SizedBox.shrink();
          }
          final stats = state.statistics;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (stats.years.isNotEmpty) ...[
                _YearSelector(stats: stats),
                const SizedBox(height: 16),
              ],
              _SectionHeader('section-overview', l10n.statsSectionOverview),
              _SummaryCards(stats: stats),
              const SizedBox(height: 16),
              _GoalCard(goal: stats.goal),
              const SizedBox(height: 16),
              _SectionHeader('section-reading', l10n.statsSectionReading),
              _ReadingCard(stats: stats),
              const SizedBox(height: 16),
              if (stats.monthly.isNotEmpty) ...[
                _MonthlyBarChart(
                  key: const ValueKey('chart-books'),
                  id: 'chart-books',
                  title: l10n.finishedBooksByMonth,
                  values: [for (final m in stats.monthly) m.books],
                  onMonth: (month) => _openMonth(context, stats, month),
                ),
                const SizedBox(height: 16),
                _MonthlyBarChart(
                  key: const ValueKey('chart-pages'),
                  id: 'chart-pages',
                  title: l10n.finishedPagesByMonth,
                  values: [for (final m in stats.monthly) m.pages],
                  onMonth: (month) => _openMonth(context, stats, month),
                ),
                const SizedBox(height: 16),
                _MonthlyBarChart(
                  key: const ValueKey('chart-added'),
                  id: 'chart-added',
                  title: l10n.addedBooksByMonth,
                  values: [for (final m in stats.monthly) m.added],
                ),
                const SizedBox(height: 16),
              ],
              _SectionHeader('section-records', l10n.statsSectionRecords),
              _AveragesCard(stats: stats),
              const SizedBox(height: 16),
              _SectionHeader('section-library', l10n.statsSectionLibrary),
              _StatusBreakdown(stats: stats),
              if (stats.unreadStack.isNotEmpty) ...[
                const SizedBox(height: 16),
                _MonthlyBarChart(
                  key: const ValueKey('chart-unread-stack'),
                  id: 'chart-unread-stack',
                  title: l10n.unreadStackByMonth,
                  values: stats.unreadStack,
                ),
              ],
              if (stats.receivedAs.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ReceivedAsCard(stats: stats),
              ],
              if (stats.spendingByYear.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SpendingCard(stats: stats),
              ],
              const SizedBox(height: 16),
              _TopList(
                title: l10n.topLocations,
                icon: Icons.shelves,
                entries: stats.topLocations,
                emptyText: l10n.noLocationsYet,
              ),
              const SizedBox(height: 16),
              _TopList(
                title: l10n.topAuthors,
                icon: Icons.person,
                entries: stats.topAuthors,
                emptyText: l10n.noBooksYet,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Title of a group of statistics (FR-R2-15).
class _SectionHeader extends StatelessWidget {
  final String id;
  final String title;
  const _SectionHeader(this.id, this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// One invisible tap target per month over a monthly chart (FR-R2-17).
class _MonthTapTargets extends StatelessWidget {
  final String id;
  final ValueChanged<int>? onMonth;
  final Widget child;

  const _MonthTapTargets({
    required this.id,
    required this.onMonth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final onMonth = this.onMonth;
    if (onMonth == null) return child;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Row(
            children: [
              for (var m = 1; m <= 12; m++)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: DateFormat.MMMM(locale).format(DateTime(2000, m)),
                    child: InkWell(
                      key: ValueKey('$id-month-$m'),
                      onTap: () => onMonth(m),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Physical objects by how they were received (FR-R2-18).
class _ReceivedAsCard extends StatelessWidget {
  final BookStatistics stats;
  const _ReceivedAsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = stats.receivedAs.values.fold(0, (sum, n) => sum + n);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fieldReceivedAs,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final how in ReceivedAs.values)
              if (stats.receivedAs[how] case final count?)
                _StatusRow(
                  label: receivedAsLabel(l10n, how),
                  count: count,
                  total: total,
                ),
          ],
        ),
      ),
    );
  }
}

/// Money spent per year, newest first (FR-R2-18).
class _SpendingCard extends StatelessWidget {
  final BookStatistics stats;
  const _SpendingCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final years = stats.spendingByYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.spendingByYear,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final year in years)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$year'),
                    Text(formatPriceCents(stats.spendingByYear[year]!, locale)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _openBooks(BuildContext context, String title, List<Book> books) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatisticsBooksScreen(title: title, books: books),
      ),
    );

void _openMonth(BuildContext context, BookStatistics stats, int month) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final date = DateTime(stats.year ?? 2000, month);
  final title = stats.year == null
      ? DateFormat.MMMM(locale).format(date)
      : DateFormat.yMMMM(locale).format(date);
  _openBooks(context, title, stats.finishedIn(month));
}

class _SummaryCards extends StatelessWidget {
  final BookStatistics stats;
  const _SummaryCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _Card(
            icon: Icons.book,
            label: l10n.totalBooks,
            value: formatCount(context, stats.totalBooks),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Card(
            icon: Icons.auto_stories,
            label: l10n.pagesRead,
            value: formatCount(context, stats.pagesRead),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Card({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final BookStatistics stats;
  const _StatusBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = stats.totalBooks;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fieldStatus,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final status in BookStatus.values)
              InkWell(
                key: ValueKey('status-books-${status.name}'),
                onTap: () => _openBooks(
                  context,
                  _statusName(context, status),
                  stats.withStatus(status),
                ),
                child: _StatusRow(
                  label: _statusName(context, status),
                  count: stats.statusCounts[status] ?? 0,
                  total: total,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text('$count')],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: fraction, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<NameCount> entries;
  final String emptyText;
  const _TopList({
    required this.title,
    required this.icon,
    required this.entries,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(emptyText),
              )
            else
              for (final entry in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon),
                  title: Text(entry.name),
                  trailing: Text(formatCount(context, entry.count)),
                ),
          ],
        ),
      ),
    );
  }
}

String _statusName(BuildContext context, BookStatus status) =>
    statusLabel(AppLocalizations.of(context), status);

/// Yearly reading goal: progress towards the target, remaining books and the
/// pace relative to an even distribution over the year (Phase 2, US-D).
class _GoalCard extends StatelessWidget {
  final GoalProgress? goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<StatisticsCubit>();
    final theme = Theme.of(context);
    final goal = this.goal;
    final year = goal?.year ?? cubit.goalYear;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.goalTitle(year),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (goal != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n.editGoal,
                    onPressed: () =>
                        _edit(context, goal.target, goal.targetPages),
                  ),
                if (goal != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.clearGoal,
                    onPressed: cubit.clearGoal,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (goal == null) ...[
              Text(l10n.noGoalYet(year)),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => _edit(context, null, null),
                child: Text(l10n.setGoal),
              ),
            ] else ...[
              if (goal.hasBookGoal) ...[
                Text(
                  l10n.goalProgress(goal.completed, goal.target),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    key: const ValueKey('goal-progress'),
                    value: goal.fraction,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_summary(l10n, goal)),
              ],
              if (goal.hasPageGoal) ...[
                if (goal.hasBookGoal) const SizedBox(height: 16),
                Text(
                  l10n.goalPagesProgress(goal.pagesRead, goal.targetPages!),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    key: const ValueKey('goal-pages-progress'),
                    value: goal.pagesFraction,
                    minHeight: 8,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _summary(AppLocalizations l10n, GoalProgress goal) {
    if (goal.reached) return l10n.goalReached;
    final delta = goal.paceDelta.round();
    final pace = delta == 0
        ? l10n.goalOnTrack
        : delta > 0
        ? l10n.goalAhead(delta)
        : l10n.goalBehind(-delta);
    return '${l10n.goalRemaining(goal.remaining)} · $pace';
  }

  Future<void> _edit(
    BuildContext context,
    int? currentBooks,
    int? currentPages,
  ) async {
    final cubit = context.read<StatisticsCubit>();
    final target = await showDialog<_GoalInput>(
      context: context,
      builder: (_) =>
          _GoalDialog(initialBooks: currentBooks, initialPages: currentPages),
    );
    if (target != null) {
      await cubit.setGoal(target.books, targetPages: target.pages);
    }
  }
}

class _GoalInput {
  final int books;
  final int? pages;
  const _GoalInput(this.books, this.pages);
}

class _GoalDialog extends StatefulWidget {
  final int? initialBooks;
  final int? initialPages;
  const _GoalDialog({required this.initialBooks, required this.initialPages});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: (widget.initialBooks ?? 0) > 0 ? widget.initialBooks.toString() : '',
  );
  late final TextEditingController _pagesController = TextEditingController(
    text: widget.initialPages?.toString() ?? '',
  );
  bool _invalid = false;
  bool _pagesInvalid = false;

  @override
  void dispose() {
    _controller.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  void _submit() {
    final booksText = _controller.text.trim();
    final books = booksText.isEmpty ? 0 : int.tryParse(booksText);
    final pagesText = _pagesController.text.trim();
    final pages = pagesText.isEmpty ? null : int.tryParse(pagesText);
    final pagesInvalid = pagesText.isNotEmpty && (pages == null || pages <= 0);
    // A book goal, a page goal or both (Openreads); at least one is needed.
    final booksInvalid =
        books == null || books < 0 || (books == 0 && pages == null);
    if (booksInvalid || pagesInvalid) {
      setState(() {
        _invalid = booksInvalid;
        _pagesInvalid = pagesInvalid;
      });
      return;
    }
    Navigator.pop(context, _GoalInput(books, pages));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.initialBooks == null ? l10n.setGoal : l10n.editGoal),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.goalBooksLabel,
              errorText: _invalid ? l10n.enterPositiveNumber : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('goal-pages-field'),
            controller: _pagesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.goalPagesLabel,
              errorText: _pagesInvalid ? l10n.enterPositiveNumber : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

/// Reading speed and total reading time across all sessions.
class _ReadingCard extends StatelessWidget {
  final BookStatistics stats;
  const _ReadingCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final speed = stats.reading.pagesPerHour;
    return Row(
      children: [
        Expanded(
          child: _Card(
            icon: Icons.speed,
            label: l10n.readingSpeed,
            value: speed == null
                ? '–'
                : l10n.pagesPerHourValue(speed.toStringAsFixed(1)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Card(
            icon: Icons.timer_outlined,
            label: l10n.totalReadingTime,
            value: formatDurationSeconds(l10n, stats.reading.totalSeconds),
          ),
        ),
      ],
    );
  }
}

/// Year dropdown: "All years" or one of the years with finished books.
class _YearSelector extends StatelessWidget {
  final BookStatistics stats;
  const _YearSelector({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.yearFilter,
        prefixIcon: const Icon(Icons.calendar_today),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          key: const ValueKey('stats-year'),
          value: stats.year,
          isExpanded: true,
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(l10n.allYears)),
            for (final y in stats.years)
              DropdownMenuItem<int?>(value: y, child: Text('$y')),
          ],
          onChanged: context.read<StatisticsCubit>().selectYear,
        ),
      ),
    );
  }
}

/// Twelve bars, January to December.
class _MonthlyBarChart extends StatelessWidget {
  final String id;
  final String title;
  final List<int> values;

  /// Opens the books of a month (1–12); without it the bars are not tappable.
  final ValueChanged<int>? onMonth;

  const _MonthlyBarChart({
    super.key,
    required this.id,
    required this.title,
    required this.values,
    this.onMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = values.fold<int>(0, (m, v) => v > m ? v : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _MonthTapTargets(
              id: id,
              onMonth: onMonth,
              child: Semantics(
                label: '$title: ${values.join(', ')}',
                child: SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      maxY: (max == 0 ? 1 : max * 1.15).toDouble(),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              meta: meta,
                              child: Text(
                                '${value.toInt() + 1}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < values.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i].toDouble(),
                                width: 12,
                                color: theme.colorScheme.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ],
                            showingTooltipIndicators: values[i] > 0 ? [0] : [],
                          ),
                      ],
                      barTouchData: BarTouchData(
                        enabled: false,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.transparent,
                          tooltipPadding: EdgeInsets.zero,
                          tooltipMargin: 2,
                          getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                            '${rod.toY.toInt()}',
                            theme.textTheme.labelSmall ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Averages (rating, pages, reading time) and the extreme books.
class _AveragesCard extends StatelessWidget {
  final BookStatistics stats;
  const _AveragesCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <(String, String)>[
      if (stats.averageRating != null)
        (l10n.averageRating, stats.averageRating!.toStringAsFixed(2)),
      if (stats.averagePages != null)
        (l10n.averagePages, l10n.pagesValue(stats.averagePages!)),
      if (stats.averageReadingTime != null)
        (
          l10n.averageReadingTime,
          formatDurationSeconds(l10n, stats.averageReadingTime!.inSeconds),
        ),
      if (stats.longestBook != null)
        (
          l10n.longestBook,
          '${stats.longestBook!.name} · ${l10n.pagesValue(stats.longestBook!.count)}',
        ),
      if (stats.shortestBook != null)
        (
          l10n.shortestBook,
          '${stats.shortestBook!.name} · ${l10n.pagesValue(stats.shortestBook!.count)}',
        ),
      if (stats.fastestBook != null)
        (
          l10n.fastestBook,
          '${stats.fastestBook!.name} · ${formatDurationSeconds(l10n, stats.fastestBook!.count)}',
        ),
      if (stats.slowestBook != null)
        (
          l10n.slowestBook,
          '${stats.slowestBook!.name} · ${formatDurationSeconds(l10n, stats.slowestBook!.count)}',
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      key: const ValueKey('averages-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.averagesTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: Text(label)),
                    Expanded(
                      flex: 6,
                      child: Text(value, textAlign: TextAlign.end),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
