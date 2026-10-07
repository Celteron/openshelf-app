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

  /// No description provided for @navImport.
  ///
  /// In de, this message translates to:
  /// **'Import'**
  String get navImport;

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

  /// No description provided for @isbn13Label.
  ///
  /// In de, this message translates to:
  /// **'ISBN-13'**
  String get isbn13Label;

  /// No description provided for @isbn10Label.
  ///
  /// In de, this message translates to:
  /// **'ISBN-10'**
  String get isbn10Label;

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

  /// No description provided for @importTitle.
  ///
  /// In de, this message translates to:
  /// **'Import'**
  String get importTitle;

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

  /// No description provided for @rowsProcessed.
  ///
  /// In de, this message translates to:
  /// **'{count} Zeilen verarbeitet'**
  String rowsProcessed(int count);

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

  /// No description provided for @exportLabel.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get exportLabel;

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
  /// **'GPL-3.0'**
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
