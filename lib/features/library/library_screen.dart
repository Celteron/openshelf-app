import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/library/add_book_screen.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/settings/settings_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

const double _wideBreakpoint = 840.0;

/// Library list: browse, search, filter by status, and batch-assign locations
/// via long-press multi-selection. On wide screens a master-detail layout shows
/// the list and the selected book side by side (spec §6.1, T071).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  int? _selectedBookId;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    context.read<LibraryCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
                tooltip: l10n.cancel,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            tooltip: l10n.settingsTitle,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          final listPane = _ListPane(
            searchController: _searchController,
            selectedIds: _selectedIds,
            onTapBook: (id) => _handleTap(id, isWide),
            onLongPressBook: _toggleSelection,
            onSearch: (q) => context.read<LibraryCubit>().search(q),
          );

          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 380, child: listPane),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedBookId == null
                      ? Center(child: Text(l10n.noBooksYet))
                      : BookDetailScreen(
                          key: ValueKey(_selectedBookId),
                          bookId: _selectedBookId!,
                        ),
                ),
              ],
            );
          }
          return listPane;
        },
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _openAddBook(context),
              tooltip: l10n.addBookTitle,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: _selectionMode
          ? _SelectionBar(
              count: _selectedIds.length,
              onClear: _clearSelection,
              onAssign: _assignLocations,
            )
          : null,
    );
  }

  void _handleTap(int id, bool isWide) {
    if (_selectionMode) {
      _toggleSelection(id);
    } else if (isWide) {
      setState(() => _selectedBookId = id);
    } else {
      _openDetail(context, id);
    }
  }

  Future<void> _assignLocations() async {
    final l10n = AppLocalizations.of(context);
    final location = await showModalBottomSheet<_LocationChoice>(
      context: context,
      builder: (_) => _LocationPickerSheet(
        title: l10n.chooseLocation,
        repository: context.read<LocationRepository>(),
      ),
    );
    if (location == null || !mounted) return;

    await context.read<LibraryCubit>().bulkAssignLocation(
      _selectedIds.toList(),
      location.id,
    );
    _clearSelection();
  }

  void _openDetail(BuildContext context, int id) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
  }

  void _openAddBook(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddBookScreen()));
  }
}

class _ListPane extends StatelessWidget {
  final TextEditingController searchController;
  final Set<int> selectedIds;
  final void Function(int id) onTapBook;
  final void Function(int id) onLongPressBook;
  final void Function(String query) onSearch;

  const _ListPane({
    required this.searchController,
    required this.selectedIds,
    required this.onTapBook,
    required this.onLongPressBook,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: onSearch,
          ),
        ),
        const _StatusFilterBar(),
        Expanded(
          child: BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              if (state is LibraryLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is LibraryLoaded) {
                if (state.books.isEmpty) {
                  return Center(child: Text(l10n.noBooksYet));
                }
                return ListView.builder(
                  itemCount: state.books.length,
                  itemBuilder: (context, index) {
                    final book = state.books[index];
                    return ListTile(
                      leading: _Cover(book),
                      title: Text(book.title),
                      subtitle: Text(book.authors.join(', ')),
                      selected: selectedIds.contains(book.id),
                      onLongPress: () => onLongPressBook(book.id),
                      onTap: () => onTapBook(book.id),
                    );
                  },
                );
              }
              return Center(child: Text(l10n.errorLoadingLibrary));
            },
          ),
        ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onAssign;

  const _SelectionBar({
    required this.count,
    required this.onClear,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(l10n.selectedCount(count)),
              const Spacer(),
              TextButton(onPressed: onClear, child: Text(l10n.cancel)),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onAssign,
                icon: const Icon(Icons.shelves),
                label: Text(l10n.assignLocation),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationChoice {
  final int? id;
  const _LocationChoice(this.id);
}

class _LocationPickerSheet extends StatelessWidget {
  final String title;
  final LocationRepository repository;

  const _LocationPickerSheet({required this.title, required this.repository});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Flexible(
            child: FutureBuilder<List<Location>>(
              future: repository.getLocations(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final locations = snapshot.data!;
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: Text(l10n.cancel),
                      onTap: () =>
                          Navigator.pop(context, const _LocationChoice(null)),
                    ),
                    for (final location in locations)
                      ListTile(
                        leading: const Icon(Icons.shelves),
                        title: Text(location.name),
                        onTap: () => Navigator.pop(
                          context,
                          _LocationChoice(location.id),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final current = state is LibraryLoaded ? state.statusFilter : null;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in BookStatus.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(status.name),
                    selected: current == status,
                    onSelected: (_) => context
                        .read<LibraryCubit>()
                        .filterByStatus(current == status ? null : status),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  final Book book;
  const _Cover(this.book);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: book.title,
      image: true,
      child: Container(
        width: 40,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.book),
      ),
    );
  }
}
