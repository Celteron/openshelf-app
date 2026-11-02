import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/helpers/isbn.dart';
import 'package:openreads/core/helpers/price.dart';
import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/cover/cover_picker.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/book_draft.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/models/reading_stats.dart';
import 'package:openreads/domain/repositories/location_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/features/library/cover_search_screen.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/library/widgets/rating_control.dart';
import 'package:openreads/features/metadata/metadata_cubit.dart';
import 'package:openreads/features/openlibrary/open_library_search_screen.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Manual book entry with optional ISBN metadata lookup (US1/US2).
///
/// Pass an existing [book] to open the form in edit mode: fields are
/// pre-filled and saving updates the record instead of inserting a new one.
/// With [searchOnline] the form opens the Open Library search right away and
/// closes again when the search is left without a pick (FR-R2-11).
class AddBookScreen extends StatefulWidget {
  final Book? book;
  final bool searchOnline;
  const AddBookScreen({super.key, this.book, this.searchOnline = false});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _description = TextEditingController();
  final _authors = TextEditingController();
  final _isbn = TextEditingController();
  String? _coverUrl;
  String? _coverLocalPath;
  String? _olid;
  final _publisher = TextEditingController();
  final _year = TextEditingController();
  final _pages = TextEditingController();
  final _language = TextEditingController();
  final _genre = TextEditingController();
  final _price = TextEditingController();
  DateTime? _receivedAt;
  ReceivedAs? _receivedAs;
  bool _priceInvalid = false;
  BookFormat _format = BookFormat.paperback;
  BookStatus _status = BookStatus.unread;
  double _rating = 0.0;
  int? _locationId;
  bool _loading = false;

  bool get _isEditing => widget.book != null;

