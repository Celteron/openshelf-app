import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/helpers/price.dart';
import 'package:openreads/core/helpers/rating.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/cover/cover_picker.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/models/enums.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/features/lending/lending_cubit.dart';
import 'package:openreads/domain/models/reading_stats.dart';
import 'package:openreads/domain/models/shelf_partition.dart';
import 'package:openreads/domain/repositories/notes_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/domain/repositories/tag_repository.dart';
import 'package:openreads/features/common/format_count.dart';
import 'package:openreads/features/common/status_label.dart';
import 'package:openreads/domain/models/app_preferences.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/features/library/add_book_screen.dart';
import 'package:openreads/features/library/cover_search_screen.dart';
import 'package:openreads/features/library/similar_books_screen.dart';
import 'package:openreads/features/library/split_volumes_screen.dart';
import 'package:openreads/features/library/widgets/rating_display.dart';
import 'package:openreads/features/settings/settings_cubit.dart';
import 'package:openreads/features/notes/notes_screen.dart';
import 'package:openreads/features/reading/reading_screen.dart';
import 'package:openreads/features/tags/tags_screen.dart';
import 'package:openreads/features/library/library_cubit.dart';
import 'package:openreads/features/library/widgets/verification_badge.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Book details: bibliographic data, rating/status editing, DNB verification
/// badge, and lending actions (spec §6.3).
class BookDetailScreen extends StatefulWidget {
  final int bookId;

  /// Called after the book was deleted. When `null` the screen pops itself,
  /// which is right for a pushed route; the embedded master-detail pane
  /// passes a callback instead so the library list stays on screen.
  final VoidCallback? onDeleted;

  const BookDetailScreen({super.key, required this.bookId, this.onDeleted});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;

