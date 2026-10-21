# Arbeitsanweisungen für kommende Entwicklungssitzungen

## Einstieg

1. Arbeitsverzeichnis, Git-Status, Branches, Remotes und vorhandene Commits prüfen.
2. Diese Datei sowie `DEVELOPMENT_STATUS.md`, `ROADMAP.md`, `ARCHITECTURE.md` und `TESTING.md` lesen.
3. Vorhandene Änderungen anderer Beteiligter erhalten. Das ZIP ist ein eigenständiger Entwicklungsstand, kein geprüfter Merge mit einer älteren Repositoryversion.
4. Werkzeuge mit `flutter --version`, `dart --version`, `java -version` und `node --version` prüfen.
5. Den nächsten offenen, überprüfbaren Schritt aus der Roadmap bearbeiten. Keine fertigen Funktionen unnötig neu schreiben.

Das vorgesehene Hauptrepository ist `ManuEtt/Dnd`, SSH `git@github.com:ManuEtt/Dnd.git`. Kein alternatives Hauptrepository anlegen. Kein Force-Push und keine fremden Dateien ohne Prüfung überschreiben. Geheimnisse niemals anfordern oder im Chat, in Logs, Quellcode oder Commits ausgeben.

## Arbeitsprioritäten und Modulverträge (Stand 21.10.2026)

Diese Regeln ergänzen die weiter unten stehenden Sicherheits-, Build- und
Kompatibilitätsvorgaben. Vor jeder Arbeit **tatsächlichen HEAD, offene Branches/PRs,
CI-Läufe und den aktuellen Quellcode** prüfen. Versions- und Statusangaben in
`README.md`, `ROADMAP.md`, `CHANGELOG.md` und älteren Abschnitten von
`DEVELOPMENT_STATUS.md` können historische Momentaufnahmen sein. Bei Widersprüchen
gelten beobachtbarer Code/Tests/CI und die neueste geprüfte Architekturentscheidung,
nicht die optimistischste Statusmeldung.

### Produktstand und verbindliche Quellen

- Produktname: **Würfelraunen – Der lebendige Spielleiter** (früher Aetheria);
  Flutter/Dart-Android-App in `app/`, Fastify-/TypeScript-Erzähler in
  `backend/`, SQLite/JSON-Spielstände, deutscher Solo-Spielleiter mit
  optionalem externem Erzähler. Weitere Plattformen, Online-Multiplayer und
  vollständige SRD-Automatik nicht als fertig ausgeben.
- Vor einer Regeländerung `docs/SRD_5_2_1_COVERAGE_AUDIT.md`,
  `docs/srd_5_2_1_requirements.json`, `docs/srd_5_2_1_entities.json`,
  `docs/UNIFIED_RULE_ENGINE.md` und die relevanten Fachtests lesen.
  `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md` ist ein **historisches
  Änderungsjournal**, keine aktuelle, vollständige Abdeckungsquote.
- Vor einer Architektur-/Storyänderung
  `docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md`,
  `app/test/rules_story_separation_test.dart` und
  `scripts/check_domain_boundaries.py` lesen.
- Der Stand vom 20.10.2026 erfasst 1.419 *Prüfaufträge* und 282
  Klassen-Freischaltungen, aber keine vollständig inventarisierte SRD und
  keinen zulässigen globalen Fertigstellungsprozentsatz. Zähler bei jedem
  Inkrement mit `python3 scripts/srd_coverage.py --json` neu ermitteln;
  **Katalogeintrag, Level-Unlock oder vorhandener Testdateiname sind kein
  Nachweis einer getesteten Regelwirkung**.

### Drei unabhängig entwickelbare Tracks

