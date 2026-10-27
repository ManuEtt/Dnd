# Würfelraunen – Der lebendige Spielleiter

## Chat B – NPC-Auswahl und sichere Wiederaufnahme bis in die Oberfläche (27.10.2026)

Neue Flutter-/SQLite-Ende-zu-Ende-Regressionstests in `app/test/npc_ui_outbox_restart_integration_test.dart` prüfen die bestehende explizite NPC-Auswahl durch das Abenteuer-Eingabefeld und die dauerhafte Outbox. Zwei gleichnamige Figuren dürfen nicht vermischt werden; die ausgewählte NPC-ID wird an den Mock-Spielleiter weitergeleitet. Ein nach bestätigtem Spielzug verlorenes Bestätigungssignal wird nach Neustart ohne erneute Provider-Anfrage abgeglichen. Eine ausstehende NPC-Auswahl aus einer älteren Kampagnenrevision bleibt dagegen sichtbar und wird nicht selbsttätig erneut gesendet. Dieses Testpaket baut auf dem Controller-PR #288 und dem UI-/SQLite-PR #290 auf; es verändert **keine** Produktionslogik oder Schema-Version.


## Chat B – NPC-Auswahl mit absturzsicherem Sendeauftrag (27.10.2026)

In generativen KI-Kampagnen erscheint am Texteingabefeld die Aktion **„NPC auswählen“**, wenn die bestehende Erzählsitzung `npc-selection-v1` unterstützt. Ein deutscher, scrollbarer und für Screenreader beschrifteter Dialog zeigt bestätigte NPCs samt Beziehung und eindeutiger Kennung – auch wenn mehrere den gleichen Namen haben. Nur ein ausdrücklicher Tipp auf eine Figur bindet ihre ID an den ausstehenden Spielzug. Ohne NPC-Auswahl funktioniert die Texteingabe unverändert. Das Gegenstück ist die revisionsgeprüfte Controller-Anbindung aus [PR #288](https://github.com/ManuEtt/Dnd/pull/288).

Die SQLite-Outbox wurde **transaktional von Version 2 auf 3** erweitert: ein optionales Paar aus NPC-ID und ursprünglicher Kampagnenrevision bleibt mit Text und Request-ID nach einem Neustart erhalten. Alte Sendeaufträge werden ohne NPC-Auswahl übernommen; eine veraltete Auswahl wird nicht unbemerkt neu gebunden. Bereits bestätigte Request-IDs können nach verlorenem Bestätigungssignal abgeglichen werden. Neue SQLite- und Flutter-Widget-Tests prüfen diese Grenzen. Kampagnen-JSON, Heldendaten und SRD-Mechaniken bleiben unverändert. Die volle CI-Abnahme auf dem PR-HEAD ist separat nachzuweisen.


## Chat B – Ausdrückliche NPC-ID bei KI-Handlungen (27.10.2026)

Die Controller-Schnittstelle `sendAction(text, selectedNpc: NpcStorySelection.choose(campaign, npcId))` kann eine **vom Spieler ausdrücklich ausgewählte, revisionsgebundene NPC-ID** an einen geeigneten KI-Erzähler übergeben. Dazu muss dessen Sitzung sowohl `npc-identity-v1` als auch `npc-selection-v1` unterstützen und zum ausgewählten NPC mindestens eine bestätigte Beziehungsnotiz existieren. Ohne solche Auswahl bleibt die bisherige Namensauflösung unverändert. Die Prüfung erfolgt vor dem lokalen Spielzug, gegen die aktuelle SQLite-Revision und erneut beim Transport. Wiederholte Handlungskennungen sind auch an die gewählte NPC-ID gebunden. Vier neue SQLite-/Mock-Integrationstests prüfen die sichere Übertragung, fehlende Capability, veraltete Auswahl und Wiederholungs-ID-Kollision. **Die grafische NPC-Auswahl ist noch nicht angebunden** und die CI-Abnahme muss anhand des PR-Laufs erfolgen. Keine Regel-, Datenbank- oder Kampagnen-JSON-Migration.


## Charaktererstellung – Integrationskandidat (27.10.2026)

Die gestapelte SRD-5.2.1-Entwicklung aus [#264](https://github.com/ManuEtt/Dnd/pull/264), [#272](https://github.com/ManuEtt/Dnd/pull/272), [#273](https://github.com/ManuEtt/Dnd/pull/273) und [#275](https://github.com/ManuEtt/Dnd/pull/275) ist gemeinsam in einem **Integrationsbranch** vorbereitet: 4W6-Würfelzuordnung; explizit bestätigte, versionierte Startattribut-Herkunft; vier Hintergrundpakete mit Werkzeug-/Fertigkeitsauswahl und A-/B-Ausrüstung; Akolythenauswahl aus drei geprüften Heiligen Symbolen. Die Einzelbranch-CIs sind grün, die **gemeinsame Main-Integration und Android-Geräteabnahme** müssen separat erfolgen. Herkunftstalentwirkungen, Magic-Initiate-Zauberwahl und vollständige SRD-Charaktererstellung fehlen weiterhin. [Integrationsbeleg](docs/CHARACTER_STACK_INTEGRATION_20261027.md).

## Chat B – Fortsetzung einer expliziten NPC-Auswahl nach Neustart (26.10.2026)

Ein neuer Integrationstest überprüft die bestehende explizite NPC-ID-Übertragung über eine tatsächlich gespeicherte SQLite-Kampagne hinweg: zwei gleichnamige Figuren, Auswahl nur per ID, Erzählkontext nur aus der passenden bestätigten NPC-Chronik, Neustart, Revisionswechsel und Ablehnung einer veralteten Auswahl. Fehlende optionale Notizen in Alt-JSONs dürfen keine Erinnerung erfinden. Der Test verwendet einen lokalen Fake-Backendtransport ohne kostenpflichtige KI-Aufrufe. **Der endgültige CI-/APK-Nachweis auf dem finalen Branch-Commit steht gesondert aus.** Keine Änderung an App-/Regelcode, Spielständen, SQLite- oder JSON-Schema. [Chat-B-Checkpoint](docs/parallel/CHAT_B_CHECKPOINT.md).


**Würfelraunen** ist eine deutschsprachige, in Entwicklung befindliche **Fantasy-Rollenspiel-App für Android**. Sie verbindet lokale Soloabenteuer, Charakter- und Kampagnenverwaltung, ausgewählte Regeln aus dem **D&D System Reference Document (SRD) 5.2.1** und eine optionale KI-gestützte Erzählung.

Die App ist eine **Alpha-Version**, kein fertiger Ersatz für einen menschlichen Spielleiter und keine vollständige D&D-5e-Regelimplementierung. **Zum lokalen Spielen ist weder ein Account noch ein KI-Server erforderlich.**

> **Projektstand (26.10.2026):** Die Flutter-App deklariert Version **0.8.42+92**. Die Versionsnummer kennzeichnet den Entwicklungsstand, nicht eine abgeschlossene Geräte- oder Release-Abnahme. Aktuelle Integrationen, Testnachweise und offene Arbeiten stehen in [Entwicklungsstatus](DEVELOPMENT_STATUS.md) und [Codex-Checkpoint](docs/CODEX_CHECKPOINT.md).

## Was kann Würfelraunen?

Du erstellst einen Charakter, wählst ein Abenteuer und bestimmst mit eigenen Aktionen, wie sich die Geschichte entwickelt. Die App verwaltet die bestätigten Spielinformationen und trennt dabei **Spielregeln**, **Erzählung** und **gespeicherte Entscheidungen**.

- **Charaktere erstellen und verwalten:** Attribute, Fertigkeiten, Klassen, Ausrüstung, Ressourcen, Trefferpunkte und Charakterporträts bearbeiten. Die zwölf SRD-Klassen sind als Grundlage vorhanden; Klassenmerkmale und Stufenentwicklung sind noch nicht vollständig automatisiert.
- **Soloabenteuer spielen:** Lokale Demo und die eigene **Rabenwacht**-Kampagnenwelt mit Szenen, Entscheidungen, Quests, Figuren und Journal.
- **Würfeln und Kämpfen:** W20-Proben, Angriffe, Schaden, Initiative sowie ausgewählte Zustände, Aktionen, Reaktionen und Zauber regelgestützt behandeln. Komplexe Mehrfigurenkämpfe und das gesamte Zaubersystem sind noch nicht vollständig abgebildet.
- **Eine fortlaufende Geschichte behalten:** Kampagnen, Ereignisse, Entscheidungen, NPCs und bestätigte Weltinformationen lokal speichern und nach einem App-Neustart fortführen.
- **Deutschsprachige Fantasy-Oberfläche nutzen:** Charakterbogen, Abenteueransicht, Würfelanzeige, Kampf- und Zauberdialoge sowie Schnellaktionen in einer Fantasy-Gestaltung.
- **Sprache einsetzen:** Erzähltexte über Text-to-Speech vorlesen lassen und Spieleraktionen per Spracheingabe vorbereiten. Sprachdienste und ihre Offline-Fähigkeit hängen vom Android-Gerät und den installierten Anbietern ab.
- **Optional einen KI-Erzähler anbinden:** Ein eigener HTTPS-Backenddienst kann Erzähltexte ausgestalten und begrenzte Abenteuerideen vorschlagen. Im Standardmodus übernimmt ein kostenloser lokaler Demo-Erzähler diese Aufgabe.

### Funktionsstand im Überblick

| Bereich | Heute vorhanden | Wichtige Grenzen |
| --- | --- | --- |
| Charakterbogen | Charakterdaten, Attribute, Ausrüstung, Klassen-/Stufengrundlagen und ausgewählte Klassenaktionen | Keine vollständige Automatik sämtlicher SRD-Klassenmerkmale |
| Regeln und Kampf | Getestete Einzelmechaniken für Würfel, Angriffe, Ressourcen, Schaden, Zustände und einzelne Zauber | Nicht alle Kampf-, Ziel-, Monster- und Zauberregeln integriert |
| Kampagnen und Gedächtnis | Lokale Solo-Kampagnen, Rabenwacht, Journal, Quests und strukturierte NPC-/Weltdaten | Keine universell autonome Spielleitung |
| Spielstände | Lokales SQLite, bestätigte Ereignisse/Revisionen und JSON-Import/-Export | Keine Cloud-Synchronisierung und keine Verschlüsselung der lokalen Datenbank |
| Erzähler-Backend | Optionaler Fastify-Dienst mit Demo-Provider, Sitzungen, Validierung und Nutzungslimits | Kein fertig betriebener öffentlicher Dienst; externe KI nur nach eigener Einrichtung |
| Android | Flutter-App, Fantasy-UI, Sprache, Datei-Backup und automatisierte Tests | Produktive Signierung, vollständige Echtgeräte-/TalkBack-Abnahme und Store-Veröffentlichung offen |

**Wichtig:** Ein vorhandener Zauber-, Gegenstands- oder Klassenkatalog bedeutet nicht automatisch, dass jede darin genannte Wirkung bereits spielbar ist. Die technische Regelabdeckung wird gesondert erfasst: [Regelabdeckung](docs/RULE_COVERAGE.md) · [SRD-5.2.1-Audit](docs/SRD_5_2_1_COVERAGE_AUDIT.md).

## Technischer Aufbau

| Verzeichnis | Aufgabe |
| --- | --- |
| `app/` | Flutter-/Dart-App für Android mit Oberfläche, Charakteren, lokaler Regel- und Spielsteuerung |
| `app/lib/domain/` | Modelle, Würfel-, Klassen-, Kampf-, Ausrüstungs- und Zauberlogik |
| `app/lib/story/` | Kampagnen, Handlung, Story-Gedächtnis und Grenzen zwischen Erzählen und Regeln |
| `app/lib/data/` | SQLite-Kampagnenspeicherung und Datenzugriff |
| `app/lib/services/` | GameController, Sprachdienste, Backend-Verbindung und Sicherungen |
| `app/lib/ui/` | Fantasy-Oberfläche, Charakterbogen und Spiel-/Regeldialoge |
| `backend/` | Optionaler Node.js-/TypeScript-/Fastify-Erzähler mit Mock- oder konfiguriertem Anbieter |
| `scripts/` | Projektprüfung, Regelabdeckungsprüfung, Grafikerzeugung und Paketierung |
| `.github/workflows/` | Automatisierte Tests und Android-Alpha-Builds |
| `docs/` | Detaillierte Architektur-, Regel-, Entwicklungs- und Testdokumentation |

**Architekturprinzip:** Die lokale Regelengine bestätigt regelrelevante Aktionen und speichert sie zusammen mit dem Ereignisverlauf. Der KI-Erzähler darf Texte und validierte Vorschläge liefern, aber **nicht eigenmächtig Trefferpunkte, Würfe, Inventar oder andere Regelzustände ändern**. Mehr dazu in [ARCHITECTURE.md](ARCHITECTURE.md).

## Android-App lokal starten

Benötigt werden **Flutter 3.35.7**, **Dart 3.9.2**, **Java 17**, eine funktionierende **Android-SDK-Toolchain** sowie ein Android-Gerät oder Emulator. Das sind die im CI-Workflow verwendeten Toolchain-Versionen.

~~~bash
git clone https://github.com/ManuEtt/Dnd.git
cd Dnd

# Fantasy-Button-Grafiken vor Analyse/Build reproduzierbar erzeugen
python3 scripts/generate_fantasy_buttons.py

cd app
flutter pub get
flutter run
~~~

Eine lokale Debug-APK erstellen:

~~~bash
cd app
flutter build apk --debug
~~~

Der Build-Befehl wird **aus dem Projektwurzelverzeichnis** mit `cd app` aufgerufen; wer bereits im Verzeichnis `app/` steht, lässt diesen Schritt weg. Die lokale Demo benötigt **keinen laufenden Backendserver**.

### Optionale KI-Erzählung einrichten

Das Backend ist **optional**. Zum lokalen Entwickeln zunächst den kostenlosen Mock-Provider nutzen:

~~~bash
cd backend
cp .env.example .env
# In .env einen eigenen, ausreichend langen LOCAL_ACCESS_TOKEN setzen.
# AI_PROVIDER=mock und ALLOW_PAID_AI=false beibehalten.
npm ci
npm run dev
~~~

Für die **Android-App** wird ein eigener, gültig TLS-gesicherter **HTTPS-Endpunkt** benötigt; reines Loopback-HTTP ist nur für lokale Backend-/Entwicklungstests gedacht. In der App erfolgt die Verbindung unter **Einstellungen → KI & Kosten → Backend verbinden**, mit einem kurzlebigen Sitzungstoken.

Ein kostenpflichtiger KI-Anbieter wird **nicht automatisch aktiviert**: Anbieter, serverseitiger API-Schlüssel, Modell und ausdrückliche Kostenfreigabe müssen separat konfiguriert werden. Der Server speichert keine lokalen Kampagnendaten. Details und Token-Erstellung: [Backend verbinden](docs/BACKEND_CONNECTION.md) · [Backend-Dokumentation](backend/README.md).

## Tests und Qualitätssicherung

Die zentrale lokale Prüfroutine führt Python-/Projektprüfungen, Backend-Checks sowie Flutter-Analyse und Tests aus:

~~~bash
# In der Repositorywurzel
bash scripts/check.sh
~~~

Einzelne Prüfungen sind auch möglich:

~~~bash
python3 scripts/verify_project.py
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py --json
python3 -m unittest discover -s scripts/tests -v

cd backend
npm ci
npm run typecheck
npm test
npm run build

cd ../app
flutter pub get
flutter analyze
flutter test
~~~

Unter Linux benötigen SQLite-Tests `libsqlite3-dev`. Die CI-Definition steht in [android-build.yml](.github/workflows/android-build.yml); Einzelheiten in [TESTING.md](TESTING.md). **Eine reine README-Änderung löst wegen der Workflow-Pfadfilter keinen automatischen Android-Testlauf aus.** Ein vorhandenes oder grünes CI-Ergebnis gilt nur für den tatsächlich geprüften Commit.

## Spielstände und Alpha-APKs

- **Lokal gespeichert:** Charaktere, Kampagnen, bestätigte Aktionen und Erinnerungen liegen in der App-Datenbank. Ereignisse und Spielzustand werden konsistent gespeichert.
- **Import/Export:** JSON-Sicherungen sind über die App nutzbar; Android-Dateidialoge verwenden das Storage Access Framework. Ein Import wird vor der tatsächlichen Übernahme geprüft und bestätigt.
- **Vor Updates sichern:** Alpha-APKs verwenden derzeit eine Testsignatur. Ein Upgrade oder Wechsel zwischen Buildvarianten ist daher nicht in allen Fällen garantiert.
- **Buildartefakte:** Erfolgreiche GitHub-Actions-Läufe können Debug-APKs, Android-ARM64-Alpha und ein dazugehöriges Quellpaket bereitstellen. Ein Quellcode-Checkpoint allein ist **keine installierbare APK**.

Anleitungen: [Sicherungen](docs/SAVE_BACKUPS.md) · [Alpha-Artefakte](docs/ALPHA_RELEASES.md) · [APK-Download](docs/APK_DOWNLOAD.md).

### Chat D D-012: Sichere Gradle-Wrapper-Vorprüfung (26.10.2026)

Die Upload-/Projektprüfung weist nun manipulierte Gradle-Wrapper-ZIP-Dateien mit mehr als 512 Einträgen oder mehr als 16 MiB entpackten Daten zurück, bevor sie mit CRC-Prüfung entpackt werden; auch die JAR-Datei selbst ist auf 16 MiB begrenzt. Neue Python-Regressionstests prüfen zu große JAR-Dateien, komprimierte ZIP-Bombs, übergroße Eintragslisten und das weiterhin gültige originale Wrapper-JAR. Die bestehende Android-/Flutter-App und Spielstände ändern sich nicht; **vollständige CI dieses Arbeitsbranches noch abzunehmen**. Details: [Chat-D-Checkpoint](docs/parallel/CHAT_D_CHECKPOINT.md).

## Entwicklungsstand und nächste Schritte

Das Projekt wird in kleinen, überprüfbaren Inkrementen entwickelt. Vorrangig sind:

1. Laufende Branch-/PR-Integrationen mit nachvollziehbaren Tests abschließen; keine historischen Ergebnisse als neue Abnahme ausgeben.
2. Vorhandene NPC-Auswahl durchgehend von der Android-Oberfläche bis zum validierten optionalen Erzählvertrag anbinden.
3. **SRD 5.2.1 schrittweise vervollständigen**: Klassen-, Kampf-, Zauber-, Monster- und Ausrüstungswirkungen jeweils mit Tests und belegter Regelquelle ergänzen.
4. Fantasy-Oberfläche, Barrierefreiheit, Android-Echtgeräteprüfung, belastbare Release-Signierung und Updateabläufe weiter absichern.

Die technische Detailplanung wird nicht in dieser Einführungsseite dupliziert. Maßgeblich sind die **aktuellen** Dateien [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md), [ROADMAP.md](ROADMAP.md) und [docs/CODEX_CHECKPOINT.md](docs/CODEX_CHECKPOINT.md). Historische Checkpoints und Branch-Migrationen sind dort bzw. unter `docs/history/` dokumentiert.

## Regeln, Inhalte und Hinweise

Die Umsetzung orientiert sich an **D&D SRD 5.2.1** von **Wizards of the Coast LLC**, lizenziert unter **Creative Commons Attribution 4.0 International (CC BY 4.0)**. Die erforderlichen Namensnennungen und weiteren Hinweise stehen in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Eigene Fantasy-Geschichten und Grafiken werden getrennt von den SRD-Regeln behandelt.

Das Repository enthält Entwicklungssoftware. **Vollständige SRD-Konformität, fehlerfreien Spielbetrieb, Produktionssicherheit oder eine Veröffentlichung im Play Store werden nicht behauptet.**