  /// The volumes when this book is a slipcase, its slipcase when it is a
  /// volume (ADR-0003).
  List<Book> _volumes = const [];
  bool _hasVolumes = false;
  Book? _slipcase;
  late final Stream<List<ReadingSession>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = context.read<ReadingRepository>().watchSessions(widget.bookId);
    _load();
    context.read<LendingCubit>().watch(widget.bookId);
  }

  Future<void> _load() async {
    final repository = context.read<BookRepository>();
    final book = await repository.getBook(widget.bookId);
    final parentId = book?.parentId;
    // Trashed volumes still make a slipcase: it cannot be split again.
    final allVolumes = book == null || parentId != null
        ? const <Book>[]
        : await repository.getVolumes(book.id, includeTrashed: true);
    final slipcase = parentId == null
        ? null
        : await repository.getBook(parentId);
    if (!mounted) return;
    setState(() {
      _book = book;
      _volumes = [
        for (final v in allVolumes)
          if (v.deletedAt == null) v,
      ];
      _hasVolumes = allVolumes.isNotEmpty;
      _slipcase = slipcase;
    });
  }

  Future<void> _openBook(int id) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id)));
    await _load();
  }

  Future<void> _split(Book book) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SplitVolumesScreen(book: book)),
    );
    if (done == true) await _load();
  }

  Future<void> _openEdit(
    BuildContext context,
    Book book, {
    bool searchOnline = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddBookScreen(book: book, searchOnline: searchOnline),
      ),
    );
    await _load();
  }

  T? _optional<T>() {
    try {
      return RepositoryProvider.of<T>(context, listen: false);
    } catch (_) {
      return null; // e.g. no camera on desktop, or isolated widget tests
    }
  }

  /// Gives a book without cover one from the camera, the gallery or an
  /// online search, without opening the form (FR-R2-14).
  Future<void> _addCover(Book book, {CoverPickSource? source}) async {
    final cache = _optional<CoverCacheService>();
    if (cache == null) return;
    final repository = context.read<BookRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).coverPickFailed;
    final key = BookCover.keyFor(book);
    String? path;
    try {
      if (source != null) {
        final bytes = await _optional<CoverPicker>()?.pick(source);
        if (bytes == null) return;
        path = await cache.saveCover(key, bytes);
      } else {
        final url = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => CoverSearchScreen(
              isbn: book.isbn13,
              coverUrl: book.coverUrl,
              query: [book.title, ...book.authors.take(1)].join(' '),
              onNothingFound: () => repository.setCoverNotFound(book.id),
            ),
          ),
        );
        if (url == null) return;
        path = await cache.downloadAndCache(key, url);
      }
    } catch (_) {
      path = null; // camera or photo access denied, storage full
    }
    if (path == null) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
      return;
    }
    await repository.setCoverLocalPath(book.id, path);
    if (mounted) await _load();
  }

  Future<void> _toggleFavorite(Book book) async {
    await context.read<LibraryCubit>().setFavorite(book.id, !book.isFavorite);
    await _load();
  }

  Future<void> _confirmDelete(Book book) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteBookTitle(book.title)),
        content: Text(l10n.deleteBookBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(l10n.moveToTrash),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final cubit = context.read<LibraryCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await cubit.deleteBook(book.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.bookDeleted),
        // A SnackBar with an action would otherwise stay until dismissed.
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => cubit.restoreBook(book.id),
        ),
      ),
    );
    if (widget.onDeleted != null) {
      widget.onDeleted!();
    } else {
      navigator.pop();
    }
  }

  /// The preferred rating style. With [watch] the screen rebuilds when the
  /// setting changes; without a settings cubit the star bar is used.
  RatingDisplay _ratingDisplay(BuildContext context, {bool watch = false}) {
    try {
      final settings = watch
          ? context.watch<SettingsCubit>()
          : context.read<SettingsCubit>();
      return settings.state.ratingDisplay;
    } catch (_) {
      return RatingDisplay.bar;
    }
  }

  Future<void> _quickRate(Book book) async {
    final rating = await showDialog<double>(
      context: context,
      builder: (_) => _QuickRatingDialog(display: _ratingDisplay(context)),
    );
    if (rating == null || rating <= 0 || !mounted) return;
    await context.read<LibraryCubit>().setRating(
      book.id,
      normalizeRating(rating),
    );
    await _load();
  }

  Future<void> _editReview(Book book) async {
    final review = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewDialog(initial: book.review),
    );
    if (review == null || !mounted) return;
    await context.read<LibraryCubit>().setReview(book.id, review);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    if (book == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            key: const ValueKey('favorite-toggle'),
            onPressed: () => _toggleFavorite(book),
            icon: Icon(
              book.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: book.isFavorite
                  ? Theme.of(context).colorScheme.tertiary
                  : null,
            ),
            tooltip: book.isFavorite ? l10n.removeFavorite : l10n.addFavorite,
          ),
          IconButton(
            onPressed: () => _openEdit(context, book),
            icon: const Icon(Icons.edit),
            tooltip: l10n.editBookTitle,
          ),
          IconButton(
            key: const ValueKey('delete-book'),
            onPressed: () => _confirmDelete(book),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteBook,
          ),
          // Only a single book can become a slipcase (one level deep).
          if (book.parentId == null && !_hasVolumes)
            PopupMenuButton<void>(
              key: const ValueKey('book-menu'),
              tooltip: l10n.moreActions,
              itemBuilder: (_) => [
                PopupMenuItem(
                  key: const ValueKey('split-volumes'),
                  onTap: () => _split(book),
                  child: Text(l10n.splitVolumesAction),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: BookCover(
              book: book,
              width: 140,
              height: 200,
              iconSize: 48,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Always one slot, so adding a cover does not shift the list's
          // children (which would resubscribe the session stream below).
          if (book.coverLocalPath != null ||
              _optional<CoverCacheService>() == null)
            const SizedBox.shrink()
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (_optional<CoverPicker>() != null) ...[
                    IconButton.outlined(
                      key: const ValueKey('detail-cover-camera'),
                      tooltip: l10n.coverFromCamera,
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: () =>
                          _addCover(book, source: CoverPickSource.camera),
                    ),
                    IconButton.outlined(
                      key: const ValueKey('detail-cover-gallery'),
                      tooltip: l10n.coverFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: () =>
                          _addCover(book, source: CoverPickSource.gallery),
                    ),
                  ],
                  IconButton.outlined(
                    key: const ValueKey('detail-cover-online'),
                    tooltip: l10n.coverSearchTitle,
                    icon: const Icon(Icons.image_search_outlined),
                    onPressed: () => _addCover(book),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Center(child: VerificationBadge(book: book)),
          const SizedBox(height: 8),
          if (book.subtitle != null)
            Text(
              book.subtitle!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final author in book.authors)
                ActionChip(
                  key: ValueKey('author-chip:$author'),
                  avatar: const Icon(Icons.person_outline, size: 16),
                  label: Text(author),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SimilarBooksScreen.byAuthor(author),
                    ),
                  ),
                ),
            ],
          ),
          if (_slipcase case final slipcase?)
            ListTile(
              key: const ValueKey('slipcase-link'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(l10n.partOfSlipcase(slipcase.title)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openBook(slipcase.id),
            ),
          // Without an ISBN no lookup finds a cover or details (FR-R2-23).
          if (book.isbn13 == null && book.isbn10 == null)
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: ListTile(
                key: const ValueKey('complete-online'),
                leading: const Icon(Icons.travel_explore),
                title: Text(l10n.completeOnline),
                subtitle: Text(l10n.completeOnlineHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openEdit(context, book, searchOnline: true),
              ),
            ),
          const SizedBox(height: 16),
          StreamBuilder<List<ReadingSession>>(
            stream: _sessions,
            builder: (context, snapshot) => _MetadataTable(
              book: book,
              reading: ReadingSummary.compute(
                snapshot.data ?? const <ReadingSession>[],
                manualSeconds: book.readingSeconds ?? 0,
              ),
            ),
          ),
          if (book.description != null && book.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.fieldDescription,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(book.description!, key: const ValueKey('book-description')),
          ],
          if (_volumes.isNotEmpty) ...[
            const SizedBox(height: 24),
            _VolumesSection(volumes: _volumes, onOpen: _openBook),
          ] else ...[
            const SizedBox(height: 24),
            Text(
              l10n.ratingLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            RatingEditor(
              value: book.rating,
              display: _ratingDisplay(context, watch: true),
              // Tapping the star that is already selected clears the rating.
              onChanged: (v) async {
                await context.read<LibraryCubit>().setRating(
                  book.id,
                  normalizeRating(v == book.rating ? 0 : v),
                );
                await _load();
              },
            ),
            const SizedBox(height: 8),
            _ReviewTile(review: book.review, onEdit: () => _editReview(book)),
            const SizedBox(height: 24),
            Text(
              l10n.statusLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            DropdownButton<BookStatus>(
              value: book.status,
              items: [
                for (final s in BookStatus.values)
                  DropdownMenuItem(value: s, child: Text(statusLabel(l10n, s))),
              ],
              onChanged: (s) async {
                if (s == null) return;
                await context.read<LibraryCubit>().setStatus(book.id, s);
                await _load();
                // Finishing an unrated book offers a quick rating (legacy).
                if (s == BookStatus.read &&
                    book.status != BookStatus.read &&
                    book.rating == 0 &&
                    mounted) {
                  await _quickRate(book);
                }
              },
            ),
            if (book.status == BookStatus.wishlist) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  await context.read<LibraryCubit>().moveToLibrary(book.id);
                  await _load();
                },
                icon: const Icon(Icons.library_add),
                label: Text(l10n.moveToLibrary),
              ),
            ],
            const SizedBox(height: 24),
            _ReadingTile(book: book, onReturn: _load),
          ],
          const SizedBox(height: 8),
          _TagsSection(bookId: book.id),
          const SizedBox(height: 8),
          _NotesTile(bookId: book.id),
          const SizedBox(height: 24),
          _LendingSection(bookId: book.id),
          _LendingHistory(bookId: book.id),
        ],
      ),
    );
  }
}

