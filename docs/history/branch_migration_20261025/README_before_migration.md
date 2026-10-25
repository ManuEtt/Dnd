# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Android-Alpha für Soloabenteuer, SRD-geprüfte Teilsysteme, regelgeprüfte Kämpfe und lokale Kampagnen mit SQLite. Flutter-/Dart-App in `app/`, optionaler Fastify-/TypeScript-Erzähler in `backend/`. **Das vollständige D&D-SRD-5.2.1-Regelwerk ist weiterhin nicht implementiert.**

## Weiterentwicklung 25.10.2026: lokal gesicherte Story-Endzustände

**Neu in [PR #165](https://github.com/ManuEtt/Dnd/pull/165):** Der Android-Story-Validator verbietet nun ebenfalls, dass ein generativer Erzähler einen bereits abgeschlossenen (`resolved`) oder aufgegebenen (`abandoned`) Handlungsstrang unbemerkt wieder öffnet oder anders abschließt. Positive manuelle Wiederöffnung im vorhandenen Editor bleibt zulässig; vor dem Anwenden werden sogar früher vorbereitete KI-Antworten erneut geprüft. Neue Domain-/JSON-/Eventregressionen in `app/test/ai_story_test.dart`. Kein Schema- oder Versionswechsel.

**Branchmodell:** PR #165 ist auf dem vollständig grünen, aber **noch nicht nach main gemergten** [Integrations-PR #164](https://github.com/ManuEtt/Dnd/pull/164) aufgebaut. Die **neue CI #165 muss separat grünes Ergebnis liefern**; der erfolgreiche Basislauf [#40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457) beweist nur die ältere Basis. [Technischer Nachweis](docs/STORY_LOCAL_TERMINAL_GUARD_20261025.md) · [Checkpoint](docs/CODEX_CHECKPOINT.md).

---

## Aktueller Integrationsvorschlag (24.10.2026)

**Basis:** `main` `b60ffe7`, App-Version **0.8.38+88**, SQLite **2**, Kampagnen-Export-JSON **1**. Der Branch `integration/approved-pr159-163-20261024` bündelt fünf einzeln grün getestete, **noch nicht nach main gemergte** PRs [#159](https://github.com/ManuEtt/Dnd/pull/159)–[#163](https://github.com/ManuEtt/Dnd/pull/163). Der gemeinsame Integrations-PR **#164** erfordert eine **neue vollständige CI auf seinem eigenen Commit** und menschliche Review, bevor Änderungen in `main` übernommen werden. Die originalen PR-Branches bleiben für die Überprüfung erhalten.

| Ursprünglicher PR | Kombinierte Änderung |
| --- | --- |
| [#159 – Sending](https://github.com/ManuEtt/Dnd/pull/159) | W100 nur bei ausdrücklich bestätigter Nichtblockade **und** bestätigter anderer Ebene anbieten; alte Eingabe nach Änderung löschen |
| [#160 – Schurke](https://github.com/ManuEtt/Dnd/pull/160) | Bereits autorisierte Nebenhandattacke mit echter Finesse-Waffe darf denselben bestätigten Verbündetenbeleg für Hinterhältigen Angriff nutzen; Miss/Krit, einmaliger Zugverbrauch, SQLite und Import |
| [#161 – Story](https://github.com/ManuEtt/Dnd/pull/161) | Erzähler darf `resolved`/`abandoned` nicht unbemerkt neu öffnen; explizite Spieleränderung im lokalen Editor bleibt möglich |
| [#162 – Rate-Limiter](https://github.com/ManuEtt/Dnd/pull/162) | Aktive Quoten bei vollem Backend-Schlüsselspeicher erhalten, nur abgelaufene Fenster entsorgen, ansonsten fail-closed ablehnen |
| [#163 – Plot-Geheimnisse](https://github.com/ManuEtt/Dnd/pull/163) | Wörtliche Komplett-Offenlegung geheimer Plottexte in öffentlichen KI-Antwortfeldern unterbinden; keine Garantie für sinngemäße Spoiler |

**Prüfstatus:** Alle fünf Einzel-PRs haben auf ihren jeweiligen finalen HEADs eigenständige erfolgreiche GitHub-CIs. Die kombinierte CI von [Integrations-PR #164](https://github.com/ManuEtt/Dnd/pull/164/checks) wird separat geprüft und ist **bis zum tatsächlichen Erfolgsnachweis noch offen**. Keine neue Version, keine Datenmigration und keine automatisch als erfolgreich markierten realen Android-Gerätetests.

Die ursprünglichen Fachbelege bleiben in `docs/SRD_SNEAK_ATTACK_OFFHAND_ALLY_20261024.md`, `docs/STORY_TERMINAL_THREAD_GUARD_20261024.md`, `docs/BACKEND_LIMITER_CAPACITY_20261024.md` und `docs/STORY_SECRET_OUTPUT_GUARD_20261024.md`. Frühere operative Checkpoints sind historisch gesichert unter `docs/history/integration_20261024/`. [Aktuelle Gesamtprüfung/Review](https://github.com/ManuEtt/Dnd/pull/164) · [Checkpoint](docs/CODEX_CHECKPOINT.md).

---

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
