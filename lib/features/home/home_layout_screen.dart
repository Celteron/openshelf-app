import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/home_layout.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

String homeModuleLabel(AppLocalizations l10n, HomeModule module) =>
    switch (module) {
      HomeModule.donut => l10n.homeModuleDonut,
      HomeModule.pinnedStats => l10n.homeModulePinned,
      HomeModule.goal => l10n.homeModuleGoal,
      HomeModule.currentlyReading => l10n.homeModuleReading,
      HomeModule.recent => l10n.homeModuleRecent,
      HomeModule.unreadTrend => l10n.homeModuleTrend,
      HomeModule.favourites => l10n.homeModuleFavourites,
      HomeModule.heatmap => l10n.homeModuleHeatmap,
    };

/// Reorder and hide the blocks of the home tab.
class HomeLayoutScreen extends StatelessWidget {
  const HomeLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeCustomizeTitle),
        actions: [
          IconButton(
            key: const ValueKey('home-layout-reset'),
            icon: const Icon(Icons.restart_alt),
            tooltip: l10n.homeCustomizeReset,
            onPressed: () => cubit.setHomeLayout(HomeLayout.standard),
          ),
        ],
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (a, b) => a.homeLayout != b.homeLayout,
        builder: (context, state) {
          final layout = state.homeLayout;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.homeCustomizeHint),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: layout.order.length,
                  onReorderItem: (from, to) =>
                      cubit.setHomeLayout(layout.move(from, to)),
                  itemBuilder: (context, i) {
                    final module = layout.order[i];
                    return SwitchListTile(
                      key: ValueKey('home-module-${module.code}'),
                      title: Text(homeModuleLabel(l10n, module)),
                      value: !layout.hidden.contains(module),
                      onChanged: (_) =>
                          cubit.setHomeLayout(layout.toggle(module)),
                      secondary: ReorderableDragStartListener(
                        index: i,
                        child: SizedBox(
                          key: ValueKey('home-handle-${module.code}'),
                          width: 48,
                          height: 48,
                          child: Tooltip(
                            message: l10n.homeCustomizeDrag,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
