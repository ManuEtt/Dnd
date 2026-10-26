# Integrationsauflösung PR #187 – NPC-Erinnerung

Ausgangsbasis main: `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`.
Originalbranch-HEAD: `80f103a3ba5ab8a95670375140e87dd1d4b459bc`, historisch als zweiter Elterncommit erhalten.

Die neuen Story-Helfer und beide Testdateien werden aus PR #187 bytegenau übernommen. In `game_controller.dart` wurden ausschließlich der neue Import und die bestehende `memories`-Zusammenstellung angepasst. Die `main`-Versionen von README und `docs/CODEX_CHECKPOINT.md` werden nicht mit älteren Branch-Fassungen ersetzt.

Entscheidung: Zusammenführung von bestätigten NPC-Beziehungsnotizen in den optionalen Erzählerkontext, ohne mechanische Zustandsänderungen. Maximal 12 Erinnerungen, maximal 400 Zeichen; keine Regel- oder Datenbankschema-Migration.

Testlage vor diesem Merge: PR #187 auf dessen ursprünglichem Kopf in GitHub-CI grün. Diese kombinierte Integration ist bis zum eigenen CI-Ergebnis **NICHT GETESTET**. Nach erfolgreichem Review/CI als Integration-PR regulär nach main übernehmen; danach Quellbranch #187 nur nach SHA- und Abstammungsprüfung archivieren und bereinigen.
