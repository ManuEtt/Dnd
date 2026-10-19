# Würfelraunen – vollständiges Grafik-Ergänzungspaket (19.10.2026)

Dieses ZIP ergänzt das GitHub-Projekt `ManuEtt/Dnd` mit den Originalgrafiken aus `wuerfelraunen_fantasy_assets(1).zip`.

## Enthalten
- Alle 9 Originalcharakterporträts (`portrait_1.webp` bis `portrait_9.webp`, jeweils 256×256).
- Original-Konzeptvorlagen für Rahmen und Buttons (unter `docs/graphics/original`).
- Dekodierte Original-Nachtkulisse und Original-Porträtatlas.
- Vier aus den Originalvorlagen vorbereitete Flutter-WebP-Rahmen-/Buttonassets.

## Einspielen
1. Aktuelle Version von `https://github.com/ManuEtt/Dnd` abrufen.
2. Diesen ZIP-Inhalt in die **Repositorywurzel** entpacken, so dass `app/assets/fantasy/portrait_1.webp` existiert.
3. Bestehende Dateien nur nach Vergleich überschreiben; die enthaltenen 9 Porträts und Zusatzrahmen sind neu.
4. Der Dart-Code der zugehörigen Korrektur bevorzugt automatisch diese 9 Originalbilder und nutzt bei fehlenden Assets den bisher vorhandenen Atlas.
5. Unter `app/`: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug` ausführen.

**Hinweis:** Dieses Archiv ist ein Ergänzungspaket mit Quellgrafiken, keine kompilierte oder getestete APK.
Weitere Rahmen- und Buttonhintergründe liegen als Flutter-Assets vor, brauchen aber für die fertige Oberflächengestaltung noch eigene responsive Widgets.
`docs/graphics/original` wird nicht als Android-Asset eingebunden.
