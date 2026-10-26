# Chat C – Kampfmöglichkeiten bei 200 % Text und TalkBack (26.10.2026)

## Abnahmeziele
1. Bei Android-Systemschrift >= 180 % und weniger als 500 dp Panel-Breite erscheinen Aktion, Bonusaktion, Reaktion, Bewegung und gegebenenfalls verbrauchter Zauberplatz untereinander in voller Panelbreite. Auch bei 320/360 dp und 200 % Schrift gibt es keine Flutter-Layoutfehler.
2. Jedes vorhandene Ressourcen-Siegel besitzt einen eigenen, vollständig deutschsprachigen TalkBack-Semantikknoten, ohne doppelt vorgelesene Icons oder Statuswerte.
3. Nicht bestätigte Bewegung bleibt „nicht bestätigt“; bei nicht verbrauchtem Zauberplatz wird auch kein Zauberplatz-Siegel erfunden. Die normale kompakte Darstellung bei üblicher Schrift bleibt bestehen.
4. Keine Veränderung an Kampfregel, Aktionsverbrauch, Ressourcenzustand, KI, Kampagne, Speicherung, Schema oder Version.

## Umsetzung und Umfang
- `app/lib/ui/fantasy_combat_status.dart`: `FantasyCombatActionEconomy` ordnet bei großer Schrift seine bisherigen schreibgeschützten Status-Siegel über einen `LayoutBuilder` in voller Breite an. Stabile Widget-Schlüssel und `Semantics(container: true)` trennen die Statusansagen.
- `app/test/fantasy_combat_status_test.dart`: kompakte Displays 320/360 dp mit 200 % Text, fünf gesonderte Statuslabels, vertikale Anordnung, unbekannte Bewegung und unveränderte Standarddarstellung; bestehende Deckungs- und Aktions-Regressionen bleiben erhalten.
- Die benachbarte `FantasyCombatCoverPanel` samt Popup-Befehlen ist nicht verändert.

## Freigabe
Ein gezielter Flutter-Widgettest allein genügt nicht: aktuelle GitHub-Android-CI mit Formatprüfung, Analyse, allen Tests und Android-Builds auf exakt dem finalen PR-HEAD auswerten. Kein Merge vor erfolgreicher gemeinsamer Abnahme. TalkBack auf echtem Gerät und produktive Signatur bleiben offen.

## Koordination
Chat C arbeitet auf `feat/chat-c/action-economy-large-text-20261026` gegen den beim Start aktuellen `main`. Andere offene Chat-A-/Chat-B-PRs und zentrale Statusdokumente werden nicht überschrieben.
