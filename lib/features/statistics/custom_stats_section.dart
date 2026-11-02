import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/helpers/maybe_read.dart';
import 'package:openreads/domain/models/stat_definition.dart';
import 'package:openreads/domain/models/stat_tile.dart';
import 'package:openreads/domain/services/stat_query.dart';
import 'package:openreads/features/statistics/custom_stats_cubit.dart';
import 'package:openreads/features/statistics/stat_builder_screen.dart';
import 'package:openreads/features/statistics/stat_tile_view.dart';
import 'package:openreads/features/statistics/statistics_books_screen.dart';
import 'package:openreads/features/statistics/stats_section_header.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// "Eigene Statistiken", the last section of the statistics screen (spec
/// 005, T5-06): the user's tiles, reorderable by drag and through their menu,
/// and a button that builds a new one.
///
/// A sliver for the screen's [CustomScrollView]: the tiles live in the
/// page's own scrollable, so dragging one to an edge scrolls the page.
class CustomStatsSection extends StatelessWidget {
  /// Switches to the library tab from a drill-down.
  final VoidCallback? onShowLibrary;

  const CustomStatsSection({super.key, this.onShowLibrary});

  @override
  Widget build(BuildContext context) {
    final cubit = context.maybeRead<CustomStatsCubit>();
    // No cubit in isolated widget tests.
    if (cubit == null) return const SliverToBoxAdapter();
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<CustomStatsCubit, CustomStatsState>(
      bloc: cubit,
      builder: (context, state) => SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: StatsSectionHeader(
              'section-custom',
              l10n.statsSectionCustom,
            ),
          ),
          switch (state) {
            CustomStatsLoading() => const SliverToBoxAdapter(),
            CustomStatsError() => SliverToBoxAdapter(
              child: Text(l10n.errorLoadingLibrary),
            ),
            CustomStatsLoaded(:final tiles, :final library) =>
              SliverReorderableList(
                key: const ValueKey('custom-tiles'),
                itemCount: tiles.length,
                onReorderItem: cubit.reorderTile,
                // Unlike ReorderableListView, the sliver adds no Material for
                // the dragged copy; the tile's card brings its own surface.
                proxyDecorator: (child, _, _) =>
                    Material(type: MaterialType.transparency, child: child),
                itemBuilder: (context, i) {
                  final t = tiles[i];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(t.tile.id),
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StatTileView(
                        id: 'custom-tile-${t.tile.id}',
                        title: t.tile.title,
                        definition: t.tile.definition,
                        result: t.result,
                        library: library,
                        onBooks: (label, ids) => showStatBooks(
                          context,
                          library,
                          label,
                          ids,
                          onShowLibrary: onShowLibrary,
                        ),
                        trailing: _TileMenu(
                          tile: t.tile,
                          library: library,
                          first: i == 0,
                          last: i == tiles.length - 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
          },
          if (state is CustomStatsLoaded)
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const ValueKey('custom-add'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.statAdd),
                  onPressed: () => _build(context, state.library),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _build(BuildContext context, StatLibrary library) async {
    final cubit = context.read<CustomStatsCubit>();
    final result = await _openBuilder(context, library);
    if (result == null) return;
    await cubit.addTile(result.$1, result.$2);
  }
}

/// The books behind a value of a tile (FR-05-07).
Future<void> showStatBooks(
  BuildContext context,
  StatLibrary library,
  String label,
  Set<int> ids, {
  VoidCallback? onShowLibrary,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => StatisticsBooksScreen(
      title: label,
      books: [
        for (final b in library.books)
          if (ids.contains(b.id)) b,
      ],
      onShowInLibrary: onShowLibrary,
    ),
  ),
);

Future<(String, StatDefinition)?> _openBuilder(
  BuildContext context,
  StatLibrary library, {
  StatTile? tile,
}) => Navigator.of(context).push<(String, StatDefinition)>(
  MaterialPageRoute(
    builder: (_) => StatBuilderScreen(library: library, tile: tile),
  ),
);

enum _TileAction { edit, pin, up, down, delete }

/// Edit, pin, move and delete; moving here is the screen-reader way to
/// reorder (drag needs a long press).
class _TileMenu extends StatelessWidget {
  final StatTile tile;
  final StatLibrary library;
  final bool first;
  final bool last;

  const _TileMenu({
    required this.tile,
    required this.library,
    required this.first,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = 'custom-tile-${tile.id}';
    PopupMenuItem<_TileAction> item(_TileAction action, String text) =>
        PopupMenuItem(
          key: ValueKey('$id-${action.name}'),
          value: action,
          child: Text(text),
        );
    return PopupMenuButton<_TileAction>(
      key: ValueKey('$id-menu'),
      tooltip: l10n.statMenu,
      onSelected: (action) => _run(context, action),
      itemBuilder: (_) => [
        item(_TileAction.edit, l10n.statEdit),
        item(_TileAction.pin, tile.pinned ? l10n.statUnpin : l10n.statPin),
        if (!first) item(_TileAction.up, l10n.statMoveUp),
        if (!last) item(_TileAction.down, l10n.statMoveDown),
        item(_TileAction.delete, l10n.delete),
      ],
    );
  }

  Future<void> _run(BuildContext context, _TileAction action) async {
    final cubit = context.read<CustomStatsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _TileAction.edit:
        final result = await _openBuilder(context, library, tile: tile);
        if (result == null) return;
        await cubit.updateTile(
          tile.id,
          title: result.$1,
          definition: result.$2,
        );
      case _TileAction.pin:
        final done = await cubit.setPinned(tile.id, pinned: !tile.pinned);
        if (!done) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.statPinLimit(StatTile.maxPinned))),
          );
        }
      case _TileAction.up:
        await cubit.moveTile(tile.id, -1);
      case _TileAction.down:
        await cubit.moveTile(tile.id, 1);
      case _TileAction.delete:
        final undo = await cubit.deleteTile(tile);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.statDeleted(tile.title)),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () async {
                if (!await undo()) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.statPinLimit(StatTile.maxPinned)),
                    ),
                  );
                }
              },
            ),
          ),
        );
    }
  }
}
