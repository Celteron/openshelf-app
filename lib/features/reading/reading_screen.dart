import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/reading_stats.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/domain/services/reading_tracker_service.dart';
import 'package:openreads/features/common/format_duration.dart';
import 'package:openreads/features/reading/reading_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Live reading timer, current-page tracker, reading speed and the session
/// history of one book (Phase 2, US-A).
class ReadingScreen extends StatelessWidget {
  final int bookId;
  const ReadingScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReadingCubit(
        bookId: bookId,
        tracker: context.read<ReadingTrackerService>(),
        readingRepository: context.read<ReadingRepository>(),
        bookRepository: context.read<BookRepository>(),
      )..load(),
      child: const _ReadingView(),
    );
  }
}

class _ReadingView extends StatefulWidget {
  const _ReadingView();

  @override
  State<_ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends State<_ReadingView> {
  final _pageController = TextEditingController();
  int? _syncedPage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Mirrors the persisted page into the text field whenever it changes.
  void _syncPage(int page) {
    if (_syncedPage == page) return;
    _syncedPage = page;
    _pageController.text = page.toString();
  }

  int? get _enteredPage => int.tryParse(_pageController.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.readingTitle)),
      body: BlocConsumer<ReadingCubit, ReadingState>(
        listener: (context, state) {
          if (state is ReadingLoaded) _syncPage(state.book.currentPage);
        },
        builder: (context, state) {
          return switch (state) {
            ReadingLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ReadingError() => Center(child: Text(l10n.errorLoadingLibrary)),
            ReadingLoaded() => _buildLoaded(context, state, l10n),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    ReadingLoaded state,
    AppLocalizations l10n,
  ) {
    _syncPage(state.book.currentPage);
    final cubit = context.read<ReadingCubit>();
    final active = state.active;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(state.book.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _ProgressCard(
          book: state.book,
          controller: _pageController,
          onSave: () {
            final page = _enteredPage;
            if (page != null) cubit.setPage(page);
          },
          onSlide: cubit.setPage,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (active != null)
                  _ElapsedClock(startedAt: active.startedAt)
                else
                  const _IdleClock(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: active == null
                      ? FilledButton.icon(
                          onPressed: cubit.start,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.readingStart),
                        )
                      : FilledButton.tonalIcon(
                          onPressed: () => cubit.stop(endPage: _enteredPage),
                          icon: const Icon(Icons.stop),
                          label: Text(l10n.readingStop),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _StatsCard(stats: state.stats),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.readingSessionsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => _logSession(context, state.book),
              icon: const Icon(Icons.add),
              label: Text(l10n.logSession),
            ),
          ],
        ),
        if (state.sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.noSessionsYet),
          )
        else
          for (final session in state.sessions)
            _SessionTile(
              session: session,
              onDelete: () => cubit.deleteSession(session.id),
            ),
      ],
    );
  }

  Future<void> _logSession(BuildContext context, Book book) async {
    final cubit = context.read<ReadingCubit>();
    final result = await showDialog<_ManualSession>(
      context: context,
      builder: (_) => _LogSessionDialog(startPage: book.currentPage),
    );
    if (result == null) return;
    await cubit.logSession(
      startedAt: result.date,
      duration: Duration(minutes: result.minutes),
      startPage: result.startPage,
      endPage: result.endPage,
      endedAt: result.endDate,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Book book;
  final TextEditingController controller;
  final VoidCallback onSave;
  final ValueChanged<int> onSlide;

  const _ProgressCard({
    required this.book,
    required this.controller,
    required this.onSave,
    required this.onSlide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = book.pageCount;
    final hasTotal = total != null && total > 0;
    final page = hasTotal
        ? book.currentPage.clamp(0, total).toInt()
        : book.currentPage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasTotal
                  ? l10n.pageOfTotal(page, total)
                  : l10n.pageOnly(book.currentPage),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hasTotal) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: page / total, minHeight: 8),
              Semantics(
                label: l10n.currentPageLabel,
                child: Slider(
                  value: page.toDouble(),
                  max: total.toDouble(),
                  divisions: total > 1 ? total : null,
                  onChangeEnd: (v) => onSlide(v.round()),
                  onChanged: (_) {},
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.currentPageLabel,
                    ),
                    onSubmitted: (_) => onSave(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(l10n.savePage),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleClock extends StatelessWidget {
  const _IdleClock();

  @override
  Widget build(BuildContext context) {
    return Text(
      formatClock(Duration.zero),
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Ticks once per second; the elapsed time is derived from the persisted
/// start time, so it stays correct across app restarts.
class _ElapsedClock extends StatefulWidget {
  final DateTime startedAt;
  const _ElapsedClock({required this.startedAt});

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    return Text(
      formatClock(elapsed),
      key: const ValueKey('reading-clock'),
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final ReadingStats stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final speed = stats.pagesPerHour;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(
              label: l10n.readingSpeed,
              value: speed == null
                  ? l10n.notEnoughData
                  : l10n.pagesPerHourValue(speed.toStringAsFixed(1)),
            ),
            _StatRow(
              label: l10n.totalReadingTime,
              value: formatDurationSeconds(l10n, stats.totalSeconds),
            ),
            _StatRow(
              label: l10n.readingSessionsTitle,
              value: l10n.readingSessionsCount(stats.sessionCount),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ReadingSession session;
  final VoidCallback onDelete;
  const _SessionTile({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running = session.endedAt == null;
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(session.startedAt);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(running ? Icons.timer : Icons.menu_book),
      title: Text(date),
      subtitle: running
          ? Text(l10n.readingStop)
          : Text(
              l10n.sessionPagesLine(
                sessionPages(session),
                formatDurationSeconds(l10n, session.durationSeconds),
              ),
            ),
      trailing: running
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteSession,
              onPressed: onDelete,
            ),
    );
  }
}

class _ManualSession {
  final DateTime date;
  final int minutes;
  final int startPage;
  final int endPage;

  /// Set for a reading that spans several days (legacy start/finish dates).
  final DateTime? endDate;

  const _ManualSession(
    this.date,
    this.minutes,
    this.startPage,
    this.endPage, [
    this.endDate,
  ]);
}

class _LogSessionDialog extends StatefulWidget {
  final int startPage;
  const _LogSessionDialog({required this.startPage});

  @override
  State<_LogSessionDialog> createState() => _LogSessionDialogState();
}

class _LogSessionDialogState extends State<_LogSessionDialog> {
  late final TextEditingController _minutes = TextEditingController();
  late final TextEditingController _start = TextEditingController(
    text: widget.startPage.toString(),
  );
  late final TextEditingController _end = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _endDate;
  bool _invalid = false;

  @override
  void dispose() {
    _minutes.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      final end = _endDate;
      if (end != null && end.isBefore(picked)) _endDate = picked;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _date,
      firstDate: _date,
      lastDate: DateTime.now().isBefore(_date) ? _date : DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _submit() {
    final minutes = int.tryParse(_minutes.text.trim());
    final start = int.tryParse(_start.text.trim());
    final end = int.tryParse(_end.text.trim());
    if (minutes == null || minutes <= 0 || start == null || end == null) {
      setState(() => _invalid = true);
      return;
    }
    final now = DateTime.now();
    final endDate = _endDate;
    Navigator.pop(
      context,
      _ManualSession(
        DateTime(_date.year, _date.month, _date.day, now.hour, now.minute),
        minutes,
        start,
        end,
        endDate == null || DateUtils.isSameDay(endDate, _date)
            ? null
            : DateTime(
                endDate.year,
                endDate.month,
                endDate.day,
                now.hour,
                now.minute,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.logSession),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(l10n.sessionDate),
              subtitle: Text(
                MaterialLocalizations.of(context).formatMediumDate(_date),
              ),
              onTap: _pickDate,
            ),
            ListTile(
              key: const ValueKey('session-end-date'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available),
              title: Text(l10n.sessionEndDate),
              subtitle: Text(
                _endDate == null
                    ? l10n.sessionEndDateHint
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(_endDate!),
              ),
              trailing: _endDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
              onTap: _pickEndDate,
            ),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.sessionDurationMinutes,
                errorText: _invalid ? l10n.enterPositiveNumber : null,
              ),
            ),
            TextField(
              controller: _start,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.sessionStartPage),
            ),
            TextField(
              controller: _end,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.sessionEndPage),
            ),
          ],
        ),
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
