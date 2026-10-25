# Light-Nahkampfbonus mit bestätigtem Waffenkontext

Version 0.8.39+89. Arbeits-ID `RULE-COMBAT-TWO-WEAPON-FIGHTING`, **partial**.
Quelle: Wizards of the Coast, [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
Light S.89, Two-Weapon Fighting S.88, Rage S.29, Damage Rolls S.16; CC BY4.0.
Die bestehende Namensnennung in THIRD_PARTY_NOTICES.md bleibt erhalten.

## Verhalten

Eine abgeschlossene eigene Angriffsaktion mit einer Light-Nahkampfwaffe eröffnet
die vorhandene optionale Bonusaktion auch ohne Kämpfer-Klasse oder Kampfstil.
Der Spieler kann seinen Zug stattdessen beenden. Für den Zusatzangriff ist eine
andere eindeutig vorhandene Light-Nahkampfwaffe ohne Schild erforderlich.

Der Abenteuerdialog erfasst Waffen-ID, Stärke oder zulässiges Finesse-Geschick,
Waffenübung als ausdrückliches Ja/Nein sowie gehaltene Waffen. Vorschau und
abschließende Zustimmung sind unverändernd; Eingabeänderung widerruft die Zustimmung.
Erst GameController/Repository reservieren die Bonusaktion mit einem atomaren
Ereignis. Stale Revision und spätere SQL-Fehler ändern keinen bestätigten Zustand.

Der Attributsmodifikator gilt für Angriff und Schaden derselben Waffe. Light lässt
positive Schadensmodifikatoren weg und behält negative. Der vorhandene bestätigte
Kämpfer-Stil fügt den Modifikator einmal hinzu. Krit verdoppelt Würfel, keine flachen
Boni. Kampfrausch verwendet die tatsächliche Waffen-ID und deren Angriffsattribut.
Negative Schadenssubtotalen werden mit weiteren Klassenboni zusammengeführt und
erst dann auf insgesamt mindestens null begrenzt; das gilt auch für Hauptwaffen.

## Speicher- und Autoritätsgrenzen

SQLite2 und Kampagnen-JSON1 unverändert. Neue optionale PendingRoll-Felder
`offhandAttackAbility`, `offhandWeaponProficient`, `offhandWeaponsHeldConfirmed`
müssen gemeinsam für eine Nebenhandprobe vorliegen; Waffenhaltung muss true sein.
Explizites false bei Übung wird erhalten. Alte Proben ohne diese Felder behalten
ihren bisherigen Fighter-Stil-Vertrag. Import und Auflösung prüfen dieselben
Waffen-, Bonus-, Ziel-, Ressourcen- und Zugregeln vor dem Würfeln.

Der bisherige Fighter-Freitextpfad nutzt bestätigte Klassenübung; andere Klassen
bestätigen ihre eigenen Waffendaten im Dialog. Primärwaffenübung und -attribut
werden nicht auf eine neue Waffe übertragen. Story/KI bestätigen keine Regelfakten.
Die bestehende Schurken-Verbündetenbestätigung aus PR160 bleibt angebunden.

## Abnahme und Grenzen

Tests: `two_weapon_fighting_test.dart`, `light_weapon_bonus_attack_test.dart`,
`offhand_attack_dialog_test.dart`, `combat_class_actions_test.dart` und
`domain_rules_test.dart` plus bisherige Sneak-/Speicher-/Widgetregressionen.
Abgedeckt sind Ablehnung vor RNG, Waffen-/Attributs-/Übungsprüfung, Krit/Miss,
negative Summen mit Rage/Sneak, gemeinsame Zugnutzung, Legacy-JSON, Backup,
SQLite-Neustart/Rekonstruktion, stale Controller, Rollback und 320/360dp mit
Schriftfaktor1,8 und eingeblendeter Tastatur.

Nur Nahkampf nach abgeschlossener Angriffsaktion. Light-Fernkampf, Munition,
Nick, allgemeine Waffenwechsel, weitere Kampfstilquellen und Positionsverwaltung
bleiben eigene Pakete. Gerät/Altspielstand-Update und produktive Signierung offen.
Tatsächliche Gesamtläufe und Artefakte: [CODEX_CHECKPOINT.md](CODEX_CHECKPOINT.md).
