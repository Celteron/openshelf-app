import 'dart:io';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/constants/app_fonts.dart';
import 'package:openreads/core/themes/app_theme.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/services/cover_sync_service.dart';
import 'package:openreads/domain/services/data_wipe_service.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/features/importer/importer_screen.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/tags/tags_cubit.dart';
import 'package:openreads/features/tags/tags_screen.dart';
import 'package:openreads/features/trash/trash_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const _sourceCodeUrl = 'https://github.com/Celteron/openshelf-app';
const _issuesUrl = 'https://github.com/Celteron/openshelf-app/issues';

/// App settings: appearance (theme, accent colour, Material You, AMOLED, font,
/// rating style, list layout), language, book defaults, tags, trash, covers,
/// export/import and app info (spec §6.6).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version}+${info.buildNumber}');
      }
    } catch (_) {
      // Unavailable (e.g. in tests): the version row simply stays empty.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(l10n.appearanceSection),
              RadioGroup<ThemeMode>(
                groupValue: state.themeMode,
                onChanged: (v) => cubit.setThemeMode(v!),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.themeSystem),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.themeLight),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.themeDark),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                key: const ValueKey('material-you'),
                title: Text(l10n.materialYou),
                subtitle: Text(l10n.materialYouHint),
                value: state.materialYou,
                onChanged: cubit.setMaterialYou,
              ),
              ListTile(
                key: const ValueKey('accent-color'),
                enabled: !state.materialYou,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(
                    state.accentColor ?? defaultAccentColor.toARGB32(),
                  ),
                ),
                title: Text(l10n.accentColor),
                subtitle: state.materialYou
                    ? Text(l10n.accentColorDisabledHint)
                    : null,
                trailing: state.accentColor == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.restart_alt),
                        tooltip: l10n.resetToDefault,
                        onPressed: () => cubit.setAccentColor(null),
                      ),
                onTap: state.materialYou ? null : () => _pickAccent(state),
              ),
              SwitchListTile(
                key: const ValueKey('amoled'),
                title: Text(l10n.amoledDark),
                subtitle: Text(l10n.amoledDarkHint),
                value: state.amoled,
                onChanged: cubit.setAmoled,
              ),
              ListTile(
                key: const ValueKey('font-tile'),
                leading: const Icon(Icons.font_download_outlined),
                title: Text(l10n.fontLabel),
                subtitle: Text(
                  appFonts
                      .firstWhere(
                        (f) => f.family == state.fontFamily,
                        orElse: () => appFonts.first,
                      )
                      .label,
                ),
                onTap: () => _pickFont(state),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.ratingStyleLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioGroup<RatingDisplay>(
                groupValue: state.ratingDisplay,
                onChanged: (v) => cubit.setRatingDisplay(v!),
                child: Column(
                  children: [
                    RadioListTile<RatingDisplay>(
                      title: Text(l10n.ratingAsBar),
                      value: RatingDisplay.bar,
                    ),
                    RadioListTile<RatingDisplay>(
                      title: Text(l10n.ratingAsNumber),
                      value: RatingDisplay.number,
                    ),
                  ],
                ),
              ),
              Text(
                l10n.listLayoutLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioGroup<LibraryDisplayType>(
                groupValue: state.displayType,
                onChanged: (v) => cubit.setDisplayType(v!),
                child: Column(
                  children: [
                    for (final type in LibraryDisplayType.values)
                      RadioListTile<LibraryDisplayType>(
                        key: ValueKey('display:${type.name}'),
                        title: Text(_displayLabel(l10n, type)),
                        value: type,
                      ),
                  ],
                ),
              ),
              const Divider(),
              _section(l10n.languageLabel),
              RadioGroup<String>(
                groupValue: state.localeCode,
                onChanged: (v) => cubit.setLocaleCode(v!),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(l10n.languageGerman),
                      value: 'de',
                    ),
                    RadioListTile<String>(
                      title: Text(l10n.languageEnglish),
                      value: 'en',
                    ),
                  ],
                ),
              ),
              const Divider(),
              _section(l10n.booksSection),
              ListTile(
                title: Text(l10n.defaultFormat),
                trailing: DropdownButton<BookFormat>(
                  key: const ValueKey('default-format'),
                  value: state.defaultFormat,
                  items: [
                    for (final f in BookFormat.values)
                      DropdownMenuItem(value: f, child: Text(f.name)),
                  ],
                  onChanged: (v) {
                    if (v != null) cubit.setDefaultFormat(v);
                  },
                ),
              ),
              ListTile(
                title: Text(l10n.defaultStatus),
                trailing: DropdownButton<BookStatus>(
                  key: const ValueKey('default-status'),
                  value: state.defaultStatus,
                  items: [
                    for (final s in BookStatus.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(statusLabel(l10n, s)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) cubit.setDefaultStatus(v);
                  },
                ),
              ),
              ListTile(
                key: const ValueKey('default-tags'),
                leading: const Icon(Icons.sell_outlined),
                title: Text(l10n.defaultTags),
                subtitle: Text(
                  l10n.defaultTagsHint(state.defaultTagIds.length),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickDefaultTags(state),
              ),
              ListTile(
                leading: const Icon(Icons.sell_outlined),
                title: Text(l10n.manageTags),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TagsScreen())),
              ),
              ListTile(
                key: const ValueKey('open-trash'),
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.trashTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TrashScreen())),
              ),
              ListTile(
                key: const ValueKey('download-covers'),
                leading: const Icon(Icons.image_outlined),
                title: Text(l10n.downloadMissingCovers),
                subtitle: Text(l10n.downloadMissingCoversHint),
                onTap: _downloadCovers,
              ),
              const Divider(),
              _section(l10n.exportLabel),
              ListTile(
                leading: const Icon(Icons.data_object),
                title: Text(l10n.exportJson),
                subtitle: Text(l10n.exportJsonHint),
                onTap: () => _exportJson(),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: Text(l10n.exportCsv),
                subtitle: Text(l10n.exportCsvHint),
                onTap: () => _exportCsv(),
              ),
              ListTile(
                key: const ValueKey('open-import'),
                leading: const Icon(Icons.settings_backup_restore),
                title: Text(l10n.restoreBackup),
                subtitle: Text(l10n.restoreBackupHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImporterScreen()),
                ),
              ),
              const Divider(),
              _section(l10n.dataSection),
              ListTile(
                key: const ValueKey('clear-library'),
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(l10n.clearLibrary),
                subtitle: Text(l10n.clearLibraryHint),
                onTap: _clearLibrary,
              ),
              ListTile(
                key: const ValueKey('delete-all-data'),
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(l10n.deleteAllData),
                subtitle: Text(l10n.deleteAllDataHint),
                onTap: _deleteAllData,
              ),
              const Divider(),
              _section(l10n.appInfoLabel),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.versionLabel),
                subtitle: Text(_version),
              ),
              ListTile(
                leading: const Icon(Icons.gavel),
                title: Text(l10n.licenseLabel),
                subtitle: Text(l10n.licenseText),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(l10n.openSourceCreditsLabel),
                subtitle: Text(l10n.creditsText),
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(l10n.sourceCode),
                subtitle: const Text(_sourceCodeUrl),
                onTap: () => _open(_sourceCodeUrl),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.reportIssue),
                subtitle: const Text(_issuesUrl),
                onTap: () => _open(_issuesUrl),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  String _displayLabel(AppLocalizations l10n, LibraryDisplayType type) =>
      switch (type) {
        LibraryDisplayType.list => l10n.displayList,
        LibraryDisplayType.compactList => l10n.displayCompactList,
        LibraryDisplayType.grid => l10n.displayGrid,
        LibraryDisplayType.detailedGrid => l10n.displayDetailedGrid,
      };

  Future<void> _pickAccent(SettingsState state) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    var selected = Color(state.accentColor ?? defaultAccentColor.toARGB32());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accentColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: selected,
            onColorChanged: (c) => selected = c,
            pickersEnabled: const <ColorPickerType, bool>{
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: false,
              ColorPickerType.wheel: true,
            },
            pickerTypeLabels: <ColorPickerType, String>{
              ColorPickerType.primary: l10n.standardColors,
              ColorPickerType.wheel: l10n.customColor,
            },
            enableShadesSelection: false,
            showColorName: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.setAccentColor(selected.toARGB32());
  }

  Future<void> _pickFont(SettingsState state) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    final picked = await showDialog<AppFont>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.fontLabel),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: 320,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final font in appFonts)
                ListTile(
                  key: ValueKey('font:${font.family ?? 'default'}'),
                  selected: font.family == state.fontFamily,
                  title: Text(
                    font.label,
                    style: TextStyle(fontFamily: font.family),
                  ),
                  onTap: () => Navigator.pop(dialogContext, font),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (picked != null) await cubit.setFontFamily(picked.family);
  }

  Future<void> _pickDefaultTags(SettingsState state) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    final tagsState = context.read<TagsCubit>().state;
    final tags = tagsState is TagsLoaded ? tagsState.tags : const [];
    final selected = {...state.defaultTagIds};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.defaultTags),
          content: SizedBox(
            width: 300,
            child: tags.isEmpty
                ? Text(l10n.noTagsYet)
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final entry in tags)
                        CheckboxListTile(
                          key: ValueKey('default-tag:${entry.tag.id}'),
                          title: Text(entry.tag.name),
                          value: selected.contains(entry.tag.id),
                          onChanged: (checked) => setDialogState(() {
                            if (checked == true) {
                              selected.add(entry.tag.id);
                            } else {
                              selected.remove(entry.tag.id);
                            }
                          }),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await cubit.setDefaultTagIds(selected);
  }

  Future<void> _downloadCovers() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sync = context.read<CoverSyncService>();
    messenger.showSnackBar(SnackBar(content: Text(l10n.coversDownloading)));
    final result = await sync.downloadMissing();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.total == 0
              ? l10n.coversNoneMissing
              : l10n.coversDownloaded(result.downloaded, result.failed),
        ),
      ),
    );
  }

  /// Empties the library: the user chooses between the (restorable) trash and
  /// deleting for good; the latter asks a second time.
  Future<void> _clearLibrary() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showDialog<_ClearChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearLibraryTitle),
        content: Text(l10n.clearLibraryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, _ClearChoice.trash),
            child: Text(l10n.moveToTrash),
          ),
          FilledButton(
            style: _dangerStyle(dialogContext),
            onPressed: () => Navigator.pop(dialogContext, _ClearChoice.forever),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;

    final service = context.read<DataWipeService>();
    final messenger = ScaffoldMessenger.of(context);
    switch (choice) {
      case _ClearChoice.trash:
        final count = await service.trashLibrary();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.libraryTrashed(count))),
        );
      case _ClearChoice.forever:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.deleteForeverAllTitle),
            content: Text(l10n.deleteForeverAllBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: _dangerStyle(dialogContext),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.deleteForever),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        final count = await service.deleteLibrary();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.libraryDeleted(count))),
        );
    }
  }

  /// Deletes everything the app stores locally. Typing the confirmation word
  /// guards against an accidental tap.
  Future<void> _deleteAllData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmWordDialog(),
    );
    if (confirmed != true || !mounted) return;

    final service = context.read<DataWipeService>();
    final settings = context.read<SettingsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    await service.deleteAllData();
    await settings.load();
    messenger.showSnackBar(SnackBar(content: Text(l10n.allDataDeleted)));
  }

  ButtonStyle _dangerStyle(BuildContext context) => FilledButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.error,
    foregroundColor: Theme.of(context).colorScheme.onError,
  );

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _exportJson() async {
    final json = await context.read<ExportService>().exportJson();
    await _writeExport('openshelf_export.json', json);
  }

  Future<void> _exportCsv() async {
    final csv = await context.read<ExportService>().exportBooksCsv();
    await _writeExport('openshelf_books.csv', csv);
  }

  Future<void> _writeExport(String name, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppLocalizations.of(context).exportDone} ${file.path}',
        ),
      ),
    );
  }
}

enum _ClearChoice { trash, forever }

/// Asks the user to type a word before the irreversible deletion is enabled.
class _ConfirmWordDialog extends StatefulWidget {
  const _ConfirmWordDialog();

  @override
  State<_ConfirmWordDialog> createState() => _ConfirmWordDialogState();
}

class _ConfirmWordDialogState extends State<_ConfirmWordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final word = l10n.confirmWord;
    final matches = _controller.text.trim().toUpperCase() == word;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.deleteAllDataTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAllDataBody),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('confirm-word'),
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(helperText: l10n.typeToConfirm(word)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: matches ? () => Navigator.pop(context, true) : null,
          child: Text(l10n.deleteEverything),
        ),
      ],
    );
  }
}
