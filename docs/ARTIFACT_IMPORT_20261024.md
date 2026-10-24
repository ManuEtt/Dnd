# Vollprojekt und Git-Patch importieren

Aktuelle Version: **0.8.38+88**. Patchbasis: `dcb42c5efff40a757994d4f5b5f8e98b2ff128e9`.
Code und tatsächliche Prüfungen: [CODEX_CHECKPOINT](CODEX_CHECKPOINT.md).

## Im bestehenden Repository

Der vorhandene Entwicklungs-PR ist der bevorzugte Integrationsweg. Alternativ den
versionierten Patch auf einem eigenen Branch von seiner exakten Basis anwenden:

```bash
git clone https://github.com/ManuEtt/Dnd.git
cd Dnd
git switch -c import/offhand-waffenpruefung dcb42c5efff40a757994d4f5b5f8e98b2ff128e9
git apply --check /pfad/Wuerfelraunen_Aenderungen.patch
git apply /pfad/Wuerfelraunen_Aenderungen.patch
bash scripts/check.sh
git add .
git commit -m "Import tested offhand weapon correction"
git push -u origin import/offhand-waffenpruefung
```

Tatsächlichen heruntergeladenen Patch-Dateinamen einsetzen. Danach einen PR nach
main erstellen. Wenn main inzwischen weiterentwickelt wurde, gemeinsame Prüfungen
und Konflikte vor Integration bearbeiten. Kein Force-Push und main nicht ersetzen.

## Vollprojekt-ZIP

Das lokale Projekt-ZIP enthält app/, backend/, scripts/, Tests, Assets, Dokumentation
und das versteckte .github/-Verzeichnis direkt in seiner Wurzel. In ein frisches
Verzeichnis entpacken; bei GitHub-Upload auch versteckte Dateien übertragen. Ein
kanonisches GitHub-Quellarchiv enthält zusätzlich einen äußeren Projektordner.
SDKs, Caches, private Spielstände, Geheimnisse und APKs gehören nicht in das Quell-ZIP.

```bash
python3 scripts/create_checkpoint.py --output-dir /pfad/ausserhalb-des-projekts \
  --base dcb42c5efff40a757994d4f5b5f8e98b2ff128e9 --label offhand-waffenpruefung-abschluss
```

Das Werkzeug prüft ZIP-CRC, Dateimanifest und die tatsächliche Patch-Anwendung auf
der angegebenen Basis. Versionierte Dateien bleiben erhalten. Prüfsummen stehen
separat in SHA256SUMS.txt; den ZIP-Selbsthash nicht in das ZIP hineinschreiben.

## Artefakte und Herkunft

Lokale Pakete: `/workspace/artifacts/`; neue Debug-/ARM64-APKs und ihre Metadaten:
`/workspace/artifacts/0.8.38+88/`. Ältere APKs bleiben unverändert erhalten und sind
kein Nachweis für diese Version. LATEST-Dateien verweisen auf den zuletzt erzeugten
Checkpoint; dessen Manifest nennt tatsächlichen HEAD und Teststatus.

Echte GitHub-Actions-Artefakte und PR-Links erst nach ihrer Erzeugung im operativen
Checkpoint übernehmen. Ein lokaler Dateipfad beweist keinen externen Upload.
Lokale und GitHub-APKs haben jeweils eigene Signatur-/Archivdigests. Build,
Signaturprüfung, Geräteinstallation und erfolgreiches Upgrade mit alten
Spielständen sind unterschiedliche Nachweise.
