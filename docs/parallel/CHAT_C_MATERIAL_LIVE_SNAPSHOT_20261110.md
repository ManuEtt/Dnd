# Entwicklungscheckpoint – Aktualisierung der Zaubermaterial-Auswahl

Stand: 2026-11-10

## Grundlage und Koordination

- CHAT-KENNUNG: C (Flutter/Android-UI).
- Ausgangs-`main`: `73f377ece91cb14a5074ddba16fbbc57b153026e`.
- Arbeitsbranch: `feat/chat-c/material-live-snapshot-reset-20261110`.
- Implementierungscommit: `4d40096bb2ad791937a904311eb291334e54a73e`.
- Widgettest-Commit: `eede4e409f90cbc0119b9b062e1b3f756c993c11`.
- Pull Request: https://github.com/ManuEtt/Dnd/pull/676 (Draft bis zur Abnahme).
- Vorher 63 offene PRs und die Fachpfade der offenen UI-PRs geprüft. Kein bekannter Fachpfad-Konflikt mit diesem Paket; beim Merge erneut prüfen.
- Die gemeinsam genutzten Dokumentationsdateien `README.md`, `docs/CODEX_CHECKPOINT.md` und `docs/parallel/CHAT_C_CHECKPOINT.md` sind von zahlreichen offenen PRs betroffen. Deshalb hier ein paketbezogener Checkpoint statt einer konkurrierenden Überschreibung; gemeinsame Nachträge sind durch die Integration zu koordinieren.

## Ausgangsproblem

Die Materialanforderungen, Duplikatprüfung und Materialbestätigungen wurden im `SrdMaterialInventoryDialog` nur einmal in `initState` vorbereitet. Erhält der weiterhin geöffnete Dialog einen anderen `HeroCharacter`- oder `SrdSpellDefinition`-Snapshot, sind alte Auswahlen und explizite Freigaben nicht mehr gültig. `DropdownButtonFormField` behält zudem seinen internen Wert unabhängig von aktualisiertem `initialValue`.

## Änderung

- `app/lib/ui/srd_material_inventory_dialog.dart`: `didUpdateWidget` reagiert auf neue Helden-/Zauberinstanzen, setzt alle Materialfreigaben, Stapel, Zieleingaben und Fehlermeldungen zurück und lädt Rezept/Inventarprüfung erneut. Versionsgebundene Identität montiert den Formularinhalt einschließlich der Dropdown- und Textfelder neu.
- `app/test/srd_material_inventory_live_snapshot_test.dart`: drei Widget-Regressionsfälle für den Live-Wechsel des Helden mit gleichbleibenden Stapel-IDs, den Wechsel über zwei geprüfte und ein ungeprüftes Zauberrezept und einen fehlerhaften Inventar-Snapshot mit Duplikat-IDs.

## Akzeptanzkriterien

1. Nach Live-Wechsel dürfen weder alte Stapel noch Bestätigungen oder Zieleingaben erhalten bleiben.
2. Nach neuem Heldensnapshot müssen alle zugehörigen expliziten Materialprüfungen wiederholt werden; anschließend ist eine read-only Auswahl möglich.
3. Materialanforderungen, Validierungsfehler und Sperrstatus folgen dem aktuell übergebenen Zauber und Inventar.
4. Ungültige Inventar-IDs blockieren die Bestätigung fail-closed; der Wechsel zurück zu gültigen Daten hebt die Setup-Sperre auf, aber genehmigt nichts automatisch.
5. Kein Regelzustand und keine Ressourcen werden im Dialog verändert; keine Schema-/JSON-/SQLite-Migration.

## Tests und Abnahme

- Flutter/Dart lokal: **nicht verfügbar**, daher Widgettests, Analyse, Dart-Formatierung und APK-Build lokal **nicht ausgeführt**.
- Python-/Backend-Projektsuiten aus diesem Stand: **nicht ausgeführt** (kein vollständiger lokaler Checkout; GitHub-Connector-Dateizugriff).
- GitHub Actions: beim Anlegen des Checkpoints **noch nicht final abgenommen**, konkreten PR-HEAD und die einzelnen Jobs prüfen.
- Android-Gerät/IME/TalkBack: **nicht ausgeführt**.
- Keine Tests wurden deaktiviert; keine Spielregel, Persistenz oder Versionsnummer geändert.

## Nächster Schritt

Nach CI-Abnahme ein separates UI-Paket für die explizite Zieleingabe bei `Astral Projection` auf 320/360 dp, 200 % Schrift und geöffneter Bildschirmtastatur prüfen; Akzeptanz: Eingabe und Abbruch bleiben erreichbar, alte Zielanzahlen werden nach einem Snapshotwechsel weder angezeigt noch bestätigt. Vor Beginn erneut offene PRs und betroffene Dateien prüfen.