**A – Regelengine:** `app/lib/rules/rules_api.dart` ist die öffentliche
Regel-Fassade; bestehende Implementierungen liegen überwiegend in
`app/lib/domain/*rules.dart`, `dice_engine.dart`,
`rules_engine.dart`, `character_rule_engine.dart` und SRD-Katalogen.
Würfel, Ressourcen, TP/RK, XP, Zustände, Zauber, Klassen, Gegenstände und
Monstermechanik müssen deterministisch und ohne Story-, UI- oder
KI-Provider-Abhängigkeit testbar sein. Die Regelmodule importieren keine
`app/lib/story/`-Dateien. Regeln dürfen niemals aus freier Erzählung,
unbestätigten Monsterwerten oder einer generativen Antwort abgeleitet werden.

**B – Story/Kampagne:** `app/lib/story/story_api.dart` mit
`story_campaign_engine.dart`, `story_memory_engine.dart` und
`story_rule_boundary.dart` ist die neue Story-Fassade.
`app/lib/domain/rabenwacht_campaign.dart` und `domain/ai_story.dart`
sind **noch Legacy-Pfade**, keine Freigabe für beliebige Cross-Imports.
Neue `story/`-Module nutzen nur die vom Importprüfer zugelassenen
Dart-/Story- und Domänenmodell-/AI-Verträge: keine Flutter-UI, keine
Backend-Provider, keine direkten Würfel-/Kampf-/Regelimporte.
`StoryRuleBoundary.ensureRuleStateUnchanged` sperrt alle Felder außerhalb
seiner expliziten Story-Whitelist (Fail-Closed bei unbekannten neuen Feldern).
Insbesondere sind `hero`, `encounter`, `facts`, `quests`, Ressourcen und
Inventar **nicht** durch diese Story-Schnittstelle frei veränderbar.
Mechanisch relevante Quest-/EP-/Kampagnenaktionen des bestehenden
Rabenwacht-Legacy-Pfads sind erst nach expliziter Validierung durch die
Integrations-/Regelschicht zulässig. Narrative Behauptungen allein lösen
keinen Zauber, Kampf, EP-Gewinn, Gegenstands- oder Questabschluss aus.
Rabenwacht-Entscheidungen, Spoilerschutz, Rückkehrwege, NPC-Gedächtnis,
Negationen und einmalige Belohnungen gezielt gegen Regression testen.

**C – Integration/Persistenz:** `app/lib/domain/models.dart`,
`app/lib/domain/game_engine.dart`, `app/lib/services/game_controller.dart`
und `app/lib/data/` sind derzeit die gemeinsam genutzten
Kompositions-/Speichergrenzen. **Sie sind noch nicht vollständig
entkoppelt.** Rule- und Story-PRs sollen diese Dateien nicht unabhängig
voneinander parallel verändern. Notwendige Änderungen an gemeinsamen
Modellen, Befehls-/Ergebnis-DTOs, Controller, SQLite-Schema und Eventformat
über einen kleinen koordinierten Integrations-PR führen. Bestehende
`GameEngine`-Aufrufe, IDs, Zeitstempel, Events und `schemaVersion=1`
bleiben bis zu einer ausdrücklich getesteten Migration kompatibel.

Zielarchitektur: versionierte `RuleCommand`/`RuleResult`-Verträge und getrennte
`RuleSnapshot`/`StorySnapshot`-Adapter; Regelentscheidung **vor** Erzählung,
atomare Bestätigung **durch** Controller/Repository. Die erste Entkopplung ist
bereits vorhanden, der mehrtausendzeilige Legacy-`game_engine.dart` sowie
die kombinierten Modelle sind **keine vollständig migrierte Architektur**.
Alte öffentliche API nicht ohne Migration und Vergleichstests entfernen.

### Konkrete fachliche Reihenfolge

1. **Zauberengine:** offiziellen Zauberkatalog quellgenau inventarisieren,
   anschließend Klassenlisten, Vorbereitung, Komponenten, Reichweite/Ziele,
   Aktionen/Reaktionen, Slot-/Paktressourcen, Konzentration, Dauer,
   Hochstufen, Würfe, Effekte und Ereignisse pro Mechanismus implementieren.
