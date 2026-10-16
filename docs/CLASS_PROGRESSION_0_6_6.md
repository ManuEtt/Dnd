# Würfelraunen 0.6.6+36 – Stufenmeilensteine und zusätzlicher Angriff

**Stand:** 16.10.2026; **Basis:** GitHub `ManuEtt/Dnd`, Commit `26d1d8b949555ea12ad55d6ed173528397157351` (0.6.5+35).
**Regelquelle:** SRD 5.2.1 / CC BY 4.0, Classes, Multiclassing, Combat.
Siehe https://www.dndbeyond.com/srd oder die Klassen- und Mehrklassenregeln unter https://5e24srd.com/ .

## Implementiert

- `ClassProgressionRules.attacksPerAttackAction(hero)` benutzt die **Klassenstufe**, nicht die Gesamtstufe.
- Barbar, Kämpfer, Mönch, Paladin und Waldläufer erhalten mit **Klassenstufe 5** zwei Attacken je regulärer **Angriffsaktion**.
- Nur Kämpfer erhalten mit **Klassenstufe 11** drei und ab **Stufe 20** vier Attacken.
- Mehrklassencharaktere addieren nicht mehrere *Extra Attack*-Merkmale: der höchste Wert zählt.
- Der Demo-/KI-Kampf setzt die möglichen Attacken einzeln um. Erst wenn alle Attacken abgewickelt sind, folgt der gegnerische Zug. Jede Probe hat eigenen Treffer-, Kritisch- und Schadenswurf. Besiegte Gegner lösen keinen weiteren Angriff aus.
- Verbleibende Attacken sind im `Encounter` gespeichert (`attacksRemaining`, optional im bisherigen Schema 1). Das alte Speicherformat ohne Feld bleibt gültig; der Zustand wird bei Zugwechsel wieder auf null gesetzt.
- Die Übersicht im Charakterbogen zeigt die Anzahl Attacken je Angriffsaktion und bevorstehende Klassenmeilensteine.
- Klassenmeilensteine: Unterklasse auf 3, häufige Talentwahlen auf 4/8/12/16, epische Gabe auf 19, Kämpfer zusätzlich 6/14, Schurke zusätzlich 10. Ein kleiner, ausdrücklich als Vorschau markierter Satz weiterer Kämpfer-Merkmale ist enthalten.

## Ausdrückliche Grenzen

- **Keine vollständige 240-Stufen-Feature-Engine.** Die Meilensteine sind eine *Vorschau*, keine automatische Zuteilung von Talenten, Unterklassen, bekannten Zaubern oder Ressourcen.
- Nicht umgesetzt: Action Surge (zusätzliche Aktion), Begleit-/Bonusaktionsangriffe, Kampfkünste, Two-Weapon Fighting, Zaubereffekte wie Haste, unbewaffnete Sonderregeln, Waffenmeisterschaften, Unterklassen-Extra-Attack (z.B. Schwertbarde) und Begleiterangriffe.
- Keine automatische Interpretation von KI-Erzähltext als Spielwerte. Der Demo-Kampf führt weiterhin nur einen Gegner mit vereinfachtem Positionsmodell; detaillierte Aktionsökonomie benötigt ein eigenes Ereignissystem.
- Der Charakterbogen zeigt künftig mögliche Klassenmeilensteine, nicht automatisch schon gewählte Klassenmerkmale.
- Bestehende `HeroCharacter.features` bleiben manuell erfasste Werte und werden nicht überschrieben.

## Tests und Abnahme

Neue Dateien:
- `app/test/class_progression_rules_test.dart`: 12 Klassen, Stufenschwellen, Fighter 11/20, Mehrklassen-Non-Stacking, Meilensteine.
- `app/test/class_progression_combat_test.dart`: einzelne Attacken in einer Angriffsaktion, ein Gegnerzug, Saves mit offenen Attacken, freiwilliges Zugende, Legacy-Saves.

**Vor APK-Freigabe:** `cd app && flutter pub get && flutter analyze && flutter test && flutter build apk --debug`.
Die Flutter-Befehle können in der aktuellen Autorenumgebung mangels installiertem Flutter-SDK nicht ausgeführt werden. Bestehende Python-Prüfungen und Archiv-/Patchprüfung sind davon unabhängig.

## Bekannte Entwicklungsaufträge

1. Klasse für Klasse *alle* SRD-Merkmale vollständig und maschinenlesbar spezifizieren; Entscheidungspflichten und begrenzte Ressourcen modellieren.
2. Erweiterbare CombatAction-/EffectEngine mit Bonusaktionen, Reaktionen, Unterbrechungen und Mehrziel-Events.
3. Gemeinsamer Parser für lokalisierte Regeldaten, nicht nur frei editierbare Namen.
4. Versionierte Tests für jede Fähigkeit mit Positiv- und Negativfällen und automatischer Ausführung in CI.
