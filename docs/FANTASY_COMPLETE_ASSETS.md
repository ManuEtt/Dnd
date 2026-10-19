# Vollständige Fantasy-Grafiken: Portäts, Rahmen, Schaltflächen

## Stand der Integration

Die aktuelle Flutter-Oberfläche benutzt vier eigene freigestellte WebP-Arten:
- `ornate_panel_background.webp` für `FantasyPanel` und damit Dialog- und Statusbereiche;
- `ornate_button_background.webp` für `FantasyShortcutTile` in Startseite und Abenteuer-Schnellaktionen;
- `ornate_card_background.webp` für `FantasyCampaignCard`;
- `ornate_portrait_border.webp` für `FantasyCharacterPortrait`.

Außerdem versucht `FantasyCharacterPortrait`, bei `portraitPreset` 0 bis 8
die neun Originaldateien `portrait_1.webp` bis `portrait_9.webp` zu laden.
Der bisherige kleine Atlas bleibt eine kompatible Rückfallebene. Bei den
Rahmen existiert dieselbe Rückfallebene auf die bisherigen Vektorecken und
Dunkelblau-Gold-Theme. Alle Texte, Buttons und Charakterwerte bleiben echte
Flutter-Widgets. Dekorationen sind nicht fokussierbar und blockieren Touch
nicht. Keine Speicherformat- oder D&D-Regeländerungen.

## Wichtig: Original-WebPs in den GitHub-Branch übertragen

Das vollständige Binärpaket befindet sich im vom Nutzer erhaltenen Archiv
`Wuerfelraunen_Grafikpaket_Korrektur_2026-10-19.zip`. Die GitHub-Connector-
Schnittstelle kann Quellcode schreiben, aber die Originaldateien des
separaten Archivs nicht ohne weiteren Import als Binärdateien übernehmen.
Deswegen zeigt ein neuer Build ohne diesen Schritt nur den Fallback!

Vom Stammordner des GitHub-Repositories aus:

```bash
python3 scripts/import_complete_fantasy_assets.py /pfad/zu/Wuerfelraunen_Grafikpaket_Korrektur_2026-10-19.zip
git add app/assets/fantasy/portrait_*.webp app/assets/fantasy/ornate_*_background.webp app/assets/fantasy/ornate_portrait_border.webp
git commit -m "assets: Original-Fantasy-Porträts und Rahmen integrieren"
git push
```

Der Importer prüft SHA-256 und RIFF/WEBP-Kennung und verweigert fremde,
abweichende Dateien, statt sie überschreiben. Er ist wiederholbar. Er kopiert
nur die 13 bisher fehlenden Dateien, nicht die großen Konzeptbilder. Alternativ
kann man `app/assets/fantasy/` aus dem ZIP in den Repository-Ordner kopieren;
dabei Dateien keinesfalls blind überschreiben.

## Prüfungen und Abnahme

```bash
python3 scripts/import_complete_fantasy_assets.py /pfad/zu/ZIP --verify-only
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Die Android-APK **muss nach dem binären Commit neu gebaut** werden. Der
Grafik-Fix ist ohne Geräteabnahme nicht als auf einem realen Android-Gerät
fertig getestete Oberfläche auszugeben. Die alten 96-Pixel-Atlasansichten
bleiben für bereits vorhandene Benutzerstände nutzbar.
