# Beitragen zu OpenShelf

Danke für dein Interesse. OpenShelf ist ein Fork von [Openreads](https://github.com/mateusz-bak/openreads) und steht unter der GPL-2.0.

## Ablauf

1. Fork und Branch von `master`: `feat|fix|refactor|docs|chore/<kurz>`.
2. Größere Änderungen beginnen mit einer Spezifikation unter [`specs/`](specs) (Spec Kit). Die Regeln stehen in [`.specify/memory/constitution.md`](.specify/memory/constitution.md), Entscheidungen mit Tragweite als ADR in [`doc/adr/`](doc/adr).
3. Test zuerst: erst ein fehlschlagender Test, dann der Code, dann aufräumen.
4. Commits nach [Conventional Commits](https://www.conventionalcommits.org): `type(scope): imperative summary`, Englisch, höchstens 72 Zeichen.
5. Pull Request gegen `master`; die CI muss grün sein.

## Gates

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Nach Änderungen an Drift-Tabellen: `dart run build_runner build --delete-conflicting-outputs`. Eine Schemaänderung braucht eine rückwärtskompatible Migration und einen Migrationstest. Texte der Oberfläche stehen in `lib/l10n/app_de.arb` (Vorlage) und `app_en.arb`, danach `flutter gen-l10n`.

## Fehler und Ideen

Bitte als [Issue](../../issues) melden. Für Fehler gibt es eine Vorlage mit den nötigen Angaben (Version, Gerät, Schritte).

## Secrets

Keys, Keystores und `key.properties` gehören nie ins Repo. Der Google-Books-Key wird nur per `--dart-define` gesetzt.
