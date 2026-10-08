import 'package:flutter/material.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// A reading entered by hand.
///
/// [date]..[endDate] is the reading *period* (when the book was read, possibly
/// over several days); [duration] is the time actually spent reading and may be
/// zero when it is unknown.
class ManualSession {
  final DateTime date;
  final Duration duration;
  final int startPage;
  final int endPage;

  /// Set for a reading that spans several days (legacy start/finish dates).
  final DateTime? endDate;

  const ManualSession({
    required this.date,
    required this.duration,
    required this.startPage,
    required this.endPage,
    this.endDate,
  });
}

enum _DurationUnit { minutes, hours }

/// Dialog for logging a finished reading after the fact. Only the start date
/// is required: the time read, the end date and the pages are optional.
class LogSessionDialog extends StatefulWidget {
  final int startPage;
  const LogSessionDialog({super.key, required this.startPage});

  @override
  State<LogSessionDialog> createState() => _LogSessionDialogState();
}

class _LogSessionDialogState extends State<LogSessionDialog> {
  late final TextEditingController _duration = TextEditingController();
  late final TextEditingController _start = TextEditingController(
    text: widget.startPage.toString(),
  );
  late final TextEditingController _end = TextEditingController();
  _DurationUnit _unit = _DurationUnit.minutes;
  DateTime _date = DateTime.now();
  DateTime? _endDate;
  bool _durationInvalid = false;
  bool _pageInvalid = false;

  @override
  void dispose() {
    _duration.dispose();
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

  /// The entered time, `Duration.zero` when left empty, `null` when invalid.
  Duration? _parseDuration() {
    final text = _duration.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return Duration.zero;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite || value <= 0) return null;
    final minutes = _unit == _DurationUnit.hours ? value * 60 : value;
    return Duration(minutes: minutes.round());
  }

  void _submit() {
    final duration = _parseDuration();
    final start = int.tryParse(_start.text.trim());
    final endText = _end.text.trim();
    final end = endText.isEmpty ? start : int.tryParse(endText);
    setState(() {
      _durationInvalid = duration == null;
      _pageInvalid = start == null || end == null;
    });
    if (duration == null || start == null || end == null) return;

    final now = DateTime.now();
    final endDate = _endDate;
    Navigator.pop(
      context,
      ManualSession(
        date: DateTime(
          _date.year,
          _date.month,
          _date.day,
          now.hour,
          now.minute,
        ),
        duration: duration,
        startPage: start,
        endPage: end,
        endDate: endDate == null || DateUtils.isSameDay(endDate, _date)
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
    final dates = MaterialLocalizations.of(context);
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
              subtitle: Text(dates.formatMediumDate(_date)),
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
                    : dates.formatMediumDate(_endDate!),
              ),
              trailing: _endDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.clearDate,
                      onPressed: () => setState(() => _endDate = null),
                    ),
              onTap: _pickEndDate,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('session-duration'),
                    controller: _duration,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.sessionTimeRead,
                      helperText: l10n.sessionTimeReadHint,
                      helperMaxLines: 2,
                      errorText: _durationInvalid
                          ? l10n.enterPositiveNumber
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<_DurationUnit>(
                  key: const ValueKey('session-unit'),
                  value: _unit,
                  items: [
                    DropdownMenuItem(
                      value: _DurationUnit.minutes,
                      child: Text(l10n.unitMinutes),
                    ),
                    DropdownMenuItem(
                      value: _DurationUnit.hours,
                      child: Text(l10n.unitHours),
                    ),
                  ],
                  onChanged: (u) {
                    if (u != null) setState(() => _unit = u);
                  },
                ),
              ],
            ),
            TextField(
              controller: _start,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.sessionStartPage,
                errorText: _pageInvalid ? l10n.enterPositiveNumber : null,
              ),
            ),
            TextField(
              key: const ValueKey('session-end-page'),
              controller: _end,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.sessionEndPageOptional,
              ),
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
