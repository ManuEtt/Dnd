# Würfelraunen – Der lebendige Spielleiter

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
weiter eigene bestätigte Angaben. Historische Arescan-Werte werden nicht
abgeleitet oder automatisch ergänzt. Regeln und Quellen:
[docs/ABILITY_RULES.md](docs/ABILITY_RULES.md).

## Die beiden Ausgangskampagnen

**Das Herz der Ewigkeit** übernimmt die vorgegebene Geschichte in Aetheria mit Arescan in Silberhain. Der Angriffsgesamtwert 19 und der erzählte Schaden 14 bleiben historische Angaben. Fehlende Attribute, Trefferpunkte, Gold, Erfahrungspunkte, Ausrüstung und der ungeprüfte frühere Geschicklichkeitsmodifikator +7 werden nicht als bestätigte Regelwerte übernommen. Die Geschichte bleibt lesbar; vor neuen regelabhängigen Aktionen muss der Charakter vervollständigt werden. Auch die Kampfwerte des Schattenritters sind unbekannt: Der historische Kampf kann noch nicht regelkonform fortgesetzt werden, solange diese nicht ausdrücklich bestätigt werden.

Seit App **0.2.2** lassen sich Charaktere und Kampagnen über **Als Datei speichern** direkt als JSON sichern. Android fragt nach dem Zielordner; die App benötigt dafür keine allgemeine Speicherberechtigung. Beim Import öffnet **Datei wählen** die Android-Dateiauswahl. Der geladene Text wird erst mit **Importieren** bestätigt und gespeichert. Abbrechen und fehlerhafte Dateien verändern den vorhandenen Spielstand nicht. JSON-Anzeige, manuelle Texteingabe und Zwischenablage bleiben verfügbar. Details und Dateigrenzen stehen in [docs/SAVE_BACKUPS.md](docs/SAVE_BACKUPS.md).

Sicherungsdateien und die lokale Datenbank sind nicht zusätzlich verschlüsselt. Wähle einen geeigneten Speicherort; ein Cloud-Dateianbieter kann Daten zu seinem Dienst übertragen. Android-App-Backups sind deaktiviert; vor einer Deinstallation wichtige Spielstände exportieren.

Die separate Demo-Kampagne **Das Licht von Mooswacht** beginnt in der Welt Lunaris mit **Liora**, einer menschlichen Kämpferin der Stufe 1. Sie enthält ausdrücklich festgelegte Demo-Werte und führt über einen Brunnen, einen Schlüssel und einen Waldschrein zu einer einfachen Begegnung. Sie dient zum Prüfen des Ablaufs ohne externe KI-Dienste. Importierbare Ausgangsspielstände liegen unter `app/assets/arescan.json` und `app/assets/demo.json`.

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
