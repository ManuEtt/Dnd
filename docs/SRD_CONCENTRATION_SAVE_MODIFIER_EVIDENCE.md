# SRD 5.2.1 – bestätigte Konstitutionsrettung für Konzentration

Stand 30.10.2026 · Quelle: [WotC D&D SRD 5.2.1](https://www.dndbeyond.com/srd), *Playing the Game / Saving Throws*, *Rules Glossary / Concentration* und *Classes / Monk*, CC BY 4.0.

## Zweck

`app/lib/domain/srd_concentration_save_modifier_rules.dart` erstellt ein **nur lesendes, an den exakten Helden-Snapshot gebundenes** Belegobjekt für den Modifikator eines Konstitutionsrettungswurfs bei Konzentration. Die Klasse **verwendet die bereits vorhandene Berechnung** `CharacterRuleEngine.savingThrow(hero, 'constitution')` statt einen zweiten, möglicherweise widersprüchlichen Bonusrechner einzuführen. Dadurch erfasst sie unter anderem:

- bestätigtes Konstitutionsattribut und einen einmaligen Übungsbonus aus `savingThrowProficiencies`;
- Mönch Stufe 14 (*Disciplined Survivor*) auch bei Multiclassing, aber **niemals doppelte Übung**;
- zwei Punkte Abzug auf D20-Tests **pro Erschöpfungsstufe** gemäß der SRD-5.2.1-Version;
- ausdrücklich bestätigte zusätzliche Modifikatoren und Wurfumstände; Vorteil und Nachteil heben sich gegenseitig auf.

Der Aufruf `SrdConcentrationSaveModifierRules.prepare` benötigt zwei unabhängige Bestätigungen: alle unmodellierten Modifikatorquellen wurden geprüft und die Wurfumstände wurden geprüft. Zusatzboni ungleich null benötigen außerdem eine eigene ausdrückliche Bestätigung. Es werden keine Gegenstands-, Talents-, Rettungswurf- oder Spieldaten aus Namen, Storytext oder KI-Erzählung abgeleitet.

## Sicherheits- und Zustandsgrenze

Der Held muss aktive Konzentration, mehr als 0 TP, bestätigte Konstitution, plausible eigene Klassendaten und eindeutige gültige Rettungswurf-Übungen besitzen und handlungsfähig sein. Unvollständige oder widersprüchliche Daten führen zu einer Ablehnung statt eines angenommenen Bonus. `sourceSnapshot` und `validateUnchanged(hero)` verhindern die Wiederverwendung desselben Belegs nach einer Charakteränderung; eine spätere Integrationsstelle muss dieses Prüfversprechen vor einem Commit erneut auswerten.

Das Belegobjekt enthält `baseModifier`, `additionalModifier`, `totalModifier`, `advantage`, `disadvantage` und `isNormalRoll`. **Es wirft keinen Würfel, verbraucht keinen Würfel oder Zauberplatz, löst keinen Schaden aus und beendet keine Konzentration.** Die tatsächliche Entscheidung ist ein getrennt geprüfter Mechanismus, derzeit in [PR #418](https://github.com/ManuEtt/Dnd/pull/418). Vor dessen Integration besteht **noch keine gekoppelte API**; eine künftige, koordinierte Regel-/Controller-Integration muss die Wurfbelege und die bestätigten Schadensquellen prüfen, einen etwaigen Reroll und Advantage/Disadvantage anwenden und die Konzentrationsentscheidung zusammen mit einer Spielstandsrevision persistieren.

Die vorhandenen APIs, JSON-/SQLite-Schemata, Controller, Story, UI, Backend, Versionsnummer und Ereignisformate bleiben unverändert. Bestehende Spielstände bleiben lesbar. Vollständige SRD-Regelabdeckung wird nicht behauptet.

## Testabdeckung

`app/test/srd_concentration_save_modifier_rules_test.dart`: acht Gruppen zu Konstitution und Übung, Mönch 13/14/Multiclassing, Erschöpfung, unbekannten Zusatzboni, Vorteil/Nachteil, fehlerhaften Klassen-/Attribut-/Übungseinträgen, fehlender Konzentration/Handlungsfähigkeit und alterungsresistentem JSON-/Snapshot-Abgleich.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_concentration_save_modifier_rules_test.dart
flutter test
flutter build apk --debug
```

Anforderungsstand: **partial**. Eine durchgängige Kampf-/Würfel-/SQLite-Integration und ein echter Android-Gerätetest bleiben offen.
