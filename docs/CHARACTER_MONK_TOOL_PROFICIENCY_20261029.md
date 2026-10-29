# Mönch: bestätigte Werkzeugübung und Paketbindung

Quelle: offizielles [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
Core Monk Traits S.49, Proficiency S.8–9, Tool Proficiency S.93–95,
Rogue/Reliable Talent S.63 und Backgrounds S.83, CC BY 4.0.

## Geprüfter Produktstand

Version `0.8.48+98`, Code `53e8e72a58dc07bda07cc50a984142465a8cef79`,
Arbeitsbranch `feat/character-monk-tool-proficiency-20261029`.
[PR #390](https://github.com/ManuEtt/Dnd/pull/390) wurde regulär nach Main
`4193000fd28154eeb8b0be3497acc722f674c5ab` zusammengeführt.
Die [finale PR-CI 40920118585](https://github.com/ManuEtt/Dnd/actions/runs/40920118585)
ist erfolgreich. Ihr Checkout `2b2114560a22f743128e6ca3c24db16f4f1556aa`,
der Code-Commit und der Main-Merge haben denselben vollständigen Git-Baum
`1f976980975d5a29ac0277c44e1bc7b79d062ab3`.
Die zusätzliche [Main-CI 40922492508](https://github.com/ManuEtt/Dnd/actions/runs/40922492508)
ist ebenfalls vollständig erfolgreich; die tatsächlichen Logs bestätigen
2.450 Flutter-, 221 Python-, 72 Backend- und weitere 20 UI-Tests sowie
Debug-/native Prüfungen, alle drei optimierten ABIs und Alpha-/Quellpakete.
Dieser Dokumentationsnachtrag behauptet keinen neuen APK-Build.

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
  Bei ausdrücklich gewählter Geschicklichkeit (Heimlichkeit) wird der
  Rüstungsnachteil berücksichtigt; andere Attribute übernehmen ihn nicht.
- Der Charakterbogen zeigt nur eine Attributsvorschau. Kein automatisches
  Werkzeugnutzen/Herstellen, keine angenommene Verfügbarkeit, kein SG und keine
  ungeprüfte Würfel-, Zeit-, Material- oder Kampagnenänderung.

## Anforderungsnachweis

| Requirement | Code/UI | Tests | Status |
| --- | --- | --- | --- |
| CHAR-MONK-TOOL-PROFICIENCY | starting_class_choice.dart, starting_equipment_import.dart, srd_class_selection_dialog.dart, character_editor.dart | monk_tool_proficiency_rules_test.dart, srd_monk_tool_creation_dialog_test.dart, character_start_class_ui_test.dart | begrenzte Startentscheidung lokal und in finaler PR-CI bestanden |
| EQUIP-CHOICES | dieselbe Paketbindung | dieselben Gegenproben zu A/B, Wiederholung und Abbruch | Gesamtanforderung weiterhin partial; dieses Teilpaket getestet |
| RULE-EQUIPMENT-TOOLS | tool_proficiency_rules.dart, character_rule_engine.dart, tool_proficiency_panel.dart, fantasy_character_sheet.dart | monk_tool_proficiency_rules_test.dart, tool_proficiency_panel_test.dart | teilweise, tatsächliche Werkzeugaktionen offen |
| Quelle/Audit/Persistenz/Bestand | bestehendes Hero-JSON/Repository, srd_character_creation_audit.dart | monk_tool_storage_test.dart, historische v1/v2-Klassenfälle | lokal und in finaler PR-CI bestanden |

## Tatsächlich ausgeführte Prüfungen

Lokal bestand `bash scripts/check.sh` auf `53e8e72a`: **2.450 Flutter-,
221 Python- und 72 Backend-Tests**, Formatprüfung mit 535 unveränderten
Dart-Dateien, saubere Analyse, Backend-Typecheck/Build und Backend-Smoke.
Zusätzlich bestanden der ARM64-Debug-Build und zwölf native App-Tests
ohne Fehler, Auslassungen oder Überspringen.

Die finale PR-CI wiederholte die vollständigen Tests mit denselben Zählern,
20 weiteren gezielten UI-Tests, Debug-APK, nativen Gradle-Tests und
optimierten APKs für ARM32, ARM64 und x86_64. Die neuen Widgetfälle prüfen
320/360 dp, 200 % Schrift, geöffnete Tastatur, Semantik und erreichbare
Berührungsflächen. Das sind automatisierte Prüfungen, keine Geräteabnahme.

Ein früher Vollversuch wurde für die ausdrückliche Fertigkeitswahl bewusst
beendet und zählt nicht als Erfolg. Der Vorlauf auf `be758357` hatte
2.448 erfolgreiche Flutterfälle und genau einen Fehler: die alte feste
Audit-Anzahl elf ignorierte den neuen zwölften Mönch-Pflichtschritt.
[CI 40918212562](https://github.com/ManuEtt/Dnd/actions/runs/40918212562)
ist deshalb historisch fehlgeschlagen. Die Erwartung wurde mit ausdrücklicher
Prüfung der fehlenden Werkzeugwahl korrigiert. Weitere Gegenproben reproduzierten
und beheben den Heimlichkeits-Rüstungsnachteil sowie eine gesperrte leere
Werkzeugauswahl beim Mönch→Barbar→Mönch-Rückwechsel. Kein Test wurde deaktiviert.

## Herunterladbarer, unabhängig geprüfter Checkpoint

- [PR-Quellcode, Patch und Git-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40920118585/artifacts/12917978197):
  alle 1.286 Manifestdateien samt SHA256/Modus geprüft, Patch tatsächlich auf
  Basis `fde0ef6ed8b419d6a31c701a03aa05d61994c352` angewendet und alle Dateien
  verglichen; Bundle unabhängig wiederhergestellt und mit Git-FSCK geprüft.
- [ARM64-Alpha mit demselben Quellcode](https://github.com/ManuEtt/Dnd/actions/runs/40920118585/artifacts/12917743855):
  APK `Wuerfelraunen_v0.8.48_98_arm64.apk`, 20.421.574 Bytes,
  ausschließlich `arm64-v8a`, Version 98; APK-v2-Testsignatur geprüft.

SHA256 des inneren Quellcode-ZIP:
`9070e1754b5d2838121f320a54c8d1fa5d93120b51f4f7bea6f47db51844116a`.
SHA256 des binärfähigen Patches:
`b95379033fad2a9e70dde9c615a7e316b8db6e8f35d11a4ce50f02d981f4fe33`.
SHA256 der ARM64-Alpha-APK:
`822ba41736c79854b863218984df4563f8bf3e2f56da2cc7a8b61dc73660a0c4`.
Diese Hashes beziehen sich auf die enthaltenen Dateien, nicht auf die äußeren
GitHub-Artefakt-ZIPs. GitHub-Artefakte unterliegen der Aufbewahrungsfrist des Laufs.

**NICHT GETESTET:** echtes Android-Gerät/TalkBack, installiertes Altversionsupgrade
und produktive Signierung. **BLOCKIERT:** kein angeschlossenes Testgerät;
kein Code-/GitHub-Zugriffsblocker. **NOCH NICHT IMPLEMENTIERT:** tatsächliche
Werkzeugaktionen mit bestätigtem Besitz, SG, Würfeln, Zeit und Material sowie
die übrigen Pflichtentscheidungen des vollständigen Charakterassistenten.

SQLite 3, Kampagnen-/Hero-JSON1 unverändert; interne Klassenwahlversion3,
keine Datenbankmigration. Details/SHA/Prüfergebnisse im CODEX_CHECKPOINT.
Die gesamte Charaktererstellung bleibt unvollständig. Nächster Schritt:
Barden-Instrumentübungen mit eigener Quellenprüfung und kompatibler Versionierung.
Bestehende v1/v2/v3-Belege erhalten dabei keine rückwirkenden Pflichtfelder.
Die vorherigen Schreibstände dieser Fachdatei und der Charakterabdeckungsmatrix
bleiben bytegenau unter `docs/history/monk_tool_acceptance_20261029/` mit
`MANIFEST_TECHNICAL.json` erhalten.

## Zusätzlich geprüfte Main-Artefakte

[Main-Quell-ZIP/Patch/Manifest/Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40922492508/artifacts/12918224840)
und [Main-ARM64-Alpha](https://github.com/ManuEtt/Dnd/actions/runs/40922492508/artifacts/12918823598)
wurden ebenfalls heruntergeladen und mit allen 1.286 Hashes/Modi, tatsächlicher
Patch-Anwendung, unabhängiger Bundle-Wiederherstellung/fsck und APK-Metadaten
geprüft. Quelldateien und Binärpatch besitzen dieselben SHA256 wie oben.
Die Main-APK stammt ausdrücklich aus `4193000f`; ihr SHA256 ist
`4fdf28d6581dd94d7cbcdc7f00f470b313c249cd52d45c3d1ae454b20ae69c79`.
Die abweichenden APK-Hashes ersetzen keinen Geräte-/Update-Nachweis.
