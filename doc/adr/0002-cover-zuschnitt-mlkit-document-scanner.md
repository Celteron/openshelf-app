# ADR-0002: Cover-Zuschnitt mit dem ML Kit Document Scanner

- **Status:** Angenommen (persönliche Sideload-Installation)
- **Datum:** 2026-11-01
- **Entscheider:** Projektinhaber

## Kontext
Fehlt ein Cover, fotografiert man es mit der Kamera (T3-23). Ein Foto ohne Zuschnitt enthält Tisch, Hände und Hintergrund, und meist ist es schräg aufgenommen. Gewünscht ist ein vertrauter, gut bedienbarer Zuschnitt, der das Cover möglichst selbst erkennt und als Vorschlag anbietet. Die Nutzerin passt ihn bei Bedarf an.

Der Stack bot das nicht. `image_picker` liefert nur das Rohfoto, und `image_cropper` wurde als ungenutztes Upstream-Plugin entfernt. Auch mit `image_cropper` gäbe es nur ein Rechteck ohne Erkennung und ohne Entzerrung.

## Betrachtete Optionen
1. **A: `google_mlkit_document_scanner` (ML Kit Document Scanner über Google Play-Dienste)**
   - Erkennt automatisch die Kanten, die Ecken lassen sich ziehen.
   - Perspektivkorrektur, Drehen, Galerie-Import.
   - Oberfläche wie beim Scannen in Google Drive.
2. **B: `image_cropper` (uCrop)**
   - Vertrauter Rechteck-Zuschnitt, aber keine Erkennung und keine Entzerrung.
   - Bringt eine eigene Activity und ein AppCompat-Theme mit.
3. **C: Eigener Zuschnitt-Screen mit dem `image`-Paket**
   - Keine neue Abhängigkeit.
   - Die Erkennung (Kanten, Perspektive) wäre Eigenbau, aufwendig und schlechter.

## Entscheidung
Option A. Nur A erfüllt die Anforderung „erkennt das Cover selbst, sonst Nutzereingabe“. Die Verarbeitung läuft auf dem Gerät.

Umsetzung:
- `ScannerCoverPicker` implementiert das bestehende `CoverPicker`-Interface. Nur der Kamera-Button nutzt den Scanner.
- Die Galerie und Geräte ohne Scanner nutzen weiter `image_picker`.
- Modus `base` (Zuschnitt und Drehen, keine Farbfilter, die ein Cover verfälschen würden).
- Ergebnisse werden wie bisher auf 1200 px verkleinert (`shrinkCover`).

## Bewertung der Abhängigkeit
- **Warum der Stack nicht reicht:** Weder `image_picker` noch `image` erkennen Kanten oder entzerren Fotos.
- **Pflege:** Publisher flutter-ml.dev, Version 0.6.1 vom 2026-08, aktiv gepflegt. Das ist dieselbe Familie wie die ML-Kit-Plugins der Community.
- **Lizenz:** Das Plugin steht unter MIT und ist GPL-2.0-kompatibel. Die eingebundene Bibliothek `play-services-mlkit-document-scanner` ist dagegen proprietär (Google APIs Terms). Für die persönliche Installation ist das akzeptabel. Für F-Droid oder einen streng GPL-konformen Vertrieb ist es das nicht. `mobile_scanner` bindet mit ML Kit Barcode schon heute proprietären Code ein, das Problem besteht also bereits.
- **Größe:** gering, weil das Scanner-Modul über die Play-Dienste kommt und nicht in der APK liegt.
- **Privacy (Constitution I.2) – bewusste Abweichung:**
  - Die Bilder werden auf dem Gerät verarbeitet.
  - Laut Googles ML-Kit-Datenhinweisen kontaktieren die ML-Kit-APIs jedoch Google-Server für Modell-Downloads und Updates. Außerdem senden sie Nutzungs- und Performance-Metriken. Das ist Telemetrie eines Dritten und weicht damit von I.2 ab, ebenso wie der proprietäre Code von VII.
  - Für die persönliche Installation ist diese Abweichung nach Governance §3 ausdrücklich akzeptiert.
  - Dasselbe gilt seit Phase 1 schon für `mobile_scanner` (ML Kit Barcode).
  - Vor einem öffentlichen oder F-Droid-Vertrieb müssen beide ML-Kit-Abhängigkeiten neu bewertet werden.

## Konsequenzen
- **Positiv:**
  - Automatischer Zuschnittsvorschlag, die Ecken sind korrigierbar.
  - Schräge Fotos werden gerade.
  - Bekannte Google-Oberfläche.
- **Negativ:**
  - Braucht die Google Play-Dienste. Ohne sie greift der Fallback mit Rohfoto ohne Zuschnitt.
  - Nur auf Android. Unter iOS bleibt `image_picker`.
- **Rückbauweg:**
  - `google_mlkit_document_scanner` aus `pubspec.yaml` entfernen.
  - `platformCoverPicker()` gibt dann immer `ImagePickerCoverPicker` zurück.
  - `ScannerCoverPicker` und `scanCoverWithMlKit` löschen. Screens und Tests hängen nur am Interface `CoverPicker`.