/// The volumes of a slipcase with its derived status; status, rating and
/// reading data live on the volumes (ADR-0003).
class _VolumesSection extends StatelessWidget {
  final List<Book> volumes;
  final ValueChanged<int> onOpen;

  const _VolumesSection({required this.volumes, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final read = volumes.where((v) => v.status == BookStatus.read).length;
    return Column(
      key: const ValueKey('volumes-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.volumesTitle} (${volumes.length})',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text(
                statusLabel(l10n, slipcaseStatus(volumes.map((v) => v.status))),
              ),
            ),
            Chip(label: Text(l10n.volumesReadProgress(read, volumes.length))),
          ],
        ),
        for (final volume in volumes)
          ListTile(
            key: ValueKey('volume:${volume.id}'),
            contentPadding: EdgeInsets.zero,
            leading: BookCover(book: volume, width: 32, height: 46),
            title: Text(volume.title),
            subtitle: Text(
              [
                statusLabel(l10n, volume.status),
                if (volume.pageCount case final pages?) l10n.pageCount(pages),
              ].join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpen(volume.id),
          ),
      ],
    );
  }
}

/// Rating prompt shown when an unrated book is marked as read.
class _QuickRatingDialog extends StatefulWidget {
  final RatingDisplay display;
  const _QuickRatingDialog({required this.display});

