# Chat C – UI-Checkpoint (25.10.2026)

- **IMPLEMENTIERT:** Separater Branch `fix/chat-c/npc-chronicle-fallback-20261025` (Basis `5c1499a9342449050bb946542659b221ac2653da`). Die NPC-Beziehungsnotizen im `CampaignMemoryPanel` werden auch ohne zugehörigen NPC-Stammdatensatz lesbar gerendert, ohne Daten oder Regeln zu verändern; zwei gezielte Widgettests ergänzt.
- **GETESTET:** Live-`main`, PR #176 und dessen geänderte Dateien abgeglichen; eigener GitHub-Diff nach Code-Commit kontrolliert. **Kein Dart-Testlauf behauptet.**
- **NICHT GETESTET:** Flutter-Format, `flutter analyze`, `flutter test`, Android-Build, Python- und Backend-Prüfungen, Realgerät. Flutter-/Dart-SDK hier nicht verfügbar; CI noch ausstehend.
- **BLOCKIERT:** Flutter-SDK in dieser Ausführungsumgebung und potenzielle Dokumentkonflikte mit PR #176 bei `README.md` und `docs/CODEX_CHECKPOINT.md`; Dokumente bei Integration bewusst zusammenführen.
- **NOCH NICHT IMPLEMENTIERT:** Änderung an Importvalidierung, NPC-Stammdatenpflege oder Rule-/Story-Modulen. Version `0.8.39+89`, SQLite 2 / JSON 1 unverändert.
- **Genau ein nächster Schritt:** Unabhängigen `FantasyAdventureStatusHud` mit 320 dp / 200 % Schriftgröße und Screenreader-Semantik regressionsprüfen; alle vier Statuswerte erreichbar und kein Overflow.
- Detailnachweise: [docs/parallel/CHAT_C_CHECKPOINT.md](parallel/CHAT_C_CHECKPOINT.md).

---

# CODEX-CHECKPOINT – Angebots-Revalidierung für Gelegenheitsangriffe

**Stand:** 2026-10-25T18:11:00+01:00; **Produkt:** Würfelraunen – Der lebendige Spielleiter, `app/pubspec.yaml` **0.8.39+89**.

