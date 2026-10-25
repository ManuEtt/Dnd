# Chat C – UI-Checkpoint (25.10.2026)

- **IMPLEMENTIERT:** Separater Branch `fix/chat-c/npc-chronicle-fallback-20261025` (Basis `5c1499a9342449050bb946542659b221ac2653da`). Die NPC-Beziehungsnotizen im `CampaignMemoryPanel` werden auch ohne zugehörigen NPC-Stammdatensatz lesbar gerendert, ohne Daten oder Regeln zu verändern; zwei gezielte Widgettests ergänzt.
- **GETESTET:** Live-`main`, PR #176 und dessen geänderte Dateien abgeglichen; eigener GitHub-Diff nach Code-Commit kontrolliert. **Kein Dart-Testlauf behauptet.**
- **NICHT GETESTET:** Flutter-Format, `flutter analyze`, `flutter test`, Android-Build, Python- und Backend-Prüfungen, Realgerät. Flutter-/Dart-SDK hier nicht verfügbar; CI noch ausstehend.
- **BLOCKIERT:** Flutter-SDK in dieser Ausführungsumgebung und potenzielle Dokumentkonflikte mit PR #176 bei `README.md` und `docs/CODEX_CHECKPOINT.md`; Dokumente bei Integration bewusst zusammenführen.
- **NOCH NICHT IMPLEMENTIERT:** Änderung an Importvalidierung, NPC-Stammdatenpflege oder Rule-/Story-Modulen. Version `0.8.39+89`, SQLite 2 / JSON 1 unverändert.
- **Genau ein nächster Schritt:** Unabhängigen `FantasyAdventureStatusHud` mit 320 dp / 200 % Schriftgröße und Screenreader-Semantik regressionsprüfen; alle vier Statuswerte erreichbar und kein Overflow.
- Detailnachweise: [docs/parallel/CHAT_C_CHECKPOINT.md](parallel/CHAT_C_CHECKPOINT.md).

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
