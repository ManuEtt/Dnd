# Migration historischer Entwicklungsbranches – 20.10.2026

## Vorgehen und Schutz der aktuellen App
Die nachfolgend bezeichneten Git-Referenzen werden über einen **Merge-Commit mit unverändertem aktuellem Quellbaum** in den Verlauf von `main` aufgenommen (`ours`-Strategie). Dadurch sind *sämtliche ursprünglichen Commits und Dateien über die jeweiligen historischen Commit-SHAs dauerhaft in Git erreichbar*, während die neueren, bereits konsolidierten Flutter-, D&D-Regel- und Asset-Implementierungen in `main` **nicht** von veralteten Dateien überschrieben werden.

**Wichtig:** Das Zusammenführen der historischen Commits ist **keine** Behauptung, dass jede alte alternative API aktiv eingebaut oder der komplette D&D-Regelumfang umgesetzt ist. Eigenständige alte Dateien/Tests, die mit aktuellen Schnittstellen inkompatibel sind, bleiben im abrufbaren historischen Commit erhalten. Die aktuelle App und ihre Tests sind maßgeblich. Die alten Branches werden erst nach Bestätigung der Git-Ancestry in `main` und nach Erzeugung überprüfter Backup-Tags gelöscht.

## Migrationsmatrix

| Alt-Branch | Festgehaltene HEAD-SHA | Inhalt / Migrationsentscheidung |
|---|---|---|
| `docs/merged-character-branches-20261019` | `f7023926b122a0286b4f02c8829875b50b6ca527` | Historische Dokumentation; neuere Projektangaben in main bleiben maßgeblich. |
| `feat/complete-graphics-ui-20261019` | `a94a3a61749917f312044d9109df225aa79948cd` | Alte Grafik-API, Importskript und Tests in Historie; moderne Grafik-API/Tests in main. |
| `feature/complete-fantasy-artwork-ui-20261019` | `7baea4f91c03d8fbaa1f08c87ae4c359fb1d77a8` | Portrait-Picker, vollständiger Asset-Importer und Tests bereits weiterentwickelt in main; temporärer Formatter wird nicht reaktiviert. |
| `feature/fantasy-portraits-and-ui-20261019` | `3f4c45838c7460352ed57def9d89235de8c51aa8` | Version und Porträts weiterentwickelt; ältere App-Navigation wird nicht zurückgespielt. |
| `feature/fantasy-rune-main-navigation-20261019` | `a1aaf75818dffd09579dd648f4a3f1fba81714bb` | Runen-Navigation über neuere PR #31 in main; alte Implementierung archiviert. |
| `feature/moonlit-scenery-20261019` | `66d530a3c75564e6465973bdf65209f4afe364c2` | Mondscheinlandschaft mit Tests durch neueren PR #32 in main; frühere Shader-Fassung in Historie. |
| `feature/primary-class-level-up-20261019` | `8ee18d04a5ba7ab820eaca72529295a8e81c6586` | Alter konkurrierender Dialog; konsolidierter SRD-Stufenaufstieg plus Mehrklassenregeln in main; alte Tests über Historie abrufbar. |
| `feature/xp-level-progression-20261019` | `a4a4bec1a449259b1edc78536ca006ef3a6ec8dd` | Fachlogik bereits über PR #35 und Sicherheitskorrektur PR #36 in main übernommen. |
| `fix/equipment-import-attributes-20261019` | `ff764e193c98c73547fe8ad5ce9fafe46772ac9b` | Ausrüstungsimport/RK/Bewegung und Tests über PR #13 in main; älterer Stand bleibt historisch. |
| `fix/fantasy-ui-responsive-20261019` | `22de1096d57ba9cb5f530b652d783ae3b41bd4f6` | Nachfolgende mobile UI in PR #29/#31, alte Abweichungen im Merge-Verlauf verfügbar. |
| `integration/legacy-branches-safe-20261020` | `d7fc2941c2da4f69eb86b9666917c5dab678a0e4` | Dokumentation und XP-Sicherheit bereits über PR #36 in main. |

