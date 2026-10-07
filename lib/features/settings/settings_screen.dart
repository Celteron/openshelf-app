import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/export/export_service.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// App settings: theme mode, language, export/import quick actions, and app
/// info (spec §6.6).
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
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version}+${info.buildNumber}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(l10n.themeLabel),
              RadioGroup<ThemeMode>(
                groupValue: state.themeMode,
                onChanged: (v) =>
                    context.read<SettingsCubit>().setThemeMode(v!),
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
              const Divider(),
              _section(l10n.languageLabel),
              RadioGroup<String>(
                groupValue: state.localeCode,
                onChanged: (v) =>
                    context.read<SettingsCubit>().setLocaleCode(v!),
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
              _section(l10n.exportLabel),
              ListTile(
                leading: const Icon(Icons.data_object),
                title: Text(l10n.exportJson),
                onTap: () => _exportJson(),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: Text(l10n.exportCsv),
                onTap: () => _exportCsv(),
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
