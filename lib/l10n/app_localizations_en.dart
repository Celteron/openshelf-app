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
}
