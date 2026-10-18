# Würfelraunen – Erweiterung um individuelle Gegenstandswerte

Stand: 18.10.2026; auf GitHub `main`-Commit `e2be23b69769765f83c0c77decec325b36e67eb0` aufgesetzt.

## Neu
- Die optionalen `stats`-Daten werden pro Inventarinstanz separat gespeichert, ohne die Beschreibung umzudeuten.
- Im Charaktereditor lassen sich Gegenstandsart, Wert in Kupfermünzen, Gewicht, Waffen-/Rüstungswerte und Magieparameter editieren.
- Kataloggegenstände übernehmen bestätigte Basisfelder als explizite Datensatzwerte.
- Historische Inventare ohne `stats` bleiben kompatibel. Bekannte Katalogwerte werden beim Öffnen des Editors angezeigt, während unbekannte Daten unbekannt bleiben.
- Bestehende ausrüstbare SRD-Items behalten ihre `catalogId`; individuelle Änderung der `stats` verändert noch nicht heimlich Kampf- oder Rüstungsregeln.

## Import
1. Dieses Projekt als Ganzes entpacken.
2. Neue Dateien in einen separaten Git-Branch übernehmen, **nicht** als ZIP-Datei direkt im Repository belassen.
3. Im Verzeichnis `app` ausführen: `flutter pub get && dart format lib test && flutter analyze && flutter test`.
4. Android-Projekt über GitHub Actions bauen, danach erst in `main` mergen.
5. Bei bereits neueren Remote-Änderungen vorher anhand des Patches zusammenführen; den neueren Stand nicht unbesehen überschreiben.

## Sicherheit und Einschränkungen
- Noch keine eigene Kampfregelwirkung von überschriebenen Itemwerten; bestätigte SRD-Katalogwerte bleiben maßgeblich.
- Keine endgültige CI-Abnahme dieses Änderungspakets, bis Flutter-SDK-Analyse/Tests und Android-Build erfolgreich gelaufen sind.
- Nie automatisch vorhandene Spielstände löschen oder Arescan als festen Startcharakter wiederherstellen.
