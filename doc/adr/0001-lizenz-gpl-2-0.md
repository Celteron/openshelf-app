# ADR-0001: Lizenz des Forks OpenShelf: GPL-2.0 statt GPL-3.0

- **Status:** Vorgeschlagen
- **Datum:** 2026-10-08
- **Entscheider:** Projektinhaber

## Kontext
OpenShelf ist ein Fork von Openreads und soll auch kommerziell nutzbar sein. Im Commit `250d531d` (2026-10-07) wurde die Lizenz auf GPL-3.0 umgestellt (`LICENSE`, Anzeige `licenseText`).

Die Prüfung des Upstreams (`mateusz-bak/openreads`) am 2026-10-08 ergab:
- Die GitHub-API meldet `spdx_id: GPL-2.0`.
- `LICENSE` ist der Text „Version 2, June 1991".
- Es gibt keine Datei-Header, etwa in `lib/main.dart`, und damit keine „or any later version"-Zusage. Der Satz im Anhang des Lizenztextes ist nur die Standardanleitung und keine Zusage des Autors.

GPL-2.0-only-Code darf ohne Zustimmung aller Urheberrechtsinhaber nicht unter GPL-3.0 weitergegeben werden. GPL-2.0-only und GPL-3.0 sind außerdem nicht kompatibel kombinierbar. Constitution Artikel VII verlangt, die Upstream-Lizenz (GPLv2) zu respektieren und das Werk ohne proprietäre Ausnahmen offen zu halten.

## Betrachtete Optionen
1. **A: GPL-2.0 behalten bzw. wiederherstellen:** `LICENSE` zurück auf den Upstream-Text, Anzeige „GPL-2.0".
2. **B: GPL-3.0 mit Zustimmung des Upstream-Autors:** Der Autor erlaubt die Umstellung ausdrücklich und schriftlich. Das ist praktisch nur mit allen Urheberrechtsinhabern des übernommenen Codes möglich.
3. **C: Dual-Lizenz, neuer Code zusätzlich GPL-3.0-kompatibel:** Eigene neue Module wären zusätzlich unter GPL-3.0 nutzbar.

## Bewertung
| Kriterium | A | B | C |
|---|---|---|---|
| Einfachheit / Codeumfang | sehr einfach, nur `LICENSE` und Anzeige | einfach, aber Zustimmung nötig | pro Datei Lizenz-Header, Trennung nötig |
| Rechtssicherheit | hoch | hoch, nur mit schriftlicher Zustimmung | gering: Das Gesamtwerk bleibt GPL-2.0 |
| Kommerzielle Nutzung | erlaubt, Quellcode bleibt offen | wie A | wie A |
| Risiko | keins | Zustimmung kann ausbleiben | Verwechslung, Kombination mit GPL-2.0-only-Teilen unzulässig |

## Entscheidung
Option A. Der Fork bleibt unter GPL-2.0. Das ist die einzige Variante, die ohne Zustimmung Dritter rechtlich tragfähig ist und Artikel VII der Constitution erfüllt. Option B bleibt möglich, falls der Upstream-Autor später zustimmt (neuer ADR, der diesen ablöst). Option C wird verworfen, weil das Gesamtwerk ohnehin GPL-2.0 bleibt.

## Konsequenzen
- **Positiv:** Rechtlich sauber, keine Abhängigkeit von Dritten. Kommerzieller Vertrieb ist weiterhin erlaubt, sofern der Quellcode unter GPL-2.0 an Empfänger weitergegeben wird.
- **Negativ / Kosten:** Keine Patentklausel und keine Anti-Tivoisierung wie in GPL-3.0. Die Einbindung von GPL-3.0-only-Bibliotheken ist nicht möglich. Neue Abhängigkeiten müssen vorher auf GPL-2.0-Kompatibilität geprüft werden.
- **Folgearbeiten:**
  - Umgesetzt: `LICENSE` aus dem ersten Commit (`1b4b606c`) wiederhergestellt, `licenseText` in `app_de.arb` und `app_en.arb` auf „GPL-2.0", `license_display_test` und `settings_screen_test` angepasst.
  - Offen: bei jeder neuen Abhängigkeit die Lizenzkompatibilität prüfen. Für den Store-Vertrieb den Hinweis auf Lizenz und Quellcode-Zugang prüfen.
  - Die Specs `001` und `002` (FR-P2-19) nennen noch GPL-3.0. Sie sind historisch und durch diesen ADR abgelöst.

## Referenzen
- Commit `250d531d` (Umstellung auf GPL-3.0), `1b4b606c` (ursprüngliche GPL-2.0-`LICENSE`)
- Upstream: https://github.com/mateusz-bak/openreads (Lizenz: GPL-2.0)
- Constitution Artikel VII, `specs/003-openshelf-feedback-round1/spec.md` (FR-F1-10, T3-17)
