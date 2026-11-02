import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/home_layout.dart';
import 'package:openreads/features/settings/settings_cubit.dart';

import '../helpers/fake_settings_repository.dart';

void main() {
  test('the standard layout is today\'s order with everything visible', () {
    expect(HomeLayout.standard.visible, [
      HomeModule.donut,
      HomeModule.pinnedStats,
      HomeModule.goal,
      HomeModule.currentlyReading,
      HomeModule.recent,
      HomeModule.unreadTrend,
      HomeModule.favourites,
      HomeModule.heatmap,
    ]);
  });

  test('a layout survives encoding', () {
    final layout = HomeLayout.standard
        .move(HomeModule.favourites.index, 0)
        .toggle(HomeModule.goal)
        .toggle(HomeModule.recent);

    final parsed = HomeLayout.parse(layout.encode());

    expect(parsed.order, layout.order);
    expect(parsed.hidden, {HomeModule.goal, HomeModule.recent});
    expect(parsed.visible.first, HomeModule.favourites);
  });

  test('nothing stored means the standard layout', () {
    expect(HomeLayout.parse(null).order, HomeLayout.standard.order);
    expect(HomeLayout.parse('').order, HomeLayout.standard.order);
  });

  test('unknown codes are dropped, repeated ones counted once', () {
    final layout = HomeLayout.parse('trend,future-thing,trend,-reading');

    expect(layout.order.take(2), [
      HomeModule.unreadTrend,
      HomeModule.currentlyReading,
    ]);
    expect(layout.hidden, {HomeModule.currentlyReading});
    expect(layout.order.toSet(), HomeModule.values.toSet());
    expect(layout.order, hasLength(HomeModule.values.length));
  });

  test('a module added in a later version shows up at the end, visible', () {
    final layout = HomeLayout.parse('trend,donut');

    expect(layout.order.take(2), [HomeModule.unreadTrend, HomeModule.donut]);
    expect(layout.visible, hasLength(HomeModule.values.length));
  });

  test('toggling twice shows the module again; moving keeps all modules', () {
    final once = HomeLayout.standard.toggle(HomeModule.donut);
    expect(once.visible, isNot(contains(HomeModule.donut)));
    expect(once.toggle(HomeModule.donut).visible, contains(HomeModule.donut));

    final moved = HomeLayout.standard.move(0, 3);
    expect(moved.order.toSet(), HomeLayout.standard.order.toSet());
    expect(moved.order[3], HomeModule.donut);
  });

  test('the settings keep the layout across restarts', () async {
    final repo = FakeSettingsRepository();
    final cubit = SettingsCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.homeLayout.order, HomeLayout.standard.order);

    await cubit.setHomeLayout(HomeLayout.standard.toggle(HomeModule.goal));

    final reloaded = SettingsCubit(repo);
    addTearDown(reloaded.close);
    await reloaded.load();
    expect(reloaded.state.homeLayout.hidden, {HomeModule.goal});
  });

  test('resetting the layout forgets the stored value', () async {
    final repo = FakeSettingsRepository();
    final cubit = SettingsCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.setHomeLayout(HomeLayout.standard.toggle(HomeModule.goal));

    await cubit.setHomeLayout(HomeLayout.standard);

    expect(repo.values.containsKey('homeLayout'), isFalse);
  });
}
