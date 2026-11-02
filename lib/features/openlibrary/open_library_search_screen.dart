import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/data/metadata/open_library_search_client.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/features/common/widgets/book_cover.dart';
import 'package:openreads/l10n/app_localizations.dart';

/// What the user picked on Open Library: the metadata to fill the book form
/// with, and the edition's Open Library id.
class OlPick {
  final BookMetadata metadata;
  final String? olid;
  const OlPick(this.metadata, this.olid);
}

/// Search Open Library by general text, title, author, ISBN or OLID and pick a
/// result (or one of its editions) to prefill a book (Openreads
/// "search Open Library"). Pops with an [OlPick].
class OpenLibrarySearchScreen extends StatefulWidget {
  final String initialQuery;
  const OpenLibrarySearchScreen({super.key, this.initialQuery = ''});

  @override
  State<OpenLibrarySearchScreen> createState() =>
      _OpenLibrarySearchScreenState();
}

class _OpenLibrarySearchScreenState extends State<OpenLibrarySearchScreen> {
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery,
  );
  OlSearchType _type = OlSearchType.general;
  List<OlSearchResult>? _results;
  bool _loading = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_query.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final results = await context.read<OpenLibrarySearchClient>().search(
      _query.text,
      _type,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  String _typeLabel(AppLocalizations l10n, OlSearchType type) => switch (type) {
    OlSearchType.general => l10n.olTypeGeneral,
    OlSearchType.title => l10n.olTypeTitle,
    OlSearchType.author => l10n.olTypeAuthor,
    OlSearchType.isbn => l10n.olTypeIsbn,
    OlSearchType.olid => l10n.olTypeOlid,
  };

  Future<void> _openEditions(OlSearchResult result) async {
    final pick = await Navigator.of(context).push<OlPick>(
      MaterialPageRoute(builder: (_) => _EditionsScreen(work: result)),
    );
    if (pick != null && mounted) Navigator.of(context).pop(pick);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.openLibrarySearch)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              key: const ValueKey('ol-query'),
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: l10n.olSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  key: const ValueKey('ol-search'),
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: l10n.search,
                  onPressed: _search,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final type in OlSearchType.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      key: ValueKey('ol-type:${type.name}'),
                      label: Text(_typeLabel(l10n, type)),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: results == null
                ? const SizedBox.shrink()
                : results.isEmpty
                ? Center(child: Text(l10n.olNoResults))
                : ListView(
                    key: const ValueKey('ol-results'),
                    children: [
                      for (final r in results)
                        ListTile(
                          key: ValueKey('ol-result:${r.key}'),
                          leading: UrlCover(
                            cacheKey: 'ol-${r.coverId ?? r.id}',
                            url: r.coverUrl,
                            width: 40,
                            height: 56,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          title: Text(r.title),
                          subtitle: Text(
                            [
                              if (r.authors.isNotEmpty) r.authors.join(', '),
                              if (r.firstPublishYear != null)
                                '${r.firstPublishYear}',
                            ].join(' · '),
                          ),
                          trailing: r.isWork
                              ? IconButton(
                                  key: ValueKey('ol-editions:${r.key}'),
                                  icon: const Icon(Icons.library_books),
                                  tooltip: l10n.olEditions,
                                  onPressed: () => _openEditions(r),
                                )
                              : null,
                          onTap: () => Navigator.of(
                            context,
                          ).pop(OlPick(r.toMetadata(), r.editionOlid)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditionsScreen extends StatelessWidget {
  final OlSearchResult work;
  const _EditionsScreen({required this.work});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(work.title)),
      body: FutureBuilder<List<OlEdition>>(
        future: context.read<OpenLibrarySearchClient>().editions(work.key),
        builder: (context, snapshot) {
          final editions = snapshot.data;
          if (editions == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (editions.isEmpty) return Center(child: Text(l10n.olNoResults));
          return ListView(
            key: const ValueKey('ol-editions-list'),
            children: [
              for (final e in editions)
                ListTile(
                  key: ValueKey('ol-edition:${e.olid}'),
                  leading: UrlCover(
                    cacheKey: 'ol-${e.coverId ?? e.olid}',
                    url: e.coverUrl,
                    width: 40,
                    height: 56,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  title: Text(e.title),
                  subtitle: Text(
                    [
                      if (e.publisher != null) e.publisher!,
                      if (e.publishYear != null) '${e.publishYear}',
                      if (e.pages != null) l10n.pagesValue(e.pages!),
                    ].join(' · '),
                  ),
                  onTap: () => Navigator.of(context).pop(
                    OlPick(
                      BookMetadata(
                        title: e.title,
                        subtitle: e.subtitle,
                        authors: work.authors,
                        publisher: e.publisher,
                        publishedYear: e.publishYear,
                        pageCount: e.pages,
                        isbn13: e.isbn13,
                        isbn10: e.isbn10,
                        language: e.language,
                        coverUrl: e.coverUrl ?? work.coverUrl,
                      ),
                      e.olid,
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
