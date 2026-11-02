import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/features/locations/location_tree_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// "Mein Regal" — Room → Shelf → Compartment tree with CRUD and the deletion
/// guard (spec §6.1, US3).
class LocationTreeScreen extends StatefulWidget {
  const LocationTreeScreen({super.key});

  @override
  State<LocationTreeScreen> createState() => _LocationTreeScreenState();
}

class _LocationTreeScreenState extends State<LocationTreeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LocationTreeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myShelf)),
      body: BlocBuilder<LocationTreeCubit, LocationTreeState>(
        builder: (context, state) {
          if (state is LocationTreeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LocationTreeLoaded) {
            if (state.roots.isEmpty) {
              return Center(child: Text(l10n.noLocationsYet));
            }
            return ListView(
              children: [
                for (final node in state.roots)
                  _buildNode(context, node, 0, state),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addLocation(context, null, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNode(
    BuildContext context,
    LocationNode node,
    int depth,
    LocationTreeState state,
  ) {
    final expanded =
        state is LocationTreeLoaded &&
        state.expandedIds.contains(node.location.id);
    final hasChildren = node.children.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 * (depth + 1)),
          leading: hasChildren
              ? Icon(expanded ? Icons.expand_more : Icons.chevron_right)
              : const Icon(Icons.bookmark_border),
          title: Text(node.location.name),
          subtitle: Text(node.location.type.name),
          onTap: () {
            if (hasChildren) {
              context.read<LocationTreeCubit>().toggleExpanded(
                node.location.id,
              );
            } else {
              context.read<LocationTreeCubit>().select(node.location.id);
            }
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () =>
                    _addLocation(context, node.location.id, node.location.type),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteLocation(context, node.location),
              ),
            ],
          ),
        ),
        if (expanded)
          for (final child in node.children)
            _buildNode(context, child, depth + 1, state),
      ],
    );
  }

  Future<void> _addLocation(
    BuildContext context,
    int? parentId,
    LocationType? parentType,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(context, l10n.locationName);
    if (name == null || name.isEmpty) return;
    if (!context.mounted) return;
    final type = parentType == null
        ? LocationType.room
        : (parentType == LocationType.room
              ? LocationType.shelf
              : LocationType.compartment);
    await context.read<LocationTreeCubit>().create(
      name: name,
      type: type,
      parentId: parentId,
    );
  }

  Future<void> _deleteLocation(BuildContext context, Location location) async {
    try {
      await context.read<LocationTreeCubit>().delete(location.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).locationNotEmpty)),
      );
    }
  }

  Future<String?> _promptName(BuildContext context, String title) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
