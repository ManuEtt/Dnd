# Chat C – Kampf-Deckung bei 200 % Systemschrift

**Datum:** 26.10.2026, Europe/Berlin  
**Repository:** `ManuEtt/Dnd`  
**Ausgangs-main:** `864b53dba0a7186bf6beef46bcfb1499077d6dc2`  
**Feature-Branch:** `feat/chat-c/combat-cover-large-text-20261026`

## Ausgangssituation

In `FantasyCombatCoverPanel` blieben die Deckungsauswahlschalter bei 320/360 dp auch bei 200 % Android-Schriftgröße nebeneinander. Text war auf zwei Zeilen beschränkt; der gesamte bestätigte Deckungswert konnte so visuell gekürzt werden. Die bestehenden Popup-Buttons dürfen nur bestätigte Deckungsbefehle melden und bei `canChange == false` keinerlei Befehl absetzen.

## IMPLEMENTIERT

- `app/lib/ui/fantasy_combat_status.dart`: LayoutBuilder plus volle Zeilenbreite für Held/Gegner ab 180 % Textskalierung bei weniger als 500 dp. Bei normaler Schrift bleiben kompakte, umbrechende Popup-Buttons mit maximal zwei Textzeilen.
- `_CombatCoverSelector` kapselt die bestehenden Popup-Optionen ohne Änderung an `CoverLevel`, `CoverRules.commandValue` oder Callback-Verträgen.
- Jeder Deckungsschalter besitzt ein separates deutsches Screenreader-Label aus der aktuell bestätigten Deckungsstufe und Änderbarkeit. Beim gesperrten Schalter ist auch der Tooltip eindeutig als nicht änderbar gekennzeichnet.
- `app/test/fantasy_combat_status_test.dart`: positive 320- und 360-dp-Tests bei 200 % für volle Labels, vertikale Anordnung, Vorlesesemantik und `Deckung: Held voll`-Befehl sowie Negativtest für `canChange == false` mit keinem Befehl und keinem geöffneten Auswahlmenü.

## AKZEPTANZ

1. 320/360 dp bei 200 % Schrift: zwei vollbreite, untereinander liegende Deckungsschalter; Deckungsnamen ohne `maxLines`-Trunkierung.
2. Screenreader sagt den aktuellen bestätigten Deckungswert und ob eine Änderung erlaubt ist. Keine unbestätigten neuen Hindernisse.
3. Auswahlmenü sendet dieselben Befehle wie bisher; kein automatischer Spielzustandswechsel.
4. Bei `canChange == false` bleiben beide Auswahlen gesperrt, erzeugen keine Befehle und melden ihre Sperre semantisch.
5. Finale Projekt-CI erfolgreich (Python, Backend, Architektur/SRD, Dart-Format, Flutter-Gesamtsuite, Android-Build/Alpha-Artefakte).

## GETESTET

- Drei zusätzliche Widgettests erstellt, aber **CI für den finalen PR-Commit steht noch aus**. Formatierung wird über temporären GitHub-Actions-Diagnoselauf mit Flutter 3.35.7/Dart 3.9 an das Projekt angeglichen und der Workflow danach entfernt.
- Zu Beginn waren alle vorherigen PRs (darunter #197 und #199) gemergt; kein offener PR und kein konkurrierender Besitzer dieser beiden Dateien.
- Code- und Datenformat unverändert: `0.8.40+90`, SQLite 2, JSON 1 – keine neue Migration, keine D&D-Regel-/KI-/Kampagnenänderung.

## NICHT GETESTET / BLOCKIERT

Noch keine tatsächliche Gerätebedienung mit TalkBack, keine produktive Signierung oder Veröffentlichung im Store; keine lokale Flutter-/Dart-SDK-Ausführung in diesem Kontext. CI-Ergebnisse erst nach Abschluss als bestanden markieren.

## NÄCHSTER SCHRITT

Finale CI inklusive Alpha-APKs prüfen, jede Regression im selben Branch korrigieren, eigenen Pull Request konfliktfrei dokumentieren. Anschließend anderes unabhängiges Fantasy-UI-Modul auswählen, statt bereits fertige Dialoge neu zu schreiben.