  /// Reading start and end as the detail page shows them (from the sessions),
  /// and what the form started with, to save only real changes (FR-R2-22).
  ReadingRepository? _reading;
  DateTime? _readStart, _readEnd, _initialStart, _initialEnd;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    if (book != null) {
      _title.text = book.title;
      _subtitle.text = book.subtitle ?? '';
      _description.text = book.description ?? '';
      _coverUrl = book.coverUrl;
      _coverLocalPath = book.coverLocalPath;
      _olid = book.olid;
      _authors.text = book.authors.join(', ');
      _isbn.text = book.isbn13 ?? book.isbn10 ?? '';
      _publisher.text = book.publisher ?? '';
      _year.text = book.publishedYear?.toString() ?? '';
      _pages.text = book.pageCount?.toString() ?? '';
      _language.text = book.language ?? '';
      _genre.text = book.genre ?? '';
      _price.text = priceInputText(book.priceCents);
      _receivedAt = book.receivedAt;
      _receivedAs = book.receivedAs;
      _format = book.format ?? BookFormat.paperback;
      _status = book.status;
      _rating = book.rating;
      _locationId = book.locationId;
    } else {
      // New book: start from the defaults chosen in the settings.
      final defaults = _settings;
      if (defaults != null) {
        _format = defaults.defaultFormat;
        _status = defaults.defaultStatus;
      }
    }
    _reading = _readingRepository;
    if (widget.book case final book?) _loadReadingDates(book.id);
    if (widget.searchOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final picked = await _searchOpenLibrary();
        if (!picked && mounted) Navigator.of(context).pop();
      });
    }
  }

  ReadingRepository? get _readingRepository {
    try {
      return context.read<ReadingRepository>();
    } catch (_) {
      return null; // not provided (isolated widget tests)
    }
  }

  Future<void> _loadReadingDates(int bookId) async {
    final sessions = await _reading?.watchSessions(bookId).first;
    if (sessions == null || !mounted) return;
    final summary = ReadingSummary.compute(sessions);
    setState(() {
      _readStart = _initialStart = summary.startedAt;
      _readEnd = _initialEnd = summary.finishedAt;
    });
  }

  SettingsState? get _settings {
    try {
      return context.read<SettingsCubit>().state;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _subtitle,
      _description,
      _authors,
      _isbn,
      _publisher,
      _year,
      _pages,
      _language,
      _genre,
      _price,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _lookup() async {
    final l10n = AppLocalizations.of(context);
    final isbn13 = normalizeIsbn(_isbn.text);
    if (isbn13 == null) {
      _showSnack(l10n.invalidIsbn);
      return;
    }

    setState(() => _loading = true);
    await context.read<MetadataCubit>().lookup(BookMetadata(isbn13: isbn13));
    if (!mounted) return;
    setState(() => _loading = false);

    final state = context.read<MetadataCubit>().state;
    if (state is MetadataLoaded) {
      final m = state.result.metadata;
      if (m.title == null || m.title!.isEmpty) {
        _showSnack(l10n.noMetadataFound);
        return;
      }
      setState(() {
        _title.text = m.title ?? _title.text;
        _subtitle.text = m.subtitle ?? _subtitle.text;
        _authors.text = m.authors.join(', ');
        _publisher.text = m.publisher ?? _publisher.text;
        _year.text = m.publishedYear?.toString() ?? _year.text;
        _pages.text = m.pageCount?.toString() ?? _pages.text;
        _language.text = m.language ?? _language.text;
        _description.text = m.description ?? _description.text;
        // The DNB fallback URL is only a guess for books no source has a cover
        // for; it must not replace a cover the user already has.
        final guess = m.coverUrl == dnbCoverUrl(isbn13);
        final hasCover = _coverLocalPath != null || _coverUrl != null;
        if (m.coverUrl != null &&
            m.coverUrl != _coverUrl &&
            !(guess && hasCover)) {
          _coverUrl = m.coverUrl;
          // A freshly looked-up cover replaces an older cached/manual file.
          _coverLocalPath = null;
        }
      });
    } else if (state is MetadataError) {
      _showSnack(state.message);
    } else {
      _showSnack(l10n.noMetadataFound);
    }
  }

  CoverPicker? get _picker {
    try {
      return RepositoryProvider.of<CoverPicker>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  CoverCacheService? get _coverCache {
    try {
      return RepositoryProvider.of<CoverCacheService>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickCover(CoverPickSource source) async {
    final picker = _picker;
    final cache = _coverCache;
    if (picker == null || cache == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).coverPickFailed;
    final String path;
    try {
      final bytes = await picker.pick(source);
      if (bytes == null || !mounted) return;
      path = await cache.saveCover(
        'manual-${DateTime.now().microsecondsSinceEpoch}',
        bytes,
      );
    } catch (_) {
      // E.g. camera or photo access denied, or storage full: keep the form as
      // it is.
      messenger.showSnackBar(SnackBar(content: Text(failed)));
      return;
    }
    if (!mounted) return;
    setState(() => _coverLocalPath = path);
  }

  /// Lets the user pick one of the covers found online (FR-R2-13) and caches
  /// it, so the library stays browsable offline (Constitution III.3).
  Future<void> _searchCover() async {
    final cache = _coverCache;
    if (cache == null) return;
    final book = widget.book;
    final library = context.read<LibraryCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).coverPickFailed;
    final authors = _parseAuthors();
    final isbn = normalizeIsbn(_isbn.text);
    final url = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CoverSearchScreen(
          isbn: isbn,
          coverUrl: _coverUrl,
          query: [
            _title.text.trim(),
            if (authors.isNotEmpty) authors.first,
          ].join(' '),
          onNothingFound: book == null
              ? null
              : () => library.setCoverNotFound(book.id),
        ),
      ),
    );
    if (url == null || !mounted) return;
    // A fresh key: the stored cover stays untouched until the form is saved
    // (cancelling keeps it), and a new path is not served from the image
    // cache.
    final path = await cache.downloadAndCache(
      'online-${DateTime.now().microsecondsSinceEpoch}',
      url,
    );
    if (!mounted) return;
    if (path == null) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
      return;
    }
    setState(() {
      _coverUrl = url;
      _coverLocalPath = path;
    });
  }

  void _removeCover() => setState(() {
    _coverLocalPath = null;
    _coverUrl = null;
  });

  Widget _coverSection(AppLocalizations l10n) {
    final cache = _coverCache;
    final local = _coverLocalPath;
    final hasLocal = local != null && (cache?.exists(local) ?? false);
    final hasCover = hasLocal || _coverUrl != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            height: 130,
            child: hasLocal
                ? CoverImage(path: local, iconSize: 32)
                : _coverUrl != null
                ? UrlCover(
                    cacheKey: widget.book == null
                        ? (normalizeIsbn(_isbn.text) ?? 'draft')
                        : BookCover.keyFor(widget.book!),
                    url: _coverUrl,
                  )
                : const CoverPlaceholder(iconSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (_picker != null) ...[
                  OutlinedButton.icon(
                    key: const ValueKey('cover-gallery'),
                    onPressed: () => _pickCover(CoverPickSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.coverFromGallery),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('cover-camera'),
                    onPressed: () => _pickCover(CoverPickSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.coverFromCamera),
                  ),
                ],
                if (cache != null)
                  OutlinedButton.icon(
                    key: const ValueKey('cover-online'),
                    onPressed: _searchCover,
                    icon: const Icon(Icons.image_search_outlined),
                    label: Text(l10n.coverSearchOnline),
                  ),
                if (hasCover)
                  TextButton.icon(
                    key: const ValueKey('cover-remove'),
                    onPressed: _removeCover,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.coverRemove),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fills the form from an Open Library result or edition; returns whether
  /// one was picked. A new book takes the pick as it is; a saved book only
  /// gets its empty fields filled (FR-R2-23), so nothing the user entered is
  /// overwritten (Constitution III.2).
  Future<bool> _searchOpenLibrary() async {
    final authors = _parseAuthors();
    final pick = await Navigator.of(context).push<OlPick>(
      MaterialPageRoute(
        builder: (_) => OpenLibrarySearchScreen(
          initialQuery: [
            _title.text.trim(),
            if (authors.isNotEmpty) authors.first,
          ].join(' '),
        ),
      ),
    );
    if (pick == null || !mounted) return false;
    final m = pick.metadata;
    final fill = _isEditing;
    void take(TextEditingController field, String? value) {
      if (value != null && !(fill && field.text.trim().isNotEmpty)) {
        field.text = value;
      }
    }

    setState(() {
      take(_title, m.title);
      take(_subtitle, m.subtitle);
      if (m.authors.isNotEmpty) take(_authors, m.authors.join(', '));
      take(_publisher, m.publisher);
      take(_year, m.publishedYear?.toString());
      take(_pages, m.pageCount?.toString());
      take(_language, m.language);
      take(_isbn, m.isbn13 ?? m.isbn10);
      _olid = fill ? _olid ?? pick.olid : pick.olid ?? _olid;
      final hasCover = _coverUrl != null || _coverLocalPath != null;
      if (m.coverUrl != null &&
          m.coverUrl != _coverUrl &&
          !(fill && hasCover)) {
        _coverUrl = m.coverUrl;
        _coverLocalPath = null;
      }
    });
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _parseAuthors() => _authors.text
      .split(',')
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .toList();

  Future<void> _pickReceivedAt() async {
    final picked = await _pickDate(_receivedAt);
    if (picked != null && mounted) setState(() => _receivedAt = picked);
  }

  Future<DateTime?> _pickDate(DateTime? value) {
    final now = DateTime.now();
    final first = DateTime(1900);
    final last = DateTime(now.year + 1);
    final current = value ?? now;
    return showDatePicker(
      context: context,
      // An imported date outside the range would trip the picker's assert.
      initialDate: current.isBefore(first)
          ? first
          : current.isAfter(last)
          ? last
          : current,
      firstDate: first,
      lastDate: last,
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) =>
      a == null || b == null ? a == b : DateUtils.isSameDay(a, b);

  Future<void> _save() async {
    final priceText = _price.text.trim();
    final priceCents = parsePriceCents(priceText);
    if (priceText.isNotEmpty && priceCents == null) {
      setState(() => _priceInvalid = true);
      return;
    }
    final isbn13 = normalizeIsbn(_isbn.text);
    final isbn10 = isbn13 != null ? null : cleanIsbn(_isbn.text);
    final draft = BookDraft(
      title: _title.text.trim(),
      subtitle: _subtitle.text.isEmpty ? null : _subtitle.text,
      authors: _parseAuthors(),
      isbn13: isbn13,
      isbn10: isbn10,
      publisher: _publisher.text.isEmpty ? null : _publisher.text,
      publishedYear: int.tryParse(_year.text),
      pageCount: int.tryParse(_pages.text),
      language: _language.text.isEmpty ? null : _language.text,
      format: _format,
      status: _status,
      rating: normalizeRating(_rating),
      metadataSource: _isEditing
          ? widget.book!.metadataSource
          : MetadataSource.manual,
      locationId: _locationId,
      coverUrl: _coverUrl,
      coverLocalPath: _coverLocalPath,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      olid: _olid,
      seriesId: widget.book?.seriesId,
      seriesVolume: widget.book?.seriesVolume,
      // Not shown in the form: carry it over so editing never drops it.
      readingSeconds: widget.book?.readingSeconds,
      genre: _genre.text.trim().isEmpty ? null : _genre.text.trim(),
      priceCents: priceCents,
      receivedAt: _receivedAt,
      receivedAs: _receivedAs,
      editedFields: _isEditing ? _editedFields() : const {},
    );

    final cubit = context.read<LibraryCubit>();
    try {
      final int id;
      if (_isEditing) {
        id = widget.book!.id;
        await cubit.updateBook(id, draft);
      } else {
        id = await cubit.addBook(draft);
        final defaultTags = _settings?.defaultTagIds ?? const <int>{};
        if (defaultTags.isNotEmpty && mounted) {
          await context.read<TagRepository>().setBookTags(id, defaultTags);
        }
      }
      // After the book: a new end date must win over the finish date a
      // status change to "read" sets.
      final start = _sameDay(_readStart, _initialStart) ? null : _readStart;
      final end = _sameDay(_readEnd, _initialEnd) ? null : _readEnd;
      if (start != null || end != null) {
        await _reading?.setReadingDates(id, start: start, end: end);
      }
    } catch (e) {
      // Stay on the form so nothing typed is lost, and say why.
      if (mounted) {
        _showSnack(AppLocalizations.of(context).saveFailed(e.toString()));
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// Fields the user changed vs. the original record (drives the verification
  /// badge: a hand-edited DNB book becomes "bearbeitet").
  Set<String> _editedFields() {
    final b = widget.book!;
    final changed = <String>{};

    if (_title.text.trim() != b.title) changed.add('title');
    final subtitle = _subtitle.text.isEmpty ? null : _subtitle.text;
    if (subtitle != b.subtitle) changed.add('subtitle');
    if (!listEquals(_parseAuthors(), b.authors)) changed.add('authors');
    if (_publisher.text.isEmpty
        ? b.publisher != null
        : _publisher.text != b.publisher) {
      changed.add('publisher');
    }
    if (int.tryParse(_year.text) != b.publishedYear) {
      changed.add('publishedYear');
    }
    if (int.tryParse(_pages.text) != b.pageCount) changed.add('pageCount');
    final language = _language.text.isEmpty ? null : _language.text;
    if (language != b.language) changed.add('language');
    if (_format != (b.format ?? BookFormat.paperback)) changed.add('format');
    final isbn13 = normalizeIsbn(_isbn.text);
    if (isbn13 != b.isbn13) changed.add('isbn13');
    if (_coverUrl != b.coverUrl) changed.add('coverUrl');

    return changed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editBookTitle : l10n.addBookTitle),
        actions: [
          IconButton(
            key: const ValueKey('open-library-search'),
            icon: const Icon(Icons.travel_explore),
            tooltip: l10n.openLibrarySearch,
            onPressed: _searchOpenLibrary,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _coverSection(l10n),
          _field(_title, l10n.fieldTitle),
          _field(_subtitle, l10n.fieldSubtitle),
          _field(_authors, l10n.fieldAuthors),
          Row(
            children: [
              Expanded(child: _field(_isbn, l10n.fieldIsbn)),
              IconButton(
                onPressed: _loading ? null : _lookup,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                tooltip: l10n.lookupMetadataTooltip,
              ),
            ],
          ),
          _field(_publisher, l10n.fieldPublisher),
          _field(_year, l10n.fieldYear),
          _field(_pages, l10n.fieldPages),
          _field(_language, l10n.fieldLanguage),
          _field(_genre, l10n.fieldGenre),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                if (_priceInvalid) setState(() => _priceInvalid = false);
              },
              decoration: InputDecoration(
                labelText: l10n.fieldPrice,
                suffixText: '€',
                errorText: _priceInvalid ? l10n.invalidPrice : null,
              ),
            ),
          ),
          _receivedAtField(l10n),
          _dropdown<ReceivedAs?>(
            key: const ValueKey('received-as'),
            label: l10n.fieldReceivedAs,
            value: _receivedAs,
            items: const [null, ...ReceivedAs.values],
            labelOf: (r) =>
                r == null ? l10n.receivedAsUnknown : receivedAsLabel(l10n, r),
            onChanged: (v) => setState(() => _receivedAs = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              controller: _description,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(labelText: l10n.fieldDescription),
            ),
          ),
          const SizedBox(height: 8),
          _dropdown<BookFormat>(
            label: l10n.fieldFormat,
            value: _format,
            items: BookFormat.values,
            labelOf: (f) => formatLabel(l10n, f),
            onChanged: (v) => setState(() => _format = v),
          ),
          _dropdown<BookStatus>(
            label: l10n.fieldStatus,
            value: _status,
            items: BookStatus.values,
            labelOf: (s) => statusLabel(l10n, s),
            onChanged: (v) => setState(() => _status = v),
          ),
          if (_reading != null) ...[
            _dateField(
              key: 'reading-start-field',
              label: l10n.readingStartedLabel,
              value: _readStart,
              onPick: (d) => _readStart = d,
            ),
            _dateField(
              key: 'reading-end-field',
              label: l10n.readingFinishedLabel,
              value: _readEnd,
              onPick: (d) => _readEnd = d,
            ),
          ],
          _locationDropdown(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.ratingLabel),
                RatingControl(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
    );
  }

  Widget _receivedAtField(AppLocalizations l10n) {
    final date = _receivedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        key: const ValueKey('received-at-field'),
        onTap: _pickReceivedAt,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.fieldReceivedAt,
            suffixIcon: date == null
                ? const Icon(Icons.calendar_today_outlined)
                : IconButton(
                    key: const ValueKey('received-at-clear'),
                    icon: const Icon(Icons.clear),
                    tooltip: l10n.clearDate,
                    onPressed: () => setState(() => _receivedAt = null),
                  ),
          ),
          child: Text(
            date == null
                ? ''
                : MaterialLocalizations.of(context).formatMediumDate(date),
          ),
        ),
      ),
    );
  }

  /// A date that is set, not cleared: the reading dates come from sessions,
  /// which the form moves but never deletes.
  Widget _dateField({
    required String key,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: InkWell(
      key: ValueKey(key),
      onTap: () async {
        final picked = await _pickDate(value);
        if (picked != null && mounted) setState(() => onPick(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value == null
              ? ''
              : MaterialLocalizations.of(context).formatMediumDate(value),
        ),
      ),
    ),
  );

  Widget _locationDropdown() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<List<Location>>(
        future: context.read<LocationRepository>().getLocations(),
        builder: (context, snapshot) {
          final locations = snapshot.data ?? const <Location>[];
          return InputDecorator(
            decoration: InputDecoration(labelText: l10n.fieldLocation),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _locationId,
                isExpanded: true,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.noLocation),
                  ),
                  for (final location in locations)
                    DropdownMenuItem<int?>(
                      value: location.id,
                      child: Text(location.name),
                    ),
                ],
                onChanged: (v) => setState(() => _locationId = v),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dropdown<T>({
    Key? key,
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
    String Function(T)? labelOf,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item,
                  child: Text(
                    labelOf?.call(item) ?? item.toString().split('.').last,
                  ),
                ),
            ],
            // For a nullable T, `null` is a real choice ("unknown").
            onChanged: (v) => onChanged(v as T),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
