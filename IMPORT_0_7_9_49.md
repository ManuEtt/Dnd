# Würfelraunen 0.7.9+49 importieren

Das vollständige Quell-ZIP enthält app/, backend/, docs/, scripts/, .github/ und die Wurzeldateien ohne zusätzlichen Dnd-Unterordner. APK und SDKs sind separate Dateien. Aktueller Prüfstand und Fortsetzung: CHECKPOINT.md.

## Git-Patch

Die neue Patchbasis ist **c889ab6619fe88bd48a420bc45f12d2751af94f7**, der am 17.10.2026 abgeglichene GitHub-main mit dem bisherigen Stand 0.7.7. Die Patches älterer Sitzungen haben andere Basen. In einem neuen, sauberen Klon:

```bash
git clone https://github.com/ManuEtt/Dnd.git
cd Dnd
git switch -c feature/wuerfelraunen-0.7.9 c889ab6619fe88bd48a420bc45f12d2751af94f7
git apply --check /pfad/zur/Wuerfelraunen_0.7.9+49_DATUM_todesrettung_Aenderungen.patch
git apply /pfad/zur/Wuerfelraunen_0.7.9+49_DATUM_todesrettung_Aenderungen.patch
```

Den tatsächlichen Artefaktnamen einsetzen. Neuere eigene Änderungen anschließend vergleichen und zusammenführen; keinen bestehenden Arbeitsstand zurücksetzen oder blind ersetzen.

## Vollständiges ZIP

ZIP lokal entpacken und seine Inhalte in die Wurzel eines Klons auf eigenem Branch übernehmen. Versteckte Dateien einschließlich .github/ und .gitignore mitnehmen; den vorhandenen .git/-Ordner erhalten. Eine einzelne ZIP-Datei in GitHub hochzuladen entpackt sie nicht. Unter Unix gegebenenfalls `chmod +x app/android/gradlew scripts/check.sh` nach dem Entpacken ausführen; das Archiv erhält die Dateimodi.

## Prüfen und sichern

Mit Flutter 3.35.7 / Dart 3.9.2, Node 22.14.0, Java 17, Android SDK und unter Linux libsqlite3-dev:

```bash
bash scripts/check.sh
cd app
flutter build apk --debug
cd ..
git add .
git commit -m "Würfelraunen 0.7.9: Zuggrenzen und Todesrettungen"
git push -u origin feature/wuerfelraunen-0.7.9
```

Danach Pull Request erstellen und die normalen GitHub-Test-/Build-Actions abwarten. Kein Force-Push. Der erneute direkte Push dieser Sitzung wurde mit HTTP403 verweigert; main blieb unverändert. Die lokale Patchwiederherstellung wird unabhängig davon tatsächlich geprüft.

SHA256SUMS.txt prüft vorhandene Artefakte mit `sha256sum --ignore-missing -c SHA256SUMS.txt`. Das Dateimanifest enthält die tatsächliche Basis, HEAD und Byte-/Modushashes. Eine separate Debug-APK ist lokal testsigniert; Geräteverhalten und Updatekompatibilität brauchen eine eigene Abnahme.
