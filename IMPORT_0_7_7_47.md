# Würfelraunen 0.7.7+47 importieren

Der vollständige Stand enthält `app/`, `backend/`, `docs/`, `scripts/`, `.github/` und alle Wurzeldateien. Das Quell-ZIP enthält keine SDKs oder APKs. Prüfstatus und offene Regeln: `CHECKPOINT.md`, `docs/RULE_COVERAGE.md`. Vollständige vorherige Checkpoints bleiben separat erhalten.

## Git-Patch (empfohlen)

Der Patch ist auf **b66354f3112165d76aa340a2f2ab5705f8019e1a** erstellt, enthält auch neue Dateien und kann vor jeder Übernahme geprüft werden. In einem neuen sauberen Klon:

```bash
git clone https://github.com/ManuEtt/Dnd.git
cd Dnd
git switch -c feature/wuerfelraunen-0.7.7 b66354f3112165d76aa340a2f2ab5705f8019e1a
git apply --check /pfad/zur/Wuerfelraunen_0.7.7+47_DATUM_heilzauber_Aenderungen.patch
git apply /pfad/zur/Wuerfelraunen_0.7.7+47_DATUM_heilzauber_Aenderungen.patch
```

Den tatsächlichen Dateinamen aus dem Download einsetzen. Danach prüfen, committen und den eigenen Branch pushen. Eine neuere bestehende Arbeitskopie nicht zurücksetzen oder blind überschreiben; Änderungen in einem neuen Branch vergleichen und zusammenführen.

## Vollständiges ZIP

ZIP entpacken, anschließend seine **Inhalte** in die Wurzel eines neuen Klons auf einem eigenen Branch kopieren. `app/`, `backend/`, `scripts/` und `.github/` müssen direkt in der Repositorywurzel liegen, ohne zusätzlichen Dnd-Unterordner. Versteckte Dateien einschließen, insbesondere `.github/` und `.gitignore`; den vorhandenen `.git/`-Ordner des Klons erhalten. Das ZIP selbst in GitHub hochzuladen entpackt es nicht.

## Prüfen und in GitHub sichern

Mit Flutter 3.35.7 / Dart 3.9.2, Node 22.14.0, Java 17 und unter Linux libsqlite3-dev:

```bash
bash scripts/check.sh
cd app
flutter build apk --debug
cd ..
git add .
git commit -m "Würfelraunen 0.7.7: ausführbare Effekte und Heilzauber"
git push -u origin feature/wuerfelraunen-0.7.7
```

Danach einen Pull Request auf main erstellen und normale Android-GitHub-Actions-Prüfungen abwarten. Kein Force-Push und keine automatische Codex-Entwicklung. Der direkte Push dieser Entwicklungssitzung und die verbundene Branch-Erstellung scheiterten an HTTP403; deshalb werden vollständiges ZIP und verifizierter Patch bereitgestellt.

`SHA256SUMS.txt` prüft die tatsächlichen Dateien, z. B. unter Linux mit `sha256sum --ignore-missing -c SHA256SUMS.txt`. Das Dateimanifest nennt exakte Basis/HEAD und Byte-/Modushashes. Es belegt auch die tatsächliche Patch-Wiederherstellungsprüfung. Eine separat bereitgestellte Debug-APK ist lokal testsigniert; APK-Build ist keine Abnahme auf einem realen Androidgerät.
