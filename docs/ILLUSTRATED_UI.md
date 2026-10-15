# Aetheria 0.5.0+20 – Illustrierte Dark-Fantasy-Oberfläche

## Konzept und technische Umsetzung

Die vier zuvor gestalteten Aetheria-Mockups wurden als **visuelle Referenzen** umgesetzt. Screenshots sind nicht als geklickte Pixeloberfläche eingesetzt; sämtliche Navigations- und Aktionsflächen sind Flutter-Widgets, und Beschriftungen/Zahlen stammen aus den existierenden Datenmodellen.

### Grafiken

- `app/assets/art/ruins.webp`: Bild für den Einstieg und die Abenteuer-Szene.
- `castle.webp`: Fantasy-Burg im Charakterbogen und Heldenarchiv.
- `shadow_forest.webp`, `blood_mountains.webp`, `forgotten_woods.webp`: drei abwechselnde Kampagnenmotive und die Chronik.
- `item_sword.webp`, `item_shield.webp`, `item_potion.webp`, `item_book.webp`, `item_bag.webp`, `item_scroll.webp`, `item_crystal.webp`: dekorative Symbole für passende Gegenstandsbezeichnungen.

Die Motive wurden aus den eigens für dieses Projekt erstellten Konzeptgrafiken extrahiert, grafische UI-Symbole und falsche Spielstandwerte wurden beim Zuschnitt ausgespart. Sie sind lokal im APK eingebunden. Die Bilddateien ändern keine gespeicherten Gegenstände. Für unbekannte Gegenstandsnamen wird ein neutrales Rucksack-Icon angezeigt.

### Flutter-Komponenten

Neue Datei `app/lib/ui/fantasy_art.dart`:
- `FantasyArtwork`: Assets und regelunabhängige Bilderzuordnung
- `FantasyOrnamentPainter`: goldene Zierecken
- `FantasyIllustratedBanner`: Titel, Beschreibung und funktionale Aktion
- `FantasyCampaignCard`: gespeicherte Kampagnen auswählen/löschen
- `FantasyScenePanel`: Landschaft und tatsächlicher Erzähltext
- `FantasyShortcutTile`: wiederverwendbare Schaltfläche
- `FantasyHeroMedallion`: individuelle Initialen statt eines fiktiven Charakterporträts
- `FantasyInventoryCards`: nur echte Inventargegenstände mit informativem Detaildialog

### Bereits vorhandene Spielmechanik bleibt unverändert

Kampagnenverwaltung, Würfelengine, Spracheingabe, Sprachausgabe, lokale SQLite-Spielstände, JSON-Backups, KI-Anbindung sowie Kämpfe verwenden weiterhin dieselben Services und Methoden.

### Bekannte Grenzen

- Keine eigenständige Weltkarte, Bildgenerierung je Szene, Porträt-Datenfelder oder ausgerüstete Slots im Domänenmodell; die Mockup-Funktionen wurden daher nicht vorgetäuscht.
- Die Gegenstandskacheln sind eine Anzeige der gespeicherten Inventardaten. Gegenstände können durch diese neue Ansicht nicht angelegt oder abgelegt werden.
- Ein echter Android-Screenshot und ein durchgelaufener Flutter/Android-CI-Build für **0.5.0+20** stehen noch aus.
- Aktuelle Builds verwenden Debug-Signierung auch für die vorläufigen Release-Artefakte. Regelmäßige Alpha-Updates sollten eine stabile Signierung erhalten.
