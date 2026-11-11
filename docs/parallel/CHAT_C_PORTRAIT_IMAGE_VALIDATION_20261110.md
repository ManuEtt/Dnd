# Porträtbild-Validierung – 10.11.2026

## Ausgangsproblem
Die Galerie begrenzte die Dateigröße eines eigenen Charakterbilds auf 45 KB, dekodierte anschließend aber zunächst das Bild in seiner nativen Auflösung und prüfte erst danach, ob Breite oder Höhe 256 Pixel überschreiten. Stark komprimierte Bilder mit großen Abmessungen konnten dadurch unnötig hohe temporäre Bitmap-Allokationen auslösen.

## Lösung
- Eingebettete Bildmaße mit `ui.ImageDescriptor.encoded` vor dem Erzeugen eines Decoders prüfen.
- Überdimensionierte Bilder vor dem Pixel-Decoding ablehnen.
- Gültige Bilder weiterhin tatsächlich dekodieren, damit defekte Bilddaten nicht akzeptiert werden.
- Bild, Codec, Descriptor und ImmutableBuffer in einem `finally`-Block freigeben.
- Bestehende Dateigrößenbegrenzung, 256-Pixel-Grenze, Galerieauswahl und Speicherformat unverändert lassen.

## Akzeptanzkriterien
- 256 × 256 Pixel werden akzeptiert.
- 257 × 1 Pixel werden als zu groß abgelehnt.
- Leere und ungültige Bilddaten werden als ungültig abgelehnt.
- Kein Bild wird vor Prüfung der eingebetteten Dimensionen auf voller Originalgröße dekodiert.
- JSON-/SQLite-Spielstände bleiben unverändert.

## Geänderte Fachdateien
- `app/lib/ui/character_portrait_picker.dart`
- `app/test/character_portrait_test.dart`

## Teststatus
Die Regressionstests wurden ergänzt. Lokale Flutter-/Dart-Ausführung steht in dieser Sitzung nicht zur Verfügung; der GitHub-Actions-Lauf auf dem finalen PR-HEAD ist noch abzuwarten.

## Kompatibilität
Keine Änderung an Modellen, JSON, SQLite, Berechtigungen, App-Version, Regelengine oder Story. Keine Migration.

## Koordination
Die zentralen Dateien `README.md`, `docs/CODEX_CHECKPOINT.md` und `docs/parallel/CHAT_C_CHECKPOINT.md` werden wegen konkurrierender offener PR-Änderungen nicht parallel verändert. Dieser paketbezogene Checkpoint und die PR-Beschreibung halten den Fortschritt fest; die zentrale, append-only Dokumentationskonsolidierung bleibt ein separater konfliktfreier Schritt.
