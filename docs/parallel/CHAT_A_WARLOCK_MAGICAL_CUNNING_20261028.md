# Chat A – SRD 5.2.1: Hexenmeister 2/20 Magical Cunning & Eldritch Master

Datum: 28.10.2026. Branch: feat/srd-warlock-magical-cunning-20261028.

## Offizielle Regelquelle
https://www.dndbeyond.com/srd (SRD 5.2.1, CC BY 4.0), Hexenmeister Level 2 Magical Cunning / Level 20 Eldritch Master.

Anforderungen:
- CLASS-HEXENMEISTER-2-BASE-MAGICAL-CUNNING-0
- CLASS-HEXENMEISTER-20-BASE-ELDRITCH-MASTER-0

## Implementierung
- Ein expliziter Befehl `Magische List: Ritual abgeschlossen` bestätigt das abgeschlossene einminütige Ritual. Erzählung oder KI-Effekte allein lösen keine Ressourcenerholung aus.
- Pure Rule: `app/lib/domain/srd_warlock_magical_cunning_rules.dart` – Hexenmeister-Klassenstufe 2+, Paktmagiepool aus `SpellcastingRules`; max. `(maxPactSlots+1) ~/ 2` wiederherstellbare Plätze, begrenzt auf tatsächlich verbrauchte Plätze.
- Hexenmeister-Klassenstufe 20: Eldritch Master stellt alle ausgegebenen Paktplätze mit demselben Ritual wieder her.
- Einmalige Nutzung je lange Rast in `spentClassResources['magicalCunning']`, validiert über `ClassResourceRules`; bestehende `afterLongRest`-Rücksetzung und `schemaVersion=1` bleiben erhalten. Short Rest setzt nur Paktmagieplätze wieder her, nicht die Magical-Cunning-Nutzung.
- GameEngine lehnt die Bestätigung während eines offenen Würfelwurfs, eines laufenden Einzelgegnerkampfs, bei ungültiger Eingabe und bei nicht spielbarem Charakter ab. Ereignistyp `class.magicalCunning` dokumentiert Vorher/Nachher, recoveredSlots, eldritchMaster, bestätigtes Ritual.
- Zwölf Tests in `app/test/srd_warlock_magical_cunning_rules_test.dart`: Stufengrenze, Mehrklasse, halbe Anzahl aufgerundet, Level20, Rest, Ressourcenmanipulation, alte/neu serialisierte Figur, doppelter Aufruf und Kampf.

## Nachweisgrenzen
- **IMPLEMENTIERT:** Code, Testfälle, Maschinenregister und Übergabedokumentation im Branch.
- **NICHT GETESTET:** finale CI des aktuellen Branch-HEAD, vollständige Flutter-Suite, APK und echtes Android-Gerät bis jeweiliger Abschluss belegbar ist.
- **NOCH NICHT IMPLEMENTIERT:** tatsächliche einminütige Zeit-/Unterbrechungssimulation, allgemeine Mehrakteur-Ritual-/Kampfregel, 100% der übrigen SRD-Klassenmerkmale.
- **Status:** Beide Anforderungs-IDs bewusst `partial`, keine globale Vollständigkeitsquote.
