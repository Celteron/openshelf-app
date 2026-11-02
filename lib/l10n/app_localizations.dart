import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'OpenShelf'**
  String get appTitle;

  /// No description provided for @navLibrary.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek'**
  String get navLibrary;

  /// No description provided for @navShelf.
  ///
  /// In de, this message translates to:
  /// **'Regal'**
  String get navShelf;

  /// No description provided for @navScan.
  ///
  /// In de, this message translates to:
  /// **'Scannen'**
  String get navScan;

  /// No description provided for @assignLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort zuweisen'**
  String get assignLocation;

  /// No description provided for @selectedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String selectedCount(int count);

  /// No description provided for @chooseLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort wählen'**
  String get chooseLocation;

  /// No description provided for @searchHint.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get searchHint;

  /// No description provided for @noBooksYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bücher'**
  String get noBooksYet;

  /// No description provided for @errorLoadingLibrary.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden der Bibliothek'**
  String get errorLoadingLibrary;

  /// No description provided for @addBookTitle.
  ///
  /// In de, this message translates to:
  /// **'Buch hinzufügen'**
  String get addBookTitle;

  /// No description provided for @editBookTitle.
  ///
  /// In de, this message translates to:
  /// **'Buch bearbeiten'**
  String get editBookTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get fieldTitle;

  /// No description provided for @fieldSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Untertitel'**
  String get fieldSubtitle;

  /// No description provided for @fieldAuthors.
  ///
  /// In de, this message translates to:
  /// **'Autoren (durch Komma getrennt)'**
  String get fieldAuthors;

  /// No description provided for @fieldIsbn.
  ///
  /// In de, this message translates to:
  /// **'ISBN'**
  String get fieldIsbn;

  /// No description provided for @fieldPublisher.
  ///
  /// In de, this message translates to:
  /// **'Verlag'**
  String get fieldPublisher;

  /// No description provided for @fieldYear.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get fieldYear;

  /// No description provided for @fieldPages.
  ///
  /// In de, this message translates to:
  /// **'Seiten'**
  String get fieldPages;

  /// No description provided for @fieldLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get fieldLanguage;

  /// No description provided for @fieldFormat.
  ///
  /// In de, this message translates to:
  /// **'Format'**
  String get fieldFormat;

  /// No description provided for @fieldStatus.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get fieldStatus;

  /// No description provided for @fieldLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort'**
  String get fieldLocation;

  /// No description provided for @noLocation.
  ///
  /// In de, this message translates to:
  /// **'Kein Standort'**
  String get noLocation;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @lookupMetadataTooltip.
  ///
  /// In de, this message translates to:
  /// **'Metadaten suchen'**
  String get lookupMetadataTooltip;

  /// No description provided for @invalidIsbn.
  ///
  /// In de, this message translates to:
  /// **'Ungültige ISBN'**
  String get invalidIsbn;

  /// No description provided for @noMetadataFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Metadaten gefunden'**
  String get noMetadataFound;

  /// No description provided for @ratingLabel.
  ///
  /// In de, this message translates to:
  /// **'Bewertung'**
  String get ratingLabel;

  /// No description provided for @statusLabel.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @publisherLabel.
  ///
  /// In de, this message translates to:
  /// **'Verlag'**
  String get publisherLabel;

  /// No description provided for @yearLabel.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get yearLabel;

  /// No description provided for @pagesLabel.
  ///
  /// In de, this message translates to:
  /// **'Seiten'**
  String get pagesLabel;

  /// No description provided for @languageLabel.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get languageLabel;

  /// No description provided for @formatLabel.
  ///
  /// In de, this message translates to:
  /// **'Format'**
  String get formatLabel;

  /// No description provided for @seriesVolumeLabel.
  ///
  /// In de, this message translates to:
  /// **'Band'**
  String get seriesVolumeLabel;

  /// No description provided for @lentTo.
  ///
  /// In de, this message translates to:
  /// **'Verliehen an {name}'**
  String lentTo(String name);

  /// No description provided for @markReturned.
  ///
  /// In de, this message translates to:
  /// **'Zurückgegeben'**
  String get markReturned;

  /// No description provided for @borrowerNameHint.
  ///
  /// In de, this message translates to:
  /// **'Name des Entleihers'**
  String get borrowerNameHint;

  /// No description provided for @lend.
  ///
  /// In de, this message translates to:
  /// **'Verleihen'**
  String get lend;

  /// No description provided for @dnbVerified.
  ///
  /// In de, this message translates to:
  /// **'DNB-verifiziert'**
  String get dnbVerified;

  /// No description provided for @edited.
  ///
  /// In de, this message translates to:
  /// **'bearbeitet'**
  String get edited;

  /// No description provided for @myShelf.
  ///
  /// In de, this message translates to:
  /// **'Mein Regal'**
  String get myShelf;

  /// No description provided for @noLocationsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Orte'**
  String get noLocationsYet;

  /// No description provided for @locationName.
  ///
  /// In de, this message translates to:
  /// **'Ortsname'**
  String get locationName;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @locationNotEmpty.
  ///
  /// In de, this message translates to:
  /// **'Ort ist nicht leer — zuerst Bücher verschieben'**
  String get locationNotEmpty;

  /// No description provided for @scannerTitle.
  ///
  /// In de, this message translates to:
  /// **'Scanner'**
  String get scannerTitle;

  /// No description provided for @scannerUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Scanner ist auf dieser Plattform nicht verfügbar. ISBN bitte manuell hinzufügen.'**
  String get scannerUnsupported;

  /// No description provided for @stagedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} erfasst'**
  String stagedCount(int count);

  /// No description provided for @alreadyInLibrary.
  ///
  /// In de, this message translates to:
  /// **'Bereits in der Bibliothek'**
  String get alreadyInLibrary;

  /// No description provided for @saveAll.
  ///
  /// In de, this message translates to:
  /// **'Alle speichern'**
  String get saveAll;

  /// No description provided for @saving.
  ///
  /// In de, this message translates to:
  /// **'Speichern…'**
  String get saving;

  /// No description provided for @chooseFile.
  ///
  /// In de, this message translates to:
  /// **'CSV/JSON-Datei auswählen'**
  String get chooseFile;

  /// No description provided for @detectedFormat.
  ///
  /// In de, this message translates to:
  /// **'Format: {name}'**
  String detectedFormat(String name);

  /// No description provided for @importAction.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get importAction;

  /// No description provided for @importedCount.
  ///
  /// In de, this message translates to:
  /// **'Importiert: {count}'**
  String importedCount(int count);

  /// No description provided for @skippedCount.
  ///
  /// In de, this message translates to:
  /// **'Übersprungen: {count}'**
  String skippedCount(int count);

  /// No description provided for @updatedCount.
  ///
  /// In de, this message translates to:
  /// **'Aktualisiert: {count}'**
  String updatedCount(int count);

  /// No description provided for @duplicatesSkippedCount.
  ///
  /// In de, this message translates to:
  /// **'Davon bereits vorhandene Duplikate: {count}'**
  String duplicatesSkippedCount(int count);

  /// No description provided for @rowError.
  ///
  /// In de, this message translates to:
  /// **'Zeile {row}: {reason}'**
  String rowError(int row, String reason);

  /// No description provided for @navStats.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get navStats;

  /// No description provided for @statisticsTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statisticsTitle;

  /// No description provided for @totalBooks.
  ///
  /// In de, this message translates to:
  /// **'Bücher gesamt'**
  String get totalBooks;

  /// No description provided for @pagesRead.
  ///
  /// In de, this message translates to:
  /// **'Gelesene Seiten'**
  String get pagesRead;

  /// No description provided for @topLocations.
  ///
  /// In de, this message translates to:
  /// **'Top Standorte'**
  String get topLocations;

  /// No description provided for @topAuthors.
  ///
  /// In de, this message translates to:
  /// **'Top Autoren'**
  String get topAuthors;

  /// No description provided for @statusUnread.
  ///
  /// In de, this message translates to:
  /// **'Ungelesen'**
  String get statusUnread;

  /// No description provided for @statusReading.
  ///
  /// In de, this message translates to:
  /// **'Am Lesen'**
  String get statusReading;

  /// No description provided for @statusRead.
  ///
  /// In de, this message translates to:
  /// **'Gelesen'**
  String get statusRead;

  /// No description provided for @statusDnf.
  ///
  /// In de, this message translates to:
  /// **'Abgebrochen'**
  String get statusDnf;

  /// No description provided for @statusWishlist.
  ///
  /// In de, this message translates to:
  /// **'Wunschliste'**
  String get statusWishlist;

  /// No description provided for @statusReReading.
  ///
  /// In de, this message translates to:
  /// **'Wiederlesen'**
  String get statusReReading;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @themeLabel.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @languageGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @importExportTitle.
  ///
  /// In de, this message translates to:
  /// **'Import & Export'**
  String get importExportTitle;

  /// No description provided for @exportJson.
  ///
  /// In de, this message translates to:
  /// **'JSON exportieren'**
  String get exportJson;

  /// No description provided for @exportCsv.
  ///
  /// In de, this message translates to:
  /// **'CSV exportieren'**
  String get exportCsv;

  /// No description provided for @exportDone.
  ///
  /// In de, this message translates to:
  /// **'Exportiert nach:'**
  String get exportDone;

  /// No description provided for @exportFailed.
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen'**
  String get exportFailed;

  /// No description provided for @appInfoLabel.
  ///
  /// In de, this message translates to:
  /// **'App-Info'**
  String get appInfoLabel;

  /// No description provided for @versionLabel.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @licenseLabel.
  ///
  /// In de, this message translates to:
  /// **'Lizenz'**
  String get licenseLabel;

  /// No description provided for @licenseText.
  ///
  /// In de, this message translates to:
  /// **'GPL-2.0'**
  String get licenseText;

  /// No description provided for @openSourceCreditsLabel.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Danksagungen'**
  String get openSourceCreditsLabel;

  /// No description provided for @creditsText.
  ///
  /// In de, this message translates to:
  /// **'Flutter, Drift, BLoC'**
  String get creditsText;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In de, this message translates to:
  /// **'Kopieren'**
  String get copy;

  /// No description provided for @copiedToClipboard.
  ///
  /// In de, this message translates to:
  /// **'In die Zwischenablage kopiert'**
  String get copiedToClipboard;

  /// No description provided for @enterPositiveNumber.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Zahl größer 0 eingeben'**
  String get enterPositiveNumber;

  /// No description provided for @clearFilters.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get clearFilters;

  /// No description provided for @readingTitle.
  ///
  /// In de, this message translates to:
  /// **'Lesefortschritt'**
  String get readingTitle;

  /// No description provided for @readingStart.
  ///
  /// In de, this message translates to:
  /// **'Lesen starten'**
  String get readingStart;

  /// No description provided for @readingStop.
  ///
  /// In de, this message translates to:
  /// **'Lesen beenden'**
  String get readingStop;

  /// No description provided for @currentPageLabel.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Seite'**
  String get currentPageLabel;

  /// No description provided for @savePage.
  ///
  /// In de, this message translates to:
  /// **'Seite speichern'**
  String get savePage;

  /// No description provided for @pageOfTotal.
  ///
  /// In de, this message translates to:
  /// **'Seite {page} von {total}'**
  String pageOfTotal(int page, int total);

  /// No description provided for @pageOnly.
  ///
  /// In de, this message translates to:
  /// **'Seite {page}'**
  String pageOnly(int page);

  /// No description provided for @readingSpeed.
  ///
  /// In de, this message translates to:
  /// **'Lesegeschwindigkeit'**
  String get readingSpeed;

  /// No description provided for @pagesPerHourValue.
  ///
  /// In de, this message translates to:
  /// **'{value} Seiten/Std.'**
  String pagesPerHourValue(String value);

  /// No description provided for @notEnoughData.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht genug Daten'**
  String get notEnoughData;

  /// No description provided for @totalReadingTime.
  ///
  /// In de, this message translates to:
  /// **'Gesamte Lesezeit'**
  String get totalReadingTime;

  /// No description provided for @readingSessionsTitle.
  ///
  /// In de, this message translates to:
  /// **'Lesesitzungen'**
  String get readingSessionsTitle;

  /// No description provided for @noSessionsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Lesesitzungen'**
  String get noSessionsYet;

  /// No description provided for @sessionPagesLine.
  ///
  /// In de, this message translates to:
  /// **'{pages} Seiten · {duration}'**
  String sessionPagesLine(int pages, String duration);

  /// No description provided for @logSession.
  ///
  /// In de, this message translates to:
  /// **'Sitzung nachtragen'**
  String get logSession;

  /// No description provided for @sessionStartPage.
  ///
  /// In de, this message translates to:
  /// **'Von Seite'**
  String get sessionStartPage;

  /// No description provided for @sessionDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get sessionDate;

  /// No description provided for @deleteSession.
  ///
  /// In de, this message translates to:
  /// **'Sitzung löschen'**
  String get deleteSession;

  /// No description provided for @durationHm.
  ///
  /// In de, this message translates to:
  /// **'{hours} Std. {minutes} Min.'**
  String durationHm(int hours, int minutes);

  /// No description provided for @durationMin.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min.'**
  String durationMin(int minutes);

  /// No description provided for @readingSessionsCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Sitzungen} =1{1 Sitzung} other{{count} Sitzungen}}'**
  String readingSessionsCount(int count);

  /// No description provided for @notesTitle.
  ///
  /// In de, this message translates to:
  /// **'Notizen & Zitate'**
  String get notesTitle;

  /// No description provided for @noteKindNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get noteKindNote;

  /// No description provided for @noteKindQuote.
  ///
  /// In de, this message translates to:
  /// **'Zitat'**
  String get noteKindQuote;

  /// No description provided for @notesTabNotes.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get notesTabNotes;

  /// No description provided for @notesTabQuotes.
  ///
  /// In de, this message translates to:
  /// **'Zitate'**
  String get notesTabQuotes;

  /// No description provided for @addNote.
  ///
  /// In de, this message translates to:
  /// **'Eintrag hinzufügen'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In de, this message translates to:
  /// **'Eintrag bearbeiten'**
  String get editNote;

  /// No description provided for @noteContentLabel.
  ///
  /// In de, this message translates to:
  /// **'Text'**
  String get noteContentLabel;

  /// No description provided for @notePageLabel.
  ///
  /// In de, this message translates to:
  /// **'Seite (optional)'**
  String get notePageLabel;

  /// No description provided for @notePage.
  ///
  /// In de, this message translates to:
  /// **'S. {page}'**
  String notePage(int page);

  /// No description provided for @noNotesYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge'**
  String get noNotesYet;

  /// No description provided for @notesCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Einträge} =1{1 Eintrag} other{{count} Einträge}}'**
  String notesCount(int count);

  /// No description provided for @tagsTitle.
  ///
  /// In de, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// No description provided for @manageTags.
  ///
  /// In de, this message translates to:
  /// **'Tags verwalten'**
  String get manageTags;

  /// No description provided for @editTags.
  ///
  /// In de, this message translates to:
  /// **'Tags bearbeiten'**
  String get editTags;

  /// No description provided for @addTag.
  ///
  /// In de, this message translates to:
  /// **'Tag hinzufügen'**
  String get addTag;

  /// No description provided for @newTagHint.
  ///
  /// In de, this message translates to:
  /// **'Neuer Tag'**
  String get newTagHint;

  /// No description provided for @renameTag.
  ///
  /// In de, this message translates to:
  /// **'Tag umbenennen'**
  String get renameTag;

  /// No description provided for @deleteTagTitle.
  ///
  /// In de, this message translates to:
  /// **'Tag „{name}“ löschen?'**
  String deleteTagTitle(String name);

  /// No description provided for @deleteTagBody.
  ///
  /// In de, this message translates to:
  /// **'Die Bücher bleiben erhalten.'**
  String get deleteTagBody;

  /// No description provided for @tagNameTaken.
  ///
  /// In de, this message translates to:
  /// **'Ein Tag mit diesem Namen existiert bereits'**
  String get tagNameTaken;

  /// No description provided for @noTagsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Tags'**
  String get noTagsYet;

  /// No description provided for @tagBookCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Buch} other{{count} Bücher}}'**
  String tagBookCount(int count);

  /// No description provided for @goalTitle.
  ///
  /// In de, this message translates to:
  /// **'Leseziel {year}'**
  String goalTitle(int year);

  /// No description provided for @setGoal.
  ///
  /// In de, this message translates to:
  /// **'Ziel festlegen'**
  String get setGoal;

  /// No description provided for @editGoal.
  ///
  /// In de, this message translates to:
  /// **'Ziel ändern'**
  String get editGoal;

  /// No description provided for @clearGoal.
  ///
  /// In de, this message translates to:
  /// **'Ziel entfernen'**
  String get clearGoal;

  /// No description provided for @goalBooksLabel.
  ///
  /// In de, this message translates to:
  /// **'Anzahl Bücher'**
  String get goalBooksLabel;

  /// No description provided for @noGoalYet.
  ///
  /// In de, this message translates to:
  /// **'Für {year} ist noch kein Ziel gesetzt'**
  String noGoalYet(int year);

  /// No description provided for @goalProgress.
  ///
  /// In de, this message translates to:
  /// **'{completed} von {target} Büchern'**
  String goalProgress(int completed, int target);

  /// No description provided for @goalRemaining.
  ///
  /// In de, this message translates to:
  /// **'Noch {count, plural, =1{1 Buch} other{{count} Bücher}}'**
  String goalRemaining(int count);

  /// No description provided for @goalReached.
  ///
  /// In de, this message translates to:
  /// **'Ziel erreicht!'**
  String get goalReached;

  /// No description provided for @goalOnTrack.
  ///
  /// In de, this message translates to:
  /// **'Genau im Plan'**
  String get goalOnTrack;

  /// No description provided for @goalAhead.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Buch} other{{count} Bücher}} vor dem Plan'**
  String goalAhead(int count);

  /// No description provided for @goalBehind.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Buch} other{{count} Bücher}} hinter dem Plan'**
  String goalBehind(int count);

  /// No description provided for @moveToLibrary.
  ///
  /// In de, this message translates to:
  /// **'In Bestand übernehmen'**
  String get moveToLibrary;

  /// No description provided for @movedToLibrary.
  ///
  /// In de, this message translates to:
  /// **'Zum Bestand hinzugefügt'**
  String get movedToLibrary;

  /// No description provided for @deleteBook.
  ///
  /// In de, this message translates to:
  /// **'In den Papierkorb'**
  String get deleteBook;

  /// No description provided for @deleteBookTitle.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ in den Papierkorb?'**
  String deleteBookTitle(String title);

  /// No description provided for @deleteBookBody.
  ///
  /// In de, this message translates to:
  /// **'Das Buch kann im Papierkorb wiederhergestellt oder endgültig gelöscht werden.'**
  String get deleteBookBody;

  /// No description provided for @bookDeleted.
  ///
  /// In de, this message translates to:
  /// **'Buch im Papierkorb'**
  String get bookDeleted;

  /// No description provided for @addFavorite.
  ///
  /// In de, this message translates to:
  /// **'Zu Favoriten hinzufügen'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In de, this message translates to:
  /// **'Aus Favoriten entfernen'**
  String get removeFavorite;

  /// No description provided for @favoritesFilter.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get favoritesFilter;

  /// No description provided for @sortBy.
  ///
  /// In de, this message translates to:
  /// **'Sortieren'**
  String get sortBy;

  /// No description provided for @sortTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get sortTitle;

  /// No description provided for @sortAuthor.
  ///
  /// In de, this message translates to:
  /// **'Autor'**
  String get sortAuthor;

  /// No description provided for @sortRating.
  ///
  /// In de, this message translates to:
  /// **'Bewertung'**
  String get sortRating;

  /// No description provided for @sortAdded.
  ///
  /// In de, this message translates to:
  /// **'Hinzugefügt am'**
  String get sortAdded;

  /// No description provided for @sortProgress.
  ///
  /// In de, this message translates to:
  /// **'Lese-Fortschritt'**
  String get sortProgress;

  /// No description provided for @sortAscending.
  ///
  /// In de, this message translates to:
  /// **'Aufsteigend'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In de, this message translates to:
  /// **'Absteigend'**
  String get sortDescending;

  /// No description provided for @reviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Rezension'**
  String get reviewTitle;

  /// No description provided for @noReviewYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Rezension'**
  String get noReviewYet;

  /// No description provided for @editReview.
  ///
  /// In de, this message translates to:
  /// **'Rezension bearbeiten'**
  String get editReview;

  /// No description provided for @reviewHint.
  ///
  /// In de, this message translates to:
  /// **'Deine Meinung zum Buch'**
  String get reviewHint;

  /// No description provided for @goalPagesLabel.
  ///
  /// In de, this message translates to:
  /// **'Seitenziel (optional)'**
  String get goalPagesLabel;

  /// No description provided for @goalPagesProgress.
  ///
  /// In de, this message translates to:
  /// **'{read} von {target} Seiten'**
  String goalPagesProgress(int read, int target);

  /// No description provided for @fieldDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get fieldDescription;

  /// No description provided for @coverFromGallery.
  ///
  /// In de, this message translates to:
  /// **'Aus Galerie'**
  String get coverFromGallery;

  /// No description provided for @coverFromCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get coverFromCamera;

  /// No description provided for @coverRemove.
  ///
  /// In de, this message translates to:
  /// **'Cover entfernen'**
  String get coverRemove;

  /// No description provided for @coverPickFailed.
  ///
  /// In de, this message translates to:
  /// **'Bild konnte nicht geladen werden'**
  String get coverPickFailed;

  /// No description provided for @sortModified.
  ///
  /// In de, this message translates to:
  /// **'Geändert am'**
  String get sortModified;

  /// No description provided for @sortPages.
  ///
  /// In de, this message translates to:
  /// **'Seitenzahl'**
  String get sortPages;

  /// No description provided for @sortPublicationYear.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsjahr'**
  String get sortPublicationYear;

  /// No description provided for @sortStatus.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get sortStatus;

  /// No description provided for @sortLastRead.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt gelesen'**
  String get sortLastRead;

  /// No description provided for @sortStartDate.
  ///
  /// In de, this message translates to:
  /// **'Lesebeginn'**
  String get sortStartDate;

  /// No description provided for @sortFinishDate.
  ///
  /// In de, this message translates to:
  /// **'Leseende'**
  String get sortFinishDate;

  /// No description provided for @showAsGrid.
  ///
  /// In de, this message translates to:
  /// **'Rasteransicht'**
  String get showAsGrid;

  /// No description provided for @showAsList.
  ///
  /// In de, this message translates to:
  /// **'Listenansicht'**
  String get showAsList;

  /// No description provided for @yearFilter.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get yearFilter;

  /// No description provided for @allYears.
  ///
  /// In de, this message translates to:
  /// **'Alle Jahre'**
  String get allYears;

  /// No description provided for @bulkSetFormat.
  ///
  /// In de, this message translates to:
  /// **'Format ändern'**
  String get bulkSetFormat;

  /// No description provided for @bulkSetAuthor.
  ///
  /// In de, this message translates to:
  /// **'Autor ändern'**
  String get bulkSetAuthor;

  /// No description provided for @bulkDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'{count} Bücher in den Papierkorb?'**
  String bulkDeleteTitle(int count);

  /// No description provided for @moveToTrash.
  ///
  /// In de, this message translates to:
  /// **'In den Papierkorb'**
  String get moveToTrash;

  /// No description provided for @moveToTrashBody.
  ///
  /// In de, this message translates to:
  /// **'Du kannst die Bücher im Papierkorb wiederherstellen.'**
  String get moveToTrashBody;

  /// No description provided for @movedToTrash.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Buch} other{{count} Bücher}} im Papierkorb'**
  String movedToTrash(int count);

  /// No description provided for @sessionEndDate.
  ///
  /// In de, this message translates to:
  /// **'Leseende (optional)'**
  String get sessionEndDate;

  /// No description provided for @sessionEndDateHint.
  ///
  /// In de, this message translates to:
  /// **'Gleicher Tag – für mehrtägiges Lesen ein Enddatum wählen'**
  String get sessionEndDateHint;

  /// No description provided for @undo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get undo;

  /// No description provided for @skip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get skip;

  /// No description provided for @quickRatingTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie hat dir das Buch gefallen?'**
  String get quickRatingTitle;

  /// No description provided for @olidLabel.
  ///
  /// In de, this message translates to:
  /// **'Open-Library-ID'**
  String get olidLabel;

  /// No description provided for @dateAddedLabel.
  ///
  /// In de, this message translates to:
  /// **'Hinzugefügt'**
  String get dateAddedLabel;

  /// No description provided for @dateModifiedLabel.
  ///
  /// In de, this message translates to:
  /// **'Geändert'**
  String get dateModifiedLabel;

  /// No description provided for @trashTitle.
  ///
  /// In de, this message translates to:
  /// **'Papierkorb'**
  String get trashTitle;

  /// No description provided for @trashEmpty.
  ///
  /// In de, this message translates to:
  /// **'Der Papierkorb ist leer'**
  String get trashEmpty;

  /// No description provided for @restore.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get restore;

  /// No description provided for @deleteForever.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deleteForever;

  /// No description provided for @deleteForeverTitle.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ endgültig löschen?'**
  String deleteForeverTitle(String title);

  /// No description provided for @deleteForeverBody.
  ///
  /// In de, this message translates to:
  /// **'Das Buch wird samt Notizen, Tags und Lesesitzungen unwiderruflich gelöscht.'**
  String get deleteForeverBody;

  /// No description provided for @emptyTrash.
  ///
  /// In de, this message translates to:
  /// **'Papierkorb leeren'**
  String get emptyTrash;

  /// No description provided for @emptyTrashTitle.
  ///
  /// In de, this message translates to:
  /// **'Papierkorb leeren?'**
  String get emptyTrashTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get appearanceSection;

  /// No description provided for @materialYou.
  ///
  /// In de, this message translates to:
  /// **'Material You'**
  String get materialYou;

  /// No description provided for @materialYouHint.
  ///
  /// In de, this message translates to:
  /// **'Systemfarben (Hintergrundbild) verwenden, wo verfügbar'**
  String get materialYouHint;

  /// No description provided for @accentColor.
  ///
  /// In de, this message translates to:
  /// **'Akzentfarbe'**
  String get accentColor;

  /// No description provided for @accentColorDisabledHint.
  ///
  /// In de, this message translates to:
  /// **'Bei Material You nicht verfügbar'**
  String get accentColorDisabledHint;

  /// No description provided for @resetToDefault.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get resetToDefault;

  /// No description provided for @amoledDark.
  ///
  /// In de, this message translates to:
  /// **'AMOLED-Dunkelmodus'**
  String get amoledDark;

  /// No description provided for @amoledDarkHint.
  ///
  /// In de, this message translates to:
  /// **'Reines Schwarz im dunklen Design'**
  String get amoledDarkHint;

  /// No description provided for @fontLabel.
  ///
  /// In de, this message translates to:
  /// **'Schriftart'**
  String get fontLabel;

  /// No description provided for @ratingStyleLabel.
  ///
  /// In de, this message translates to:
  /// **'Bewertung anzeigen als'**
  String get ratingStyleLabel;

  /// No description provided for @ratingAsBar.
  ///
  /// In de, this message translates to:
  /// **'Sterne'**
  String get ratingAsBar;

  /// No description provided for @ratingAsNumber.
  ///
  /// In de, this message translates to:
  /// **'Zahl'**
  String get ratingAsNumber;

  /// No description provided for @listLayoutLabel.
  ///
  /// In de, this message translates to:
  /// **'Ansicht der Bibliothek'**
  String get listLayoutLabel;

  /// No description provided for @displayList.
  ///
  /// In de, this message translates to:
  /// **'Liste'**
  String get displayList;

  /// No description provided for @displayCompactList.
  ///
  /// In de, this message translates to:
  /// **'Kompakte Liste'**
  String get displayCompactList;

  /// No description provided for @displayGrid.
  ///
  /// In de, this message translates to:
  /// **'Raster'**
  String get displayGrid;

  /// No description provided for @displayDetailedGrid.
  ///
  /// In de, this message translates to:
  /// **'Detailliertes Raster'**
  String get displayDetailedGrid;

  /// No description provided for @booksSection.
  ///
  /// In de, this message translates to:
  /// **'Bücher'**
  String get booksSection;

  /// No description provided for @defaultFormat.
  ///
  /// In de, this message translates to:
  /// **'Standardformat'**
  String get defaultFormat;

  /// No description provided for @defaultStatus.
  ///
  /// In de, this message translates to:
  /// **'Standardstatus'**
  String get defaultStatus;

  /// No description provided for @defaultTags.
  ///
  /// In de, this message translates to:
  /// **'Standard-Tags'**
  String get defaultTags;

  /// No description provided for @defaultTagsHint.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine} =1{1 Tag} other{{count} Tags}} für neue Bücher'**
  String defaultTagsHint(int count);

  /// No description provided for @downloadMissingCovers.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Cover laden'**
  String get downloadMissingCovers;

  /// No description provided for @downloadMissingCoversHint.
  ///
  /// In de, this message translates to:
  /// **'Lädt Cover nach, die nur als Link bekannt sind'**
  String get downloadMissingCoversHint;

  /// No description provided for @googleBooksKey.
  ///
  /// In de, this message translates to:
  /// **'Google-Books-API-Key'**
  String get googleBooksKey;

  /// No description provided for @googleBooksKeyNone.
  ///
  /// In de, this message translates to:
  /// **'Nicht gesetzt (gemeinsames Kontingent)'**
  String get googleBooksKeyNone;

  /// No description provided for @googleBooksKeySet.
  ///
  /// In de, this message translates to:
  /// **'Gesetzt (…{suffix})'**
  String googleBooksKeySet(String suffix);

  /// No description provided for @showKey.
  ///
  /// In de, this message translates to:
  /// **'Key anzeigen'**
  String get showKey;

  /// No description provided for @hideKey.
  ///
  /// In de, this message translates to:
  /// **'Key verbergen'**
  String get hideKey;

  /// No description provided for @googleBooksKeyHint.
  ///
  /// In de, this message translates to:
  /// **'Ohne eigenen Key teilen sich alle Nutzer ein Kontingent, das oft ausgeschöpft ist. Leer lassen, um keinen Key zu senden.'**
  String get googleBooksKeyHint;

  /// No description provided for @coversDownloading.
  ///
  /// In de, this message translates to:
  /// **'Cover werden geladen …'**
  String get coversDownloading;

  /// No description provided for @coversNoneMissing.
  ///
  /// In de, this message translates to:
  /// **'Es fehlen keine Cover'**
  String get coversNoneMissing;

  /// No description provided for @coversDownloaded.
  ///
  /// In de, this message translates to:
  /// **'{ok} Cover geladen, {missing} ohne Online-Cover, {failed} nicht erreichbar'**
  String coversDownloaded(int ok, int missing, int failed);

  /// No description provided for @exportJsonHint.
  ///
  /// In de, this message translates to:
  /// **'Vollständiges Backup – lässt sich wiederherstellen'**
  String get exportJsonHint;

  /// No description provided for @exportCsvHint.
  ///
  /// In de, this message translates to:
  /// **'Alle Felder, kompatibel mit dem Openreads-CSV-Import'**
  String get exportCsvHint;

  /// No description provided for @restoreBackupHint.
  ///
  /// In de, this message translates to:
  /// **'Bookstats, OpenShelf-Backup, Openreads, Goodreads, StoryGraph, Bookwyrm …'**
  String get restoreBackupHint;

  /// No description provided for @sourceCode.
  ///
  /// In de, this message translates to:
  /// **'Quellcode'**
  String get sourceCode;

  /// No description provided for @reportIssue.
  ///
  /// In de, this message translates to:
  /// **'Fehler melden'**
  String get reportIssue;

  /// No description provided for @standardColors.
  ///
  /// In de, this message translates to:
  /// **'Standard'**
  String get standardColors;

  /// No description provided for @customColor.
  ///
  /// In de, this message translates to:
  /// **'Eigene Farbe'**
  String get customColor;

  /// No description provided for @finishedBooksByMonth.
  ///
  /// In de, this message translates to:
  /// **'Gelesene Bücher pro Monat'**
  String get finishedBooksByMonth;

  /// No description provided for @finishedPagesByMonth.
  ///
  /// In de, this message translates to:
  /// **'Gelesene Seiten pro Monat'**
  String get finishedPagesByMonth;

  /// No description provided for @averagesTitle.
  ///
  /// In de, this message translates to:
  /// **'Durchschnitte & Rekorde'**
  String get averagesTitle;

  /// No description provided for @averageRating.
  ///
  /// In de, this message translates to:
  /// **'Ø Bewertung'**
  String get averageRating;

  /// No description provided for @averagePages.
  ///
  /// In de, this message translates to:
  /// **'Ø Seitenzahl'**
  String get averagePages;

  /// No description provided for @averageReadingTime.
  ///
  /// In de, this message translates to:
  /// **'Ø Lesezeit'**
  String get averageReadingTime;

  /// No description provided for @longestBook.
  ///
  /// In de, this message translates to:
  /// **'Längstes Buch'**
  String get longestBook;

  /// No description provided for @shortestBook.
  ///
  /// In de, this message translates to:
  /// **'Kürzestes Buch'**
  String get shortestBook;

  /// No description provided for @fastestBook.
  ///
  /// In de, this message translates to:
  /// **'Am schnellsten gelesen'**
  String get fastestBook;

  /// No description provided for @slowestBook.
  ///
  /// In de, this message translates to:
  /// **'Am langsamsten gelesen'**
  String get slowestBook;

  /// No description provided for @pagesValue.
  ///
  /// In de, this message translates to:
  /// **'{count} Seiten'**
  String pagesValue(int count);

  /// No description provided for @openLibrarySearch.
  ///
  /// In de, this message translates to:
  /// **'Open-Library-Suche'**
  String get openLibrarySearch;

  /// No description provided for @olSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Titel, Autor, ISBN oder OLID'**
  String get olSearchHint;

  /// No description provided for @olTypeGeneral.
  ///
  /// In de, this message translates to:
  /// **'Allgemein'**
  String get olTypeGeneral;

  /// No description provided for @olTypeTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get olTypeTitle;

  /// No description provided for @olTypeAuthor.
  ///
  /// In de, this message translates to:
  /// **'Autor'**
  String get olTypeAuthor;

  /// No description provided for @olTypeIsbn.
  ///
  /// In de, this message translates to:
  /// **'ISBN'**
  String get olTypeIsbn;

  /// No description provided for @olTypeOlid.
  ///
  /// In de, this message translates to:
  /// **'OLID'**
  String get olTypeOlid;

  /// No description provided for @olNoResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer'**
  String get olNoResults;

  /// No description provided for @olEditions.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben'**
  String get olEditions;

  /// No description provided for @search.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get search;

  /// No description provided for @lendingHistory.
  ///
  /// In de, this message translates to:
  /// **'Frühere Leihen ({count})'**
  String lendingHistory(int count);

  /// No description provided for @filePickerFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Dateidialog ist nicht verfügbar (unter Linux wird zenity oder kdialog benötigt). Gib den Pfad unten ein.'**
  String get filePickerFailed;

  /// No description provided for @fileNotReadable.
  ///
  /// In de, this message translates to:
  /// **'Die Datei konnte nicht gelesen werden'**
  String get fileNotReadable;

  /// No description provided for @importPathLabel.
  ///
  /// In de, this message translates to:
  /// **'Dateipfad'**
  String get importPathLabel;

  /// No description provided for @importFromPath.
  ///
  /// In de, this message translates to:
  /// **'Aus Pfad laden'**
  String get importFromPath;

  /// No description provided for @genreLabel.
  ///
  /// In de, this message translates to:
  /// **'Genre'**
  String get genreLabel;

  /// No description provided for @priceLabel.
  ///
  /// In de, this message translates to:
  /// **'Preis'**
  String get priceLabel;

  /// No description provided for @receivedAtLabel.
  ///
  /// In de, this message translates to:
  /// **'Erhalten am'**
  String get receivedAtLabel;

  /// No description provided for @readingStartedLabel.
  ///
  /// In de, this message translates to:
  /// **'Lesebeginn'**
  String get readingStartedLabel;

  /// No description provided for @readingFinishedLabel.
  ///
  /// In de, this message translates to:
  /// **'Leseende'**
  String get readingFinishedLabel;

  /// No description provided for @readingTimeLabel.
  ///
  /// In de, this message translates to:
  /// **'Lesezeit'**
  String get readingTimeLabel;

  /// No description provided for @readingDuration.
  ///
  /// In de, this message translates to:
  /// **'{hours} Std. {minutes} Min.'**
  String readingDuration(int hours, int minutes);

  /// No description provided for @daysCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String daysCount(int count);

  /// No description provided for @copyValue.
  ///
  /// In de, this message translates to:
  /// **'{label} kopieren'**
  String copyValue(String label);

  /// No description provided for @fieldGenre.
  ///
  /// In de, this message translates to:
  /// **'Genre'**
  String get fieldGenre;

  /// No description provided for @fieldPrice.
  ///
  /// In de, this message translates to:
  /// **'Preis in Euro'**
  String get fieldPrice;

  /// No description provided for @fieldReceivedAt.
  ///
  /// In de, this message translates to:
  /// **'Erhalten am'**
  String get fieldReceivedAt;

  /// No description provided for @invalidPrice.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen gültigen Preis eingeben, z. B. 12,90'**
  String get invalidPrice;

  /// No description provided for @clearDate.
  ///
  /// In de, this message translates to:
  /// **'Datum entfernen'**
  String get clearDate;

  /// No description provided for @importFieldName.
  ///
  /// In de, this message translates to:
  /// **'{field, select, title{Titel} subtitle{Untertitel} authors{Autor(en)} isbn{ISBN} isbn13{ISBN-13} isbn10{ISBN-10} publisher{Verlag} publishedYear{Erscheinungsjahr} pageCount{Seitenzahl} format{Format} language{Sprache} description{Beschreibung} rating{Bewertung} status{Lesestatus} seriesName{Reihe} seriesVolume{Band} favorite{Favorit} review{Rezension} notes{Notizen} tags{Tags} startDate{Lesebeginn} finishDate{Leseende} readings{Lesungen} dateAdded{Hinzugefügt am} olid{Open-Library-ID} quotes{Zitate} currentPage{Aktuelle Seite} finishedAt{Beendet am} location{Standort} borrower{Verleihen an} lentAt{Verliehen am} expectedReturn{Rückgabe bis} lendingStatus{Verleihstatus} coverUrl{Cover-URL} dateModified{Geändert am} genre{Genre} price{Preis} receivedAt{Erhalten am} durationHours{Lesedauer (Stunden)} durationMinutes{Lesedauer (Minuten)} readingSeconds{Lesezeit (Sekunden)} receivedAs{Erhalten als} other{{field}}}'**
  String importFieldName(String field);

  /// No description provided for @importIgnoreColumn.
  ///
  /// In de, this message translates to:
  /// **'Nicht importieren'**
  String get importIgnoreColumn;

  /// No description provided for @importFormatLabel.
  ///
  /// In de, this message translates to:
  /// **'Importformat'**
  String get importFormatLabel;

  /// No description provided for @importColumnsHint.
  ///
  /// In de, this message translates to:
  /// **'Ordne jede Spalte einem Feld zu. Spalten ohne Zuordnung werden nicht importiert.'**
  String get importColumnsHint;

  /// No description provided for @sessionTimeRead.
  ///
  /// In de, this message translates to:
  /// **'Gelesene Zeit (optional)'**
  String get sessionTimeRead;

  /// No description provided for @sessionTimeReadHint.
  ///
  /// In de, this message translates to:
  /// **'Nur die tatsächliche Lesezeit. Der Zeitraum ergibt sich aus Start- und Enddatum.'**
  String get sessionTimeReadHint;

  /// No description provided for @unitMinutes.
  ///
  /// In de, this message translates to:
  /// **'Minuten'**
  String get unitMinutes;

  /// No description provided for @unitHours.
  ///
  /// In de, this message translates to:
  /// **'Stunden'**
  String get unitHours;

  /// No description provided for @sessionEndPageOptional.
  ///
  /// In de, this message translates to:
  /// **'Bis Seite (optional)'**
  String get sessionEndPageOptional;

  /// No description provided for @readingSpanLabel.
  ///
  /// In de, this message translates to:
  /// **'Lesezeitraum'**
  String get readingSpanLabel;

  /// No description provided for @dataSection.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get dataSection;

  /// No description provided for @clearLibrary.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek leeren'**
  String get clearLibrary;

  /// No description provided for @clearLibraryHint.
  ///
  /// In de, this message translates to:
  /// **'Alle Bücher entfernen; Orte, Tags und Einstellungen bleiben'**
  String get clearLibraryHint;

  /// No description provided for @clearLibraryTitle.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek leeren?'**
  String get clearLibraryTitle;

  /// No description provided for @clearLibraryBody.
  ///
  /// In de, this message translates to:
  /// **'Alle Bücher in den Papierkorb verschieben (wiederherstellbar) oder endgültig löschen?'**
  String get clearLibraryBody;

  /// No description provided for @deleteForeverAllTitle.
  ///
  /// In de, this message translates to:
  /// **'Wirklich endgültig löschen?'**
  String get deleteForeverAllTitle;

  /// No description provided for @deleteForeverAllBody.
  ///
  /// In de, this message translates to:
  /// **'Alle Bücher samt Notizen, Tag-Zuordnungen, Lesesitzungen und Covern, auch im Papierkorb, werden unwiderruflich gelöscht. Exportiere vorher ein Backup, wenn du die Daten behalten willst.'**
  String get deleteForeverAllBody;

  /// No description provided for @libraryTrashed.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Buch in den Papierkorb verschoben} other{{count} Bücher in den Papierkorb verschoben}}'**
  String libraryTrashed(int count);

  /// No description provided for @libraryDeleted.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Buch endgültig gelöscht} other{{count} Bücher endgültig gelöscht}}'**
  String libraryDeleted(int count);

  /// No description provided for @deleteAllData.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataHint.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek, Orte, Tags, Ziele, Cover und Einstellungen'**
  String get deleteAllDataHint;

  /// No description provided for @deleteAllDataTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen?'**
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataBody.
  ///
  /// In de, this message translates to:
  /// **'Alles, was die App lokal speichert, wird unwiderruflich gelöscht: Bücher, Orte, Tags, Lesesitzungen, Ziele, Cover und Einstellungen. Die App selbst bleibt installiert. Exportiere vorher ein Backup, wenn du die Daten behalten willst.'**
  String get deleteAllDataBody;

  /// No description provided for @confirmWord.
  ///
  /// In de, this message translates to:
  /// **'LÖSCHEN'**
  String get confirmWord;

  /// No description provided for @typeToConfirm.
  ///
  /// In de, this message translates to:
  /// **'Tippe „{word}“ zur Bestätigung'**
  String typeToConfirm(String word);

  /// No description provided for @deleteEverything.
  ///
  /// In de, this message translates to:
  /// **'Alles löschen'**
  String get deleteEverything;

  /// No description provided for @allDataDeleted.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten wurden gelöscht'**
  String get allDataDeleted;

  /// No description provided for @selectAll.
  ///
  /// In de, this message translates to:
  /// **'Alle auswählen'**
  String get selectAll;

  /// No description provided for @importColumnN.
  ///
  /// In de, this message translates to:
  /// **'Spalte {n}'**
  String importColumnN(int n);

  /// No description provided for @importNeedsTitle.
  ///
  /// In de, this message translates to:
  /// **'Ordne mindestens eine Spalte dem Titel zu.'**
  String get importNeedsTitle;

  /// No description provided for @importFormatOwnCsv.
  ///
  /// In de, this message translates to:
  /// **'Eigene CSV'**
  String get importFormatOwnCsv;

  /// No description provided for @saveFailed.
  ///
  /// In de, this message translates to:
  /// **'Das Buch konnte nicht gespeichert werden: {error}'**
  String saveFailed(String error);

  /// No description provided for @tagFilterLabel.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Tags} other{Tags ({count})}}'**
  String tagFilterLabel(int count);

  /// No description provided for @filterByTags.
  ///
  /// In de, this message translates to:
  /// **'Nach Tags filtern'**
  String get filterByTags;

  /// No description provided for @tagSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Tag suchen'**
  String get tagSearchHint;

  /// No description provided for @clearTagFilter.
  ///
  /// In de, this message translates to:
  /// **'Auswahl aufheben'**
  String get clearTagFilter;

  /// No description provided for @noMatchingTags.
  ///
  /// In de, this message translates to:
  /// **'Kein passender Tag'**
  String get noMatchingTags;

  /// No description provided for @removeTagFilter.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ entfernen'**
  String removeTagFilter(String name);

  /// No description provided for @importExportHint.
  ///
  /// In de, this message translates to:
  /// **'Bookstats, Backups und CSV importieren oder alle Daten sichern'**
  String get importExportHint;

  /// No description provided for @exportAction.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get exportAction;

  /// No description provided for @exportActionHint.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten als Datei sichern, z. B. vor einem Handywechsel'**
  String get exportActionHint;

  /// No description provided for @importRunning.
  ///
  /// In de, this message translates to:
  /// **'Import läuft …'**
  String get importRunning;

  /// No description provided for @importProgress.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total} Zeilen'**
  String importProgress(int done, int total);

  /// No description provided for @importDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Import abgeschlossen'**
  String get importDoneTitle;

  /// No description provided for @importFailedTitle.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen'**
  String get importFailedTitle;

  /// No description provided for @importAgain.
  ///
  /// In de, this message translates to:
  /// **'Neuer Import'**
  String get importAgain;

  /// No description provided for @importFinish.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get importFinish;

  /// No description provided for @importUnsupportedFormat.
  ///
  /// In de, this message translates to:
  /// **'Das Dateiformat wird nicht erkannt.'**
  String get importUnsupportedFormat;

  /// No description provided for @importAborted.
  ///
  /// In de, this message translates to:
  /// **'Der Import wurde abgebrochen.'**
  String get importAborted;

  /// No description provided for @importPathHint.
  ///
  /// In de, this message translates to:
  /// **'/pfad/zur/datei.csv'**
  String get importPathHint;

  /// No description provided for @fieldReceivedAs.
  ///
  /// In de, this message translates to:
  /// **'Erhalten als'**
  String get fieldReceivedAs;

  /// No description provided for @receivedAsUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get receivedAsUnknown;

  /// No description provided for @receivedAsPurchase.
  ///
  /// In de, this message translates to:
  /// **'Kauf'**
  String get receivedAsPurchase;

  /// No description provided for @receivedAsGift.
  ///
  /// In de, this message translates to:
  /// **'Geschenk'**
  String get receivedAsGift;

  /// No description provided for @receivedAsLoan.
  ///
  /// In de, this message translates to:
  /// **'Leihe'**
  String get receivedAsLoan;

  /// No description provided for @receivedAsReviewCopy.
  ///
  /// In de, this message translates to:
  /// **'Rezensionsexemplar'**
  String get receivedAsReviewCopy;

  /// No description provided for @receivedAsOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get receivedAsOther;

  /// No description provided for @moreActions.
  ///
  /// In de, this message translates to:
  /// **'Weitere Aktionen'**
  String get moreActions;

  /// No description provided for @splitVolumesAction.
  ///
  /// In de, this message translates to:
  /// **'In Bände aufteilen'**
  String get splitVolumesAction;

  /// No description provided for @splitVolumesHint.
  ///
  /// In de, this message translates to:
  /// **'Der Schuber bleibt das physische Objekt mit ISBN, Preis, Standort und Cover. Jeder Band bekommt eigenen Titel, eigene Seiten und eigenen Lesestatus. Sitzungen, Notizen und Rezension wandern zu Band 1.'**
  String get splitVolumesHint;

  /// No description provided for @volumeTitleLabel.
  ///
  /// In de, this message translates to:
  /// **'Titel Band {number}'**
  String volumeTitleLabel(int number);

  /// No description provided for @volumePagesLabel.
  ///
  /// In de, this message translates to:
  /// **'Seiten'**
  String get volumePagesLabel;

  /// No description provided for @addVolume.
  ///
  /// In de, this message translates to:
  /// **'Band hinzufügen'**
  String get addVolume;

  /// No description provided for @removeVolume.
  ///
  /// In de, this message translates to:
  /// **'Band entfernen'**
  String get removeVolume;

  /// No description provided for @splitVolumesSave.
  ///
  /// In de, this message translates to:
  /// **'Aufteilen'**
  String get splitVolumesSave;

  /// No description provided for @splitVolumesFailed.
  ///
  /// In de, this message translates to:
  /// **'Aufteilen fehlgeschlagen'**
  String get splitVolumesFailed;

  /// No description provided for @volumesTitle.
  ///
  /// In de, this message translates to:
  /// **'Bände'**
  String get volumesTitle;

  /// No description provided for @volumesReadProgress.
  ///
  /// In de, this message translates to:
  /// **'{read} von {total} gelesen'**
  String volumesReadProgress(int read, int total);

  /// No description provided for @partOfSlipcase.
  ///
  /// In de, this message translates to:
  /// **'Teil von „{title}“'**
  String partOfSlipcase(String title);

  /// No description provided for @volumeCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Band} other{{count} Bände}}'**
  String volumeCount(int count);

  /// No description provided for @trashedWithVolumes.
  ///
  /// In de, this message translates to:
  /// **'mit {count, plural, =1{1 Band} other{{count} Bänden}}'**
  String trashedWithVolumes(int count);

  /// No description provided for @showVolumes.
  ///
  /// In de, this message translates to:
  /// **'Bände anzeigen'**
  String get showVolumes;

  /// No description provided for @hideVolumes.
  ///
  /// In de, this message translates to:
  /// **'Bände ausblenden'**
  String get hideVolumes;

  /// No description provided for @addScanTitle.
  ///
  /// In de, this message translates to:
  /// **'ISBN scannen'**
  String get addScanTitle;

  /// No description provided for @addScanHint.
  ///
  /// In de, this message translates to:
  /// **'Barcode mit der Kamera erfassen, auch mehrere nacheinander'**
  String get addScanHint;

  /// No description provided for @addSearchTitle.
  ///
  /// In de, this message translates to:
  /// **'Online suchen'**
  String get addSearchTitle;

  /// No description provided for @addSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Nach Titel oder Autor bei Open Library suchen'**
  String get addSearchHint;

  /// No description provided for @addManualTitle.
  ///
  /// In de, this message translates to:
  /// **'Manuell eingeben'**
  String get addManualTitle;

  /// No description provided for @addManualHint.
  ///
  /// In de, this message translates to:
  /// **'Alle Angaben selbst ausfüllen'**
  String get addManualHint;

  /// No description provided for @formatHardcover.
  ///
  /// In de, this message translates to:
  /// **'Hardcover'**
  String get formatHardcover;

  /// No description provided for @formatPaperback.
  ///
  /// In de, this message translates to:
  /// **'Taschenbuch'**
  String get formatPaperback;

  /// No description provided for @formatEbook.
  ///
  /// In de, this message translates to:
  /// **'E-Book'**
  String get formatEbook;

  /// No description provided for @formatAudiobook.
  ///
  /// In de, this message translates to:
  /// **'Hörbuch'**
  String get formatAudiobook;

  /// No description provided for @formatUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get formatUnknown;

  /// No description provided for @editStagedTitle.
  ///
  /// In de, this message translates to:
  /// **'Erfasstes Buch bearbeiten'**
  String get editStagedTitle;

  /// No description provided for @removeStaged.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get removeStaged;

  /// No description provided for @sharedValuesTitle.
  ///
  /// In de, this message translates to:
  /// **'Für alle übernehmen'**
  String get sharedValuesTitle;

  /// No description provided for @sharedValuesHint.
  ///
  /// In de, this message translates to:
  /// **'Diese Angaben bekommen alle erfassten Bücher beim Speichern.'**
  String get sharedValuesHint;

  /// No description provided for @apply.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get apply;

  /// No description provided for @pageCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Seite} other{{count} Seiten}}'**
  String pageCount(int count);

  /// No description provided for @coverSearchOnline.
  ///
  /// In de, this message translates to:
  /// **'Online suchen'**
  String get coverSearchOnline;

  /// No description provided for @coverSearchTitle.
  ///
  /// In de, this message translates to:
  /// **'Cover online suchen'**
  String get coverSearchTitle;

  /// No description provided for @coverSearchEmpty.
  ///
  /// In de, this message translates to:
  /// **'Kein Cover online gefunden. Du kannst eins fotografieren oder aus der Galerie wählen.'**
  String get coverSearchEmpty;

  /// No description provided for @coverSearchOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Bitte später erneut versuchen.'**
  String get coverSearchOffline;

  /// No description provided for @completeOnline.
  ///
  /// In de, this message translates to:
  /// **'Online vervollständigen'**
  String get completeOnline;

  /// No description provided for @completeOnlineHint.
  ///
  /// In de, this message translates to:
  /// **'Ohne ISBN findet die App weder Cover noch Daten. Such das Buch online, um sie zu ergänzen.'**
  String get completeOnlineHint;

  /// No description provided for @withoutCoverFilter.
  ///
  /// In de, this message translates to:
  /// **'Ohne Cover'**
  String get withoutCoverFilter;

  /// No description provided for @show.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get show;

  /// No description provided for @durationDh.
  ///
  /// In de, this message translates to:
  /// **'{days} T. {hours} Std.'**
  String durationDh(int days, int hours);

  /// No description provided for @durationSec.
  ///
  /// In de, this message translates to:
  /// **'{seconds} Sek.'**
  String durationSec(int seconds);

  /// No description provided for @statsSectionOverview.
  ///
  /// In de, this message translates to:
  /// **'Überblick'**
  String get statsSectionOverview;

  /// No description provided for @statsSectionReading.
  ///
  /// In de, this message translates to:
  /// **'Lesen'**
  String get statsSectionReading;

  /// No description provided for @statsSectionRecords.
  ///
  /// In de, this message translates to:
  /// **'Durchschnitt & Rekorde'**
  String get statsSectionRecords;

  /// No description provided for @statsSectionLibrary.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek'**
  String get statsSectionLibrary;

  /// No description provided for @addedBooksByMonth.
  ///
  /// In de, this message translates to:
  /// **'Hinzugefügte Bücher pro Monat'**
  String get addedBooksByMonth;

  /// No description provided for @unreadStackByMonth.
  ///
  /// In de, this message translates to:
  /// **'Ungelesen-Stapel am Monatsende'**
  String get unreadStackByMonth;

  /// No description provided for @spendingByYear.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben pro Jahr'**
  String get spendingByYear;

  /// No description provided for @showInLibrary.
  ///
  /// In de, this message translates to:
  /// **'In Bibliothek zeigen'**
  String get showInLibrary;

  /// No description provided for @selectionFilter.
  ///
  /// In de, this message translates to:
  /// **'Auswahl ({count})'**
  String selectionFilter(int count);

  /// No description provided for @navHome.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get navHome;

  /// No description provided for @homeRecentlyAdded.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt hinzugefügt'**
  String get homeRecentlyAdded;

  /// No description provided for @homeCurrentlyReading.
  ///
  /// In de, this message translates to:
  /// **'Gerade am Lesen'**
  String get homeCurrentlyReading;

  /// No description provided for @homeUnreadTrend.
  ///
  /// In de, this message translates to:
  /// **'Ungelesen-Stapel, letzte 6 Monate'**
  String get homeUnreadTrend;

  /// No description provided for @homeEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bücher. Tippe in der Bibliothek auf +, um loszulegen.'**
  String get homeEmpty;

  /// No description provided for @scanSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen. Prüfe den Standort und versuche es erneut.'**
  String get scanSaveFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