2. **Klassen Stufe 1–20:** die katalogisierten Features *einzeln* auf
   tatsächliche Trigger, Entscheidungen, Ressourcen, Unterklassen,
   Multiclassing, Wirkung, Persistenz und Ende-zu-Ende-Tests prüfen.
3. **SRD-Monster:** nur amtlich verifizierte Statblocks, Traits,
   Mehrfachangriffe, Reaktionen, Zielauswahl, Initiative und Ressourcen
   integrieren; unbekannte Werte bleiben unbekannt.
4. **Kampf, Erkundung und Magiegegenstände:** Aktionsökonomie,
   Bewegungs-/Reise-/Sicht-/Deckungsregeln, Ladungen, Einstimmung und
   dauerhafte Effekte abschließen.

Vor neuen Features haben **reproduzierbare Buildfehler und bestehende
fehlschlagende Tests** Vorrang. Insbesondere unabhängige Regel-/Story-Branches
erst nach erfolgreich geprüfter Importgrenze integrieren. Das Scheitern
eines frühen Python-Schritts bedeutet, dass spätere Flutter-/APK-Schritte
**nicht geprüft** sind, nicht dass sie bestanden hätten.

### Belegpflicht je Inkrement

- Eine stabile Anforderungs-ID mit offizieller SRD-5.2.1-Stelle,
  Lizenz/Provenienz, Code-Pfad und konkretem Test führen. Status in den
  maschinenlesbaren Registern nur als `tested`, `partial`, `missing`
  oder `unverified` setzen; `tested` verlangt tatsächlich bestandene
  zutreffende Tests. Offene Inventurlücken nicht stillschweigend schließen.
- Happy Path **und** Gegenbeispiele: unbekannte Werte, Manipulation,
  fehlende Ressourcen, abgelehnte Aktion, doppelte IDs, Wiederholung,
  Race/Stale Revision, Neustart/SQLite, alte JSONs, Regel-/Story-Grenze.
  Automatische Test-Zufallsquellen und Mocks statt kostenpflichtiger KI.
- Für Rabenwacht neue Handlung getrennt von SRD-Geltung dokumentieren;
  alternative Wege/Entscheidungen nicht als zusätzliche Regelimplementierung
  zählen. KI generiert Erzählung und Vorschläge, aber keine bestätigten
  D20-Würfe, Monsterstatistiken, XP oder regelmechanischen Weltzustände.
- Für jede Änderung **IMPLEMENTIERT**, **GETESTET**, **NICHT GETESTET**,
  **BLOCKIERT** und **NOCH NICHT IMPLEMENTIERT** anhand belegter Ergebnisse
  unterscheiden. Dokumentation, Build, CI-APK und echte Geräteabnahme
  sind verschiedene Nachweise.

### Prüf- und Git-Workflow

In der Repositorywurzel (wenn lokal verfügbar):

```bash
python3 scripts/verify_project.py
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py
python3 -m unittest discover -s scripts/tests -v
```

Danach die weiter unten dokumentierten Backend-/Flutter-Prüfungen oder
`bash scripts/check.sh`, sofern die SDKs/Abhängigkeiten installiert sind;
zusätzlich für Android den Debug-Build und native Gradle-Tests gemäß
`.github/workflows/android-build.yml`. Keine Erfolgsmeldung ohne
konkreten Lauf/Commit; fehlendes SDK als **nicht ausgeführt** ausweisen.
Das strengere `srd_coverage.py --require-complete-inventory` darf bei
offenen Inventurlücken **absichtlich fehlschlagen**.

**Wichtig für Dokumentations-PRs:** `android-build.yml` nutzt
Pfadfilter nur für `app/**`, `backend/**`, `scripts/**` und den Workflow
selbst. Eine Änderung ausschließlich an `AGENTS.md` oder `docs/**`
startet daher **nicht automatisch** die normale Android-CI.
Erforderliche vollständige Abnahmen explizit per `workflow_dispatch`
auf geeignetem Stand anstoßen und deren Ergebnis abwarten; fehlende
Checks nicht als grünen Build interpretieren.

