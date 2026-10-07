import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/notes_repository.dart';
import 'package:openreads/features/notes/notes_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Text placed on the clipboard by the quick-copy action: the raw text for a
/// note, and the quote followed by its page for a quote.
String noteClipboardText(AppLocalizations l10n, BookNote note) {
  final page = note.pageNumber;
  if (note.kind == NoteKind.quote) {
    final quoted = '„${note.content}“';
    return page == null ? quoted : '$quoted (${l10n.notePage(page)})';
  }
  return note.content;
}

/// Notes and quotes of one book with quick-copy (Phase 2, US-B).
class NotesScreen extends StatelessWidget {
  final int bookId;
  const NotesScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          NotesCubit(bookId, context.read<NotesRepository>())..load(),
      child: const NotesView(),
    );
  }
}

/// The screen body; exposed so it can be tested with a provided cubit.
class NotesView extends StatelessWidget {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabs = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.notesTitle),
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.notesTabNotes),
                  Tab(text: l10n.notesTabQuotes),
                ],
              ),
            ),
            body: BlocBuilder<NotesCubit, NotesState>(
              builder: (context, state) {
                return switch (state) {
                  NotesLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  NotesError() => Center(child: Text(l10n.errorLoadingLibrary)),
                  NotesLoaded() => TabBarView(
                    children: [
                      _NoteList(notes: state.ofKind(NoteKind.note)),
                      _NoteList(notes: state.ofKind(NoteKind.quote)),
                    ],
                  ),
                };
              },
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: l10n.addNote,
              onPressed: () => _edit(
                context,
                initialKind: tabs.index == 1 ? NoteKind.quote : NoteKind.note,
              ),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _edit(
  BuildContext context, {
  BookNote? note,
  NoteKind initialKind = NoteKind.note,
}) async {
  final cubit = context.read<NotesCubit>();
  final result = await showDialog<_NoteInput>(
    context: context,
    builder: (_) => _NoteDialog(note: note, initialKind: initialKind),
  );
  if (result == null) return;
  if (note == null) {
    await cubit.add(
      kind: result.kind,
      content: result.content,
      pageNumber: result.page,
    );
  } else {
    await cubit.update(
      note.id,
      kind: result.kind,
      content: result.content,
      pageNumber: result.page,
    );
  }
}

class _NoteList extends StatelessWidget {
  final List<BookNote> notes;
  const _NoteList({required this.notes});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (notes.isEmpty) return Center(child: Text(l10n.noNotesYet));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: notes.length,
      itemBuilder: (context, index) => _NoteCard(note: notes[index]),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final BookNote note;
  const _NoteCard({required this.note});

  Future<void> _copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: noteClipboardText(l10n, note)));
    messenger.showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isQuote = note.kind == NoteKind.quote;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isQuote ? '„${note.content}“' : note.content,
              style: isQuote
                  ? theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    )
                  : theme.textTheme.bodyLarge,
            ),
            Row(
              children: [
                if (note.pageNumber != null)
                  Chip(
                    label: Text(l10n.notePage(note.pageNumber!)),
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: l10n.copy,
                  onPressed: () => _copy(context),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.editNote,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _edit(context, note: note);
                    } else {
                      context.read<NotesCubit>().delete(note.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.editNote)),
                    PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteInput {
  final NoteKind kind;
  final String content;
  final int? page;
  const _NoteInput(this.kind, this.content, this.page);
}

class _NoteDialog extends StatefulWidget {
  final BookNote? note;
  final NoteKind initialKind;
  const _NoteDialog({required this.note, required this.initialKind});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late NoteKind _kind = widget.note?.kind ?? widget.initialKind;
  late final TextEditingController _content = TextEditingController(
    text: widget.note?.content ?? '',
  );
  late final TextEditingController _page = TextEditingController(
    text: widget.note?.pageNumber?.toString() ?? '',
  );

  @override
  void dispose() {
    _content.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.note == null ? l10n.addNote : l10n.editNote),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<NoteKind>(
              segments: [
                ButtonSegment(
                  value: NoteKind.note,
                  label: Text(l10n.noteKindNote),
                ),
                ButtonSegment(
                  value: NoteKind.quote,
                  label: Text(l10n.noteKindQuote),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.single),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.noteContentLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _page,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.notePageLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _NoteInput(_kind, _content.text, int.tryParse(_page.text.trim())),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
