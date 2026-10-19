# Grafikfehlerbehebung – Original-Porträts

## Ursache
Im Repository `ManuEtt/Dnd` waren von den neun Original-Porträts mit
256 × 256 Pixeln nur die kleinen Ausschnitte aus
`app/assets/fantasy/portrait_atlas.webp` vorhanden. Die App konnte
deshalb die Originale nicht anzeigen, auch wenn ein Benutzer sie bereits
im separaten Grafik-ZIP besaß.

## Korrektur
`FantasyCharacterPortrait` verwendet, sofern Flutter die neun Dateien
`app/assets/fantasy/portrait_1.webp` bis `portrait_9.webp`
eingebunden hat, jetzt die entsprechenden Originale. Die Auswahlindizes
0 bis 8 bleiben dabei erhalten. Fehlen die Dateien, bleibt das bisherige
Atlasbild sichtbar. Ungültige eigene Bilddaten zeigen weiterhin einen
neutralen Fallback. Bereits gespeicherte Charakterbilder werden nicht
geändert.

## Assetpaket und GitHub-Grenze
Das Originalarchiv wurde vollständig als
`Wuerfelraunen_Grafikpaket_Korrektur_2026-10-19.zip`
aufbereitet. Es enthält die neun Original-Porträts, die Nachtgrafik
sowie vorbereitete Goldrahmen und Original-Konzeptvorlagen. Das
zusätzliche Grafikpaket muss in die Repositorywurzel entpackt
und als **separater binärer Commit** nach GitHub übertragen werden;
die Bilddaten befinden sich noch nicht vollständig in diesem PR.

Der aktuelle Hauptbranch enthält weiterhin das kleine Atlasbild, die
bisherigen Icons, Hintergrundbilder und die Gold-Ecken. Die vier großen
Grafikrahmen im Zusatzpaket benötigen noch eine separate responsive
UI-Integration; ihre reine Existenz als Dateien garantiert keine
Darstellung.

## Überprüfung
```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Zusätzliche Tests unter
`app/test/high_resolution_portrait_fallback_test.dart`.
