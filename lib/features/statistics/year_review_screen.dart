import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:openreads/data/export/export_file_saver.dart';
import 'package:openreads/domain/models/year_review.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';
import 'package:openreads/features/common/format_count.dart';
import 'package:openreads/features/common/format_duration.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/features/library/widgets/rating_display.dart';
import 'package:openreads/features/statistics/year_review_cubit.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// The year in swipeable cards. Everything is computed on the device; a card
/// can be saved as an image, which is the only way it leaves the app and is
/// the user's own action.
class YearReviewScreen extends StatelessWidget {
  final int year;
  const YearReviewScreen({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => YearReviewCubit(
        context.read<BookRepository>(),
        context.read<ReadingRepository>(),
        year: year,
      )..load(),
      child: _ReviewView(year: year),
    );
  }
}

class _ReviewView extends StatefulWidget {
  final int year;
  const _ReviewView({required this.year});

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  final _controller = PageController();
  final _keys = <int, GlobalKey>{};
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final saver = context.read<ExportFileSaver>();
    final fileName = 'openshelf-${widget.year}-${_page + 1}.png';
    try {
      final boundary =
          _keys[_page]?.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('card not on screen');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose(); // a screen-sized bitmap: do not wait for the GC
      if (data == null) throw StateError('no image data');
      final saved = await saver.saveBytes(
        fileName,
        data.buffer.asUint8List(),
        mimeType: 'image/png',
      );
      if (saved != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.reviewSaved(fileName))),
        );
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reviewSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<YearReviewCubit, YearReviewState>(
      builder: (context, state) {
        final review = state is YearReviewLoaded ? state.review : null;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.reviewOpen(widget.year)),
            actions: [
              if (review != null && !review.isEmpty)
                IconButton(
                  key: const ValueKey('review-save'),
                  icon: const Icon(Icons.download),
                  tooltip: l10n.reviewSave,
                  onPressed: () => _save(l10n),
                ),
            ],
          ),
          body: switch (state) {
            YearReviewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            YearReviewError() => Center(child: Text(l10n.errorLoadingLibrary)),
            YearReviewLoaded(:final review) when review.isEmpty => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.reviewEmpty(widget.year),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            YearReviewLoaded(:final review) => _pages(context, l10n, review),
          },
        );
      },
    );
  }

  Widget _pages(BuildContext context, AppLocalizations l10n, YearReview r) {
    final locale = Localizations.localeOf(context).toString();
    final cards = <Widget>[
      _IntroCard(review: r),
      if (r.readingSeconds > 0 || r.readingDays > 0) _TimeCard(review: r),
      if (r.longest != null || r.best != null) _HighlightCard(review: r),
      if (r.topAuthor != null || r.bestMonth != null)
        _PeopleCard(review: r, locale: locale),
      if (r.covers.isNotEmpty) _CoversCard(review: r),
    ];
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              for (final (i, card) in cards.indexed)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: RepaintBoundary(
                    key: _keys.putIfAbsent(i, GlobalKey.new),
                    child: card,
                  ),
                ),
            ],
          ),
        ),
        Semantics(
          label: l10n.reviewPage(_page + 1, cards.length),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < cards.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The frame every card shares: the brand colours, large rounded corners.
class _Frame extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment alignment;
  const _Frame({
    required this.children,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onPrimaryContainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: alignment,
          children: children,
        ),
      ),
    );
  }
}

/// A big number or phrase that shrinks to fit rather than wrapping.
class _Big extends StatelessWidget {
  final String text;
  const _Big(this.text);

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

/// A caption, the thing it names and one line of detail.
class _Stat extends StatelessWidget {
  final String label;
  final String title;
  final String detail;
  const _Stat({required this.label, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.titleMedium),
        const SizedBox(height: 8),
        Text(title, style: text.headlineMedium),
        Text(detail),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  final YearReview review;
  const _IntroCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return _Frame(
      children: [
        Text(l10n.reviewIntro(review.year), style: text.headlineMedium),
        const SizedBox(height: 24),
        _Big(l10n.reviewBooks(review.books)),
        const SizedBox(height: 8),
        Text(
          l10n.reviewPages(formatCount(context, review.pages)),
          style: text.headlineSmall,
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final YearReview review;
  const _TimeCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return _Frame(
      children: [
        Text(l10n.reviewTimeHeading, style: text.titleMedium),
        const SizedBox(height: 16),
        if (review.readingSeconds > 0)
          _Big(formatDurationSeconds(l10n, review.readingSeconds)),
        const SizedBox(height: 8),
        Text(l10n.reviewDays(review.readingDays), style: text.headlineSmall),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final YearReview review;
  const _HighlightCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final longest = review.longest;
    final best = review.best;
    return _Frame(
      children: [
        if (longest != null)
          _Stat(
            label: l10n.reviewLongest,
            title: longest.title,
            detail: l10n.reviewPages(
              formatCount(context, longest.pageCount ?? 0),
            ),
          ),
        if (best != null)
          _Stat(
            label: l10n.reviewBest,
            title: best.title,
            detail:
                '★ ${formatRating(best.rating)}  ${best.authors.join(', ')}',
          ),
      ],
    );
  }
}

class _PeopleCard extends StatelessWidget {
  final YearReview review;
  final String locale;
  const _PeopleCard({required this.review, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final author = review.topAuthor;
    final month = review.bestMonth;
    return _Frame(
      children: [
        if (author != null)
          _Stat(
            label: l10n.reviewTopAuthor,
            title: author.$1,
            detail: l10n.reviewBooks(author.$2),
          ),
        if (month != null)
          _Stat(
            label: l10n.reviewBestMonth,
            title: DateFormat.MMMM(
              locale,
            ).format(DateTime(review.year, month.$1)),
            detail: l10n.reviewBooks(month.$2),
          ),
      ],
    );
  }
}

class _CoversCard extends StatelessWidget {
  final YearReview review;
  const _CoversCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Frame(
      alignment: MainAxisAlignment.start,
      children: [
        Text(
          l10n.reviewCoversHeading,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2 / 3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final book in review.covers)
                BookCover(book: book, borderRadius: BorderRadius.circular(6)),
            ],
          ),
        ),
      ],
    );
  }
}
