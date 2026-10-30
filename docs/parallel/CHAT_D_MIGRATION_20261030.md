# Chat D – geprüfte Branch-Konsolidierung vom 30.10.2026

Dieser Bericht dokumentiert das technische Teilpaket des ausdrücklich
beauftragten Gesamtimports für Issue #425. Er ist kein Nachweis eines bereits
erfolgten Main-Merges, einer gelöschten Remote-Branch oder einer Geräteabnahme.

## Ausgangspunkt und Verfahren

- Geprüfte Ausgangsbasis: `6465a4b2fc8d42ae7aab596ac26e85d61d2b8f49`.
- Lokaler Integrationsbranch: `integrate/tooling-all-20261030`.
- Fachlich geprüfter kombinierter Quellstand:
  `6cbb34f1` (vollständige SHA über Git auflösen).
- 15 ursprüngliche Chat-D-Branch-Heads vollständig als Vorfahren enthalten;
  `fix/chat-d/npc-picker-scroll-layout-20261030` gehört zum gesonderten
  UI-Integrationspaket.
- 14 reguläre Merge-Commits; der bereits über #435 integrierte
  `integrate-ci-safety`-Head war schon Vorfahre der Ausgangsbasis.
- Konflikte betrafen ausschließlich additive Markdown-Abschnitte. Beide
  Seiten wurden mit dem Union-Merge erhalten. Keine technische Datei musste
  durch `ours` oder `theirs` ersetzt werden.
- Die kompletten bisherigen Zeilen von README, zentralem Checkpoint und
  Chat-D-Checkpoint sind nachweislich in ihrer ursprünglichen Reihenfolge
  erhalten. Historische Aussagen über laufende CI sind historische Nachweise,
  keine neue Freigabe des Gesamtsystems.

## Enthaltene ursprüngliche Branches

| Branch unter `fix/chat-d/` | Gesicherter ursprünglicher Head |
| --- | --- |
| `apk-entry-types-20261030` | `14470f238740c767e0b68dd16ffe277219d096c4` |
| `backend-public-origin-20261030` | `76fbca6ef27b85e4bbae3757b934b972b1f6b442` |
| `boundary-module-presence-20261030` | `0544c238c39da11b4f18e77a70c1cb0af10b4bbd` |
| `bounded-metadata-preflight-20261029` | `0ede900ca86f67bf35a7b4632c45328494702e1e` |
| `checkpoint-publish-lock-20261029` | `974bc29aae832197c696520877333ad512668b80` |
| `fantasy-button-output-safety-20261030` | `236e6666ab4c68cddf63487d081bafd598c3cb56` |
| `fantasy-import-symlink-20261030` | `ead299e3f149023082f33186294ddc28b064f10b` |
| `integrate-archive-apk-safety-20261030` | `325589daedf451299629d69d64392ec30275e405` |
| `integrate-boundaries-ndk-20261030` | `6dac0109cdd7bc46d043bd81d12c651859e4bf2e` |
| `integrate-ci-safety-20261030` | `31b023e49c826dc4279b4848756dd421f877058c` |
| `pending-action-sqlite-validation-20261030` | `dd48f28203a04846beef78c96185580ef00c9f46` |
| `preserve-installed-ndk-20261030` | `1f8a6c81e9b294bf16e897c994a6861636b246b7` |
| `retire-main-recheck-20261030` | `e9f9cc38fa1b379ce677b237bceb2d923b939be0` |
| `source-archive-publish-lock-20261029` | `b807afe172ee9504909c308729639161494494d8` |
| `srd-audit-malformed-records-20261030` | `86ace76e32e27162b0683e16cd3febf13f9a04ce` |

## Implementiert

Bereits auf Main technisch vorhandene Sicherheitskorrekturen für ZIP-/APK-
Dateitypen, Quellarchiv-Veröffentlichung, Modulgrenzen, NDK-Wiederherstellung,
Fantasy-Import und SRD-Audit wurden mit ihren ursprünglichen Historien
vereinigt. Deren bereits integrierte Dateien wurden nicht zurückgesetzt.

Neu gegenüber der Ausgangsbasis sind die getrennt entwickelten Korrekturen für:

- reine HTTPS-`PUBLIC_ORIGIN` ohne Pfad, Query oder Fragment;
- begrenztes Einlesen von Projekt-JSON, Gradle-Properties und Gradle-Shebang;
- exklusive Veröffentlichung vollständiger Checkpoints und LATEST-Prüfsummen;
- gegen Symlinks geschützte und atomare Fantasy-Button-Ausgaben;
- Validierung direkt gespeicherter SQLite-Outbox-Aufträge vor Schreibbeginn;
- erneute Main-/Ancestry-Prüfung vor Branchlöschung und Bestätigung des
  tatsächlichen Verschwindens danach.

Es gibt keine Schema-, Versions-, Regel- oder Spielstandmigration. Der
bestehende SQLite-/JSON-Vertrag bleibt erhalten. Der ursprüngliche
`retire_merged_branches.py` ist weiterhin eine feste historische Allowlist,
keine Freigabe zum Löschen beliebiger Branches.

Die Git-Blob-Prüfung umfasst 34 Herkunftsnachweise für 25 unterschiedliche
technische Quell- und Testpfade: Alle sind bytegenau mit den jeweiligen
ursprünglichen Branch-Versionen identisch. Fachlich überlappende bereits
integrierte Korrekturen stimmen ebenfalls exakt überein.

## Tatsächlich lokal getestet

Auf dem kombinierten Fachstand `6cbb34f1` mit Flutter 3.35.7/Dart 3.9.2,
Node 22.14.0 und SQLite-FFI:

- `python3 scripts/verify_project.py`: bestanden.
- `python3 scripts/check_domain_boundaries.py`: bestanden.
- `python3 scripts/srd_coverage.py --json`: bestanden, 1.419 Prüfaufträge,
  neun offene Inventurlücken, kein globaler Fertigstellungsprozentsatz.
- `python3 -m unittest discover -s scripts/tests -v`: **258 bestanden**.
- Backend: `npm ci`, Typecheck und Build bestanden; **73 Tests bestanden**.
- `flutter test test/pending_action_sqlite_validation_test.dart
  test/player_action_outbox_test.dart`: **11 bestanden**, einschließlich
  Neustart, Ablehnung ungültiger direkter Aufträge und unveränderter bereits
  gespeicherter Aufträge.
- `flutter analyze`: ohne Befund.
- `dart format --output=none --set-exit-if-changed lib test`: **537 Dateien**,
  keine Änderungen.

## Noch nicht als Gesamtsystem abgenommen

Vollständige Flutter-Suite, Android-Build/native Tests und aktuelle GitHub-CI
werden erst auf dem übergeordneten kombinierten Integrationsstand bewertet.
Dieses Teilpaket wurde nicht auf einem echten Android-Gerät geprüft. Remote-
Branches wurden durch dieses Teilpaket weder verändert noch gelöscht.

Nächster Schritt: Zusammenführung mit den unabhängig konsolidierten Regel-,
Story- und UI-Paketen, vollständige kombinierte Prüfungen, regulärer Pull
Request und erst nach nachgewiesener Main-Integration archivierte Bereinigung
unveränderter alter Heads. Issue #425 bis dahin offen halten.
