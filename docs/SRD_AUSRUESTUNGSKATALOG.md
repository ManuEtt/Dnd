# D&D-SRD-Ausrüstungskatalog – Würfelraunen 0.5.9+29

**Quelle:** [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0; Seiten 89–102 (Waffen, Rüstungen, Werkzeuge, Abenteuerausrüstung), 204–253 (magische Gegenstände). Siehe `THIRD_PARTY_NOTICES.md`.

## Datensatz

- **38 von 38** Waffen der SRD-5.2.1-Waffentabelle: Standard-Schadenswürfel, Schadensart, Handhabung, Reichweite, Eigenschaften, Meisterschaft, Gewicht, Preis.
- **13 von 13** Rüstungseinträge einschließlich Schild: Basis-RK, BE-Deckel, ST-Mindestwert, Heimlichkeitsnachteil, Gewicht und Preis. `armorClassWithDex` liefert reine Vorschau. Die Übung mit Rüstung/Schild und weitere Boni werden **nicht** automatisch angenommen.
- **92** Abenteuerausrüstung, Pakete, Munition und Fokusvarianten sowie **50** weitere Werkzeuge, Spielsets, Instrumente, Tiere und Fahrzeuge.
- **79** namentlich erfasste magische SRD-Katalogeinträge. **Nicht die gesamte Magie-Gegenstandsliste**: Wirkungen, Seltenheitsstufen, Einstimmung, Ladungen und automatische Boni müssen in späteren Paketen erst pro Eintrag geprüft und modelliert werden. Kein Effekt wird stillschweigend angewendet.
- Insgesamt **272 katalogisierte Einträge**. Deutsche Benennungen für die Benutzeroberfläche sind projektbezogen; die englischen SRD-Namen sind als Referenz erhalten.

## Integration und Grenzen

Im Charaktereditor öffnet „Aus SRD-Katalog wählen“ einen Such- und Kategorien-Dialog. Beim bewussten Hinzufügen entsteht ein regulärer Inventareintrag mit **optionaler `catalogId`**. Daten aus alten Savegames haben dieses Feld nicht und bleiben importierbar; manuell erfasste Gegenstände funktionieren weiterhin. **Kein automatischer Goldabzug, keine RK- oder Schadensänderung, kein ohne Bestätigung aktivierter magischer Effekt.** Der Katalog ist nicht gleich einem vollständigen Handels- oder Ausrüstungssystem.

Für eine vollständige Implementierung der Gegenstände aus allen D&D-Büchern besteht ohne ausdrückliche Lizenz keine Freigabe. Das SRD beschreibt eine rechtlich nutzbare Teilmenge; Homebrew kann später als eindeutig getrennte Datenquelle ergänzt werden.

## Nachweise

`app/test/srd_equipment_catalog_test.dart` prüft Katalogumfang, IDs, Waffendaten, RK-Grenzen, Suchergebnisse und Legacy-JSON-Migration. `app/test/ui_equipment_catalog_test.dart` prüft die Auswahl bis in den Charakterbogen. Zusätzlich sind volle Flutter-Analyse, Tests und APK-CI vor Freigabe auszuführen.
