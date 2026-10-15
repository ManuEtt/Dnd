# Aetheria – einheitliches Dark-Fantasy-Design ab 0.4.0+16

Die Oberfläche nutzt jetzt durchgängig **denselben visuellen Stil wie der deutsche Charakterbogen**. Die neue zentrale Datei `app/lib/ui/fantasy_ui.dart` definiert die Palette, das Material-3-Theme und wiederverwendbare UI-Bausteine.

## Farben und Darstellungsregeln

- Nachtblau `#09121F`: App-Hintergrund
- Dunkelblau `#0D1927`: Navigation und Dialoge
- Blaugrau `#142536`: Karten und Panels
- Gold `#DDB96C`: Überschriften, Rahmen, wichtige Aktionen
- Elfenbein `#F4EAD6`: gut lesbare Schrift
- Hellblau `#79B8DD`: Magie und sekundäre Hervorhebung
- Rot `#D76D72`: Trefferpunkte und Warnung
- Grün `#64C4A1`: positiv bestätigte Zustände

Statt separater Designs verwenden alle Bildschirme `buildFantasyTheme()`. Die Komponenten `FantasyBackdrop`, `FantasyPanel`, `FantasySectionTitle`, `FantasyHeroBanner` und `FantasyStatTile` sind auch für neue Seiten zu verwenden.

## Integrierte Ansichten

1. **Start und Kampagnenauswahl:** gerahmter Einstieg, Kampagnenarchiv, Start-/Importaktionen und Hinweise.
2. **Abenteuer und Kampf:** gerahmte Kopfzeile, Szenen- und Begegnungskarten, hervorgehobener Eingabebereich, Erzähler-Sprechblasen und Kampfrunden.
3. **Heldenarchiv und Charakterbogen:** Heldendatenkarten, farbige Trefferpunkte-/Rüstungs-/Bewegungswerte, neuer Fantasy-Charakterbogen und bestehende Bearbeitungsfunktionen.
4. **Chronik und Kampagnengedächtnis:** einheitliche Erinnerungs-, Quest-, NPC-, Orts-, Rückblick- und Handlungsstrang-Panels.
5. **Optionen und KI-Backend:** Unterteilungen mit Icon/Trennlinie, gerahmte KI-Einstellungen, passende Formular- und Dialogfarben.
6. **Inventar, Würfeln, Export, Import, Charaktererstellung und Klassenassistenten:** gemeinsame Material-Theme-Stile; Inventar zusätzlich mit Statuskacheln und Kategorien in gerahmten Panels.
7. **Navigation:** bei Handybreite Navigation unten, ab 920 logischen Pixeln zusätzlich eine beschriftete Seitenleiste statt der unteren Leiste.

## Funktionale Grenzen

Der Umbau ist **nur optisch**. Keine Änderungen an Charakterwerten, SRD-Regeln, KI-/Backend-API, SQLite-Schema, JSON-Export oder Würfelgenerator. Fehlende Werte bleiben unbekannt. Ein persönliches Porträtfeld, eine eigenständige Weltkarten-Seite oder ein vollständiges SRD-Nachschlagewerk existieren in diesem Projekt noch nicht und wurden nicht durch Attrappen ersetzt.

## Prüfungen

- `python3 scripts/verify_project.py .`
- `python3 -m unittest discover -s scripts/tests -v`
- `cd app && flutter analyze`
- `cd app && flutter test`
- `cd app && flutter build apk --debug`

Die ersten beiden Prüfungen wurden in der Arbeitsumgebung durchgeführt. Flutter und Android-SDK sind hier nicht verfügbar; Flutter- und APK-Abnahme müssen in GitHub Actions erfolgen. Zusätzlich sind Widgettests für das Design-System und für 320/360/1000 logische Pixel beigefügt.
