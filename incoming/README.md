# Original-Fantasy-Grafiken hochladen

Für die vollständige Grafikinstallation **nur einmal** die bereits in ChatGPT
erzeugte Datei `Wuerfelraunen_Grafikpaket_Korrektur_2026-10-19.zip` in **diesen**
GitHub-Ordner `incoming/` hochladen.

1. In GitHub `incoming/` öffnen, **Add file** → **Upload files**.
2. Die unveränderte ZIP `Wuerfelraunen_Grafikpaket_Korrektur_2026-10-19.zip`
   auswählen und mit **Commit changes** auf `main` hochladen.
3. GitHub Actions → **Original-Grafiken aus ZIP übernehmen** verfolgen.

Die Aktion prüft das ZIP und das enthaltene SHA-256-Inventar, installiert genau
neun Originalporträts und vier Rahmenbilder unter `app/assets/fantasy/`,
löscht die hochgeladene ZIP-Datei wieder aus dem aktuellen Git-Stand und startet
anschließend den Android-Build. Dateien werden nicht blind überschrieben.
Bei einem Fehler bleibt das ZIP erhalten; das Hochladen allein ist daher noch
kein Nachweis einer erfolgreichen Integration.

Die Originalbilder dürfen nicht neu generiert, umbenannt oder mit falschen
Beispielbildern ersetzt werden. Bestehende Benutzer-Spielstände sind davon
nicht betroffen.
