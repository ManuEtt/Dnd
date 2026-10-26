# Chat A – Zauberreichweite: kanonische Mengen und Überlaufschutz (26.10.2026)

## Problem und Abgrenzung

`SrdSpellTargetRules.maxRangeFeet` interpretierte bisher `0 feet`, `1 miles`, `2 foot` und `01 mile` als numerische SRD-Reichweiten. Sehr große Meilenwerte wurden ohne explizite 64-bit-Grenze multipliziert. Dies kann unbestätigte Katalogmetadaten als reguläre Zielreichweite akzeptieren.

## Änderung und Akzeptanz

- In `app/lib/domain/srd_spell_target_rules.dart` wird ausschließlich die rein lesende Range-Interpretation gehärtet: positive dezimale Zahl ohne führende Null, grammatisch passendes `foot/feet` bzw. `mile/miles`, `int.tryParse` und expliziter 64-bit-Überlaufschutz vor der Umrechnung.
- Bestehende gültige Katalogreichweiten und 1 Meile = 5280 Fuß bleiben erhalten. Unbekannte Werte liefern `null` und werden in `validateOrigin` weiter als `UnsupportedError` verweigert.
- `app/test/srd_spell_target_rules_test.dart` prüft acht negative bzw. überlaufende Angaben und positive Grenzfälle; vorhandener 339-Zauber-Katalogtest bleibt bestehen.

**Quelle:** Wizards of the Coast LLC, SRD 5.2.1, *Spellcasting / Range* und *Targets*, CC BY 4.0, https://www.dndbeyond.com/srd . Diese Eingabevalidierung ist kein Nachweis einer vollständigen Ziel-, Wirkungs- oder Sichtlinien-Engine. Abdeckung bleibt partial.

## Ausgangslage und Zusammenarbeit

- Ausgangs-main: `5e3116f9e3f8de0af6e8125a97b3962cb8910cdf`.
- Branch: `fix/chat-a/spell-range-unit-validation-20261026`.
- Offene Fremdpakete bei Start: #236 (Chat A Eldritch Blast), #237 (Chat B NPC), #239/#240 (Chat C UI). Keine gemeinsame Laufzeit- oder Testdatei.
- `docs/parallel/CHAT_A_CHECKPOINT.md` wird von PR #236 geändert und hier bewusst nicht überschrieben; dieser separate Fachcheckpoint dokumentiert das unabhängige Paket.
- `README.md` und `docs/CODEX_CHECKPOINT.md` werden additiv dokumentiert; Chat D muss ihre konkurrierenden Änderungen bei Integration konsolidieren.

## Prüfplan, Risiken und Migrationen

1. `flutter test test/srd_spell_target_rules_test.dart`, vollständiges `flutter test`, Dart-Format, `flutter analyze`, APK-Build und CI.
2. Projekt-/Grenzprüfungen, Coverage-Inventar und Backendtests als Gesamtregression.
3. Zusätzlich laufende GitHub Actions auf exaktem Branch-HEAD prüfen; ohne CI keinen Testerfolg behaupten.

Kein Würfelwurf, kein Effekt, kein Ressourcenverbrauch und keine Speicherung im geänderten Parser. SQLite 2, Kampagnen-JSON 1 und alle vorhandenen Spielstände bleiben unverändert; keine Migration nötig.

## Status

Implementierung und Regressionstests sind eingecheckt; Test-/CI-Ergebnisse werden erst nach tatsächlich abgeschlossener Ausführung ergänzt. Kein Merge nach main.
