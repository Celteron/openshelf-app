import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/library_sort.dart';
import 'package:openreads/domain/models/tag_with_count.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/library/add_book_screen.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/library/widgets/book_grid_tile.dart';
import 'package:openreads/features/library/widgets/book_list_tile.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/tags/tags_cubit.dart';
import 'package:openreads/features/settings/settings_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

const double _wideBreakpoint = 840.0;

/// Library list: browse, search, filter by status, and batch-assign locations
/// via long-press multi-selection. On wide screens a master-detail layout shows
/// the list and the selected book side by side (spec §6.1, T071).
class LibraryScreen extends StatefulWidget {
  /// Opens the scanner tab; the add sheet offers scanning only with it.
  final VoidCallback? onScan;

  const LibraryScreen({super.key, this.onScan});

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

  /// Selects every book the list currently shows (respecting search/filters).
  void _selectAll() {
    final state = context.read<LibraryCubit>().state;
    if (state is! LibraryLoaded) return;
    setState(() => _selectedIds.addAll(state.books.map((b) => b.id)));
  }

  /// Keeps the selection within the shown books, so a bulk action after a
  /// filter or search change never touches books the user cannot see.
  void _pruneSelection(LibraryState state) {
    if (state is! LibraryLoaded || _selectedIds.isEmpty) return;
    final shown = {for (final b in state.books) b.id};
    if (_selectedIds.every(shown.contains)) return;
    setState(() => _selectedIds.retainWhere(shown.contains));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<LibraryCubit, LibraryState>(
      listener: (_, state) => _pruneSelection(state),
      child: _buildScaffold(context, l10n),
    );
  }

  Widget _buildScaffold(BuildContext context, AppLocalizations l10n) {
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
          if (_selectionMode)
            IconButton(
              key: const ValueKey('select-all'),
              icon: const Icon(Icons.select_all),
              tooltip: l10n.selectAll,
              onPressed: _selectAll,
            ),
          const _ViewToggle(),
          const _SortMenu(),
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
                          onDeleted: () =>
                              setState(() => _selectedBookId = null),
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
              onSetFormat: _setFormat,
              onSetAuthor: _setAuthor,
              onDelete: _deleteSelected,
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

  Future<void> _setFormat() async {
    final l10n = AppLocalizations.of(context);
    final format = await showDialog<BookFormat>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.bulkSetFormat),
        children: [
          for (final f in BookFormat.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, f),
              child: Text(formatLabel(l10n, f)),
            ),
        ],
      ),
    );
    if (format == null || !mounted) return;
    await context.read<LibraryCubit>().bulkSetFormat(
      _selectedIds.toList(),
      format,
    );
    _clearSelection();
  }

  Future<void> _setAuthor() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _BulkAuthorDialog(),
    );
    final authors = [
      for (final a in (text ?? '').split(','))
        if (a.trim().isNotEmpty) a.trim(),
    ];
    if (authors.isEmpty || !mounted) return;
    await context.read<LibraryCubit>().bulkSetAuthors(
      _selectedIds.toList(),
      authors,
    );
    _clearSelection();
  }

  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context);
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bulkDeleteTitle(count)),
        content: Text(l10n.moveToTrashBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.moveToTrash),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final cubit = context.read<LibraryCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ids = _selectedIds.toList();
    await cubit.deleteBooks(ids);
    if (_selectedBookId != null && ids.contains(_selectedBookId)) {
      _selectedBookId = null;
    }
    _clearSelection();
    messenger.showSnackBar(SnackBar(content: Text(l10n.movedToTrash(count))));
  }

  void _openDetail(BuildContext context, int id) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
  }

  /// "+" asks how to add (FR-R2-11): next to the scanner a lone "add" button
  /// was ambiguous.
  Future<void> _openAddBook(BuildContext context) async {
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AddSheet(canScan: widget.onScan != null),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _AddChoice.scan:
        widget.onScan?.call();
      case _AddChoice.search || _AddChoice.manual:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AddBookScreen(searchOnline: choice == _AddChoice.search),
          ),
        );
    }
  }
}

enum _AddChoice { scan, search, manual }

class _AddSheet extends StatelessWidget {
  final bool canScan;
  const _AddSheet({required this.canScan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget option(
      _AddChoice choice,
      IconData icon,
      String title,
      String hint,
    ) => ListTile(
      key: ValueKey('add-${choice.name}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(hint),
      onTap: () => Navigator.of(context).pop(choice),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canScan)
              option(
                _AddChoice.scan,
                Icons.qr_code_scanner,
                l10n.addScanTitle,
                l10n.addScanHint,
              ),
            option(
              _AddChoice.search,
              Icons.travel_explore,
              l10n.addSearchTitle,
              l10n.addSearchHint,
            ),
            option(
              _AddChoice.manual,
              Icons.edit_note,
              l10n.addManualTitle,
              l10n.addManualHint,
            ),
          ],
        ),
      ),
    );
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
        const _ActiveTagsBar(),
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
                return BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (a, b) =>
                      a.displayType != b.displayType ||
                      a.ratingDisplay != b.ratingDisplay,
                  builder: (context, settings) => _BookCollection(
                    books: state.books,
                    volumes: state.volumes,
                    displayType: settings.displayType,
                    ratingDisplay: settings.ratingDisplay,
                    selectedIds: selectedIds,
                    onTapBook: onTapBook,
                    onLongPressBook: onLongPressBook,
                  ),
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

