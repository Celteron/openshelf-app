import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/enums.dart';
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
                label: status.name,
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
