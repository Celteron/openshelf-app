import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/features/scanner/scanner_cubit.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Continuous batch barcode scanner with a staging shelf and "save all" CTA
/// (spec §6.2, US5). On platforms without a camera implementation (e.g. Linux
/// desktop) the preview degrades gracefully to a notice.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;

  /// Kept for dispose(): looking up the cubit through a deactivated context
  /// is unsafe.
  late final ScannerCubit _cubit;

  static bool get _supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_supportsCamera) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.ean13],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
    _cubit = context.read<ScannerCubit>()..start(defaults: _defaults());
  }

  StagedDefaults _defaults() {
    try {
      final settings = context.read<SettingsCubit>().state;
      return StagedDefaults(
        format: settings.defaultFormat,
        status: settings.defaultStatus,
      );
    } catch (_) {
      return const StagedDefaults(); // no settings (isolated widget tests)
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _cubit.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scannerTitle)),
      body: Column(
        children: [
          Expanded(
            child: _supportsCamera
                ? Semantics(
                    label: l10n.scannerTitle,
                    image: true,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller!,
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              final raw = barcode.rawValue;
                              if (raw != null) {
                                context.read<ScannerCubit>().onScanned(raw);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.scannerUnsupported,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
          _StagingShelf(),
        ],
      ),
    );
  }
}

class _StagingShelf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ScannerCubit, ScannerState>(
      builder: (context, state) {
        if (state is! ScannerActive) return const SizedBox.shrink();
        final cubit = context.read<ScannerCubit>();
        return Container(
          constraints: const BoxConstraints(maxHeight: 280),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.stagedCount(state.staged.length))),
                  IconButton(
                    key: const ValueKey('staged-shared'),
                    icon: const Icon(Icons.tune),
                    tooltip: l10n.sharedValuesTitle,
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: _SharedValuesSheet(initial: state.shared),
                      ),
                    ),
                  ),
                ],
              ),
              _SharedSummary(shared: state.shared),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final book in state.staged)
                      ListTile(
                        dense: true,
                        leading: book.duplicate
                            ? Icon(
                                Icons.warning,
                                color: Theme.of(context).colorScheme.error,
                              )
                            : UrlCover(
                                key: ValueKey('staged-cover:${book.isbn13}'),
                                cacheKey: book.isbn13,
                                url: book.metadata?.coverUrl,
                                width: 32,
                                height: 46,
                                borderRadius: BorderRadius.circular(3),
                              ),
                        title: Text(book.metadata?.title ?? book.isbn13),
                        subtitle: Text(
                          book.duplicate
                              ? l10n.alreadyInLibrary
                              : switch (book.metadata?.authors) {
                                  final authors? when authors.isNotEmpty =>
                                    authors.join(', '),
                                  _ => book.isbn13,
                                },
                        ),
                        trailing: IconButton(
                          key: ValueKey('staged-remove:${book.isbn13}'),
                          icon: const Icon(Icons.close),
                          tooltip: l10n.removeStaged,
                          onPressed: () => cubit.removeStaged(book.isbn13),
                        ),
                        // An owned book is skipped on save; nothing to edit.
                        onTap: book.duplicate
                            ? null
                            : () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) => BlocProvider.value(
                                  value: cubit,
                                  child: _StagedEditor(book: book),
                                ),
                              ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.saving ? null : cubit.saveAll,
                  child: Text(state.saving ? l10n.saving : l10n.saveAll),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One line saying what "save all" will apply.
