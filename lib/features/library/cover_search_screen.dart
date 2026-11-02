import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/cover/cover_cache_service.dart';
import 'package:openreads/data/metadata/open_library_search_client.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// Shows the covers available online for a book and pops with the URL the
/// user taps (FR-R2-13): the stored URL, the DNB and Open Library by ISBN,
/// then the covers of other editions found by [query] (title and author).
class CoverSearchScreen extends StatefulWidget {
  final String? isbn;
  final String? coverUrl;
  final String query;

  /// Called when no source has a cover, so the book can be marked.
  final VoidCallback? onNothingFound;

  const CoverSearchScreen({
    super.key,
    this.isbn,
    this.coverUrl,
    required this.query,
    this.onNothingFound,
  });

  @override
  State<CoverSearchScreen> createState() => _CoverSearchScreenState();
}

class _CoverSearchScreenState extends State<CoverSearchScreen> {
  List<String>? _candidates;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    final results = await context.read<OpenLibrarySearchClient>().trySearch(
      widget.query,
      OlSearchType.general,
    );
    if (!mounted) return;
    final candidates = {
      ...coverCandidates(coverUrl: widget.coverUrl, isbn: widget.isbn),
      for (final r in results ?? const <OlSearchResult>[])
        if (r.coverUrl case final url?) url,
    }.toList();
    setState(() {
      _candidates = candidates;
      _offline = results == null;
    });
    // Offline proves nothing: only a search that ran may mark the book.
    if (candidates.isEmpty && !_offline) widget.onNothingFound?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidates = _candidates;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coverSearchTitle)),
      body: candidates == null
          ? const Center(child: CircularProgressIndicator())
          : candidates.isEmpty
          ? Center(
              key: ValueKey(
                _offline ? 'cover-search-offline' : 'cover-search-empty',
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _offline ? l10n.coverSearchOffline : l10n.coverSearchEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: candidates.length,
              itemBuilder: (context, i) => CoverCandidateTile(
                url: candidates[i],
                onTap: () => Navigator.of(context).pop(candidates[i]),
              ),
            ),
    );
  }
}

/// One cover found online. A source that has none shows a broken-image
/// icon instead of failing.
class CoverCandidateTile extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const CoverCandidateTile({super.key, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(
              Icons.broken_image_outlined,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
