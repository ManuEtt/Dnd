# Chat C – Kampfteilnehmerkarte bei 200 % Systemschrift

**Stand:** 26.10.2026  
**Ausgangsbasis:** `main` `e903ae38c6ae99abfa99a432e7f7777f0eee853f`  
**Branch:** `feat/chat-c/combatant-card-large-text-20261026`

## IMPLEMENTIERT

`FantasyCombatantCard` in `app/lib/ui/fantasy_combatant_card.dart` zeigt ab 180 % Systemschrift die Kopfzeile vertikal statt horizontal an. Bestätigte Helden- und Gegnernamen dürfen vollständig umbrechen; Rolle (HELD/GEGNER), dekorative Rune und `AM ZUG` bleiben erkennbar. Der kompakten Ansicht bei normaler Schrift bleiben Zweizeilenbegrenzung und horizontale Anordnung erhalten. `Flexible` darf im vertikalen, in der Höhe unbeschränkten Layout nicht verwendet werden; ein eigener, nicht flexibler Namensabschnitt verhindert RenderFlex-Fehler.

Alle bisherigen INI-/RK-/TP-/TEMP-Tags und der Trefferpunktebalken bleiben vorhanden; unbestätigte Werte bleiben `?` und ohne Fortschrittsbalken. Es gibt keine Mutationslogik.

## TESTS ERGÄNZT

`app/test/fantasy_combatant_card_test.dart`: vier neue Widgettests:
- 320 dp und 360 dp bei 200 % Textskalierung: lange Namen ohne Ellipsis, vertikale Kopfzeile, aktiver Zug unter dem Namen, bestätigte Statuswerte und zwei TP-Anzeigen.
- 320 dp/200 %: unbekannte Initiative/Rüstungsklasse/Trefferpunkte bleiben unbekannt, kein aktiver Zug und kein erfundener Lebensbalken.
- 360 dp/normale Schrift: bestehender horizontaler Kopfbereich mit zweizeiliger, komprimierter Namensanzeige.

## CI-STATUS UND BLOCKER

Die CI auf dem anfänglichen Branch-Commit [#40282720333](https://github.com/ManuEtt/Dnd/actions/runs/40282720333) endet noch **vor** Flutter bei drei Python-ZIP-/Checkpoint-Testfehlern in `scripts/tests/test_create_checkpoint.py` und `scripts/tests/test_package_project.py`. Der aktuelle unveränderte Main-CI-Lauf [#40282602855](https://github.com/ManuEtt/Dnd/actions/runs/40282602855) meldet ebenfalls einen Fehler. Diese Tests sind nicht durch UI-Änderungen berührt; keine Behauptung einer grünen Gesamt-CI, solange der Main-Blocker nicht gelöst ist.

Der temporäre Dart-Formatierungsworkflow und ein gezielter Flutter-Analyse-/Widget-Testlauf sind separat zu prüfen. **Status gezielter Testlauf:** noch ausstehend.

## NICHT GETESTET / ABGRENZUNG

Kein reales Android-Gerät mit TalkBack, keine produktive Signierung, kein im neuen Branch erfolgreich durchgelaufener vollständiger Android-Alpha-Build. Keine Änderungen an Domain, Controller, Regelwerk D&D-SRD 5.2.1, persistenten Spielständen, JSON 1, SQLite 2 oder App-Version `0.8.40+90`. Andere Chats und Main bleiben unverändert.

## NÄCHSTER SCHRITT

Canonical Dart-Formatierung anwenden; gezielte Flutter-Tests und Analyse über GitHub Actions ausführen; bei Erfolg PR mit offen ausgewiesenem CI-Blocker erstellen. Integration erst nach erfolgreicher vollständiger Main-/PR-CI und konfliktfreier Prüfung.
