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
  String get navImport => 'Import';

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
  String get isbn13Label => 'ISBN-13';

  @override
  String get isbn10Label => 'ISBN-10';

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
  String get importTitle => 'Import';

  @override
  String get chooseFile => 'Choose CSV/JSON file';

  @override
  String detectedFormat(String name) {
    return 'Format: $name';
  }

  @override
  String get importAction => 'Import';

  @override
  String rowsProcessed(int count) {
    return '$count rows processed';
  }

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
  String get exportLabel => 'Data';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportDone => 'Exported to:';

  @override
  String get appInfoLabel => 'App info';

  @override
  String get versionLabel => 'Version';

  @override
  String get licenseLabel => 'License';

  @override
  String get licenseText => 'GPL-3.0';

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
  String get sessionDurationMinutes => 'Duration (minutes)';

  @override
  String get sessionStartPage => 'From page';

  @override
  String get sessionEndPage => 'To page';

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
  String get deleteBook => 'Delete book';

  @override
  String deleteBookTitle(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get deleteBookBody =>
      'The book will be permanently deleted together with its notes, tags and reading sessions.';

  @override
  String get bookDeleted => 'Book deleted';

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
    return '$read of $target pages';
  }
}
