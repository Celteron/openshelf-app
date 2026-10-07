import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/features/library/widgets/book_list_tile.dart';
import 'package:openreads/features/trash/trash_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Deleted books: restore them or remove them permanently.
class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TrashCubit>().load();
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('trash-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _deleteForever(Book book) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TrashCubit>();
    if (!await _confirm(
      l10n.deleteForeverTitle(book.title),
      l10n.deleteForeverBody,
      l10n.deleteForever,
    )) {
      return;
    }
    await cubit.deleteForever(book);
  }

  Future<void> _emptyTrash() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TrashCubit>();
    if (!await _confirm(
      l10n.emptyTrashTitle,
      l10n.deleteForeverBody,
      l10n.emptyTrash,
    )) {
      return;
    }
    await cubit.emptyTrash();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trashTitle),
        actions: [
          BlocBuilder<TrashCubit, TrashState>(
            builder: (context, state) {
              final hasBooks = state is TrashLoaded && state.books.isNotEmpty;
              return IconButton(
                key: const ValueKey('empty-trash'),
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: l10n.emptyTrash,
                onPressed: hasBooks ? _emptyTrash : null,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TrashCubit, TrashState>(
        builder: (context, state) {
          if (state is TrashLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! TrashLoaded) {
            return Center(child: Text(l10n.errorLoadingLibrary));
          }
          if (state.books.isEmpty) {
            return Center(
              key: const ValueKey('trash-empty'),
              child: Text(l10n.trashEmpty),
            );
          }
          return ListView(
            children: [
              for (final book in state.books)
                BookListTile(
                  book: book,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: ValueKey('restore:${book.id}'),
                        icon: const Icon(Icons.restore_from_trash),
                        tooltip: l10n.restore,
                        onPressed: () =>
                            context.read<TrashCubit>().restore(book.id),
                      ),
                      IconButton(
                        key: ValueKey('purge:${book.id}'),
                        icon: const Icon(Icons.delete_forever_outlined),
                        tooltip: l10n.deleteForever,
                        onPressed: () => _deleteForever(book),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
