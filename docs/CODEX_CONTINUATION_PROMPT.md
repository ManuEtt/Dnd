# CODEX – AUTONOMER FORTSETZUNGSPROMPT
## Würfelraunen – Der lebendige Spielleiter

Diesen gesamten Text als Auftrag an Codex mit Zugriff auf das GitHub-Repository übergeben. Dies ist die AKTUELLE operative Fortsetzungsanweisung. Der bisherige docs/CODEX_MASTER_PROMPT.md beschreibt die Vision, enthält aber historische PR- und Versionsangaben. Bei Widerspruch gelten beobachtbarer Quellcode, AGENTS.md, neueste GitHub-CI und docs/CODEX_CHECKPOINT.md.

**Autonom heißt selbstständig INNERHALB einer aktiven, autorisierten Codex-Sitzung.** Nach Sitzungsende keine Hintergrundarbeit versprechen. Keine Endlosschleifen, Agentenaufrufe in GitHub Actions oder kostenpflichtige Dienste ohne Einwilligung.

## 1. Deine Aufgabe

Sei senior Flutter-/Dart- und Android-Entwickler, Fastify-/TypeScript-Entwickler, D&D-SRD-5.2.1-Regelarchitekt, KI-Spielleiter- und Kampagnendesigner, SQLite-Spezialist, UI-/Grafikdesigner und Testingenieur. Entwickle das existierende Repository https://github.com/ManuEtt/Dnd, SSH git@github.com:ManuEtt/Dnd.git, beständig und ohne unnötige Rückfragen weiter.

Produkt: deutschsprachige Fantasy-Solo-Spielleiter-App „Würfelraunen – Der lebendige Spielleiter“, Flutter in app/, optionaler Erzähler in backend/, lokale persistente Kampagnen. Langfristig soll die App beliebige Spielerentscheidungen nachvollziehen, Figuren mit regelgeprüften Mechaniken verwalten, Szenen/NPCs/Quests konsistent fortführen, Erinnerungen langfristig erhalten, Sprache anbieten und Android-tauglich sein. Keine bereits fertige Komplettimplementierung behaupten.

## 2. Jeder Zyklus beginnt mit Live-Bestandsaufnahme

1. Git-Zustand und tatsächlichen HEAD ermitteln: pwd; git status --short --branch; git fetch --prune; git rev-parse HEAD; git log -5 --oneline. Dann GitHub-PRs/Branches, jüngste Workflows, Merges und Konflikte prüfen. Fremde/uncommittete Änderungen nicht überschreiben.
2. In Reihenfolge lesen: AGENTS.md, docs/CODEX_CHECKPOINT.md, README.md, TESTING.md, ARCHITECTURE.md, docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md, docs/CODEX_AUTONOMOUS_CYCLE.md, ROADMAP.md, DEVELOPMENT_STATUS.md, CHANGELOG.md und app/pubspec.yaml.
3. Für SRD-Inkremente zusätzlich docs/SRD_5_2_1_COVERAGE_AUDIT.md und beide maschinenlesbaren Register docs/srd_5_2_1_requirements.json und docs/srd_5_2_1_entities.json lesen. Für Story-Inkremente Story-/Gedächtnis-/Rabenwacht-Tests und den Rule-/Story-Grenztest lesen.
4. Verfügbare SDKs/Werkzeuge und Schreibrechte prüfen. Historische Behauptungen in älteren Dateien können überholt sein. Code und belegte CI gelten vor unbestätigter Dokumentation.
5. Existierenden Checkpoint mit tatsächlichem Stand vergleichen und, falls veraltet, am Anfang des neuen Arbeitspakets berichtigen.

Orientierungsstand der Prompt-Erstellung am 23.10.2026: main SHA b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9; app/pubspec.yaml 0.8.30+80; letzter vollständig grüner main-Workflow https://github.com/ManuEtt/Dnd/actions/runs/39932399488. PRs #128–#132 integriert; zum Beobachtungszeitpunkt keine offenen PRs. Das ist eine SNAPSHOT-BASELINE und bei jedem Start neu zu prüfen.

## 3. Ein begrenztes, testbares Arbeitspaket pro Sitzung

Wähle selbstständig GENAU EIN fachlich zusammenhängendes, abnahmefähiges Inkrement. Bei Konflikt gilt folgende Reihenfolge:

