## Zyklus 24.10.2026 – Bestätigte, transaktionale EP-Gutschrift über Controller/Regelengine

- **CI-/Merge-Reconciliation 24.10.2026:** PR #145 wurde mit Main-Commit `1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd` integriert. PR #148 wurde trotz roter [CI #40058169046](https://github.com/ManuEtt/Dnd/actions/runs/40058169046) in den inzwischen geschlossenen (nicht nach Main integrierten) PR-#146-Branch gemergt: Merge-Commit `ca9167cfec691c11710ea40cc364f245ae00202a`. Der Original-Feature-Branch von #148 wurde gelöscht. **Neuer gesicherter Recovery-Branch:** `fix/confirmed-xp-ci-recovery-20261024` startet exakt von diesem Merge-Commit, erhält alle Änderungen und korrigiert ausschließlich einen falschen Testparameter: Beim zweiten Reward-Request zur selben Reward-ID muss für die erwartete Duplicate-Fehlermeldung die aktuell bestätigte Revision statt der veralteten Revision 0 übergeben werden. Eine separate Stale-Revision-Regression bleibt vorhanden. Im roten Lauf bestanden 1.439 Tests, genau 1 Testfall scheiterte wegen der falschen Testvorbedingung; Flutter-Analyse, Python, Backend und der Race-Test waren grün. Android-Builds wegen Testfehler nicht ausgeführt. **Neue Recovery-CI ausstehend.** Keine unbestätigte Merge-Freigabe nach main.


- **Zusätzliche Race-Regression:** Zwei gleichzeitig arbeitende Controller: Der erste wird vor seinem SQLite-Commit angehalten, der zweite bestätigt dieselbe Request-ID, danach quittiert der erste den bereits gespeicherten Beleg ohne doppelten XP- oder Ereigniseintrag. `app/test/confirmed_xp_reward_storage_test.dart` ergänzt; erneute CI für den finalen Commit erforderlich.

