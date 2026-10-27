# Chat A – Mehrteilige SRD-Zaubermaterialien (27.10.2026)

## Quelle und Geltung

- D&D SRD 5.2.1, Kapitel *Spells / Components* und jeweilige Zauberbeschreibungen, Wizards of the Coast LLC, CC BY 4.0.
- Requirement: `RULE-SPELLS-MATERIAL-COMPONENTS` und `RULE-SPELLS-SPELL-COMPONENTS` bleiben ausdrücklich **partial**.
- Ausgangs-main: `4bd97b4d72fc747228df9bea46b61c3d4c82c382`.
- Isolierter Branch: `feat/chat-a/audited-multi-material-components-20261027`.

## IMPLEMENTIERT

Die bestehende pauschale Materialfreigabe war für katalogisierte Mehrfachmaterialien unzureichend. Für die vier Zauber **Astral Projection**, **Clone**, **Legend Lore** und **Secret Chest** wurden jeweils zwei geprüfte Katalog-Materialpositionen mit stabilen Anforderungs-IDs modelliert. Die exakte ursprüngliche englische Komponentenbeschreibung wird vor Verwendung gegen eine festgehaltene Signatur abgeglichen; geänderte Transkripte werden zunächst abgewiesen. Für jede Materialposition müssen **Identität/Preis**, **vollständige Anzahl** sowie bei Verbrauch **Reservierung** separat bestätigt sein. Mehrfach-IDs, unbekannte IDs, fehlende Positionen und falscher Verbrauchsstatus führen zur Ablehnung. Das normale und das Ritual-Preflight können Einzelbestätigungen weiterreichen.

Differenzierte Verbrauchsregeln: Bei **Clone** ist nur der Diamant Verbrauchsmaterial, nicht das Gefäß. Bei **Legend Lore** wird der Weihrauch, nicht die vier Elfenbeinstreifen, verbraucht. Bei **Astral Projection** werden die zwei Materialarten je bestätigtem Ziel verbraucht; die tatsächlich benötigte Anzahl bleibt explizit nachzuweisen. **Secret Chest** verbraucht keine der beiden Materialpositionen. Keine Regelinterpretation bei nicht inventarisierten Mehrfachmaterialien als vollständig ausgeben.

## Code, Tests, Grenzen

- `app/lib/domain/srd_spell_component_rules.dart`: reine Materialrezeptprüfung, Identitäts- und Mengenbestätigung, Verbrauch.
- `app/lib/domain/srd_spell_preflight_rules.dart` und `app/lib/domain/srd_ritual_casting_rules.dart`: optionale, bisher nicht von allen UI-Flows angebotene Einzelbestätigungen.
- `app/test/srd_multi_material_audit_test.dart`: positive/negative Nachweise, einschließlich Read-only-Preflight bei Secret Chest.

Die bestätigenden Booleans sind deklarierte Eingaben, **keine** automatische Inventarprüfung oder Beweis über den tatsächlichen Gegenstandspreis. Es wurden weder konkrete Inventar-ID-Zuordnung noch verpflichtender Abgleich mit Inventarbeständen, Zahlungs-/Materialtransaktionen oder Mehrziel-Mengenermittlung implementiert. Cast-UI für die neuen Einzelbestätigungen folgt in einem gesonderten Integrationspaket. Keine Story-Imports, keine Datenmigration, kein SQLite-/Kampagnen-JSON-Wechsel, keine unerlaubte Zustandsänderung.

## GETESTET / NICHT GETESTET / BLOCKIERT

**GETESTET:** Statische Prüfung des aktuellen Katalogs auf die vier exakten Komponentenbeschreibungen; weiterer CI-Status anhand des finalen Pull Requests verifizieren.

**NICHT GETESTET:** Bei Erstbeschreibung noch keine endgültige Dart-/Flutter-/Android-CI des Branchs; kein echter Android-Gerätetest.

**BLOCKIERT:** Lokales Flutter/Dart nicht verfügbar, daher CI über GitHub Actions. Die weitere UI-/Controller-/Inventarintegration ist wegen paralleler Änderungen ausdrücklich nicht Bestandteil dieses isolierten Regelpakets.

## NOCH NICHT IMPLEMENTIERT / NÄCHSTER SCHRITT

Kontrollierte Inventarzuordnung jeder Materialposition, Mengenbestätigung je Ziel bei Astral Projection, Kosten-/Wertnachweis, atomarer Materialverbrauch zusammen mit bestehender Inventar-/Slottransaktion und UI-Dialoge fehlen. Nächstes Paket soll nach erneuter Hauptbranch-/PR-Prüfung genau diese nachweisbare Transaktionsgrenze in der Integrationsspur angehen. Keine falsche vollständige SRD-Abdeckung behaupten.
