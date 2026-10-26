# Chat C – Kampfhinweise als getrennte TalkBack-Meldungen (26.10.2026)

## Ziel und Abnahme
- Die bereits bestätigten Siegel für laufenden Gegnerzug, verbleibende Angriffe, ausstehende Schildentscheidung, aktive Schilde und verbrauchte Reaktion sind jeweils separat per Screenreader erreichbar.
- Bei 320 und 360 dp, 200 % Systemschrift und gleichzeitig sechs Siegeln bleibt jede vollständige Meldung lesbar; es treten keine Flutter-Layoutfehler auf.
- Bei beendeter Begegnung wird nur der bestätigte Abschlussstatus angezeigt; keine laufende Reaktion oder angedrohte Attacke wird erfunden.
- Die bestehende Regelengine, Initiative, Würfel, Trefferpunkte, Persistenz, KI und Aktionen sind unverändert.

## Umsetzung
In `app/lib/ui/fantasy_combat_threat_status.dart` ist jedes `_ThreatSeal` mit `Semantics(container: true, label: label)` ein eigener Semantik-Knoten. `ExcludeSemantics` verhindert die doppelte Vorlesung von Icon und Text. `app/test/fantasy_combat_threat_status_test.dart` deckt zwei kompakte Bildschirmbreiten, 200 %-Schrift, je sechs Semantik-Labels und den abgeschlossenen Kampf ab.

## Prüfung
Automatische Dart-/Flutter-/Android-Prüfungen werden für den Branch durchgeführt; ein echter Android-TalkBack-Gerätetest steht weiterhin aus. Ein erfolgreicher Widgettest ist keine Geräteabnahme. Es werden keine fremden Branches überschrieben und keine anderen offenen PRs automatisch integriert.
