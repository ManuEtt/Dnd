# ULTIMATIVER MASTER-PROMPT FÜR CODEX

> **Aktueller Codex-Einstieg (23.10.2026):** Bitte für neue Sitzungen stattdessen [CODEX_CONTINUATION_PROMPT.md](CODEX_CONTINUATION_PROMPT.md) lesen und den [lebenden Checkpoint](CODEX_CHECKPOINT.md) fortschreiben. Dieser ältere Master-Prompt bleibt als langfristige Produktvision erhalten; referenzierte frühe PRs, Versionen und Testzustände (z. B. PR #6) sind **historisch**. Neuen Git-/CI-Stand vor jeder Entwicklung prüfen.
## Würfelraunen – autonome, regelkonforme Weiterentwicklung der D&D-Spielleiter-App

> **Diesen gesamten Text als neuen Auftrag an Codex übergeben.** Er ist ein Arbeitsauftrag, keine bloße Analyse. Setze die Aufgaben soweit wie möglich im tatsächlichen Repository um. Arbeite iterativ, überprüfbar und ohne unnötige Rückfragen. Eine Ausführung setzt eine laufende Codex-Sitzung bzw. eine ausdrücklich eingerichtete Ausführungsumgebung voraus; behaupte keine unabhängige Hintergrundarbeit.

### 1. Rolle, Ziel und unveränderliche Projektidentität

Du bist leitender Flutter-/Dart-/TypeScript-Entwickler, D&D-5E-Regelarchitekt, Testingenieur, Android-Release-Engineer, Datenbankentwickler, UI-/UX-Designer und Qualitätsverantwortlicher. Entwickle die bestehende App **Würfelraunen** zu einer stabilen, umfassenden deutschsprachigen digitalen Solo-Spielleiter-App mit optionaler Erweiterbarkeit für mehrere Spieler.

- **Repository:** `https://github.com/ManuEtt/Dnd` (`git@github.com:ManuEtt/Dnd.git`). Benutze dieses bestehende Projekt; lege kein alternatives Hauptprojekt an.
- **Anwendung:** Flutter/Dart unter `app/` für Android ARM64, Backend unter `backend/` mit Fastify/TypeScript, lokale Persistenz über SQLite.
- **Aktuelle Basis ermitteln:** `git fetch`, tatsächlichen `main`-HEAD, alle offenen Pull Requests und Actions prüfen. Bei Auftragserteilung war PR #6 (`feature/two-weapon-fighting-20261018`) offen, die letzten Android-Builds erfolgreich. Diese Information kann bereits veraltet sein: niemals blind einen alten Branch/Commit überschreiben oder dieselbe Arbeit doppelt durchführen.
- **CI-Basis:** Flutter 3.35.7, Dart 3.9.2, Java 17, Node.js 22.14.0, sofern der aktuelle Workflow nichts Abweichendes verbindlich festlegt.
- **Oberfläche:** Deutsch, dunkles Fantasy-/Charakterbogen-Design (Dunkelblau, Gold/Silber). Schnellaktionen ausschließlich in der Abenteueransicht, unten fixiert.
- **Keine feste Spielerfigur:** Arescan ist ausschließlich zulässiger Legacy-Kompatibilitätstest und niemals ein vordefinierter Spielstand, ein normaler Startcharakter oder fest eingebauter Abenteuerinhalt.

**Endziel:** Ein neuer Nutzer kann regelkonform einen Charakter erstellen, eigenständig ein KI-geleitetes Abenteuer beginnen, frei handeln, erkunden, sprechen, handeln, kämpfen, würfeln, zaubern, Gegenstände nutzen, Stufen aufsteigen, Entscheidungen und deren Konsequenzen dauerhaft speichern und zu jedem Zeitpunkt sicher fortsetzen. Alle vom Projekt unterstützten Mechaniken folgen dem verbindlichen Regelwerk. Keine Spielregel darf nur durch Beschreibungstext „implementiert“ erscheinen.

### 2. Verbindliche Regeln und rechtliche Grenzen

- **Normative Quelle:** Offizielles **Systemreferenzdokument (SRD) 5.2.1** für D&D 2024 / überarbeitete fünfte Edition, vorzugsweise seine autorisierte deutsche Fassung: `https://www.dndbeyond.com/srd`. Quellensprache, Abschnitt, Regelversion und begründete Auslegung pro Regel dokumentieren.
- **Nicht versehentlich mit SRD 5.1 / D&D 2014 vermischen.** Frühere Daten dürfen importiert werden, bekommen aber eine explizite Versions- oder Kompatibilitätsbehandlung.
- **Urheberrecht beachten:** Nur Inhalte aus SRD 5.2.1 unter CC BY 4.0, selbst erstellte Inhalte und nachweisbar anderweitig lizenzierte Inhalte ausliefern. Das SRD ist **nicht** identisch mit allen Inhalten aus Spielerhandbuch, Spielleiterhandbuch, Monsterhandbuch oder kostenpflichtigen Erweiterungen. Nicht freigegebene Zauber, Monster, Unterklassen, Welten, Texte oder Bilder nicht kopieren. Für Lücken entweder eigenständige kompatible Inhalte mit klarer Kennzeichnung erstellen oder die Funktion als noch nicht implementiert markieren. Lizenzhinweise und vorgeschriebene Namensnennung in `THIRD_PARTY_NOTICES.md`, App und Dokumentation aktualisieren.
- **Regelauslegung:** Bei Unklarheiten nach offiziellen Errata und autorisierten Quellen prüfen. Regellücken nicht mit erfundenen Automatismen überdecken. Optional vorhandene Hausregeln nur als deaktivierte, ausdrücklich wählbare Varianten mit abweichender Kennzeichnung.
- **Transparenz:** „100 % regelkonform“ oder „vollständig“ ausschließlich bei nachweislich vollständiger und getesteter SRD-Abdeckung behaupten.

### 3. Sofortiger Start: Bestandsaufnahme, Regelmatrix, Priorisierung

Führe ohne Rückfrage unmittelbar aus:

1. `AGENTS.md`, `ARCHITECTURE.md`, `DEVELOPMENT_STATUS.md`, `ROADMAP.md`, `TESTING.md`, `CHECKPOINT.md`, `docs/RULE_COVERAGE.md`, alle relevanten `docs/`-Dokumente und CI-Workflows lesen. Vorhandene Tests und Backend-Verträge analysieren.
2. Sämtliche Funktionen, Datenmodelle, UI-Bildschirme, Datenbanktabellen, Dienste, Workflows, Build-Artefakte und ungenutzten Module inventarisieren. Widersprüche zwischen README, Code und Tests aufdecken. Code ist maßgeblich für den Istzustand, SRD für die Norm.
3. `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md` anlegen und dauerhaft pflegen. Jede Regel erhält **ID, SRD-Abschnitt/Quelle, fachliche Beschreibung, betroffene Entitäten, Engine-Pfad, UI-Pfad, Persistenz, erforderliche Tests, Status und bekannte Abweichungen**. Verwende Status `FEHLT`, `TEILWEISE`, `IMPLEMENTIERT_UNGETESTET`, `GETESTET`, `BLOCKIERT`, `NICHT_IM_SRD`.
4. `docs/TECHNICAL_DEBT_AND_REMOVALS.md` anlegen: Dubletten, ungenutzter Code, tote Navigation, alte Demos, unbenutzte Assets, alte Skripte, veraltete Kommentare und widersprüchliche Regelimplementierungen, jeweils mit Nachweis und Risiken.
5. Eine priorisierte, abhängige Roadmap erstellen. **Zuerst kaputte Builds, Speicherintegrität, korrekte Charaktererstellung und zentrale Regelengine; dann übrige Regelbereiche und Spielkomfort.** Nicht bereits funktionierende Features neu schreiben.
6. GitHub-Issues oder überschaubare Pull Requests nur erstellen, wenn der Schreibzugriff existiert und sie wirklich helfen. Alle Änderungen auf einem aktuellen Featurebranch, niemals ungetestet direkt auf `main`.

### 4. Charaktererstellung – vollständig regelgeleitet statt freier Eingabemaske

Die Charaktererstellung ist ein nachvollziehbarer Schritt-für-Schritt-Assistent mit **Vorschau, Zurück, Korrektur, Validierung und expliziter Bestätigung**. Behandle erst neue Charaktere, dann Import/Bearbeitung historischer Figuren. Implementiere nur tatsächlich SRD-freigegebene Auswahlmöglichkeiten.

- **Klasse und Stufe:** Alle zwölf SRD-Klassen; Klassen-Trefferwürfel, Primärmerkmale, Rettungswurf-Übungen, zulässige Fertigkeitswahlen, Waffen-/Rüstungs-/Werkzeugübungen, Zauberattribute, Ressourcen und stufengerechte Klassenmerkmale. Der Klassenname ist nicht nur ein Textfeld.
- **Herkunft:** Regelkonforme Spezies, Hintergrund, Hintergrundfähigkeiten, Ursprungstalente, Sprachen und Startausrüstung/Startgold, ausschließlich in SRD-Abdeckung. Entscheidungen haben Regeln, Voraussetzungen und gespeicherte IDs.
- **Attribute:** Offizielle Methoden (Standardsatz, 27-Punkte-Kauf, ggf. regelkonforme Wurfmethode); Hintergrundboni gesondert anwenden und nie doppelt rechnen. Grenzen, Budget, Verteilung und abgeleitete Modifikatoren automatisch prüfen.
- **Startwerte:** Stufe 1 = 0 EP, weitere Stufen entsprechend SRD-EP-Tabelle; Übungsbonus; Klassen-Trefferwürfel; Trefferpunkte auf Stufe 1 aus Klassenwürfelmaximum + KO-Modifikator mit korrekter Untergrenze; Initiative, passive Werte, Bewegung, Rüstungsklasse nach bestätigter Ausrüstung und SRD-Sonderregeln; Klassenressourcen. **Keine erfundenen Werte für unvollständige Bögen.**
- **Fertigkeiten und Rettungswürfe:** Übungslisten regelgerecht auswählen; Fertigkeitsbonus aus Attribut, Übung, Expertise, temporären Effekten berechnen. Doppelübungen nicht fälschlich stapeln; Auswahlpflichten und Ersatzwahlen beachten.
- **Kämpfer:** Auf Stufe 1 insbesondere Zweite Luft, Kampfstil und Waffenmeisterschaft gemäß SRD; gewählte Stile und Waffenregeln müssen in der Kampfengine wirken. Weitere Fähigkeiten und Verbesserungen an den jeweiligen Klassenstufen vollständig einbinden.
- **Andere Klassen:** Klassen- und Unterklassenentwicklung, Ressourcen, Talente und Zauberwahl entsprechend verfügbarer SRD-Optionen; Mönch, Barbar, Paladin, Schurke, Zauberwirker usw. nicht gegenüber Kämpfern vernachlässigen. Mehrklassenregeln und Voraussetzungen vollständig validieren, Klassenstufen von Gesamtstufe trennen.
- **Inventar:** Waffen, Rüstungen, Schilde, Werkzeuge, Fokusmaterial, Verbrauchsgüter, Munition, Währung und magische Gegenstände als typisierte Entitäten. Einzelne, separat bearbeitbare Felder für Schaden/Würfel/Typ, Eigenschaften, Reichweite, Übungsanforderung, Gewicht, Preis, RK, Stärke-Anforderung, magischen Bonus, Ladungen, Seltenheit, Einstimmung, Menge und Zustände. Kein Parsing spielentscheidender Zahlen aus dem Beschreibungstext. Katalog-ID, eigene Abweichungen und Provenienz getrennt sichern.
- **Charakterbogen:** Alle abgeleiteten Werte sind sichtbar und bei jeder Änderung neu berechnet; Quellwerte vs. berechnete Werte klar unterscheiden. Benutzer darf bewusst Hausregeln wählen, darf aber nicht unbemerkt SRD-Regeln umgehen.
- **Speicherung:** Unvollständige Entwürfe separat sicher speichern; einen als regelkonform markierten Charakter erst nach erfolgreicher Gesamtabnahme freigeben. Bestehende Spielstände nicht stillschweigend ändern. JSON-/SQLite-Migrations- und Wiederherstellungstests ergänzen.
- **Stufenaufstieg:** EP-Grenzen, optional ausdrücklich aktivierter Meilensteinmodus, HP-Zuwachs, Klassen- und Unterklassenmerkmale, Talente/Attributsverbesserungen, neue Zauber, Ressourcen und begründete Entscheidungen. Keine automatische Auswahl ohne Zustimmung.

Erstelle End-to-End-Tests für neue Charaktere jeder Klasse auf Stufe 1, repräsentative Stufen 2–20, Speicherneustart, Import älterer Figuren, invaliden Input, Wahlkonflikte, Mehrklassenaufstieg und Grenzfälle.

### 5. Autoritative, deterministische D&D-Regelengine

**Regelentscheidungen müssen im Dart-Domänenmodell bzw. autorisierten Dienst erfolgen, nicht im KI-Erzähltext oder in UI-Spezialfällen.** Einheitliche typisierte Action-/Result-Modelle, überprüfbare Voraussetzungen und kontrollierbare Zufallsquellen verwenden.

Implementiere alle SRD-Mechaniken, soweit lizenzrechtlich verfügbar, einschließlich:

- W4, W6, W8, W10, W12, W20, W100; natürliche Ergebnisse, Würfelanzahl, Modifikatoren, Vorteil/Nachteil, Proben, Fertigkeitswürfe, passive Proben, Rettungswürfe und Vergleichsregeln.
- Initiative, Kampfteilnehmer und Gegnerwerte, Zugreihenfolge, Bewegung, Aktionsökonomie, **Aktion, Bonusaktion, Reaktion**, Extraangriff, Gelegenheitsangriffe und Sonderaktionen. Eine Bonusaktion darf nicht zweimal verbraucht werden.
- Angriffe mit Nahkampf-, Fernkampf- und Wurfwaffen; Reichweite, Deckung, Ziele, Sichtverhältnisse, Zweihändigkeit, leichte Waffen, Munition, Nachladen, Waffenmeisterschaften einschließlich **Nick**, Kampfstile, kritische Treffer, Treffer/Miss, Schadenswürfel, Schadensarten, Widerstand, Immunität, Verwundbarkeit und temporäre TP.
- **Kampf mit zwei Waffen:** Voraussetzung zweier passender bestätigter Waffen, Offenlegung Haupt-/Nebenhand, Bonusaktionsregel, Umgang mit Nick nach SRD, richtiger Attributsbonus und Kampfstil, Vermeidung doppelter Schadensboni, bewusste Zugbeendigung, Neustart mit offenem Wurf und Einmaligkeitsgarantie.
- Zustände, Erschöpfung, Konzentration, Gelegenheits- und Reaktionsfenster, Todesrettungen (natürliche 1/20), Stabilisierung, Heilung, Überraschung nach 2024er Regelstand, Kampfrunden und Regeln bei 0 TP.
- Zauberwirken: bekannte/vorbereitete Zauber, Stufen, Slots/Paktmagie, Komponenten, Aktionszeit, Reichweite, Dauer, Konzentration, Zielwahl, Rettungswurf-SG, Angriffsbonus, Upcasting, Wirkungswürfel, Resistenz, Flächeneffekte und Ressourcenverbrauch. Spells dürfen nicht nur als Namen/Erzählung existieren, sondern benötigen ausführbare Wirkung oder klaren Status `nicht implementiert`.
- Rasten, Trefferwürfel, Erholung, langfristige Ressourcen, Ausrüstungseffekte, Tragen/Verbrauch, Zeit und Kosten, Leveling, Tod und Wiederbelebung gemäß SRD.
- Erkundung und soziale Regeln: Reisezeiten, Bewegung, Wahrnehmung, Heimlichkeit, Fallen, Interaktion, Dialoghandlungen, passende Proben und nicht ausschließlich Kampf.
- Monster/NPC-Regeln aus freigegebenem SRD, Aktionsprofile, KI-Gegnerentscheidungen, Schadens- und Statuseffekte, Begegnungen, Belohnungen und EP. Fehlende SRD-Werte nicht ausdenken und als offiziell verkaufen.

Regelengine und Spieloberfläche dürfen keine getrennten, widersprüchlichen Boni berechnen. Eine gespeicherte Wurfanforderung enthält benötigten Regelkontext und ist gegen Manipulation validiert; **Würfelmodifikatoren nie zweimal addieren**. Idempotenz für bestätigte Handlungen, Ressourcen und Ereignisse durchsetzen.

### 6. Wirklich autonomer, aber regelgebundener KI-Spielleiter

Entwickle einen deutschsprachigen Spielleiter, der **eine eigene Geschichte entwerfen, auf Spielerentscheidungen reagieren und eine Kampagne konsistent fortführen** kann, ohne den Regelkern zu manipulieren.

- Beim Kampagnenstart aus Spielerpräferenzen, Charakterdaten und einem gewählten oder zufällig regelkonformen Thema einen Abenteuerplan erstellen: Ausgangslage, Welt, Orte, Ziele, Konflikte, Fraktionen, NPCs, Geheimnisse, mögliche Wendungen und mehrere offene Lösungswege.
- **Story-Bibel** mit dauerhaften Fakten, offenen und geschlossenen Quests, Beziehungen, NPC-Zielen, Orten, Ereignischronik, Inventarfolgen und Spielerentscheidungen. Kontinuität über viele Sitzungen und Neustarts erhalten, ohne den Kontext unkontrolliert wachsen zu lassen.
- Freie deutsche Spracheingaben in strukturierte **Absichten/Vorschläge** umwandeln. Bei notwendigem Wurf eine regeltechnische Anfrage erstellen; Spieler bestätigt oder würfelt, **danach** autorisierte State-Änderung, **danach** passende Erzählung. Ein KI-Modell darf niemals ungeprüft HP, EP, Treffer, Würfe, Gegenstände, Münzen oder Quests ändern.
- Der Spielleiter darf proaktiv Szenen, Begegnungen, Konsequenzen und sinnvolle Handlungsoptionen entwerfen, aber Spielerentscheidungen nicht ignorieren oder den Ausgang eines bestätigten Würfels nachträglich „erzählen“.
- Kampf und Nichtkampf sollen gleichwertig spielbar sein. Gegner und NPCs handeln glaubwürdig innerhalb ihrer bestätigten Fähigkeiten und Ressourcen.
- Lokaler/offline nutzbarer Grundmodus ohne kostenpflichtigen Dienst. Optionaler KI-Backend-Modus mit bewusst bestätigter Verbindung, Kostenhinweis, Limits, Datenschutz und Abbruchverhalten. Externe KI-Schlüssel ausschließlich serverseitig; kein automatischer unautorisierter Request, kein stiller bezahlter Retry.
- Sprache: deutsche Text-to-Speech-Ausgabe, Spracherkennung soweit geräteseitig verfügbar, Stop/Unterbrechen, kein dauerhafter Audio-Mitschnitt.
- Sicherheits- und Konsistenzprüfungen: ungültiges JSON, Halluzinationen, Prompt-Injection in Spielertext/Erzähltext und manipulierte KI-Responses dürfen nie Spielstand, Geheimnisse oder Kostenkontrollen umgehen.

### 7. Spielablauf, UX und Android-Qualität

Sorge für eine durchgängig spielbare Nutzerreise: App starten → Charakter erstellen oder importieren → Kampagne generieren/öffnen → Abenteuer auswählen → erkunden/dialogführen/kämpfen → Würfel bestätigen → Belohnung/EP/Inventar verwalten → rasten → Stufe aufsteigen → speichern/exportieren → App neu starten → exakt fortsetzen.

- Durchgängig deutsche UI, klare Regelnachweise/Tooltips, komfortabler Charakterbogen und nachvollziehbares Kampflog.
- Bereits vereinbarte Fantasy-Optik respektieren; keine unnötigen Komplett-Redesigns. Schnellaktionen **nur in der Abenteueransicht**, dort fest unten; auf anderen Ansichten keine Leiste.
- Für 320/360-dp-Geräte, Android-Tastatur, Bildschirmrotation, große Schrift und Screenreader testen. Keine überlaufenden Dialoge oder verdeckten Aktionen.
- Einfache Wahl der Aktion und nötiger Ziele; Spieler versteht warum eine Aktion verfügbar/gesperrt ist, welche Ressource sie kostet und wie das Ergebnis entstanden ist.
- Offline-first mit SQLite, sofortiger Speichersicherheit, nachvollziehbaren Änderungen, Versionsmigration, Schutz vor veralteten Revisionsständen, unveränderbaren Ereignis-IDs, sicherem JSON-Import/Export über Android Storage Access Framework und ohne unnötige Speicherberechtigungen.
- Mehrspielerfähigkeit modular vorsehen, aber nicht als fertig ausgeben, solange echtes Sitzungs-/Synchronisations-/Rechtemodell und Integrationstests fehlen.

### 8. Überflüssige Bestandteile entfernen – kontrolliert und nachweisbar

Es ist ausdrücklich erwünscht, das Repository **schlanker, eindeutiger und wartbarer** zu machen. Entferne schrittweise:

- Tote Codepfade, nachgewiesen ungenutzte Klassen/Dateien/Abhängigkeiten, doppelte Regeln, widersprüchliche Berechnungswege, veraltete Demo-Startpfade, verwaiste Grafiken, alte temporäre Workflows und irreführende Dokumentation.
- Fest eingebauten Arescan-Startspielstand und sonstige personenbezogene/voreingestellte Spielstände **nicht** reaktivieren. Historical-Import-Fixures und zugehörige Tests **behalten**, wenn sie die Rückwärtskompatibilität absichern.
- Keine produktiven historischen Daten, Migrationsroutinen, Lizenzhinweise, Sicherheitsregeln, Tests, Nutzer-Assets oder fremde Änderungen nur wegen vermeintlicher Redundanz löschen.
- Vor **jedem** Entfernen Suchergebnisse für Referenzen, dynamische Aufrufstellen, Laufzeitabhängigkeiten, öffentliche Schnittstellen, Migrationsbedarf und Testabdeckung prüfen. Für ersetzte Regelimplementierungen erst gemeinsame neue Domänenfunktion und Regressionstests schaffen, dann alte Umsetzung entfernen.
- Entfernte Dateien/Funktionen plus Begründung in `docs/TECHNICAL_DEBT_AND_REMOVALS.md` dokumentieren. Nach jedem Aufräumen Kompletttest und Build durchführen. Keine Massenlöschung als Fortschritt ausgeben.

### 9. Architektur, Validierung, Daten und Tests

- Regeln als kleine, testbare, deterministische Module mit klaren Abhängigkeiten implementieren; Berechnung, Controller, Datenbank und UI getrennt halten.
- Bevorzugt bestehende `app/lib/domain/`, `app/lib/services/`, `app/lib/ui/` und `backend/` weiterentwickeln. Keine zweite parallel arbeitende Regelengine aufbauen.
- Alle neuen Domänenobjekte strikt typisieren; Datenbankmigrationen vornehmen und unveränderte alte Spielstände testen.
- Für **jede Regel-ID** mindestens Positivfall, Negativfall, Grenzfall, Persistenz-/Replayfall und bei Nutzerinteraktion Widget-/Integrationstest. Tests für zufällige Regelkonstellationen auch mit festen Seeds.
- Regressionstests insbesondere für Attributswerte, TP, EP, Bonusaktionen, Ressourcen, Zaubereffekte, kritische Treffer, Nick, Mehrklassenstufen, Speichern/Laden, unfertige Entscheidungen, Fehlerbehandlung und historische Spielstände.
- Keine Regel als abgeschlossen markieren, solange die Engine sie nicht tatsächlich ausführt oder erforderliche UI-/Speichertests fehlen.
- Bei Änderungen an Bibliotheken, Flutter-SDK, Gradle, Android-Target oder Backend API zuerst Kompatibilität, Sicherheit und Lockfiles prüfen; nicht grundlos aktualisieren.

### 10. Verpflichtender Entwicklungs- und GitHub-Zyklus

Arbeite **in kleinen vertikalen Inkrementen mit funktionierendem Code**. Wiederhole autonom:

1. Neuesten Git-Zustand holen und mit offenen PRs vergleichen; keine offenen PRs überschreiben oder unbemerkt parallel dieselben Funktionen implementieren.
2. Eine klar abgrenzbare, priorisierte Regel-/UX-Lücke aus der Anforderungsmatrix wählen. Fachregel und Abnahmekriterien vor dem Code festhalten.
3. Eigenen Featurebranch vom aktuellen geprüften Stand erstellen. Keine Force-Pushes, keine direkte Änderung an `main`.
4. Regelcode, Datenmodell/Migration, UI und erforderliche Tests in dieser Reihenfolge liefern. Alte Daten kompatibel halten.
5. Formatiere und prüfe tatsächlich:

   ```bash
   python3 scripts/verify_project.py .
   python3 -m unittest discover -s scripts/tests -v
   cd app
   flutter pub get
   dart format lib test
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test
   flutter build apk --debug
   cd ../backend
   npm ci
   npm run typecheck
   npm run build
   npm test
   ```

   Führt ein Tool mangels SDK/Netzwerk/Gerät nicht aus, **nicht** behaupten, es sei bestanden. Verwende dann GitHub Actions, wenn zulässig. Bei Android-Migration zusätzlich die nativen Gradle-Tests ausführen. Fehler durch Logs auf die eigentliche Ursache zurückführen und beheben; rote Builds niemals ignorieren oder mit übersprungenen Tests „reparieren“.
6. Commit mit verständlicher Nachricht, Push in Featurebranch, Pull Request mit Teststatus, Regelabdeckung und möglicher Datenmigration. Android-CI abwarten und Logs prüfen. Pull Requests nur nach vollständigem grünen Build und ohne unaufgelöste Blocker mergen, sofern Berechtigung/Projektregeln das erlauben. Nutzerdaten und veröffentlichte Releases nicht automatisiert überschreiben.
7. Nach jedem geprüften Inkrement mindestens aktualisieren: `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md`, `DEVELOPMENT_STATUS.md`, `CHANGELOG.md`, `CHECKPOINT.md` und gegebenenfalls `README.md`/`ROADMAP.md`. Alte, falsche Startseitenangaben berichtigen.
8. Nächste Aufgabe selbstständig auswählen und fortfahren; keine Rückfragen für normale technische Entscheidungen. Nur bei echter Produkt-/Kosten-/Lizenzentscheidung oder riskanter irreversibler Änderung nachfragen.

**Kein autonomer Entwicklungs-Codex-Lauf in GitHub Actions einrichten.** Bestehende Actions bleiben reine Qualitäts-, Build- und Artefakt-Workflows; kein Modellaufruf, keine API-Credits oder Endlosschleifen in CI. Kontingentgrenzen sind zu respektieren.

### 11. ZIP, APK, Checkpoint und sichere Limit-Unterbrechung

- Bei jedem erfolgreich geprüften Meilenstein einen vollständigen **importierbaren Quellcode-Checkpoint** aus dem tatsächlichen aktuellen Code und getrennt eine über GitHub Actions erzeugte installierbare **Android-ARM64-APK** als Artefakt bereitstellen, soweit verfügbar.
- Projekt-ZIP muss `app/`, `backend/`, `scripts/`, `.github/`, Dokumentation, Lockfiles und sämtliche tatsächlich benötigten Quell-/Asset-Dateien enthalten; keine Geheimnisse, API-Keys, `node_modules/`, `.dart_tool/`, temporäre Builds oder bereits erzeugte APK im Quell-ZIP. `scripts/package_project.py` und `scripts/prepare_alpha_release.py` bevorzugen, sofern aktuell korrekt.
- Downloadlinks nur für tatsächlich existierende GitHub-Artefakte aus einem **erfolgreichen** Lauf angeben; bei fehlgeschlagenem Build nur als ungeprüften Quell-Checkpoint kennzeichnen.
- Vor Ende einer verfügbaren Arbeitssitzung bzw. bei einer tatsächlichen Limitwarnung **zuerst den kleinsten stabilen Schritt abschließen**, formatieren, Tests laufen lassen, Commit/Push soweit möglich ausführen und einen Checkpoint erstellen. Keine große neue Teilaufgabe mehr starten.
- Dokumentiere exakt: letzter HEAD, Branch, offene PRs, letzte erfolgreiche CI-Ausführung, implementierte Regel-IDs, noch rote Tests, bekannte Bugs, Dateien mit lokalen Änderungen, nächste konkrete Handlung und vorhandene Artefakte. Ein neues Codex-Fenster muss ohne wiederholte Grundanalyse fortsetzen können.
- Keine Behauptung, du könntest nach Sitzungsschluss selbständig weiterarbeiten; eine Folgesitzung braucht einen neuen Aufruf oder explizit bereitgestellte Orchestrierung. Kein Kauf zusätzlicher Credits ohne ausdrückliche Freigabe.

### 12. Abnahmekriterien für die Gesamtfertigstellung

Erkläre Würfelraunen erst dann zur vollständigen SRD-5.2.1-Spielleiter-App, wenn:

1. Die gesamte lizenzierbare **SRD-5.2.1-Regelmatrix** keine unbewerteten oder fälschlich als vollständig bezeichneten Regeln mehr enthält; alle projektseitig zugesagten Mechaniken sind implementiert und getestet.
2. Charaktere aus allen verfügbaren SRD-Klassen vollständig und regelkonform erstellt, gespeichert, importiert, verändert und aufgestuft werden können, einschließlich Fähigkeiten, Ressourcen, Zauber und Ausrüstung.
3. Normale Aktionen, Bonusaktionen, Reaktionen, Zauber, Zustände, Würfe, Kampffluss, Tod/Heilung, Rasten, soziale und Erkundungsabläufe sowie relevante Monster-/Itemeffekte tatsächlich konsistent funktionieren.
4. Der KI-Spielleiter autonom Geschichten erstellt und fortführt, langfristige Konsequenzen/Erinnerungen wahrt und niemals unautorisierte Regeländerungen durchsetzt.
5. Alle neuen und bestehenden Tests sowie Backend, Flutter-Analyse, Dart-Format, native Android-Tests und Android-ARM64-APK erfolgreich nachgewiesen sind. Kritische Nutzerreisen auf echtem Gerät separat abnehmen und nicht mit CI gleichsetzen.
6. Datenmigration, Neustart, Offlinebetrieb, Authentifizierung, Kostenfreigaben, Import/Export und Rollback getestet sind.
7. Tote/überflüssige Bestandteile mit Nachweis entfernt und Architektur, Lizenzen sowie Nutzeranleitung auf den tatsächlichen Zustand gebracht wurden.

### 13. Startbefehl – JETZT HANDELN

**Beginne sofort im bestehenden Repository.** Ermittele den neuesten Head, prüfe den Status von PR #6 und den CI-Build, erstelle die Regelanforderungsmatrix, identifiziere den wichtigsten echten Regelverstoß oder die wichtigste Lücke in der Charaktererstellung bzw. im laufenden Kampf, implementiere das erste funktionsfähige Inkrement mit Tests, übertrage es in einen eigenen GitHub-Branch, überprüfe die CI-Ergebnisse, behebe Fehler und setze mit dem nächsten Inkrement fort, solange die laufende Ausführungsumgebung und ihr Kontingent dies zulassen. Falls PR #6 grün und ohne Konflikt ist, kann er gemäß den Repository-Regeln zuerst sicher abgeschlossen werden. Keine erneute Zustimmung für gewöhnliche Entwicklungsschritte einholen. Sorge zu jedem Zeitpunkt dafür, dass ein funktionsfähiger `main`-Branch, gesicherte Spielstände und ein nachvollziehbarer Checkpoint erhalten bleiben.

**Gib nach jedem Inkrement nur einen knappen, überprüfbaren Fortschrittsbericht aus:** Regel-IDs, wirklich umgesetzte Funktionen, Commit/PR, bestandene/fehlgeschlagene Tests, APK-Artefakt, offene Risiken und der bereits bestimmte nächste Schritt. Priorisiere tatsächliche Codeänderungen statt Statusprosa.