- **LIVE-BASIS:** `main` `5958579e5321338bb7b4e46abb859fd3bfd1515f`; [Main-CI #40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485) success. PR #145 auf `41da7ee40344fe0fb03ecedb505ea3e39662b25b` mit [CI #40014984206](https://github.com/ManuEtt/Dnd/actions/runs/40014984206) success; PR #146 auf `97d0075df0a4a2d78a35662f8ee16fd5b247513b` mit vollständig erfolgreicher [CI #40056990387](https://github.com/ManuEtt/Dnd/actions/runs/40056990387), einschließlich nativer Android-Tests und Alpha-APKs. Unabhängige PRs #144 (Sending) und #147 (Schurke) bleiben unverändert. Neuer Branch `feat/confirmed-xp-award-journal-20261024` baut auf PR #146 auf; App-Version vorläufig `0.8.36+86`.
- **IMPLEMENTIERT:** `GameEngine.confirmExperienceReward` erstellt ausschließlich nach `playerConfirmed=true` eine positive, per `rewardId` deduplizierte Belohnung über `ExperienceProgression.grant`; `GameController.confirmExperienceReward` validiert Kampagne, Revision und `actionRequestId`. Bestätigtes `xp.reward.confirmed`-Event inklusive `rewardId`, Betrag, Kennung, Bestätigung und `stateAfter` wird über die vorhandene SQLite-Transaktion gemeinsam mit dem Kampagnen-Snapshot und Heldenarchiv gespeichert. Wiederholungen nach Verlust der Antwort/Neustart erkennen den **persistierten Beleg vor Revisionsprüfung**, auch bei parallelem identischem Commit. Andere Daten/IDs scheitern ohne zweite Buchung.
- **TESTS GESCHRIEBEN:** `app/test/confirmed_xp_reward_storage_test.dart`: explizite Zustimmung, ungültige Werte/IDs, atomarer SQLite-Commit, verlorene Bestätigungsantwort, idempotente Wiederholung mit alter Revision, Neustart, Konkurrenz/Revisionskonflikt, Wiederverwendung für eine freie Handlung, SQL-Triggerfehler mit vollständigem Rollback, Klassenstufe unverändert.
- **GETESTET:** Vorgelagerter PR #146 erfolgreich in CI #40056990387. **NICHT GETESTET:** Neuer Branch bis eigener grüner CI; kein reales Android-Gerät, kein UI-Test der künftigen Belohnungsbestätigung. **BLOCKIERT:** Kein lokales Flutter-/Android-SDK und kein Testgerät in dieser Sitzung. **NOCH NICHT IMPLEMENTIERT:** Eigener Bestätigungsdialog mit lesbarer XP-Vorschau und Nutzerentscheidung, vollständige SRD-Abdeckung, providerweite Exactly-once-Garantie.
- **KOMPATIBILITÄT:** SQLite-DB-Schema 2, Export-JSON `schemaVersion=1`, bestehende APIs und Spielstände unverändert. Keine Story-/KI-Provider-Gutschrift, keine neue Berechtigung, keine Änderung offizieller XP-Levelschwellen und kein Versionssprung angesichts paralleler Versions-Branches.
- **NÄCHSTER KONKRETER SCHRITT:** Finale PR-CI (Python, Backend, Format/Analyse, gesamte Flutter-Suite, Android/JVM und APK-Artefakte) abnehmen und Fehler beheben. Vorgelagerte PRs in Reihenfolge #145 → #146 → XP-Controller-PR nach Review/CI integrieren. Danach gesonderte UI-Vorschau für bestätigte Gutschriften mit stabler Request-ID, Nein/Ja-Aktion, Accessibility- und 360dp-Layouttests.

---

## Zyklus 24.10.2026 – Rabenwacht-EP-Beleg bei beschädigten Altwerten sperren (neuer gestapelter PR)

- **CI-DIAGNOSE / KORREKTUR:** Erster neuer PR-Lauf [#40056860284](https://github.com/ManuEtt/Dnd/actions/runs/40056860284) auf Code-SHA `fa32c8d467d3910f952da9f713b2ab9cc031a46b` **failed** bei `flutter analyze` wegen `unused_import` in `app/test/rabenwacht_xp_sqlite_test.dart:11`; Python-, Backend- und Dart-Formatprüfung waren erfolgreich, Flutter-Tests/Android folgerichtig **übersprungen**. Unbenutzten Modellimport im Folgecommit entfernt. **Erneuter CI-Lauf ist erforderlich; kein Erfolg vor bestätigtem neuen HEAD.**

- **LIVE-BASIS:** `main` `5958579e5321338bb7b4e46abb859fd3bfd1515f` mit erfolgreicher [Main-CI #40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485); unabhängiger [PR #144](https://github.com/ManuEtt/Dnd/pull/144) (`Sending`) offen, erfolgreich getestet. Der vorgelagerte [PR #145](https://github.com/ManuEtt/Dnd/pull/145) auf `41da7ee40344fe0fb03ecedb505ea3e39662b25b` besitzt vollständig erfolgreiche [PR-CI #40014984206](https://github.com/ManuEtt/Dnd/actions/runs/40014984206). Neuer gestapelter Branch `fix/rabenwacht-xp-marker-integrity-20261024` auf genau diesem PR-HEAD; PR-Ziel ist dessen Branch, damit Dokumentation und Code nicht versehentlich gegeneinander arbeiten. App-Version bleibt vorerst `0.8.36+86` wegen paralleler Versionsarbeit.
- **IMPLEMENTIERT:** `CampaignExperience.awardOnce` unterscheidet ausdrücklich zwischen **fehlendem** Rabenwacht-XP-Beleg (belohnbar), **bestätigtem** Beleg `true` (idempotent) und **vorhandenem, beschädigtem** Beleg (hard fail mit `FormatException`). Alte falsche Markerwerte werden nicht automatisch überschrieben oder als offene Belohnungen behandelt.
- **TESTS GESCHRIEBEN:** `app/test/campaign_experience_test.dart` prüft drei beschädigte Marker und zulässigen Altstand ohne Marker; `app/test/rabenwacht_xp_sqlite_test.dart` führt echte Rabenwacht-Spielhandlungen mit vollständigen SQLite-Snapshot-/Event-Revisionen aus, schließt/öffnet die DB, prüft die fehlende Doppelbelohnung, manipulierter Beleg ohne DB-Schreibwirkung und konkurrierende veraltete Revision.
- **GETESTET:** Erfolgreiche CI des vorgelagerten PR #145 [#40014984206](https://github.com/ManuEtt/Dnd/actions/runs/40014984206) – **nur dessen SHA `41da7ee40344fe0fb03ecedb505ea3e39662b25b`**. **NICHT GETESTET:** Änderungen dieses neuen Branches vor eigener Flutter-/Android-CI, echtes Android-Gerät, Release-Signierung. **BLOCKIERT:** Kein lokales Flutter-/Android-SDK und kein Gerät. **NOCH NICHT IMPLEMENTIERT:** Generische XP-Vergabe über bestätigte GameController-Aktion samt eigener UI und Ende-zu-Ende-Request-ID; vollständige SRD-5.2.1-Automatik.
- **KOMPATIBILITÄT:** SQLite-Version 2, Kampagnen-JSON `schemaVersion=1` unverändert. Keine neue Datenmigration, keine KI-/Narrations-Autorität, keine externen Provider, keine Änderung an regelkonformen XP-Schwellen. Rabenwacht-Belohnungshöhen bleiben proprietäres Abenteuerdesign und keine SRD-Quote.
- **NÄCHSTER SCHRITT:** Eigene PR-CI auf finalem Branch-HEAD (Python, Backend, Dart, Flutter/SQLite, Android) abnehmen; nach Merge von PR #145 den gestapelten PR gegen `main` retargeten und Reconciliation-CI prüfen. Danach gesondert einen autorisierten, idempotenten XP-Bestätigungsbefehl über GameController/SQLite-Journal mit sichtbarer Nutzerbestätigung entwickeln.

---

## Zyklus 2026-10-23 (Europe/Berlin) – Widersprüchliche XP-Belohnungs-ID ablehnen (PR-/CI-Prüfung)

- **LIVE-BASIS:** `main` `5958579e5321338bb7b4e46abb859fd3bfd1515f`, GitHub Actions [#40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485) **completed / success** ausschließlich auf diesem Main-SHA. Bei Beginn war [PR #144](https://github.com/ManuEtt/Dnd/pull/144) zum Zauber `Sending` offen; dessen [CI #40012034969](https://github.com/ManuEtt/Dnd/actions/runs/40012034969) erfolgreich für einen **anderen** Code-HEAD. Arbeitsbranch `fix/xp-reward-id-conflict-20261023`, Ausgangsversion `0.8.36+86`; kein paralleler Versionssprung wegen offenem PR #144.
- **IMPLEMENTIERT:** `ExperienceProgression.grant` bestätigt eine wiederholte ID nur noch bei **exakt gleichem** bereits gespeicherten XP-Betrag; abweichende oder unlesbare Bestandswerte führen zu `FormatException` ohne Zustandsänderung. Bekannte identische Bestätigungen bleiben idempotent. **Kein geänderter SRD-Mechanismus:** Es handelt sich um Konsistenzprüfung der lokalen Belohnungsbelege.
- **TESTS GESCHRIEBEN:** `app/test/experience_progression_test.dart` – bestätigte Duplikate nach JSON-Roundtrip, ID-Kollision mit abweichendem Betrag und manipulierter Legacy-Beleg ohne Veränderung von Held/XP/Fakten. Die lokale Ausführungsumgebung hat **kein Dart-/Flutter-SDK**; Tests werden erst nach tatsächlichem erfolgreichem CI-Lauf als bestanden bezeichnet.
- **KOMPATIBILITÄT:** SQLite-Schema 2 und Kampagnen-JSON `schemaVersion=1` unverändert, kein KI-Provider, keine Migration. Widersprüchliche Altdaten werden nicht automatisch überschrieben.
- **GETESTET:** Main-CI #40012217485 nur als Vorher-Baseline. **NICHT GETESTET:** Neue Branch-CI und Android-Gerät bis eindeutige Ergebnisse vorliegen. **BLOCKIERT:** Lokale Flutter-/Android-/Geräteprüfungen mangels SDK/Gerät. **NOCH NICHT IMPLEMENTIERT:** Vollständige SRD-5.2.1-Regelabdeckung sowie Validierung externer Erzählungs-/Belohnungsquellen.
- **NÄCHSTER KONKRETER SCHRITT:** Den PR-Workflow auf dem **finalen** Branch-SHA auswerten und Fehler beheben; anschließend separat eine bestätigte, revidierbare XP-Belohnungsaktion von GameEngine/GameController bis SQLite-Journal auf Doppel-IDs und Neustart prüfen. Keine automatische Integration in `main` ohne PR-Abnahme.

---

## Zyklus 23.10.2026 – SRD-5.2.1-Schurke: Hinterhältiger Angriff mit bestätigtem Verbündeten

- **LIVE-BASIS:** `main` nach Merge von [PR #142](https://github.com/ManuEtt/Dnd/pull/142) auf `f71c287e4cdade3c678dbe6a93d080b3c31b9e80`, Flutter-App `0.8.35+85`; die zugehörige [main-CI #40010469412](https://github.com/ManuEtt/Dnd/actions/runs/40010469412) lief beim Start dieses Zyklus noch. Nachweis für den **vorherigen** Stand `2dac48e0`: [CI #40008013311](https://github.com/ManuEtt/Dnd/actions/runs/40008013311) erfolgreich. Neuer Branch `fix/srd-rogue-sneak-attack-ally-20261023` und neue App-Version `0.8.36+86`.
- **IMPLEMENTIERT:** `ClassCombatFeatures.eligibleSneakAttackDice` erfordert zusätzlich zum alten Ally-Hinweis zwei unabhängige bestätigte Fakten für die alternative Auslösung ohne Vorteil: der Verbündete muss **innerhalb von 5 Fuß DES ZIELS** stehen und darf **nicht den Zustand Incapacitated** besitzen. Ein bewusster, aber stunned/incapacitated Verbündeter qualifiziert nicht. Bestehende normale Angriffsvorteile bleiben unabhängig. Fehlende Angaben liefern konservativ **keinen** Sneak-Attack-Bonus.
- **TESTS NEU:** `app/test/class_combat_features_test.dart` testet korrekten Verbündetenfall, fehlende Entfernung, kampfunfähigen Verbündeten, aufgehobenen Vorteil/Nachteil, tatsächlich vorhandenen Vorteil, 1x-pro-Zug-Guard und kritische Treffer. **CI des neuen Branches ausstehend**, ebenso echter Android-Geräte-Test.
- **SRD-BELEGE:** Original [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), Schurke Sneak Attack S. 62, CC BY 4.0. Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt `partial` mit konkretem Testpfad; **keine globale Fertigstellungsquote**. Die aktive `GameEngine` reicht derzeit `adjacentConsciousAlly: false` ein: Verbündeten-Situationsmechanik ist **noch nicht** mit validierten Positionen/Zuständen in der GameEngine verbunden. Keine unbestätigte Positionsannahme und kein automatischer Schaden.
- **KOMPATIBILITÄT:** unverändert DB-Schema 2, Kampagnen-JSON `schemaVersion=1`, keine neue Berechtigung, Provider-Anfrage oder Storylogik. Alte API bleibt über optionale neue Guard-Felder kompilierbar, fail-closed.
- **NÄCHSTER KONKRETER SCHRITT:** Neuen PR/CI auf dem finalen Code-HEAD abnehmen und Fehler beheben; danach explizite Positions-/Zustandsbestätigungen in den Kampfdialog und Revisionsjournal integrieren, ohne KI-Narration als Fakt zu akzeptieren. Echtes Android-Upgrade/Backup-Restore separat abnehmen.

---

## Zyklus 23.10.2026 – SRD 5.2.1: Zauberreichweite Sicht (CI ausstehend)

- **Live-Basis:** `main`-SHA `2dac48e0ceedc9759255b224a5e38b8b3383c801`; [PR #140](https://github.com/ManuEtt/Dnd/pull/140) und [#141](https://github.com/ManuEtt/Dnd/pull/141) sind inzwischen **gemergt**. Kombinierte [PR-CI #40004287299](https://github.com/ManuEtt/Dnd/actions/runs/40004287299) vollständig grün auf Merge-Branch `eb45415c`, neue Main-CI [#40008013311](https://github.com/ManuEtt/Dnd/actions/runs/40008013311) bei Start noch nicht abgeschlossen. Neuer Feature-Branch `feat/srd-sight-range-preflight-20261023`, App-Version **0.8.35+85**.
- **IMPLEMENTIERT:** `SrdSpellTargetRules.validateOrigin` unterscheidet für SRD-Reichweite `Sight` ausdrücklich bestätigte Sicht und bestätigten freien Weg. Neuer optionaler `visibleOriginConfirmed`-Wert in `SrdSpellTargetFacts`, separate Weitergabe über `SrdSpellGridTargetRequest.originVisibleConfirmed`. Klare 2D-Kartenrasterlinie ist **kein** Nachweis der Sicht; unbestätigte Sicht, Mauern und unvollständig vermessene Karten sind gesperrt. `Unlimited` und `Special` bleiben **UnsupportedError**. Keine automatische Wirkung, Ressourcenabbuchung oder Freigabe des zehnminütigen `Mirage Arcane`.
- **TESTS GESCHRIEBEN:** `srd_spell_target_rules_test.dart` (339 katalogisierte Zauberreichweiten, nun 2 weiterhin ununterstützte Sonderwerte; Sichtbestätigung, Abbruchfälle); `srd_spell_grid_target_rules_test.dart` (räumliche Bestätigung und Rasterblockaden). Status in `docs/srd_5_2_1_requirements.json` bleibt `partial`, mit ausdrücklich dokumentierter Begrenzung.
- **GETESTET:** Nur bisherige Basis-CI und die in älteren Abschnitten belegten Features. **NICHT GETESTET:** endgültige CI des neuen Branches bis zu deren erfolgreichem Abschluss, echtes Android-Gerät, kompletter SRD-Zauberkatalog/automatische Effekte. **BLOCKIERT:** kein lokal erreichbares Flutter-/Android-SDK und echtes Gerät. **NOCH NICHT IMPLEMENTIERT:** regelgeprüfter `Sending`-Zielpfad, `Dream`-Sonderreichweite, 3D-Sicht, 10-Minuten-Zauberverbrauch und komplette SRD-5.2.1-Abdeckung.
- **Geändert:** `app/lib/domain/srd_spell_target_rules.dart`, `app/lib/domain/srd_spell_grid_target_rules.dart`, zwei bestehende Testdateien, `app/pubspec.yaml`, `docs/srd_5_2_1_requirements.json`, `docs/SRD_SIGHT_RANGE_PREFLIGHT_20261023.md`, Checkpoint/README/Changelog/Entwicklungsstatus.
- **Nächster Schritt:** vollständige GitHub-CI auf dem aktuellen Feature-Code-HEAD prüfen, Defekte reparieren, PR nach Review integrieren, danach offizielle Zauberquelleninventur und nächsten Ziel-/Wirkungsbaustein mit echter Ressourcen- und Persistenzprüfung fortsetzen. Keine offenen CI-Lücken als Erfolg ausgeben.

---

## Zyklus 23.10.2026 – SQLite-v1-Bestandsmigration auf integriertem Stand (PR #141)
- **Git-Basis:** `main` ist nach geprüftem Merge von [PR #140](https://github.com/ManuEtt/Dnd/pull/140) bei `a3dec6196e0b97acc185a77b525fdd9c5cc676da`, App **0.8.34+84**. PR #140: [CI #39968525780](https://github.com/ManuEtt/Dnd/actions/runs/39968525780) **completed/success** auf Head `012c51d09f599ea4daf004834aef8e23d71c2fcc`; neuer Main-Merge-Commit muss separat in [Actions](https://github.com/ManuEtt/Dnd/actions) geprüft werden.
- **IMPLEMENTIERT:** [PR #141](https://github.com/ManuEtt/Dnd/pull/141) übernimmt `app/test/populated_legacy_upgrade_test.dart` aus dem ohne Merge geschlossenen #137 und ergänzt einen Test auf **doppelte Legacy-Request-IDs** mit vollständigem v1-Rollback. Gespeicherte Kampagnen, Heldenarchive, Ereignisse, Revisionshistorie, Einstellungen, Outbox-Request-ID, Wiederöffnung und altes JSON-Exportformat werden geprüft. Kein Produktcode und kein DB-Schema geändert.
- **GETESTET:** Vor der Auflösung des Dokumentationskonflikts bestand die vollständige PR-CI [#39994226404](https://github.com/ManuEtt/Dnd/actions/runs/39994226404) auf `625e043cd6f7d0d4f976603e485864634bc14017`, einschließlich aller Tests und Android-APK-Builds. **NICHT GETESTET:** der neue zusammengeführte Branch-HEAD, bevor dessen CI abgeschlossen ist; echtes Android-Geräteupgrade mit Sicherung und Rückspielung.
- **BLOCKIERT:** reales Android-Gerät lokal nicht verfügbar. **NOCH NICHT IMPLEMENTIERT:** vollständige SRD-5.2.1-Abdeckung und Drittanbieter-Exactly-once-Garantie.
- **NÄCHSTER KONKRETER SCHRITT:** Merge-Reconciliation-CI auf finalem PR #141-HEAD prüfen, danach PR nach Review integrieren; die Hauptbranch-CI anschließend ausdrücklich getrennt verifizieren. Echte Geräte- und Altspielstandabnahme weiterhin offen.

---

## Zyklus 23.10.2026 – Atomare Kampagnenlöschung und gespeicherte Auswahl (CI ausstehend)

- **LIVE-BASIS:** `main` bei Beginn `4061d6510dd7072f980e317155b878317790eecc`. Die zuvor gestapelten PRs #133–#136 wurden inzwischen integriert (teilweise über neue Merge-PRs #138/#139). Der gefüllte v1→v2-Test-PR [#137](https://github.com/ManuEtt/Dnd/pull/137) ist **geschlossen, nicht gemergt**, seine [CI #39964813706](https://github.com/ManuEtt/Dnd/actions/runs/39964813706) war auf Test-HEAD `ebf2a6f` erfolgreich. Für `main`-HEAD `4061d651` läuft [CI #39967425937](https://github.com/ManuEtt/Dnd/actions/runs/39967425937) noch; keine Freigabe für diesen HEAD behaupten.
- **IMPLEMENTIERT IM NEUEN BRANCH:** `fix/atomic-campaign-deletion-selection-20261023`, App-Version `0.8.34+84`. Vertrag `AtomicCampaignDeletion` sorgt dafür, dass SQLite beim gezielten Löschen einer Kampagne deren Snapshot (inklusive per FK zugeordnetem Journal und bestätigten Events), ihre ausstehende Spielerhandlung und – **nur wenn die gelöschte Kampagne ausgewählt war** – `settings.lastCampaignId` in **einer** Transaktion anpasst. Andere Einstellungen sowie eine neuere, anderslautende Auswahl bleiben erhalten. `GameController.deleteCampaign` nutzt den Vertrag, ohne im Anschluss eine konkurrierende Auswahl durch `_remember(null)` überschreiben zu können; alte/Test-Repositories behalten den bisherigen Ablauf.
- **REGRESSIONSTESTS ERSTELLT, BIS CI UNBESTÄTIGT:** `app/test/atomic_campaign_deletion_test.dart` – ausgewählte und nicht ausgewählte Kampagnen, gleichzeitig wechselnde Auswahl über zwei SQLite-Verbindungen, Outbox-Isolation, Neustart, und Rollback bei absichtlich fehlschlagendem Settings-Update. Tests waren in der Sitzung lokal nicht ausführbar; endgültige GitHub-CI inklusive Flutter-Tests/Analyse und Android-Build ist abzuwarten.
- **KOMPATIBILITÄT:** SQLite-Datenbankschema **2** und Kampagnen-JSON-`schemaVersion=1` unverändert. Keine geänderten SRD-5.2.1-Regeln, KI-/Provider-Aufrufe oder Geräteberechtigungen.
- **NICHT GETESTET:** neue CI, reale Android-Installation/Altgerät-Migration, echte Wiederherstellung und Releasesignatur. **BLOCKIERT:** kein Flutter-/Android-SDK und kein reales Gerät in der Ausführungsumgebung. **NOCH NICHT IMPLEMENTIERT:** vollständige SRD-5.2.1-Abdeckung, providerübergreifendes Exactly-once und Mehrgeräte-Synchronisierung.
- **DATEIEN:** `app/lib/data/campaign_repository.dart`, `app/lib/data/sqlite_campaign_repository.dart`, `app/lib/services/game_controller.dart`, `app/test/atomic_campaign_deletion_test.dart`, `app/pubspec.yaml`, `docs/CODEX_CHECKPOINT.md`, `README.md`, `CHANGELOG.md`, `DEVELOPMENT_STATUS.md`.
- **NÄCHSTER KONKRETER SCHRITT:** finale CI dieses PR-HEAD prüfen, fehlerhafte Tests/Kompilation korrigieren; danach Test auf echter Android-Sicherung/Migration und verbliebene Referenzintegrität bei Kampagnenwechseln gesondert bearbeiten. Ein Merge nach `main` erst mit grünen Checks und Review.

---

## Zyklus 23.10.2026 – Transaktionaler vollständiger Datenreset (Code-CI vollständig grün)

- **Git-Stand:** `main` zu Beginn `b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9`; offener gestapelter [PR #136](https://github.com/ManuEtt/Dnd/pull/136) auf `fix/atomic-full-data-reset-20261023`, Basis PR #135. Vorgelagerte PRs #133 (Draft), #134 und #135 offen und nicht nach `main` integriert. App-Version **0.8.33+83**. Letzter tatsächlich getesteter neuer Code-HEAD: **`0145108c57c562e3a6635a2ea6440d4649278222`**.
- **IMPLEMENTIERT:** `AtomicUserDataReset` im Repository-Vertrag; `SqliteCampaignRepository.deleteAllUserData` löscht Kampagnen, Revisionsjournal, Spielereignisse, Charakterarchiv, Einstellungen und persistente PlayerActionOutbox in **einer SQLite-Transaktion**, beim Fehler mit vollständigem Rollback. `GameController.deleteAllData` wählt diese Operation für SQLite und bewahrt den bisherigen Fallback für andere Repository-Implementierungen.
- **GETESTET:** [GitHub Actions #39946157697](https://github.com/ManuEtt/Dnd/actions/runs/39946157697) – **completed/success**, Head SHA `0145108c57c562e3a6635a2ea6440d4649278222`. Bestanden: Python-Projekt-/Pakettests, Backend-Typen/Build/Tests, Dart-Formatierung, Flutter-Analyse, gezielte UI-Tests, **vollständige Flutter-Suite inklusive SQLite-Rollback-/Neustarttests**, Android-Debug-APK, native Android-Tests, kleine Alpha-APKs und Release-/Quellcode-Artefaktschritte. Erster Versuch [#39945364361](https://github.com/ManuEtt/Dnd/actions/runs/39945364361) scheiterte an zwei Testhelfer-Verbindungsfehlern (`database_closed`); getrennte Diagnoseverbindungen mit `singleInstance:false` behoben und durch erfolgreichen finalen Lauf erneut geprüft.
- **Artefakte aus erfolgreicher PR-CI:** [Versioniertes Alpha-Paket](https://github.com/ManuEtt/Dnd/actions/runs/39946157697/artifacts/12498941276) (Archiv-SHA256 `0134fc78296801e17da2cd5c4a08905ae9eb84080bf54963f9d8ed7998a1b1ae`), [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/39946157697/artifacts/12498088523), [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/39946157697/artifacts/12497829089), [Quellcode-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/39946157697/artifacts/12498926248). Das Artefakt-Namens-SHA `6c861223...` gehört zum vom PR-Workflow ausgecheckten Merge-Commit; GitHub meldet den Head-SHA `0145108c...`. Downloadartefakte sind zeitlich befristet.
- **Datenformat und Sicherheit:** DB-Schema bleibt **2**, JSON-Kampagnen-`schemaVersion=1`; keine D&D-Regel-/Story-/KI-Provider-Änderung. Vollständige Löschung nur bei ausdrücklicher Benutzeraktion. Nach abgeschlossenem Reset sind neue spätere Schreibvorgänge unabhängiger Verbindungen möglich; keine anwendungsweite Schreibsperre implementiert.
- **NICHT GETESTET:** Echter Android-Installations-/Updatepfad, Migration realer SQLite-Version-1-Spielstände auf Gerät, Backup/Restore, langfristige Release-Signatur. **BLOCKIERT:** Keine Zugriffsmöglichkeit auf ein echtes Android-Gerät hier. **NOCH NICHT IMPLEMENTIERT:** Echte providerübergreifende Exactly-once-Semantik, vollständige SRD-5.2.1-Regelabdeckung.
- **Änderungen:** `app/lib/data/campaign_repository.dart`, `app/lib/data/sqlite_campaign_repository.dart`, `app/lib/services/game_controller.dart`, `app/test/atomic_full_data_reset_test.dart`, `app/pubspec.yaml`, `docs/ATOMIC_FULL_DATA_RESET_20261023.md`, `README.md`, `CHANGELOG.md`, `DEVELOPMENT_STATUS.md`, dieser Checkpoint.
- **NÄCHSTER SCHRITT:** PRs **#133 → #134 → #135 → #136** in dieser Reihenfolge prüfen und erst mit gültigen Merge-Basen und CI integrieren. Anschließend ein echtes Android-Geräteupgrade von SQLite 1 auf 2 mit vorher gesichertem Altspielstand sowie Export/Import und vollständigem Datenreset abnehmen. Ein weiterer reiner Markdown-Nachtrag benötigt für dessen Head ggf. eine neue PR-CI; oben genannte grüne CI belegt explizit den angegebenen Code-SHA.

---
## Zyklus 23.10.2026 – Atomare Teilaktualisierung von App-Einstellungen (PR/CI-Prüfung)

- **Baseline:** `main` bei Start `b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9`; #133 noch offen (Docs), #134 noch offen (SQLite-Outbox; finale CI [#39940517928](https://github.com/ManuEtt/Dnd/actions/runs/39940517928) **success** auf `8162388e`). Arbeitsbranch `fix/atomic-settings-updates-20261023` baut auf #134 auf. App-Version **0.8.32+82**.
- **IMPLEMENTIERT:** `AtomicSettingsStore` und `CampaignSettingsUpdates.patchSettings` bieten atomare JSON-Teilupdates mit benannten Löschungen über eine SQLite-Transaktion. Die bestehenden Schreibstellen für `lastCampaignId`, `backendUrl`/`backendRequestLimit` und Sprachausgabepräferenzen nutzen jetzt diese Schnittstelle. Klassische Full-Snapshot-`saveSettings`-Semantik bleibt absichtlich erhalten für `deleteAllData` und ältere Mock-Repositories; Fallback ohne Atomizitätsgarantie ist dokumentiert.
- **Zusätzlicher Datenreset-Fix:** `deleteCampaign` entfernt die dazugehörige transaktionale Outbox-Zeile; `GameController.deleteAllData` leert ausdrücklich auch verwaiste `pending_player_actions` (nicht nur die alte Settings-Zeile). Tests für Kampagnen-Isolation und Komplettreset ergänzt.
- **Tests erstellt:** `app/test/atomic_settings_updates_test.dart`: unabhängige SQLite-Verbindungen, gleichzeitige Einstellungen, 24 konkurrierende unabhängige Updates, selektives Entfernen, fehlgeschlagene Kodierung/Rollback, unveränderte PlayerActionOutbox und Kampagnenwiederherstellung nach Neustart.
- **Datenkompatibilität:** Keine weitere SQLite-Migration; bestehendes DB-Schema 2 und Kampagnen-JSON-`schemaVersion=1` unverändert; keine unbestätigte Regel-, XP- oder Inventaränderung. Der Sprach- und Backend-Provider bekommt keinen neuen Zugriff und wird nicht automatisch erneut aufgerufen.
- **GETESTET:** Vorheriger #134-Code-HEAD `8162388e` ist durch CI #39940517928 nachgewiesen. **NICHT GETESTET:** Neue Änderungen dieses Branches bis zum Abschluss der aktuellen GitHub-CI, echtes Android-Gerät und Langzeit-Upgrade mit Nutzerdaten. **BLOCKIERT:** lokales Flutter-/Android-SDK hier nicht vorhanden. **NOCH NICHT IMPLEMENTIERT:** atomare Vollsnapshot-`saveSettings`-Konkurrenzsicherung, providerübergreifendes Exactly-once, vollständige SRD-5.2.1-Automatisierung.
- **Dateien:** `app/lib/data/campaign_repository.dart`, `app/lib/data/sqlite_campaign_repository.dart`, `app/lib/services/game_controller.dart`, `app/lib/main.dart`, `app/test/atomic_settings_updates_test.dart`, `app/pubspec.yaml` sowie README, Changelog, Entwicklungsstatus und dieser Checkpoint.
- **NÄCHSTER KONKRETER SCHRITT:** CI auf dem finalen neuen Code-HEAD prüfen, mögliche Fehler reparieren; gestapelte PRs #133 → #134 → diese Änderung erst nach Review und geprüftem Merge-Kontext integrieren. Danach eine separate Geräte-Migrations-/Backupabnahme mit realem Altspielstand vorbereiten und die verbleibenden vollständigen `saveSettings`-Aufrufer gegen verlorene Änderungen absichern.

---

## Zyklus 23.10.2026 – Transaktionale Player-Action-Outbox (Code-CI vollständig erfolgreich)

- **Stand / Referenzen:** main `b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9`; Funktionsbranch `fix/transactional-player-action-outbox-20261023`, [PR #134](https://github.com/ManuEtt/Dnd/pull/134) gestapelt auf offenem Dokumentations-[PR #133](https://github.com/ManuEtt/Dnd/pull/133); App **0.8.31+81**. **Getesteter Code-HEAD: `1ca83e63c5d78c84b1babebcc15c0a392725b7a3`**.
- **IMPLEMENTIERT:** Eigene SQLite-Tabelle `pending_player_actions`, eindeutige Request-ID und Kampagnenbindung, atomare Stage-/Remove-Transaktionen. DB-Migration **1 → 2** übernimmt vorhandene `pendingPlayerActionsV1`-Einträge samt ID und Text, bewahrt unabhängige Settings; ungültige Legacy-Aufträge verhindern stillen Verlust durch Abbruch/Rollback. Export der Kampagnen unverändert JSON-`schemaVersion=1`. Kein automatischer bezahlter Erzähler-Retry.
- **GETESTET:** [Vollständige GitHub-Actions-CI #39938760852](https://github.com/ManuEtt/Dnd/actions/runs/39938760852) auf `1ca83e63c5d78c84b1babebcc15c0a392725b7a3` **completed/success** am 23.10.2026. Erfolgreich: Python-Struktur-/Pakettests, Backend-Typecheck/Build/Tests, Dart-Format, Flutter-Analyse, gezielte Dialog- und **vollständige Flutter-Tests** einschließlich neuer Outbox-/SQLite-Migrationstests, Android-Debug-APK, native Android-Tests und drei ABI-Alpha-APKs sowie Release-/Quell-ZIP-Erstellung. Für den älteren `main`-SHA war CI #39932399488 erfolgreich.
- **Neue Tests:** `app/test/player_action_outbox_test.dart` (parallele SQLite-Verbindungen, Setting-Kollision, Kampagnenisolation, invalid/stale Request) und `app/test/player_action_outbox_migration_test.dart` (v1-Upgrade mit Neustart, fehlerhafter Legacy-Eintrag/Rollback). `app/test/storage_repository_test.dart` unterstützt DB-Schema-Version 2.
- **Artefakte des verifizierten CI-Laufs:** `wuerfelraunen-alpha-1612-1ca83e63c5d78c84b1babebcc15c0a392725b7a3` (SHA-256 des GitHub-Artefaktarchives `629d6e7054a6298e1c78950965d84a0de68ff01b036ffe8c391e8aa0b293f08d`), `lebendiger-spielleiter-alpha-kleine-apks`, `lebendiger-spielleiter-android-debug`, `wuerfelraunen-source-checkpoint-1ca83e63c5d78c84b1babebcc15c0a392725b7a3`. Diese Artefaktnamen und Digests stammen aus GitHub; keine Geräteeignung behauptet. Bei diesem Dokumentationsnachtrag nach grünem Code-Run kann der finale Docs-HEAD vom getesteten Code-HEAD abweichen.
- **NICHT GETESTET:** App-Installation und Upgrade mit echten Altspielständen auf einem Android-Gerät, Release-Signierung für produktive Updates, kostenpflichtiger Drittanbieter-Exactly-once-Pfad. **BLOCKIERT:** reales Android-Gerät hier nicht erreichbar, kein lokales Flutter-/Dart-SDK. **NOCH NICHT IMPLEMENTIERT:** atomare Teilupdates ALLER übrigen Einstellungen, echte KI-Provider-Exactly-once-Semantik, vollständige SRD-5.2.1-Automatik.
- **Dateien:** `app/lib/data/campaign_repository.dart`, `app/lib/data/sqlite_campaign_repository.dart`, `app/lib/services/player_action_outbox.dart`, `app/pubspec.yaml`, drei Outbox-/Storage-Tests und `docs/CODEX_CHECKPOINT.md`, `README.md`, `CHANGELOG.md`, `DEVELOPMENT_STATUS.md`.
- **NÄCHSTER KONKRETER SCHRITT:** Nach Merge von PR #133 den gestapelten PR #134 auf `main` umstellen, Rebase-/Merge-Basis und neue finale CI prüfen; anschließend als eigenes Inkrement übrige Einstellungs-Updates auf atomare Teilupdates umstellen, mit konkurrierenden Writer- und Neustarttests. Vor produktivem Update echte Android-Migration gesondert abnehmen.

---

# CODEX-CHECKPOINT – aktueller Entwicklungs- und Übergabestand

> **Operative Wiederaufnahme** von Würfelraunen. Bei jeder aktiven Codex-Sitzung dieses Dokument **am Anfang prüfen und am Ende aktualisieren**; alle unten stehenden Werte sind eine Momentaufnahme und niemals Ersatz für einen erneuten GitHub-Check. Einstieg: [CODEX_CONTINUATION_PROMPT.md](CODEX_CONTINUATION_PROMPT.md).
>
> Stand der ersten Bestandsaufnahme: **2026-10-23, Europa/Berlin**. GitHub-API-Beobachtung vor Erstellung dieses Dokumentationsbranches. Nicht verifizierte zukünftige Änderungen oder CI-Ergebnisse werden nicht vorweggenommen.

## 1. Quelle der Wahrheit und Git-Baseline

| Merkmal | Verifizierter Ausgangswert |
| --- | --- |
| Produkt | Würfelraunen – Der lebendige Spielleiter |
| Repository | https://github.com/ManuEtt/Dnd |
| Hauptbranch | main |
| main HEAD bei Bestandsaufnahme | b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9 |
| Letzter hier bestätigter erfolgreicher Main-CI | https://github.com/ManuEtt/Dnd/actions/runs/39932399488 |
| CI geprüfter SHA | b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9 |
| CI Status | completed / success |
| Version aus app/pubspec.yaml | 0.8.30+80 |
| Offene PRs bei Bestandsaufnahme | keine (GitHub-API) |
| Dokumentations-Arbeitsbranch | docs/autonomous-codex-handoff-20261023 |
| Inhalt des Branches | dieser Checkpoint, aktueller Codex-Prompt, README- und Einstiegshinweise |
| Produktionsstatus | Android-Alpha; kein vollständiges D&D-SRD-Regelwerk |
| Lizenz | Offizielles SRD 5.2.1, CC BY 4.0; THIRD_PARTY_NOTICES.md beachten |

Die letzte geprüfte Main-CI #39932399488 ist auf obigem Main-Commit vollständig grün: Python-Struktur- und Testsuite, Node-/TypeScript-Backend-Typecheck/Build/Tests, Dart-Format und Flutter-Analyse, gezielte sowie vollständige Flutter-Tests, Android-Debug-APK, native Android-Tests, ARM64/ARM/x64-Alpha-Builds, Alpha-Release- und Quell-ZIP-Artefakte. **Das ist KEIN Nachweis für Installation/Funktionstest auf realem Android-Gerät.**

Dieser Dokumentationsbranch ist nicht durch den genannten Main-Lauf geprüft. README/docs-only-Änderungen lösen den Android-Workflow wegen dessen Pfadfiltern nicht automatisch aus. Bei Bedarf Workflow auf dem tatsächlich relevanten Branch explizit starten. Dokumentenänderungen sind keine neue App-Version.

## 2. IMPLEMENTIERT (basierend auf integriertem Code und bestandenem Main-CI)

- Flutter-App mit deutscher Fantasy-Gestaltung, Charaktererstellung, Charakterbogen, Kampagnenwahl, Abenteuer, Journal, lokalem SQLite-Spielstand und JSON-Import/Export; Sprachaufnahme/Text-to-Speech über die vorhandenen Geräteschnittstellen.
- Offline spielbarer Demonstrations-/Rabenwacht-Inhalt; optionaler separater Backend-Erzähler. Narration ändert keine bestätigten D&D-Regelwerte frei.
- SRD-5.2.1-Teilmechaniken zu Attributen/Fertigkeiten, Klassen, Kampf-/Würfelaktionen, ausgewählten Zaubern, Reaktionen, Effekten und Klassenentwicklung. Nicht mit vollständiger offizieller SRD-Abdeckung verwechseln.
- Fixierte Schnellaktionen im Abenteuer, mit überprüftem Kampfkontext und Erhalt freier Eingabeentwürfe: PR #128.
- Persistentes Action-Receipt und idempotente Spieleraktionen mit stabiler Handlungskennung über GameController.sendAction: PR #129.
- Persistenter ausstehender Handlungsauftrag je Kampagne via PlayerActionOutbox, explizites Wiederholen oder Verwerfen statt stillschweigender Wiederholung: PR #130.
- UI-Initialisierung, Wiederherstellungstests und Android-Tastaturregressionen korrigiert: PR #131.
- Parallel eintreffende Bestätigung derselben Spielerhandlung bei SQLite-Revisionsrennen abgeglichen: PR #132, siehe docs/PARALLEL_ACTION_ACK_20261023.md.

## 3. GETESTET – exakt belegte Ebene

- **Erfolgreiche GitHub-Actions-Prüfung**: Run #39932399488 auf SHA b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9.
- In diesem Lauf grün: Paket-/Strukturprüfungen, Python-Tests, Backend-Typecheck/Build/Tests, Dart-Format, Flutter-Codeanalyse, vollständige Flutter-Suite, nativer Android-JVM-Test, Debug-/Alpha-APK-Builds und Artefaktbereitstellung.
- Spezifische Tests für Outbox, verlorene Antworten, SQLite-Neustart und parallelen Action-Commit liegen im Quellcode. Ihr tatsächlicher bestanden/nicht-bestanden-Status wurde über die vollständig grüne Gesamtsuite des oben genannten Builds abgesichert. Prüfobjekt ist ausschließlich dieser Commit.
- Vom neuen Dokumentationsbranch wurden **keine** Flutter- oder Android-Tests lokal ausgeführt oder als bestanden behauptet.

## 4. NICHT GETESTET / BLOCKIERT

**NICHT GETESTET**
- Echte Geräteinstallation auf Android und Ausführung von Spracherkennung/TTS, Bildwähler, großen Schriftgrößen/Screenreader, komplexen Kampf- und Mehrklassenpfaden.
- Langfristiges Upgrade derselben installierten App und reale Datenmigration/Backup-Wiederherstellung auf verschiedenen Android-Versionen.
- Reale KI-Anbieter- und Kosten-/Datenschutz-End-to-End-Abnahme; keine freigegebene unbegrenzte API-Ausführung.
- Vollständiger amtlicher Regel-für-Regel-Abgleich der SRD 5.2.1; der historische Inventory-Stand ist keine Vollständigkeitsquote.

**BLOCKIERT**
- Ein dauerhaft autonomer Hintergrund-Codex ist in diesem Repository absichtlich nicht eingerichtet. Weitere Arbeit benötigt eine aktive Codex-Sitzung bzw. ausdrücklich autorisierte Orchestrierung.
- Eine sichere reale App-Update-/Produktionssignierung benötigt eigenes Release-/Geräteverfahren; vorhandene Alpha-APKs sind nicht automatisch Store- oder langlebige Upgrade-Releases.
- Freigaben für paid Provider, lizenzrechtlich unklare Grafiken und produktive irreversible Datenoperationen fehlen und dürfen nicht angenommen werden.

## 5. NOCH NICHT IMPLEMENTIERT – bekannte Grenzen

- Vollständige D&D-SRD-5.2.1-Regelwirkung und amtlich vollständig gegengeprüfte Zauber-/Monster-/Feature-Inventur; Coverage-Audit unter docs/SRD_5_2_1_COVERAGE_AUDIT.md hat offene Inventurlücken und keine belastbare Fertigstellungsquote.
- Allgemeine Ende-zu-Ende-Exactly-once-Garantie für externe AI-Provider. Eine vor SQLite-Commit erfolgte Provideranfrage kann bei manueller Wiederholung erneut berechnet werden.
- Transaktionale Outbox-Tabelle für konkurrierende Änderungen an allen App-Einstellungen; bisheriger Outbox-Speicher nutzt read-modify-write über vorhandenes Settings-JSON.
- Stabile Request-IDs für **alle** übrigen GameController-Operationen wie freie Würfe, separate Würfelentscheidungen und Effektaktionen.
- Vollständige autonome KI-Kampagnenleitung mit dauerhaftem NPC-Wissen und belastbarer Langzeitkonsistenz in allen freien Spielsituationen.

## 6. Technische Entscheidungen und unveränderliche Verträge

1. Regeln und Story strikt getrennt: app/lib/rules/rules_api.dart, app/lib/story/story_api.dart und story_rule_boundary.dart; Tests der Importgrenze einhalten.
2. Nur validierte Aktionen mutieren Held/Kampf/Inventar/Ressourcen; atomare Snapshot-/Event-/Revisionsspeicherung in SQLite. Importformat/schemaVersion=1 nicht stillschweigend ändern.
3. Offene Handlung vor Ausführung dauerhaft merken; beim Neustart nicht ungefragt wiederholen; identische bestätigte Request-ID nicht doppelt anwenden. Reale Drittanbieteraufrufe bleiben ein separates Risiko.
4. Normative SRD-Quelle und CC-BY-4.0-Namensnennung; keine Buchinhalte außerhalb der Lizenz kopieren. Keine privaten Spielstände oder Geheimnisse in Git.
5. Feature-, Story- und UI-Inkremente nur in kleinem separatem Branch mit Tests und GitHub-PR. Kein Merge auf Basis früherer CI; kein Force-Push oder ungesichertes Löschen.
6. Bestehende CHECKPOINT.md, DEVELOPMENT_STATUS.md, CHANGELOG.md und ROADMAP.md enthalten historische Zwischenstände und gelten nicht automatisch als aktueller Head-Nachweis.

## 7. NÄCHSTER KONKRETER ARBEITSSCHRITT

**Empfohlenes erstes Arbeitsziel: Outbox-Einstellungen unter konkurrierenden Schreibern absichern (kleines Integration-/SQLite-Inkrement).** Vor der Umsetzung das Problem reproduzieren, prüfen, ob andere Entwickler bereits daran arbeiten, und die tatsächliche Priorität anhand aktueller CI neu bewerten. Wenn die CI rot ist, deren Fehler vorrangig beheben.

**Definition of Done:**
1. Reproduzierbarer SQLite-Test zeigt das Risiko zweier konkurrierender Einstellungen-Schreiber bzw. einer Outbox-Operation und Einstellungen-Speicherung.
2. Persistente Outbox in einen transaktionalen Datenbankpfad überführen **oder** eine nachweislich serialisierte atomare Alternative einführen; bestehende Spielstände/Settings nicht verlieren.
3. Bei schemaVersion-/Datenbankschemaänderung explizite Migration und Neustarttests für bestehende SQLite-Dateien; alte App-Versionen nicht fälschlich als kompatibel versprechen.
4. Abgedeckt: offene Handlung laden, vor Ausführung speichern, Acknowledgement entfernen, kampagnengetrennter Betrieb, gleichzeitige Änderungen, Datenfehler, Rollback, KI-Erzähler nicht doppelt automatisch anfordern.
5. Vollständige lokal verfügbare Tests und GitHub-CI auf finalem PR-HEAD grün; echte Android-Geräteabnahme separat als offen dokumentieren.
6. Dieses Dokument und die aktuelle README-Sektion mit konkreten Commits, Runs, offener Risikoliste und anschließendem Arbeitspaket aktualisieren.

**Prüfkommandos:**
- python3 scripts/verify_project.py
- python3 scripts/check_domain_boundaries.py
- python3 scripts/srd_coverage.py --json
- python3 -m unittest discover -s scripts/tests -v
- cd backend && npm ci && npm run typecheck && npm run build && npm test
- cd app && flutter pub get && flutter analyze && flutter test && flutter build apk --debug
- Android-Gradle-Tests und ABI-Alpha-Build wie .github/workflows/android-build.yml

## 8. Eintragsschema für künftige Updates

Zuletzt aktualisiert: 2026-10-23 (Initialversion; zukünftige Bearbeiter setzen genaue Uhrzeit/Zeitzone).

Vor jedem späteren Commit **oben** ergänzen/ersetzen: ISO-Zeit; main SHA; Arbeits-HEAD; PR-Links; App-Version; Anforderung und Entscheidung; Änderungspfade; IMPLEMENTIERT; GETESTET mit Link/SHA; NICHT GETESTET; BLOCKIERT; NOCH NICHT IMPLEMENTIERT; Datenmigration; Artefakte nur bei Existenz; die nächste konkrete Aufgabe. Historische geprüfte Runs als Historie behalten, aber nicht als Nachweis für spätere Commits darstellen.

**Historischer Beleg:** Baseline 2026-10-23, Version 0.8.30+80, Main-CI #39932399488 success auf b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9; Zeitpunkt vor eigenem Dokumentationsbranch.