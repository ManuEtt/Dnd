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


---

## Paralleles Chat-B-Paket – bestätigter NPC-Verlauf (25.10.2026)

- **Basis:** Main-`fb788a980b8ee9eb60439c249f3e1f5092a9f188`; Branch `feat/chat-b/npc-continuity-20261025`. PR #179 aus dem vorherigen Chat-B-Zyklus ist offen, dessen vollständige GitHub-CI #40217711273 auf `7778df9081e7c053599a9e7a05cd1235943f7056` erfolgreich.
- **IMPLEMENTIERT:** Neuer `app/lib/story/npc_continuity_reader.dart` und Export über `app/lib/story/story_api.dart`: bestätigte NPC-ID, Status, aktuelle Beziehung und begrenzte, stabil sortierte persistierte Notizen als unveränderliche Projektion. Keine Regeln, keine Narrative als Tatsachen, keine JSON-/SQLite-Migration.
- **TESTS HINZUGEFÜGT:** Sechs positive und negative Fälle in `app/test/npc_continuity_reader_test.dart` einschließlich altem JSON und erneut geladenem Spielstand.
- **GETESTET:** GitHub-Livebasis und Dateipfade der offenen PRs #177–#180 verglichen; lokales `flutter`/`dart` nicht installiert. Dies ist noch kein erfolgreicher fachlicher Test des neuen Pakets.
- **NICHT GETESTET:** finale PR-CI, Flutter-/APK-Build am endgültigen Branchstand und Android-Gerät.
- **BLOCKIERT:** SDK fehlt lokal; gemeinsame README-/Checkpoint-Historie vor Merge koordinieren.
- **NOCH NICHT IMPLEMENTIERT:** Automatische Einbindung der NPC-Projektion in KI-Prompt/Storyvorschläge, semantische Konflikterkennung, providerübergreifende E2E-Abnahme.
- **NÄCHSTER SCHRITT:** kontrollierte Verwendung der Projektion als optionaler NPC-Kontext mit Provider-Mocks und Negativtests.
- **Individueller Beleg:** `docs/parallel/CHAT_B_NPC_CONTINUITY_20261025.md`. Die bestehende `docs/parallel/CHAT_B_CHECKPOINT.md` gehört noch zu offenem PR #179 und wird zur Konfliktvermeidung in diesem PR nicht ersetzt.
