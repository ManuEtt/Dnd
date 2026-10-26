# CHAT C – Auftragsübersicht: 200 % Schrift und Semantik

**Stand:** 26.10.2026  
**Ausgangs-main:** `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`  
**Branch:** `feat/chat-c/quest-board-large-text-20261026`  
**PR:** Nach Erstellung nachtragen.

## Ausgangsproblem

`FantasyAdventureQuestBoard` begrenzte die Unterzeile auf zwei, die Quest-Titel und -Beschreibungen auf drei Zeilen. Bei 320 dp/200 % Schriftgröße werden dadurch bestätigte Auftragsinformationen sichtbar abgeschnitten. Zudem stand je Auftragszeile kein zusammenhängender, vollständig lesbarer Status für Screenreader zur Verfügung.

## IMPLEMENTIERT

- `app/lib/ui/fantasy_adventure_hud.dart`: ab 180 % Textskalierung darf die Auftrags-Unterzeile vollständig umbrechen; die rein dekorative Buch-Rune wird ausgeblendet, um der Titelzeile Breite zu geben.
- Die bereits gespeicherten Quest-Titel und -Beschreibungen werden bei starker Schriftvergrößerung ohne `maxLines`-Trunkierung gerendert. Die reguläre kompakte Darstellung unter 180 % bleibt erhalten.
- Jede bestätigte `_QuestLine` erhält eine zusammenhängende, nicht editierbare Screenreader-Beschriftung aus Status, Titel und gegebenenfalls Beschreibung. Der Text entsteht ausschließlich aus dem bestehenden `Quest`; keine Vermutungen oder Änderungen am Spielstand.
- `app/test/fantasy_adventure_hud_test.dart`: zwei positive Tests für 320 und 360 dp/200 % mit unverfälschten Strings, Semantik, unverändertem Queststatus und bedienbarem Tagebuch; ein negativer Test für einen leeren Spielstand ohne erfundene Ziele.

## Akzeptanzkriterien

1. Die Anzeige bleibt bei 320/360 dp mit 200 % Schrift ohne Flutter-Overflow lesbar.
2. Die lange Aufgabenbeschreibung wird ohne Ellipsis dargestellt und ist als vollständige deutsche Semantik zugänglich.
3. Erfolgreiche, aktive und unbekannte/fehlende Einträge werden nicht umklassifiziert; keine Änderung an `campaign.quests`.
4. `Tagebuch öffnen` bleibt bedienbar und ruft den vorhandenen Callback auf.
5. Format-, Analyse-, Flutter-, Backend-, Architektur-/SRD- und Android-CI muss auf finalem PR-Commit abgeschlossen werden.

## Tests und Limits

- **Geschrieben:** drei neue Widgettests. **Noch keine finale CI-Abnahme:** [formatierender Prüfworkflow #40267319215](https://github.com/ManuEtt/Dnd/actions/runs/40267319215) sowie Android-CI des neuen Branches gesondert kontrollieren. Nicht mit einem bestandenen Test verwechseln.
- **Nicht getestet:** reales Android-Gerät mit TalkBack, produktive APK-Signierung, manuelle Bildschirmlupenprüfung.

## Kompatibilität / Koordination

App-Version `0.8.40+90` aus `main` unverändert, keine SQLite-/JSON-, Controller-, D&D-SRD- oder Kampagnenerzählungsänderung. Vor Beginn die offenen PRs #178, #192, #193, #194, #195 überprüft; diese bearbeiten keine der zwei UI-/Testdateien des neuen Pakets. README und `docs/CODEX_CHECKPOINT.md` werden von mehreren Chats bearbeitet und müssen beim Merge in `main` historientreu konsolidiert werden.

## NÄCHSTER SCHRITT

Nach erfolgreicher CI ein separates Fantasy-UI-Element mit geringer Überschneidungsgefahr für 320 dp/200 % sowie Screenreader-Wirkung prüfen. Keine unbeaufsichtigte Hintergrundentwicklung.
