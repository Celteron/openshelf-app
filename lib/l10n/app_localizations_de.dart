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
}
