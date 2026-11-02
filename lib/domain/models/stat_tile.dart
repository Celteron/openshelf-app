import 'package:openreads/domain/models/stat_definition.dart';

/// A stored tile of the user-defined statistics (spec 005).
class StatTile {
  /// At most this many tiles are shown on the home tab.
  static const maxPinned = 3;

  final int id;
  final String title;
  final StatDefinition definition;

  /// Also shown on the home tab.
  final bool pinned;

  const StatTile({
    required this.id,
    required this.title,
    required this.definition,
    this.pinned = false,
  });
}
