## Zyklus 2026-10-23 – Transaktionale Player-Action-Outbox (Arbeitsstand; CI ausstehend)

- **Baseline:** main `b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9`; letzter bestätigter grüner main-Lauf [#39932399488](https://github.com/ManuEtt/Dnd/actions/runs/39932399488), **nur für diesen SHA**. Offener Dokumentations-PR #133; dieser Funktionsbranch `fix/transactional-player-action-outbox-20261023` baut darauf auf. App-Version **0.8.31+81**.
- **IMPLEMENTIERT im Arbeitsbranch:** Die Pending-Action-Outbox nutzt eine eigene SQLite-Tabelle mit `campaign_id` als Primärschlüssel und eindeutiger `request_id`. Anlegen und Quittieren erfolgen in eigenen Transaktionen; Schreibvorgänge an `settings` können den Outbox-Eintrag nicht mehr überschreiben. SQLite-Datenbankschema **1 → 2** wird beim Öffnen migriert: gültige Einträge aus `pendingPlayerActionsV1` bleiben mit ihren IDs/Texten erhalten, andere Einstellungen bleiben bestehen; beschädigte Altdaten verhindern eine stille verlustbehaftete Migration. Kampagnen-JSON-Exportformat `schemaVersion=1` bleibt unverändert; kein automatischer KI-Retry.
- **Tests geschrieben, nicht lokal ausgeführt:** `app/test/player_action_outbox_test.dart` (zwei gleichzeitige SQLite-Verbindungen, Settings-Kollision, Kampagnenisolation, ungültige IDs, stale Quittierung), `app/test/player_action_outbox_migration_test.dart` (v1→v2 inklusive Neustart, beschädigtes altes JSON mit Rollback).
- **GETESTET:** Basis-main über CI #39932399488, nicht dieser Branch. **NICHT GETESTET:** Flutter-Format/Analyse/Test, komplette CI, Android-APK, reales Android-Gerät und Upgrade eines echten Nutzergeräts auf dem neuen Code-HEAD. **BLOCKIERT:** Lokales Flutter-/Dart-SDK in dieser Sitzung nicht verfügbar; aktuelle CI des Funktionsbranches muss geprüft werden. **NOCH NICHT IMPLEMENTIERT:** Genau-einmal-Ausführung externer KI-Provider, genereller atomarer Update-Vertrag für sämtliche App-Einstellungen, vollständige SRD 5.2.1.
- **Dateien:** `app/lib/data/campaign_repository.dart`, `app/lib/data/sqlite_campaign_repository.dart`, `app/lib/services/player_action_outbox.dart`, `app/test/player_action_outbox_test.dart`, `app/test/player_action_outbox_migration_test.dart`, `app/pubspec.yaml`; dieser Checkpoint und README/Changelog/Entwicklungsstatus.
- **Nächster Schritt nach diesem PR:** Finale CI-Checks auf dem Head auswerten, eventuelle Dart-/SQLite-Migrationsfehler korrigieren; danach als separates Paket weitere `GameController`-Einstellungsänderungen auf atomare Teilupdates prüfen. Keine Freigabe ohne grüne CI und gesonderte Geräteprüfung.

---
# CODEX-CHECKPOINT – aktueller Entwicklungs- und Übergabestand

> **Operative Wiederaufnahme** von Würfelraunen. Bei jeder aktiven Codex-Sitzung dieses Dokument **am Anfang prüfen und am Ende aktualisieren**; alle unten stehenden Werte sind eine Momentaufnahme und niemals Ersatz für einen erneuten GitHub-Check. Einstieg: [CODEX_CONTINUATION_PROMPT.md](CODEX_CONTINUATION_PROMPT.md).
>
> Stand der ersten Bestandsaufnahme: **2026-10-23, Europa/Berlin**. GitHub-API-Beobachtung vor Erstellung dieses Dokumentationsbranches. Nicht verifizierte zukünftige Änderungen oder CI-Ergebnisse werden nicht vorweggenommen.

## 1. Quelle der Wahrheit und Git-Baseline

| Merkmal | Verifizierter Ausgangswert |
| --- | --- |
| Produkt | Würfelraunen – Der lebendige Spielleiter |
| Repository | https://github.com/ManuEtt/Dnd |
| Hauptbranch | main |
| main HEAD bei Bestandsaufnahme | b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9 |
| Letzter hier bestätigter erfolgreicher Main-CI | https://github.com/ManuEtt/Dnd/actions/runs/39932399488 |
| CI geprüfter SHA | b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9 |
| CI Status | completed / success |
| Version aus app/pubspec.yaml | 0.8.30+80 |
| Offene PRs bei Bestandsaufnahme | keine (GitHub-API) |
| Dokumentations-Arbeitsbranch | docs/autonomous-codex-handoff-20261023 |
| Inhalt des Branches | dieser Checkpoint, aktueller Codex-Prompt, README- und Einstiegshinweise |
| Produktionsstatus | Android-Alpha; kein vollständiges D&D-SRD-Regelwerk |
| Lizenz | Offizielles SRD 5.2.1, CC BY 4.0; THIRD_PARTY_NOTICES.md beachten |

Die letzte geprüfte Main-CI #39932399488 ist auf obigem Main-Commit vollständig grün: Python-Struktur- und Testsuite, Node-/TypeScript-Backend-Typecheck/Build/Tests, Dart-Format und Flutter-Analyse, gezielte sowie vollständige Flutter-Tests, Android-Debug-APK, native Android-Tests, ARM64/ARM/x64-Alpha-Builds, Alpha-Release- und Quell-ZIP-Artefakte. **Das ist KEIN Nachweis für Installation/Funktionstest auf realem Android-Gerät.**

Dieser Dokumentationsbranch ist nicht durch den genannten Main-Lauf geprüft. README/docs-only-Änderungen lösen den Android-Workflow wegen dessen Pfadfiltern nicht automatisch aus. Bei Bedarf Workflow auf dem tatsächlich relevanten Branch explizit starten. Dokumentenänderungen sind keine neue App-Version.

## 2. IMPLEMENTIERT (basierend auf integriertem Code und bestandenem Main-CI)

- Flutter-App mit deutscher Fantasy-Gestaltung, Charaktererstellung, Charakterbogen, Kampagnenwahl, Abenteuer, Journal, lokalem SQLite-Spielstand und JSON-Import/Export; Sprachaufnahme/Text-to-Speech über die vorhandenen Geräteschnittstellen.
- Offline spielbarer Demonstrations-/Rabenwacht-Inhalt; optionaler separater Backend-Erzähler. Narration ändert keine bestätigten D&D-Regelwerte frei.
- SRD-5.2.1-Teilmechaniken zu Attributen/Fertigkeiten, Klassen, Kampf-/Würfelaktionen, ausgewählten Zaubern, Reaktionen, Effekten und Klassenentwicklung. Nicht mit vollständiger offizieller SRD-Abdeckung verwechseln.
- Fixierte Schnellaktionen im Abenteuer, mit überprüftem Kampfkontext und Erhalt freier Eingabeentwürfe: PR #128.
- Persistentes Action-Receipt und idempotente Spieleraktionen mit stabiler Handlungskennung über GameController.sendAction: PR #129.
- Persistenter ausstehender Handlungsauftrag je Kampagne via PlayerActionOutbox, explizites Wiederholen oder Verwerfen statt stillschweigender Wiederholung: PR #130.
- UI-Initialisierung, Wiederherstellungstests und Android-Tastaturregressionen korrigiert: PR #131.
- Parallel eintreffende Bestätigung derselben Spielerhandlung bei SQLite-Revisionsrennen abgeglichen: PR #132, siehe docs/PARALLEL_ACTION_ACK_20261023.md.

## 3. GETESTET – exakt belegte Ebene

- **Erfolgreiche GitHub-Actions-Prüfung**: Run #39932399488 auf SHA b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9.
- In diesem Lauf grün: Paket-/Strukturprüfungen, Python-Tests, Backend-Typecheck/Build/Tests, Dart-Format, Flutter-Codeanalyse, vollständige Flutter-Suite, nativer Android-JVM-Test, Debug-/Alpha-APK-Builds und Artefaktbereitstellung.
- Spezifische Tests für Outbox, verlorene Antworten, SQLite-Neustart und parallelen Action-Commit liegen im Quellcode. Ihr tatsächlicher bestanden/nicht-bestanden-Status wurde über die vollständig grüne Gesamtsuite des oben genannten Builds abgesichert. Prüfobjekt ist ausschließlich dieser Commit.
- Vom neuen Dokumentationsbranch wurden **keine** Flutter- oder Android-Tests lokal ausgeführt oder als bestanden behauptet.

## 4. NICHT GETESTET / BLOCKIERT

**NICHT GETESTET**
- Echte Geräteinstallation auf Android und Ausführung von Spracherkennung/TTS, Bildwähler, großen Schriftgrößen/Screenreader, komplexen Kampf- und Mehrklassenpfaden.
- Langfristiges Upgrade derselben installierten App und reale Datenmigration/Backup-Wiederherstellung auf verschiedenen Android-Versionen.
- Reale KI-Anbieter- und Kosten-/Datenschutz-End-to-End-Abnahme; keine freigegebene unbegrenzte API-Ausführung.
- Vollständiger amtlicher Regel-für-Regel-Abgleich der SRD 5.2.1; der historische Inventory-Stand ist keine Vollständigkeitsquote.

**BLOCKIERT**
- Ein dauerhaft autonomer Hintergrund-Codex ist in diesem Repository absichtlich nicht eingerichtet. Weitere Arbeit benötigt eine aktive Codex-Sitzung bzw. ausdrücklich autorisierte Orchestrierung.
- Eine sichere reale App-Update-/Produktionssignierung benötigt eigenes Release-/Geräteverfahren; vorhandene Alpha-APKs sind nicht automatisch Store- oder langlebige Upgrade-Releases.
- Freigaben für paid Provider, lizenzrechtlich unklare Grafiken und produktive irreversible Datenoperationen fehlen und dürfen nicht angenommen werden.

## 5. NOCH NICHT IMPLEMENTIERT – bekannte Grenzen

- Vollständige D&D-SRD-5.2.1-Regelwirkung und amtlich vollständig gegengeprüfte Zauber-/Monster-/Feature-Inventur; Coverage-Audit unter docs/SRD_5_2_1_COVERAGE_AUDIT.md hat offene Inventurlücken und keine belastbare Fertigstellungsquote.
- Allgemeine Ende-zu-Ende-Exactly-once-Garantie für externe AI-Provider. Eine vor SQLite-Commit erfolgte Provideranfrage kann bei manueller Wiederholung erneut berechnet werden.
- Transaktionale Outbox-Tabelle für konkurrierende Änderungen an allen App-Einstellungen; bisheriger Outbox-Speicher nutzt read-modify-write über vorhandenes Settings-JSON.
- Stabile Request-IDs für **alle** übrigen GameController-Operationen wie freie Würfe, separate Würfelentscheidungen und Effektaktionen.
- Vollständige autonome KI-Kampagnenleitung mit dauerhaftem NPC-Wissen und belastbarer Langzeitkonsistenz in allen freien Spielsituationen.

## 6. Technische Entscheidungen und unveränderliche Verträge

1. Regeln und Story strikt getrennt: app/lib/rules/rules_api.dart, app/lib/story/story_api.dart und story_rule_boundary.dart; Tests der Importgrenze einhalten.
2. Nur validierte Aktionen mutieren Held/Kampf/Inventar/Ressourcen; atomare Snapshot-/Event-/Revisionsspeicherung in SQLite. Importformat/schemaVersion=1 nicht stillschweigend ändern.
3. Offene Handlung vor Ausführung dauerhaft merken; beim Neustart nicht ungefragt wiederholen; identische bestätigte Request-ID nicht doppelt anwenden. Reale Drittanbieteraufrufe bleiben ein separates Risiko.
4. Normative SRD-Quelle und CC-BY-4.0-Namensnennung; keine Buchinhalte außerhalb der Lizenz kopieren. Keine privaten Spielstände oder Geheimnisse in Git.
5. Feature-, Story- und UI-Inkremente nur in kleinem separatem Branch mit Tests und GitHub-PR. Kein Merge auf Basis früherer CI; kein Force-Push oder ungesichertes Löschen.
6. Bestehende CHECKPOINT.md, DEVELOPMENT_STATUS.md, CHANGELOG.md und ROADMAP.md enthalten historische Zwischenstände und gelten nicht automatisch als aktueller Head-Nachweis.

## 7. NÄCHSTER KONKRETER ARBEITSSCHRITT

**Empfohlenes erstes Arbeitsziel: Outbox-Einstellungen unter konkurrierenden Schreibern absichern (kleines Integration-/SQLite-Inkrement).** Vor der Umsetzung das Problem reproduzieren, prüfen, ob andere Entwickler bereits daran arbeiten, und die tatsächliche Priorität anhand aktueller CI neu bewerten. Wenn die CI rot ist, deren Fehler vorrangig beheben.

**Definition of Done:**
1. Reproduzierbarer SQLite-Test zeigt das Risiko zweier konkurrierender Einstellungen-Schreiber bzw. einer Outbox-Operation und Einstellungen-Speicherung.
2. Persistente Outbox in einen transaktionalen Datenbankpfad überführen **oder** eine nachweislich serialisierte atomare Alternative einführen; bestehende Spielstände/Settings nicht verlieren.
3. Bei schemaVersion-/Datenbankschemaänderung explizite Migration und Neustarttests für bestehende SQLite-Dateien; alte App-Versionen nicht fälschlich als kompatibel versprechen.
4. Abgedeckt: offene Handlung laden, vor Ausführung speichern, Acknowledgement entfernen, kampagnengetrennter Betrieb, gleichzeitige Änderungen, Datenfehler, Rollback, KI-Erzähler nicht doppelt automatisch anfordern.
5. Vollständige lokal verfügbare Tests und GitHub-CI auf finalem PR-HEAD grün; echte Android-Geräteabnahme separat als offen dokumentieren.
6. Dieses Dokument und die aktuelle README-Sektion mit konkreten Commits, Runs, offener Risikoliste und anschließendem Arbeitspaket aktualisieren.

**Prüfkommandos:**
- python3 scripts/verify_project.py
- python3 scripts/check_domain_boundaries.py
- python3 scripts/srd_coverage.py --json
- python3 -m unittest discover -s scripts/tests -v
- cd backend && npm ci && npm run typecheck && npm run build && npm test
- cd app && flutter pub get && flutter analyze && flutter test && flutter build apk --debug
- Android-Gradle-Tests und ABI-Alpha-Build wie .github/workflows/android-build.yml

## 8. Eintragsschema für künftige Updates

Zuletzt aktualisiert: 2026-10-23 (Initialversion; zukünftige Bearbeiter setzen genaue Uhrzeit/Zeitzone).

Vor jedem späteren Commit **oben** ergänzen/ersetzen: ISO-Zeit; main SHA; Arbeits-HEAD; PR-Links; App-Version; Anforderung und Entscheidung; Änderungspfade; IMPLEMENTIERT; GETESTET mit Link/SHA; NICHT GETESTET; BLOCKIERT; NOCH NICHT IMPLEMENTIERT; Datenmigration; Artefakte nur bei Existenz; die nächste konkrete Aufgabe. Historische geprüfte Runs als Historie behalten, aber nicht als Nachweis für spätere Commits darstellen.

**Historischer Beleg:** Baseline 2026-10-23, Version 0.8.30+80, Main-CI #39932399488 success auf b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9; Zeitpunkt vor eigenem Dokumentationsbranch.