/// Asks for the author(s) to set on all selected books (comma-separated).
/// Owns its controller so it is disposed together with the dialog.
class _BulkAuthorDialog extends StatefulWidget {
  const _BulkAuthorDialog();

  @override
  State<_BulkAuthorDialog> createState() => _BulkAuthorDialogState();
}

class _BulkAuthorDialogState extends State<_BulkAuthorDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.bulkSetAuthor),
      content: TextField(
        key: const ValueKey('bulk-author-field'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.fieldAuthors),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// App-bar sort menu: pick a field; picking the active one flips direction.
class _SortMenu extends StatelessWidget {
  const _SortMenu();

  static String _label(AppLocalizations l10n, LibrarySortField field) =>
      switch (field) {
        LibrarySortField.title => l10n.sortTitle,
        LibrarySortField.author => l10n.sortAuthor,
        LibrarySortField.rating => l10n.sortRating,
        LibrarySortField.added => l10n.sortAdded,
        LibrarySortField.progress => l10n.sortProgress,
        LibrarySortField.modified => l10n.sortModified,
        LibrarySortField.pages => l10n.sortPages,
        LibrarySortField.publicationYear => l10n.sortPublicationYear,
        LibrarySortField.status => l10n.sortStatus,
        LibrarySortField.lastRead => l10n.sortLastRead,
        LibrarySortField.startDate => l10n.sortStartDate,
        LibrarySortField.finishDate => l10n.sortFinishDate,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final sort = state is LibraryLoaded ? state.sort : const LibrarySort();
        return PopupMenuButton<LibrarySortField>(
          key: const ValueKey('sort-menu'),
          icon: const Icon(Icons.sort),
          tooltip: l10n.sortBy,
          onSelected: context.read<LibraryCubit>().selectSort,
          itemBuilder: (_) => [
            for (final field in LibrarySortField.values)
              PopupMenuItem(
                value: field,
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: field == sort.field
                          ? Icon(
                              sort.ascending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 18,
                              semanticLabel: sort.ascending
                                  ? l10n.sortAscending
                                  : l10n.sortDescending,
                            )
                          : null,
                    ),
                    Text(_label(l10n, field)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onAssign;
  final VoidCallback onSetFormat;
  final VoidCallback onSetAuthor;
  final VoidCallback onDelete;

  const _SelectionBar({
    required this.count,
    required this.onClear,
    required this.onAssign,
    required this.onSetFormat,
    required this.onSetAuthor,
    required this.onDelete,
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
              Expanded(child: Text(l10n.selectedCount(count))),
              IconButton(
                key: const ValueKey('bulk-location'),
                icon: const Icon(Icons.shelves),
                tooltip: l10n.assignLocation,
                onPressed: onAssign,
              ),
              IconButton(
                key: const ValueKey('bulk-format'),
                icon: const Icon(Icons.menu_book_outlined),
                tooltip: l10n.bulkSetFormat,
                onPressed: onSetFormat,
              ),
              IconButton(
                key: const ValueKey('bulk-author'),
                icon: const Icon(Icons.person_outline),
                tooltip: l10n.bulkSetAuthor,
                onPressed: onSetAuthor,
              ),
              IconButton(
                key: const ValueKey('bulk-delete'),
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.moveToTrash,
                onPressed: onDelete,
              ),
              TextButton(onPressed: onClear, child: Text(l10n.cancel)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The library as a list, compact list, grid or detailed grid. A slipcase
/// shows its volume count; in the lists it expands to its volumes.
class _BookCollection extends StatefulWidget {
  final List<Book> books;
  final Map<int, List<Book>> volumes;
  final LibraryDisplayType displayType;
  final RatingDisplay ratingDisplay;
  final Set<int> selectedIds;
  final void Function(int id) onTapBook;
  final void Function(int id) onLongPressBook;

  const _BookCollection({
    required this.books,
    required this.volumes,
    required this.displayType,
    required this.ratingDisplay,
    required this.selectedIds,
    required this.onTapBook,
    required this.onLongPressBook,
  });

  @override
  State<_BookCollection> createState() => _BookCollectionState();
}

class _BookCollectionState extends State<_BookCollection> {
  final _expanded = <int>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final books = widget.books;
    final volumes = widget.volumes;
    if (widget.displayType.isGrid) {
      final detailed = widget.displayType == LibraryDisplayType.detailedGrid;
      return GridView.builder(
        key: const ValueKey('book-grid'),
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: detailed ? 170 : 140,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: detailed ? 0.5 : 0.68,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          final count = volumes[book.id]?.length;
          return BookGridTile(
            book: book,
            detailed: detailed,
            ratingDisplay: widget.ratingDisplay,
            selected: widget.selectedIds.contains(book.id),
            badge: count == null ? null : l10n.volumeCount(count),
            onTap: () => widget.onTapBook(book.id),
            onLongPress: () => widget.onLongPressBook(book.id),
          );
        },
      );
    }
    final compact = widget.displayType == LibraryDisplayType.compactList;
    // Expanded slipcases are followed by their volumes, indented.
    final rows = <(Book, {bool isVolume})>[
      for (final book in books) ...[
        (book, isVolume: false),
        if (_expanded.contains(book.id))
          for (final volume in volumes[book.id] ?? const <Book>[])
            (volume, isVolume: true),
      ],
    ];
    return ListView.builder(
      key: const ValueKey('book-list'),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final (book, :isVolume) = rows[index];
        final ownVolumes = volumes[book.id];
        final tile = BookListTile(
          book: book,
          compact: compact || isVolume,
          ratingDisplay: widget.ratingDisplay,
          selected: widget.selectedIds.contains(book.id),
          note: ownVolumes == null ? null : _slipcaseNote(l10n, ownVolumes),
          trailing: ownVolumes != null
              ? _ExpandButton(
                  slipcaseId: book.id,
                  expanded: _expanded.contains(book.id),
                  onPressed: () => setState(() {
                    if (!_expanded.remove(book.id)) _expanded.add(book.id);
                  }),
                )
              : book.status == BookStatus.wishlist
              ? _MoveToLibraryButton(bookId: book.id)
              : null,
          onTap: () => widget.onTapBook(book.id),
          onLongPress: () => widget.onLongPressBook(book.id),
        );
        return isVolume
            ? Padding(padding: const EdgeInsets.only(left: 32), child: tile)
            : tile;
      },
    );
  }

  static String _slipcaseNote(AppLocalizations l10n, List<Book> volumes) {
    final read = volumes.where((v) => v.status == BookStatus.read).length;
    return '${l10n.volumeCount(volumes.length)} · '
        '${l10n.volumesReadProgress(read, volumes.length)}';
  }
}

class _ExpandButton extends StatelessWidget {
  final int slipcaseId;
  final bool expanded;
  final VoidCallback onPressed;

  const _ExpandButton({
    required this.slipcaseId,
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: ValueKey('expand:$slipcaseId'),
      icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      tooltip: expanded ? l10n.hideVolumes : l10n.showVolumes,
      onPressed: onPressed,
    );
  }
}

/// App-bar button switching between the list and the grid layout. The two
/// compact/detailed variants are chosen in the settings.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) => a.displayType != b.displayType,
      builder: (context, settings) {
        final isGrid = settings.displayType.isGrid;
        return IconButton(
          key: const ValueKey('view-toggle'),
          icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
          tooltip: isGrid ? l10n.showAsList : l10n.showAsGrid,
          onPressed: () => context.read<SettingsCubit>().setDisplayType(
            isGrid ? LibraryDisplayType.list : LibraryDisplayType.grid,
          ),
        );
      },
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
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final current = state is LibraryLoaded ? state.statusFilter : null;
        final favoritesOnly = state is LibraryLoaded && state.favoritesOnly;
        final withoutCover = state is LibraryLoaded && state.withoutCoverOnly;
        final hasCoverless = state is LibraryLoaded && state.hasCoverless;
        final years = state is LibraryLoaded
            ? state.availableYears
            : const <int>[];
        final yearFilter = state is LibraryLoaded ? state.yearFilter : null;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const _TagFilterChip(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  key: const ValueKey('favorites-filter'),
                  avatar: const Icon(Icons.favorite_border, size: 16),
                  label: Text(l10n.favoritesFilter),
                  selected: favoritesOnly,
                  onSelected: (_) =>
                      context.read<LibraryCubit>().toggleFavoritesOnly(),
                ),
              ),
              if (hasCoverless || withoutCover)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    key: const ValueKey('without-cover-filter'),
                    avatar: const Icon(Icons.hide_image_outlined, size: 16),
                    label: Text(l10n.withoutCoverFilter),
                    selected: withoutCover,
                    onSelected: (_) =>
                        context.read<LibraryCubit>().toggleWithoutCover(),
                  ),
                ),
              if (years.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  // PopupMenuButton never reports a `null` selection, so "all
                  // years" is the sentinel 0.
                  child: PopupMenuButton<int>(
                    key: const ValueKey('year-filter'),
                    tooltip: l10n.yearFilter,
                    onSelected: (y) => context
                        .read<LibraryCubit>()
                        .filterByYear(y == 0 ? null : y),
                    itemBuilder: (_) => [
                      PopupMenuItem<int>(value: 0, child: Text(l10n.allYears)),
                      for (final y in years)
                        PopupMenuItem<int>(value: y, child: Text('$y')),
                    ],
                    child: Chip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text(yearFilter?.toString() ?? l10n.yearFilter),
                      backgroundColor: yearFilter == null
                          ? null
                          : Theme.of(context).colorScheme.secondaryContainer,
                    ),
                  ),
                ),
              for (final status in BookStatus.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(statusLabel(l10n, status)),
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

/// Wishlist → owned in one tap, without a confirmation dialog
/// (Constitution V.2).
class _MoveToLibraryButton extends StatelessWidget {
  final int bookId;
  const _MoveToLibraryButton({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.library_add),
      tooltip: l10n.moveToLibrary,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        await context.read<LibraryCubit>().moveToLibrary(bookId);
        messenger.showSnackBar(SnackBar(content: Text(l10n.movedToLibrary)));
      },
    );
  }
}

/// Opens the tag sheet; shows how many tags are active. Hidden without tags.
class _TagFilterChip extends StatelessWidget {
  const _TagFilterChip();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasTags = context.select(
      (TagsCubit c) => switch (c.state) {
        TagsLoaded(:final tags) => tags.isNotEmpty,
        _ => false,
      },
    );
    if (!hasTags) return const SizedBox.shrink();
    final activeCount = context.select(
      (LibraryCubit c) => switch (c.state) {
        LibraryLoaded(:final tagIds) => tagIds.length,
        _ => 0,
      },
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        key: const ValueKey('tag-filter'),
        avatar: const Icon(Icons.sell_outlined, size: 16),
        label: Text(l10n.tagFilterLabel(activeCount)),
        backgroundColor: activeCount == 0
            ? null
            : Theme.of(context).colorScheme.secondaryContainer,
        onPressed: () => _showTagSheet(context),
      ),
    );
  }

  void _showTagSheet(BuildContext context) {
    final tags = context.read<TagsCubit>();
    final library = context.read<LibraryCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: tags),
          BlocProvider.value(value: library),
        ],
        child: const _TagFilterSheet(),
      ),
    );
  }
}