## Belege
- Hauptzweig bei Arbeitsbeginn: `44894a6a9861715d6f8ad97573be4c3fcfd4c414` (bereits XP-Funktion sowie PR #35/#36).
- Jede HEAD-SHA oben muss zum Merge-Zeitpunkt exakt mit dem Remote übereinstimmen.
- Alle SHA-Werte werden als zusätzliche Eltern des historischen Sammel-Merge-Commits eingebunden (oder sind bereits in `main` enthalten).
- Die Ausführung der Bereinigung prüft vor jeder Löschung, dass jeder Alt-HEAD ein Vorfahre von aktuellem `main` ist; Tags `archive/legacy-20261020/<branch>` sichern die alten Spitzen dauerhaft.
- Temporäre Workflow- und Artifaktimporte aus alten Branches werden nicht blind aktiviert. Der aktuelle `scripts/import_complete_fantasy_assets.py` bleibt die maßgebliche Asset-Importvariante.
- Vollständige Flutter-/Android-Verifikation und ein Gerätetest sind gesondert nachzuweisen. Die Historien-Migration ändert selbst keine aktiven App-Dateien.

## Wiederherstellung
Nach der Migration kann jeder alte Branch anhand seines Tags wiederhergestellt werden:

```bash
git fetch --tags origin
git switch -c wiederhergestellt archive/legacy-20261020/feature/moonlit-scenery-20261019
```

Für die alten Tests oder Implementierungen kann alternativ jede oben notierte SHA explizit ausgecheckt oder über GitHub eingesehen werden. Der Quellbaum von `main` ist absichtlich nicht auf das ältere Niveau zurückgesetzt.

## Technischer Main-Nachweis

Der Sammelmerge wurde über [PR #38](https://github.com/ManuEtt/Dnd/pull/38) in `main` aufgenommen (Merge-Commit `23c937af976c94b472585219bf73b386a813350a`). Die Bereinigung überprüft den aktuellen Stand nochmals vor dem Entfernen jeder alten Branch-Referenz. Die tatsächlich entfernten Referenzen und Backup-Tags sind separat anhand des GitHub-Workflows nachzuprüfen.

**Sicherheitskorrektur:** Vor der Löschung wurde eine fehlerhafte SHA-Länge im Bereinigungsmanifest erkannt und korrigiert. Der erste Löschlauf hat sämtliche alten Branches unverändert gelassen. Der erneute Lauf verwendet ausschließlich die nachgeprüften aktuellen Commit-IDs.

## Abschlussstatus – erfolgreich

**Abgeschlossen am 20.10.2026.** Nach der historischen Integration über [PR #38](https://github.com/ManuEtt/Dnd/pull/38) wurden die ursprünglichen zehn Feature-/Fix-/Dokumentationsbranches sowie die zwei temporären Integrationsbranches erfolgreich gelöscht.

- Erfolgreicher GitHub-Actions-Lauf: [39372908266](https://github.com/ManuEtt/Dnd/actions/runs/39372908266), Status **success**.
- Es existiert danach ausschließlich der Arbeitsbranch `main`; dies wurde über die GitHub-Branchliste geprüft.
- Für **alle zwölf** entfernten Branches existiert der gleichnamige unveränderliche Backup-Tag unter `archive/legacy-20261020/<alter-branchname>`. Jeder Tag wurde per GitHub-Commitvergleich erfolgreich verifiziert.
- Alle zwölf alten HEAD-Commits sind Vorfahren von `main`; keiner der alten Entwicklungsstände geht dadurch verloren.
- Der einmalige Bereinigungsworkflow wurde anschließend aus `main` entfernt, um zukünftige versehentliche Löschläufe auszuschließen.
- Die Änderungen des Migrations-PRs betreffen nur Dokumentation und den inzwischen entfernten Workflow. Die laufende App wird nicht auf veraltete UI-/Regelfassungen zurückgesetzt.

**Wichtig zur Terminologie:** Historie und Wiederherstellbarkeit sind vollständig integriert; diese historienbewahrende `ours`-Zusammenführung aktiviert absichtlich keine durch neuere Implementierungen ersetzten Altdateien. Ein erneuter Flutter-/Android-Build kann bei späteren funktionalen Änderungen weiterhin notwendig sein.