Pro Arbeitspaket einen kleinen Entwicklungsbranch von aktuellem `main`
anlegen, Änderungen inklusive Regressionstests dokumentieren und per PR
prüfen. Parallele Regel- und Story-PRs anhand gemeinsamer Dateien,
Merge-Basis, finalem HEAD und aktuellen CI-Läufen integrieren; nicht blind
veraltete Branch-Versionen über `main` kopieren. Bereits historisch
zusammengeführte Branches nur nach ancestry-/SHA-/Backup-Tag-Prüfung
bereinigen; niemals Force-Push oder ungeprüftes Branch-Löschen. Nicht für
reine Dokumentationskorrekturen die App-Version hochzählen. Ältere
`docs/AUTONOMOUS_DEVELOPMENT_STATE.md`-Angaben sind historische
Übergaben, keine verlässliche heutige Branch-/CI-Aussage.

Autonome Codex-Ausführung bedeutet **ein begrenztes, überprüfbares
Arbeitspaket pro Sitzung** gemäß `docs/CODEX_AUTONOMOUS_CYCLE.md`,
keine unbeaufsichtigte Endlosschleife, keine GitHub-Actions-Codex-Jobs,
kein kostenpflichtiger Anbieteraufruf ohne Freigabe und keine Zusage einer
automatischen Wiederaufnahme. Vor Limit/Abbruch verifizierten Stand,
konkrete Fehler, Commit/PR und nächsten Schritt dokumentieren.

## Architektur und Regeln

- Flutter in `app/`, Fastify/TypeScript in `backend/`; UI, Domänenregeln und Datenzugriff getrennt halten.
- Der Spielleiter liefert Erzählung und validierte Vorschläge. Zustandsänderungen erfolgen ausschließlich durch die autorisierte Geschäfts- beziehungsweise Regelengine.
- Natürliche Würfelergebnisse getrennt von Gesamtwerten halten; Boni niemals zweimal anwenden.
- Kontrollierbare Zufallsquellen für Regeln verwenden. Tests benötigen keine kostenpflichtige KI.
- Ältere persönliche Spielstände einschließlich ehemaliger Testkampagnen nur durch expliziten JSON-Import unterstützen; keine speziellen Startknöpfe, fest eingebauten Charaktere oder Namen aus alten Spielständen als Standarddaten vorgeben. Unbestätigte historische Kampfwerte nicht als neue Regelwerte übernehmen.
- Nur rechtmäßig verwendbare SRD-5.2.1-Inhalte und eigene Texte einsetzen. Neue Regelumsetzungen mit Quelle und Test versehen. `THIRD_PARTY_NOTICES.md` erhalten.
- Als Demo ausgewiesene Werte sind ausdrücklich festgelegte Demo-Daten; sie dürfen niemals importierte Nutzer-Charakterwerte ersetzen.

## Speicher- und Sicherheitsvorgaben

- SQLite-Schema und Importformat versionieren. Schemaänderungen brauchen Migrationen und Wiederherstellungstests.
- Snapshot und dazugehöriges Ereignis in derselben Transaktion speichern.
- Doppelte Ereignis-IDs dürfen keine zweite Zustandsänderung erzeugen.
- Ungültige Importe ohne Teiländerungen ablehnen. Den letzten bestätigten Zustand nach Neustart erhalten.
- Dauerhafte Anbieter-Schlüssel ausschließlich serverseitig speichern; `.env` und Benutzerexporte nicht committen.
- Authentifizierung, Rollenprüfung, Eingabevalidierung und Nutzungsgrenzen nicht durch Clientdaten umgehen lassen.
- Audio nicht dauerhaft speichern. Geräteabhängige Spracherkennung nicht als garantiert offline bezeichnen.
- Die vorhandene Solo-Architektur nicht als fertigen öffentlichen Mehrspielerdienst darstellen.

## Befehle

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

```bash
cd backend
npm ci
npm run typecheck
npm run build
npm test
```

