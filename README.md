# OpenShelf

Offline-first Bücher-App für die **physische Bibliothek**: Was lese ich, habe ich das schon, und wo steht es? Kein Konto, keine Telemetrie, Netzzugriff nur auf Nutzeraktion (Cover- und Metadatensuche).

OpenShelf ist ein Fork von [Openreads](https://github.com/mateusz-bak/openreads) (Mateusz Bąk) und steht wie dieser unter der GPL-2.0 ([ADR-0001](doc/adr/0001-lizenz-gpl-2-0.md)).

## Funktionen

- **Bibliothek:** Räume, Regale und Fächer, Schuber mit Einzelbänden, Reihen, Tags, Leihen, Papierkorb
- **Regalwand:** Bücherrücken in Cover-Farben, Suche, Verschieben per Drag-and-drop
- **Scannen:** Barcode oder Cover-Foto; „Habe ich das schon?“ im Laden mit Reihen-Lücken, Wunsch- und Einkaufsliste
- **Lesen:** Lesesitzungen, Ziele, Notizen und Zitate, Zitat aus Foto mit freier Offline-Texterkennung (Tesseract)
- **Auswertung:** Statistiken mit eigenen Kacheln, Lesekalender als Heatmap, Jahresrückblick als Bild
- **Daten:** Export und Import (CSV), alles lokal in einer Drift/SQLite-Datenbank
- **Startseite** nach Wunsch anpassbar, Deutsch und Englisch

Metadaten kommen aus DNB, Google Books und Open Library, in dieser Reihenfolge. Nutzerbearbeitungen werden nie überschrieben.

## Entwickeln

```bash
flutter pub get
flutter run -d linux            # Desktop-Entwicklung
dart format lib test            # CI: dart format --set-exit-if-changed lib test
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # nach Drift-Änderungen
flutter gen-l10n                # nach Änderungen an lib/l10n/*.arb
```

Die Flutter-Version steht in [`.flutter-version`](.flutter-version). APK bauen:

```bash
flutter build apk --release --dart-define=GOOGLE_BOOKS_API_KEY="$GOOGLE_BOOKS_API_KEY"
```

Der Google-Books-Key ist optional und gehört nie ins Repo. Release-Builds werden ohne eigene `android/key.properties` mit dem Debug-Key signiert; Updates lassen sich nur mit demselben Key einspielen.

Arbeitsweise: Spezifikationen unter [`specs/`](specs) (Spec Kit), Entscheidungen unter [`doc/adr/`](doc/adr), Regeln in [`.specify/memory/constitution.md`](.specify/memory/constitution.md). Beiträge: [CONTRIBUTING.md](CONTRIBUTING.md).

## Freie Software und F-Droid

Ziel ist eine Veröffentlichung bei F-Droid. Noch proprietär sind der ML-Kit-Dokumentenscanner und die Barcode-Erkennung sowie die optionale Google-Books-API; der Stand und der Weg dorthin stehen in [ADR-0006](doc/adr/0006-freie-texterkennung-und-fdroid-ziel.md).

## Danksagung

Openreads von Mateusz Bąk und den Mitwirkenden, Icons von [Font Awesome](https://fontawesome.com/), Schriften und Lizenzen unter [`doc/licences/`](doc/licences).