- **Git/Basis:** zuletzt direkt überprüfter `main`-HEAD `407c2e1ef8ee310b30d1543a263fb66b3331a26e` (PR #174 gemergt); beim Beginn keine offenen PRs. Arbeitsbranch: `fix/opportunity-offer-revalidation-20261025`. Code-Commit `af99da8571aa38a1648b58662ebb8cbe3a7745ea`, Test-Commit `18b3fcbd39ad756a77988f77e01cedd82b0a2c96`, Formatkorrektur-Commit `b14c3de64726feb28e0d243c163b7057635d4bd2`; offener [PR #175](https://github.com/ManuEtt/Dnd/pull/175). Endgültigen Dokumentations-HEAD und CI separat prüfen.
- **Letzte nachgewiesene erfolgreiche Main-CI vor diesem Paket:** [Android-Alpha #40203583841](https://github.com/ManuEtt/Dnd/actions/runs/40203583841), `completed/success` für `407c2e1ef8ee310b30d1543a263fb66b3331a26e`. Dies ist **kein** Nachweis für den neuen Branch.
- **IMPLEMENTIERT:** `SrdOpportunityAttackRules.revalidate` vergleicht das ausgegebene Angebot mit der bestätigten Bewegung (Encounter, Revision, Angriffstyp, Waffen-ID und Distanz-/Reichweitenwerte) und wiederholt danach sämtliche bestehenden Regelprüfungen. Das Angebot selbst enthält hierfür drei unveränderliche Bewegungsangaben. Keine Spielstandmutation.
- **GETESTET:** Vor dem Formatprüfungsschritt sind auf einem früheren Branch-Commit Python-Strukturtests und Backend-Prüfungen in GitHub Actions erfolgreich durchgelaufen (CI-Logs [#40215191126](https://github.com/ManuEtt/Dnd/actions/runs/40215191126)); keine erfolgreich abgeschlossene neue Flutter-/Dart-/Android-Testsuite belegt. Der vorherige Main-Workflow war grün, ist jedoch kein Testresultat dieses Branches.
- **NICHT GETESTET:** Die erste GitHub-CI [#40215191126](https://github.com/ManuEtt/Dnd/actions/runs/40215191126) scheiterte an der Dart-Formatierung des ergänzten Tests; Formatkorrektur `b14c3de` wurde anschließend gepusht. Die [neue PR-CI #40215558767](https://github.com/ManuEtt/Dnd/actions/runs/40215558767) läuft bzw. benötigt Ergebniskontrolle. Drei ergänzte Dart-Testfälle in `app/test/srd_opportunity_attack_rules_test.dart`; vollständige Format-/Analyze-/Flutter-/Backend-/Android-PR-CI; echte Android-Geräteinstallation und Upgrade historischer Spielstände.
- **BLOCKIERT:** In dieser Ausführungsumgebung fehlen Flutter-/Dart- und Android-SDKs; GitHub Actions ist die vorgesehene neue Codeabnahme. Keine produktive Signierung/Realgerät vorhanden.
- **NOCH NICHT IMPLEMENTIERT:** dauerhafter Bewegungsauslöser, wartende Spielerentscheidung, transaktionale Reaktionsverbrauchs-/Idempotenzgarantie, Angriffswurf/Schaden und Android-UI. `RULE-COMBAT-OPPORTUNITY-ATTACKS` bleibt **partial**, SRD 5.2.1 *Opportunity Attacks* S. 15, CC BY 4.0.
- **Änderungen:** `app/lib/domain/srd_opportunity_attack_rules.dart`, `app/test/srd_opportunity_attack_rules_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/SRD_OPPORTUNITY_ATTACK_PREFLIGHT_20261025.md`, `DEVELOPMENT_STATUS.md`, `CHANGELOG.md`. Keine Schema- oder JSON-Migration (SQLite 2/JSON 1), keine Anpassung an KI/Story, bestehender Regelfassaden-Export bleibt erhalten. Keine geheimen Daten oder Assets ergänzt; Lizenzhinweise bleiben unverändert.
- **Artefakte:** kein branchbezogenes ZIP und keine branchbezogene APK erzeugt; keine neuen Downloads oder Digests behauptet.
- **Genau ein nächster Schritt:** bestätigte Gegnerbewegung als gespeicherten, eindeutigen Unterbrechungspunkt mit Controller-Transaktion und ausdrücklicher Spielerwahl einführen; DoD: persistierter Übergang, Ablehnung und Wiederaufnahme, Stale Revision, doppelte ID, Reaktionskonflikt mit Schild und Alt-JSON regressionsgetestet. Befehle: `python3 scripts/verify_project.py`, `python3 scripts/check_domain_boundaries.py`, `python3 -m unittest discover -s scripts/tests -v`, `cd app && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build apk --debug`.
- **Änderungsprotokoll:** 2026-10-25T18:11:00+01:00 – die bisher fehlende Angebots-Revalidierung für spätere bestätigte Aktionen als eigenständige, speicherneutrale Regelvorprüfung ergänzt. PR- und Teststand nach Rückmeldung der CI aktualisieren.

---

# CODEX-CHECKPOINT – Regelvorprüfung für Gelegenheitsangriffe

Stand **25.10.2026**. Ein begrenztes neues SRD-Inkrement nach erfolgreichem Main-Merge. Der Stand der vorherigen Integration bleibt nach dem Trenner erhalten.

## Git und Referenzen

- Letzter beobachteter `main`-HEAD vor diesem Paket: `5175a4b39b1dd8968b91dd963b664690956885bd` (Dokumentations-Merge #173 nach vollständig grüner Code-Main-CI [#40193476536](https://github.com/ManuEtt/Dnd/actions/runs/40193476536) auf dessen Vorgänger `635773db`). Keine offenen PRs beim Start.
- Neuer Entwicklungsbranch `feat/srd-opportunity-preflight-20261025`; [PR #174](https://github.com/ManuEtt/Dnd/pull/174) auf `main`. Die finalen Checks beziehen sich auf den **letzten Commit** im PR, nicht auf frühere grüne Runs.
- App-Version `0.8.39+89`, SQLite-Schema 2, Kampagnen-JSON 1 unverändert; keine Datenmigration oder Umgehung der Story/Rules-Grenze.

## IMPLEMENTIERT

- Reiner Domänen-Preflight `SrdOpportunityAttackRules.prepare`: nur bei bestätigter Gegnerbewegung aus Sicht- und Reichweitenkontakt nach draußen, eigener Reaktionsfreigabe, eigenem handlungsfähigen Helden, freier Reaktion und passender Encounter-ID. Die drei SRD-Ausnahmen Disengage, Teleport und Fremdbewegung sind explizit ausgeschieden.
- Waffe: nur eindeutiger vorhandener ausgerüsteter Nahkampf-Katalogeintrag oder `Unarmed Strike`, ohne unbestätigten Waffen-/Monsterwert. Rückgabe: unveränderliche Angebotsdaten mit Encounter-ID, Revision und Angriffstyp; **kein** Schadens-/Wurf-/Ressourcen- oder JSON-Update.
- Öffentliche Regel-Fassade, maschinenlesbare Anforderung `RULE-COMBAT-OPPORTUNITY-ATTACKS` (**partial**) und Fachbeschreibung aktualisiert. Offizielle SRD 5.2.1, *Playing the Game*, Seite 15; Wizards of the Coast LLC unter CC BY 4.0. [Details](SRD_OPPORTUNITY_ATTACK_PREFLIGHT_20261025.md).

## GETESTET

- Vorherige Main-Codebasis: unabhängige [CI #40193476536](https://github.com/ManuEtt/Dnd/actions/runs/40193476536) `completed/success` auf `635773db`; **kein** Nachweis für neuen PR #174.
- Neue Positiv-/Negativregressionen in `app/test/srd_opportunity_attack_rules_test.dart` erfasst; bis tatsächlichem erfolgreichen Workflow auf dem neuen finalen Head **noch nicht als bestanden gewertet**.

## NICHT GETESTET / BLOCKIERT

- Eigener finaler CI-Lauf mit Python, Format, Flutter-Analyse/Tests, Backend, Android-Debug/Alpha und nativen Gradle-Tests; echtes Android-Gerät/Upgrade und produktive Signierung.
- In der verfügbaren Umgebung kein lokales Dart-/Flutter-/Android-SDK; GitHub Actions übernehmen Build- und Formatprüfung.
- Alte Remote-Branches konnten mangels SHA-gebundener GitHub-Ref-Löschfunktion nicht entfernt werden; Archivtags bleiben erhalten.

## NOCH NICHT IMPLEMENTIERT

- Echte Positions-/Bewegungsverfolgung und Unterbrechung des Gegnerzugs, gespeicherte Reaktionsentscheidung, atomarer Controller-/SQLite-Ressourcenverbrauch, Treffer/Schaden, Miss/Krit, automatische Reaktion auf Fremd-/Schildereignisse sowie Android-Dialog. Kein Gelegenheitsangriff vollständig spielbar.

## Ein einziger nächster Schritt

**Ausdrücklich bestätigte Gegnerbewegung mit persistiertem, eindeutigen Reaktions-Angebot unterbrechen**, inklusive Kampf-ID, Ziel, Reichweite, Sicht, Bewegungsart und Revision. Testen: doppelte/stale Bestätigung, Rückzug/Teleport/Fremdbewegung, parallele Schildreaktion, Spielstand-JSON/SQLite-Neustart und Ablehnung ohne HP-/Ressourcenänderung. Erst danach Treffer-/Schadensmechanik eigenständig ergänzen.

---

# CODEX-CHECKPOINT – Live-Nachtrag nach Branch-Merge (25.10.2026)

**Geprüfter Stand:** `main=635773db33724f543d61bacde9a9ebe679b9b1e9` nach regulärem GitHub-Merge [PR #171](https://github.com/ManuEtt/Dnd/pull/171), Integrations-HEAD `255a5a0bdf8dc4915bfd70e808a69862f3d0708a`. App **0.8.39+89**, SQLite 2, Kampagnen-JSON 1 unverändert. Nur ein separater Dokumentationsbranch wird bearbeitet, `main` nicht erneut direkt verändert.

- **IMPLEMENTIERT:** Alle im untenstehenden Migrationscheckpoint beschriebenen Feature- und Sicherheitsänderungen auf `main` integriert, ohne Squash, historische Branch-SHAs behalten.
- **GETESTET:** [PR-CI #40192473811](https://github.com/ManuEtt/Dnd/actions/runs/40192473811) für exakt `255a5a0`: `completed/success` mit Python, Backend, Flutter, Android-/APK- und Artefaktschritten. Unabhängig 19/19 verzeichnete Archive-Tag-Refs und GitHub-Ancestry gegen Integrations-HEAD positiv geprüft; sechs nach dem Merge als enthalten erkannte gestapelte PRs mit Heads, die Vorfahren von `main` sind.
- **GETESTET (Main):** Auch die eigenständige [Main-CI #40193476536](https://github.com/ManuEtt/Dnd/actions/runs/40193476536) auf exakt `635773db33724f543d61bacde9a9ebe679b9b1e9` ist `completed/success`, einschließlich Python/Backend/Flutter, Debug-APK, nativen Tests, ARM-/Alpha-Paket und Quell-ZIP-Artefakten.
- **NICHT GETESTET:** Reales Android-Gerät, Upgrade mit historischen Gerätespielständen, produktive Signierung und lokales Bundle erneut in dieser Umgebung. Kein zusätzlicher ZIP-/APK-Digest vorgetäuscht.
- **BLOCKIERT:** Physische Geräteabnahme und GitHub-Branch-Löschung über die aktuell verfügbare Connector-Schnittstelle (kein sicherer `delete_ref`-Endpunkt). Lokale Git-Bundle-Prüfung aus dokumentiertem Fremd-Arbeitsverzeichnis wurde hier nicht unabhängig wiederholt. Archivtags bleiben bestehen.
- **NOCH NICHT IMPLEMENTIERT:** Die abschließende Remote-Branchlöschung erfordert einen SHA-gebundenen Ref-Löschzugriff; die aktuell verfügbare GitHub-Connector-Schnittstelle bietet diesen nicht. Vollständige SRD-Automatik und produktive Gerätefreigabe bleiben offen.
- **PR-Bereinigung:** Nach grüner Main-CI und Prüfung ihrer Head-SHAs wurden #165, #166, #167, #168, #169 und #172 ohne Doppel-Merge geschlossen. Nur Dokumentations-PR #173 ist noch offen.
- **Nächster konkreter Schritt:** Die verbleibenden, bereits nach Main migrierten Remote-Branches erst über einen passenden GitHub-Ref-Löschzugriff oder geprüfte lokale Git-CLI mit erwarteter SHA-Lease löschen. Vor jedem Löschen Branch-SHA, zugehörigen unveränderten Archivtag und Main-Abstammung erneut prüfen; `main` und unbekannte/weiterentwickelte Heads erhalten. Danach Löschprotokoll und README aktualisieren. Bis dahin keine Branchlöschung als erledigt melden.

---

# CODEX-CHECKPOINT – Branch-Migration

Stand **2026-10-25T12:16:00+00:00**. Nutzerauftrag: alle GitHub-Branches migrieren, Fehler beheben und alte Branches löschen. Die ausdrückliche Freigabe umfasst geprüfte Main-Integration und anschließende sichere Bereinigung.

## Git und Herkunft

- Arbeitskopie `/workspace/Dnd-migration-20261025`, Branch `integration/all-branches-20261025`, [PR #171](https://github.com/ManuEtt/Dnd/pull/171).
- Ausgangs-Main `b60ffe7ff1aae502ea927cb77153b988be33e397`; Funktions-/Integrationscommit `cd724629c79a169ff1a078517031a33cf73ae130`. Version **0.8.39+89**, SQLite **2**, Kampagnen-JSON **1** unverändert.
- 19 erfasste Remote-Köpfe vor Integration gesichert, remote tags SHA-genau geprüft; alle Köpfe echte Vorfahren. Ursprünglich 13, später vier Sourcebranches plus eigener Integrationscheckpoint und Atomic-Archivbranch hinzugekommen.
- Sicherung: `Wuerfelraunen_Branches_vor_Migration_20261025_19_final_mit_Dokumentation.bundle`, SHA256 `344e499cd8b21f04148903002428fe81ba58b83bf8aa67832f4a02a71476c973`. Unter `/workspace/artifacts/branch-migration-20261025/`; dort auch ältere unveränderte Bundles und Manifeste. Archivtags unter `archive/branch-migration-20261025T075644Z`. Atomic-Zwischenkopf und finaler geprüfter Atomic-Kopf separat erhalten.
- Reguläre Funktions-Merges, zehn nach konkreter Inhaltsprüfung unveränderte Historien-Merges; 42 bytegenau archivierte Dokumente. [JSON-Herkunft](branch_migration_20261025.json), [Audit](BRANCH_MIGRATION_AUDIT_20261025.md).

## IMPLEMENTIERT

Sending-W100-Validierung, Verbündetenbestätigung bei zulässigen Nebenhandangriffen, allgemeine Light-Nahkampfbonusangriffe, Schutz abgeschlossener Storyfäden, lokale und serverseitige ID-Kollisionssperren, Plot-Geheimnisschutz, Backend-Limiter und sichere Projektarchive sind vereinigt. Der bei der Integration gefundene Casefold-Fehler für generierte/Systemdateien ist mit Regressionstest behoben. Fehler beim ZIP-Schreiben oder Veröffentlichen der Prüfsumme bewahren das zuvor vorhandene Archiv; keine Zusage einer absturzübergreifend atomaren Dateipaar-Transaktion.

## GETESTET

**1.552 Flutter-, 106 Python-, 40 Backend- und 12 native Android-Tests bestanden.** Dart-Formatierung: 360 Dateien unverändert; Flutter-Analyse sowie Backend-Typecheck und -Build erfolgreich. Debug-APK und ARM64-Alpha gebaut; Version, ZIP-CRC, ABI und lokale Debug-Signatur geprüft.

Vollständiger Lauf `/workspace/validation/20261025-migration-final-full-check.log`: Flutter 1.552 / Python 102 / Backend 40 auf Quelle `6aef90d`. Danach nur Archivskript/-tests geändert; `/workspace/validation/20261025-migration-atomic-python-tests.log`: **106/106**. App, Backend und Workflow weiterhin bytegleich; kein Wiederholungslauf dieser unveränderten Quellen nötig. APK-Bau aus geprüftem Projekt-ZIP `6aef90d`; 424 App-Eingabedateien für ARM64 gegen ZIP, Arbeitskopie und Buildkopie geprüft. Alle 19 gesicherten Köpfe auf Ancestry geprüft. Casefold-Regression vor Fix fehlgeschlagen, danach grün. [Prüfnachweise](branch_migration_validation_20261025.json).

## NICHT GETESTET

Finale gemeinsame PR-CI und anschließende Main-CI bis tatsächlichem Abschluss separat ausstehend. Alte Einzel-CIs ersetzen diese Prüfung nicht. Kein reales Android-Gerät, kein reales Geräte-Upgrade mit historischem Spielstand, keine produktive Signierung. SRD-Gesamtumfang nicht fertig.

## BLOCKIERT

Geräteabnahme und produktive Signierung mangels Gerät/Schlüssel. GitHub-Schreibrechte, SDKs und lokale Tests funktionieren; keine weiteren technischen Blocker beobachtet.

## NOCH NICHT IMPLEMENTIERT / NÄCHSTER SCHRITT

**Zuerst Migration abschließen:** aktuellen finalen PR-Head pushen/CI abnehmen, normaler Merge mit erwartetem Head (kein Squash), tatsächliche Main-CI prüfen. Danach offene Vorgänger-PRs nur bei in Main enthaltenem Kopf schließen. Remote-SHAs erneut mit Backup vergleichen, Tags und Main-Abstammung prüfen, bedingte atomare Branchlöschung; Main erhalten. Neue oder verschobene Branches erneut sichern/integrieren. Ergebnisse in README, Checkpoint und Löschbericht nachführen.

Nach vollständigem Abschluss eigenes SRD-Paket allgemeine Gelegenheitsangriffe; konkrete Gegenfälle und Akzeptanzkriterien in README. Weitere Zauber-/Klassen-/Monsterwirkungen, Inventur, Item-Overrides und reale Android-Abnahme bleiben offen.

## Artefakte und Wiederaufnahme

`/workspace/artifacts/branch-migration-20261025/`: versionierte Vollprojekt-ZIPs, tatsächlich gegen Basis-Main angewandte Git-Patches, SHA256/Dateimanifeste, Git-Bundles und geprüfte Debug-/ARM64-APKs. Beide lokalen APKs verwenden den lokalen Android-Debugschlüssel, keine Gerätezulassung. Aktuelle Dateinamen nach jeder Paketierung im Artefaktindex nachführen.

Zuerst Git-Status/HEAD, Main, offene PRs und laufende Workflows neu prüfen. Manifest `/workspace/validation/20261025-branch-backup-manifest.json`; Löschwerkzeug `/workspace/validation/cleanup_migrated_branches.py` prüft grüne exakte Main-CI, Inventar, SHA, Archivtag und Ancestry vor SHA-gebundener Löschung. **Noch keine Main-Veröffentlichung oder Branchlöschung erfolgt.** Historische lokale Worktrees und unveröffentlichte Entwürfe nicht entfernen. Keine automatische Fortsetzung außerhalb einer aktiven Sitzung.

Nachtrag: späterer Atomic-Dokumentationskopf `1eb8046` ebenfalls remote gesichert, alle vier einzigartigen Statusdateien bytegenau archiviert und mit unverändertem Inhaltsbaum als Vorfahr aufgenommen. Nun zehn geprüfte Historien-Merges und 42 Archivdateien. App/Backend/Skripte bleiben gegenüber geprüftem Funktionscommit `cd72462` unverändert.