Unter Linux benötigen SQLite-Tests `libsqlite3-dev`; der CI-Workflow installiert das Paket.

Flutter 3.35.7, Dart 3.9.2, Java 17 und Node.js 22.14.0 bilden die CI-Grundlage. Lockdateien mit Änderungen an Abhängigkeiten gemeinsam prüfen. App-Tests sollen insbesondere Regeln, Speichertransaktionen, Export/Import und relevante UI-Abläufe abdecken. Backend-Tests dürfen Fastify-Injection und Anbieter-Mocks verwenden. Erfolgreiche Tests nur mit tatsächlich beobachtetem Ergebnis dokumentieren.

## Abschluss eines Inkrements

Relevante Analyse, Tests und Build ausführen, Fehler beheben und `DEVELOPMENT_STATUS.md`, `CHANGELOG.md` sowie nötige technische Dokumentation aktualisieren. Klar zwischen **IMPLEMENTIERT**, **GETESTET**, **NICHT GETESTET**, **BLOCKIERT** und **NOCH NICHT IMPLEMENTIERT** unterscheiden. Build, Emulator und reales Gerät getrennt aufführen. Bei fehlendem Zugriff eine konkrete Übergabe erstellen und unabhängig mögliche Arbeiten fortführen. Geprüfte Änderungen mit aussagekräftiger Nachricht auf einem Entwicklungsbranch committen; nur bei vorhandener Berechtigung pushen.

## Autonomer Modus und Limit-Pause

Normale technische Entscheidungen selbst treffen und in kleinen, abgeschlossenen
Schritten entwickeln. Keine Credits kaufen und keine kostenpflichtigen
Limit-Zurücksetzungen auslösen. Bei einer tatsächlichen Limitwarnung keine große
neue Aufgabe oder zusätzliche Agentengruppe starten; zuerst den laufenden
Schritt testen, speichern und soweit möglich committen. Vor einer Pause den
fertigen Schritt, gesicherten Code-Commit, offene Aufgaben, bekannte Fehler und
den konkreten nächsten Schritt in DEVELOPMENT_STATUS.md dokumentieren. Ein
Kontingentstand darf nicht erfunden werden. Eine neue Sitzung liest zuerst den
Status und prüft anschließend den tatsächlichen Git-HEAD; automatische
Sitzungswiederaufnahme wird nicht vorausgesetzt.

## Backend-Erzähler seit 0.2.0

Sitzungstokens und Kostenfreigaben bleiben im Arbeitsspeicher. Die App darf nach
einem Neustart keinen Backendaufruf automatisch autorisieren. Nur validierte
freie Erzählungen werden extern ausgestaltet; Regelaktionen und historische
Werte bleiben lokal. Externe `stateChanges` sind unzulässig. Neue Erzählungen
und deren Checkpoints gemeinsam speichern. Weiterleitungen dürfen kein
Bearer-Token erhalten. Kein automatischer POST-Retry, da bereits übermittelte
Anfragen Kosten verursachen können. Hinweise: docs/BACKEND_CONNECTION.md.

Der zusätzliche Node-/Dart-Protokolltest läuft mit RUN_BACKEND_SMOKE=1 nach dem
Backend-Build. `scripts/check.sh` und CI aktivieren ihn; sein Loopback-HTTP ist
ausschließlich eine Testoption, die mobile Oberfläche akzeptiert nur HTTPS.

## Dateisicherung seit App 0.2.2

Android-JSON-Dokumente ausschließlich über die austauschbare BackupFiles-Schnittstelle und das Storage Access Framework öffnen beziehungsweise speichern. Keine allgemeine Speicherberechtigung und keine dauerhaften URI-Rechte ergänzen. Beide Kanalseiten prüfen Dateinamen und eine 10-MiB-Grenze. Importdateien zunächst im bearbeitbaren Dialog zeigen; vor ausdrücklicher Bestätigung keine Datenbankänderung. Bestehende versionierte Repositoryvalidierung erhalten. Abbruch, fehlerhafte Dateien, parallele Auswahl und UTF-8 mit Mocks beziehungsweise JVM testen; eine echte Dateiauswahl erfordert weiterhin Geräteabnahme. Details: docs/SAVE_BACKUPS.md.

