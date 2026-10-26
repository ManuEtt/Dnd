# Chat C – barrierefreier Abenteuerstatus (25.10.2026)

- **Main-Basis:** initial `97a06118f17d71cc77be2cb15a2fc9a53db20ee0`, jetzt `45bea9c2a897275583bdbe32ed50afde5d0a76b0`; Branch `feat/chat-c/accessible-status-hud-20261025`.
- **IMPLEMENTIERT:** Statuskarten reagieren ab 180 % auf schmale Android-Breiten mit Einspalten-Layout; Werte statt per `FittedBox` visuell geschrumpft zu werden als umbrechbarer Text; Screenreader benennt Trefferpunkte, Rüstungsklasse, Bewegung und EP sowie bestätigte HP-/XP-Prozentwerte. Unbekannte Werte bleiben unbekannt.
- **GETESTET:** nach Korrektur der Dart-Formatierung bisher Python-Strukturtests, Architekturgrenzen, SRD-Abdeckung, Backend-Typecheck/-Build/-Tests, Dart-Format und Flutter-Analyse im Actions-Lauf [#40221062928](https://github.com/ManuEtt/Dnd/actions/runs/40221062928) erfolgreich; vollständige Flutter-/Android-Abnahme für diesen finalen Merge-Stand steht noch aus.
- **NICHT GETESTET:** finaler GitHub-Workflow inklusive gesamter Flutter-Suite, Android-Debug-/Alpha-APKs, reales Smartphone, TalkBack auf einem Android-Gerät und produktive Signierung.
- **BLOCKIERT:** keine SDKs für eine lokale Dart-/Flutter-Ausführung verfügbar; automatisierte CI ist für finale technische Abnahme vorgesehen.
- **NOCH NICHT IMPLEMENTIERT:** keine Regel-/Controller-/Story-/Datenmodelländerung; keine JSON-/SQLite-Migration. App-Version `0.8.40+90` aus Main unverändert.
- **Nächster eigenständiger Schritt:** Quest-Board-Beschriftungen bei 320 dp/200 % samt Screenreader prüfen; positives/negatives Widgettestpaar, keine Änderung an Questzuständen.
- [Detaillierter persönlicher Checkpoint](parallel/CHAT_C_HUD_ACCESSIBILITY_20261025.md). Den historischen Verlauf anderer Chats unterhalb erhalten.

---

---

**Nachgewiesene CI-Abnahme (historischer, vollständig bestandener Head):** [Actions #40222374831](https://github.com/ManuEtt/Dnd/actions/runs/40222374831) auf `91d007120e3a1a7b4beea9e91a7e8cffb2d831d8`, `completed/success`. Alle HUD-Regressionen, Flutter-Gesamtsuite, Backend, Python, Architektur/SRD, Android-Build und Artefakterzeugung bestanden. Hauptbranch wurde zwischenzeitlich durch Chat-D-PR #186 auf `af70a48c84d83c133ced4200be04ca81a91abf1b` erhöht; aktuelle gemeinsame CI für den neu synchronisierten Dokumentationsstand ist noch nicht abgenommen. Reales TalkBack und produktive Signierung nicht getestet.

# Chat D D-004 – Gradle-Wrapper-JAR-Sicherheit (25.10.2026)

- **Basis:** `main` `713b8cc2831f9d8039ef4e6ebf37c10682aec675` mit bereits integriertem D-003-PR #183; D-004-Branch `fix/chat-d/gradle-wrapper-jar-safety-20261025`.
- **Implementiert:** `scripts/verify_project.py` rejectiert mehrdeutige doppelte ZIP-Namen, unsichere Pfadvarianten und ZIP-Symlinks vor dem Gradle-Start; vier zusätzliche positive/negative Tests.
- **Status:** Frühere CI auf `c7f2df12a9df474e6204ad1de4011f7c5b6e3e7f` belegt **nicht** den neuen Synchronisations-Commit. Vollständige Actions-Abnahme und Android-Artefakte des neuen Standes sind noch offen.
- **Keine Migration:** SQLite/JSON, App-Version und bestehende Spielmechanik unverändert.
- **Nächster Schritt:** finale CI prüfen, gegen aktuellen `main` konfliktfrei abgleichen, erst danach Zusammenführung freigeben.
- **Checkpoint:** [CHAT_D_CHECKPOINT.md](parallel/CHAT_D_CHECKPOINT.md).

---

# Chat D – PR #183 APK-Archivschutz nach Integration #182

- **Neuer Main-HEAD:** `45bea9c2a897275583bdbe32ed50afde5d0a76b0`. Die beiden Chat-D-PRs #177 und #182 sind inzwischen integriert; dieser Branch übernimmt ihre technischen Dateien und Statusdokumentation unverändert.
- **Implementiert:** `scripts/prepare_alpha_release.py` weist doppelte Archivnamen, Traversal-/absolute Pfade, Rückwärtsschrägstriche, Steuerzeichen und ZIP-Symlinks zurück; vier neue positive/negative Regressionen.
- **GETESTET:** Code/Testdateien über GitHub auf eigenem Branch überprüft. Die ältere PR-183-CI auf `ae0efbe` ist **kein** Abnahmenachweis des neu kombinierten Commits.
- **NICHT GETESTET:** finale Python-/Flutter-/Backend-/Android-CI auf dem neuen PR-183-HEAD; reales Gerät. Keine Datenmigration.
- **NÄCHSTER SCHRITT:** exakte neue PR-/Push-CI abnehmen, aktuelle Parallel-PR-Dateien vergleichen, danach nur bei grüner CI und Konfliktfreiheit integrieren.
- **Vollständiger Status:** [CHAT_D_CHECKPOINT.md](parallel/CHAT_D_CHECKPOINT.md).

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


---

## Chat B – ID- und revisionsgeschützte NPC-Chronik (26.10.2026)

- **Basis:** `main` `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`, Branch `feat/chat-b/npc-revision-context-20261026`; parallele PRs vor Entwicklung geprüft.
- **IMPLEMENTIERT:** `app/lib/story/npc_identity_memory.dart` stellt eine unveränderliche NPC-Projektion nach eindeutiger ID bereit, einschließlich Kampagnen-ID/-Revision, Lebensstatus, Beziehung und bis zu 20 chronologischen Notizen. `requireCurrent` verwirft stale Revisionen, fremde Kampagnen und widersprüchliche gleichrevisionierte Daten.
- **TESTS GESCHRIEBEN:** Sechs Flutter-Regressionen in `app/test/npc_identity_memory_test.dart`: gleichnamige NPCs, Sitzung/JSON, stabile Datumsordnung, stale/missing/doppelte IDs, Legacy-Fälle, reine Lesesicherheit.
- **GETESTET:** GitHub-`main`/offene PRs auf Dateipfad- und Integrationskonflikte geprüft; verbindliche neue CI erst nach Pull Request.
- **NICHT GETESTET:** finaler Flutter-/Android-Workflow und echte Android-Installation; keine produktive KI-Anbindung oder serverseitige ID-Validierung.
- **GRENZE:** `toContextMap` ist eine lokale Vorstufe und kein akzeptierter Request des bestehenden Backends. Das Server-API bleibt stringbasiert und unverändert.
- **NÄCHSTER SCHRITT:** ID-/Revisionskontext erst nach PR-Integration in einem eigenen, serverseitig validierten optionalen Story-API-Feld übertragen.
- **Einzelcheckpoint:** `docs/parallel/CHAT_B_NPC_REVISION_CONTEXT_20261026.md`. README-/zentraler Checkpoint bei Integration mit Chat D abgleichen.
