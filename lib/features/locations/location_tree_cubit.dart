import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/location_repository.dart';

class LocationNode {
  final Location location;
  final List<LocationNode> children;

  const LocationNode({required this.location, this.children = const []});
}

sealed class LocationTreeState {
  const LocationTreeState();
}

class LocationTreeLoading extends LocationTreeState {
  const LocationTreeLoading();
}

class LocationTreeLoaded extends LocationTreeState {
  final List<LocationNode> roots;
  final int? selectedId;
  final Set<int> expandedIds;

  const LocationTreeLoaded({
    required this.roots,
    this.selectedId,
    this.expandedIds = const {},
  });

  LocationTreeLoaded copyWith({
    List<LocationNode>? roots,
    int? selectedId,
    Set<int>? expandedIds,
  }) {
    return LocationTreeLoaded(
      roots: roots ?? this.roots,
      selectedId: selectedId ?? this.selectedId,
      expandedIds: expandedIds ?? this.expandedIds,
    );
  }
}

/// Loads the Room → Shelf → Compartment tree, manages selection/expansion and
/// CRUD, and enforces the deletion guard (spec §6.1, US3).
class LocationTreeCubit extends Cubit<LocationTreeState> {
  final LocationRepository _repository;
  StreamSubscription<List<Location>>? _subscription;

  LocationTreeCubit(this._repository) : super(const LocationTreeLoading());

  void load() {
    _subscription?.cancel();
    _subscription = _repository.watchLocations().listen((locations) {
      final current = state;
      emit(
        LocationTreeLoaded(
          roots: _buildTree(locations),
          selectedId: current is LocationTreeLoaded ? current.selectedId : null,
          expandedIds: current is LocationTreeLoaded
              ? current.expandedIds
              : const {},
        ),
      );
    }, onError: (_) => emit(const LocationTreeLoading()));
  }

  Future<void> create({
    required String name,
    required LocationType type,
    int? parentId,
  }) async {
    await _repository.createLocation(
      name: name,
      type: type,
      parentId: parentId,
    );
  }

  Future<void> delete(int id) async {
    await _repository.deleteLocation(id);
  }

  void select(int id) {
    final current = state;
    if (current is LocationTreeLoaded) {
      emit(current.copyWith(selectedId: id));
    }
  }

  void toggleExpanded(int id) {
    final current = state;
    if (current is LocationTreeLoaded) {
      final expanded = {...current.expandedIds};
      expanded.contains(id) ? expanded.remove(id) : expanded.add(id);
      emit(current.copyWith(expandedIds: expanded));
    }
  }

  List<LocationNode> _buildTree(List<Location> locations) {
    final byParent = <int?, List<Location>>{};
    for (final location in locations) {
      byParent.putIfAbsent(location.parentId, () => []).add(location);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    List<LocationNode> buildChildren(int? parentId) {
      return (byParent[parentId] ?? const <Location>[])
          .map((l) => LocationNode(location: l, children: buildChildren(l.id)))
          .toList();
    }

    return buildChildren(null);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
