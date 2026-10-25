# Chat C – UI-Checkpoint (25.10.2026)

**Aktuelle CI-Abnahme nach Main-Nachzug:** [Android-Alpha #40218237100](https://github.com/ManuEtt/Dnd/actions/runs/40218237100) war `completed/success` auf Feature-Head `0500ce52ce88eda8a1e7d1259293ce5530327d22` (von GitHub geprüfter PR-Stand). Python-Struktur-/Pakettests, Backend-Typecheck/-Build/-Tests, Flutter/Dart-Formatierung, Analyse, gezielte Dialogtests, vollständige Flutter-Testsuite, Android-Debug-Build, native Dateisicherungstests und die Alpha-/Quellartefakterstellung waren erfolgreich. [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12608841640), [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12609515426) und [Quellpaket](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12609101293) veröffentlicht. Reales Android-Gerät, produktive Signierung, unabhängige manuelle Bedienprüfung weiterhin **nicht getestet**. PR #178 bleibt offen, keine Main-Integration. `main` wurde während der Arbeit über PR #176 auf `fb788a980b8ee9eb60439c249f3e1f5092a9f188` gebracht, nun Produktversion **0.8.40+90** (übernommen; keine Erhöhung durch Chat C). Der untenstehende ältere Tests-ausstehend-Eintrag ist ein historischer Zwischenstand; nicht als aktuelles CI-Ergebnis verwenden.

- **IMPLEMENTIERT:** Separater Branch `fix/chat-c/npc-chronicle-fallback-20261025` (Basis `5c1499a9342449050bb946542659b221ac2653da`). Die NPC-Beziehungsnotizen im `CampaignMemoryPanel` werden auch ohne zugehörigen NPC-Stammdatensatz lesbar gerendert, ohne Daten oder Regeln zu verändern; zwei gezielte Widgettests ergänzt.
- **GETESTET:** Live-`main`, PR #176 und dessen geänderte Dateien abgeglichen; eigener GitHub-Diff nach Code-Commit kontrolliert. **Kein Dart-Testlauf behauptet.**
- **NICHT GETESTET:** Flutter-Format, `flutter analyze`, `flutter test`, Android-Build, Python- und Backend-Prüfungen, Realgerät. Flutter-/Dart-SDK hier nicht verfügbar; CI noch ausstehend.
- **BLOCKIERT:** Flutter-SDK in dieser Ausführungsumgebung und potenzielle Dokumentkonflikte mit PR #176 bei `README.md` und `docs/CODEX_CHECKPOINT.md`; Dokumente bei Integration bewusst zusammenführen.
- **NOCH NICHT IMPLEMENTIERT:** Änderung an Importvalidierung, NPC-Stammdatenpflege oder Rule-/Story-Modulen. Version `0.8.39+89`, SQLite 2 / JSON 1 unverändert.
- **Genau ein nächster Schritt:** Unabhängigen `FantasyAdventureStatusHud` mit 320 dp / 200 % Schriftgröße und Screenreader-Semantik regressionsprüfen; alle vier Statuswerte erreichbar und kein Overflow.
- Detailnachweise: [docs/parallel/CHAT_C_CHECKPOINT.md](parallel/CHAT_C_CHECKPOINT.md).

---

# Chat D – Qualität und Integration, 25.10.2026 (PR #177)

- **Main-Abgleich:** neuer Main-HEAD `fb788a980b8ee9eb60439c249f3e1f5092a9f188` nach Merge von PR #176; ursprüngliche PR-D-Basis `5c1499a9342449050bb946542659b221ac2653da`.
- **IMPLEMENTIERT:** zwei verpflichtende Prüfungen im Android-Actions-Workflow und im lokalen `scripts/check.sh`: `scripts/check_domain_boundaries.py` sowie `scripts/srd_coverage.py --json`; dazu vier Konfigurations-Regressionstests einschließlich negativer Fälle.
- **GEPRÜFT:** die zwei neuen Gates, reguläre Python-Tests, Backend-Tests, Flutter-Analyse und Flutter-Tests sind in [Actions #40217436454](https://github.com/ManuEtt/Dnd/actions/runs/40217436454) auf dem vorherigen Commit `1fdd3c0` erfolgreich durchgelaufen. Das ist noch kein CI-Nachweis des hier neu synchronisierten Commit-Stands.
- **NICHT GETESTET:** abschließende CI/Android-Builds für den neuen kombinierten Stand, reale Geräteinstallation und Upgrade älterer Spielstände. Keine vollständige SRD-Abdeckung behauptet.
- **BLOCKIERT:** endgültige GitHub-Actions-Abnahme; Flutter-/Android-SDK lokal hier nicht verfügbar. Nicht freigegebene PRs #178 (Chat C), #179 (Chat B), #180 (Chat A) dürfen nicht ungeprüft zusammengeführt werden.
- **PERSISTENZ:** keine Änderungen an SQLite- oder JSON-Schema, keine Migration und keine Spielstandsänderung durch dieses CI-Arbeitspaket.
- **PR:** [#177](https://github.com/ManuEtt/Dnd/pull/177) auf `fix/chat-d/ci-rule-quality-gates-20261025`. Persönliche Details: [CHAT_D_CHECKPOINT.md](parallel/CHAT_D_CHECKPOINT.md).
- **NÄCHSTER SCHRITT:** CI des **finalen** PR-D-Commits vollständig abnehmen, danach Integration erst mit konfliktfreier Dokumentation und ohne stilles Zusammenführen der fremden PRs.

---

# CODEX-CHECKPOINT – gespeicherte Gelegenheitsreaktion

Stand **2026-10-25T17:17:46+00:00**, aktives Paket auf `feature/opportunity-reaction-offer-20261025`, Arbeitskopie `/workspace/Dnd-opportunity-20261025`.

## Git und tatsächliche Basis

Main `407c2e1ef8ee310b30d1543a263fb66b3331a26e`, [Main-CI #40203583841](https://github.com/ManuEtt/Dnd/actions/runs/40203583841) `completed/success`. Vor Beginn nur Main und keine offenen PRs; alte Remotebranches bereits entfernt. Vorherige gegenteilige Connector-Statusangaben sind historisch. Aktuelle Umsetzung noch nicht nach Main übernommen. Version **0.8.40+90**, SQLite **2**, Kampagnen-JSON **1**, neues optionales Pending-Feld ohne Tabellenmigration.

## IMPLEMENTIERT

Bestätigte gegnerische Bewegung im aktiven Gegnersegment erzeugt ein eindeutiges, an Kampf/Runde/Waffe/Revision und Bewegungsfakten gebundenes Angebot. Ereignis und Snapshot über bestehenden Controller/SQLite-Commit atomar; Neustart und Replay erhalten den Unterbrechungspunkt. Abenteuerdialog ohne vorausgefüllte Fakten, persistentes Panel, ausdrücklicher Verzicht. Keine Reaktion, Würfel, TP, Ressourcen oder Rundenfortschritte beim Angebot/Verzicht. Andere Mutationen werden vor Würfel-/Providerzugriff durch den Controller gesperrt; Lesen, Kampagnenwechsel und bewusste Datenlöschung bleiben möglich. Story darf das neue Regelfeld nicht verändern.

## GETESTET

Gezielte Domain-/SQLite-Tests und zwölf neue Widgettests bisher erfolgreich. Neue zusätzliche Regression für Schreibfehler bei Angebotserzeugung im nächsten Lauf mitprüfen. Importgrenze und erste Flutter-Analyse ohne Befund. Neue komplette Suite, Android-Builds und finale eigene CI noch ausstehend; grüne Basis-CI nicht dafür verwenden.

## NICHT GETESTET

Kompletter finaler Paketstand bis Abschluss der laufenden Abnahme; echtes Android-Gerät, reales Altspielstand-Upgrade und produktive Signierung. Keine automatische Bewegungserkennung, keine vollständige Gelegenheitsattacke.

## BLOCKIERT

Kein echtes Android-Gerät/Produktivschlüssel. Lokale Flutter-/Dart-/Node-/Java-/Android-SDKs sind vorhanden und funktionsfähig; ältere anderslautende Aussagen wurden nicht übernommen.

## NOCH NICHT IMPLEMENTIERT / NÄCHSTER SCHRITT

Nach Abnahme dieses Pakets: eigener Reaktionsangriff auf dem gespeicherten Angebot, mit einmaligem Reaktionsverbrauch, korrektem tatsächlichem Zug/Sneak Attack, Waffen-/Unarmed-Schaden und Krit/Miss; keine Extra-Attack-/Light-/Gegnerzug-Nebenwirkungen. Alte/abgelehnte/überholte Angebote sowie Schildkonkurrenz und SQLite-Rollback prüfen. SRD-Status bleibt `partial`.

## Sicherung und Wiederaufnahme

Geprüfte Main-Basis zusätzlich als ZIP/Patch unter `/workspace/artifacts/main-407c2e1-20261025/` gesichert. Neuer Quellcheckpoint nach diesem Update unter `/workspace/artifacts/0.8.40+90/`; Dateimanifest und tatsächlich gegen `407c2e1ef8ee310b30d1543a263fb66b3331a26e` angewandter Patch. Vor endgültigem Abschluss neue Ergebnisse und PR/Commit eintragen. Historische lokale Worktrees/Item-Entwürfe erhalten. Keine automatische Fortsetzung außerhalb aktiver Sitzung.