  @override
  State<_QuickRatingDialog> createState() => _QuickRatingDialogState();
}

class _QuickRatingDialogState extends State<_QuickRatingDialog> {
  double _value = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const ValueKey('quick-rating'),
      title: Text(l10n.quickRatingTitle),
      content: RatingEditor(
        value: _value,
        display: widget.display,
        onChanged: (v) => setState(() => _value = v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.skip),
        ),
        FilledButton(
          onPressed: _value <= 0 ? null : () => Navigator.pop(context, _value),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// The reader's own review text with an edit action.
class _ReviewTile extends StatelessWidget {
  final String? review;
  final VoidCallback onEdit;
  const _ReviewTile({required this.review, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = review;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.rate_review_outlined),
        title: Text(l10n.reviewTitle),
        subtitle: Text(text == null || text.isEmpty ? l10n.noReviewYet : text),
        trailing: IconButton(
          key: const ValueKey('edit-review'),
          icon: const Icon(Icons.edit_outlined),
          tooltip: l10n.editReview,
          onPressed: onEdit,
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final String? initial;
  const _ReviewDialog({required this.initial});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editReview),
      content: TextField(
        key: const ValueKey('review-field'),
        controller: _controller,
        autofocus: true,
        minLines: 4,
        maxLines: 10,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(hintText: l10n.reviewHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Entry point to the reading-progress screen with a one-line summary.
class _ReadingTile extends StatelessWidget {
  final Book book;
  final Future<void> Function() onReturn;
  const _ReadingTile({required this.book, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = book.pageCount;
    final hasTotal = total != null && total > 0;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.auto_stories),
        title: Text(l10n.readingTitle),
        subtitle: Text(
          hasTotal
              ? l10n.pageOfTotal(book.currentPage, total)
              : l10n.pageOnly(book.currentPage),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReadingScreen(bookId: book.id)),
          );
          await onReturn();
        },
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  final int bookId;
  const _TagsSection({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<Tag>>(
      stream: context.read<TagRepository>().watchTagsForBook(bookId),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <Tag>[];
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.sell_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: tags.isEmpty
                      ? Text(l10n.noTagsYet)
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final tag in tags)
                              ActionChip(
                                key: ValueKey('tag-chip:${tag.id}'),
                                label: Text(tag.name),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SimilarBooksScreen.byTag(tag),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editTags,
                  onPressed: () => BookTagPickerSheet.show(context, bookId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotesTile extends StatelessWidget {
  final int bookId;
  const _NotesTile({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<BookNote>>(
      stream: context.read<NotesRepository>().watchNotes(bookId),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.format_quote),
            title: Text(l10n.notesTitle),
            subtitle: Text(l10n.notesCount(count)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NotesScreen(bookId: bookId)),
            ),
          ),
        );
      },
    );
  }
}

class _MetadataTable extends StatelessWidget {
  final Book book;
  final ReadingSummary reading;
  const _MetadataTable({required this.book, required this.reading});

  static String _date(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);

  static String _time(AppLocalizations l10n, Duration time) =>
      time <= Duration.zero
      ? ''
      : l10n.readingDuration(time.inHours, time.inMinutes % 60);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final price = book.priceCents;
    final started = reading.startedAt;
    final finished = reading.finishedAt;
    final rows = <(String, String?)>[
      // One ISBN is enough for the reader; both numbers stay in the data.
      (l10n.fieldIsbn, book.isbn13 ?? book.isbn10),
      (l10n.genreLabel, book.genre),
      (l10n.publisherLabel, book.publisher),
      (l10n.yearLabel, book.publishedYear?.toString()),
      (
        l10n.pagesLabel,
        book.pageCount == null ? null : formatCount(context, book.pageCount!),
      ),
      (l10n.languageLabel, book.language),
      (
        l10n.formatLabel,
        book.format == null ? null : formatLabel(l10n, book.format!),
      ),
      (l10n.seriesVolumeLabel, book.seriesVolume?.toString()),
      (l10n.olidLabel, book.olid),
      (l10n.priceLabel, price == null ? null : formatPriceCents(price, locale)),
      (
        l10n.receivedAtLabel,
        book.receivedAt == null ? null : _date(context, book.receivedAt!),
      ),
      (
        l10n.fieldReceivedAs,
        book.receivedAs == null
            ? null
            : receivedAsLabel(l10n, book.receivedAs!),
      ),
      (l10n.dateAddedLabel, _date(context, book.createdAt)),
      (l10n.dateModifiedLabel, _date(context, book.updatedAt)),
      (
        l10n.readingStartedLabel,
        started == null ? null : _date(context, started),
      ),
      (
        l10n.readingFinishedLabel,
        finished == null ? null : _date(context, finished),
      ),
      // The period (when it was read) and the time (how long actually) differ.
      (
        l10n.readingSpanLabel,
        reading.spanDays == null ? null : l10n.daysCount(reading.spanDays!),
      ),
      (l10n.readingTimeLabel, _time(l10n, reading.readingTime)),
    ];
    return Column(
      children: [
        for (final (label, value) in rows)
          if (value != null && value.isNotEmpty)
            _CopyableRow(label: label, value: value),
      ],
    );
  }
}

/// One label/value line whose value can be selected and copied in one tap.
class _CopyableRow extends StatelessWidget {
  final String label;
  final String value;
  const _CopyableRow({required this.label, required this.value});

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).copiedToClipboard;
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: SelectableText(value)),
        IconButton(
          key: ValueKey('copy:$label'),
          icon: const Icon(Icons.copy, size: 18),
          tooltip: l10n.copyValue(label),
          onPressed: () => _copy(context),
        ),
      ],
    );
  }
}

