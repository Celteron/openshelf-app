# ADR-0007: Regalwand mit abgeleiteten Rückenfarben

- **Status:** Angenommen
- **Datum:** 2026-11-02
- **Entscheider:** Projektinhaber, nach Bewertung durch den Architect-Agenten

## Kontext
Der Tab „Regal“ zeigte einen Textbaum (Raum, Regal, Fach). Gewünscht ist ein Bild des echten Regals: pro Fach eine Reihe Buchrücken, Suche mit Hervorhebung, Verschieben per Ziehen (Spec 006, P7). Die Rückenfarbe soll vom Cover kommen. Die Bibliothek kann 500 bis 3000 Bücher haben, viele ohne Cover.

## Optionen
1. **A: Den Baum um Farbbalken erweitern.** Klein, erfüllt das Ziel aber nicht.
2. **B: Reine Layout-Schicht (`ShelfWall`) plus Widget-Wand, eine Zeile pro Fach, lazy.** Drag, Semantics und Tap kommen von Flutter.
3. **C: Ein `CustomPainter` pro Fach.** Schneller zu zeichnen, aber Hit-Test, Semantics und Drag müssten selbst gebaut werden (Verfassung V.3 wäre schwer einzuhalten).

## Entscheidung
Option B.

- **Domain (rein, ohne Flutter):** `ShelfWall.build` (Zeilen, Reihenfolge, Breiten, Offsets), `spine_color.dart` (Platzhalterfarbe aus FNV-1a des Titels, Farbwahl aus RGBA, Kontrastfarbe), `findOnShelf` (Suche mit Umlaut-Faltung).
- **Rückenfarbe wird nie gespeichert** (FR-R2-10: abgeleitete Daten bekommen keine Spalte). `SpineColorService` liest sie lazy, wenn ein Rücken sichtbar wird: Die Engine verkleinert beim Dekodieren (`targetWidth: 12`), höchstens zwei Jobs gleichzeitig, Speicher-Cache (LRU, 4000 Einträge) mit Pfad und Änderungszeit als Schlüssel. Ohne Cover oder ohne verwertbare Farbe gilt die Titelfarbe.
- **Rücken sind mindestens 48 dp breit** (Verfassung V.3), höchstens 96 dp. Auf einem Handy stehen deshalb etwa sieben Rücken nebeneinander. Das ist bewusst so entschieden.
- Der Standort gehört zum Schuber (ADR-0003). Bände lassen sich nicht einzeln verschieben.
- Verschieben geht per Ziehen (mit Kantenscroll, Rückgängig) und über eine Aktion für Screenreader und Rechtsklick, die eine Liste der Orte öffnet.
- Der Tab wird erst beim ersten Besuch gebaut, weil der `IndexedStack` sonst schon beim Start alle Bücher layoutet. Der alte Standortbaum bleibt über „Standorte verwalten“ erreichbar.

## Konsequenzen
- Die Farbe über die Engine ist auf dem Gerät mit 3000 Covern noch nicht gemessen. Fällt sie dort zu langsam aus, bleibt die Signatur `colorFor` gleich, und die Implementierung wechselt auf `image` mit `Isolate.run`.
- Keine manuelle Reihenfolge im Fach: Sie wäre eine neue Spalte. Die Ordnung ist abgeleitet (Autor, Band, Titel).
- Ziehen innerhalb sehr langer Reihen scrollt nicht an den Seitenrändern. Wer weit verschieben will, nimmt die Aktion mit der Liste.

## Rückbau
`ShelfWallScreen` im Tab durch `LocationTreeScreen` ersetzen. Die Domain-Dateien und der Service sind danach ungenutzt und können gelöscht werden. Es gibt keine Datenmigration.
