import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/features/tags/tags_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Tag management: create, rename and delete tags (Phase 2, US-C).
class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageTags)),
      body: BlocBuilder<TagsCubit, TagsState>(
        builder: (context, state) {
          return switch (state) {
            TagsLoading() => const Center(child: CircularProgressIndicator()),
            TagsError() => Center(child: Text(l10n.errorLoadingLibrary)),
            TagsLoaded(:final tags) =>
              tags.isEmpty
                  ? Center(child: Text(l10n.noTagsYet))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [
                        for (final entry in tags)
                          ListTile(
                            leading: const Icon(Icons.sell_outlined),
                            title: Text(entry.tag.name),
                            subtitle: Text(l10n.tagBookCount(entry.bookCount)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: l10n.renameTag,
                                  onPressed: () => _rename(context, entry.tag),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: l10n.delete,
                                  onPressed: () => _delete(context, entry.tag),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addTag,
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<TagsCubit>();
    final name = await _askName(
      context,
      title: AppLocalizations.of(context).addTag,
    );
    if (name != null) await cubit.create(name);
  }

  Future<void> _rename(BuildContext context, Tag tag) async {
    final cubit = context.read<TagsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final name = await _askName(
      context,
      title: l10n.renameTag,
      initial: tag.name,
    );
    if (name == null) return;
    final result = await cubit.rename(tag.id, name);
    if (result == TagResult.nameTaken) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.tagNameTaken)));
    }
  }

  Future<void> _delete(BuildContext context, Tag tag) async {
    final cubit = context.read<TagsCubit>();
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTagTitle(tag.name)),
        content: Text(l10n.deleteTagBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.delete(tag.id);
  }
}

Future<String?> _askName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.newTagHint),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l10n.save),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

/// Bottom sheet that toggles the tags of one book and creates new ones inline.
class BookTagPickerSheet extends StatefulWidget {
  final int bookId;
  const BookTagPickerSheet({super.key, required this.bookId});

  static Future<void> show(BuildContext context, int bookId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TagsCubit>()),
          BlocProvider(
            create: (context) =>
                BookTagsCubit(bookId, context.read<TagRepository>())..load(),
          ),
        ],
        child: BookTagPickerSheet(bookId: bookId),
      ),
    );
  }

  @override
  State<BookTagPickerSheet> createState() => _BookTagPickerSheetState();
}

class _BookTagPickerSheetState extends State<BookTagPickerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _controller.text;
    _controller.clear();
    await context.read<BookTagsCubit>().createAndAssign(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.editTags, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          BlocBuilder<TagsCubit, TagsState>(
            builder: (context, tagsState) {
              final all = tagsState is TagsLoaded ? tagsState.tags : const [];
              return BlocBuilder<BookTagsCubit, List<Tag>>(
                builder: (context, assigned) {
                  final ids = {for (final t in assigned) t.id};
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final entry in all)
                        FilterChip(
                          label: Text(entry.tag.name),
                          selected: ids.contains(entry.tag.id),
                          onSelected: (_) => context
                              .read<BookTagsCubit>()
                              .toggle(entry.tag.id),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: l10n.newTagHint),
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.addTag,
                onPressed: _add,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
