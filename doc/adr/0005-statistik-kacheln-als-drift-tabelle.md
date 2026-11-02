# ADR-0005: Eigene Statistiken als Drift-Tabelle `stat_tiles` mit JSON-Definition

- **Status:** Angenommen
- **Datum:** 2026-11-02
- **Entscheider:** Projektinhaber (Spec 005)

## Kontext
Spec 005 erlaubt eigene Statistik-Kacheln. Eine Kachel kombiniert eine Messgröße (z. B. gelesene Seiten), eine Gruppierung (z. B. Monat), einen Zeitraum, eine Darstellung und Filter (Status, Buchart, Tags). Die Kacheln brauchen:
- eine Reihenfolge,
- das Anpinnen auf die Startseite (höchstens 3),
- einen Weg durch das JSON-Backup (FR-05-09),
- Robustheit, wenn spätere Versionen neue Messgrößen hinzufügen.

## Betrachtete Optionen
1. **A: Drift-Tabelle `stat_tiles`** (id, position, title, definition als JSON, pinned, created_at).
2. **B: Ein Settings-Key mit einer JSON-Liste aller Kacheln.** Kommt ohne Schemaänderung aus. Dafür wird bei jeder Änderung die ganze Liste neu geschrieben, sie ist leichter zu beschädigen, und Settings sind nicht Teil jedes Backup-Wegs.
3. **C: Ein normalisiertes Schema** mit einer Spalte je Feld und Filtertabellen. Jede neue Messgröße oder jeder neue Filter bräuchte eine Migration.

## Entscheidung
Option A. Die Definition wird als JSON-Text mit **stabilen Codes** gespeichert, also `pages_read` statt Enum-Namen. Sie wird am Rand validiert (`StatDefinition.tryDecode`):
- Eine Kachel mit unbekanntem Code oder kaputtem JSON wird ausgeblendet und belegt keinen Startseiten-Platz. Die übrigen Kacheln bleiben sichtbar.
- Unbekannte Filterwerte werden verworfen, die Kachel bleibt erhalten.
- Das Limit von 3 angepinnten Kacheln setzt das Repository in einer Transaktion durch.
- Im Backup reisen Tag-Filter über den Tag-Namen, denn Tag-IDs unterscheiden sich zwischen Bibliotheken. Beim Restore werden die Kacheln hinten angehängt, identische Kacheln übersprungen, und Pins bleiben innerhalb der 3 Plätze.
- Die Auswertung (`StatQuery`) ist rein und frameworkfrei. Für Lese-Messgrößen nutzt sie `ShelfPartition` (ADR-0003).

## Konsequenzen
- Schema v7: eine neue Tabelle, nicht destruktiv, mit Migrationstest v6 → v7.
- Eine neue Messgröße oder Gruppierung braucht nur einen neuen Code und keine Migration.
- Ältere App-Versionen blenden Kacheln aus neueren Versionen aus, statt abzustürzen.
- Der CSV-Export enthält keine Kacheln, weil er nur Buchdaten führt. JSON- und SQLite-Export enthalten sie.
- Die Drift-Datenklasse heißt `StatTileRow`, damit `StatTile` das Domänenmodell mit geparster Definition bleibt.

## Rückbau
Tabelle `stat_tiles` per Migration leeren oder entfernen. Bücher und andere Daten hängen nicht von ihr ab.
