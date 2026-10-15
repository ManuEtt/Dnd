# Einheitliche SRD-5.2.1-Regelauswertung – Würfelraunen 0.6.3+33

**Quelle:** [SRD 5.2.1, CC BY 4.0](https://www.dndbeyond.com/srd), Kapitel *Playing the Game*, *Equipment* und *Rules Glossary*, insbesondere D20 Tests, Exhaustion, Conditions, Armor und Weapons.

## Architektur

`app/lib/domain/character_rule_engine.dart` ist der **rein lesende, zentrale Zugriffspunkt** für bestätigte, mechanische Charakterwerte. Die Werte werden aus `HeroCharacter` berechnet; Basisattribute, Grundbewegung und übrige Spielstände werden dabei nicht überschrieben. `rules_engine.dart` bleibt die Instanz für bestätigte Kampf-/Schadens-/Heilungsänderungen, `equipment_rules.dart` für explizit bestätigte Ausrüstungswechsel, `rest_rules.dart` für Trefferwürfel/Rasten, `condition_rules.dart` für Zustandseffekte.

| Komponente | Integration |
| --- | --- |
| Charakterbogen (`fantasy_character_sheet.dart`) | Übungsbonus und Initiative aus RulesEngine; effektive Bewegung, Rettungswürfe einschließlich Erschöpfung, Zustandserklärungen |
| Charaktereditor | Bestätigte Erschöpfungsstufe und Zustände bleiben editierbar; Validierung in `HeroCharacter.fromJson` |
| Ausrüstungsdialog | Getrennte Anzeige von Waffen-Grundbonus und aktuellem Erschöpfungsabzug, zustandsbedingtem Angriffsnachteil; Übernahme weiterhin explizit |
| Kampf / Spielleiter (`game_engine.dart`) | Angriff, Initiative, Wahrnehmung, Flucht und Rundentempo nutzen zentrale Regeln; Gegnerangriff berücksichtigt unbedingten Verteidigerzustand |
| Würfelsystem | Vorteil/Nachteil wird als Bestandteil der PendingRoll-Anfrage gespeichert; zwei W20 nur bei automatischer Probe, Vorteil und Nachteil heben sich auf |
| Speicher/Import/Journal | Optionale boolesche `advantage`/`disadvantage`-Felder im bestehenden `PendingRoll`-JSON; frühere Spielstände ohne diese Felder standardmäßig Normalwurf; keine Schema-Migration |

## Bestätigte automatische Modifikatoren

* Erschöpfung: −2 je Stufe bei W20-Tests; −1,5 Meter je Stufe Bewegung; Grundwerte bleiben erhalten.
* Rüstung: schwere Rüstung ohne erforderliche Stärke −3 Meter (entspricht 10 Fuß); ungeübte Rüstung/Schild bedingt Nachteil auf ST-/GE-W20-Tests. Rüstungsbedingter Heimlichkeitsnachteil wird bei ausdrücklich als Stealth deklarierter Probe berücksichtigt.
* Angriffe: Blinded/Poisoned/Prone/Restrained des Angreifers sowie schwere Waffen unter Attribut 13 erzeugen Nachteil. **Keine automatisierte Fernkampf-/Nahkampfentfernungsannahme.**
* Initiative: Invisible gibt Vorteil, Incapacitated und Poisoned/ungeübte Rüstung geben Nachteil. Gleichzeitiger Vorteil und Nachteil werden wie gewohnt neutralisiert.
* Rettungswürfe: Attribut, Übungsbonus und Erschöpfung genau einmal. Restrained gibt Nachteil auf Dexterity Saving Throws.
* Gegnerangriffe: Unbedingter Vorteilszustand des Verteidigers berücksichtigt; Ausweichen führt Nachteil zu und kann neutralisieren.
* Bewegung: Conditions mit Bewegungsverbot = 0 Meter. Kampf speichert ganzzahlige Meter abgerundet; im Charakterbogen bleibt die präzisere Meterangabe sichtbar.

**Absichtlich weiterhin manuell:** Augen-/Sichtlinie, tatsächlich unbekannte gegnerische Bedingungen, Abstand zu Ziel beim liegenden Ziel, fliegende/bewegte Ziele, Zauber und Magieboni, Konzentration, Waffenmeisterschaften, Munitions-/Laderegel, Klassen-/Speziesfeatures, Aktionsökonomie verschiedener Gegner, Heimlichkeit ohne deklarierte Art, Abschirmung und Höhenunterschiede. Solche Daten dürfen nicht vom KI-Erzähler erfunden oder stillschweigend als bestätigte Kampfmechanik übernommen werden.

## Testerwartungen

In `app/test/character_rule_engine_test.dart` werden reine Berechnungen, doppelte Vorteile/Nachteile, alter/neuer JSON-Import, schwere Rüstung, fehlende Übung und Spielleiter-D20-Integration getestet. `app/test/character_rule_engine_widget_test.dart` prüft, dass ein Charakterbogen die effektive Bewegung und Erschöpfung konsistent zeigt.

```sh
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Die Tests können in diesem Quellstand ohne Flutter-SDK noch nicht lokal ausgeführt werden; ein erfolgreicher Android-Build ist daher **nicht bestätigt**. Dies ist ein nachvollziehbarer Quell-Checkpoint, keine freigegebene Geräteversion.
