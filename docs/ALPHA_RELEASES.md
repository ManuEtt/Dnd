# Versionierte Android-Alpha-Artefakte

Seit **0.5.4+24** erhält ein vollständig erfolgreicher `android-build.yml`-Lauf zusätzlich zu den bisherigen Debug- und ABI-APKs ein einzelnes, zusammengehöriges Release-Artefakt. Es enthält:

- `Wuerfelraunen_vX.Y.Z_BUILD_Source.zip` – vollständiges wiederherstellbares Projekt im Repository-Root-Layout
- `Wuerfelraunen_vX.Y.Z_BUILD_arm64.apk` – tatsächlich gebaute Android-ARM64-Alpha (AOT)
- `Wuerfelraunen_vX.Y.Z_BUILD_ReleaseNotes.md` – Commit, CI-Nachweis und Warnung zur Signatur
- `Wuerfelraunen_vX.Y.Z_BUILD_SHA256.txt` – Checksummen für Quellarchiv, APK und Notizen
- `Wuerfelraunen_vX.Y.Z_BUILD_Source.zip.sha256` – zusätzlicher Prüfnachweis des Packagers

`python3 scripts/prepare_alpha_release.py "$RUNNER_TEMP/wuerfelraunen-release" --commit "$GITHUB_SHA" --run-url "https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"` baut nichts eigenständig. Das Skript liest `app/pubspec.yaml`, kontrolliert ZIP-Integrität und die erforderlichen `arm64-v8a`-Bibliotheken im schon gebauten APK, erzeugt das Quellenarchiv außerhalb des Projektordners und die Checksummen.

**Freigaberegel:** Diese Veröffentlichung läuft in GitHub Actions erst nach Backend-, Python-, Flutter- und Android-Tests sowie den Debug- und AOT-Builds. Schlägt eine Prüfung fehl, wird kein neues **freigegebenes** Release-Artefakt erstellt. Der separate Quellcode-Checkpoint wird dank `if: always()` weiter bereitgestellt und ausdrücklich nicht als installierbare getestete Version ausgegeben.

**Einschränkung:** Solange die vorhandene Release-Build-Konfiguration eine Debug-Testsignatur verwendet, ist keine langfristig konsistente Aktualisierbarkeit garantiert. Vor Installation bestehende Daten per JSON sichern. Im Android-Studio-/Codex-Import fehlt bewusst eine vorgebaute APK: Sie entsteht ausschließlich im erfolgreichen CI-Build. API-Schlüssel, `.env`-Dateien und private Signiermaterialien dürfen nicht in das Quellarchiv gelangen.

## Benutzung nach Import

1. Vollständiges Projektarchiv ohne zusätzlichen Oberordner auf einen neuen Branch übernehmen.
2. GitHub Actions `Android-Alpha bauen` auslösen oder nach Commit ablaufen lassen.
3. Erst bei grünem Workflow unter **Artifacts** nach `wuerfelraunen-alpha-...` suchen.
4. Artefakt herunterladen, SHA-256-Datei prüfen, danach ARM64-APK testen.
5. Fehlerhafte Läufe nur aus dem `wuerfelraunen-source-checkpoint-...`-Artefakt reparieren; Checkpoint nicht als Release deklarieren.
