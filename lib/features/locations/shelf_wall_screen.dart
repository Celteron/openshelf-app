import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/helpers/maybe_read.dart';
import 'package:openreads/data/cover/spine_color_service.dart';
import 'package:openreads/domain/models/shelf_wall.dart';
import 'package:openreads/domain/models/spine_color.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/library/book_detail_screen.dart';
import 'package:openreads/features/locations/location_tree_screen.dart';
import 'package:openreads/features/locations/shelf_wall_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// The shelf as a picture: a row of spines per compartment. The former text
/// tree stays one tap away for managing locations.
class ShelfWallScreen extends StatelessWidget {
  /// Opens a book; the detail screen unless a test says otherwise.
  final void Function(int bookId)? onOpenBook;

  const ShelfWallScreen({super.key, this.onOpenBook});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShelfWallCubit(
        context.read<BookRepository>(),
        context.read<LocationRepository>(),
      )..load(),
      child: _WallView(onOpenBook: onOpenBook),
    );
  }
}

/// Header (path) plus the shelf board: every row is this high, so the wall
/// can scroll to a row by arithmetic even though rows are built lazily.
const _headerHeight = 44.0;
const _rowExtent = _headerHeight + SpineMetrics.maxHeight + 8;

class _WallView extends StatefulWidget {
  final void Function(int bookId)? onOpenBook;
  const _WallView({this.onOpenBook});

  @override
  State<_WallView> createState() => _WallViewState();
}

