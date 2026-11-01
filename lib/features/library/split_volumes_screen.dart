import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Turns a book into a slipcase by entering its volumes (ADR-0003). Pops with
/// `true` once the volumes exist.
class SplitVolumesScreen extends StatefulWidget {
  final Book book;
  const SplitVolumesScreen({super.key, required this.book});

  @override
  State<SplitVolumesScreen> createState() => _SplitVolumesScreenState();
}

class _SplitVolumesScreenState extends State<SplitVolumesScreen> {
  final _rows =
      <({TextEditingController title, TextEditingController pages})>[];
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _addRow();
    _addRow();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.title.dispose();
      row.pages.dispose();
    }
    super.dispose();
  }

  void _addRow() => _rows.add((
    title: TextEditingController()..addListener(_refresh),
    pages: TextEditingController(),
  ));

  void _removeRow(int index) {
    final row = _rows.removeAt(index);
    row.title.dispose();
    row.pages.dispose();
    setState(() {});
  }

  void _refresh() => setState(() {});

  List<VolumeDraft> get _drafts => [
    for (final row in _rows)
      if (row.title.text.trim().isNotEmpty)
        VolumeDraft(
          title: row.title.text.trim(),
          pageCount: int.tryParse(row.pages.text.trim()),
        ),
  ];

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).splitVolumesFailed;
    try {
      await context.read<LibraryCubit>().splitIntoVolumes(
        widget.book.id,
        _drafts,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSave = !_saving && _drafts.length >= 2;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.splitVolumesAction)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.book.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(l10n.splitVolumesHint),
          const SizedBox(height: 16),
          for (final (i, row) in _rows.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      key: ValueKey('volume-title-$i'),
                      controller: row.title,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.volumeTitleLabel(i + 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: ValueKey('volume-pages-$i'),
                      controller: row.pages,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.volumePagesLabel,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _rows.length > 2 ? () => _removeRow(i) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: l10n.removeVolume,
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('add-volume'),
              onPressed: () => setState(_addRow),
              icon: const Icon(Icons.add),
              label: Text(l10n.addVolume),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('split-save'),
            onPressed: canSave ? _save : null,
            child: Text(l10n.splitVolumesSave),
          ),
        ],
      ),
    );
  }
}
