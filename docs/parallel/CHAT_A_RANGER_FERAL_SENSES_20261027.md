# Chat A: Waldläufer Feral Senses (SRD 5.2.1, Stufe 18) – 27.10.2026

## Quelle und Abgrenzung

- Wizards of the Coast, [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0, **Ranger level 18 – Feral Senses**: Blindsight mit 30 Fuß Reichweite.
- Regelstatus: **partial**. Das Klassenmerkmal selbst und die Reichweite sind automatisch verfügbar. Die Erkennung eines konkreten Ziels wird **nicht** behauptet, nur weil seine Distanz in Reichweite liegt: bestätigte Position, Deckung/Hindernisse, Verstecken und andere relevante Wahrnehmungsregeln müssen separat aufgelöst werden. Keine Angriffs-Vorteile oder andere Wirkungen hinzuerfunden.
- Stack: dieses kleine Feature-PR basiert auf der noch offenen **Integration #280**, die ihrerseits die grünen #276 (Roving) und #278 (bestätigte Kletter-/Schwimmbewegung) koordiniert. **#280 muss vor diesem Paket integriert werden.**

## Implementiert

- `app/lib/domain/srd_ranger_feral_senses_rules.dart`: read-only Blindsight-Freischaltung ab **Waldläufer-Klassenstufe 18** (nicht Gesamtstufe) und bestätigte 30-Fuß-Grenze, keine weitere Game-/Story-/UI-Abhängigkeit.
- `app/lib/ui/fantasy_character_sheet.dart`: Blindsicht mit 9 m / 30 Fuß im Verteidigungsreiter der Figur nur mit vorhandener Freischaltung.
- `app/lib/domain/srd_class_feature_catalog.dart` und `docs/srd_5_2_1_requirements.json`: **partial** statt fehlender oder fälschlich vollautomatischer Wahrnehmung; ID `CLASS-WALDL-UFER-18-BASE-FERAL-SENSES-0`.
- `app/test/ranger_feral_senses_rules_test.dart`: Stufen 17/18/20, legale Mehrklasse, bestätigte/unbestätigte Entfernungen, Unveränderlichkeit, Katalog und JSON-Rundlauf.
- `app/test/ranger_feral_senses_sheet_test.dart`: Darstellung auf 360 px und keine unberechtigte Freischaltung auf Stufe 17.

## Bewusst offen

- Keine automatischen Angriffe gegen unsichtbare Wesen, keine Detektion durch Deckung, Dunkelheit oder Hindernisse ohne eigenes bestätigtes Zielmodell.
- Kein Speicherschema-/Controller-/GameEngine-Umbau und keine neue API für unbestätigte Gegner.
- Flutter-Tests und Android-APK erst nach grüner CI auf dem finalen PR-Head als bestanden kennzeichnen. Echte Geräteabnahme separat erforderlich.
