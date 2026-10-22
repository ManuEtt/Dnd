# Würfelraunen – bestätigte mehrzügige Zustandsdauer

Entwicklungszyklus vom 22.10.2026; Ausgangscommit
`e7e4255625435d0fb68e94eef922e32e4f840065` auf `main`.

## Regelgrundlage und Grenzen

D&D System Reference Document 5.2.1, Kapitel *Spells – Duration*
und Rules Glossary *Concentration* (CC BY 4.0):
https://www.dndbeyond.com/srd

Dauer ist bei jedem konkreten Zauber durch dessen offiziell geprüfte
Beschreibung festgelegt. Die hier angebotenen Zeitwerte sind **keine
automatische Ermittlung** der Dauer eines beliebigen Zaubers. Der Spieler
bestätigt eine Quelle sowie eine Dauer vor der mechanischen Änderung.
Die Erweiterung betrifft die bereits vorhandenen extern bestätigten,
quellgebundenen **Zustandseffekte** des eigenen Charakters. Ziel-/Flächen-
und Gegnereffekte sowie die allgemeine Zauber-/Minutenzeitverwaltung
bleiben offen.

## Anforderungen, Code und Sicherheitsgrenzen

- **SRD-EFFECT-OWN-TURNS-20261022 (partial):**
  `ConditionEffectDuration` bietet weiterhin *bis Entfernung*,
  *aktuelles eigenes Zugende*, *nächstes eigenes Zugende* und neu
  **3, 5 und 10 eigene Zugenden**. Für eine Bestätigung auf eigener
  Runde `R` mit `N` Zugenden wird ausschließlich
  `expiresAtOwnTurnEndRound = R + N - 1` in der bisherigen
  `ConditionEffect`-Struktur gespeichert.
- **SRD-EFFECT-BOUNDARY-20261022 (partial):**
  Die vorhandene Kampfregel entfernt den Effekt ausschließlich beim
  bestätigten eigenen Zugende der richtigen Begegnung. Ein Gegnerzug,
  Neustart, Anzeige oder die Uhrzeit entfernen ihn nicht. Andere
  Ursachen desselben Zustands bleiben aktiv.
- **SRD-EFFECT-COUNTDOWN-20261022 (partial):**
  `ConditionEffectRules.remainingOwnTurnEnds` ist rein lesend.
  Ein Restzähler erscheint nur im eigenen aktiven Kampfzug derselben
  noch laufenden Begegnung, andernfalls bleibt die bestätigte
  absolute Endrunde samt Begegnungs-ID sichtbar. Der Countdown
  verändert keine Spielwerte.
- **SCHUTZ VOR FEHLERN:** Bei ungültiger Kampfphase oder Endrunde
  über 1.000.000 wird die Aktion vor der Effekt-ID-Vergabe abgewiesen.
  Keine Schemaänderung, kein neues Pflichtfeld, keine Änderung alter
  `ConditionEffect`-JSONs, keine Neuerstellung historischer Events.

## Tests und Nachweis

- `app/test/confirmed_condition_turn_durations_test.dart`:
  echte `GameEngine.endHeroTurn`-Übergänge für 1/2/3/5/10,
  1.000.000-Rundengrenze, Verweigerung fremder Zugphase,
  alte JSON-Spielstände und unabhängige Ursachen.
- `app/test/condition_effect_storage_test.dart`:
  SQLite-Neustart und exaktes Ende einer bestätigten Drei-Zug-Dauer
  mit vollständig revisionierter Transaktion.
- `app/test/condition_effect_dialog_test.dart`:
  Sichtbarkeit zusätzlicher Auswahlwerte nur auf dem eigenen Zug.
- `app/test/fantasy_effect_ward_test.dart`:
  sichtbarer Countdown in gleicher Begegnung und bewusstes
  Unterdrücken bei fremden Begegnungen.

Qualitätsstatus erst nach überprüftem GitHub-Actions-Lauf als
**GETESTET** markieren; der eigene Android-Gerätetest bleibt gesondert.

## Noch nicht implementiert

Ein vollständiges eigenständiges Modell für Zauberwirkungsdauer in
Runden/Minuten/Stunden, das an konkrete SRD-Zauber, Zielpersonen,
Konzentration und Auslöser zu Anfang/Ende eines beliebigen Akteurzuges
gebunden ist. Dafür sind gesonderte fachliche Regeln, serialisierte
Ziel-/Quelle-Verknüpfungen und Integrationstests erforderlich.