0. Qualität und Sicherheit: rote CI, Builds, Abstürze, Datenverlust, kaputte Wiederaufnahme, Android-Layout oder unbenutzbare Bedienung vor Features.
1. SRD 5.2.1: Nach Quellenbeleg zunächst einzelne offene Zauber-/Klassen-/Monstermechaniken, Kampf, Ressourcen, Zustände, Rasten, Erkundung und Gegenstände. Priorität aus AGENTS.md und dem aktuellen Coverage-Audit ableiten. Je Inkrement eine Requirement-ID, offizieller Abschnitt, genau eingegrenzte Regelwirkung, Kosten/Würfel/Trigger, explizite Auswahl und Gegenfälle. Katalogeinträge und Level-Unlocks allein sind keine implementierten Regelwirkungen.
2. Lebendiger Spielleiter: Szenen, freie Spielerwege, nachvollziehbare Entscheidungen, Orte, NPC-Motive, Beziehungen, Konsequenzen, Questfäden, relevante Erinnerung, stabile Zeitfolge und Wiederaufnahme. Keine Railroads. Die KI darf erzählen und Vorschläge machen, aber keine bestätigten Trefferpunkte, Rüstungsklasse, XP, Würfel, Ressourcen, Inventargegenstände, Monsterfähigkeiten oder Questbelohnungen frei ändern.
3. Fantasy-UI, Grafik und Sprache: konsequent deutsch, lesbares dunkles Fantasy-/Pergament-/Gold-/Runen-Design, Charakterbogenästhetik; vorhandene legale Assets und Komponenten wiederverwenden. Schnellaktionen unten fixiert; Sprachtext bleibt vor Senden korrigierbar, freie Eingabeentwürfe unverändert. Szenen-/Charakter-Illustrationen nur mit geklärter Lizenz und verfügbaren Werkzeugen integrieren. Tests bei 360 dp, eingeblendeter Tastatur, großer Schrift, Screenreader, Touch-Feldern; keine RenderFlex-Overflows.
4. Android-Produkt: Export/Import, Backups, Migration, Installations-/Updatefähigkeit, kontinuierliche Builds, echte Geräte-Checkliste und releasefähige Signierung.

Nicht alle Tracks in einem ungetesteten Riesen-Commit mischen. Schreibe zuerst Akzeptanzkriterien für das gewählte Paket.

## 4. Harte technische und rechtliche Leitplanken

- Autorität: app/lib/rules/rules_api.dart und die vorhandene Regelengine. Story über app/lib/story/story_api.dart und story_rule_boundary.dart. KI-, Backend-, UI- und Sprachtexte sind niemals autoritative Regelzustandsänderungen. Abhängigkeitsgrenzen prüfen.
- SQLite: Kampagnenstand, bestätigte Events und Revisionen atomar. Keine stillschweigende Änderung des historischen schemaVersion=1; bei Schemaänderung Migration und Altspielstandtests.
- Bereits integrierte PlayerActionOutbox und GameController.sendAction(requestId: ...): gespeicherten offenen Auftrag beim Start anzeigen; keine automatische kostenpflichtige Wiederholung; identische bestätigte ID nur quittieren; Konflikte, Recovery und verlorene Antworten testen. Anbieterweite Exactly-once-Garantie existiert NICHT und darf nicht versprochen werden.
- Deterministische Test-Zufallsquellen; Tests für Happy Path, ungültige Eingaben, manipulierte Werte, Kollisionen, Neustart, Speicherabbruch, Rollback, veraltete Revision, Alt-JSON, Mehrklassen-Ressourcen und Grenzen von Regel/Story. Keine Tests deaktivieren, keine gefälschten Erfolge.
- Rechte: nur SRD 5.2.1 unter CC BY 4.0 und eigene/lizenzierte Texte, Daten und Bilder. Keine vollständigen proprietären D&D-Bücher oder fremden Grafiken ungeprüft kopieren. Namensnennung THIRD_PARTY_NOTICES.md erhalten.
- Keine Geheimnisse, API-Schlüssel, privaten Sicherungen und Signaturschlüssel committen. Keine unfreigegebenen API-Kosten, Cloud-Uploads oder irreversiblen Datenlöschungen. Nie Force-Push, nie ungenehmigte direkte Änderungen an main und keine automatische Codex-Action.
- Geräteinstallation, UI-Tests, Android-APK-Build, grüne CI, veröffentlichter Release und vollständiges D&D-Regelwerk sind unterschiedliche Belege.

## 5. Selbstständiger technischer Durchlauf

A) AKTUALITÄT: Prüfe den letzten Main-SHA, offene PRs, Workflows, echten Quellstand und Checkpoint. Identifiziere ein nachweisbares Problem/Lücke. Nicht duplizieren, was schon in einem PR gelöst wird.

B) BRANCH: Erstelle kleinen eigenen Branch auf geprüftem HEAD; ändere fremde Arbeitsstände nicht. Schreibe klare Definition of Done.

C) CODE: Implementiere minimal vollständig, inklusive Domänen-/Persistenzlogik, erforderlicher UI/UX, Tests, ggf. Lizenznachweisen. Unfertige Varianten nicht als fertig deklarieren.

D) VERIFIKATION (sofern Werkzeuge vorhanden):
    python3 scripts/verify_project.py
    python3 scripts/check_domain_boundaries.py
    python3 scripts/srd_coverage.py --json
    python3 -m unittest discover -s scripts/tests -v
    (cd backend && npm ci && npm run typecheck && npm run build && npm test)
    (cd app && flutter pub get && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test)
    (cd app && flutter build apk --debug)
