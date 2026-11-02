import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/home_summary.dart';
import 'package:openreads/domain/models/stat_tile.dart';
import 'package:openreads/features/common/format_count.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/features/home/home_cubit.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/statistics/custom_stats_cubit.dart';
import 'package:openreads/features/statistics/custom_stats_section.dart';
import 'package:openreads/features/statistics/stat_tile_view.dart';
import 'package:openreads/features/statistics/statistics_cubit.dart';
import 'package:openreads/features/statistics/statistics_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// The first tab (FR-R2-19): the library at a glance.
class HomeScreen extends StatefulWidget {
  /// Switches to the library tab, e.g. after a donut segment set a filter.
  final VoidCallback? onShowLibrary;

  const HomeScreen({super.key, this.onShowLibrary});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().load();
  }

  void _showStatus(BookStatus status, HomeSummary summary) {
    final library = context.read<LibraryCubit>();
    final reading = summary.currentlyReading;
    // The segment counts re-reads as well, which the reading chip leaves
    // out: show exactly the counted books then.
    if (status == BookStatus.reading &&
        reading.any((b) => b.status == BookStatus.reReading)) {
      library.showOnly({for (final b in reading) b.id});
    } else {
      library.showStatus(status);
    }
    widget.onShowLibrary?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHome)),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => switch (state) {
          HomeLoading() => const Center(child: CircularProgressIndicator()),
          HomeError() => Center(child: Text(l10n.errorLoadingLibrary)),
          HomeLoaded(:final summary)
              when summary.total == 0 && summary.recent.isEmpty =>
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.homeEmpty, textAlign: TextAlign.center),
              ),
            ),
          HomeLoaded(:final summary) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Donut(
                summary: summary,
                onStatus: (status) => _showStatus(status, summary),
              ),
              _PinnedStats(onShowLibrary: widget.onShowLibrary),
              const _HomeGoal(),
              if (summary.currentlyReading.isNotEmpty)
                _Section(
                  key: const ValueKey('home-reading'),
                  title: l10n.homeCurrentlyReading,
                  child: Column(
                    children: [
                      for (final book in summary.currentlyReading)
                        _ReadingTile(book: book),
                    ],
                  ),
                ),
              if (summary.recent.isNotEmpty)
                _Section(
                  key: const ValueKey('home-recent'),
                  title: l10n.homeRecentlyAdded,
                  child: _CoverRow(books: summary.recent),
                ),
              _Section(
                key: const ValueKey('home-unread-trend'),
                title: l10n.homeUnreadTrend,
                child: _Trend(values: summary.unreadTrend),
              ),
              if (summary.favourites.isNotEmpty)
                _Section(
                  key: const ValueKey('home-favourites'),
                  title: l10n.favoritesFilter,
                  child: _CoverRow(books: summary.favourites),
                ),
            ],
          ),
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Read / reading / unread with the total in the centre; a segment or its
/// legend row opens the filtered library.
class _Donut extends StatelessWidget {
  final HomeSummary summary;
  final ValueChanged<BookStatus> onStatus;
  const _Donut({required this.summary, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final segments = [
      (BookStatus.read, summary.read, scheme.primary),
      (BookStatus.reading, summary.reading, scheme.tertiary),
      (BookStatus.unread, summary.unread, scheme.outlineVariant),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    PieChartData(
                      centerSpaceRadius: 56,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          final index =
                              response?.touchedSection?.touchedSectionIndex;
                          if (event is FlTapUpEvent &&
                              index != null &&
                              index >= 0 &&
                              index < segments.length) {
                            onStatus(segments[index].$1);
                          }
                        },
                      ),
                      sections: [
                        for (final (_, count, color) in segments)
                          PieChartSectionData(
                            value: count.toDouble(),
                            color: color,
                            radius: 28,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatCount(context, summary.total),
                    key: const ValueKey('home-total'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final (status, count, color) in segments)
              InkWell(
                key: ValueKey('home-segment-${status.name}'),
                onTap: () => onStatus(status),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(statusLabel(l10n, status))),
                      Text(formatCount(context, count)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The user-defined statistics pinned to the home tab (spec 005, T5-07).
class _PinnedStats extends StatelessWidget {
  final VoidCallback? onShowLibrary;
  const _PinnedStats({required this.onShowLibrary});

  @override
  Widget build(BuildContext context) {
    final CustomStatsCubit cubit;
    try {
      cubit = context.read<CustomStatsCubit>();
    } catch (_) {
      return const SizedBox.shrink(); // isolated widget tests
    }
    return BlocBuilder<CustomStatsCubit, CustomStatsState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        CustomStatsLoaded(:final tiles, :final library) => Column(
          children: [
            for (final t
                in tiles.where((t) => t.tile.pinned).take(StatTile.maxPinned))
              Padding(
                key: ValueKey('home-tile-${t.tile.id}'),
                padding: const EdgeInsets.only(top: 16),
                child: StatTileView(
                  id: 'home-tile-${t.tile.id}',
                  title: t.tile.title,
                  definition: t.tile.definition,
                  result: t.result,
                  library: library,
                  onBooks: (label, ids) => showStatBooks(
                    context,
                    library,
                    label,
                    ids,
                    onShowLibrary: onShowLibrary,
                  ),
                ),
              ),
          ],
        ),
        CustomStatsLoading() || CustomStatsError() => const SizedBox.shrink(),
      },
    );
  }
}

/// The yearly goal from the statistics, when the app provides them.
class _HomeGoal extends StatelessWidget {
  const _HomeGoal();

  @override
  Widget build(BuildContext context) {
    final StatisticsCubit cubit;
    try {
      cubit = context.read<StatisticsCubit>();
    } catch (_) {
      return const SizedBox.shrink(); // isolated widget tests
    }
    return BlocBuilder<StatisticsCubit, StatisticsState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        StatisticsLoaded(:final statistics) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: GoalCard(goal: statistics.goal),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final Book book;
  const _ReadingTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final pages = book.pageCount ?? 0;
    final progress = pages <= 0
        ? null
        : (book.currentPage / pages).clamp(0.0, 1.0);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 40,
        height: 56,
        child: BookCover(book: book, borderRadius: BorderRadius.circular(4)),
      ),
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: progress == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(value: progress, minHeight: 6),
            ),
      onTap: () => _openBook(context, book),
    );
  }
}

class _CoverRow extends StatelessWidget {
  final List<Book> books;
  const _CoverRow({required this.books});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final book = books[i];
          return InkWell(
            onTap: () => _openBook(context, book),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    height: 130,
                    child: BookCover(
                      book: book,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A small bar chart of the unread stack, oldest month first.
class _Trend extends StatelessWidget {
  final List<int> values;
  const _Trend({required this.values});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final max = values.fold<int>(0, (m, v) => v > m ? v : m);
    return Semantics(
      label: values.join(', '),
      child: SizedBox(
        height: 64,
        child: BarChart(
          BarChartData(
            maxY: (max == 0 ? 1 : max).toDouble(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            barTouchData: BarTouchData(enabled: false),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i].toDouble(),
                      width: 18,
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openBook(BuildContext context, Book book) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id)));
