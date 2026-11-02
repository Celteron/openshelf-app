/// The blocks the home tab is built from. [code] is what gets stored, so
/// renaming a value never changes what a saved layout means.
enum HomeModule {
  donut('donut'),
  pinnedStats('pinned'),
  goal('goal'),
  currentlyReading('reading'),
  recent('recent'),
  unreadTrend('trend'),
  favourites('favourites'),
  heatmap('heatmap');

  final String code;
  const HomeModule(this.code);

  static HomeModule? fromCode(String code) =>
      values.where((m) => m.code == code).firstOrNull;
}

/// Which home blocks are shown, and in which order (user setting).
///
/// Stored as one string, e.g. `donut,-goal,recent`: codes in order, a `-`
/// marks a hidden block. Reading is tolerant, so a setting written by an
/// older or newer version never breaks the home tab.
class HomeLayout {
  /// Every module exactly once.
  final List<HomeModule> order;
  final Set<HomeModule> hidden;

  const HomeLayout(this.order, [this.hidden = const {}]);

  /// Today's home tab: everything, in the original order.
  static const standard = HomeLayout(HomeModule.values);

  List<HomeModule> get visible => [
    for (final m in order)
      if (!hidden.contains(m)) m,
  ];

  /// Moves the module at [from] to position [to] (both indices into
  /// [order], [to] counted after the module was taken out).
  HomeLayout move(int from, int to) {
    final next = [...order];
    next.insert(to, next.removeAt(from));
    return HomeLayout(next, hidden);
  }

  HomeLayout toggle(HomeModule module) => HomeLayout(
    order,
    hidden.contains(module)
        ? ({...hidden}..remove(module))
        : {...hidden, module},
  );

  String encode() =>
      order.map((m) => hidden.contains(m) ? '-${m.code}' : m.code).join(',');

  /// Unknown codes are dropped, repeats counted once, and modules the string
  /// does not know (added in a later version) are appended, visible.
  factory HomeLayout.parse(String? stored) {
    if (stored == null || stored.trim().isEmpty) return standard;
    final order = <HomeModule>[];
    final hidden = <HomeModule>{};
    for (final token in stored.split(',')) {
      final off = token.startsWith('-');
      final module = HomeModule.fromCode(off ? token.substring(1) : token);
      if (module == null || order.contains(module)) continue;
      order.add(module);
      if (off) hidden.add(module);
    }
    for (final m in HomeModule.values) {
      if (!order.contains(m)) order.add(m);
    }
    return HomeLayout(order, hidden);
  }
}
