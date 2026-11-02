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
  String get chooseFile => 'CSV/JSON-Datei auswählen';

  @override
  String detectedFormat(String name) {
    return 'Format: $name';
  }

  @override
  String get importAction => 'Importieren';

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
  String get importExportTitle => 'Import & Export';

  @override
  String get exportJson => 'JSON exportieren';

  @override
  String get exportCsv => 'CSV exportieren';

  @override
  String get exportDone => 'Exportiert nach:';

  @override
  String get exportFailed => 'Export fehlgeschlagen';

  @override
  String get appInfoLabel => 'App-Info';

  @override
  String get versionLabel => 'Version';

  @override
  String get licenseLabel => 'Lizenz';

  @override
  String get licenseText => 'GPL-2.0';

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
  String get sessionStartPage => 'Von Seite';

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
  String get deleteBook => 'In den Papierkorb';

  @override
  String deleteBookTitle(String title) {
    return '„$title“ in den Papierkorb?';
  }

  @override
  String get deleteBookBody =>
      'Das Buch kann im Papierkorb wiederhergestellt oder endgültig gelöscht werden.';

  @override
  String get bookDeleted => 'Buch im Papierkorb';

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
    final intl.NumberFormat readNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String readString = readNumberFormat.format(read);
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$readString von $targetString Seiten';
  }

  @override
  String get fieldDescription => 'Beschreibung';

  @override
  String get coverFromGallery => 'Aus Galerie';

  @override
  String get coverFromCamera => 'Kamera';

  @override
  String get coverRemove => 'Cover entfernen';

  @override
  String get coverPickFailed => 'Bild konnte nicht geladen werden';

  @override
  String get sortModified => 'Geändert am';

  @override
  String get sortPages => 'Seitenzahl';

  @override
  String get sortPublicationYear => 'Erscheinungsjahr';

  @override
  String get sortStatus => 'Status';

  @override
  String get sortLastRead => 'Zuletzt gelesen';

  @override
  String get sortStartDate => 'Lesebeginn';

  @override
  String get sortFinishDate => 'Leseende';

  @override
  String get showAsGrid => 'Rasteransicht';

  @override
  String get showAsList => 'Listenansicht';

  @override
  String get yearFilter => 'Jahr';

  @override
  String get allYears => 'Alle Jahre';

  @override
  String get bulkSetFormat => 'Format ändern';

  @override
  String get bulkSetAuthor => 'Autor ändern';

  @override
  String bulkDeleteTitle(int count) {
    return '$count Bücher in den Papierkorb?';
  }

  @override
  String get moveToTrash => 'In den Papierkorb';

  @override
  String get moveToTrashBody =>
      'Du kannst die Bücher im Papierkorb wiederherstellen.';

  @override
  String movedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0 im Papierkorb';
  }

  @override
  String get sessionEndDate => 'Leseende (optional)';

  @override
  String get sessionEndDateHint =>
      'Gleicher Tag – für mehrtägiges Lesen ein Enddatum wählen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get skip => 'Überspringen';

  @override
  String get quickRatingTitle => 'Wie hat dir das Buch gefallen?';

  @override
  String get olidLabel => 'Open-Library-ID';

  @override
  String get dateAddedLabel => 'Hinzugefügt';

  @override
  String get dateModifiedLabel => 'Geändert';

  @override
  String get trashTitle => 'Papierkorb';

  @override
  String get trashEmpty => 'Der Papierkorb ist leer';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get deleteForever => 'Endgültig löschen';

  @override
  String deleteForeverTitle(String title) {
    return '„$title“ endgültig löschen?';
  }

  @override
  String get deleteForeverBody =>
      'Das Buch wird samt Notizen, Tags und Lesesitzungen unwiderruflich gelöscht.';

  @override
  String get emptyTrash => 'Papierkorb leeren';

  @override
  String get emptyTrashTitle => 'Papierkorb leeren?';

  @override
  String get appearanceSection => 'Darstellung';

  @override
  String get materialYou => 'Material You';

  @override
  String get materialYouHint =>
      'Systemfarben (Hintergrundbild) verwenden, wo verfügbar';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get accentColorDisabledHint => 'Bei Material You nicht verfügbar';

  @override
  String get resetToDefault => 'Zurücksetzen';

  @override
  String get amoledDark => 'AMOLED-Dunkelmodus';

  @override
  String get amoledDarkHint => 'Reines Schwarz im dunklen Design';

  @override
  String get fontLabel => 'Schriftart';

  @override
  String get ratingStyleLabel => 'Bewertung anzeigen als';

  @override
  String get ratingAsBar => 'Sterne';

  @override
  String get ratingAsNumber => 'Zahl';

  @override
  String get listLayoutLabel => 'Ansicht der Bibliothek';

  @override
  String get displayList => 'Liste';

  @override
  String get displayCompactList => 'Kompakte Liste';

  @override
  String get displayGrid => 'Raster';

  @override
  String get displayDetailedGrid => 'Detailliertes Raster';

  @override
  String get booksSection => 'Bücher';

  @override
  String get defaultFormat => 'Standardformat';

  @override
  String get defaultStatus => 'Standardstatus';

  @override
  String get defaultTags => 'Standard-Tags';

  @override
  String defaultTagsHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tags',
      one: '1 Tag',
      zero: 'Keine',
    );
    return '$_temp0 für neue Bücher';
  }

  @override
  String get downloadMissingCovers => 'Fehlende Cover laden';

  @override
  String get downloadMissingCoversHint =>
      'Lädt Cover nach, die nur als Link bekannt sind';

  @override
  String get googleBooksKey => 'Google-Books-API-Key';

  @override
  String get googleBooksKeyNone => 'Nicht gesetzt (gemeinsames Kontingent)';

  @override
  String googleBooksKeySet(String suffix) {
    return 'Gesetzt (…$suffix)';
  }

  @override
  String get showKey => 'Key anzeigen';

  @override
  String get hideKey => 'Key verbergen';

  @override
  String get googleBooksKeyHint =>
      'Ohne eigenen Key teilen sich alle Nutzer ein Kontingent, das oft ausgeschöpft ist. Leer lassen, um keinen Key zu senden.';

  @override
  String get coversDownloading => 'Cover werden geladen …';

  @override
  String get coversNoneMissing => 'Es fehlen keine Cover';

  @override
  String coversDownloaded(int ok, int missing, int failed) {
    return '$ok Cover geladen, $missing ohne Online-Cover, $failed nicht erreichbar';
  }

  @override
  String get exportJsonHint =>
      'Vollständiges Backup – lässt sich wiederherstellen';

  @override
  String get exportCsvHint =>
      'Alle Felder, kompatibel mit dem Openreads-CSV-Import';

  @override
  String get restoreBackupHint =>
      'Bookstats, OpenShelf-Backup, Openreads, Goodreads, StoryGraph, Bookwyrm …';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get reportIssue => 'Fehler melden';

  @override
  String get standardColors => 'Standard';

  @override
  String get customColor => 'Eigene Farbe';

  @override
  String get finishedBooksByMonth => 'Gelesene Bücher pro Monat';

  @override
  String get finishedPagesByMonth => 'Gelesene Seiten pro Monat';

  @override
  String get averagesTitle => 'Durchschnitte & Rekorde';

  @override
  String get averageRating => 'Ø Bewertung';

  @override
  String get averagePages => 'Ø Seitenzahl';

  @override
  String get averageReadingTime => 'Ø Lesezeit';

  @override
  String get longestBook => 'Längstes Buch';

  @override
  String get shortestBook => 'Kürzestes Buch';

  @override
  String get fastestBook => 'Am schnellsten gelesen';

  @override
  String get slowestBook => 'Am langsamsten gelesen';

  @override
  String pagesValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString Seiten';
  }

  @override
  String get openLibrarySearch => 'Open-Library-Suche';

  @override
  String get olSearchHint => 'Titel, Autor, ISBN oder OLID';

  @override
  String get olTypeGeneral => 'Allgemein';

  @override
  String get olTypeTitle => 'Titel';

  @override
  String get olTypeAuthor => 'Autor';

  @override
  String get olTypeIsbn => 'ISBN';

  @override
  String get olTypeOlid => 'OLID';

  @override
  String get olNoResults => 'Keine Treffer';

  @override
  String get olEditions => 'Ausgaben';

  @override
  String get search => 'Suchen';

  @override
  String lendingHistory(int count) {
    return 'Frühere Leihen ($count)';
  }

  @override
  String get filePickerFailed =>
      'Der Dateidialog ist nicht verfügbar (unter Linux wird zenity oder kdialog benötigt). Gib den Pfad unten ein.';

  @override
  String get fileNotReadable => 'Die Datei konnte nicht gelesen werden';

  @override
  String get importPathLabel => 'Dateipfad';

  @override
  String get importFromPath => 'Aus Pfad laden';

  @override
  String get genreLabel => 'Genre';

  @override
  String get priceLabel => 'Preis';

  @override
  String get receivedAtLabel => 'Erhalten am';

  @override
  String get readingStartedLabel => 'Lesebeginn';

  @override
  String get readingFinishedLabel => 'Leseende';

  @override
  String get readingTimeLabel => 'Lesezeit';

  @override
  String readingDuration(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String copyValue(String label) {
    return '$label kopieren';
  }

  @override
  String get fieldGenre => 'Genre';

  @override
  String get fieldPrice => 'Preis in Euro';

  @override
  String get fieldReceivedAt => 'Erhalten am';

  @override
  String get invalidPrice => 'Bitte einen gültigen Preis eingeben, z. B. 12,90';

  @override
  String get clearDate => 'Datum entfernen';

  @override
  String importFieldName(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'title': 'Titel',
      'subtitle': 'Untertitel',
      'authors': 'Autor(en)',
      'isbn': 'ISBN',
      'isbn13': 'ISBN-13',
      'isbn10': 'ISBN-10',
      'publisher': 'Verlag',
      'publishedYear': 'Erscheinungsjahr',
      'pageCount': 'Seitenzahl',
      'format': 'Format',
      'language': 'Sprache',
      'description': 'Beschreibung',
      'rating': 'Bewertung',
      'status': 'Lesestatus',
      'seriesName': 'Reihe',
      'seriesVolume': 'Band',
      'favorite': 'Favorit',
      'review': 'Rezension',
      'notes': 'Notizen',
      'tags': 'Tags',
      'startDate': 'Lesebeginn',
      'finishDate': 'Leseende',
      'readings': 'Lesungen',
      'dateAdded': 'Hinzugefügt am',
      'olid': 'Open-Library-ID',
      'quotes': 'Zitate',
      'currentPage': 'Aktuelle Seite',
      'finishedAt': 'Beendet am',
      'location': 'Standort',
      'borrower': 'Verleihen an',
      'lentAt': 'Verliehen am',
      'expectedReturn': 'Rückgabe bis',
      'lendingStatus': 'Verleihstatus',
      'coverUrl': 'Cover-URL',
      'dateModified': 'Geändert am',
      'genre': 'Genre',
      'price': 'Preis',
      'receivedAt': 'Erhalten am',
      'durationHours': 'Lesedauer (Stunden)',
      'durationMinutes': 'Lesedauer (Minuten)',
      'readingSeconds': 'Lesezeit (Sekunden)',
      'receivedAs': 'Erhalten als',
      'other': '$field',
    });
    return '$_temp0';
  }

  @override
  String get importIgnoreColumn => 'Nicht importieren';

  @override
  String get importFormatLabel => 'Importformat';

  @override
  String get importColumnsHint =>
      'Ordne jede Spalte einem Feld zu. Spalten ohne Zuordnung werden nicht importiert.';

  @override
  String get sessionTimeRead => 'Gelesene Zeit (optional)';

  @override
  String get sessionTimeReadHint =>
      'Nur die tatsächliche Lesezeit. Der Zeitraum ergibt sich aus Start- und Enddatum.';

  @override
  String get unitMinutes => 'Minuten';

  @override
  String get unitHours => 'Stunden';

  @override
  String get sessionEndPageOptional => 'Bis Seite (optional)';

  @override
  String get readingSpanLabel => 'Lesezeitraum';

  @override
  String get dataSection => 'Daten';

  @override
  String get clearLibrary => 'Bibliothek leeren';

  @override
  String get clearLibraryHint =>
      'Alle Bücher entfernen; Orte, Tags und Einstellungen bleiben';

  @override
  String get clearLibraryTitle => 'Bibliothek leeren?';

  @override
  String get clearLibraryBody =>
      'Alle Bücher in den Papierkorb verschieben (wiederherstellbar) oder endgültig löschen?';

  @override
  String get deleteForeverAllTitle => 'Wirklich endgültig löschen?';

  @override
  String get deleteForeverAllBody =>
      'Alle Bücher samt Notizen, Tag-Zuordnungen, Lesesitzungen und Covern, auch im Papierkorb, werden unwiderruflich gelöscht. Exportiere vorher ein Backup, wenn du die Daten behalten willst.';

  @override
  String libraryTrashed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher in den Papierkorb verschoben',
      one: '1 Buch in den Papierkorb verschoben',
    );
    return '$_temp0';
  }

  @override
  String libraryDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher endgültig gelöscht',
      one: '1 Buch endgültig gelöscht',
    );
    return '$_temp0';
  }

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get deleteAllDataHint =>
      'Bibliothek, Orte, Tags, Ziele, Cover und Einstellungen';

  @override
  String get deleteAllDataTitle => 'Alle Daten löschen?';

  @override
  String get deleteAllDataBody =>
      'Alles, was die App lokal speichert, wird unwiderruflich gelöscht: Bücher, Orte, Tags, Lesesitzungen, Ziele, Cover und Einstellungen. Die App selbst bleibt installiert. Exportiere vorher ein Backup, wenn du die Daten behalten willst.';

  @override
  String get confirmWord => 'LÖSCHEN';

  @override
  String typeToConfirm(String word) {
    return 'Tippe „$word“ zur Bestätigung';
  }

  @override
  String get deleteEverything => 'Alles löschen';

  @override
  String get allDataDeleted => 'Alle Daten wurden gelöscht';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String importColumnN(int n) {
    return 'Spalte $n';
  }

  @override
  String get importNeedsTitle => 'Ordne mindestens eine Spalte dem Titel zu.';

  @override
  String get importFormatOwnCsv => 'Eigene CSV';

  @override
  String saveFailed(String error) {
    return 'Das Buch konnte nicht gespeichert werden: $error';
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
  String get filterByTags => 'Nach Tags filtern';

  @override
  String get tagSearchHint => 'Tag suchen';

  @override
  String get clearTagFilter => 'Auswahl aufheben';

  @override
  String get noMatchingTags => 'Kein passender Tag';

  @override
  String removeTagFilter(String name) {
    return '„$name“ entfernen';
  }

  @override
  String get importExportHint =>
      'Bookstats, Backups und CSV importieren oder alle Daten sichern';

  @override
  String get exportAction => 'Exportieren';

  @override
  String get exportActionHint =>
      'Alle Daten als Datei sichern, z. B. vor einem Handywechsel';

  @override
  String get importRunning => 'Import läuft …';

  @override
  String importProgress(int done, int total) {
    return '$done von $total Zeilen';
  }

  @override
  String get importDoneTitle => 'Import abgeschlossen';

  @override
  String get importFailedTitle => 'Import fehlgeschlagen';

  @override
  String get importAgain => 'Neuer Import';

  @override
  String get importFinish => 'Fertig';

  @override
  String get importUnsupportedFormat => 'Das Dateiformat wird nicht erkannt.';

  @override
  String get importAborted => 'Der Import wurde abgebrochen.';

  @override
  String get importPathHint => '/pfad/zur/datei.csv';

  @override
  String get fieldReceivedAs => 'Erhalten als';

  @override
  String get receivedAsUnknown => 'Unbekannt';

  @override
  String get receivedAsPurchase => 'Kauf';

  @override
  String get receivedAsGift => 'Geschenk';

  @override
  String get receivedAsLoan => 'Leihe';

  @override
  String get receivedAsReviewCopy => 'Rezensionsexemplar';

  @override
  String get receivedAsOther => 'Sonstiges';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get splitVolumesAction => 'In Bände aufteilen';

  @override
  String get splitVolumesHint =>
      'Der Schuber bleibt das physische Objekt mit ISBN, Preis, Standort und Cover. Jeder Band bekommt eigenen Titel, eigene Seiten und eigenen Lesestatus. Sitzungen, Notizen und Rezension wandern zu Band 1.';

  @override
  String volumeTitleLabel(int number) {
    return 'Titel Band $number';
  }

  @override
  String get volumePagesLabel => 'Seiten';

  @override
  String get addVolume => 'Band hinzufügen';

  @override
  String get removeVolume => 'Band entfernen';

  @override
  String get splitVolumesSave => 'Aufteilen';

  @override
  String get splitVolumesFailed => 'Aufteilen fehlgeschlagen';

  @override
  String get volumesTitle => 'Bände';

  @override
  String volumesReadProgress(int read, int total) {
    return '$read von $total gelesen';
  }

  @override
  String partOfSlipcase(String title) {
    return 'Teil von „$title“';
  }

  @override
  String volumeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bände',
      one: '1 Band',
    );
    return '$_temp0';
  }

  @override
  String trashedWithVolumes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bänden',
      one: '1 Band',
    );
    return 'mit $_temp0';
  }

  @override
  String get showVolumes => 'Bände anzeigen';

  @override
  String get hideVolumes => 'Bände ausblenden';

  @override
  String get addScanTitle => 'ISBN scannen';

  @override
  String get addScanHint =>
      'Barcode mit der Kamera erfassen, auch mehrere nacheinander';

  @override
  String get addSearchTitle => 'Online suchen';

  @override
  String get addSearchHint => 'Nach Titel oder Autor bei Open Library suchen';

  @override
  String get addManualTitle => 'Manuell eingeben';

  @override
  String get addManualHint => 'Alle Angaben selbst ausfüllen';

  @override
  String get formatHardcover => 'Hardcover';

  @override
  String get formatPaperback => 'Taschenbuch';

  @override
  String get formatEbook => 'E-Book';

  @override
  String get formatAudiobook => 'Hörbuch';

  @override
  String get formatUnknown => 'Unbekannt';

  @override
  String get editStagedTitle => 'Erfasstes Buch bearbeiten';

  @override
  String get removeStaged => 'Entfernen';

  @override
  String get sharedValuesTitle => 'Für alle übernehmen';

  @override
  String get sharedValuesHint =>
      'Diese Angaben bekommen alle erfassten Bücher beim Speichern.';

  @override
  String get apply => 'Übernehmen';

  @override
  String pageCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Seiten',
      one: '1 Seite',
    );
    return '$_temp0';
  }

  @override
  String get coverSearchOnline => 'Online suchen';

  @override
  String get coverSearchTitle => 'Cover online suchen';

  @override
  String get coverSearchEmpty =>
      'Kein Cover online gefunden. Du kannst eins fotografieren oder aus der Galerie wählen.';

  @override
  String get coverSearchOffline =>
      'Die Online-Suche ist gerade nicht erreichbar. Bitte später erneut versuchen.';

  @override
  String get completeOnline => 'Online vervollständigen';

  @override
  String get completeOnlineHint =>
      'Ohne ISBN findet die App weder Cover noch Daten. Such das Buch online, um sie zu ergänzen.';

  @override
  String get withoutCoverFilter => 'Ohne Cover';

  @override
  String get show => 'Anzeigen';

  @override
  String durationDh(int days, int hours) {
    return '$days T. $hours Std.';
  }

  @override
  String durationSec(int seconds) {
    return '$seconds Sek.';
  }

  @override
  String get statsSectionOverview => 'Überblick';

  @override
  String get statsSectionReading => 'Lesen';

  @override
  String get statsSectionRecords => 'Durchschnitt & Rekorde';

  @override
  String get statsSectionLibrary => 'Bibliothek';

  @override
  String get addedBooksByMonth => 'Hinzugefügte Bücher pro Monat';

  @override
  String get unreadStackByMonth => 'Ungelesen-Stapel am Monatsende';

  @override
  String get spendingByYear => 'Ausgaben pro Jahr';

  @override
  String get showInLibrary => 'In Bibliothek zeigen';

  @override
  String selectionFilter(int count) {
    return 'Auswahl ($count)';
  }

  @override
  String get navHome => 'Start';

  @override
  String get homeRecentlyAdded => 'Zuletzt hinzugefügt';

  @override
  String get homeCurrentlyReading => 'Gerade am Lesen';

  @override
  String get homeUnreadTrend => 'Ungelesen-Stapel, letzte 6 Monate';

  @override
  String get homeEmpty =>
      'Noch keine Bücher. Tippe in der Bibliothek auf +, um loszulegen.';

  @override
  String get scanSaveFailed =>
      'Speichern fehlgeschlagen. Prüfe den Standort und versuche es erneut.';

  @override
  String get statNoData => 'Noch keine Daten.';

  @override
  String get statOther => 'Andere';

  @override
  String get statTagsCountTwice => 'Bücher mit mehreren Tags zählen mehrfach.';

  @override
  String statShowAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Alle $countString anzeigen';
  }

  @override
  String get statsSectionCustom => 'Eigene Statistiken';

  @override
  String get statAdd => 'Statistik hinzufügen';

  @override
  String get statNew => 'Neue Statistik';

  @override
  String get statEdit => 'Statistik bearbeiten';

  @override
  String get statPresets => 'Vorlagen';

  @override
  String get statStepMeasure => '1 · Was wird gemessen?';

  @override
  String get statStepGrouping => '2 · Gruppiert nach';

  @override
  String get statStepPeriod => '3 · Zeitraum und Filter';

  @override
  String get statStepChart => '4 · Darstellung und Titel';

  @override
  String get statPreview => 'Vorschau';

  @override
  String get statTitle => 'Titel';

  @override
  String get statAllTime => 'Gesamt';

  @override
  String get statNoGrouping => 'Keine (eine Zahl)';

  @override
  String get statFilterStatus => 'Nur mit Status';

  @override
  String get statFilterFormat => 'Nur Buchart';

  @override
  String get statFilterTags => 'Nur mit Tag';

  @override
  String get statMeasureBooks => 'Anzahl Bücher';

  @override
  String get statMeasurePagesRead => 'Gelesene Seiten';

  @override
  String get statMeasureReadingTime => 'Lesezeit';

  @override
  String get statMeasureAverageRating => 'Durchschnittliche Bewertung';

  @override
  String get statMeasureSpending => 'Ausgaben';

  @override
  String get statGroupMonth => 'Monat';

  @override
  String get statGroupYear => 'Jahr';

  @override
  String get statGroupStatus => 'Status';

  @override
  String get statGroupFormat => 'Buchart';

  @override
  String get statGroupGenre => 'Genre';

  @override
  String get statGroupAuthor => 'Autor';

  @override
  String get statGroupLocation => 'Standort';

  @override
  String get statGroupReceivedAs => 'Erhalten als';

  @override
  String get statGroupTag => 'Tag';

  @override
  String get statChartNumber => 'Zahl';

  @override
  String get statChartBar => 'Balken';

  @override
  String get statChartLine => 'Linie';

  @override
  String get statChartDonut => 'Ring';

  @override
  String statPresetPagesPerMonth(int year) {
    return 'Seiten pro Monat $year';
  }

  @override
  String get statPresetBooksByGenre => 'Bücher nach Genre';

  @override
  String get statPresetSpendingPerYear => 'Ausgaben pro Jahr';

  @override
  String statPresetReadingTimePerMonth(int year) {
    return 'Lesezeit pro Monat $year';
  }

  @override
  String get statPresetBooksByFormat => 'Bücher nach Buchart';

  @override
  String statAutoTitle(String measure, String grouping) {
    return '$measure nach $grouping';
  }

  @override
  String statDeleted(String title) {
    return '„$title“ gelöscht';
  }

  @override
  String get statPin => 'Auf Startseite anzeigen';

  @override
  String get statUnpin => 'Nicht mehr auf Startseite';

  @override
  String statPinLimit(int max) {
    return 'Auf der Startseite sind höchstens $max Statistiken möglich.';
  }

  @override
  String get statMoveUp => 'Nach oben';

  @override
  String get statMoveDown => 'Nach unten';

  @override
  String get statMenu => 'Statistik-Menü';
}
