# Chat C – Kampfteilnehmerkarte bei 200 % Systemschrift

Datum: 26.10.2026. Basis-main: `e903ae38c6ae99abfa99a432e7f7777f0eee853f`.

## IMPLEMENTIERT

In `app/lib/ui/fantasy_combatant_card.dart` wird bei Textskalierung ab 180 % die Kopfzeile vertikal aufgebaut, damit ein langer bestätigter Helden- oder Gegnername ohne die bisherige Begrenzung auf zwei Zeilen dargestellt wird. Das Abzeichen „AM ZUG“ bleibt sichtbar, ebenso Initiative, Rüstungsklasse, Trefferpunkte und Fortschrittsanzeige. Bei kleinerer Schrift bleibt die bisherige horizontale Kopfzeile bestehen.

## TESTSTATUS

Die GitHub-Actions-CI für den neuen Branch ist ausstehend; keine erfolgreiche Abnahme behauptet. Noch keine neue gezielte Widget-Regression ergänzt. Flutter-Analyse, Flutter-Gesamttests und Android-Alpha-Build über die CI prüfen. Kein manuelles Android-/TalkBack-Testing.

## GRENZEN

Keine Regeln, Würfel, Spielstand-/Kampagnenmutation, neue Assets, JSON-/SQLite-Migration oder Signierung. Vorheriger PR #199 ist mit grüner CI in main integriert. Keine offenen parallelen PRs zum Zeitpunkt des Starts.

## NÄCHSTER SCHRITT

Widget-Regressionen für 320/360 dp bei 200 % ergänzen, dann vollständige CI abnehmen und PR erstellen.