class _SharedSummary extends StatelessWidget {
  final StagedDefaults shared;
  const _SharedSummary({required this.shared});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<Location>>(
      future: shared.locationId == null
          ? null
          : context.read<LocationRepository>().getLocations(),
      builder: (context, snapshot) {
        final location = [
          for (final l in snapshot.data ?? const <Location>[])
            if (l.id == shared.locationId) l.name,
        ];
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            [
              statusLabel(l10n, shared.status),
              if (shared.format case final format?) formatLabel(l10n, format),
              if (shared.receivedAs case final received?)
                receivedAsLabel(l10n, received),
              ...location,
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}

/// Corrects what the lookup found for one staged book; only changed fields
/// count as user edits.
class _StagedEditor extends StatefulWidget {
  final StagedBook book;
  const _StagedEditor({required this.book});

  @override
  State<_StagedEditor> createState() => _StagedEditorState();
}

class _StagedEditorState extends State<_StagedEditor> {
  late final BookMetadata _initial =
      widget.book.metadata ?? const BookMetadata();
  late final _title = TextEditingController(text: _initial.title ?? '');
  late final _authors = TextEditingController(
    text: _initial.authors.join(', '),
  );
  late final _pages = TextEditingController(
    text: _initial.pageCount?.toString() ?? '',
  );
  late final _publisher = TextEditingController(text: _initial.publisher ?? '');
  late final _year = TextEditingController(
    text: _initial.publishedYear?.toString() ?? '',
  );

  @override
  void dispose() {
    for (final c in [_title, _authors, _pages, _publisher, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _save() {
    final edited = BookMetadata(
      title: _text(_title),
      authors: [
        for (final a in _authors.text.split(','))
          if (a.trim().isNotEmpty) a.trim(),
      ],
      pageCount: int.tryParse(_pages.text.trim()),
      publisher: _text(_publisher),
      publishedYear: int.tryParse(_year.text.trim()),
    );
    final changed = {
      if (edited.title != _initial.title) 'title',
      if (edited.authors.join(', ') != _initial.authors.join(', ')) 'authors',
      if (edited.pageCount != _initial.pageCount) 'pageCount',
      if (edited.publisher != _initial.publisher) 'publisher',
      if (edited.publishedYear != _initial.publishedYear) 'publishedYear',
    };
    if (changed.isNotEmpty) {
      context.read<ScannerCubit>().editStaged(
        widget.book.isbn13,
        edited,
        changed,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget field(
      String key,
      TextEditingController controller,
      String label, {
      bool number = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: ValueKey(key),
        controller: controller,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.editStagedTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(widget.book.isbn13),
            const SizedBox(height: 16),
            field('staged-edit-title', _title, l10n.fieldTitle),
            field('staged-edit-authors', _authors, l10n.fieldAuthors),
            field('staged-edit-pages', _pages, l10n.fieldPages, number: true),
            field('staged-edit-publisher', _publisher, l10n.fieldPublisher),
            field('staged-edit-year', _year, l10n.fieldYear, number: true),
            FilledButton(
              key: const ValueKey('staged-edit-save'),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location, format, status and "received as" for every book of the batch.
class _SharedValuesSheet extends StatefulWidget {
  final StagedDefaults initial;
  const _SharedValuesSheet({required this.initial});

  @override
  State<_SharedValuesSheet> createState() => _SharedValuesSheetState();
}

class _SharedValuesSheetState extends State<_SharedValuesSheet> {
  late int? _locationId = widget.initial.locationId;
  late BookFormat? _format = widget.initial.format;
  late BookStatus _status = widget.initial.status;
  late ReceivedAs? _receivedAs = widget.initial.receivedAs;
  late final Future<List<Location>> _locations = context
      .read<LocationRepository>()
      .getLocations();

  Widget _dropdown<T>({
    required String key,
    required String label,
    required T value,
    required List<(T, String)> items,
    required ValueChanged<T> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: ValueKey(key),
          value: value,
          isExpanded: true,
          items: [
            for (final (v, text) in items)
              DropdownMenuItem<T>(value: v, child: Text(text)),
          ],
          onChanged: (v) => setState(() => onChanged(v as T)),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.sharedValuesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(l10n.sharedValuesHint),
            const SizedBox(height: 16),
            FutureBuilder<List<Location>>(
              future: _locations,
              builder: (context, snapshot) => _dropdown<int?>(
                key: 'shared-location',
                label: l10n.fieldLocation,
                value: _locationId,
                items: [
                  (null, l10n.noLocation),
                  for (final l in snapshot.data ?? const <Location>[])
                    (l.id, l.name),
                ],
                onChanged: (v) => _locationId = v,
              ),
            ),
            _dropdown<BookFormat?>(
              key: 'shared-format',
              label: l10n.fieldFormat,
              value: _format,
              items: [
                (null, l10n.formatUnknown),
                for (final f in BookFormat.values) (f, formatLabel(l10n, f)),
              ],
              onChanged: (v) => _format = v,
            ),
            _dropdown<BookStatus>(
              key: 'shared-status',
              label: l10n.statusLabel,
              value: _status,
              items: [
                for (final s in BookStatus.values) (s, statusLabel(l10n, s)),
              ],
              onChanged: (v) => _status = v,
            ),
            _dropdown<ReceivedAs?>(
              key: 'shared-received-as',
              label: l10n.fieldReceivedAs,
              value: _receivedAs,
              items: [
                (null, l10n.receivedAsUnknown),
                for (final r in ReceivedAs.values)
                  (r, receivedAsLabel(l10n, r)),
              ],
              onChanged: (v) => _receivedAs = v,
            ),
            FilledButton(
              key: const ValueKey('shared-apply'),
              onPressed: () {
                context.read<ScannerCubit>().setShared(
                  StagedDefaults(
                    locationId: _locationId,
                    format: _format,
                    status: _status,
                    receivedAs: _receivedAs,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Text(l10n.apply),
            ),
          ],
        ),
      ),
    );
  }
}
