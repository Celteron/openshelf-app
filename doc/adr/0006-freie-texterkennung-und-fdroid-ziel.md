# ADR-0006: Freie Texterkennung und der Weg zu F-Droid

- **Status:** Angenommen
- **Datum:** 2026-11-02
- **Entscheider:** Projektinhaber

## Kontext
Zitate sollen sich von einem Foto der Buchseite einlesen lassen (Spec 006, P6). Der Projektinhaber will die App langfristig bei F-Droid veröffentlichen, deshalb darf die neue Funktion keine proprietäre Abhängigkeit mitbringen. ML Kit Text Recognition (Google) scheidet aus.

Ein Stand der proprietären Teile, die F-Droid heute beanstanden würde:

| Teil | Wofür | Status |
|---|---|---|
| `google_mlkit_document_scanner` | Cover-Zuschnitt (ADR-0002) | proprietär, bleibt vorerst |
| `mobile_scanner` mit ML Kit Barcode | ISBN-Scanner | proprietär, bleibt vorerst |
| Google Books API | Metadaten und Cover (nur Web-API, keine Bibliothek) | bleibt, bis es eine Lösung gibt |

Die Einträge dieser Tabelle ändern sich mit diesem ADR nicht. Sie sind die Arbeitsliste für den Weg zu F-Droid.

## Optionen
1. **A: Flutter-Plugin `tesseract_ocr` (BSD-3, Tesseract4Android).** Scheitert an Gradle 9 und AGP 9: Das Plugin ruft `jcenter()` auf (in Gradle 9 entfernt) und wendet `kotlin-android` an. Geprüft am 2026-11-02, der Build bricht ab.
2. **B: Tesseract4Android (Apache-2.0) direkt, mit eigenem Platform-Channel.** Rund 60 Zeilen Kotlin (`MainActivity.kt`) und ein Dart-Wrapper. Kein fremdes Flutter-Plugin, das gepflegt werden müsste.
3. **C: PaddleOCR über ONNX oder NCNN.** Genauer, aber die Flutter-Plugins sind jung und teils nur für einzelne Plattformen. Die Lizenz der Modelle ist ungeprüft.

## Entscheidung
Option B. Die Texterkennung sitzt hinter `TextRecognizer` (Domain). Die Engine lässt sich tauschen, falls Option C später besser ist.

- Sprachdaten: `deu` und `eng` aus `tessdata_fast` (Apache-2.0), zusammen 5,6 MB, als Assets in der App. Es gibt keinen Modell-Download, die Funktion arbeitet offline (Verfassung I.1, I.2).
- Das Foto liegt nur für die Dauer der Erkennung als Datei vor und wird danach gelöscht. Das Ergebnis ist Text im Notizdialog, den der Nutzer vor dem Speichern bearbeitet.
- Die Funktion gibt es nur unter Android. Anderswo fehlt der Button.

## Bewertung der Abhängigkeit
- **Warum der Stack nicht reicht:** Weder Flutter noch `image` lesen Text aus Bildern.
- **Pflege:** Tesseract4Android ist aktiv gepflegt (4.9.0). Tesseract selbst ist ein etabliertes Projekt.
- **Lizenz:** Tesseract4Android, Tesseract und tessdata_fast stehen unter Apache-2.0. Das Projekt ist GPL-2.0-only (ADR-0001), und die FSF hält Apache-2.0 und GPLv2 nicht für kombinierbar. Das ist kein neuer Fall: Jede Android-App bringt Apache-2.0-Bibliotheken mit (AndroidX, Flutter-Engine-Abhängigkeiten). **Offen:** Vor einer F-Droid-Veröffentlichung braucht das Projekt eine Lizenzprüfung über alle Abhängigkeiten, nicht nur für diese. Für die persönliche Installation unkritisch.
- **Quelle:** Die Bibliothek kommt von JitPack (nur dieser Gruppe zugelassen, `includeGroup`). F-Droid baut Abhängigkeiten aus dem Quellcode. JitPack-Artefakte müssten dort geprüft werden.
- **Größe:** etwa 4 MB native Bibliotheken pro ABI plus 5,6 MB Modelle.
- **Qualität:** Auf echten Seitenfotos noch nicht gemessen. Tesseract liefert bei gutem Licht und gerader Seite brauchbare Ergebnisse, bei gebogenen Seiten und Schatten deutlich schlechter.

## Konsequenzen
- Eine neue native Abhängigkeit und eine Zeile in `android/build.gradle` (JitPack, beschränkt auf eine Gruppe).
- Die Lizenzprüfung (Apache-2.0 und GPL-2.0-only) steht vor einer F-Droid-Veröffentlichung an.

## Rückbau
`TextRecognizer`-Provider in `main.dart` entfernen: Dann verschwindet der Foto-Button. Danach `MainActivity.kt`, die Gradle-Zeilen und `assets/tessdata` löschen.
