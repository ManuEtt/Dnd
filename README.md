# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Android-Alpha für Soloabenteuer, regelgeprüfte Kämpfe und lokale Kampagnen mit SQLite. Flutter/Dart-App und optionaler Fastify-/TypeScript-Erzähler. Das vollständige SRD 5.2.1 ist noch nicht implementiert.

## Aktueller Entwicklungszyklus – Handlungsstränge sicher fortsetzen (24.10.2026)

[PR #161](https://github.com/ManuEtt/Dnd/pull/161) auf `fix/story-terminal-thread-reopen-20261024` behebt eine Kontinuitätslücke des **Backend-Erzählers**: Ein von Spielerentscheidungen bereits `resolved` oder `abandoned` gespeicherter Handlungsstrang darf durch eine spätere generierte `/v1/story/advance`-Antwort nicht stillschweigend wieder auf `open` gesetzt oder anders abgeschlossen werden. Unveränderter Terminalstatus und neue rein narrative Notizen bleiben zulässig. Spieler können weiterhin ausdrücklich im lokalen Thread-Editor wiederöffnen; der bestätigte neue `open`-Stand ist danach die Eingabe für den Erzähler.

**IMPLEMENTIERT:** kleine Validatoränderung in `backend/src/story.ts` und zwei neue Backend-Regressionen (geschlossene Statuswechsel, manuelle Wiederöffnung und HTTP-502 ohne Leckage). **GETESTET:** bis zur vollständig grünen CI von [PR #161](https://github.com/ManuEtt/Dnd/pull/161/checks) noch nicht als abgeschlossen melden. **NICHT GETESTET:** lokales Android-Gerät/Altspielstandupgrade. **BLOCKIERT:** kein lokaler Checkout mit Android-SDK; GitHub-CI verfügbar. **NOCH NICHT IMPLEMENTIERT:** vollständige autonome KI-Weltzustandsverwaltung und SRD-5.2.1-Vollabdeckung.

Unverändert App-Version **0.8.38+88**, SQLite **2**, Export-JSON **1**. `main` steht beim Start dieses Zyklus auf `b60ffe7`; [PR #159](https://github.com/ManuEtt/Dnd/pull/159) (Sending) und [PR #160](https://github.com/ManuEtt/Dnd/pull/160) (Nebenhandverbündeter) bleiben getrennt offen. PR #160 hat eine vollständige grüne CI [#40100211878](https://github.com/ManuEtt/Dnd/actions/runs/40100211878). Diese ist kein Nachweis des neuen Backend-Fixes. [Regelgrenze/Regression](docs/STORY_TERMINAL_THREAD_GUARD_20261024.md) · [Checkpoint](docs/CODEX_CHECKPOINT.md).

**Nächster Schritt:** finale CI und Tests für PR #161 auswerten, etwaige Fehler beheben, dann zur Review freigeben. Vor Merge sind parallele Dokumentationsänderungen aus PRs #159/#160 abzugleichen.

---

## Vorheriger Main-Dokumentationsstand (historischer PR #158)

**Version 0.8.38+88**, Branch `fix/sneak-attack-offhand-weapon-20261024`, [PR #158](https://github.com/ManuEtt/Dnd/pull/158). Funktionaler Code [`aa79ce5`](https://github.com/ManuEtt/Dnd/commit/aa79ce593790e5763e9125743b0adeab55b581d5), Basis-main `dcb42c5efff40a757994d4f5b5f8e98b2ff128e9` (PR #157 integriert). Eigene aktuelle [GitHub-Checks](https://github.com/ManuEtt/Dnd/pull/158/checks) zeigen den jeweiligen finalen HEAD; Basisprüfungen und lokale Abnahme werden getrennt geführt. Main bleibt durch diesen Zyklus unverändert.

**Korrigiert: Hinterhältiger Angriff prüft die tatsächlich angreifende Waffe.** Bisher wurde bei einer Nebenhandprobe die Hauptwaffe auf Finesse/Fernkampf geprüft. Ein bestätigter Dolch-Nebenhandangriff kann jetzt seine eigene Eignung nutzen; eine Handaxt erhält keine Eignung durch einen Dolch in der Hauptwaffe. Angriff, Schaden, kritische Treffer, einmalige Zugnutzung und Journal bleiben im vorhandenen Kampffluss.

Das betrifft auch gespeicherte offene Angriffe mit bereits bestätigtem Vorteil. Die Änderung erzeugt keinen Vorteil und erweitert die bisherigen Nebenhandvoraussetzungen nicht. Die Verbündetenbestätigung bleibt vorerst auf Hauptwaffenangriffe begrenzt. SQLite-Schema 2 und Kampagnen-JSON 1 bleiben erhalten; keine Migration und keine erfundenen KI-Regelwerte.

### Tatsächlicher Prüfstand dieses Pakets

| Prüfung | Beobachtetes Ergebnis |
| --- | --- |
| Gezielte Regressionen | 27 bestehende/Helper- und 8 neue Kampf-/SQLite-Tests erfolgreich |
| Vollständige Flutter-Suite | **1505 Tests erfolgreich** |
| Python / Backend | 100 /31 Tests, Typecheck und Build erfolgreich |
| Dart / Flutter-Analyse | 356 Dateien ohne Formatänderung; keine Befunde |
| Android | Debug-APK und ARM64-Alpha gebaut und geprüft; 12 native Tests erfolgreich |
| GitHub | [PR158 und aktuelle Checks](https://github.com/ManuEtt/Dnd/pull/158/checks), separat von lokalen Ergebnissen |
| Echtes Gerät / produktive Signierung | nicht getestet |

APKs wurden aus dem vollständigen Quell-ZIP gebaut; 474 ausführungsrelevante Dateien per SHA256 abgeglichen. Version 0.8.38/Build 88, minSdk24/targetSdk36; Debug mit ARM64/ARMv7/x64, kleine Alpha nur ARM64, jeweils lokale Debug-Testsignatur. Vollprojekt-ZIP, Patch und Prüfsummen unter `/workspace/artifacts/`; neue APKs unter `/workspace/artifacts/0.8.38+88/`. [Importanleitung](docs/ARTIFACT_IMPORT_20261024.md).

Aktuelle Übergabe: [CODEX_CHECKPOINT](docs/CODEX_CHECKPOINT.md). [Regelquelle und Abnahmekriterien](docs/SRD_SNEAK_ATTACK_WEAPON_CONTEXT_20261024.md). Vorherige Sending-, XP- und Schurkenstände sind integriert; deren frühere Entwicklungsangaben stehen separat in der [README-Historie](docs/history/main_0.8.37_20261024/README.md).

## Vorhandene Funktionen und Grenzen

| Bereich | Implementierter Umfang |
| --- | --- |
| Charaktere und Aufstieg | Zwölf SRD-Klassen, Attribute, bestätigte Startwerte/Ausrüstung, XP-Schwellen und bestätigte idempotente EP-Belohnungen, einzelne Aufstiege bis Gesamtstufe 20, bestehende Zweitklasse; zahlreiche Merkmals- und Talentwirkungen weiterhin offen |
| Kampf | W20/Vorteil/Nachteil, Angriff und Schaden, ausgewählte Zustände/Klassenaktionen, Bewegung/Aufstehen/Kriechen, Deckung, Einzelgegner mit bestätigten Mehrfachangriffen; keine vollständige Mehrakteur-Automatik |
| Magie | Zauberkatalog und Vorprüfungen, Plätze/Paktressourcen/Konzentration, ausgewählte echte Wirkungen und Schildreaktionen; Sending mit bestätigtem Dialog, Slotverbrauch und SQLite-Beleg, ohne Nachrichtenzustellung; Katalogeinträge sind keine vollständigen Zauberwirkungen |
| Kampagnen | Lokale Solo-Demo und Rabenwacht mit optionalen Fortsetzungen, Entscheidungen, NPC-Erinnerungen und Journal; keine universell fertige autonome Spielleitung |
| Speicherung | Kampagnen, Ereignisse und Revisionen atomar; JSON-Sicherung, transaktionale Spielerhandlungs-Outbox, Settings-Teilupdates und Datenreset; SQLite-Version 2, Kampagnen-JSON-Version 1 |
| Android und Fantasy-UI | Deutsche Oberfläche, Charakterbogen, vorhandene Fantasy-Assets/Porträts, Sprache/TTS und Abenteueraktionen; reale Geräteabnahme und produktive Signierung offen |
| Optionaler Erzähler | Getrennter Backenddienst, bestätigter Regelzustand bleibt lokal; keine automatische kostenpflichtige Wiederholung und keine externe Exactly-once-Garantie |

Regelanforderungen stehen in [Coverage-Audit](docs/SRD_5_2_1_COVERAGE_AUDIT.md) und den beiden JSON-Registern. Die derzeitigen **1.419 Prüfaufträge und neun Inventurlücken sind kein vollständiger SRD-Nenner**. Eine globale Fertigstellungsquote wird nicht behauptet.

## Lokal entwickeln und prüfen

Toolchain wie CI: Flutter 3.35.7 / Dart 3.9.2, Java 17, Node.js 22.14.0 und Android-SDK. Linux-SQLite-Tests benötigen `libsqlite3-dev`.

```bash
bash scripts/check.sh
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py --json
cd app
flutter build apk --debug
cd android
bash ./gradlew :app:testDebugUnitTest --no-daemon
```

Die Demo benötigt keinen externen KI-Anbieter. Für einen eigenen Erzähler siehe [Backend](backend/README.md) und [Verbindung](docs/BACKEND_CONNECTION.md). Dauerhafte Anbieter-Schlüssel gehören ausschließlich auf den Server.

## Nächster konkreter Entwicklungsschritt

Die manuelle Verbündetenbestätigung für zulässige Nebenhandangriffe an denselben sicheren Dialog-/Controllerpfad anbinden. Abnahme: Eignung der tatsächlichen Angriffswaffe, ziel-/wurfgebundene Zustimmung, gemeinsame einmalige Zugnutzung, Krit/Miss, Ablehnung, alte Hauptwaffen-/JSON-Abläufe und SQLite-Neustart. Allgemeine Gelegenheitsangriffe bleiben ein eigenes Arbeitspaket.

Weitere offene Arbeiten: vollständige Quelleninventur, Zauberwirkungen, Klassen-/Monstermechaniken, strukturierte Item-Overrides, Android-Upgrade mit echten Spielständen und produktive Signierung. Der frühere lokale Item-Entwurf ist separat gesichert und wurde nicht über neuere Main-Dateien kopiert.

## Dokumentation und Historie

- [Aktueller Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [Operativer Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Artefakte importieren](docs/ARTIFACT_IMPORT_20261024.md) · [Validierungsbericht](docs/VALIDATION_0_8_38_20261024.md)
- [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md)
- [README vor diesem Zyklus](docs/history/main_0.8.36_20261023/README.md) · [ältere Historie](docs/README_HISTORIE_BIS_20261020.md)

Nur ausgewählte Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte verwenden. [Namensnennung und Lizenzen](THIRD_PARTY_NOTICES.md) erhalten. Neue Arbeit erfolgt während einer aktiven Sitzung in einem eigenen Branch und PR; keine automatische Fortsetzung außerhalb einer laufenden Sitzung.
