# Vollprojekt und Patch importieren –0.8.39+89

Bevorzugt [PR166](https://github.com/ManuEtt/Dnd/pull/166) nach dessen Abhängigkeit PR160 integrieren. Der Patch gehört zu Basis **6f2ebbc893fb5ee053d069410a103a102662aa4d**, nicht unmittelbar zum älteren Mainb60ffe7. Enthält der aktuelle Main die Basis noch nicht, dort nicht ungeprüft anwenden. Vollständiges ZIP enthält bereits die Basis plus Light-Paket.

```bash
git clone https://github.com/ManuEtt/Dnd.git
cd Dnd
git switch -c import/light-checkpoint 6f2ebbc893fb5ee053d069410a103a102662aa4d
git apply --check /pfad/Wuerfelraunen_Aenderungen.patch
git apply /pfad/Wuerfelraunen_Aenderungen.patch
bash scripts/check.sh
git add .
git commit -m "Import tested Light attack checkpoint"
git push -u origin import/light-checkpoint
```

Tatsächlichen versionierten Patchnamen verwenden, anschließend PR erstellen. Keine Mainüberschreibung und kein Force-Push. Bei inzwischen verändertem Main gemeinsame Basis neu prüfen und Konflikte auflösen.

ZIP in frisches Verzeichnis entpacken; app/,backend/,scripts/,Tests,Assets,docs/ und verstecktes .github/ gehören in die Projektwurzel. Das kanonische GitHub-ZIP hat zusätzlich einen äußeren Projektordner. SDKs,Caches,Geheimnisse,persönliche Spielstände und APKs sind nicht im Quell-ZIP. APKs bleiben separate Artefakte.

```bash
python3 scripts/create_checkpoint.py --output-dir /pfad/ausserhalb-des-projekts \
  --base 6f2ebbc893fb5ee053d069410a103a102662aa4d --label light-abschluss
```

Das Werkzeug prüft CRC,Dateihashes und tatsächliche Patch-Anwendung auf der Basis. Versionierte Pakete bleiben erhalten. Lokale Dateien unter /workspace/artifacts/, APKs/Prüfungen unter /workspace/artifacts/0.8.39+89/. Echte GitHub-Artefaktlinks am PR wählen; ein Workspacepfad beweist keinen externen Upload. Lokale und GitHub-Binaries haben eigene Signatur-/Archivdigests. Gerätestart und sicheres Upgrade bleiben ungetestet. Details: [CODEX_CHECKPOINT](CODEX_CHECKPOINT.md).
