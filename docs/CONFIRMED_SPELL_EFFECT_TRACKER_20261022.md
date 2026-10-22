# SRD 5.2.1 – Bestätigte Zauberwirkungs-Einträge (22.10.2026)

Ausgangscommit: `c8179de63273d678e711d45a9642dd000f1ee710`.
Quellen: D&D System Reference Document 5.2.1 (Spells – Duration,
Rules Glossary – Concentration), Wizards of the Coast LLC, CC BY 4.0:
https://www.dndbeyond.com/srd

## Implementierter Inkrement

**SRD-SPELL-EFFECT-TRACK-20261022 (partial)**

- `app/lib/domain/confirmed_spell_effects.dart` führt ein separates
  **bereits unabhängig geprüftes** Zauberwirkungsprotokoll für den
  Helden. Jede Ursache ist durch ID, bekannten Zaubernamen und
  bestätigte Quellenbezeichnung unabhängig nachvollziehbar.
- Dauer nur als **ausdrücklich bestätigter eigener Zugendpunkt**
  (1, 3, 10 im Dialog; Domänenregel 1–100), oder ausdrücklich
  zu beendende Wirkung. Kein aus Zaubernamen, Katalogtexten oder
  Echtzeit hochgerechnetes Ablaufdatum.
- Gespeicherter Zeitpunkt: `expiresInEncounterId` und
  `expiresAtOwnTurnEndRound` mit (R + N - 1) auf eigenem aktivem
  Kampfzug. Abbruch bei fremder Zugphase und Überlauf > 1.000.000.
- Optional `concentrationBound` nur mit aktuell bestätigter
  Konzentration auf denselben dem Charakter bekannten Zauber,
  maximal ein gebundener Eintrag pro Held. Konzentrationsende durch
  bestätigten Schaden, Handlungsunfähigkeit oder neuen Zauber
  entfernt gebundene Einträge beim Regel-Checkpoint.
  Durch eine erreichte Endrunde dieser Quelle endet auch die
  entsprechende bestätigte Konzentration.
- Keine automatischen Zauberwürfe, keine Slotkosten, keine
  Zielauswahl und keinerlei Zustands- oder Schadenseffekte;
  **kein generischer Ersatz für einen verifizierten Zauber-Cast**.
- `app/lib/domain/models.dart` speichert Einträge als optionales
  `confirmedSpellEffects` in `HeroCharacter` (Schema **1 bleibt
  bestehen**). Import prüft Zuordnung, Typen, Quellen, Mengenbegrenzung,
  IDs und Konzentration. Alte Spielstände ohne Feld bleiben identisch.
- `app/lib/domain/game_engine.dart` und
  `app/lib/services/game_controller.dart` führen atomar und
  revisioniert bestätigende Hinzufügung/Entfernung, echte
  eigene Zugendpunkte und konzentrationsbedingten Cleanup durch.
  Protokollierung per `spell.effect.confirmed` und
  `spell.effect.recordRemoved`.
- `app/lib/ui/confirmed_spell_effect_dialog.dart` und
  `app/lib/ui/fantasy_effect_ward.dart`: Fantasy-Karte,
  anzeigegeschützter Countdown, Quelle, Konzentrationsbindung und
  separate Bestätigungs-/Entfernungsdialoge. Die Anzeige hat
  niemals mechanische Seiteneffekte.

## Tests / Abnahmekriterien

- `app/test/confirmed_spell_effects_test.dart`:
  unveränderte Slots, TP, Bedingungen/Aktionen; echte
  EndHeroTurn-Transitions, Grenzwerte, falsche Kampfphase,
  unbekannte Zauber, Konzentrationsbruch, manuelle Entfernung,
  doppelter ID-Eintrag, fremde Begegnungen, Alt-JSON und Manipulation.
- `app/test/confirmed_spell_effect_storage_test.dart`:
  SQLite-Neustart, korrekte Runden-/Event-Rekonstruktion,
  vorab abgewiesene unbestätigte Quelle.
- `app/test/confirmed_spell_effect_widget_test.dart`:
  320/360/960 dp, bestätigte Quelle, Rundenanzeige,
  fremde Begegnungen, Abbruch, Auswahlfenster.

## Qualifikationen

**IMPLEMENTIERT:** Beschränkter, explizit bestätigter, nur auf den
eigenen Helden bezogener Wirkungsnachweis mit Konzentrationsbindung
und rundenbasierter Ablaufverwaltung.

**GETESTET:** erst nach tatsächlich erfolgreicher CI so markieren.
**NICHT GETESTET:** reales Android-Gerät.
**BLOCKIERT:** vollständige automatische Zauberziel- und
Zeitverwaltung bis zu einzeln geprüften SRD-Effekten und Uhrmodell.
**NOCH NICHT IMPLEMENTIERT:** minutiöse Echtzeit-/Reisezeitdauer,
Zauber gegen Gegner, Mehrziele, an beliebige Akteurszüge
gekoppelte Trigger, explizite Auflösung spezifischer Zauberwirkungen,
automatisches Zuordnen aller katalogisierten Zauberdauern,
Revisionskonflikte bei parallelen Geräten.