class _LendingSection extends StatelessWidget {
  final int bookId;
  const _LendingSection({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<LendingCubit, LendingState>(
      builder: (context, state) {
        if (state is LendingActive) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.lentTo(state.lending.borrowerName)),
              trailing: TextButton(
                onPressed: () =>
                    context.read<LendingCubit>().markReturned(state.lending.id),
                child: Text(l10n.markReturned),
              ),
            ),
          );
        }
        return _LendForm(bookId: bookId);
      },
    );
  }
}

/// Past lendings of the book (returned ones), collapsed by default.
class _LendingHistory extends StatelessWidget {
  final int bookId;
  const _LendingHistory({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dates = MaterialLocalizations.of(context);
    return StreamBuilder<List<LendingData>>(
      stream: context.read<LendingCubit>().history(bookId),
      builder: (context, snapshot) {
        final returned = [
          for (final l in snapshot.data ?? const <LendingData>[])
            if (l.returnedAt != null) l,
        ];
        if (returned.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          key: const ValueKey('lending-history'),
          tilePadding: EdgeInsets.zero,
          leading: const Icon(Icons.history),
          title: Text(l10n.lendingHistory(returned.length)),
          children: [
            for (final l in returned)
              ListTile(
                dense: true,
                title: Text(l.borrowerName),
                subtitle: Text(
                  '${dates.formatMediumDate(l.lentAt)} – '
                  '${dates.formatMediumDate(l.returnedAt!)}',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LendForm extends StatefulWidget {
  final int bookId;
  const _LendForm({required this.bookId});

  @override
  State<_LendForm> createState() => _LendFormState();
}

class _LendFormState extends State<_LendForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: l10n.borrowerNameHint),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) return;
            context.read<LendingCubit>().lend(
              widget.bookId,
              borrowerName: _controller.text.trim(),
            );
            _controller.clear();
          },
          child: Text(l10n.lend),
        ),
      ],
    );
  }
}
