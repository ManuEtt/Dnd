# Codex-Checkpoint – Würfelraunen

## Aktueller Stand – Mönch-Werkzeugwahl, 0.8.48+98

Stand: 2026-10-29T17:00:04.686609+00:00. Arbeitsbranch
`feat/character-monk-tool-proficiency-20261029`, Basis-Main `fde0ef6ed8b419d6a31c701a03aa05d61994c352`.
Die vorherigen 24 PRs sind über [#386](https://github.com/ManuEtt/Dnd/pull/386)
integriert, [Main-CI 40867945743](https://github.com/ManuEtt/Dnd/actions/runs/40867945743)
auf `fde0ef6e` erfolgreich; live keine offenen PRs beim Start. Ältere Aussagen
„noch nicht integriert“ sind historische Schreibstände, kein aktueller Blocker.

**IMPLEMENTIERT:** Neue Mönche wählen ausdrücklich eine von 27 zulässigen
Handwerkszeug-/Instrumentübungen, auch bei Startgold. Paket A enthält genau
diesen Gegenstand und 11 GM; B enthält 50 GM ohne Gegenstand. Bestätigte
Klassenbelege v3 speichern die Auswahl, v1/v2 bleiben unverändert lesbar und
gewähren keine aus Inventar/Freitext erfundene Übung. Bereits erlernte typisierte
Klassen-/Hintergrundübungen bleiben bei späteren Namens-/Inventaränderungen erhalten.
Eine neue Zweitklasse allein erteilt keine erste Mönch-Werkzeugwahl.

Der Charakterbogen zeigt quellenbasierte Werkzeugübungen und eine ausdrücklich
gewählte Attributsvorschau. Die Regelengine berechnet Übungsbonus nur einmal,
Zustände/Erschöpfung, Vorteil bei ausdrücklich passender trainierter Fertigkeit
und Werkzeug-Verlässliches-Talent ab Schurke 7. Die Vorschau ist kein ausgeführter
Wurf und bestätigt weder Werkzeugbesitz, konkrete Verwendung, SG noch Herstellung.
Der lesende Erstellungs-Audit prüft die neue Pflichtwahl und Paketbindung getrennt.
Eine tatsächlich reproduzierte UI-Sperre beim Mönch→Barbar→Mönch-Rückwechsel mit
bereits übernommenem Paket ist behoben; gleiche Klasse/gleiches Paket erhalten
bereits bestätigte Entscheidungen. Keine doppelte Gold-/Ausrüstungsvergabe.

**GETESTET:** 65 gezielte Domain-/SQLite-Fälle, 17 Dialog-, 14 Vorschau- und
15 Editor-Widgetfälle bestanden. Darunter alle 27 Varianten mit A/B, alle zwölf
historischen Klassen/Kits in v1/v2, falsche/fehlende Quellen, doppelte Übungen,
JSON/SQLite-Neustart, stale Editor ohne Änderungen aller sechs Tabellen sowie
320/360 dp bei 200 % Schrift/IME/Semantik. 535 Dart-Dateien unverändert formatiert,
Analyse ohne Befund. Der erste Vollversuch wurde für die zusätzliche explizite Fertigkeitswahl nach Beginn der Flutter-Tests bewusst beendet; er gilt nicht als voller Erfolg. Vollständige gemeinsame Prüfkette und aktuelle CI folgen;
frühere Baseline-CI wird nicht als neue Abnahme ausgegeben.

**NICHT GETESTET:** komplette neue Flutter-/Python-/Backend-Suite und Android-
Builds bis zu ihrem tatsächlichen Abschluss; echtes Android-Gerät/TalkBack,
installiertes Altversionsupgrade und produktive Signatur.
**BLOCKIERT:** kein angeschlossenes Testgerät; kein Code-/GitHub-Zugriffsblocker.
**NOCH NICHT IMPLEMENTIERT:** vollständiger Charakter-Wizard, übrige verpflichtende
Klassen-/Spezies-/Zauberentscheidungen; tatsächliche Werkzeugaktionen und deren
Würfel-/Zeit-/Materialtransaktionen. SQLite 3 / äußeres JSON 1 unverändert,
keine Datenbankmigration. Regel-/Story-Grenze und KI-Autorität unverändert.

Quellen: offizielles SRD 5.2.1, S.8–9/49/63/83/93–95, CC BY 4.0;
THIRD_PARTY_NOTICES.md unverändert. [Fachnachweis](CHARACTER_MONK_TOOL_PROFICIENCY_20261029.md).
`RULE-EQUIPMENT-TOOLS` / `EQUIP-CHOICES` bleiben konservativ `partial`.

Arbeits-PR: [#390](https://github.com/ManuEtt/Dnd/pull/390); maßgeblich sind dessen aktuelle Checks, nicht die bewusst beendeten Zwischenläufe.

Nächster begrenzter Charakter-Schritt: die drei Barden-Instrumentübungen und die
Bindung des Paket-A-Instruments an eine davon ausdrücklich wählen und dauerhaft
belegen. Zuerst amtlichen SRD-Kerntrait prüfen; bestehende v1/v2/v3-Belege nicht
rückwirkend verschärfen. Keine automatische Nachvergabe, Gegenfälle/SQLite/UI/CI
wie im aktuellen Paket. Keine automatische Arbeit nach Sitzungsende.

## Wiederaufnahme und Sicherung

Vor Änderungen Main/PRs/CI und Quellcode neu prüfen; die Baseline-Migration ist
abgeschlossen und wird nicht wiederholt. Aktuellen eigenen Branch mit geprüftem
Code/Checkpoint sichern. Neue ZIPs/Patches über scripts/create_checkpoint.py
außerhalb des Projekts erstellen; keine privaten Spielstände/Schlüssel aufnehmen.
Vorigen Stand bytegenau mit Manifest unter docs/history/monk_tool_start_20261029/ erhalten.
