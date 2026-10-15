# GitHub-Import – Aetheria 0.3.9+15

Basis: `ManuEtt/Dnd`, `main`, Commit `125fc3630722002a955a4e3479395edd6bfb6635` (0.3.8+14).

1. ZIP entpacken. Alle Dateien, auch `.github/`, direkt in die Repository-Wurzel hochladen, **nicht** die ZIP selbst.
2. Vorzugsweise einen neuen Branch von diesem Basiscommit erstellen. Bei zwischenzeitlich neueren Commits erst vergleichen/zusammenführen.
3. Besonders die neue Datei `app/lib/ui/fantasy_character_sheet.dart`, die Änderungen in `app/lib/ui/app.dart`, `app/test/fantasy_character_sheet_test.dart`, `backend/test/backend.test.ts` und die Dokumentation mit übertragen.
4. Unter **GitHub Actions** zunächst Projektprüfung, Backend, `flutter analyze`, `flutter test` und die APK-Builds abwarten. Dieses ZIP ist **Quellcode**, keine installierbare APK.
5. Auf dem Gerät unter **Helden** den Bogen eines gespeicherten Helden öffnen; dieselbe Ansicht im **Abenteuer** aufrufen. Deutsch, TP-Anzeige, sechs Attributkarten, Rettungswürfe, Zustände und Verteidigung prüfen. „Charakter bearbeiten“ muss den vorhandenen Editor öffnen.

Es werden keine API-Schlüssel oder persönlichen Spielstände im neuen Paket hinzugefügt. Der `main`-Branch wurde hier nicht verändert.
