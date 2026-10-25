# Chat A – Zauberklassenwerte, 25.10.2026

- **Baseline:** `main=97a06118f17d71cc77be2cb15a2fc9a53db20ee0`; Branch `feat/chat-a/spell-class-stats-20261025` (neues isoliertes Arbeitspaket neben offenem PR #180).
- **IMPLEMENTIERT:** Rein lesender Klassenvergleich für Zauberangriffsbonus und Zauber-SG einschließlich Mehrklassencharaktere in `app/lib/domain/srd_spell_saving_throw_rules.dart`; acht neue Dart-Testgruppen; die Requirements `RULE-SPELLS-SPELL-ATTACK-ROLLS` und `RULE-SPELLS-SPELL-SAVE-DC` bleiben nur `partial`.
- **GETESTET:** Noch kein bestätigter finaler PR-CI-Testlauf für dieses neue Paket; frühere grüne Läufe von PR #180 gelten nicht als Nachweis.
- **NICHT GETESTET:** Neuer Flutter-Testlauf, Dart-Format/Analyse, Backend/Python, APK/Android und Geräteabnahme bis zu einem tatsächlich abgeschlossenen Workflow.
- **BLOCKIERT:** Flutter-/Dart-/Android-SDK lokal nicht verfügbar; gemeinsame README/Checkpoint-Dateien anderer PRs vor Merge konsolidieren.
- **NOCH NICHT IMPLEMENTIERT:** Echte Zuordnung des konkreten Zaubers, Angriffswurf/Ziel/Schaden, Inventareffekte, persistente Ausführung.
- **NÄCHSTER SCHRITT:** Nach Abnahme genau eine bestätigte Zauberangriffsaktion mit klassengeprüftem Modifikator, Ziel und deterministischem W20 in einen eigenen Integrationszyklus überführen.

[Eigener Chat-A-Checkpoint](parallel/CHAT_A_SPELL_STATS_20261025.md) · [fachliche SRD-Dokumentation](SRD_SPELL_CLASS_STATS_20261025.md)

---

# Chat D – rekursive Modulgrenzen (25.10.2026, D-002)

- **Integrationsbasis:** `main` = `97a06118f17d71cc77be2cb15a2fc9a53db20ee0` mit bereits integriertem und geprüftem [PR #177](https://github.com/ManuEtt/Dnd/pull/177). D-002-Branch: `fix/chat-d/nested-boundary-scan-20261025`.
- **IMPLEMENTIERT:** `scripts/check_domain_boundaries.py` durchsucht beide Dart-Domainbereiche rekursiv und normalisiert Importpfade, sodass Unterordner und äquivalente Traversal-Imports die Grenze nicht umgehen. Sechs neue Regressionen.
- **GETESTET:** 6 neue und 6 bisherige Python-Grenztests in einer isolierten Teststruktur erfolgreich. Die neue D-002-PR-CI bezieht sich auf einen anderen Commit und muss nach dieser Main-Synchronisierung vollständig neu abgenommen werden.
- **NICHT GETESTET:** Repositoryweite finale Python-/Flutter-/Android-CI und APK auf dem neuen D-002-Kombinationscommit, Realgerät.
- **BLOCKIERT:** laufende CI; keine lokalen Android-/Flutter-SDKs/kompletter Checkout. Keine Spielstand-/Schemamigration und kein neuer SRD-Fertigstellungsnachweis.
- **NÄCHSTER SCHRITT:** vollständige finale PR-CI auf dem neuen Commit prüfen und danach separat mergefähig freigeben; parallele PRs ohne überschreibende Dokumentationsupdates behandeln.
- **Detaillierter Stand:** [Chat-D-Checkpoint](parallel/CHAT_D_CHECKPOINT.md).

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
