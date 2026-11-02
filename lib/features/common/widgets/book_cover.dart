import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openreads/core/helpers/maybe_read.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/database/app_database.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Neutral stand-in shown while a cover loads or when a book has none.
///
/// Two states are told apart at a glance (P1): a plain grey book (not
/// searched yet) and the same with an amber banner (every online source said
/// "no cover": add one by hand).
class CoverPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double iconSize;

  /// Every source was asked and none has a cover (FR-R2-14); otherwise the
  /// book was not looked up yet.
  final bool notFound;

  const CoverPlaceholder({
    super.key,
    this.width,
    this.height,
    this.iconSize = 24,
    this.notFound = false,
  });

  /// Below this width the banner shows only its icon: text would be noise.
  static const _minBannerTextWidth = 90.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Optional so widgets still render in tests without the app's delegates.
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    // A plain grey book: a darker spine on the left, the icon on the cover.
    return Container(
      key: const ValueKey('cover-placeholder'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(color: scheme.outlineVariant, width: iconSize / 4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final withText = l10n != null && box.maxWidth >= _minBannerTextWidth;
          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: notFound ? iconSize : 0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Icon(
                      notFound
                          ? Icons.hide_image_outlined
                          : Icons.menu_book_outlined,
                      size: iconSize,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (notFound)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Semantics(
                    label: l10n?.coverMissingBanner,
                    excludeSemantics: true,
                    child: Container(
                      key: const ValueKey('cover-missing-banner'),
                      color: scheme.tertiaryContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 14,
                            color: scheme.onTertiaryContainer,
                          ),
                          if (withText) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                box.maxWidth >= 130
                                    ? l10n.coverMissingBanner
                                    : l10n.coverMissingShort,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Shows a file from the cover cache, or the placeholder when it is missing or
/// cannot be decoded.
class CoverImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;
  final bool notFound;
  const CoverImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 24,
    this.notFound = false,
  });

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    final placeholder = CoverPlaceholder(
      width: width,
      height: height,
      iconSize: iconSize,
      notFound: notFound,
    );
    if (path == null) return placeholder;
    return Image.file(
      File(path),
      key: ValueKey('cover-image:$path'),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// The cover service is optional: widgets still render (with placeholders) when
/// no [CoverCacheService] is provided, e.g. in tests.
CoverCacheService? _maybeCoverCache(BuildContext context) =>
    context.maybeRead<CoverCacheService>();

/// Downloads that already failed in this session are not retried on every
/// rebuild/scroll.
final _failedKeys = <String>{};

/// The cover of a [Book]: a manually chosen/cached local file, else the remote
/// `coverUrl` downloaded once into the cache (and remembered on the book),
/// else a placeholder.
class BookCover extends StatefulWidget {
  final Book book;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;
  final BorderRadius? borderRadius;

  const BookCover({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 24,
    this.borderRadius,
  });

  /// Cache key of a book: its ISBN-13 when it has one (shared with the scanner
  /// staging shelf), else its id.
  static String keyFor(Book book) => book.isbn13 ?? 'book-${book.id}';

  @override
  State<BookCover> createState() => _BookCoverState();
}

class _BookCoverState extends State<BookCover> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(BookCover old) {
    super.didUpdateWidget(old);
    if (old.book.id != widget.book.id ||
        old.book.coverUrl != widget.book.coverUrl ||
        old.book.coverLocalPath != widget.book.coverLocalPath) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final book = widget.book;
    final cache = _maybeCoverCache(context);
    final repository = _maybeBookRepository(context);

    final local = book.coverLocalPath;
    if (local != null && (cache?.exists(local) ?? File(local).existsSync())) {
      if (mounted) setState(() => _path = local);
      return;
    }
    if (mounted && _path != null) setState(() => _path = null);
    if (cache == null) return;

    final key = BookCover.keyFor(book);
    var path = cache.cachedPath(key);
    // Known to have no cover online: only the explicit online search asks.
    if (path == null && !book.coverNotFound && !_failedKeys.contains(key)) {
      // Merely showing a book asks one source: its stored URL, or Open Library
      // for imported books without one. The wider fallback (DNB, ...) runs in
      // the explicit "download missing covers" action (Constitution I.2).
      final isbn = book.isbn13;
      final stored = (book.coverUrl ?? '').trim();
      final candidates = [
        if (stored.isNotEmpty) stored,
        // Without a stored URL, or with only the DNB guess (see the
        // aggregator), Open Library is the one other place to look.
        if (isbn != null && (stored.isEmpty || stored == dnbCoverUrl(isbn)))
          openLibraryCoverUrl(isbn),
      ];
      path = await cache.resolveAny(key, candidates);
      if (path == null && candidates.isNotEmpty) _failedKeys.add(key);
    }
    if (path == null || !mounted) return;
    setState(() => _path = path);
    if (book.coverLocalPath != path) {
      await repository?.setCoverLocalPath(book.id, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = CoverImage(
      path: _path,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      iconSize: widget.iconSize,
      notFound: widget.book.coverNotFound,
    );
    final radius = widget.borderRadius;
    return Semantics(
      label: widget.book.title,
      image: true,
      child: radius == null
          ? image
          : ClipRRect(borderRadius: radius, child: image),
    );
  }
}

BookRepository? _maybeBookRepository(BuildContext context) =>
    context.maybeRead<BookRepository>();

/// A cover that is not (yet) a stored book, e.g. in the scanner staging shelf:
/// cached under the ISBN so saving the book later reuses the same file.
class UrlCover extends StatefulWidget {
  final String cacheKey;
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const UrlCover({
    super.key,
    required this.cacheKey,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<UrlCover> createState() => _UrlCoverState();
}

class _UrlCoverState extends State<UrlCover> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(UrlCover old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.cacheKey != widget.cacheKey) _resolve();
  }

  Future<void> _resolve() async {
    final cache = _maybeCoverCache(context);
    if (cache == null) return;
    final path = await cache.resolve(widget.cacheKey, widget.url);
    if (mounted && path != _path) setState(() => _path = path);
  }

  @override
  Widget build(BuildContext context) {
    final image = CoverImage(
      path: _path,
      width: widget.width,
      height: widget.height,
    );
    final radius = widget.borderRadius;
    return radius == null
        ? image
        : ClipRRect(borderRadius: radius, child: image);
  }
}
