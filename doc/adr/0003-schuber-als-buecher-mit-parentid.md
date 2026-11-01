# ADR-0003: Schuber als Bücher mit `parentId`

- **Status:** Angenommen
- **Datum:** 2026-11-01
- **Entscheider:** Projektinhaber, nach Architektur-Review

## Kontext
Ein Schuber (Box-Set) ist bisher ein einziges Buch. Mit der Gesamtseitenzahl verfälscht er Durchschnitte und Rekorde. In der Bookstats-Bibliothek ist ein Schuber mit 1184 Seiten das „längste Buch“. Gewünscht ist (FR-R2-09):
- Ein Schuber ist ein Behälter für Einzelbände.
- Das physische Objekt (ISBN, Preis, „erhalten als/am“, Standort, Cover) gehört zum Schuber.
- Jeder Band ist ein normales Buch mit eigenen Seiten, eigenem Status und eigenen Lesedaten.
- Statistiken zählen Bände; der Preis zählt einmal.

## Betrachtete Optionen
1. **A: Selbstreferenz `Books.parentId` (nullable, `ON DELETE SET NULL`), ohne Markierungsspalte.** Ein Buch ist genau dann Schuber, wenn es Kinder hat.
2. **B: Eigene Tabelle `Slipcases`.** Doppelt alle physischen Spalten, die Cover-Pipeline, die ISBN-Suche, Tags und Verleih. Die Bibliothek müsste zwei Typen listen.
3. **C: Reihen (`Series`) wiederverwenden.** Eine Reihe ist logisch und hat keine ISBN, keinen Preis und keinen Standort.
4. **D: A plus Spalte `isSlipcase`.** Abgeleitet und kann den echten Kindern widersprechen. Das widerspricht FR-R2-10 (keine abgeleiteten Spalten).

## Entscheidung
Option A, mit genau einer Ebene. Die Tiefe erzwingt das Repository: Der Elternteil hat selbst keinen Elternteil, und ein Band hat keine Kinder.

- **Statistiken** trennen zwei Mengen über ein reines Domänenmodul (`ShelfPartition`):
  - *readable* = Einzelbücher und Bände. Grundlage für Lese-Statistik, Ziel und Startseite.
  - *physical* = alles mit `parentId == null`. Grundlage für Ausgaben, „erhalten als“ und Standorte.
- **Status eines Schubers** wird aus den Bänden abgeleitet (reine Funktion). Eine Mischung aus gelesen und ungelesen gilt als „am Lesen“. Dazu wird „x von n gelesen“ angezeigt (Entscheidung des Projektinhabers).
- **Aufteilen** ist eine Transaktion:
  - Die Bände übernehmen Autoren, Verlag, Buchart, Status, Enddatum und Bewertung.
  - Sitzungen, Notizen, Rezension und `readingSeconds` wandern zu Band 1 (Entscheidung des Projektinhabers).
  - Die Lesefelder des Schubers werden zurückgesetzt.
- **Papierkorb:** Wird ein Schuber verworfen, bekommen seine aktiven Bände dasselbe `deletedAt`. Ein aktiver Band impliziert einen aktiven Schuber.
- **Export/Import:**
  - JSON und eigenes CSV exportieren die dateilokale `id` und `parentId`/`slipcase_id`.
  - Der Import löst die Beziehung über eine Id-Zuordnung auf, die über alle Batches gilt.
  - Lässt sich der Elternteil nicht auflösen, wird der Band als Einzelbuch importiert und mit einer Warnung gemeldet.
  - Der Titelabgleich gegen Duplikate gilt nur innerhalb desselben Elternteils.

## Konsequenzen
- **Speicher:** eine nullable INTEGER-Spalte. Bei NULL kostet sie nur das Header-Byte.
- Status-, Standort- und Suchfilter der Bibliothek wandern teilweise aus SQL in die Dart-Gruppierung (`LibraryEntry = SingleBook | Slipcase`). Bei rund 800 Büchern ist das unkritisch.
- Jede Lese-Statistik muss über `ShelfPartition` laufen.
- Fremde CSV-Formate kennen die Beziehung nicht. Dort erscheinen Schuber und Bände als Bücher.

## Rückbau
`parentId` auf NULL setzen. Dann sind alle Bände wieder Einzelbücher, und der Schuber ist ein normales Buch. Daten gehen dabei nicht verloren.