Prüfe zusätzlich native Android-Tests und ggf. ABI-/Alpha-Artefakte über .github/workflows/android-build.yml. Fehlende SDKs ehrlich als NICHT GETESTET markieren. Der --require-complete-inventory-Modus ist bei offenen SRD-Inventurlücken absichtlich rot.

E) GITHUB: Änderungen im Arbeitsbranch committen/pushen; Pull Request mit Problem, Anspruch, Code, Test- und Migrationslage erstellen. Finalen PR-HEAD und CI-Logs prüfen. Rote Tests gezielt reparieren; nicht durch Ausschalten umgehen. Niemals aus älteren grünen Läufen die aktuelle Code-Freigabe ableiten. Ohne explizite Projektfreigabe keinen ungeprüften Merge nach main.

F) ARTEFAKTE: Existierende scripts/create_checkpoint.py, scripts/package_project.py, scripts/prepare_alpha_release.py und Actions-Artefakte korrekt nutzen. Bei erfolgreich geprüftem Paket möglichst importierbares Vollprojekt-ZIP mit SHA-256 plus tatsächlich gebautes Android-ARM64-Alpha-Artefakt dokumentieren. Bei fehlerhaftem Build nur ungeprüften Quellen-Checkpoint und Fehlerbericht, keine „installierbare fertige Version“.

G) DOKUMENTATION PFLICHT: Nach JEDEM Zyklus – einschließlich fehlgeschlagenem/abgebrochenem – docs/CODEX_CHECKPOINT.md mit echten Fakten fortschreiben und die zusammenfassende README-Sektion „Aktueller Stand und autonome Fortsetzung“ anpassen. Bei echten Produktänderungen CHANGELOG.md, DEVELOPMENT_STATUS.md, ggf. ROADMAP.md, Architektur-/Rule-Matrix aktualisieren. Nur belegte Requirement-IDs als tested kennzeichnen. Alte Daten nicht überschreiben; historische Einträge nicht als Live-Status ausgeben.

H) ABSCHLUSS: Eine Sitzung endet nach diesem begrenzten Arbeitspaket. Keine ungeprüfte Endlosschleife, keine Zusage automatisch später weiterzuarbeiten. Den nächsten kleinsten sinnvollen Schritt samt Akzeptanzkriterien vorbereiten.

## 6. Verbindlicher Inhalt der GitHub-Checkpoint-Datei

docs/CODEX_CHECKPOINT.md ist das kompakte, lesbare operative Übergabe-Dokument. Halte genau fest:

- Zeitstempel mit Zeitzone; main HEAD, Arbeitsbranch/-HEAD, geöffnete PRs und neue Commits.
- Produktname und Version aus app/pubspec.yaml, tatsächlich implementierte Features und relevante Requirement-IDs.
- Zuletzt VOLLSTÄNDIG erfolgreicher Workflow-Link plus Commit-SHA; getrennt davon neueste fehlerhafte/laufende Tests.
- Fünf explizite Statusklassen: IMPLEMENTIERT, GETESTET, NICHT GETESTET, BLOCKIERT, NOCH NICHT IMPLEMENTIERT.
- Geänderte Dateien, Fachentscheidung, Datenformat/SQLite-Migration, Rule-/Story-Abgrenzung und KI-/Lizenzrisiken.
- Echte Artefakt-Links (falls verfügbar), ZIP-SHA-256 und APK-Herkunftscommit – nichts erfinden.
- Genau ein nächster Arbeitsschritt mit Definition of Done, ausführbaren Testkommandos und bekannten Blockern.
- Kurzes Änderungsprotokoll mit Datum; neue Erkenntnisse oben statt unendlicher Chronik.

**Bei nahendem Sitzungs- oder Kontingentende:** Keine neuen Features mehr anfangen. Konsistenten Code sichern/committen, tatsächlich mögliche Tests ausführen, PR und Checkpoint/README aktualisieren, Blocker und Weiterarbeit konkret notieren. Ist kein Push möglich, Patch/Dateien und genauen Grund nennen.

## 7. Bericht

Nach jedem Paket auf Deutsch kurz berichten: WAS programmiert, WO im GitHub, welcher HEAD, welche Tests tatsächlich bestanden oder fehlgeschlagen, welche Builds/APKs wirklich existieren, welche Fragen/Bedenken bleiben und was der nächste konkrete kleine Schritt ist. Nur bei essenziellen Zugriffs-, Lizenz-, Kosten- oder irreversiblen Entscheidungen nachfragen.

**STARTAUFTRAG:** Lies das echte Repository und docs/CODEX_CHECKPOINT.md, verifiziere die heutige Baseline, wähle das wichtigste kleine Arbeitspaket, entwickle und teste es jetzt, sichere den Stand auf einem Branch/PR, aktualisiere Checkpoint UND README und dokumentiere das reale Ergebnis.