class _WallViewState extends State<_WallView> {
  final _scroll = ScrollController();
  final _field = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _scroll.dispose();
    _field.dispose();
    super.dispose();
  }

  void _open(BuildContext context, int bookId) {
    final custom = widget.onOpenBook;
    if (custom != null) return custom(bookId);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)));
  }

  /// Moves a book and offers to undo it. Saving can fail, so the user hears
  /// about that instead of the book silently staying put.
  Future<void> _move(
    BuildContext context,
    ShelfWall wall,
    int bookId,
    int? locationId,
  ) async {
    final cubit = context.read<ShelfWallCubit>();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final move = await cubit.moveBook(bookId, locationId);
      if (move == null) return;
      final place = _placeLabel(l10n, wall, locationId);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.shelfMoved(place)),
            action: SnackBarAction(
              label: l10n.shelfUndo,
              onPressed: () async {
                try {
                  await cubit.moveBook(bookId, move.from);
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.shelfMoveFailed)),
                  );
                }
              },
            ),
          ),
        );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.shelfMoveFailed)));
    }
  }

  static String _placeLabel(
    AppLocalizations l10n,
    ShelfWall wall,
    int? locationId,
  ) {
    if (locationId == null) return l10n.shelfUnassigned;
    return wall.rows
            .where((r) => r.locationId == locationId)
            .map((r) => r.pathLabel)
            .firstOrNull ??
        '';
  }

  /// The accessible alternative to dragging: pick the place from a list.
  Future<void> _pickPlace(
    BuildContext context,
    ShelfWall wall,
    int bookId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final position = wall.positionOf(bookId);
    if (position == null) return;
    final current = wall.rows[position.row].locationId;
    final places = [
      for (final row in wall.rows)
        if (row.locationId != null && row.locationId != current)
          (id: row.locationId, label: row.pathLabel),
      if (current != null) (id: null, label: l10n.shelfUnassigned),
    ];
    final picked = await showModalBottomSheet<({int? id})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.shelfMoveTo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final place in places)
                    ListTile(
                      leading: const Icon(Icons.shelves),
                      title: Text(place.label),
                      onTap: () => Navigator.pop(context, (id: place.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) {
      await _move(context, wall, bookId, picked.id);
    }
  }

  /// While a spine is dragged near the top or bottom edge the wall scrolls,
  /// so a far-away shelf can be reached.
  void _edgeScroll(DragUpdateDetails details) {
    if (!_scroll.hasClients) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final y = box.globalToLocal(details.globalPosition).dy;
    const zone = 120.0;
    final step = y < kToolbarHeight + zone
        ? -16.0
        : (y > box.size.height - zone ? 16.0 : 0.0);
    if (step == 0) return;
    _scroll.jumpTo(
      (_scroll.offset + step).clamp(0.0, _scroll.position.maxScrollExtent),
    );
  }

  void _closeSearch(ShelfWallCubit cubit) {
    _field.clear();
    cubit.clearFind();
    setState(() => _searching = false);
  }

  /// Brings the focused hit's row into view.
  void _scrollToFocus(ShelfWallLoaded state) {
    final id = state.focusedBookId;
    final position = id == null ? null : state.wall.positionOf(id);
    if (position == null || !_scroll.hasClients) return;
    final target = (position.row * _rowExtent - _rowExtent).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  AppBar _appBar(BuildContext context, AppLocalizations l10n) {
    final cubit = context.read<ShelfWallCubit>();
    if (!_searching) {
      return AppBar(
        title: Text(l10n.myShelf),
        actions: [
          IconButton(
            key: const ValueKey('shelf-find'),
            icon: const Icon(Icons.search),
            tooltip: l10n.shelfFind,
            onPressed: () => setState(() => _searching = true),
          ),
          IconButton(
            key: const ValueKey('shelf-manage'),
            icon: const Icon(Icons.edit_location_alt_outlined),
            tooltip: l10n.shelfManage,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LocationTreeScreen()),
            ),
          ),
        ],
      );
    }
    return AppBar(
      leading: IconButton(
        key: const ValueKey('shelf-find-close'),
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.shelfFindClose,
        onPressed: () => _closeSearch(cubit),
      ),
      title: TextField(
        key: const ValueKey('shelf-find-field'),
        controller: _field,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.shelfFindHint,
          border: InputBorder.none,
        ),
        onChanged: cubit.find,
      ),
      actions: [
        BlocBuilder<ShelfWallCubit, ShelfWallState>(
          builder: (context, state) {
            if (state is! ShelfWallLoaded || !state.isSearching) {
              return const SizedBox.shrink();
            }
            final hits = state.hits;
            return Row(
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    hits.isEmpty
                        ? l10n.shelfFindNone
                        : l10n.shelfFindCount(
                            hits.indexOf(state.focusedBookId ?? hits.first) + 1,
                            hits.length,
                          ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('shelf-find-previous'),
                  icon: const Icon(Icons.keyboard_arrow_up),
                  tooltip: l10n.shelfFindPrevious,
                  onPressed: hits.isEmpty ? null : cubit.previousHit,
                ),
                IconButton(
                  key: const ValueKey('shelf-find-next'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: l10n.shelfFindNext,
                  onPressed: hits.isEmpty ? null : cubit.nextHit,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<ShelfWallCubit, ShelfWallState>(
      listenWhen: (a, b) =>
          b is ShelfWallLoaded &&
          b.focusedBookId != null &&
          (a is! ShelfWallLoaded || a.focusedBookId != b.focusedBookId),
      listener: (context, state) => _scrollToFocus(state as ShelfWallLoaded),
      child: Scaffold(
        appBar: _appBar(context, l10n),
        body: BlocBuilder<ShelfWallCubit, ShelfWallState>(
          builder: (context, state) => switch (state) {
            ShelfWallLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ShelfWallError() => Center(child: Text(l10n.errorLoadingLibrary)),
            ShelfWallLoaded(:final wall) when wall.rows.isEmpty => Center(
              child: Text(l10n.noLocationsYet),
            ),
            ShelfWallLoaded() => ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 24),
              itemExtent: _rowExtent,
              itemCount: state.wall.rows.length,
              itemBuilder: (context, i) => _RowView(
                row: state.wall.rows[i],
                hits: state.isSearching ? state.hits.toSet() : null,
                focusedId: state.focusedBookId,
                expanded: state.expanded,
                onToggleSlipcase: context.read<ShelfWallCubit>().toggleSlipcase,
                onOpen: (id) => _open(context, id),
                onPickPlace: (id) => _pickPlace(context, state.wall, id),
                onDrop: (id, place) => _move(context, state.wall, id, place),
                onDragUpdate: _edgeScroll,
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _RowView extends StatefulWidget {
  final ShelfRow row;

  /// The ids of the matching spines while a search is open, else `null`.
  final Set<int>? hits;
  final int? focusedId;

  /// Slipcases shown open.
  final Set<int> expanded;
  final void Function(int bookId) onToggleSlipcase;
  final void Function(int bookId) onOpen;
  final void Function(int bookId) onPickPlace;

  /// A spine was dropped on this row: move it here.
  final void Function(int bookId, int? locationId) onDrop;
  final void Function(DragUpdateDetails) onDragUpdate;

  const _RowView({
    required this.row,
    required this.hits,
    required this.focusedId,
    required this.expanded,
    required this.onToggleSlipcase,
    required this.onOpen,
    required this.onPickPlace,
    required this.onDrop,
    required this.onDragUpdate,
  });

  @override
  State<_RowView> createState() => _RowViewState();
}

class _RowViewState extends State<_RowView> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: _offsetOfFocus() ?? 0,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// What stands on the board: spines, with an open slipcase followed by its
  /// volumes and a handle to its own page.
  List<_Item> _items() {
    final items = <_Item>[];
    for (final spine in widget.row.spines) {
      final id = spine.book.id;
      if (spine.volumes.isNotEmpty && widget.expanded.contains(id)) {
        items.add(
          _Item(
            spine: Spine(
              book: spine.book,
              volumes: spine.volumes,
              width: SpineMetrics.minWidth,
              height: spine.height,
            ),
            kind: _ItemKind.slipcase,
            slipcaseId: id,
          ),
        );
        for (final volume in spine.volumes) {
          items.add(
            _Item(
              spine: Spine(
                book: volume,
                volumes: const [],
                width: SpineMetrics.widthFor(volume.pageCount),
                height: SpineMetrics.heightFor(volume.pageCount),
              ),
              kind: _ItemKind.volume,
              slipcaseId: id,
            ),
          );
        }
        items.add(
          _Item(
            spine: Spine(
              book: spine.book,
              volumes: const [],
              width: SpineMetrics.minWidth,
              height: SpineMetrics.minHeight,
            ),
            kind: _ItemKind.handle,
            slipcaseId: id,
          ),
        );
      } else {
        items.add(_Item(spine: spine, kind: _ItemKind.spine, slipcaseId: id));
      }
    }
    return items;
  }

  /// Where the focused spine starts, when it stands in this row.
  double? _offsetOfFocus() {
    final id = widget.focusedId;
    if (id == null) return null;
    var x = 0.0;
    for (final item in _items()) {
      if (item.spine.book.id == id && item.kind != _ItemKind.handle) return x;
      x += item.spine.width + SpineMetrics.gap;
    }
    return null;
  }

  @override
  void didUpdateWidget(_RowView old) {
    super.didUpdateWidget(old);
    final target = widget.focusedId == old.focusedId ? null : _offsetOfFocus();
    if (target != null && _scroll.hasClients) {
      _scroll.animateTo(
        target.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// A closed slipcase opens and an open one closes; every other spine
  /// leads to its book's page.
  VoidCallback _onTap(_Item item) {
    final id = item.spine.book.id;
    final isCase =
        item.kind == _ItemKind.slipcase ||
        (item.kind == _ItemKind.spine && item.spine.volumes.isNotEmpty);
    return isCase ? () => widget.onToggleSlipcase(id) : () => widget.onOpen(id);
  }

  SpineHighlight _highlight(_Item item) {
    final hits = widget.hits;
    if (hits == null) return SpineHighlight.none;
    // A volume stands in for its slipcase: it is a hit when the case is.
    if (!hits.contains(item.slipcaseId)) return SpineHighlight.dimmed;
    return item.slipcaseId == widget.focusedId && item.kind != _ItemKind.volume
        ? SpineHighlight.focused
        : SpineHighlight.hit;
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final items = _items();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = row.locationId == null ? l10n.shelfUnassigned : row.pathLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _headerHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Semantics(
              header: true,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: SpineMetrics.maxHeight + 8,
          child: DragTarget<int>(
            onWillAcceptWithDetails: (d) =>
                !row.spines.any((sp) => sp.book.id == d.data),
            onAcceptWithDetails: (d) => widget.onDrop(d.data, row.locationId),
            builder: (context, candidates, _) => DecoratedBox(
              decoration: BoxDecoration(
                color: candidates.isEmpty
                    ? null
                    : theme.colorScheme.tertiaryContainer.withValues(
                        alpha: 0.5,
                      ),
                // The board the books stand on.
                border: Border(
                  bottom: BorderSide(
                    color: candidates.isEmpty
                        ? theme.colorScheme.outlineVariant
                        : theme.colorScheme.tertiary,
                    width: 4,
                  ),
                ),
              ),
              child: row.spines.isEmpty
                  ? Center(
                      child: Text(
                        l10n.shelfEmptyRow,
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final id = item.spine.book.id;
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: SpineMetrics.gap,
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _SpineView(
                              key: ValueKey('item-${item.kind.name}-$id'),
                              spine: item.spine,
                              kind: item.kind,
                              highlight: _highlight(item),
                              onTap: _onTap(item),
                              onPickPlace: () => widget.onPickPlace(id),
                              onDragUpdate: widget.onDragUpdate,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _ItemKind {
  spine,
  slipcase,
  volume,
  handle;

  /// The small tab of an open slipcase that leads to its own page.
  bool get isHandle => this == handle;

  /// A volume's place is its slipcase's place, and the handle is no book:
  /// neither can be dragged or moved on its own.
  bool get movable => this == spine || this == slipcase;
}

/// One thing standing on the board.
class _Item {
  final Spine spine;
  final _ItemKind kind;

  /// The slipcase this belongs to (the spine's own id for a plain spine).
  final int slipcaseId;

  const _Item({
    required this.spine,
    required this.kind,
    required this.slipcaseId,
  });
}

/// How a spine looks while "find it" is open.
enum SpineHighlight { none, dimmed, hit, focused }

class _SpineView extends StatefulWidget {
  final Spine spine;
  final SpineHighlight highlight;
  final VoidCallback onTap;

  /// Opens the list of places: the way to move a book without dragging.
  final VoidCallback onPickPlace;
  final void Function(DragUpdateDetails) onDragUpdate;

  final _ItemKind kind;
  const _SpineView({
    super.key,
    required this.spine,
    required this.kind,
    required this.highlight,
    required this.onTap,
    required this.onPickPlace,
    required this.onDragUpdate,
  });

  @override
  State<_SpineView> createState() => _SpineViewState();
}

class _SpineViewState extends State<_SpineView> {
  /// The cover's colour once known; until then (and without a cover) the
  /// colour the title gives, so a spine never flashes.
  int? _coverColor;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_SpineView old) {
    super.didUpdateWidget(old);
    if (old.spine.book.coverLocalPath != widget.spine.book.coverLocalPath) {
      _coverColor = null;
      _resolve();
    }
  }

  /// Asked when the spine is built, which for the lazy rows means when it
  /// comes into view.
  Future<void> _resolve() async {
    final path = widget.spine.book.coverLocalPath;
    if (path == null) return;
    final service = context.maybeRead<SpineColorService>();
    if (service == null) return; // isolated widget tests
    final color = await service.colorFor(path);
    // The answer may belong to a cover that has been replaced meanwhile.
    if (!mounted || path != widget.spine.book.coverLocalPath) return;
    if (color != _coverColor) setState(() => _coverColor = color);
  }

  @override
  Widget build(BuildContext context) {
    final spine = widget.spine;
    final onTap = widget.onTap;
    final l10n = AppLocalizations.of(context);
    final book = spine.book;
    final scheme = Theme.of(context).colorScheme;
    final base = _coverColor ?? placeholderSpineColor(book.title);
    // Dimmed by mixing with the surface (not by Opacity), so the title stays
    // as readable as its own background allows.
    final color = widget.highlight == SpineHighlight.dimmed
        ? Color.lerp(Color(base), scheme.surface, 0.72)!.toARGB32()
        : base;
    final side = switch (widget.highlight) {
      SpineHighlight.focused => BorderSide(color: scheme.tertiary, width: 4),
      SpineHighlight.hit => BorderSide(color: scheme.tertiary, width: 2),
      _ => BorderSide.none,
    };
    const radius = BorderRadius.vertical(top: Radius.circular(4));
    final onColor = Color(onSpineColor(color));
    final authors = book.authors.join(', ');
    final pages = book.pageCount;
    Widget face({Key? key, VoidCallback? onTap, double elevation = 0}) =>
        Material(
          key: key,
          color: Color(color),
          elevation: elevation,
          shape: RoundedRectangleBorder(borderRadius: radius, side: side),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: SizedBox(
              width: spine.width,
              height: spine.height,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    Expanded(
                      child: widget.kind.isHandle
                          ? Center(
                              child: Icon(Icons.open_in_new, color: onColor),
                            )
                          : RotatedBox(
                              quarterTurns: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: onColor),
                                ),
                              ),
                            ),
                    ),
                    if (spine.volumes.isNotEmpty)
                      Text(
                        l10n.shelfSlipcaseCount(spine.volumes.length),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: onColor),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

    final facekey = ValueKey(
      widget.kind.isHandle ? 'slipcase-open-${book.id}' : 'spine-${book.id}',
    );
    final semanticsLabel = widget.kind.isHandle
        ? book.title
        : (pages == null || pages <= 0
              ? l10n.shelfSpineLabel(book.title, authors)
              : l10n.shelfSpineLabelPages(book.title, authors, pages));
    final tappable = face(key: facekey, onTap: onTap);
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      // Dragging is for sighted users; this is the same move for everyone else.
      customSemanticsActions: widget.kind.movable
          ? {CustomSemanticsAction(label: l10n.shelfMoveTo): widget.onPickPlace}
          : null,
      child: widget.kind.movable
          ? GestureDetector(
              onSecondaryTap: widget.onPickPlace,
              child: LongPressDraggable<int>(
                data: book.id,
                onDragUpdate: widget.onDragUpdate,
                feedback: face(elevation: 8),
                childWhenDragging: Opacity(opacity: 0.25, child: face()),
                child: tappable,
              ),
            )
          : tappable,
    );
  }
}
