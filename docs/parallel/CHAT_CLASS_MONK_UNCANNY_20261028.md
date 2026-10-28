# Chat Klassenautomatik – Mönch: Unheimlicher Stoffwechsel (SRD 5.2.1)

Stand: 28.10.2026. Quelle: Wizards of the Coast, [System Reference Document 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0 (Mönch, Stufe 2; Perfekter Fokus Stufe 15).

## Ausführbare Regel

- **Nur mit ausdrücklicher Spielerentscheidung beim Initiativewurf**: Der Aufrufer setzt `useUncannyMetabolism: true`; erzählter Text/LLM-Ausgaben lösen diese Nutzung **nie** selbst aus.
- Die Engine ermittelt die **Mönchsklassenstufe**, nicht die Gesamtstufe. Ab Mönch 2 regeneriert sie bei Aktivierung sämtliche verbrauchten Fokuspunkte.
- Heilung: Mönchsklassenstufe + tatsächlicher Würfelwurf auf dem stufengerechten Kampfkünste-Würfel (W6/W8/W10/W12), begrenzt auf bestätigte maximale Trefferpunkte.
- Genau **eine** Nutzung pro langer Rast im bestehenden `spentClassResources['uncannyMetabolism']`-Zähler. Kurze Rast erhält die Sperre; lange Rast setzt sie zurück. Legacy-JSON bleibt gültig. Ungültige Klassen/gefälschte Werte werden abgelehnt.
- Bei Mönch 15 ist die Wahl **entweder** Unheimlicher Stoffwechsel **oder** Perfekter Fokus (automatisch bis auf vier Fokuspunkte): nie beide beim selben Initiativewurf.
- Die drei vorhandenen Kampfbeginnwege des `GameEngine` verwenden die neue `MonkInitiativeFeatures.onInitiative`-Regel. Event-Payload dokumentiert bei bestätigter Aktivierung Würfelwurf, geheilte TP und zurückgewonnene Fokuspunkte.

## Schnittstelle

`GameEngine.act(campaign, input, useUncannyMetabolism: true)` und `GameEngine.acceptAdventure(campaign, useUncannyMetabolism: true)` benötigen **vorheriges UI-/Spieler-Opt-in**; Standard ist immer `false`. Für eigenständige Regeladapter ist `MonkInitiativeFeatures.onInitiative(hero, useUncannyMetabolism: true, dice: dice)` im Regel-API-Export verfügbar.

**UI:** Bei KI-Kampfangeboten erscheint bei einem berechtigten Mönch vor der Initiative eine zweite, explizite Schaltfläche **„Annehmen + Unheimlicher Stoffwechsel“**; die normale Schaltfläche bleibt ohne Verbrauch. Für kampfauslösende Freitext-/Skriptaktionen ist die vorherige UI-Bestätigung noch offen. Der PR bleibt ein einzelnes Klassenmerkmal, keine vollständige SRD-Automatik.

## Abnahme

```bash
cd app
flutter analyze
flutter test test/monk_uncanny_metabolism_test.dart test/monk_perfect_focus_test.dart test/class_resource_rules_test.dart
flutter test
```

Tests für No-op ohne Opt-in, Stufen 1/2/5/10/15, Mehrklassen, Trefferpunktgrenzen, Würfelwurf, Fokus/HP-Update, Rast, JSON-Roundtrip, ungültige Speicherstände, doppelte Nutzung sowie Skript- und KI-Kampfbeginn. Die automatische GitHub-CI ist maßgeblich; **ohne tatsächlich grüne CI keine vollständige Freigabe behaupten**.

## Folgearbeit

1. Vor Freitext-/Skript-Kampfbeginn einen separaten Bestätigungsdialog anbieten; die KI-Abenteuerannahme besitzt bereits eine explizite Auswahl.
2. UI-Widget- und Controller-Regression für den neuen KI-Angebotsknopf einschließlich deaktivierter/verbrauchter Nutzung bauen.
3. Nach Abgleich mit parallel laufendem PR #323 die Laufzeitabdeckung für `Uncanny Metabolism` von `manual` auf **bestätigte Regelaktion** setzen, **nicht** auf vollständig automatisch.
4. Restliche 281+ Merkmale benötigen eigene Wirkungs-, Ziel-/Dauer-, Auswahllogik- und E2E-Tests.