/// All tags as wrapping chips with a search field; selecting several narrows
/// the list (AND).
class _TagFilterSheet extends StatefulWidget {
  const _TagFilterSheet();

  @override
  State<_TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends State<_TagFilterSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tagsState = context.watch<TagsCubit>().state;
    final libraryState = context.watch<LibraryCubit>().state;
    final tags = tagsState is TagsLoaded ? tagsState.tags : <TagWithCount>[];
    final selected = libraryState is LibraryLoaded
        ? libraryState.tagIds
        : const <int>{};
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final entry in tags)
        if (entry.tag.name.toLowerCase().contains(query)) entry,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.filterByTags,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (selected.isNotEmpty)
                  TextButton(
                    onPressed: () => context.read<LibraryCubit>().clearTags(),
                    child: Text(l10n.clearTagFilter),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('tag-search'),
              decoration: InputDecoration(
                hintText: l10n.tagSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (q) => setState(() => _query = q),
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  tags.isEmpty ? l10n.noTagsYet : l10n.noMatchingTags,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final entry in shown)
                        FilterChip(
                          label: Text(entry.tag.name),
                          selected: selected.contains(entry.tag.id),
                          onSelected: (_) => context
                              .read<LibraryCubit>()
                              .toggleTag(entry.tag.id),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The active tags above the list, each removable; takes no space without
/// any. Also drops filters on tags that were deleted meanwhile.
class _ActiveTagsBar extends StatelessWidget {
  const _ActiveTagsBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<TagsCubit, TagsState>(
      listener: (context, tagsState) {
        if (tagsState is TagsLoaded) {
          context.read<LibraryCubit>().retainTags({
            for (final entry in tagsState.tags) entry.tag.id,
          });
        }
      },
      builder: (context, tagsState) {
        if (tagsState is! TagsLoaded) return const SizedBox.shrink();
        return BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            final selected = state is LibraryLoaded
                ? state.tagIds
                : const <int>{};
            final active = [
              for (final entry in tagsState.tags)
                if (selected.contains(entry.tag.id)) entry.tag,
            ];
            if (active.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final tag in active)
                      InputChip(
                        avatar: const Icon(Icons.sell_outlined, size: 16),
                        label: Text(tag.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        deleteButtonTooltipMessage: l10n.removeTagFilter(
                          tag.name,
                        ),
                        onDeleted: () =>
                            context.read<LibraryCubit>().toggleTag(tag.id),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