## Upload und kleine APKs seit 0.2.3

Vor Analyse/Build `python3 scripts/verify_project.py` und
`python3 -m unittest discover -s scripts/tests -v` ausführen. Das Korrektur-ZIP
wird mit `python3 scripts/package_project.py <Ziel-außerhalb-des-Projekts>
--layout root` ohne zusätzlichen Dnd-Ordner erzeugt. Quellcode-ZIPs enthalten
keine APKs. ZIP-Integrität und Pflichtdateien prüfen; frühere Dateien nicht
ungeprüft überschreiben.

Kleine interne Alpha-APKs mit `flutter build apk --release --target-platform
android-arm64` beziehungsweise `android-arm`/`android-x64` bauen und die jeweilige
app-release.apk vor dem nächsten Build unter eigenem Namen sichern. Keine
ABI-Versionscodeoffsets aus `--split-per-abi` übernehmen: Die bereitgestellten
Sideload-Versionen sollen die normale Buildnummer behalten. Releasemodus bleibt
mit Debug-Testsignatur; echte Release-Signierung ist weiterhin offen. APK-Metadaten,
Signatur und Architektur prüfen. Neue Downloadlinks müssen aus bestätigten
Datei-/Artefaktergebnissen stammen; ein Workspacepfad allein beweist keinen
funktionierenden Benutzerdownload. Drive-Dateien privat halten; vorhandene
Freigaben nicht ändern. Details: docs/APK_DOWNLOAD.md.

## Attributstarthilfe seit 0.3.0

Grundwerte und Hintergrundsteigerungen getrennt halten. Standardsatz muss jeden
Wert genau einmal enthalten; Punktekauf validiert nur die neuen Basiswerte von 8 bis 15
und das Höchstbudget von 27 Punkten. Nicht ausgegebene Punkte werden sichtbar angezeigt und
nicht als ausdrücklich verbotener Regelverstoß dargestellt. Regelquelle und
Auslegung: docs/ABILITY_RULES.md. Hintergrundboni niemals auf bereits bestätigte
Endwerte erneut addieren. Die Oberfläche übernimmt nur ausdrücklich gewählte
Hintergrundsteigerungen, bewahrt bestehende Werte bis zur Bestätigung und lässt
manuelle/historische Charakterbearbeitung zu. Schema 1 bleibt kompatibel.
Die vier Hintergrundbezeichnungen sind keine vollständige Hintergrundimplementation:
Talente, Fertigkeiten, Ausrüstung und Klassenwerte werden weiterhin separat
bestätigt. Neue Ergänzungen an diesen Regeln vor Implementierung im offiziellen
SRD 5.2.1 prüfen und mit Domain-/Persistenztests absichern.

## Sprachdienste seit 0.3.1

Die Hauptsprache bleibt Deutsch. Native FlutterTts-Ergebnisse 0/false dürfen
nicht als Erfolg gespeichert werden. Stimmmetadaten für Netzwerkbedarf und
bekannt fehlende Daten erhalten; native Namen/Locale-IDs nicht umschreiben.
Locale-Normalisierung ausschließlich für Vergleich und Rangfolge verwenden.
Die Android-Erkennung kann bei der Sprachabfrage hängen; Abfragen begrenzen
und fehlende Listeneinträge nicht als Beweis fehlender Online-Unterstützung
interpretieren. Keine automatische erneute Mikrofonöffnung. TTS-Fehler können
native Futures offen lassen; lokale Abbruch-/Zeitgrenzen mit Mocks prüfen.
Eine Stimmensuche fordert keine Mikrofonberechtigung. Der Samsung-Gerätebericht
ist eine Benutzerrückmeldung, keine vollständige Entwicklerabnahme. Anleitung
und Paketquellen: docs/SPEECH_TROUBLESHOOTING.md.
