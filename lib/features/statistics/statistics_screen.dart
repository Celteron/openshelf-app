import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/goal_progress.dart';
import 'package:openreads/features/common/format_duration.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/domain/models/statistics.dart';
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
              _SummaryCards(stats: stats),
              const SizedBox(height: 16),
              _GoalCard(goal: stats.goal),
              const SizedBox(height: 16),
              _ReadingCard(stats: stats),
              const SizedBox(height: 16),
              _StatusBreakdown(stats: stats),
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
            value: stats.totalBooks.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Card(
            icon: Icons.auto_stories,
            label: l10n.pagesRead,
            value: stats.pagesRead.toString(),
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
              _StatusRow(
                label: _statusName(context, status),
                count: stats.statusCounts[status] ?? 0,
                total: total,
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
                  trailing: Text(entry.count.toString()),
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
              if (goal.hasPageGoal) ...[
                const SizedBox(height: 16),
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
    text: widget.initialBooks?.toString() ?? '',
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
    final books = int.tryParse(_controller.text.trim());
    final pagesText = _pagesController.text.trim();
    final pages = pagesText.isEmpty ? null : int.tryParse(pagesText);
    final booksInvalid = books == null || books <= 0;
    final pagesInvalid = pagesText.isNotEmpty && (pages == null || pages <= 0);
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
