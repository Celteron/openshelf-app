import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:openreads/core/helpers/maybe_read.dart';
import 'package:openreads/domain/models/reading_calendar.dart';
import 'package:openreads/features/common/format_duration.dart';
import 'package:openreads/features/statistics/reading_calendar_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// The reading calendar for the home tab and the statistics, fed by the
/// [ReadingCalendarCubit]; nothing is shown without it (isolated widget tests).
class ReadingHeatmapCard extends StatelessWidget {
  const ReadingHeatmapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.maybeRead<ReadingCalendarCubit>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<ReadingCalendarCubit, ReadingCalendarState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        ReadingCalendarLoaded(:final calendar) => ReadingHeatmap(
          calendar: calendar,
          today: DateTime.now(),
        ),
        ReadingCalendarLoading() ||
        ReadingCalendarError() => const SizedBox.shrink(),
      },
    );
  }
}

/// A year of reading as a grid of days, one column per week (Monday first).
///
/// Two layers (see [ReadingCalendar]): a faint cell means a book was in
/// progress, stronger cells mean time actually read. The grid is a picture;
/// screen readers get the summary and the line of the tapped day instead of
/// 365 cells.
class ReadingHeatmap extends StatefulWidget {
  final ReadingCalendar calendar;
  final DateTime today;

  const ReadingHeatmap({
    super.key,
    required this.calendar,
    required this.today,
  });

  @override
  State<ReadingHeatmap> createState() => _ReadingHeatmapState();
}

class _ReadingHeatmapState extends State<ReadingHeatmap> {
  static const _cell = 14.0;
  static const _gap = 2.0;
  static const _pitch = _cell + _gap;

  int? _year;
  DateTime? _selected;

  List<int> get _years => widget.calendar.years;

  int get _shownYear {
    final chosen = _year;
    if (chosen != null) return chosen;
    return _years.contains(widget.today.year)
        ? widget.today.year
        : (_years.isEmpty ? widget.today.year : _years.first);
  }

  void _moveYear(int delta) {
    final years = _years.reversed.toList(); // oldest first
    final i = years.indexOf(_shownYear) + delta;
    if (i >= 0 && i < years.length) {
      setState(() {
        _year = years[i];
        _selected = null;
      });
    }
  }

  Color _color(ColorScheme scheme, int level) => switch (level) {
    0 => scheme.surfaceContainerHighest,
    1 => scheme.primary.withValues(alpha: 0.22),
    2 => scheme.primary.withValues(alpha: 0.42),
    3 => scheme.primary.withValues(alpha: 0.62),
    4 => scheme.primary.withValues(alpha: 0.82),
    _ => scheme.primary,
  };

  String _dayLine(AppLocalizations l10n, String locale, DateTime day) {
    final date = DateFormat.yMMMMEEEEd(locale).format(day);
    final cell = widget.calendar.dayOf(day);
    if (cell.seconds > 0) {
      return l10n.heatmapDayDetail(
        date,
        formatDurationSeconds(l10n, cell.seconds),
        cell.booksInProgress,
      );
    }
    return cell.booksInProgress > 0
        ? l10n.heatmapDayProgress(date, cell.booksInProgress)
        : l10n.heatmapDayNothing(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final year = _shownYear;
    final years = _years.reversed.toList();
    final index = years.indexOf(year);
    final summary = l10n.heatmapSummary(
      widget.calendar.daysWithTime(year),
      widget.calendar.daysInProgress(year),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.heatmapTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('heatmap-prev'),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: l10n.heatmapPrevYear,
                  onPressed: index > 0 ? () => _moveYear(-1) : null,
                ),
                Text('$year'),
                IconButton(
                  key: const ValueKey('heatmap-next'),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: l10n.heatmapNextYear,
                  onPressed: index >= 0 && index < years.length - 1
                      ? () => _moveYear(1)
                      : null,
                ),
              ],
            ),
            if (years.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.heatmapEmpty),
              )
            else ...[
              Text(summary, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              ExcludeSemantics(child: _grid(context, year, locale)),
              const SizedBox(height: 8),
              _legend(context, l10n),
              if (_selected case final day?)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(_dayLine(l10n, locale, day)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, int year, String locale) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(year);
    // The current year stops at today, so the view can open on the right end.
    final isCurrent = year == widget.today.year;
    final last = isCurrent
        ? DateTime(year, widget.today.month, widget.today.day)
        : DateTime(year, 12, 31);
    final offset = first.weekday - DateTime.monday; // empty cells before Jan 1
    // Calendar-day count without DST pitfalls.
    final count =
        DateTime.utc(
          last.year,
          last.month,
          last.day,
        ).difference(DateTime.utc(year)).inDays +
        1;
    final weeks = ((offset + count) / 7).ceil();

    DateTime? dateAt(int week, int row) {
      final n = week * 7 + row - offset;
      if (n < 0 || n >= count) return null;
      return DateTime(year, 1, 1 + n);
    }

    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: isCurrent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 16,
            width: weeks * _pitch,
            child: Stack(
              children: [
                for (var w = 0; w < weeks; w++)
                  for (var r = 0; r < 7; r++)
                    if (dateAt(w, r) case final d? when d.day == 1)
                      Positioned(
                        left: w * _pitch,
                        child: Text(
                          DateFormat.MMM(locale).format(d),
                          style: labelStyle,
                        ),
                      ),
              ],
            ),
          ),
          Row(
            children: [
              for (var w = 0; w < weeks; w++)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: Column(
                    children: [
                      for (var r = 0; r < 7; r++)
                        _cellFor(scheme, dateAt(w, r)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cellFor(ColorScheme scheme, DateTime? date) {
    if (date == null) {
      return const SizedBox(width: _cell, height: _cell + _gap);
    }
    final level = widget.calendar.dayOf(date).level;
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final selected = _selected == date;
    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      child: Container(
        key: ValueKey('heat-$key-$level'),
        width: _cell,
        height: _cell,
        margin: const EdgeInsets.only(bottom: _gap),
        decoration: BoxDecoration(
          color: _color(scheme, level),
          borderRadius: BorderRadius.circular(3),
          border: selected
              ? Border.all(color: scheme.onSurface, width: 1.5)
              : null,
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;
    return ExcludeSemantics(
      child: Row(
        children: [
          Text(l10n.heatmapLess, style: style),
          const SizedBox(width: 6),
          for (var level = 0; level <= 5; level++)
            Container(
              width: _cell,
              height: _cell,
              margin: const EdgeInsets.only(right: _gap),
              decoration: BoxDecoration(
                color: _color(scheme, level),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          const SizedBox(width: 4),
          Text(l10n.heatmapMore, style: style),
        ],
      ),
    );
  }
}
