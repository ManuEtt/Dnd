# Entwicklungscheckpoint – Live-Snapshot-Sicherheit für Magisches Geschoss

**Datum:** 2026-11-10  
**Zuständigkeit:** Android/Flutter-Oberfläche  
**Ausgangs-main:** `4b02b7ff0c3f5328d49c1a2930ef11dd933934fa`  
**Branch:** `feat/chat-c/magic-missile-live-snapshot-20261110`  
**Code-/Test-HEAD vor Dokumentation:** `c93cb0f1d63aa8cde4381eeade8189f4a45a23e2`  
**Pull Request:** [#678](https://github.com/ManuEtt/Dnd/pull/678) (Draft)

## Ausgangsproblem

`MagicMissileDialog` ermittelte die vorbereiteten Klassen, Zauberplätze,
gegnerische Force-Abwehr und Shield-Daten nur beim Öffnen. Beim Austausch einer
bereits dargestellten `HeroCharacter`- oder `Encounter`-Instanz blieben die
alten Bestätigungen und internen `DropdownButtonFormField`-Werte bestehen.
Damit konnte der Dialog eine fachlich veraltete Auswahl zurückmelden.

## Implementiert

- `didUpdateWidget` erkennt neue Hero- und Encounter-Snapshot-Instanzen.
- `_loadOffer` erneuert sämtliche Klassen-/Slotangebote und Gegnerdaten;
  Sicht, Reichweite, Komponenten und Shield-Bestätigungen werden verworfen.
- Vier versionierte `KeyedSubtree`-Hüllen setzen auch den internen
  Formularfeld-Zustand zurück. Bestehende Widget-Keys bleiben stabil.
- Normale Parent-Rebuilds mit identischen Snapshot-Instanzen behalten die
  ausdrücklich getroffene Auswahl.

**Geänderte Dateien:**
- `app/lib/ui/magic_missile_dialog.dart`
- `app/test/magic_missile_live_snapshot_test.dart`
- `docs/parallel/CHAT_C_MAGIC_MISSILE_SNAPSHOT_20261110.md`

## Testfälle und Abnahmestand

Vier neue positive/negative Widgettests prüfen:
1. unveränderten Parent-Rebuild mit erfolgreicher bestätigter Auswahl;
2. verbrauchte hochgradige Slots bei bereits geöffnetem Dialog;
3. Gegnerwechsel mit verwerfener Ziel- und Abwehrbestätigung;
4. fehlende Vorbereitung, vollständig verbrauchte Slots und Erholung.

**GETESTET:** GitHub-Dateien, Hauptbranch und offene Fach-PRs geprüft;
Änderungen und Regressionstests als Commits auf eigenem Branch gespeichert.
Dies ist kein ausführbarer Flutter-Testnachweis.

**NICHT GETESTET:** Lokales `dart format`, `flutter analyze`,
`flutter test`, `flutter build apk --debug`, Python-/Backend-Suiten und
Android-/TalkBack-/IME-Realgerätetest. Flutter/Dart SDK steht im
verfügbaren Container nicht bereit. GitHub-Actions-Abnahme auf dem finalen
Branch-HEAD steht zunächst aus.

**BLOCKIERT:** Die gemeinsam genutzten Statusdateien `README.md`,
`docs/CODEX_CHECKPOINT.md` und `docs/parallel/CHAT_C_CHECKPOINT.md`
werden bereits in zahlreichen offenen PRs parallel geändert. Um keine
fremden README-Anhänge bzw. Checkpoints zu verlieren, wird dieser
paketbezogene Status separat versioniert und zusätzlich im PR dokumentiert.
Der verlustfreie zentrale Nachtrag gehört in einen koordinierten
Integrationsschritt.

**Migration und Kompatibilität:** Keine Änderungen an Rule-/Story-/Controller-
Schnittstellen, SQLite, JSON, Inventar, Spielstand, App-Version oder
Berechtigungen. Keine Migration; keine Würfe oder Ressourcenbuchungen im Dialog.

**Bekannte Risiken:** Vollständige CI, gemeinsame PR-Integration und tatsächliche
Android-Bedienung sind noch nicht abgenommen.

**NÄCHSTER SCHRITT:** Finale GitHub-Actions-Ausführung für PR #678 prüfen;
bei Format-/Analyse-/Widgetfehlern denselben Branch korrigieren und
anschließend die reale TalkBack-/IME-Abnahme durchführen.
