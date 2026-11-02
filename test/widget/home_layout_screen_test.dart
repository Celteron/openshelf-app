import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openreads/domain/models/home_layout.dart';
import 'package:openreads/features/home/home_layout_screen.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

import '../helpers/fake_settings_repository.dart';

void main() {
  late SettingsCubit settings;
  late FakeSettingsRepository repo;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    repo = FakeSettingsRepository();
    settings = SettingsCubit(repo);
    addTearDown(settings.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: settings,
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeLayoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every block with its switch on', (tester) async {
    await pump(tester);

    for (final m in HomeModule.values) {
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(ValueKey('home-module-${m.code}')),
            )
            .value,
        isTrue,
        reason: m.code,
      );
    }
    expect(find.text('Leseziel'), findsOneWidget);
  });

  testWidgets('a switch hides the block and the choice is saved', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('home-module-goal')));
    await tester.pumpAndSettle();

    expect(settings.state.homeLayout.hidden, {HomeModule.goal});
    expect(repo.values['homeLayout'], contains('-goal'));
  });

  testWidgets('dragging the handle reorders the blocks', (tester) async {
    await pump(tester);

    final handle = find.byKey(const ValueKey('home-handle-donut'));
    final target = tester.getCenter(
      find.byKey(const ValueKey('home-handle-goal')),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(target + const Offset(0, 30));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final order = settings.state.homeLayout.order;
    expect(order.indexOf(HomeModule.donut), greaterThan(0));
    expect(order.first, HomeModule.pinnedStats);
  });

  testWidgets('reset restores the standard layout', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('home-module-goal')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-layout-reset')));
    await tester.pumpAndSettle();

    expect(settings.state.homeLayout.encode(), HomeLayout.standard.encode());
    expect(repo.values.containsKey('homeLayout'), isFalse);
  });
}
