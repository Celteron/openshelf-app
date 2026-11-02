# Spec 006: Reader flow (cover states, shop check, customizable home, reading calendar, year review, quote photos, shelf wall)

Status: **approved in chat on 2026-11-02** (order: P1–P5, build, P6, P7, build). Decisions of the product owner are in section 5.

## 1. Goal
Serve what the reader does day to day: find a book, check whether she owns it, remember what she read. Everything is computed on the device (Constitution I.1, I.2); no new network access except the cover search that an import or a scan already triggers.

## 2. Requirements

### P1 Cover states
- **FR-06-01** A cover placeholder is a plain grey book while the book was not searched yet. After every online source answered "no cover" it carries an amber banner ("Cover fehlt – manuell ergänzen"; icon only on small tiles).
- **FR-06-02** After an import that added books, and after saving scanned books, the missing covers are looked up in the background (the user action behind the network use). Overlapping runs share one pass.

### P2 Shop check and shopping list
- **FR-06-03** Every scan of an already known ISBN answers with a verdict card: owned (title, location path, status of the series), on the wishlist, in the trash. A new ISBN in "in the shop" mode answers "not in your library" with the looked-up title and the actions "Add" and "Wishlist".
- **FR-06-04** The scanner has an "In the shop" switch: scans only answer, nothing is staged. The verdict of a wishlist book offers "Bought".
- **FR-06-05** Series with a planned length report missing whole volumes; wishlist books are not owned. A series without length can be given one from the shopping list.
- **FR-06-06** The shopping list (library app bar) shows the wishlist and the missing volumes (minus those already on the wishlist) and copies them as plain text. Nothing is shared by the app itself.

### P3 Customizable home
- **FR-06-07** The home tab is built from blocks (donut, pinned statistics, goal, currently reading, recently added, unread stack, favourites, reading calendar). Order and visibility are a setting ("Startseite anpassen", reachable from home and settings). The standard layout is the former one.
- **FR-06-08** A currently-read book has a one-tap "read now" button that opens the reading screen.
- **FR-06-09** The layout is a device preference like all settings; it is not part of the JSON backup.

### P4 Reading calendar
- **FR-06-10** A year grid (Monday first) with two layers: logged reading time (strong, five levels) and "a book was in progress" between its first start and last end (faint). Imported start/end dates therefore work without sessions. Tapping a cell says what happened that day; the summary and that line are the screen reader view.
- **FR-06-11** The calendar is a home block and part of the statistics' reading section; arrows move between years that have data.

### P5 Year review
- **FR-06-12** Swipeable cards for a year: books and pages, reading time and days, longest and best-rated book, favourite author and strongest month, covers. Volumes count, slipcases do not. A card can be saved as a PNG (user action; the system "save as" dialog).

### P6 Quote from a photo
- **FR-06-13** The note dialog can read the text of a photo (camera or gallery) with free OCR on the device (ADR-0006) and appends it, tidied (line breaks and hyphenation of the printed page removed), to the text field for editing. The photo exists only during recognition. Android only.

### P7 Shelf wall (architect review 2026-11-02, ADR-0007)
- **FR-06-14** The shelf tab draws each compartment as a row of spines (width and height from the page count, never narrower than 48 dp; colour from the cover, a stable colour from the title without one). A slipcase is one block. Books without a location are in a row "Ohne Standort". The location management of the former tree stays reachable.
- **FR-06-15** "Find it": a title/author search highlights the matches, dims the rest and scrolls to the first; next/previous steps through the hits.
- **FR-06-16** A book can be moved to another compartment by dragging its spine onto the row, with an undo, and by an accessible action that opens the location picker.
- **FR-06-17** A slipcase expands to its volumes.

## 3. Non-goals
Inventory mode, "what to read next", lending reminders (rejected or parked by the product owner). No manual order within a compartment. Renaming and moving locations stay out of this spec.

## 4. Constitution check
- I.1/I.2: no new network use; OCR and colours are local.
- I.3: no new user data besides a setting.
- II.3: no schema change in this spec (series length uses the existing column).
- IV.2: pure engines (verdict, series gaps, calendar, year review, OCR cleanup, shelf layout) have unit tests.
- V: 48 dp targets, screen reader summaries, dark/light.
- VII: ADR-0006 records the open licence question of Apache-2.0 parts.

## 5. Decisions
- Scan integration: one scanner, verdict first, plus an "In the shop" switch (no separate mode screen).
- Home: customizable or not at all.
- OCR: free and offline (Tesseract through an own Android channel), no Google component. Existing Google parts (ML Kit scanner, barcode, Books API) stay until F-Droid work starts (ADR-0006 table).
- Shelf wall minimum spine width 48 dp (Art. V.3) over a realistic overview; about seven spines per phone width.
