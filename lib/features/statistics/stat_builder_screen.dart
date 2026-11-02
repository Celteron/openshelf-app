import 'package:flutter/material.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';
import 'package:openreads/domain/services/stat_query.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/features/statistics/stat_labels.dart';
import 'package:openreads/features/statistics/stat_tile_view.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Builds or edits a user-defined statistic (spec 005, T5-05) in four steps
/// with a live preview over [library]. Pops with the title and definition;
/// the caller stores them.
class StatBuilderScreen extends StatefulWidget {
  final StatLibrary library;

  /// The tile to edit; `null` builds a new one, starting from a preset.
  final StatTile? tile;
  final DateTime Function()? now;

  const StatBuilderScreen({
    super.key,
    required this.library,
    this.tile,
    this.now,
  });

  @override
  State<StatBuilderScreen> createState() => _StatBuilderScreenState();
}

class _StatBuilderScreenState extends State<StatBuilderScreen> {
  late StatDefinition _definition;
  late final TextEditingController _title;

  /// The preview of [_definition]; typing the title rebuilds the screen on
  /// every keystroke, and a large library should not be re-evaluated then.
  late StatResult _result;

  @override
  void initState() {
    super.initState();
    final tile = widget.tile;
    _definition = tile != null
        ? widget.library.withKnownTags(tile.definition)
        : const StatDefinition(
            measure: StatMeasure.books,
            period: StatAllTime(),
            chart: StatChart.number,
          );
    _result = widget.library.evaluate(_definition);
    _title = TextEditingController(text: widget.tile?.title ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// Applies [change] to the current definition, not to the one of the last
  /// build, so quick taps never undo each other.
  void _edit(StatDefinition Function(StatDefinition current) change) {
    final next = change(_definition);
    setState(() {
      if (next != _definition) _result = widget.library.evaluate(next);
      _definition = next;
    });
  }

  void _save() {
    final typed = _title.text.trim();
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop((
      typed.isEmpty ? statAutoTitle(l10n, _definition) : typed,
      _definition,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = (widget.now ?? DateTime.now)();
    final year = now.year;
    final library = widget.library;

    Widget step(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
    Widget choice<T>(
      String key,
      String label,
      T value,
      T selected,
      ValueChanged<T> onSelected,
    ) => ChoiceChip(
      key: ValueKey(key),
      label: Text(label),
      selected: value == selected,
      onSelected: (_) => onSelected(value),
    );
    Widget filter<T>(
      String key,
      String label,
      T value,
      Set<T> Function(StatDefinition) read,
      StatDefinition Function(StatDefinition, Set<T>) write,
    ) => FilterChip(
      key: ValueKey(key),
      label: Text(label),
      selected: read(_definition).contains(value),
      onSelected: (on) => _edit((d) {
        final current = read(d);
        return write(
          d,
          on ? {...current, value} : {...current.where((v) => v != value)},
        );
      }),
    );
    Widget chips(List<Widget> children) =>
        Wrap(spacing: 8, runSpacing: 4, children: children);

    final d = _definition;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tile == null ? l10n.statNew : l10n.statEdit),
        actions: [
          TextButton(
            key: const ValueKey('builder-save'),
            onPressed: _save,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (widget.tile == null) ...[
            step(l10n.statPresets),
            chips([
              for (final preset in StatPreset.values)
                ActionChip(
                  key: ValueKey('preset-${preset.name}'),
                  label: Text(statPresetTitle(l10n, preset, year)),
                  onPressed: () {
                    _title.text = statPresetTitle(l10n, preset, year);
                    _edit((_) => preset.definition(year));
                  },
                ),
            ]),
          ],
          step(l10n.statStepMeasure),
          chips([
            for (final m in StatMeasure.values)
              choice(
                'measure-${m.code}',
                statMeasureLabel(l10n, m),
                m,
                d.measure,
                (m) => _edit((d) => d.copyWith(measure: m)),
              ),
          ]),
          step(l10n.statStepGrouping),
          chips([
            choice<StatGrouping?>(
              'grouping-none',
              l10n.statNoGrouping,
              null,
              d.grouping,
              (g) => _edit((d) => d.withGrouping(g)),
            ),
            for (final g in StatGrouping.values)
              choice<StatGrouping?>(
                'grouping-${g.code}',
                statGroupingLabel(l10n, g),
                g,
                d.grouping,
                (g) => _edit((d) => d.withGrouping(g)),
              ),
          ]),
          step(l10n.statStepPeriod),
          chips([
            choice<StatPeriod>(
              'period-all',
              l10n.statAllTime,
              const StatAllTime(),
              d.period,
              (p) => _edit((d) => d.copyWith(period: p)),
            ),
            for (final y in library.years(now: now))
              choice<StatPeriod>(
                'period-$y',
                '$y',
                StatYear(y),
                d.period,
                (p) => _edit((d) => d.copyWith(period: p)),
              ),
          ]),
          const SizedBox(height: 8),
          Text(l10n.statFilterStatus, style: theme.textTheme.bodySmall),
          chips([
            for (final s in BookStatus.values)
              filter(
                'filter-status-${s.name}',
                statusLabel(l10n, s),
                s,
                (d) => d.statuses,
                (d, next) => d.copyWith(statuses: next),
              ),
          ]),
          const SizedBox(height: 8),
          Text(l10n.statFilterFormat, style: theme.textTheme.bodySmall),
          chips([
            for (final f in BookFormat.values)
              filter(
                'filter-format-${f.name}',
                formatLabel(l10n, f),
                f,
                (d) => d.formats,
                (d, next) => d.copyWith(formats: next),
              ),
          ]),
          if (library.tagNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.statFilterTags, style: theme.textTheme.bodySmall),
            chips([
              for (final MapEntry(key: id, value: name)
                  in library.tagNames.entries)
                filter(
                  'filter-tag-$id',
                  name,
                  id,
                  (d) => d.tagIds,
                  (d, next) => d.copyWith(tagIds: next),
                ),
            ]),
          ],
          step(l10n.statStepChart),
          chips([
            for (final c in StatDefinition.chartsFor(d.grouping, d.measure))
              choice(
                'chart-${c.code}',
                statChartLabel(l10n, c),
                c,
                d.chart,
                (c) => _edit((d) => d.copyWith(chart: c)),
              ),
          ]),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('builder-title'),
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            // The preview shows the title as it is typed.
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.statTitle,
              hintText: statAutoTitle(l10n, d),
              border: const OutlineInputBorder(),
            ),
          ),
          step(l10n.statPreview),
          StatTileView(
            id: 'preview',
            title: _title.text.trim().isEmpty
                ? statAutoTitle(l10n, d)
                : _title.text.trim(),
            definition: d,
            result: _result,
            library: library,
          ),
        ],
      ),
    );
  }
}
