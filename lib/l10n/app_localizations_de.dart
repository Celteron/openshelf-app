// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'OpenShelf';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navShelf => 'Regal';

  @override
  String get navScan => 'Scannen';

  @override
  String get navImport => 'Import';

  @override
  String get assignLocation => 'Standort zuweisen';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get chooseLocation => 'Standort wählen';

  @override
  String get searchHint => 'Suchen';

  @override
  String get noBooksYet => 'Noch keine Bücher';

  @override
  String get errorLoadingLibrary => 'Fehler beim Laden der Bibliothek';

  @override
  String get addBookTitle => 'Buch hinzufügen';

  @override
  String get editBookTitle => 'Buch bearbeiten';

  @override
  String get fieldTitle => 'Titel';

  @override
  String get fieldSubtitle => 'Untertitel';

  @override
  String get fieldAuthors => 'Autoren (durch Komma getrennt)';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldPublisher => 'Verlag';

  @override
  String get fieldYear => 'Jahr';

  @override
  String get fieldPages => 'Seiten';

  @override
  String get fieldLanguage => 'Sprache';

  @override
  String get fieldFormat => 'Format';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldLocation => 'Standort';

  @override
  String get noLocation => 'Kein Standort';

  @override
  String get save => 'Speichern';

  @override
  String get lookupMetadataTooltip => 'Metadaten suchen';

  @override
  String get invalidIsbn => 'Ungültige ISBN';

  @override
  String get noMetadataFound => 'Keine Metadaten gefunden';

  @override
  String get ratingLabel => 'Bewertung';

  @override
  String get statusLabel => 'Status';

  @override
  String get isbn13Label => 'ISBN-13';

  @override
  String get isbn10Label => 'ISBN-10';

  @override
  String get publisherLabel => 'Verlag';

  @override
  String get yearLabel => 'Jahr';

  @override
  String get pagesLabel => 'Seiten';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get formatLabel => 'Format';

  @override
  String get seriesVolumeLabel => 'Band';

  @override
  String lentTo(String name) {
    return 'Verliehen an $name';
  }

  @override
  String get markReturned => 'Zurückgegeben';

  @override
  String get borrowerNameHint => 'Name des Entleihers';

  @override
  String get lend => 'Verleihen';

  @override
  String get dnbVerified => 'DNB-verifiziert';

  @override
  String get edited => 'bearbeitet';

  @override
  String get myShelf => 'Mein Regal';

  @override
  String get noLocationsYet => 'Noch keine Orte';

  @override
  String get locationName => 'Ortsname';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get locationNotEmpty =>
      'Ort ist nicht leer — zuerst Bücher verschieben';

  @override
  String get scannerTitle => 'Scanner';

  @override
  String get scannerUnsupported =>
      'Scanner ist auf dieser Plattform nicht verfügbar. ISBN bitte manuell hinzufügen.';

  @override
  String stagedCount(int count) {
    return '$count erfasst';
  }

  @override
  String get alreadyInLibrary => 'Bereits in der Bibliothek';

  @override
  String get saveAll => 'Alle speichern';

  @override
  String get saving => 'Speichern…';

  @override
  String get importTitle => 'Import';

  @override
  String get chooseFile => 'CSV/JSON-Datei auswählen';

  @override
  String detectedFormat(String name) {
    return 'Format: $name';
  }

  @override
  String get importAction => 'Importieren';

  @override
  String rowsProcessed(int count) {
    return '$count Zeilen verarbeitet';
  }

  @override
  String importedCount(int count) {
    return 'Importiert: $count';
  }

  @override
  String skippedCount(int count) {
    return 'Übersprungen: $count';
  }

  @override
  String updatedCount(int count) {
    return 'Aktualisiert: $count';
  }

  @override
  String duplicatesSkippedCount(int count) {
    return 'Davon bereits vorhandene Duplikate: $count';
  }

  @override
  String rowError(int row, String reason) {
    return 'Zeile $row: $reason';
  }

  @override
  String get navStats => 'Statistik';

  @override
  String get statisticsTitle => 'Statistik';

  @override
  String get totalBooks => 'Bücher gesamt';

  @override
  String get pagesRead => 'Gelesene Seiten';

  @override
  String get topLocations => 'Top Standorte';

  @override
  String get topAuthors => 'Top Autoren';

  @override
  String get statusUnread => 'Ungelesen';

  @override
  String get statusReading => 'Am Lesen';

  @override
  String get statusRead => 'Gelesen';

  @override
  String get statusDnf => 'Abgebrochen';

  @override
  String get statusWishlist => 'Wunschliste';

  @override
  String get statusReReading => 'Wiederlesen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get themeLabel => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get exportLabel => 'Daten';

  @override
  String get exportJson => 'JSON exportieren';

  @override
  String get exportCsv => 'CSV exportieren';

  @override
  String get exportDone => 'Exportiert nach:';

  @override
  String get appInfoLabel => 'App-Info';

  @override
  String get versionLabel => 'Version';

  @override
  String get licenseLabel => 'Lizenz';

  @override
  String get licenseText => 'GPL-3.0';

  @override
  String get openSourceCreditsLabel => 'Open-Source-Danksagungen';

  @override
  String get creditsText => 'Flutter, Drift, BLoC';

  @override
  String get delete => 'Löschen';

  @override
  String get copy => 'Kopieren';

  @override
  String get copiedToClipboard => 'In die Zwischenablage kopiert';

  @override
  String get enterPositiveNumber => 'Bitte eine Zahl größer 0 eingeben';

  @override
  String get clearFilters => 'Filter zurücksetzen';

  @override
  String get readingTitle => 'Lesefortschritt';

  @override
  String get readingStart => 'Lesen starten';

  @override
  String get readingStop => 'Lesen beenden';

  @override
  String get currentPageLabel => 'Aktuelle Seite';

  @override
  String get savePage => 'Seite speichern';

  @override
  String pageOfTotal(int page, int total) {
    return 'Seite $page von $total';
  }

  @override
  String pageOnly(int page) {
    return 'Seite $page';
  }

  @override
  String get readingSpeed => 'Lesegeschwindigkeit';

  @override
  String pagesPerHourValue(String value) {
    return '$value Seiten/Std.';
  }

  @override
  String get notEnoughData => 'Noch nicht genug Daten';

  @override
  String get totalReadingTime => 'Gesamte Lesezeit';

  @override
  String get readingSessionsTitle => 'Lesesitzungen';

  @override
  String get noSessionsYet => 'Noch keine Lesesitzungen';

  @override
  String sessionPagesLine(int pages, String duration) {
    return '$pages Seiten · $duration';
  }

  @override
  String get logSession => 'Sitzung nachtragen';

  @override
  String get sessionDurationMinutes => 'Dauer (Minuten)';

  @override
  String get sessionStartPage => 'Von Seite';

  @override
  String get sessionEndPage => 'Bis Seite';

  @override
  String get sessionDate => 'Datum';

  @override
  String get deleteSession => 'Sitzung löschen';

  @override
  String durationHm(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String durationMin(int minutes) {
    return '$minutes Min.';
  }

  @override
  String readingSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sitzungen',
      one: '1 Sitzung',
      zero: 'Keine Sitzungen',
    );
    return '$_temp0';
  }

  @override
  String get notesTitle => 'Notizen & Zitate';

  @override
  String get noteKindNote => 'Notiz';

  @override
  String get noteKindQuote => 'Zitat';

  @override
  String get notesTabNotes => 'Notizen';

  @override
  String get notesTabQuotes => 'Zitate';

  @override
  String get addNote => 'Eintrag hinzufügen';

  @override
  String get editNote => 'Eintrag bearbeiten';

  @override
  String get noteContentLabel => 'Text';

  @override
  String get notePageLabel => 'Seite (optional)';

  @override
  String notePage(int page) {
    return 'S. $page';
  }

  @override
  String get noNotesYet => 'Noch keine Einträge';

  @override
  String notesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
      zero: 'Keine Einträge',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'Tags';

  @override
  String get manageTags => 'Tags verwalten';

  @override
  String get editTags => 'Tags bearbeiten';

  @override
  String get addTag => 'Tag hinzufügen';

  @override
  String get newTagHint => 'Neuer Tag';

  @override
  String get renameTag => 'Tag umbenennen';

  @override
  String deleteTagTitle(String name) {
    return 'Tag „$name“ löschen?';
  }

  @override
  String get deleteTagBody => 'Die Bücher bleiben erhalten.';

  @override
  String get tagNameTaken => 'Ein Tag mit diesem Namen existiert bereits';

  @override
  String get noTagsYet => 'Noch keine Tags';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String goalTitle(int year) {
    return 'Leseziel $year';
  }

  @override
  String get setGoal => 'Ziel festlegen';

  @override
  String get editGoal => 'Ziel ändern';

  @override
  String get clearGoal => 'Ziel entfernen';

  @override
  String get goalBooksLabel => 'Anzahl Bücher';

  @override
  String noGoalYet(int year) {
    return 'Für $year ist noch kein Ziel gesetzt';
  }

  @override
  String goalProgress(int completed, int target) {
    return '$completed von $target Büchern';
  }

  @override
  String goalRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return 'Noch $_temp0';
  }

  @override
  String get goalReached => 'Ziel erreicht!';

  @override
  String get goalOnTrack => 'Genau im Plan';

  @override
  String goalAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0 vor dem Plan';
  }

  @override
  String goalBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0 hinter dem Plan';
  }

  @override
  String get moveToLibrary => 'In Bestand übernehmen';

  @override
  String get movedToLibrary => 'Zum Bestand hinzugefügt';

  @override
  String get deleteBook => 'Buch löschen';

  @override
  String deleteBookTitle(String title) {
    return '„$title“ löschen?';
  }

  @override
  String get deleteBookBody =>
      'Das Buch wird samt Notizen, Tags und Lesesitzungen endgültig gelöscht.';

  @override
  String get bookDeleted => 'Buch gelöscht';

  @override
  String get addFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get removeFavorite => 'Aus Favoriten entfernen';

  @override
  String get favoritesFilter => 'Favoriten';

  @override
  String get sortBy => 'Sortieren';

  @override
  String get sortTitle => 'Titel';

  @override
  String get sortAuthor => 'Autor';

  @override
  String get sortRating => 'Bewertung';

  @override
  String get sortAdded => 'Hinzugefügt am';

  @override
  String get sortProgress => 'Lese-Fortschritt';

  @override
  String get sortAscending => 'Aufsteigend';

  @override
  String get sortDescending => 'Absteigend';

  @override
  String get reviewTitle => 'Rezension';

  @override
  String get noReviewYet => 'Noch keine Rezension';

  @override
  String get editReview => 'Rezension bearbeiten';

  @override
  String get reviewHint => 'Deine Meinung zum Buch';

  @override
  String get goalPagesLabel => 'Seitenziel (optional)';

  @override
  String goalPagesProgress(int read, int target) {
    return '$read von $target Seiten';
  }
}
