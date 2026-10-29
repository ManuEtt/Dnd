# Mönch: bestätigte Werkzeugübung und Paketbindung

Quelle: offizielles [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
Core Monk Traits S.49, Proficiency S.8–9, Tool Proficiency S.93–95,
Rogue/Reliable Talent S.63 und Backgrounds S.83, CC BY 4.0.

## Fachliche Abnahmegrenzen

- Genau eine ausdrückliche Wahl aus 17 Handwerkszeugen oder zehn Instrumenten.
- A liefert dieses Werkzeug, Speer, fünf Dolche, Entdeckerausrüstung und 11 GM;
  B nur 50 GM, die erlernte Werkzeugübung bleibt trotzdem bestehen.
- Ein erstmaliger Mönch als Zweitklasse erhält diese Core-Tool-Wahl nicht.
- Klassenbeleg v3 prüft Pflichtwahl auch ohne Paket sowie Gleichheit von
  Ausrüstung und Übung bei A. Neue nicht-Mönch-Belege erhalten keinen Toolwert.
  Alte v1/v2 bleiben nach ihrem ursprünglichen Vertrag lesbar/ungeklärt.
- Erneute Bestätigung ergänzt kein Gold/Inventar. A bindet die Übung an das
  bereits übernommene Werkzeug; B darf im ungespeicherten Entwurf ausdrücklich
  neu gewählt werden, ohne zweite Gaben. Abbruch verändert keinen Charakter.
- Historische typisierte Quellen bleiben bei späteren Anzeigenamens-/Klassen-/
  Hintergrund-/Inventaränderungen erhalten. Keine Übung aus Freitext oder Besitz.
- Werkzeug-/Hintergrundquellen bilden eine Menge: gleicher Bonus nur einmal.
  Passende tatsächlich trainierte SRD-Fertigkeit gibt bei ausdrücklicher Relevanz
  Vorteil, nicht nochmals PB. Historischer Medizin-Alias wird nur lesend erkannt.
  Zustände/Erschöpfung bleiben erhalten; Schurke7-Mindestwurf gilt auch für Tools.
- Der Charakterbogen zeigt nur eine Attributsvorschau. Kein automatisches
  Werkzeugnutzen/Herstellen, keine angenommene Verfügbarkeit, kein SG und keine
  ungeprüfte Würfel-, Zeit-, Material- oder Kampagnenänderung.

## Anforderungsnachweis

| Requirement | Code/UI | Tests | Status |
| --- | --- | --- | --- |
| CHAR-MONK-TOOL-PROFICIENCY / EQUIP-CHOICES | starting_class_choice.dart, starting_equipment_import.dart, srd_class_selection_dialog.dart, character_editor.dart | monk_tool_proficiency_rules_test.dart, srd_monk_tool_creation_dialog_test.dart, character_start_class_ui_test.dart | lokal gezielt bestanden, finale CI separat |
| RULE-EQUIPMENT-TOOLS | tool_proficiency_rules.dart, character_rule_engine.dart, tool_proficiency_panel.dart, fantasy_character_sheet.dart | monk_tool_proficiency_rules_test.dart, tool_proficiency_panel_test.dart | teilweise, tatsächliche Werkzeugaktionen offen |
| Quelle/Audit/Persistenz/Bestand | bestehendes Hero-JSON/Repository, srd_character_creation_audit.dart | monk_tool_storage_test.dart, historische v1/v2-Klassenfälle | gezielt lokal bestanden |

SQLite 3, Kampagnen-/Hero-JSON1 unverändert; interne Klassenwahlversion3,
keine Datenbankmigration. Details/SHA/Prüfergebnisse im CODEX_CHECKPOINT.
Die gesamte Charaktererstellung bleibt unvollständig. Nächster Schritt:
Barden-Instrumentübungen mit eigener Quellenprüfung und kompatibler Versionierung.
