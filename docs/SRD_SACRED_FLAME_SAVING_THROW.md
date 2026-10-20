# SRD 5.2.1: Heilige Flamme – erster Rettungswurf-Zauber (0.8.24+74)

**Quelle:** D&D [SRD 5.2.1](https://www.dndbeyond.com/srd), Zauber *Sacred Flame*, CC BY 4.0. Die Regeltexte in der Entwicklungsquelle stehen weiterhin unter ausstehendem vollständigem amtlichen Quellenabgleich.

## Neu

- **Wiederverwendbare Prüfung:** `SrdSpellSavingThrowRules.spellSaveDc` = 8 + Übungsbonus + bestätigter Zauberattributsmodifikator. Unmodellierte Gegenstände, Merkmale und magische SG-Modifikatoren müssen ausdrücklich ausgeschlossen werden.
- **Wiederverwendbarer Rettungswurf:** `SrdSpellSavingThrowRules.resolve` nimmt **den vollständigen, bestätigten** Monsterrettungswurfbonus entgegen, einschließlich ggf. vorhandener Übung. Der W20 wird lokal gewürfelt und mit dem SG verglichen. Ein natürlicher 1er/20er ist bei Rettungswürfen nicht automatisch Fehlschlag/Erfolg; Vorteil/Nachteil gelten nach der üblichen D20-Regel.
- **Heilige Flamme / Sacred Flame:** Kleriker-Zaubertrick (V/S, 60 Fuß, Aktion), sichtbare einzelne Kreatur, Geschicklichkeitsrettungswurf. Fehlschlag verursacht 1W8 (Stufe 1–4), 2W8 (5–10), 3W8 (11–16), 4W8 (17–20) **Strahlenschaden**. Erfolg verursacht **0 Schaden ohne Schadenswurf**. Halb-/Dreivierteldeckung bietet bei genau diesem Rettungswurf keinen Bonus. Vollständige Deckung bleibt ausgeschlossen.
- **Kampfintegration:** `GameEngine.castSacredFlame`, revisionsgeschützter Controller, neue Schnellaktion und eigenständiger Dialog für explizite Sicht-/Reichweiten-/V/S-/Gegner-SG- und Defensivbestätigungen. Lokale Würfe und angewendeter Schaden werden im `spell.sacredFlame`-Event samt serialisierbarem Zustandscheckpoint protokolliert. Kein Zauberplatzverbrauch; genau eine Magieaktion.
- **Prüfungen:** Stufenskalierung, Zauber-SG, natürliche 1/20, Deckungs-Ausnahme, Vorteil/Nachteil, ungültige oder fehlende Gegnerdaten vor RNG, Mehrklassen-Kleriker, Erfolg ohne Schadenswurf, persistentes Journal, illegale Kampfzüge und ungeprüfte Dialogbedingungen.

## Grenzen der Mechanik

Nur ein bestätigter Gegner. Die Engine **erfindet niemals** den Monster-Geschicklichkeitsrettungswurfbonus, Vorteil/Nachteil, Strahlenschadensabwehr oder weitere SG-Modifikatoren. Automatisches Erkennen von Monstertraits, magischen Gegenständen, Geometrie/Sichtlinien, Gruppen-/Flächeneffekten oder anderen SRD-Zaubern folgt separat. `SPELL-ENTRY-SACRED-FLAME` ist deshalb als `partial` eingeordnet. Dieses Inkrement ist **noch keine vollständige SRD-Zauberengine**.

## Build-Gates

```bash
python3 -m unittest discover -s scripts/tests
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Erst nach vollständig erfolgreicher GitHub-CI nach `main` mergen. Testinstallation auf einem echten Android-Gerät bleibt separat offen.
