# SRD 5.2.1 – Feuerpfeil / Fire Bolt (0.8.23+73)

**Quelle:** [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), `Spells / Fire Bolt` unter CC BY 4.0. Der bisherige spell-indexierte Namensbestand stammt aus einer öffentlichen SRD-5.2.1-Transkription und bleibt zum Vollabgleich markiert.

## Tatsächlich umgesetzte Mechanik

Feuerpfeil ist ein **Zaubertrick (Grad 0)** für **Magier** (Intelligenz) und **Zauberer** (Charisma) mit Magieaktion, V/S-Komponenten, 120 Fuß Reichweite und einem **Fernkampf-Zauberangriff**. Die Engine verlangt ausdrücklich bestätigte Ziel-/Umstandsbedingungen, inklusive etwaiger Deckung, aktueller gegnerischer Schild-RK sowie fehlender **weiterer** gegnerischer Feuer-Schadensmodifikatoren/ungeklärter Schildreaktion.

- Zauberangriffsbonus: Zauberattributsmodifikator + Übungsbonus der Charakterstufe, abzüglich Erschöpfungsabzug. Der natürliche W20 und Gesamtergebnis werden getrennt protokolliert; Vorteil/Nachteil mit d20-Auswahl und bestätigtes liegendes Ziel werden geprüft.
- Treffer (W20 20 automatisch, W20 1 nie) fügt **1W10** Feuer auf Stufe 1–4, **2W10** Stufe 5–10, **3W10** Stufe 11–16, **4W10** Stufe 17–20 zu. Kritischer Treffer würfelt doppelt so viele Schadenswürfel. Kein Schaden bei Fehlschlag.
- Bestehender Gegner erhält die berechneten Trefferpunktänderungen; das Kampfevent `spell.fireBolt` speichert W20, Trefferstatus, Bonus, Deckungs-RK, Schadenswürfel/-typ und verbleibende Gegner-TP.
- **Nur die Magieaktion** ist verbraucht; Zauberplatz und `spellSlotExpendedThisTurn` bleiben unverändert. Ein alter Spielstand behält seine Schema-/JSON-Formatstruktur.
- Der Controller prüft erwartete Revision und atomaren SQLite-Checkpoint. Die Schnellaktion **Feuerpfeil** erscheint nur, wenn ein bestätigter bekannter Zauber vorliegt. Vor Würfeln sind tatsächliche Voraussetzungen anzukreuzen.

## Noch offen – deshalb Matrixstatus TEILWEISE

**Nicht** automatisch: entzündbare Objekte, unbestätigte Feuerresistenz/Immunität/Anfälligkeit, mehrere Gegner/Zielwechsel, automatischer Standort/Sichtlinie, beliebige Monster-Spezialreaktionen, vollautomatische situationsabhängige Vorteilsbestimmung. Die Oberfläche verlangt hier ehrliche Bestätigung und verändert nicht selbstständig unbekannte Gegnerfähigkeiten.

Dateien:
- `app/lib/domain/fire_bolt_rules.dart`
- `app/lib/domain/game_engine.dart` / `app/lib/services/game_controller.dart`
- `app/lib/ui/fire_bolt_dialog.dart` / `app/lib/ui/app.dart`
- `app/test/fire_bolt_rules_test.dart` / `app/test/fire_bolt_dialog_test.dart`

Vor `main`-Merge vollständig erforderlich: Python-Struktur/Audit, Backend-Tests, Dart format, flutter analyze/test, Android-Debug-APK, native Android-Tests und arm64/arm/x64 Alpha-Artefakte über GitHub CI. Android-Geräteabnahme bleibt separat offen.
