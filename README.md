# Würfelraunen – aktueller Entwicklungsstand (19.10.2026)

**Schwerpunkt:** Fehlerbehebung für fehlende Attribute beim Ausrüstungsimport und Ausbau der D&D-5E-Regeln nach **SRD 5.2.1**.

**Entwicklungsbranch:** `fix/equipment-import-attributes-20261019` (Abzweigung von `main` `82f2786b`). **App-Version laut Quellcode:** `0.8.5+55`; kein Release für diesen Fix zugesagt, bis alle CI-/Android-Prüfungen erfolgreich sind. Der separate [Aufstehen-PR #8](https://github.com/ManuEtt/Dnd/pull/8) ist parallel offen und **nicht** Bestandteil dieses Fehlerfixes.

## Fehler behoben: Startausrüstung ohne SRD-Attribute

**Ursache:** Der Klassenassistent übernahm die ausgewählte Startausrüstung bisher nur als `name` und `quantity`, nicht als `catalogId` plus `stats`. Deshalb fehlten Eigenschaften bei Waffen, Rüstungen und weiteren Gegenständen, obwohl der SRD-Katalog bereits strukturierte Felder enthielt.

**Neuer Ablauf:**
- Alle 12 SRD-Klassen erhalten bei der bestätigten Startausrüstung eindeutige Katalog-IDs, soweit ein Artikel eindeutig dem enthaltenen SRD-Katalog zugeordnet ist. Automatisch vorhandene strukturierte Werte: Gegenstandsart, Preis, Gewicht, Schaden/Schadensart, Vielseitigkeit, Waffeneigenschaften/-meisterschaften, Reichweiten/Munition, RK-/Stärke-/Geschicklichkeitswerte und Heimlichkeitsnachteil, je nach Artikel.
- Die Bezeichnungen `Zweihänder`, `Arkaner Fokus (Kristall/Kugel/Kampfstab)`, `Kräuterkunde-Ausrüstung` etc. werden nur über **geprüfte eindeutige Aliasse** zugeordnet; freie Gegenstandsnamen oder Auswahlmöglichkeiten wie `Musikinstrument (nach Wahl)` / `Heiliges Symbol` werden **nicht** geraten.
- Besonders wichtig: `20 Pfeile` sind **ein** Katalogpaket mit 20 Pfeilen, nicht 20 Pakete mit 400 Pfeilen.
- Bei Charakter-JSON-Importen mit einer schon vorhandenen validen `catalogId`, aber fehlenden `stats`, werden die veröffentlichten Katalogattribute rekonstruiert. Eigens gespeicherte/überschriebene Stats bleiben unverändert; reine freie Namen bleiben unverändert.
- **Altcharaktere ohne Katalog-ID:** Im Charaktereditor **„Fehlende SRD-Gegenstandswerte ergänzen“** auswählen. Die App zeigt die eindeutigen Zuordnungen und ändert das Inventar **erst nach ausdrücklicher Zustimmung**. Unbekannte und mehrdeutige Einträge bleiben bestehen.
- Die Wahl eines Gegenstands im SRD-Katalog übernimmt zusätzlich dessen vorhandenen Informationstext; dies löst noch **keine magische Wirkung oder automatische Ausrüstung** aus. Rüstung, Schild und Waffe müssen wie bisher gesondert bestätigt/angelegt werden.

**Tests und Builds:** `app/test/starting_equipment_import_test.dart` (alle zwölf Klassensets, Waffen-/Rüstungsdaten, Pfeile, Aliasse, Import-/Legacy-/Eigenwerte-Schutz) und `app/test/ui_starting_equipment_import_test.dart` (Bestätigung und Altinventar-Reparatur) wurden ergänzt. Der vollständige GitHub-Actions-Lauf [39199122240](https://github.com/ManuEtt/Dnd/actions/runs/39199122240) auf Commit `a8f2f090` ist **erfolgreich abgeschlossen** (Formatter, Flutter-Analyse, Flutter-/Backendtests, Android-Debug-APK, native Tests und APK-Artefakte). Ein Test auf einem echten Android-Gerät steht noch aus.

## Vollständiges D&D-Regelwerk – realistischer Umfang

**Nicht fertig:** Die App deckt das vollständige D&D-Regelwerk weder jetzt noch nach diesem Inventarfix ab. Lizenz- und Regelgrundlage ist das [deutsche SRD 5.2.1](https://www.dndbeyond.com/srd) unter CC BY 4.0. Nicht im SRD enthaltene, geschützte Zusatzbücher, Monster, Kampagnen und Markeninhalte dürfen nicht als frei lizenzierbar vorausgesetzt werden.

Die Umsetzung erfolgt als überprüfbare Regelinkremente: (1) vollständige SRD-5.2.1-Anforderungsmatrix, (2) 12 Klassen und alle lizenzierten Herkünfte mit automatischer Charaktererstellung/-entwicklung, (3) Kampf-/Bewegungssystem und Zustände, (4) Zauber inklusive Ressourcen/Konzentration/Wirkungen, (5) Gegenstände/Ausrüstung/Schätze, (6) lizenzierte Monster/NPCs, Begegnungen und Exploration, (7) persistente KI-Spielleitung nur als Erzähler, (8) Migrationen, Import/Export und Android-/End-to-End-Abnahme. `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md` hält jede überprüfbare Regel mit Status und Tests fest. Keine pauschale 100-%-Behauptung.

**Nächste Abnahme:** Featurebranch-HEAD und PR-Checks vergleichen, mit Flutter 3.35.7 / Dart 3.9.2 formatieren, Analyse/Tests/Backend/APK vollständig prüfen. Erst danach in `main` integrieren, danach PR #8 rebasen bzw. erneut vergleichen. Eingangsstand bleibt erhalten; kein unkontrollierter GitHub-Actions-Codex-Workflow.

---

## Ältere Projektchronik

Die folgenden Einträge enthalten historische Statusangaben (u. a. der inzwischen geschlossene PR #7); der jeweils aktuelle Entwicklungs- und Prüfstand steht **oben**.

# Würfelraunen – Entwicklungsstand und Fortsetzung

**Stand:** 18.10.2026 · **App-Version im Quellcode:** `0.8.5+55` (`app/pubspec.yaml`) · **Entwicklung:** [Pull Request #7](https://github.com/ManuEtt/Dnd/pull/7) auf `feature/condition-source-ledger-20261018`, noch nicht in `main`.

**Produkt:** Deutschsprachiger D&D-5E-Solo-Spielleiter für Android mit Flutter/Dart, optionalem Fastify-/TypeScript-Erzähler und lokalem SQLite-Kampagnenspeicher. Normative Regelquelle ist das lizenzierte [SRD 5.2.1](https://www.dndbeyond.com/srd); die App setzt davon bisher **nur einen Teil** um. Die KI darf keine bestätigten Regelwerte ändern. Kein fest eingebauter Arescan-Startspielstand.

## Neue SRD-Regel: Bewusstlos → Liegend (19.10.2026)

**In Entwicklung auf PR #7:** Die Regelengine verknüpft jetzt bestätigte Bewusstlosigkeit mit dem eigenständigen Zustand `liegend`. Dies gilt bei einem Treffer auf 0 TP, beim Tod durch Schaden, bei bestätigten externen Zustandsquellen und bei neu bestätigten Charakterbogenänderungen. Nach TP-Heilung, einer natürlichen 20 bei der Todesrettung oder dem Ende der letzten Bewusstlos-Quelle bleibt `liegend` erhalten, bis der Spieler es regelkonform separat beendet. Mehrere Bewusstlos-Quellen werden weiterhin getrennt verwaltet. Ältere JSON-Spielstände werden beim bloßen Laden **nicht** umgeschrieben; die Folge wird erst bei einer bestätigten Zustandsänderung gespeichert.

**Zusätzliche Sicherheit:** Eine bestätigte Bearbeitung des Charakterbogens beendet bestehende Konzentration, sobald der Charakter dadurch handlungsunfähig wird. Tests für Schaden, Heilung, Todesrettungen, Quelldauer, JSON-Rundlauf und Charakterbogenbestätigung stehen unter `app/test/unconscious_prone_test.dart`. Die **CI-/APK-Abnahme dieser neuen Änderung** ist noch zu bestätigen; die zuletzt belegte erfolgreiche Gesamtprüfung gehört zum vorherigen Codecommit `c000e78b` (GitHub Actions [39165288268](https://github.com/ManuEtt/Dnd/actions/runs/39165288268)). Reale Android-Gerätetests bleiben offen. Der neue Code ist noch kein vollständiger Positions-/Bewegungs- oder Inventar-Ablege-Mechanismus.

## Aktuell in Entwicklung – quellgebundene Zustände

Im offenen PR #7 wurden die Ursachen einzelner Zustände als `ConditionEffect` mit eigener ID, Quelle und optionalem Ende des aktuellen bzw. nächsten eigenen Kampfzugs ergänzt. Manuelle historische Zustände bleiben getrennt; mehrere Ursachen wirken regeltechnisch nicht mehrfach und können getrennt entfernt werden. Zustandsursachen und Laufzeiten erscheinen im Charakterbogen, der Abenteuerbereich zeigt die wirksamen Zustände.

**Neue Bedienung im PR:** In der Abenteueransicht `Zustände verwalten` öffnen, einen der 14 unterstützten SRD-Zustände sowie eine bestätigte Quelle auswählen und die Änderung ausdrücklich bestätigen. Während des eigenen laufenden Kampfzugs kann ein Ende am aktuellen/nächsten eigenen Zug gewählt werden; außerhalb des Kampfes nur die ausdrücklich zu entfernende Variante. Über denselben Dialog lässt sich eine ausgewählte **einzelne Quelle** beenden, ohne weitere Ursachen oder manuelle Zustände zu löschen. Ein bestätigter handlungsunfähiger Zustand beendet Konzentration, Kampfrausch und Ausweichen; Entfernen startet diese nicht neu. Aktionen durchlaufen `GameEngine`, `GameController` und die transaktionale SQLite-Speicherung einschließlich erwarteter Spielstandsrevision. Freie Erzählungen vergeben keine Zustände.

**Tests/Qualität:** Domänen-, Dialog- und SQLite-Regressionsfälle für Quellenbesitz, Ablauf, Neustart, veraltete Dialoge und Rollback sind im PR eingereicht. Die abschließende CI- und APK-Abnahme für **diese** Erweiterung ist noch offen; kein neues installierbares Release oder erfolgreicher Gerätetest wird behauptet. Der letzte erfolgreiche `main`-Android-Lauf vor diesem PR war [39161290442](https://github.com/ManuEtt/Dnd/actions/runs/39161290442), Codecommit `50fd700e`. [Aktuelle PR-Prüfungen](https://github.com/ManuEtt/Dnd/pull/7/checks) zeigen, ob die Erweiterung inzwischen grün ist. Ein Draft-PR ist keine Freigabe.

**Offen:** vollständige SRD-Regelabdeckung, nicht kampfgebundene Zeit-/Konzentrationsdauern, Positions-/Fremdzielregeln, Vollständigkeit der Klassen-/Zauber-/Monsterwirkungen, weitere SQLite-/Widget-Grenzfälle und Abnahme auf echtem Android-Gerät. Keine kostenpflichtigen KI-Aufrufe oder unbeaufsichtigten Codex-Actions-Workflows.

**Wiederaufnahme:** Zuerst tatsächlichen GitHub-HEAD, PR #7, laufende Checks und eventuelle neue Commits vergleichen. Fehlgeschlagene Tests reparieren, App und Backend sowie Android-APK prüfen, anschließend nur nach grüner Abnahme freigeben. Detaillierte Dateien: [SRD-Regelmatrix](docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md), [Regelabdeckung](docs/RULE_COVERAGE.md), [CHECKPOINT](CHECKPOINT.md), [Entwicklungsstatus](DEVELOPMENT_STATUS.md), [Änderungsprotokoll](CHANGELOG.md) und [Codex-Master-Prompt](docs/CODEX_MASTER_PROMPT.md).

---

## Historische Entwicklungsnotizen (ältere Versionsstände)

Die nachfolgenden Abschnitte dokumentieren frühere Entwicklungsstände. Ihre damaligen CI-Aussagen und Versionsnummern sind **keine aktuelle Freigabeinformation**; maßgeblich ist die Zusammenfassung oben und die PR-/GitHub-Actions-Abnahme.

Aktueller Entwicklungsstand: **Würfelraunen 0.7.9+49**. Todesrettungen mit Mönch-/Kämpfer-Wiederholungen, gespeicherter deutscher Entscheidung und einmaliger Rettung je eigenem Kampfzug; korrigiertes Zugende und dauerhaftes Kampfrauschende bei Handlungsunfähigkeit. Charaktereffekte und zwei ausführbare SRD-Heilzauber bleiben integriert. Prüfstatus/Artefakte: [CHECKPOINT.md](CHECKPOINT.md); [GitHub-Import](IMPORT_0_7_9_49.md); [Regelabdeckung](docs/RULE_COVERAGE.md). Das SRD 5.2.1 ist teilweise umgesetzt.

Ältere Versionshinweise und ausstehende Prüfungen weiter unten beschreiben den damaligen Stand. Maßgeblich für die aktuelle Abnahme ist CHECKPOINT.md.

**Neue Regelengine 0.6.4+34:** Zauberplätze und Hexenmeister-Paktmagie werden jetzt getrennt verbraucht und gespeichert, Konzentration wird verfolgt, Rasten stellen Ressourcen wieder her. Im Charaktereditor unter „Fertigkeiten, Fähigkeiten & Zauber“ den Ressourcen-Dialog öffnen. Das sind bewusst noch **keine automatischen Zauberwirkungen**; siehe [docs/SPELLCASTING_RESOURCES.md](docs/SPELLCASTING_RESOURCES.md).

### Gemeinsame D&D-Regelengine ab 0.6.3+33

Spielhandlungen und Charakterbogen verwenden dieselben bestätigten Regeln für Erschöpfung, Initiative, Trefferwürfe, Rettungswürfe, Bewegung und zentrale Zustände. Vorteils- und Nachteilinformationen werden bei offenen Würfen gespeichert. Regelbasis und bekannte Grenzen: [Einheitliche Regelengine](docs/UNIFIED_RULE_ENGINE.md). Der neue Flutter-/Android-Build muss noch im CI bestätigt werden.

**Neues Regelpaket 0.6.2+32:** D&D-SRD-5.2.1-Erschöpfung
(W20-Abzüge, Bewegung, Rast, Tod) und konservative Zustandsauswertung.
Details: [docs/CONDITIONS_EXHAUSTION.md](docs/CONDITIONS_EXHAUSTION.md).
Vor APK-Freigabe CI bestätigen.

> **0.6.0+30 (Entwicklungsstand):** SRD-Waffen und Rüstungen können im Charaktereditor mit bestätigter RK-/Waffenvorschau angelegt werden. Ein vollständiger Flutter-/Android-Build steht für diese Version noch aus. Details: `docs/EQUIPMENT_RULES.md`.

## Neue Ausrüstungssuche (0.5.9+29 – CI ausstehend)

Im Charaktereditor unter „Inventar & Ausrüstung“ gibt es „Aus SRD-Ausrüstungskatalog wählen“. Der Katalog enthält 272 Waffen, Rüstungen, Gegenstände, Werkzeuge und namentliche magische Referenzeinträge; 38 Waffen und 13 Rüstungstypen aus der SRD-Tabelle sind vollständig mit Basisdaten erfasst. Freies Inventar bleibt nutzbar, bestehende Spielstände bleiben kompatibel. Beim Hinzufügen werden keine Goldkosten berechnet, keine Waffen oder Rüstungen stillschweigend angelegt und keine magischen Effekte automatisch verwendet. [Details, Quellen, Tests und Grenzen](docs/SRD_AUSRUESTUNGSKATALOG.md).

Im Abenteuer kannst du eine **kurze Rast** (`Ich mache eine kurze Rast 2W10.`) zur Heilung mit verfügbaren Trefferwürfeln oder eine **lange Rast** (`Ich mache eine lange Rast.`) zur Wiederherstellung von TP und Trefferwürfelvorrat bestätigen. Die Ressourcen bleiben im Spielstand erhalten und werden im Charakterbogen unter **Verteidigung** angezeigt. Die Regelumsetzung ist auf den dokumentierten Teilumfang begrenzt; siehe [Rast-Regeln](docs/REST_RULES.md). Flutter-/Android-CI für diese neue Version noch ausstehend.

> Entwicklungsstand `0.5.7+27` (15.10.2026): Inventar-Widgettest stabilisiert. Noch keine CI-/Android-Abnahme für diesen Stand. Die letzte GitHub-Abnahme zu `0.5.6+26` meldete 351 erfolgreiche und einen fehlgeschlagenen Flutter-Test.

# Würfelraunen – Der lebendige Spielleiter

## Neu in 0.5.8+28: D&D-Rasten und Trefferwürfel

Im Abenteuer kannst du eine **kurze Rast** (`Ich mache eine kurze Rast 2W10.`) zur Heilung mit verfügbaren Trefferwürfeln oder eine **lange Rast** (`Ich mache eine lange Rast.`) zur Wiederherstellung von TP und Trefferwürfelvorrat bestätigen. Die Ressourcen bleiben im Spielstand erhalten und werden im Charakterbogen unter **Verteidigung** angezeigt. Die Regelumsetzung ist auf den dokumentierten Teilumfang begrenzt; siehe [Rast-Regeln](docs/REST_RULES.md). Flutter-/Android-CI für diese neue Version noch ausstehend.

> **Neuer Quellstand 0.5.6+26 (CI ausstehend):** Drei konkrete Fehler aus dem GitHub-Lauf für 0.5.5+25 korrigiert: Android-Tastatur-Erkennung der unteren Schnellaktionen, Overflow bei 320dp/großer Schrift und Antippbarkeit der Inventarschaltfläche im Widgettest. Alle vier Schnellaktionen bleiben fest unten. Keine Änderungen an Spielständen oder dem KI-Backend.

### Schnellaktionen unten fest angedockt (0.5.5+25)

In der Abenteueransicht liegen **Sprache / Stopp**, **Untersuchen**, **Angriff** und **W20** unterhalb des Texteingabefelds **fest über der unteren App-Navigation**. Beim Scrollen durch Geschichte oder Kampf bewegen sie sich nicht mit. Die Sprach- und Würfelknöpfe werden nicht zusätzlich im Texteingabebereich wiederholt. Der `Rückblick` bleibt dort erreichbar. Ein fertiger Android-Build dieser Quellversion muss erst durch GitHub Actions bestätigt werden.


> **Neu 0.5.4+24 – vollständiger Importstand (CI ausstehend):** Mehrklassenaufstiege werden gegen veraltete Charakterwerte abgesichert. Nach vollständig bestandenem GitHub-CI erstellt ein neuer Release-Schritt automatisch ein vollständiges, versioniertes Projekt-ZIP, eine ARM64-APK, Release-Notizen und SHA-256-Prüfsummen. Die APK wird weiterhin mit einer internen Debug-Testsignatur erstellt. Dieser ZIP-Quellstand ist **noch keine freigegebene APK**; die zuvor fest fixierten Schnellaktionen bleiben erhalten. Siehe [Release-Prozess](docs/ALPHA_RELEASES.md).

> **Vollständiges Quellarchiv 0.5.3+23:** Die gesonderte Importanleitung steht in [docs/VOLLSTAENDIGES_PROJEKT_IMPORTIEREN.md](docs/VOLLSTAENDIGES_PROJEKT_IMPORTIEREN.md). Der automatische Codex-Workflow wurde auf Wunsch entfernt; GitHub Actions enthält nur reguläre Projektprüfungen und Android-APKs. Der Android-Build dieses Archivstands ist noch nicht CI-validiert.

> **Neu 0.5.3+23:** Die vier Schnellaktionen **Sprache, Untersuchen, Angriff und W20** sind nun als kompakte, **fixierte Leiste oberhalb der unteren Navigation** erreichbar – auch beim Scrollen durch die Geschichte und in der Kampfübersicht. Bei geöffneter Bildschirmtastatur bleibt die Leiste sichtbar. Außerdem ist der bekannte `pubspec.yaml`-YAML-Fehler der Vorversion korrigiert. Siehe [Prüfanleitung](TESTING.md).

> **Neu 0.5.2+22:** Sichtbarer App-Name von Aetheria auf **Würfelraunen** umgestellt. Der Android-Paketname `de.aetheria.lebendiger_spielleiter`, die lokalen Backup-Kanäle und historische Kampagnendaten bleiben aus Update-Kompatibilitätsgründen unverändert. Die Mehrklassen-Erweiterung ermöglicht eine ausdrücklich bestätigte zweite D&D-SRD-Klasse beim Stufenaufstieg einschließlich Voraussetzungen, Trefferpunkten und ausgewählten Fertigkeiten. Klassenfähigkeiten und Spezialressourcen sind noch nicht vollständig automatisiert. Siehe [Mehrklassen](docs/MULTICLASSING.md) und [Namenswechsel](docs/RENAMING.md).

> **Aetheria 0.5.1+21:** Zwei CI-Fehler nach illustriertem Design-Update behoben: zuvor nicht erreichbare Schaltflächen im Charakterbogen-/Startseiten-Widgettest werden jetzt sichtbar gescrollt und auf Hit-Test geprüft. Eine neue Android-APK ist erst nach bestandener GitHub Actions Pipeline freigegeben.

> **Aetheria 0.5.0+20 – Illustratives Fantasy-Redesign:** Die vier abgestimmten Design-Entwürfe sind als echte Flutter-Widgets umgesetzt. Neue lokale WebP-Illustrationen für Ruinen/Burgen/Wälder, Kampagnenkarten und Inventargegenstände. Start, Abenteuer, Helden, Chronik und Charakterbogen werden bildgestützt dargestellt. Keine erfundenen Spielwerte; keine Regel- oder Schemaänderungen. **Flutter/Android-CI für diese neue Version steht noch aus.** Siehe [Designumsetzung](docs/ILLUSTRATED_UI.md).

> **Aetheria 0.4.3+19:** Attributkarten mit skalierter Mindesthöhe und eindeutigen Widget-Test-Selektoren statt Seitenverhältnis-/`GridView`-Fehler. GitHub-Actions-Abnahme noch ausstehend.

 > **Aetheria 0.4.2+18 (15.10.2026):** Korrigiert den `flutter analyze`-Fehler aus 0.4.1: `mainAxisExtent` gehört in den Grid-Delegate und nicht in den `GridView.count`-Konstruktor. Die Anpassung der Kachelhöhe und Regressionstests für Smartphones und größere Schrift bleiben erhalten. Dieses Quellpaket muss noch vollständig in GitHub Actions geprüft werden.

> **UI-Fix 0.4.1+17:** Die drei aus GitHub Actions bekannten Überlauffehler in den Statistik-Kacheln des Fantasy-Charakterbogens wurden im Quellcode behoben. Tests für 320/360/400 dp und große Systemschrift sind enthalten. Die vollständige CI-/APK-Abnahme steht noch aus. Details: `CHANGELOG.md`.

> **Aetheria 0.4.0+16:** Einheitliches deutsches Dark-Fantasy-Design für alle vorhandenen Bildschirme. Smartphone-Navigation unten, große Bildschirme mit Seitenleiste, gemeinsame Panel-/Dialog- und Formular-Gestaltung. Siehe [Design-System](docs/UI_DESIGN_SYSTEM.md). GitHub-Actions-Abnahme steht für diesen Stand noch aus.

## Neu in 0.3.9+15: Deutsches Fantasy-Design und Charakterbogen

Die Charakteransicht orientiert sich an der gewählten Dark-Fantasy-Vorlage: dunkles Blau, Goldakzente, farbige Attributkarten und große Trefferpunkteanzeige. **Alle UI-Texte sind auf Deutsch.** Der Bogen ist über **Helden → Bogen ansehen** sowie im **Abenteuer → Charakterbogen ansehen** erreichbar. Das Bearbeiten bleibt möglich.

Die Darstellung ist an die echten Spieldaten gebunden; fehlende Attribute/TP/RK werden nicht geraten. Speziell: Bewegung wird entsprechend den vorhandenen Spielwerten in **Metern** angezeigt; der Übungsbonus ist stufenabhängig, Rettungswürfe verwenden nur dokumentierte Fertigkeiten. Da das Datenmodell noch keine Porträtbilder verwaltet, steht ein stilisierter Initialen-Avatar anstelle eines festen Beispielbilds. Details: [UI-Design und Bedienung](docs/UI_DESIGN.md).

Hinweis: Der neue Quellstand muss noch `flutter analyze`, `flutter test` und den Android-Build bei GitHub Actions bestehen. Ein fertig getestetes APK liegt für 0.3.9 noch nicht vor.

## Neu in Aetheria 0.3.8+14 – spielbare KI-Abenteuer

Der KI-Spielleiter kann passende Quests und Gegnerbegegnungen oder Erkundungsaufgaben vorschlagen. **Erst nach Bestätigung** durch den Spieler aktiviert die App eine Aufgabe. Initiative, Gegnerwerte, Proben, Treffer, Questabschluss und einmalige Beute werden **nur lokal** bestimmt und gespeichert. Der KI-Erzähler erhält keine Regelautorität. Details, Testablauf und Grenzen: [Dynamische Abenteuer](docs/AI_ADVENTURES.md). Die App erfordert weiterhin einen für echte Story-Generierung verbundenen KI-Backend-Server und ausdrückliche Kostenfreigabe.

## Neu in 0.3.7: Eine eigene KI-Kampagne beginnen

1. In **Helden** einen Charakter anlegen und speichern.
2. Unter **Optionen** einen eigenen HTTPS-Backend-Spielleiter verbinden. Für echte kreative KI muss dessen OpenAI-Anbieter serverseitig eingerichtet und die kostenpflichtige Nutzung ausdrücklich freigegeben sein. Der lokale `mock`-Anbieter bietet nur eine fest vorgegebene Testgeschichte.
3. Unter **Kampagnen** den Button **KI-Kampagne erstellen** wählen, Held und Wunschthema angeben. Die KI liefert Welt, Einstieg, verborgenes Ziel, NPCs und offene Handlungsstränge; die App validiert und speichert sie in SQLite.
4. Freie Aktionen im Abenteuer verändern erzählerische Handlungsstränge und Beziehungen. Die KI erhält nur den begrenzten Kontext und gibt **Vorschläge** zurück. Würfelergebnisse, Kämpfe, HP, Inventar und Belohnungen bleiben bei der lokalen Regelengine.
5. Im **Tagebuch** findest du den sichtbaren Kampagnenplan, den Entscheidungszähler, offene/gelöste Geschichten und NPC-Beziehungsnotizen. Der interne Twist wird beim Spielen nicht vorzeitig angezeigt, kann aber im vollständigen JSON-Export gelesen werden.

Bei Ausfall des Backends wird ein lokaler Erzähltext verwendet und kein KI-Fortschritt behauptet. Eine abgebrochene Generierung erzeugt keinen leeren Spielstand. Kostenfreigabe und Sitzungstoken werden nicht dauerhaft gespeichert. **„Lernend“ bedeutet hier ein wachsendes gespeichertes Kampagnengedächtnis, nicht das Trainieren eines neuen KI-Modells.**

# Der lebendige Spielleiter (ältere Projektdokumentation)

**Aktueller Quellstand 0.3.6+12 (Flutter-CI noch abzunehmen):** Ein
regelkonformer Stufe-1-Trefferpunktevorschlag aus Klasse und Konstitution ist
direkt im Charaktereditor integriert und erfordert ausdrückliche Bestätigung.
Das vollständige ZIP enthält `app/`, `backend/`, `scripts/`, die versteckte
`.github/`-Struktur und die ursprünglichen Projektdateien unmittelbar an
der Wurzel. Für GitHub den ZIP-Inhalt entpacken und die enthaltenen Dateien
hochladen, nicht das ZIP selbst als einzige Repositorydatei ablegen.


Deutschsprachiger Fantasy-Spielleiter für Android mit Flutter, lokalem Kampagnengedächtnis und einem kostenlosen Demo-Modus in [ManuEtt/Dnd](https://github.com/ManuEtt/Dnd). Der zunächst unabhängig erstellte Stand wurde nach Wiederherstellung des Zugriffs mit dem hochgeladenen 0.3.0-Repository verglichen: Die Dateiinhalte stimmen überein, lediglich vier Ausführungsrechte unterscheiden sich. Neue Korrekturen bauen auf diesem Repositorystand auf.

Der Schwerpunkt liegt auf einem spielbaren Solo-Ablauf: Charakter und Kampagne anlegen, Entscheidungen eingeben, mit einem deterministischen Spielleiter interagieren, würfeln, einfache Kämpfe austragen und den bestätigten Zustand wieder laden. Der Demo-Spielleiter verarbeitet einige Handlungsarten und liefert passende Szenen; frei formulierte Texte sind möglich, die Antworttiefe ist jedoch begrenzt. Eine umfassende generative KI und eine vollständige Umsetzung aller SRD-Regeln sind weitere Entwicklungsschritte.

## Dauerhaftes Kampagnengedächtnis in Version 0.3.6

Im Bereich **Tagebuch** lassen sich jetzt **Sitzungsrückblicke speichern**, **Handlungsstränge verwalten** und **NPC-Beziehungen mit Begründung festhalten**. Dazu wird immer ausdrücklich eine Aktion in der Oberfläche ausgeführt. Der Spielleiter übernimmt niemals bloße KI-Erzählungen oder gesprochene Spielerbehauptungen automatisch als bestätigte Weltfakten.

- **Sitzungsrückblick:** Erstellt eine dauerhaft gespeicherte, begrenzte Momentaufnahme aus bekannten Quests, NPCs, Fakten und verwalteten Handlungssträngen. Ältere Rückblicke bleiben für spätere Sitzungen erhalten.
- **Handlungsstränge:** Titel, Notiz und Status „Offen“, „Gelöst“ oder „Aufgegeben“ können hinzugefügt und aktualisiert werden. Ein gelöster Handlungsstrang löst ausdrücklich keine Questbelohnung aus.
- **NPC-Beziehungen:** Bestehende Personen können eine bestätigte Beziehungsänderung mit erläuternder Notiz erhalten. Die vorherigen Änderungen bleiben als Verlauf abrufbar.

Alle neuen Informationen liegen im bestehenden lokalen Kampagnen-JSON und SQLite-Revisionsjournal und werden beim normalen Spielstandexport mitgesichert. Ältere Version-1-Exporte ohne diese Felder bleiben importierbar. Die Suche bleibt deterministisch/lexikalisch, also noch ohne semantische KI-Suche. **Flutter-, Backend- und Android-Tests für diesen neuen Stand müssen über GitHub Actions bestanden werden**; die hier ausgeführten Python-Strukturprüfungen sind kein Ersatz dafür.

## Neuer Kampagnenrückblick in Version 0.3.5

Im Abenteuer findest du neben **Würfeln** und **Sprechen** die Schaltfläche
**Rückblick**. Sie erstellt einen auf bestätigten Spieldaten basierenden
Überblick, ohne deinen möglicherweise noch ungesendeten Handlungstext zu
überschreiben. Alternativ kannst du etwa „Was weißt du über Mira?“, „Erinnere
dich an den Waldschrein“ oder „Fasse unsere bisherige Geschichte zusammen“
eingeben oder diktieren. Bei thematischen Fragen gibt es nur passende
Erinnerungen. Ohne passenden bestätigten Inhalt benennt der Spielleiter die
Lücke, statt Fakten zu erfinden.

Die kostenlose Demo lässt Mira auf den gespeicherten Fortschritt reagieren:
Sie fordert weder einen bereits gefundenen Schlüssel noch einen erledigten
Auftrag erneut an. Spieler-/KI-Erzähltext wird weiterhin nicht als bestätigter
Regel- oder Weltzustand interpretiert. Diese Verbesserung ist eine
**deterministische lokale Regel-/Erinnerungsfunktion**, noch keine frei
handelnde generative KI. Neue Flutter-Tests und der neue Android-Build müssen
nach dem Import erfolgreich in GitHub Actions durchlaufen. Details:
[CHANGELOG.md](CHANGELOG.md) und [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

## Korrektur und Weiterentwicklung in Version 0.3.4

Der fehlgeschlagene Widgettest zur manuellen Hausregel-Bestätigung scrollt
nun gezielt zurueck zur Checkbox. Im Charaktereditor wird direkt unter jedem
bestätigten gültigen Attribut (1–30) der berechnete Modifikator angezeigt,
z. B. `14 → +2`. Diese Anzeige ist eine Vorschau: Sie ändert weder Regeln,
Würfelergebnisse noch einen gespeicherten Charakter automatisch.
Ein neuer Widgettest prüft die Vorschau auch bei Änderungen und leeren Werten.
Der letzte bekannte GitHub-Workflow zum Stand 0.3.3+9 vom 15.10.2026 hatte
**281 bestandene Tests und einen fehlgeschlagenen Widgettest**. Es gibt
für 0.3.4+10 noch keine Flutter-CI-/APK-Abnahme.

## Neue Funktionen in Version 0.3.3

Der Stufe-1-Charaktereditor besitzt einen Assistenten **„D&D-Klasse und Fertigkeiten wählen“**. Es stehen zwölf Klassen des SRD 5.2.1 mit jeweils passenden Rettungswurf-Übungen und auswählbaren Klassenfertigkeiten zur Verfügung. Auf Wunsch werden Start-TP vorgeschlagen und ein SRD-Startpaket bzw. Startgold in den bislang leeren Charakterbogen übernommen. Bei älteren Charakteren werden Fertigkeiten, TP und Ausrüstung nicht heimlich überschrieben.

Neue Charaktere können die vorhandene 27-Punkte-/Standardwert-Attributshilfe verwenden. Freie Startwerte außerhalb dieser Verteilung benötigen im Editor eine ausdrücklich gewählte Hausregel-Ausnahme. Nicht bestätigte/leere Attribute bleiben für Entwürfe möglich.

Noch **nicht** Teil dieses Inkrements: Vollständige Herkunfts-Fertigkeits-/Talentauswahl, Klassenmerkmale, Zauberplätze, Rüstungsanlegen, vollständiger Kampf und automatisierte Stufenaufstiege. Siehe `ROADMAP.md` und [Anleitung für Klassenwahl](docs/CLASS_CREATION.md).

## ZIP nach GitHub übertragen

Das vollständige aktuelle 0.3.6+12-ZIP entpacken und seine Projektinhalte einschließlich `.github/` direkt in die Repositorywurzel übertragen; das neue Paket enthält keinen äußeren `Dnd/`-Ordner. Nur die ZIP-Datei hochzuladen startet keinen Android-Build. Vorhandene Dateien vorher vergleichen und in einem neuen Branch arbeiten. Die [Schritt-für-Schritt-Anleitung](docs/UPLOAD_TO_GITHUB.md) erklärt Zugriff, Upload und APK-Download. Vor dem Build prüft `python3 scripts/verify_project.py` die Vollständigkeit ohne Flutter/Android SDK.

## Starten und prüfen

Benötigte Versionen: Flutter **3.35.7** mit Dart **3.9.2**, Java **17** (vollständiges JDK einschließlich `javac`), Android SDK und Node.js **22.14.0** oder eine kompatible neuere Node-22-Version. Abhängigkeiten sind über `app/pubspec.lock` und `backend/package-lock.json` festgehalten. Netzwerkzugang wird beim ersten Installieren der Entwicklungsabhängigkeiten benötigt.

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

Für SQLite-Tests unter Linux wird zusätzlich `libsqlite3-dev` benötigt, unter Debian/Ubuntu beispielsweise über `sudo apt-get install libsqlite3-dev`.

Der Demo-Modus benötigt keinen Server, keinen OpenAI-Schlüssel und keine kostenpflichtigen API-Aufrufe. Ab Version **0.2.0** lässt sich unter Einstellungen zusätzlich ein eigener HTTPS-Backend-Erzähler mit kurzlebigem Sitzungstoken verbinden. Der Token bleibt ausschließlich im Arbeitsspeicher. Kostenpflichtige Anbieter benötigen eine ausdrückliche Freigabe; bei Ausfall erzählt die lokale Demo weiter. Regeln, Würfel und bestätigter Spielzustand bleiben lokal. Einrichtung und Grenzen stehen in [docs/BACKEND_CONNECTION.md](docs/BACKEND_CONNECTION.md).

Die Android-Spracherkennung und Textausgabe nutzen die auf dem Gerät verfügbaren Systemdienste. Deutsche Sprachpakete müssen vorhanden sein; die Spracherkennung kann je nach Android-Dienst eine Internetverbindung benötigen. Eine vollständige Offline-Sprachfunktion wird nicht garantiert. Erkannte Eingaben lassen sich vor dem Absenden bearbeiten. Audiodateien werden von dieser App nicht dauerhaft gespeichert.

Seit **0.3.1** lassen sich Stimmen nach einer Sprachpaketinstallation neu prüfen.
Die Auswahl zeigt vom Anbieter gemeldete Netzwerkabhängigkeit; fehlende
Sprachdaten und abgewiesene Stimmen erhalten verständliche Rückmeldungen.
Wartezeiten für nicht antwortende Dienste sind begrenzt; die lokale Oberfläche
startet bereits während der Sprachdienstprüfung. Die App unterstützt
derzeit Deutsch; eine Stimmwahl übersetzt keine Spieltexte. Gerätehilfe und
der Benutzerbericht zum Samsung Galaxy S26 Ultra stehen in
[docs/SPEECH_TROUBLESHOOTING.md](docs/SPEECH_TROUBLESHOOTING.md).

Optionales Backend:

```bash
cd backend
npm ci
npm run typecheck
npm test
npm run build
npm run dev
```

Die Backend-Konfiguration steht in [backend/.env.example](backend/.env.example). Echte Schlüssel gehören ausschließlich in lokale Umgebungsvariablen beziehungsweise die sichere Serverkonfiguration. Details zu vorhandenen API-Routen, Demo-Betrieb und optionaler OpenAI-Verbindung stehen im [Backend-README](backend/README.md). Es ist keine öffentliche Hostingumgebung eingerichtet.

## Android installieren

Nach Übertragung der Projektdateien läuft der Workflow **Android-Alpha bauen**. Unter **Actions → erfolgreicher Lauf → Artifacts** das Artefakt `lebendiger-spielleiter-alpha-kleine-apks` herunterladen und entpacken. Für übliche 64-Bit-Android-Geräte `app-arm64-v8a-alpha.apk` wählen; ältere 32-Bit-Geräte benötigen `app-armeabi-v7a-alpha.apk`. Das zusätzliche große Debug-Artefakt bleibt verfügbar. Die kleinen APKs sind optimierte interne Alpha-Builds mit Testsignatur. Downloadhilfe: [docs/APK_DOWNLOAD.md](docs/APK_DOWNLOAD.md). Android kann für die Installation eine Freigabe der verwendeten Installationsquelle verlangen. Es handelt sich nicht um einen signierten Store-Release.

Ein lokaler Build ist ebenfalls möglich:

```bash
cd app
flutter build apk --debug
```

Ausgabe: `app/build/app/outputs/flutter-apk/app-debug.apk`. Der lokale Android-Debug-Build wurde erfolgreich geprüft; die APK benötigt mindestens Android 7.0 (API 24). Tatsächlich durchgeführte Prüfungen und verbleibende Grenzen stehen in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) und [TESTING.md](TESTING.md). Ein erfolgreicher Build ersetzt keinen Test auf einem Android-Gerät.

## Attribute erstellen

Ab **0.3.0** öffnet **Attribute ermitteln** im Charaktereditor eine
Stufe-1-Starthilfe. Weise den Standardsatz 15, 14, 13, 12, 10, 8 zu oder kaufe
Grundwerte von 8 bis 15 mit bis zu 27 Punkten. Wähle anschließend ausdrücklich
Akolyth, Krimineller, Weiser oder Soldat sowie dessen zulässige
Attributssteigerungen. Die Vorschau zeigt Grundwert, Bonus, Endwert und
Modifikator. Erst **Attribute übernehmen** ändert den Editor, und erst
**Charakter speichern** bestätigt die Daten dauerhaft. Vorhandene Werte
benötigen eine zusätzliche Bestätigung zum Ersetzen; Abbrechen erhält sie.

Die Hilfe vergibt Attribute und die gewählte Hintergrundbezeichnung.
Fertigkeiten, Talente, Ausrüstung, Trefferpunkte und Klassenfortschritt brauchen
weiter eigene bestätigte Angaben. Werte aus importierten, unvollständigen Alt-Spielständen werden nicht
abgeleitet oder automatisch ergänzt. Regeln und Quellen:
[docs/ABILITY_RULES.md](docs/ABILITY_RULES.md).

## Kampagnen und persönliche Spielstände

Bei einer neuen App-Installation wird **kein Arescan-Spielstand** angelegt oder
angeboten. Die einzige ausdrücklich auswählbare Beispielkampagne ist die
optionale Demo **Das Licht von Mooswacht** mit Liora. Eigene Charaktere und
Kampagnen können über die Benutzeroberfläche erstellt und gespeichert werden.

Ältere Arescan-Spielstände werden **nicht automatisch gelöscht**: Sie bleiben
bei einem App-Update in der lokalen Datenbank, und persönliche JSON-Backups
können wie andere Kampagnen importiert werden. Arescan besitzt keine
hartkodierte Sonderhandlung mehr. Ohne bestätigte regelrelevante Daten
blockiert die generische Importkampagnenlogik unzulässige Kampfaktionen;
historische Ereignisse und Texte bleiben erhalten. Eine historische
Arescan-Testdatei liegt ausschließlich unter `app/test/fixtures/` und wird
nicht als App-Asset ausgeliefert.

Seit App **0.2.2** lassen sich Charaktere und Kampagnen über **Als Datei speichern** direkt als JSON sichern. Android fragt nach dem Zielordner; die App benötigt dafür keine allgemeine Speicherberechtigung. Beim Import öffnet **Datei wählen** die Android-Dateiauswahl. Der geladene Text wird erst mit **Importieren** bestätigt und gespeichert. Abbrechen und fehlerhafte Dateien verändern den vorhandenen Spielstand nicht. JSON-Anzeige, manuelle Texteingabe und Zwischenablage bleiben verfügbar. Details und Dateigrenzen stehen in [docs/SAVE_BACKUPS.md](docs/SAVE_BACKUPS.md).

Sicherungsdateien und die lokale Datenbank sind nicht zusätzlich verschlüsselt. Wähle einen geeigneten Speicherort; ein Cloud-Dateianbieter kann Daten zu seinem Dienst übertragen. Android-App-Backups sind deaktiviert; vor einer Deinstallation wichtige Spielstände exportieren.

Die separate Demo-Kampagne **Das Licht von Mooswacht** beginnt in der Welt Lunaris mit **Liora**, einer menschlichen Kämpferin der Stufe 1. Sie enthält ausdrücklich festgelegte Demo-Werte und führt über einen Brunnen, einen Schlüssel und einen Waldschrein zu einer einfachen Begegnung. Sie dient zum Prüfen des Ablaufs ohne externe KI-Dienste. Die Demo-Testdaten liegen unter `app/assets/demo.json`.

## Projektstruktur

| Pfad | Aufgabe |
| --- | --- |
| `app/` | Flutter-App, Android-Projekt, Domänenmodelle, Regeln, Persistenz, UI und Tests |
| `backend/` | TypeScript/Fastify, validierte API, Demo-Provider und optionale OpenAI-Anbindung |
| `.github/workflows/` | Analyse, Tests und Android-Debug-APK |
| `docs/` | Übergabe- und Upload-Anleitungen |
| `scripts/` | Lokale Prüfung und sauberes ZIP-Paket ohne Buildcache oder Geheimnisse |

Architektur: [ARCHITECTURE.md](ARCHITECTURE.md). Nächste Aufgaben: [ROADMAP.md](ROADMAP.md). Hinweise für spätere Entwicklungssitzungen: [AGENTS.md](AGENTS.md).

Die verwendete Regelgrundlage ist eine ausgewählte Teilmenge von SRD 5.2.1 unter CC BY 4.0. Namensnennung und weitere Hinweise stehen in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Eine Lizenz für den eigenständigen Projektquellcode ist noch festzulegen.
