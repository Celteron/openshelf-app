// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OpenShelf';

  @override
  String get navLibrary => 'Library';

  @override
  String get navShelf => 'Shelf';

  @override
  String get navScan => 'Scan';

  @override
  String get assignLocation => 'Assign location';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get chooseLocation => 'Choose location';

  @override
  String get searchHint => 'Search';

  @override
  String get noBooksYet => 'No books yet';

  @override
  String get errorLoadingLibrary => 'Error loading library';

  @override
  String get addBookTitle => 'Add book';

  @override
  String get editBookTitle => 'Edit book';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldSubtitle => 'Subtitle';

  @override
  String get fieldAuthors => 'Authors (comma-separated)';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldPublisher => 'Publisher';

  @override
  String get fieldYear => 'Year';

  @override
  String get fieldPages => 'Pages';

  @override
  String get fieldLanguage => 'Language';

  @override
  String get fieldFormat => 'Format';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldLocation => 'Location';

  @override
  String get noLocation => 'No location';

  @override
  String get save => 'Save';

  @override
  String get lookupMetadataTooltip => 'Lookup metadata';

  @override
  String get invalidIsbn => 'Invalid ISBN';

  @override
  String get noMetadataFound => 'No metadata found';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get statusLabel => 'Status';

  @override
  String get publisherLabel => 'Publisher';

  @override
  String get yearLabel => 'Year';

  @override
  String get pagesLabel => 'Pages';

  @override
  String get languageLabel => 'Language';

  @override
  String get formatLabel => 'Format';

  @override
  String get seriesVolumeLabel => 'Series volume';

  @override
  String lentTo(String name) {
    return 'Lent to $name';
  }

  @override
  String get markReturned => 'Returned';

  @override
  String get borrowerNameHint => 'Borrower name';

  @override
  String get lend => 'Lend';

  @override
  String get dnbVerified => 'DNB-verified';

  @override
  String get edited => 'edited';

  @override
  String get myShelf => 'My Shelf';

  @override
  String get noLocationsYet => 'No locations yet';

  @override
  String get locationName => 'Location name';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get locationNotEmpty => 'Location not empty — move books first';

  @override
  String get scannerTitle => 'Scanner';

  @override
  String get scannerUnsupported =>
      'The scanner is not available on this platform. Please add the ISBN manually.';

  @override
  String stagedCount(int count) {
    return '$count staged';
  }

  @override
  String get alreadyInLibrary => 'Already in library';

  @override
  String get saveAll => 'Save all';

  @override
  String get saving => 'Saving…';

  @override
  String get chooseFile => 'Choose CSV/JSON file';

  @override
  String detectedFormat(String name) {
    return 'Format: $name';
  }

  @override
  String get importAction => 'Import';

  @override
  String importedCount(int count) {
    return 'Imported: $count';
  }

  @override
  String skippedCount(int count) {
    return 'Skipped: $count';
  }

  @override
  String updatedCount(int count) {
    return 'Updated: $count';
  }

  @override
  String duplicatesSkippedCount(int count) {
    return 'Of those, already-present duplicates: $count';
  }

  @override
  String rowError(int row, String reason) {
    return 'Row $row: $reason';
  }

  @override
  String get navStats => 'Statistics';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get totalBooks => 'Total books';

  @override
  String get pagesRead => 'Pages read';

  @override
  String get topLocations => 'Top locations';

  @override
  String get topAuthors => 'Top authors';

  @override
  String get statusUnread => 'Unread';

  @override
  String get statusReading => 'Reading';

  @override
  String get statusRead => 'Read';

  @override
  String get statusDnf => 'Abandoned';

  @override
  String get statusWishlist => 'Wishlist';

  @override
  String get statusReReading => 'Re-reading';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get importExportTitle => 'Import & export';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportDone => 'Exported to:';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get appInfoLabel => 'App info';

  @override
  String get versionLabel => 'Version';

  @override
  String get licenseLabel => 'License';

  @override
  String get licenseText => 'GPL-2.0';

  @override
  String get openSourceCreditsLabel => 'Open source credits';

  @override
  String get creditsText => 'Flutter, Drift, BLoC';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get enterPositiveNumber => 'Enter a number greater than 0';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get readingTitle => 'Reading progress';

  @override
  String get readingStart => 'Start reading';

  @override
  String get readingStop => 'Stop reading';

  @override
  String get currentPageLabel => 'Current page';

  @override
  String get savePage => 'Save page';

  @override
  String pageOfTotal(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String pageOnly(int page) {
    return 'Page $page';
  }

  @override
  String get readingSpeed => 'Reading speed';

  @override
  String pagesPerHourValue(String value) {
    return '$value pages/h';
  }

  @override
  String get notEnoughData => 'Not enough data yet';

  @override
  String get totalReadingTime => 'Total reading time';

  @override
  String get readingSessionsTitle => 'Reading sessions';

  @override
  String get noSessionsYet => 'No reading sessions yet';

  @override
  String sessionPagesLine(int pages, String duration) {
    return '$pages pages · $duration';
  }

  @override
  String get logSession => 'Log a session';

  @override
  String get sessionStartPage => 'From page';

  @override
  String get sessionDate => 'Date';

  @override
  String get deleteSession => 'Delete session';

  @override
  String durationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMin(int minutes) {
    return '$minutes min';
  }

  @override
  String readingSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
      zero: 'No sessions',
    );
    return '$_temp0';
  }

  @override
  String get notesTitle => 'Notes & quotes';

  @override
  String get noteKindNote => 'Note';

  @override
  String get noteKindQuote => 'Quote';

  @override
  String get notesTabNotes => 'Notes';

  @override
  String get notesTabQuotes => 'Quotes';

  @override
  String get addNote => 'Add entry';

  @override
  String get editNote => 'Edit entry';

  @override
  String get noteContentLabel => 'Text';

  @override
  String get notePageLabel => 'Page (optional)';

  @override
  String notePage(int page) {
    return 'p. $page';
  }

  @override
  String get noNotesYet => 'No entries yet';

  @override
  String notesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'Tags';

  @override
  String get manageTags => 'Manage tags';

  @override
  String get editTags => 'Edit tags';

  @override
  String get addTag => 'Add tag';

  @override
  String get newTagHint => 'New tag';

  @override
  String get renameTag => 'Rename tag';

  @override
  String deleteTagTitle(String name) {
    return 'Delete tag “$name”?';
  }

  @override
  String get deleteTagBody => 'The books are kept.';

  @override
  String get tagNameTaken => 'A tag with this name already exists';

  @override
  String get noTagsYet => 'No tags yet';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String goalTitle(int year) {
    return 'Reading goal $year';
  }

  @override
  String get setGoal => 'Set goal';

  @override
  String get editGoal => 'Change goal';

  @override
  String get clearGoal => 'Remove goal';

  @override
  String get goalBooksLabel => 'Number of books';

  @override
  String noGoalYet(int year) {
    return 'No goal set for $year yet';
  }

  @override
  String goalProgress(int completed, int target) {
    return '$completed of $target books';
  }

  @override
  String goalRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0 to go';
  }

  @override
  String get goalReached => 'Goal reached!';

  @override
  String get goalOnTrack => 'Right on track';

  @override
  String goalAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0 ahead of schedule';
  }

  @override
  String goalBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0 behind schedule';
  }

  @override
  String get moveToLibrary => 'Add to library';

  @override
  String get movedToLibrary => 'Added to library';

  @override
  String get deleteBook => 'Move to trash';

  @override
  String deleteBookTitle(String title) {
    return 'Move “$title” to the trash?';
  }

  @override
  String get deleteBookBody =>
      'You can restore the book from the trash or delete it permanently.';

  @override
  String get bookDeleted => 'Book moved to the trash';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get favoritesFilter => 'Favorites';

  @override
  String get sortBy => 'Sort';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortAuthor => 'Author';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortAdded => 'Date added';

  @override
  String get sortProgress => 'Reading progress';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get reviewTitle => 'Review';

  @override
  String get noReviewYet => 'No review yet';

  @override
  String get editReview => 'Edit review';

  @override
  String get reviewHint => 'Your thoughts on the book';

  @override
  String get goalPagesLabel => 'Page goal (optional)';

  @override
  String goalPagesProgress(int read, int target) {
    final intl.NumberFormat readNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String readString = readNumberFormat.format(read);
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$readString of $targetString pages';
  }

  @override
  String get fieldDescription => 'Description';

  @override
  String get coverFromGallery => 'From gallery';

  @override
  String get coverFromCamera => 'Camera';

  @override
  String get coverRemove => 'Remove cover';

  @override
  String get coverPickFailed => 'Could not load the image';

  @override
  String get sortModified => 'Date modified';

  @override
  String get sortPages => 'Page count';

  @override
  String get sortPublicationYear => 'Publication year';

  @override
  String get sortStatus => 'Status';

  @override
  String get sortLastRead => 'Last read';

  @override
  String get sortStartDate => 'Start date';

  @override
  String get sortFinishDate => 'Finish date';

  @override
  String get showAsGrid => 'Grid view';

  @override
  String get showAsList => 'List view';

  @override
  String get yearFilter => 'Year';

  @override
  String get allYears => 'All years';

  @override
  String get bulkSetFormat => 'Change format';

  @override
  String get bulkSetAuthor => 'Change author';

  @override
  String bulkDeleteTitle(int count) {
    return 'Move $count books to the trash?';
  }

  @override
  String get moveToTrash => 'Move to trash';

  @override
  String get moveToTrashBody => 'You can restore the books from the trash.';

  @override
  String movedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0 moved to the trash';
  }

  @override
  String get sessionEndDate => 'Finish date (optional)';

  @override
  String get sessionEndDateHint =>
      'Same day – pick an end date for multi-day readings';

  @override
  String get undo => 'Undo';

  @override
  String get skip => 'Skip';

  @override
  String get quickRatingTitle => 'How did you like the book?';

  @override
  String get olidLabel => 'Open Library ID';

  @override
  String get dateAddedLabel => 'Added';

  @override
  String get dateModifiedLabel => 'Modified';

  @override
  String get trashTitle => 'Trash';

  @override
  String get trashEmpty => 'The trash is empty';

  @override
  String get restore => 'Restore';

  @override
  String get deleteForever => 'Delete permanently';

  @override
  String deleteForeverTitle(String title) {
    return 'Delete “$title” permanently?';
  }

  @override
  String get deleteForeverBody =>
      'The book will be deleted irrevocably together with its notes, tags and reading sessions.';

  @override
  String get emptyTrash => 'Empty trash';

  @override
  String get emptyTrashTitle => 'Empty the trash?';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get materialYou => 'Material You';

  @override
  String get materialYouHint =>
      'Use system (wallpaper) colours where available';

  @override
  String get accentColor => 'Accent colour';

  @override
  String get accentColorDisabledHint => 'Not available with Material You';

  @override
  String get resetToDefault => 'Reset';

  @override
  String get amoledDark => 'AMOLED dark mode';

  @override
  String get amoledDarkHint => 'Pure black in the dark theme';

  @override
  String get fontLabel => 'Font';

  @override
  String get ratingStyleLabel => 'Show rating as';

  @override
  String get ratingAsBar => 'Stars';

  @override
  String get ratingAsNumber => 'Number';

  @override
  String get listLayoutLabel => 'Library layout';

  @override
  String get displayList => 'List';

  @override
  String get displayCompactList => 'Compact list';

  @override
  String get displayGrid => 'Grid';

  @override
  String get displayDetailedGrid => 'Detailed grid';

  @override
  String get booksSection => 'Books';

  @override
  String get defaultFormat => 'Default format';

  @override
  String get defaultStatus => 'Default status';

  @override
  String get defaultTags => 'Default tags';

  @override
  String defaultTagsHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
      zero: 'No tags',
    );
    return '$_temp0 for new books';
  }

  @override
  String get downloadMissingCovers => 'Download missing covers';

  @override
  String get downloadMissingCoversHint =>
      'Fetches covers that are only known by link';

  @override
  String get googleBooksKey => 'Google Books API key';

  @override
  String get googleBooksKeyNone => 'Not set (shared quota)';

  @override
  String googleBooksKeySet(String suffix) {
    return 'Set (…$suffix)';
  }

  @override
  String get showKey => 'Show key';

  @override
  String get hideKey => 'Hide key';

  @override
  String get googleBooksKeyHint =>
      'Without your own key all users share a quota that is often used up. Leave empty to send no key.';

  @override
  String get coversDownloading => 'Downloading covers …';

  @override
  String get coversNoneMissing => 'No covers are missing';

  @override
  String coversDownloaded(int ok, int missing, int failed) {
    return '$ok covers loaded, $missing without an online cover, $failed unreachable';
  }

  @override
  String get exportJsonHint => 'Full backup – can be restored';

  @override
  String get exportCsvHint =>
      'All fields, compatible with the Openreads CSV import';

  @override
  String get restoreBackupHint =>
      'Bookstats, OpenShelf backup, Openreads, Goodreads, StoryGraph, Bookwyrm …';

  @override
  String get sourceCode => 'Source code';

  @override
  String get reportIssue => 'Report an issue';

  @override
  String get standardColors => 'Standard';

  @override
  String get customColor => 'Custom colour';

  @override
  String get finishedBooksByMonth => 'Books finished per month';

  @override
  String get finishedPagesByMonth => 'Pages finished per month';

  @override
  String get averagesTitle => 'Averages & records';

  @override
  String get averageRating => 'Average rating';

  @override
  String get averagePages => 'Average pages';

  @override
  String get averageReadingTime => 'Average reading time';

  @override
  String get longestBook => 'Longest book';

  @override
  String get shortestBook => 'Shortest book';

  @override
  String get fastestBook => 'Read fastest';

  @override
  String get slowestBook => 'Read slowest';

  @override
  String pagesValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString pages';
  }

  @override
  String get openLibrarySearch => 'Open Library search';

  @override
  String get olSearchHint => 'Title, author, ISBN or OLID';

  @override
  String get olTypeGeneral => 'General';

  @override
  String get olTypeTitle => 'Title';

  @override
  String get olTypeAuthor => 'Author';

  @override
  String get olTypeIsbn => 'ISBN';

  @override
  String get olTypeOlid => 'OLID';

  @override
  String get olNoResults => 'No results';

  @override
  String get olEditions => 'Editions';

  @override
  String get search => 'Search';

  @override
  String lendingHistory(int count) {
    return 'Past lendings ($count)';
  }

  @override
  String get filePickerFailed =>
      'The file dialog is unavailable (Linux needs zenity or kdialog). Enter the path below.';

  @override
  String get fileNotReadable => 'The file could not be read';

  @override
  String get importPathLabel => 'File path';

  @override
  String get importFromPath => 'Load from path';

  @override
  String get genreLabel => 'Genre';

  @override
  String get priceLabel => 'Price';

  @override
  String get receivedAtLabel => 'Received on';

  @override
  String get readingStartedLabel => 'Reading started';

  @override
  String get readingFinishedLabel => 'Reading finished';

  @override
  String get readingTimeLabel => 'Reading time';

  @override
  String readingDuration(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String copyValue(String label) {
    return 'Copy $label';
  }

  @override
  String get fieldGenre => 'Genre';

  @override
  String get fieldPrice => 'Price in euro';

  @override
  String get fieldReceivedAt => 'Received on';

  @override
  String get invalidPrice => 'Enter a valid price, e.g. 12.90';

  @override
  String get clearDate => 'Clear date';

  @override
  String importFieldName(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'title': 'Title',
      'subtitle': 'Subtitle',
      'authors': 'Author(s)',
      'isbn': 'ISBN',
      'isbn13': 'ISBN-13',
      'isbn10': 'ISBN-10',
      'publisher': 'Publisher',
      'publishedYear': 'Year published',
      'pageCount': 'Page count',
      'format': 'Format',
      'language': 'Language',
      'description': 'Description',
      'rating': 'Rating',
      'status': 'Reading status',
      'seriesName': 'Series',
      'seriesVolume': 'Volume',
      'favorite': 'Favourite',
      'review': 'Review',
      'notes': 'Notes',
      'tags': 'Tags',
      'startDate': 'Reading started',
      'finishDate': 'Reading finished',
      'readings': 'Readings',
      'dateAdded': 'Added on',
      'olid': 'Open Library ID',
      'quotes': 'Quotes',
      'currentPage': 'Current page',
      'finishedAt': 'Finished on',
      'location': 'Location',
      'borrower': 'Lent to',
      'lentAt': 'Lent on',
      'expectedReturn': 'Return by',
      'lendingStatus': 'Lending status',
      'coverUrl': 'Cover URL',
      'dateModified': 'Modified on',
      'genre': 'Genre',
      'price': 'Price',
      'receivedAt': 'Received on',
      'durationHours': 'Reading time (hours)',
      'durationMinutes': 'Reading time (minutes)',
      'readingSeconds': 'Reading time (seconds)',
      'receivedAs': 'Received as',
      'other': '$field',
    });
    return '$_temp0';
  }

  @override
  String get importIgnoreColumn => 'Do not import';

  @override
  String get importFormatLabel => 'Import format';

  @override
  String get importColumnsHint =>
      'Assign each column to a field. Columns without an assignment are not imported.';

  @override
  String get sessionTimeRead => 'Time read (optional)';

  @override
  String get sessionTimeReadHint =>
      'Only the time actually spent reading. The period follows from the start and end date.';

  @override
  String get unitMinutes => 'Minutes';

  @override
  String get unitHours => 'Hours';

  @override
  String get sessionEndPageOptional => 'To page (optional)';

  @override
  String get readingSpanLabel => 'Reading period';

  @override
  String get dataSection => 'Data';

  @override
  String get clearLibrary => 'Empty library';

  @override
  String get clearLibraryHint =>
      'Remove all books; locations, tags and settings stay';

  @override
  String get clearLibraryTitle => 'Empty the library?';

  @override
  String get clearLibraryBody =>
      'Move all books to the trash (restorable) or delete them permanently?';

  @override
  String get deleteForeverAllTitle => 'Really delete permanently?';

  @override
  String get deleteForeverAllBody =>
      'All books with their notes, tag assignments, reading sessions and covers, including those in the trash, are deleted for good. Export a backup first if you want to keep the data.';

  @override
  String libraryTrashed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books moved to the trash',
      one: '1 book moved to the trash',
    );
    return '$_temp0';
  }

  @override
  String libraryDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books deleted permanently',
      one: '1 book deleted permanently',
    );
    return '$_temp0';
  }

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataHint =>
      'Library, locations, tags, goals, covers and settings';

  @override
  String get deleteAllDataTitle => 'Delete all data?';

  @override
  String get deleteAllDataBody =>
      'Everything the app stores locally is deleted for good: books, locations, tags, reading sessions, goals, covers and settings. The app itself stays installed. Export a backup first if you want to keep the data.';

  @override
  String get confirmWord => 'DELETE';

  @override
  String typeToConfirm(String word) {
    return 'Type “$word” to confirm';
  }

  @override
  String get deleteEverything => 'Delete everything';

  @override
  String get allDataDeleted => 'All data was deleted';

  @override
  String get selectAll => 'Select all';

  @override
  String importColumnN(int n) {
    return 'Column $n';
  }

  @override
  String get importNeedsTitle => 'Assign at least one column to the title.';

  @override
  String get importFormatOwnCsv => 'Custom CSV';

  @override
  String saveFailed(String error) {
    return 'The book could not be saved: $error';
  }

  @override
  String tagFilterLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tags ($count)',
      zero: 'Tags',
    );
    return '$_temp0';
  }

  @override
  String get filterByTags => 'Filter by tags';

  @override
  String get tagSearchHint => 'Search tags';

  @override
  String get clearTagFilter => 'Clear selection';

  @override
  String get noMatchingTags => 'No matching tag';

  @override
  String removeTagFilter(String name) {
    return 'Remove “$name”';
  }

  @override
  String get importExportHint =>
      'Import Bookstats, backups and CSV, or back up all data';

  @override
  String get exportAction => 'Export';

  @override
  String get exportActionHint =>
      'Save all data to a file, e.g. before switching phones';

  @override
  String get importRunning => 'Importing …';

  @override
  String importProgress(int done, int total) {
    return '$done of $total rows';
  }

  @override
  String get importDoneTitle => 'Import finished';

  @override
  String get importFailedTitle => 'Import failed';

  @override
  String get importAgain => 'New import';

  @override
  String get importFinish => 'Done';

  @override
  String get importUnsupportedFormat => 'The file format is not recognised.';

  @override
  String get importAborted => 'The import was cancelled.';

  @override
  String get importPathHint => '/path/to/file.csv';

  @override
  String get fieldReceivedAs => 'Received as';

  @override
  String get receivedAsUnknown => 'Unknown';

  @override
  String get receivedAsPurchase => 'Purchase';

  @override
  String get receivedAsGift => 'Gift';

  @override
  String get receivedAsLoan => 'Loan';

  @override
  String get receivedAsReviewCopy => 'Review copy';

  @override
  String get receivedAsOther => 'Other';

  @override
  String get moreActions => 'More actions';

  @override
  String get splitVolumesAction => 'Split into volumes';

  @override
  String get splitVolumesHint =>
      'The slipcase stays the physical object with ISBN, price, location and cover. Every volume gets its own title, pages and reading status. Sessions, notes and review move to volume 1.';

  @override
  String volumeTitleLabel(int number) {
    return 'Title of volume $number';
  }

  @override
  String get volumePagesLabel => 'Pages';

  @override
  String get addVolume => 'Add volume';

  @override
  String get removeVolume => 'Remove volume';

  @override
  String get splitVolumesSave => 'Split';

  @override
  String get splitVolumesFailed => 'Splitting failed';

  @override
  String get volumesTitle => 'Volumes';

  @override
  String volumesReadProgress(int read, int total) {
    return '$read of $total read';
  }

  @override
  String partOfSlipcase(String title) {
    return 'Part of “$title”';
  }

  @override
  String volumeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volumes',
      one: '1 volume',
    );
    return '$_temp0';
  }

  @override
  String trashedWithVolumes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volumes',
      one: '1 volume',
    );
    return 'with $_temp0';
  }

  @override
  String get showVolumes => 'Show volumes';

  @override
  String get hideVolumes => 'Hide volumes';

  @override
  String get addScanTitle => 'Scan ISBN';

  @override
  String get addScanHint =>
      'Capture barcodes with the camera, several in a row';

  @override
  String get addSearchTitle => 'Search online';

  @override
  String get addSearchHint => 'Search Open Library by title or author';

  @override
  String get addManualTitle => 'Enter manually';

  @override
  String get addManualHint => 'Fill in all details yourself';

  @override
  String get formatHardcover => 'Hardcover';

  @override
  String get formatPaperback => 'Paperback';

  @override
  String get formatEbook => 'E-book';

  @override
  String get formatAudiobook => 'Audiobook';

  @override
  String get formatUnknown => 'Unknown';

  @override
  String get editStagedTitle => 'Edit captured book';

  @override
  String get removeStaged => 'Remove';

  @override
  String get sharedValuesTitle => 'Apply to all';

  @override
  String get sharedValuesHint =>
      'All captured books get these details when saved.';

  @override
  String get apply => 'Apply';

  @override
  String pageCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get coverSearchOnline => 'Search online';

  @override
  String get coverSearchTitle => 'Search cover online';

  @override
  String get coverSearchEmpty =>
      'No cover found online. You can take a photo or pick one from the gallery.';

  @override
  String get coverSearchOffline => 'No connection. Please try again later.';

  @override
  String get completeOnline => 'Complete online';

  @override
  String get completeOnlineHint =>
      'Without an ISBN the app finds neither cover nor details. Search the book online to add them.';

  @override
  String get withoutCoverFilter => 'Without cover';

  @override
  String get show => 'Show';

  @override
  String durationDh(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String durationSec(int seconds) {
    return '$seconds s';
  }

  @override
  String get statsSectionOverview => 'Overview';

  @override
  String get statsSectionReading => 'Reading';

  @override
  String get statsSectionRecords => 'Averages & records';

  @override
  String get statsSectionLibrary => 'Library';

  @override
  String get addedBooksByMonth => 'Books added per month';

  @override
  String get unreadStackByMonth => 'Unread stack at month end';

  @override
  String get spendingByYear => 'Spending per year';

  @override
  String get showInLibrary => 'Show in library';

  @override
  String selectionFilter(int count) {
    return 'Selection ($count)';
  }

  @override
  String get navHome => 'Home';

  @override
  String get homeRecentlyAdded => 'Recently added';

  @override
  String get homeCurrentlyReading => 'Currently reading';

  @override
  String get homeUnreadTrend => 'Unread stack, last 6 months';

  @override
  String get homeEmpty => 'No books yet. Tap + in the library to get started.';

  @override
  String get scanSaveFailed =>
      'Saving failed. Check the location and try again.';

  @override
  String get statNoData => 'No data yet.';

  @override
  String get statOther => 'Other';

  @override
  String get statTagsCountTwice =>
      'Books with several tags count more than once.';

  @override
  String statShowAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Show all $countString';
  }

  @override
  String get statsSectionCustom => 'My statistics';

  @override
  String get statAdd => 'Add statistic';

  @override
  String get statNew => 'New statistic';

  @override
  String get statEdit => 'Edit statistic';

  @override
  String get statPresets => 'Presets';

  @override
  String get statStepMeasure => '1 · What is measured?';

  @override
  String get statStepGrouping => '2 · Grouped by';

  @override
  String get statStepPeriod => '3 · Period and filter';

  @override
  String get statStepChart => '4 · Chart and title';

  @override
  String get statPreview => 'Preview';

  @override
  String get statTitle => 'Title';

  @override
  String get statAllTime => 'All time';

  @override
  String get statNoGrouping => 'None (one number)';

  @override
  String get statFilterStatus => 'Only with status';

  @override
  String get statFilterFormat => 'Only format';

  @override
  String get statFilterTags => 'Only with tag';

  @override
  String get statMeasureBooks => 'Number of books';

  @override
  String get statMeasurePagesRead => 'Pages read';

  @override
  String get statMeasureReadingTime => 'Reading time';

  @override
  String get statMeasureAverageRating => 'Average rating';

  @override
  String get statMeasureSpending => 'Spending';

  @override
  String get statGroupMonth => 'Month';

  @override
  String get statGroupYear => 'Year';

  @override
  String get statGroupStatus => 'Status';

  @override
  String get statGroupFormat => 'Format';

  @override
  String get statGroupGenre => 'Genre';

  @override
  String get statGroupAuthor => 'Author';

  @override
  String get statGroupLocation => 'Location';

  @override
  String get statGroupReceivedAs => 'Received as';

  @override
  String get statGroupTag => 'Tag';

  @override
  String get statChartNumber => 'Number';

  @override
  String get statChartBar => 'Bars';

  @override
  String get statChartLine => 'Line';

  @override
  String get statChartDonut => 'Donut';

  @override
  String statPresetPagesPerMonth(int year) {
    return 'Pages per month $year';
  }

  @override
  String get statPresetBooksByGenre => 'Books by genre';

  @override
  String get statPresetSpendingPerYear => 'Spending per year';

  @override
  String statPresetReadingTimePerMonth(int year) {
    return 'Reading time per month $year';
  }

  @override
  String get statPresetBooksByFormat => 'Books by format';

  @override
  String statAutoTitle(String measure, String grouping) {
    return '$measure by $grouping';
  }

  @override
  String statDeleted(String title) {
    return '\"$title\" deleted';
  }

  @override
  String get statPin => 'Show on home';

  @override
  String get statUnpin => 'Remove from home';

  @override
  String get statPinLimit => 'The home tab shows at most 3 statistics.';

  @override
  String get statMoveUp => 'Move up';

  @override
  String get statMoveDown => 'Move down';

  @override
  String get statMenu => 'Statistic menu';
}
