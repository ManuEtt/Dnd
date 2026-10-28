# Würfelraunen – Der lebendige Spielleiter

## Chat D – Geschützte Branches bleiben bei der automatischen Bereinigung erhalten (28.10.2026)

Der aktive GitHub-Actions-Workflow zur Archivierung vollständig integrierter Pull-Request-Branches prüft nun zusätzlich das GitHub-Flag `branch.protected`. Geschützte Branches werden **vor** SHA-Vergleich und möglicher Löschung übersprungen; die vorhandenen Schutzmechanismen für offene PRs, Archive und geänderte Referenzen bleiben erhalten. Ein Python-Test prüft den positiven Guard, negative Manipulationen und die bisherigen Sicherheitsbedingungen. [PR #335](https://github.com/ManuEtt/Dnd/pull/335) ist wegen der Überschneidung mit PR #337 auf dessen Branch gestapelt; kombinierte CI noch offen. Keine Branchlöschungen in diesem Paket, keine Spielstands-, SRD- oder Versionsänderung.

## Chat B – Gleichnamige NPCs im bestätigten Sitzungsrückblick (27.10.2026)

Der automatische Sitzungsrückblick unterscheidet jetzt gleichnamige NPCs anhand ihrer **bestätigten gespeicherten NPC-ID**, genau wie der gezielte Gedächtnisabruf. Zwei Figuren namens Mira mit derselben Beziehung erscheinen nicht mehr als undifferenzierte Namenseinträge. Eindeutige Namen behalten die bisherigen menschenlesbaren Texte; beschädigte mehrfach verwendete NPC-IDs werden nicht als bestätigte Identitäten ausgegeben. Die vorhandene 2.400-Zeichen-Grenze bleibt erhalten. Vier neue Flutter-Regressionstests prüfen gleiche Namen, ältere JSON-Spielstände ohne optionale Notizen, ungültige doppelte IDs und einen tatsächlich gespeicherten Sitzungsrückblick samt JSON-Roundtrip. Reine Storyprojektion: keine Änderungen an Regeln, Questbelohnungen, SQLite-Schema oder Backend.


## Chat D – Sicherere Android-Alpha-Bündelung (27.10.2026)

Die ARM64-Release-Prüfung weist nun vor dem Dekomprimieren manipulierte APK-ZIP-Dateien mit zu vielen Mitgliedern, zu großer entpackter Gesamtsumme oder extremen Kompressionsverhältnissen zurück. Vier neue Regressionstests sichern diese Grenzen. Kein Einfluss auf D&D-Regeln, Story, App-Daten oder bestehende Spielstände. **Neue CI/Android-Abnahme des zugehörigen Chat-D-Branches ist noch offen**; vorherige erfolgreiche Builds beweisen diese Änderung nicht. [Detailcheckpoint](docs/parallel/CHAT_D_CHECKPOINT.md).


## Chat D – Doppelte automatische Branch-Bereinigung stillgelegt (28.10.2026)

Die frühere Workflow-Datei `.github/workflows/retire-verified-branches-20261026.yml` konkurrierte mit der neuen SHA-/PR-gesicherten Bereinigung `cleanup-merged-safe-20261027.yml`. Am 27.10.2026 archivierte und entfernte der neue Workflow den Branch `test/chat-b/story-12-memory-transport-20261027`; der alte Workflow scheiterte anschließend beim erneuten Abruf mit HTTP 404 ([fehlgeschlagener Lauf](https://github.com/ManuEtt/Dnd/actions/runs/40589220593)). Der alte Eintrag bleibt als **manueller, schreibgeschützter Hinweis ohne Branch-Aktionen** erhalten. Drei neue Python-Tests prüfen Deaktivierung, Negativfälle und unveränderte Sicherungsprüfungen des Nachfolgers. Der neue [PR #329](https://github.com/ManuEtt/Dnd/pull/329) ist zur Review freigegeben; kombinierte CI noch ausstehend. Keine Spielstand-, Regel-, Versions- oder Datenmigration.

## Chat B – NPC-Aufträge bei zwei SQLite-Verbindungen sicher quittieren (27.10.2026)

Vier zusätzliche Integrationstests in `app/test/npc_outbox_multiwriter_cas_test.dart` prüfen die bereits in [PR #305](https://github.com/ManuEtt/Dnd/pull/305) ergänzte **atomare Vergleichs- und Löschlogik** der ausstehenden NPC-Handlungen über zwei gleichzeitig geöffnete SQLite-Verbindungen. Verspätete Bestätigungen dürfen weder einen bewusst ersetzten gleichnamigen NPC noch eine neue Kampagnenrevision löschen. Auch der Wechsel zwischen früheren reinen Textaufträgen und einer ausdrücklich ausgewählten NPC-ID ist abgesichert. Gleichzeitige Sendeversuche derselben Kampagne dürfen nur einen einzigen Auftrag erzeugen. Alle Tests verwenden echte lokale SQLite-Dateien, keine externen KI-Aufrufe. **Keine neue Produktionscode- oder Datenbankänderung**; die Tests benötigen PR #305.


## Chat B – Sichere Bestätigung ausdrücklich ausgewählter NPC-Handlungen (27.10.2026)

Beim Entfernen eines ausstehenden Spielerauftrags vergleicht die SQLite-Outbox jetzt **Handlungskennung, exakten Text, gewählte NPC-ID und ursprüngliche Kampagnenrevision**, statt nur Kennung und Text. Ein verspätetes Bestätigungssignal für die erste „Mira“ kann daher keinen später neu angelegten Auftrag für die zweite „Mira“ beseitigen. Die Prüfung und Löschung erfolgen in einer SQLite-Transaktion; auch der Fallback für ältere Repository-Implementierungen vergleicht beide NPC-Felder. Zwei neue SQLite-Regressionstests prüfen falsche IDs/Revisionen und die Wiederverwendung derselben Test-Handlungskennung nach bewusster Auftragsersetzung. Zusätzlich nennt der Fehler für zu neue Datenbanken nun die tatsächlich unterstützte SQLite-Version 3. Kein Schema-, Export- oder SRD-Regelwechsel. Dieses Paket baut auf [PR #303](https://github.com/ManuEtt/Dnd/pull/303) auf.


## Chat B – ausstehende NPC-Handlungen klar anzeigen (27.10.2026)

Die Anzeige einer ausstehenden Spielhandlung ist nun als separate, zustandslose Komponente `PendingActionStatus` implementiert. Sie bewahrt die bisherigen UI-Kennungen für Wiederholen, Verwerfen, laufendes Senden und Fehlermeldungen. Bei einer ausdrücklich gewählten Figur erklärt sie, dass deren Auswahl an den gespeicherten Auftrag gebunden bleibt und bei veralteter Revision bewusst verworfen und neu getroffen werden muss. Fünf kleine Flutter-Widgettests prüfen die Darstellung und Buttons **ohne** SQLite, Netzwerk, TTS oder Widget-/FFI-Zeitsteuerungsabhängigkeiten. Der fachliche Controller-/SQLite-Schutz aus den Basis-PRs #288, #290 und #303 wird dadurch nicht verändert. Keine Datenbankmigration oder D&D-Regeländerung.


## Chat B – deterministische Wiederaufnahme von NPC-Sendeaufträgen (27.10.2026)

Die sichere Wiederaufnahme einer ausdrücklich gewählten NPC-ID nach SQLite-Neustart wird jetzt durch die gemeinsame Funktion `resolvePendingNpcAction(campaign, action)` bestimmt. Sie unterscheidet normale, gültige, bereits bestätigte, veraltete und nicht mehr verfügbare Auswahlen, ohne selbst Netzwerkzugriffe oder Speicheränderungen auszuführen. Die Abenteueroberfläche nutzt dieselbe Funktion; eine verlorene Bestätigung wird nur anhand eines **exakt zu Text, Request-ID und NPC-ID passenden gespeicherten Ereignisses** abgeglichen. Andernfalls ist eine erneute bewusste NPC-Auswahl erforderlich.

Der vorherige Flutter-Komplettwidgettest in `npc_ui_outbox_restart_integration_test.dart` wurde nach reproduzierbaren `WidgetTester`-/FakeAsync-Deadlocks in **vier echte asynchrone SQLite-/Controller-/Transportintegrationstests** umgestellt. Die eigentliche Dialogbedienung bleibt separat in `npc_story_selection_dialog_test.dart` geprüft; eine vollständig durchgeklickte App-Ende-zu-Ende-Abnahme wird damit **nicht** behauptet. Dies ist ein abhängiges Test- und Sicherheitsinkrement auf PR #300, der wiederum auf #292 → #290 → #288 beruht. Keine SQLite-, Export- oder Regelmigration.


## Chat B – NPC-Auswahl und sichere Wiederaufnahme bis in die Oberfläche (27.10.2026)

Neue Flutter-/SQLite-Ende-zu-Ende-Regressionstests in `app/test/npc_ui_outbox_restart_integration_test.dart` prüfen die bestehende explizite NPC-Auswahl durch das Abenteuer-Eingabefeld und die dauerhafte Outbox. Zwei gleichnamige Figuren dürfen nicht vermischt werden; die ausgewählte NPC-ID wird an den Mock-Spielleiter weitergeleitet. Ein nach bestätigtem Spielzug verlorenes Bestätigungssignal wird nach Neustart ohne erneute Provider-Anfrage abgeglichen. Eine ausstehende NPC-Auswahl aus einer älteren Kampagnenrevision bleibt dagegen sichtbar und wird nicht selbsttätig erneut gesendet. Dieses Testpaket baut auf dem Controller-PR #288 und dem UI-/SQLite-PR #290 auf; es verändert **keine** Produktionslogik oder Schema-Version.


## Chat B – NPC-Auswahl mit absturzsicherem Sendeauftrag (27.10.2026)

In generativen KI-Kampagnen erscheint am Texteingabefeld die Aktion **„NPC auswählen“**, wenn die bestehende Erzählsitzung `npc-selection-v1` unterstützt. Ein deutscher, scrollbarer und für Screenreader beschrifteter Dialog zeigt bestätigte NPCs samt Beziehung und eindeutiger Kennung – auch wenn mehrere den gleichen Namen haben. Nur ein ausdrücklicher Tipp auf eine Figur bindet ihre ID an den ausstehenden Spielzug. Ohne NPC-Auswahl funktioniert die Texteingabe unverändert. Das Gegenstück ist die revisionsgeprüfte Controller-Anbindung aus [PR #288](https://github.com/ManuEtt/Dnd/pull/288).

Die SQLite-Outbox wurde **transaktional von Version 2 auf 3** erweitert: ein optionales Paar aus NPC-ID und ursprünglicher Kampagnenrevision bleibt mit Text und Request-ID nach einem Neustart erhalten. Alte Sendeaufträge werden ohne NPC-Auswahl übernommen; eine veraltete Auswahl wird nicht unbemerkt neu gebunden. Bereits bestätigte Request-IDs können nach verlorenem Bestätigungssignal abgeglichen werden. Neue SQLite- und Flutter-Widget-Tests prüfen diese Grenzen. Kampagnen-JSON, Heldendaten und SRD-Mechaniken bleiben unverändert. Die volle CI-Abnahme auf dem PR-HEAD ist separat nachzuweisen.


## Chat D – Pflichtdateien ohne symbolische Links prüfen (27.10.2026)

Die Python-Projektprüfung lehnt jetzt Pflichtdateien und deren übergeordnete Verzeichnisse ab, wenn sie symbolische Links sind. Dadurch werden keine verlinkten externen Backend-JSON-Dateien oder Gradle-Wrapper-Dateien mehr als reguläre Upload-Dateien geöffnet. Vier Regressionstests untersuchen Dateilinks, Verzeichnislinks, Wrapper-Nichtöffnung und defekte Links. Bestehende reguläre Projektkopien bleiben zugelassen. [PR #321](https://github.com/ManuEtt/Dnd/pull/321) ist ein **Draft**; die abschließende GitHub-CI ist auf dem finalen PR-Commit separat abzunehmen. Keine Migration oder App-Änderung.


## Chat B – Zwölf KI-Erinnerungen bis zur Story-API-Grenze absichern (27.10.2026)

Zwei neue Integrationstests prüfen das Erinnerungslimit **an der tatsächlich gesendeten Story-Anfrage**: Eine KI-Kampagne mit bestätigten Mira-Beziehungsnotizen und mindestens 18 allgemeinen Fakten wird in einer echten SQLite-Datei gespeichert, über den `GameController` fortgesetzt und mit einem lokalen Backend-Transport abgefragt. Sowohl mit als auch ohne `npc-identity-v1` erhält das Backend genau zwölf priorisierte und begrenzte Erinnerungseinträge. Die drei bestätigten NPC-Notizen bleiben zuerst; zusätzliche allgemeine Fakten verwenden lediglich die freien Plätze. Heldenwerte, Revision und gespeicherter Spielstand bleiben überprüfbar. Dieses Testpaket baut auf [PR #307](https://github.com/ManuEtt/Dnd/pull/307) auf und verändert keine Produktionslogik, Datenbankschemata oder SRD-Regeln.


## Chat B – Gemeinsames Budget für NPC- und allgemeine KI-Erinnerungen (27.10.2026)

Die vom KI-Spielleiter übermittelten bestätigten NPC-Notizen und allgemeinen Erinnerungseinträge teilen sich dasselbe Limit (standardmäßig 12 Einträge). Bisher wurde ein weiterer allgemeiner Eintrag angehängt, selbst wenn NPC-Notizen das Budget schon vollständig belegten. `NpcNarratorMemory.merge` prüft jetzt die gemeinsame Grenze **vor** dem Anhängen allgemeiner Einträge. Neue Regressionen decken vollständig belegte Grenzen von einem und zwei Einträgen sowie verbleibenden Platz ab. Es gibt keine Änderung an NPC-Identitäten, SRD-Regeln, SQLite, Backend-Protokoll oder Kampagnenexport.


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


### Chat D D-014: Bedingte Dart-Modulimporte ebenfalls prüfen

Die Modulgrenzenprüfung schützt jetzt auch alternative URIs in `import`- und `export`-Direktiven einschließlich Kommentare zwischen den Direktivenbestandteilen, z. B. `if (dart.library.io)`: Damit können bedingte Imports nicht unbemerkt von der Regel- in die Storyschicht wechseln. Neun Python-Regressionen decken unerlaubte und erlaubte Varianten ab. Änderungen betreffen nur Entwicklungstests und statische Projektprüfungen, nicht die App-Speicherung. **Vollständige GitHub-CI für dieses Paket steht noch aus.**


## Branchmigration 28.10.2026 – Werkzeugprüfungen und ein aktiver Cleanup

PR #316 (bedingte Dart-Imports/-Exports), #335 (geschützte Branches erhalten)
und #301 (historische Story/UI-Bereinigung) sind auf Basis `dd0c2e94` durch
reguläre Merge-Commits zusammengeführt. Die ursprüngliche automatische
PR-301-Löschroutine bleibt bytegetreu mit SHA256 in der Historie, ihr ausführbarer
Workflow ist nur noch ein manuell startbarer, lesender Hinweis. Dadurch läuft
kein zweiter automatischer Referenzschreiber neben der gepflegten Bereinigung.
Der aktive Cleanup verlangt weiter erfolgreiche Android-CI des exakt aktuellen
Main, Ancestry, Archivtag und unveränderte Köpfe und schützt aktive PRs sowie
`branch.protected`.

**Lokal geprüft:** Projektstruktur, Story/Regelgrenzen und SRD-Register gültig;
195 Python-Tests bestanden. Zusätzlich 28 gezielte Grenz-/Cleanup-Tests nach
letzter Testverschärfung bestanden. **Noch offen:** kombinierte Flutter-/Backend-/
Android-/GitHub-CI des Gesamtmigrationsstands, Main-Integration und tatsächliche
Archivierung/Löschung. Keine Referenz wurde durch diesen Teilbranch entfernt.
App-/Speicherversionen unverändert. [Fachcheckpoint](docs/BRANCH_MIGRATION_TOOLING_20261028.md).
