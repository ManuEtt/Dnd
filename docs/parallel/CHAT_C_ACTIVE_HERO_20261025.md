# CHAT C – Lesbare aktive Heldenkarte

**Stand:** 2026-10-25, Europe/Berlin  
**Ausgangs-main:** `af70a48c84d83c133ced4200be04ca81a91abf1b`  
**Branch:** `feat/chat-c/accessible-active-hero-20261025`  
**Code:** `efda08d6810f4bcc4073be0a741abcf36bd3587f`  
**Widgettests:** `ca7dc63e2deaa69ef653703c10d62f28a7d9ab08`  
**PR:** nach Veröffentlichung im GitHub-PR nachtragen

## Ausgangsproblem

In `FantasyActiveHeroCard` standen die drei Metriken Trefferpunkte, Rüstungsklasse und Bewegung auch bei 200 % Systemschrift nebeneinander. `FittedBox` verkleinerte Zahlen unabhängig von der eingestellten Schriftgröße. Bei einem Screenreader fehlte ein zusammenhängendes, sicheres Label je Karte.

## IMPLEMENTIERT

- `app/lib/ui/fantasy_campaign_dashboard.dart`: `LayoutBuilder`/Wrap teilt die drei Metrikkarten normal in drei Spalten und ab 180 % Textskalierung bei unter 500 dp in eine Spalte auf. Die Werte sind echte `Text`-Widgets und werden nicht über `FittedBox` verkleinert.
- `_HeroMetric`: je eine zusammenhängende, deutschsprachige, bestätigungsgetreue `Semantics`-Beschriftung; fehlende Werte werden nicht erfunden.
- `app/test/fantasy_campaign_dashboard_test.dart`: zwei positive Widgettests (320/360 dp bei 200 %, Spaltenpositionen, Werte, Vorleselabels, Bedienbarkeit) und ein negativer Test für unbestätigte Werte und deaktivierte Fortsetzung.

## Akzeptanz

- Die drei Metrikkarten erscheinen bei 320/360 dp und 200 % untereinander, ohne RenderFlex-Overflow.
- Der Text wird nicht künstlich herunter skaliert, sondern darf umbrechen.
- Screenreader erhält vollständige Namen und die bestätigten Werte; unbekannte Werte bleiben unbekannt.
- Weiterhin lässt sich das Abenteuer explizit fortsetzen, aber nicht bei `onContinue == null`.
- Keine Änderungen am Charakterzustand, D&D-Regelwerk, Kampagnenlogik, SQLite- oder JSON-Format.

## GETESTET

- GitHub-Livebestand vor Entwicklungsbeginn geprüft. Bei Arbeitsbeginn offene PRs #178, #179, #180, #181, #184, #185, #187, #188 und #189; keiner dieser PRs bearbeitet `fantasy_campaign_dashboard.dart` oder dessen Widgettests.
- Tests hinzugefügt, aber noch nicht als bestanden bewertet. CI für ursprünglichen Test-Head: [GitHub Actions #40233056288](https://github.com/ManuEtt/Dnd/actions/runs/40233056288), Ergebnis nach Abschluss separat prüfen.

## NICHT GETESTET / BLOCKIERT

- Dart-Format, `flutter analyze`, vollständige Flutter-Tests, Android-Debug-/Alpha-APKs, Backend-/Python-/SRD-Prüfungen auf dem finalen PR-Head noch nicht abschließend verifiziert.
- Kein Flutter-/Dart-/Android-SDK in dieser ausführenden GitHub-Connector-Umgebung für lokale Builds.
- Realgerät, TalkBack, produktive Signatur nicht geprüft.

## Versionsstand / Migration

- App `0.8.40+90`, SQLite 2, JSON 1 aus Basis unverändert.
- Keine Migration oder Änderung am Spielstand, keine KI-/Regeländerung.

## NÄCHSTER SCHRITT

Nach grüner finaler CI ein separates, noch nicht von anderen PRs beanspruchtes UI-Modul auf 320 dp/200 % plus korrektes Screenreader-Verhalten prüfen. Beim nächsten Paket wieder offenen PR- und Main-Bestand kontrollieren.

## Revalidierung nach Main-Merge von PR #185

- `main` `5f9a01dd73f68ad4f9e226f859a8ca87803b8337` beinhaltet jetzt die vollständig CI-geprüfte und integrierte Chat-C-HUD-Arbeit PR #185; sie bleibt erhalten. Eigene Dateien dieses Pakets bleiben `fantasy_campaign_dashboard.dart` und Widgettests, komplett unabhängig von `fantasy_adventure_hud.dart`.
- CI [#40233351659](https://github.com/ManuEtt/Dnd/actions/runs/40233351659) hat die Flutter-Gesamtsuite nach kanonischer Formatierung auf dem früheren Testcommit erfolgreich ausgeführt; aktuelle PR-/Merge-Commit-CI separat prüfen.
- Keine Datenmigration, kein automatischer Main-Merge.
