# Projektpaket und Patch importieren

Der aktuelle operative Stand und echte GitHub-PR-/CI-Links stehen in [CODEX_CHECKPOINT.md](CODEX_CHECKPOINT.md). Quellcode-ZIP und Git-Patch entstehen mit:

```bash
python3 scripts/create_checkpoint.py --output-dir /pfad/ausserhalb-des-projekts \
  --base 1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd --label sneak-main-integriert-abschluss
```

Das Skript prüft ZIP-Integrität, Dateihashes und die Anwendung des Patches gegen genau diesen Basis-Commit. Versionierte Pakete werden erhalten. Das ZIP enthält den vollständigen importierbaren Quellcode einschließlich Tests, Assets, Backend, scripts/ und verstecktem .github/-Verzeichnis; keine SDK-Caches, Zugangsdaten oder APKs. Android-Binaries bleiben separate Artefakte.

## Bestehendes GitHub-Repository

Den Patch auf einem eigenen Branch vom angegebenen Basis-Commit anwenden:

```bash
git clone https://github.com/ManuEtt/Dnd.git
cd Dnd
git switch -c import/sneak-attack-checkpoint 1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd
git apply --check /pfad/Wuerfelraunen_Aenderungen.patch
git apply /pfad/Wuerfelraunen_Aenderungen.patch
bash scripts/check.sh
git add .
git commit -m "Import tested Sneak Attack checkpoint"
git push -u origin import/sneak-attack-checkpoint
```

Den tatsächlichen versionierten Dateinamen verwenden. Anschließend PR nach main erstellen. Hat main inzwischen weitere Änderungen, Konflikte und gesamte gemeinsame Testbasis vor dem Merge prüfen. Weder main überschreiben noch Force-Push verwenden.

## Vollprojekt-ZIP

In ein frisches Verzeichnis entpacken. app/, backend/, scripts/ und .github/ müssen unmittelbar in dessen Wurzel liegen. Bei GitHub-Upload auch das versteckte .github/-Verzeichnis übertragen. Persönliche Spielstände und lokale Geheimnisse separat behalten. Die bereits vorhandene PR-Variante ist für das bestehende Repository vorzuziehen.

## Artefakte

- Lokale Dateien dieser Umgebung: `/workspace/artifacts/`; `Wuerfelraunen_LATEST_Vollprojekt.zip` und SHA256SUMS.txt zeigen auf den zuletzt geprüften lokalen Quellen-Checkpoint.
- GitHub-Workflow `Android-Alpha bauen`: erfolgreicher Lauf liefert eigenen Quellcode-Checkpoint sowie Debug- und ABI-Alpha-APKs unter den echten Actions-Artefakten. Deren Namen/Links erst nach Beobachtung des konkreten Laufs übernehmen.
- Ein Workspace-Dateipfad ist kein Beleg für einen externen Upload. APK-Build, Signaturprüfung, Gerätestart und sichere Installation über eine frühere App sind getrennte Nachweise.

Konkreter überprüfter integrierter Code-Lauf: [CI40059091439](https://github.com/ManuEtt/Dnd/actions/runs/40059091439), completed/success auf a6a949c / Merge-Test30fb8f2. [Quell-ZIP](https://github.com/ManuEtt/Dnd/actions/runs/40059091439/artifacts/12547141868) und [Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40059091439/artifacts/12546708433) sind tatsächlich vorhanden. Abschlussdokumentation verändert den ausführbaren Code nicht. Neue lokale APKs liegen unter `/workspace/artifacts/0.8.37+87_main_1c2ee/`; alte Vorintegrationsartefakte bleiben erhalten. Die neue Patchbasis ist1c2eeab.
