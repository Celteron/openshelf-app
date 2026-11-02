# ADR-0004: Kompakte Cover-Speicherung

- **Status:** Angenommen
- **Datum:** 2026-11-01
- **Entscheider:** Projektinhaber

## Kontext
Cover-Dateien belegen den Großteil des Speichers der App, weit mehr als die Datenbank. Bisher werden heruntergeladene Cover unverändert gespeichert. Nur Kamera-Fotos werden auf 1200 px Breite bei JPEG q85 verkleinert. Der Projektinhaber verlangt eine möglichst platzsparende Speicherung (FR-R2-10), die dennoch gut aussieht.

## Optionen
1. **A: Eine Größe**, eingepasst in 720×1080 px, JPEG q82. Alle Schreibwege laufen über `CoverCacheService`.
2. **B: Zwei Größen** (Liste und Detail). Kostet 10–15 % mehr Speicher und zwei Schreibwege. Die Liste lässt sich ebenso gut über `cacheWidth` beim Dekodieren verkleinern.
3. **C: WebP.** Das `image`-Paket hat keinen verlustbehafteten WebP-Encoder. Das bräuchte eine neue native Abhängigkeit.

## Entscheidung
Option A. Der Projektinhaber wünscht etwas mehr Qualität als die 600 px aus dem Architektur-Vorschlag. 720 px reichen auch in der Detailansicht hochauflösender Handys.

- Ein einziger Engpass: `CoverCacheService._write` → `compactCover`.
  - Was schon klein genug ist (innerhalb der Box und höchstens 100 KB), bleibt byte-gleich. So entsteht kein Generationsverlust.
  - Was sich nicht dekodieren lässt, ist kein Cover.
  - Wird das neu kodierte Ergebnis größer, bleibt das Original.
- Ein einmaliger Hintergrundlauf verkleinert die vorhandenen Dateien an Ort und Stelle (Temp-Datei, dann atomares Umbenennen). Er ist idempotent und wird über einen Einstellungsschlüssel gesteuert. Auch eigene Fotos werden verkleinert (Entscheidung des Projektinhabers).
- Ein Export inklusive Cover ist ein eigener, späterer Punkt (FR-R2-21).

## Konsequenzen
- Erwartet werden etwa 60–100 KB statt 150–300 KB pro Cover. Das ist geschätzt, nicht gemessen.
- Bereits verkleinerte eigene Fotos lassen sich nicht wiederherstellen.

## Rückbau
Die Konstanten in `compactCover` anheben. Neue Cover werden dann größer gespeichert. Heruntergeladene Cover lassen sich über „Fehlende Cover laden“ nach dem Löschen der Dateien neu laden.
