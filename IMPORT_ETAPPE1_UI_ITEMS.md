# Würfelraunen – vollständiges Projekt-ZIP mit UI-/Itemwerte-Etappe 1

Stand: 18. Oktober 2026.

## Inhalt und Herkunft

- Vollständiger Flutter-/Android-/Backend-Quellcode aus dem GitHub-Actions-Quellcode-Checkpoint zum Commit `f4da42c6c1d28037d1cf9791beb7cafcb5b58c93`.
- Am 18.10.2026 war `main` auf `a4f2dabb91d39395e310471cee2d8b5f82b3dc33`. Im Vergleich zu `f4da42c6` fügte `main` nur die Datei `docs/prompts/Wuerfelraunen_Codex_Prompt_UI_und_strukturierte_Items.md` hinzu. Dieses Paket enthält eine aus dem hier erstellten Prompt übernommene Markdown-Fassung der Datei; deren Formatierung muss nicht bytegleich mit dem GitHub-Dokument sein.
- Darauf angewendet: `Wuerfelraunen_UI_Itemwerte_Etappe1.patch` (gegen den unveränderten Quellcode-Checkpoint auf Anwendbarkeit geprüft).
- Die Ergänzungen sind: `app/lib/ui/equipment_fields.dart`, Änderungen an `equipment_catalog_dialog.dart` und `character_editor.dart`, sowie neue Flutter- und Python-Regressionstests.

## Bereits verändert

1. Bestehende mechanische SRD-Werte werden im Equipment-Katalog als getrennte, benannte Felder angezeigt.
2. Beim Hinzufügen eines Kataloggegenstands landen die mechanischen Daten nicht mehr im Freitext `InventoryItem.description`; sie bleiben über `catalogId` dem Katalog zugeordnet.
3. Die Schnellaktionen bleiben wie bisher nur innerhalb der Abenteueransicht an `Scaffold.bottomNavigationBar` befestigt.

## Noch nicht umgesetzt

- Vollständige editierbare und strukturierte Werte für **eigene** Inventargegenstände sowie zusätzliche magische Effekte.
- Komplettes visuelles Redesign aller App-Seiten nach den Konzeptbildern.
- Ausführung der neuen Flutter-/Dart-Widgettests und Neubau der APK. Dieser Schritt erfordert eine Flutter-/Android-Umgebung.

## Import in GitHub

Dieses ZIP enthält die Projektdateien direkt auf oberster ZIP-Ebene (kein zweites verschachteltes ZIP).

1. In GitHub im Repository `ManuEtt/Dnd` einen separaten Branch anlegen (z. B. `feature/ui-itemwerte-etappe1`).
2. ZIP **lokal entpacken**. Ein einzelner ZIP-Upload nach GitHub entpackt die Dateien nicht automatisch.
3. Die entpackten Projektinhalte in einen frischen Klon kopieren, ohne einen eventuell neueren Stand blind zu überschreiben. Achte besonders auf `.github/` und andere versteckte Dateien.
4. Im Ordner `app`: `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, und optional `flutter build apk --debug` ausführen.
5. Änderungen committen und einen Pull Request nach `main` erstellen. Keine ungetesteten Änderungen direkt auf `main` erzwingen.

**Regel:** Wenn in GitHub nach Commit `a4f2dabb...` neue Änderungen vorliegen, zuerst abgleichen und Konflikte auflösen. Alte Spielstände und bestehende Domainlogik nicht ungeprüft ändern.
