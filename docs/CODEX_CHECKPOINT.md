# CODEX-CHECKPOINT – Würfelraunen

Stand **2026-10-23T19:47:39+00:00**, aktive Sitzung. Vollständige vorige Übergabe: [Historie](history/main_0.8.36_20261023/CODEX_CHECKPOINT.md). Vor Wiederaufnahme tatsächliches main, PRs und CI erneut abfragen.

## Git und Produkt

- Basis-main: `5958579e5321338bb7b4e46abb859fd3bfd1515f` (PR143 integriert).
- Arbeitsbranch: `feature/sneak-attack-ally-integration-20261023`.
- Formatnormalisierung: `309b07e`; funktionaler Code: `0a56aba7057dc12d80750759443f6d70ed510dc1`.
- Version: **0.8.37+87**, Android-Alpha. Eigener PR/Push noch ausstehend.
- Offener Fremd-PR bei Bestandsaufnahme: [144 / Sending](https://github.com/ManuEtt/Dnd/pull/144), nicht dupliziert.
- Letzter vollständig erfolgreicher Basisworkflow: [40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485), geprüftes SHA5958579. Kein Nachweis für neuen Code.

## IMPLEMENTIERT

Hinterhältiger Angriff mit manuell bestätigtem Verbündeten für einen offenen Hauptwaffenangriff. Beide Fakten (5Fuß zum Ziel, nicht Incapacitated) werden separat erfasst und an Kampagne/Ziel/Wurf gebunden. Vorbereitung würfelt nicht und verbraucht keine Ressourcen; erst der gültige Treffer erzeugt Zusatzwürfel und Nutzung. Entfernen, Krit, Miss und neue Probe sind angebunden. Keine aus KI-Text erfundenen Werte. Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt partial.

Import und Ausführung prüfen dieselbe Bindung, eigene Zugberechtigung, Finesse/Fernkampf und Nutzung. Gespeicherter Angriffsbonus kommt aus RulesEngine einschließlich Bogenschießen. Story darf pendingRoll nicht verändern. SQLite2 und Kampagnen-JSON1 bleiben erhalten; optionales PendingRoll.sneakAttackAlly hat nestedVersion1, Alt-JSON bleibt gültig.

Dateien: neue Domain `app/lib/domain/sneak_attack_ally_rules.dart`, Models, GameEngine, Controller, rules_api, Abenteuer-UI, neuer Dialog und zwei neue Testdateien; App-Version, CI-Formatgate, Requirement-Register und Statusdokumentation. Backend, Outbox und Berechtigungen unverändert.

## GETESTET

- Normalisierte Basis: scripts/check.sh vollständig erfolgreich; **1.431 Flutter-Tests**, **100 Python-Tests**, Backend-Typecheck/Build/**31 Tests**, Analyse und Formatierung.
- Neuer Code gezielt: **11 Domain-/SQLite-Tests** und **6 Widgettests** erfolgreich. Abgedeckt: vor Zufall validieren, Treffer/Miss/Krit, 1x-pro-Zug, Datenmanipulation, verbrauchte/fremde Ziele, Storygrenze, Neustart, Export/Import, Rekonstruktion, stale Dialog, verspäteter Eventfehler/Rollback, Abbruch, Eingabeentwurf, 360dp/Schrift1,8/Tastatur260dp.
- Neuer vollständiger Lauf erfolgreich: **1.448 Flutter-Tests**, Format344-Dateien/Analyse ohne Befunde, Backend31 und Python100 erfolgreich.
- Prüfprotokolle: `/workspace/validation/20261023-sneak-full-check.log`, `20261023-sneak-domain.log`, `20261023-sneak-ally-ui-final.log`.

## NICHT GETESTET

Neue GitHub-CI, Android-APK/native Tests (Build aus dem geprüften ZIP läuft) und reales Gerät. Keine fremde grüne CI als neue Freigabe ausgeben.

## BLOCKIERT

Kein erreichbares Android-Realgerät und keine produktive Release-Signierung. Flutter3.35.7/Dart3.9.2, Node22.14, Java17 und Android-SDK sind lokal verfügbar; fehlende SDKs aus älteren Übergaben gelten hier nicht.

## NOCH NICHT IMPLEMENTIERT

Allgemeine Verbündeten-/Positionsverwaltung, bestätigter Nebenhandkontext und allgemeine Gelegenheitsangriffe; vollständiges SRD. Keine globale Abdeckungsquote (1.419 Prüfaufträge, neun Inventurlücken). Frühere Item-Arbeit separat in `/workspace/Dnd-current` und `/workspace/artifacts` gesichert; sie basiert auf b965efc und muss vor Übernahme mit neuerem main abgeglichen werden. Dort letzter Gesamtversuch: zwei überholte Python-Quellstring-Vertragstests fehlgeschlagen; kein neuer Android-Build behauptet.

## Noch laufender Abschluss / Artefakte

Gesamtlauf erfolgreich. Unveränderten Code aus vollständigem ZIP auf Android bauen, native Tests ausführen, Ergebnisse und Artefakt-SHA aktualisieren. Danach commit/push/PR, finale CI beobachten. Main nicht ungeprüft verändern. ZIP und Patch werden mit scripts/create_checkpoint.py gegen explizite Basis5958579 erzeugt; keine erfolgreiche Bereitstellung vor Dateiprüfung behaupten.

## Genau ein nächster fachlicher Schritt

**Nebenhand-Sneak-Attack am tatsächlich angreifenden Inventargegenstand prüfen und bestätigen.** Akzeptanz: Finesse/Fernkampf der wirklichen Waffe, einmal pro Zug, fehlende Fakten ablehnen, separate Haupt-/Nebenhand, Krit und Miss, JSON/SQLite-Neustart, alte Hauptwaffenprobe unverändert. Gelegenheitsangriffe bleiben eigener Scope.

Prüfung: `bash scripts/check.sh`; `python3 scripts/check_domain_boundaries.py`; `python3 scripts/srd_coverage.py --json`; `cd app && flutter build apk --debug`; `cd android && bash ./gradlew :app:testDebugUnitTest --no-daemon`. SDK-/SQLite-Pfade dieser Umgebung: `/workspace/validation/TOOLCHAIN.md`.

Keine automatische Wiederaufnahme außerhalb einer tatsächlich laufenden Sitzung.
