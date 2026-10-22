# SRD 5.2.1: Linienförmige Flächen auf dem 5-Fuß-Raster

Stand: 22.10.2026. Fachquelle: [D&D System Reference Document 5.2.1](https://www.dndbeyond.com/srd), Rules Glossary **Area of Effect**, **Line** und **Cover**, CC BY 4.0.

## Implementiert

`app/lib/domain/srd_line_area_rules.dart` bietet eine **read-only 2D-Vorschau** der *möglichen* Rasterfelder einer vom konkreten Zaubereffekt bestätigten Linie:

- `SrdLineAreaRules.preview`: freie und vollständig bestätigte 2D-Karte, Ursprungsfeld, separat bestätigte Länge (5–300 Fuß in 5-Fuß-Schritten), Breite (5–60 Fuß in 5-Fuß-Schritten) und eine von acht festgelegten Himmelsrichtungen.
- Rechteckige Projektion der Linie vom **Ursprungspunkt** in die vorgegebene Richtung. Eine inklusive SAT-Rechteck-Quadrat-Prüfung markiert auch Berührungen von Rändern oder Ecken **nur als Kandidaten**. Das Mittelpunktmerkmal `centerWithinLine` ist unabhängig von Randüberlappung.
- Der Ursprungspunkt ist standardmäßig nicht im Mittelpunktmerkmal enthalten und erfordert explizite Zustimmung zum Einschluss. Das **gesamte Ursprungsfeld** bleibt als Überlappungskandidat erhalten und ist separat durch `originCellRequiresReview` gekennzeichnet.
- Bestätigte Vollhindernisfelder werden nicht als freie Bodenfelder angeboten. Ein gesperrter Mittelpunktstrahl führt nur zu `SrdSphereCenterRay.requiresCoverReview`; er beweist **nicht** vollständige Deckung, da ein anderer ungesperrter Strahl möglich sein kann.
- `previewConfirmedSpell` prüft erst die katalogisierte Zauberreichweite zum Ursprung. Linienform, **Länge und Breite** müssen separat am SRD-Effekt bestätigt werden und dürfen nicht aus der bloßen Reichweite erfunden werden. Beispiel `Lightning Bolt` (Self-Ursprung; eigentliche Linienmaße aus dem Effekt).
- Ergebnisliste unveränderlich; keine Lager-, Slot-, Figuren-/Gegnerzustands- oder SQLite-Änderung.

## Nicht implementiert

Der Code berechnet weder vollständige 3D-Linienräume, beliebige Winkel, Höhenunterschiede, exakte 5-Fuß-Feldabdeckungsentscheidungen, freie Strahlen durch alle Punkte eines Raumes noch reale betroffene Kreaturen/Gegenstände. Sichtlinie, Teildeckung, Total-Cover-Grad, Ausweichen, Rettungswürfe, Schaden, Hochstufen, Konzentration, einzelne Spezialeffekte und tatsächliche Karte-/Kampf-UI sind **nicht** Teil des Inkrements. Insbesondere ist `centerWithinLine` niemals ein Nachweis eines gültigen Treffers.

## Testabdeckung

`app/test/srd_line_area_rules_test.dart` prüft Zentrum versus Grenzkandidat, Ursprungspunkt und Ursprungsfeld, unabhängige Breite und Länge, entgegengesetzte und diagonale Richtungen, bekannte Hindernisse mit offenem Cover-Review, unvollständige Karte, blockierten Ursprung, ungültige Maße, Kartengrenzen, Unveränderlichkeit und `Lightning Bolt` mit bestätigtem Self-Ursprung und getrennten Effektmaßen.

Die maschinenlesbaren Auditpunkte `RULE-SPELLS-SPELL-AREAS-OF-EFFECT`, `RULE-SPELLS-SPELL-TARGETS`, `RULE-SPELLS-SPELL-ATTACK-COVER` bleiben **partial**.

Prüfung über GitHub Actions auf dem PR-HEAD: Python-Projekt-/Importgrenzen, Backend-Tests, Dart-Format, Flutter-Analyse und -Tests, Android-Debug-APK, native Android-Tests sowie Alpha-Artefakte. Ein bestandenes CI-Build ersetzt keinen Geräteabnahmetest.
