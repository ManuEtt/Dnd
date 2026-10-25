## 24.10.2026 – Integrationsstand der fünf offenen PRs #159–#163

**IMPLEMENTIERT im Integrationsbranch:** alle jeweils unabhängig abgenommenen Produktänderungen (Sending W100, Schurken-Nebenhandbestätigung, Story-Endstatus, Rate-Limiter-Kapazität, wörtliche Geheimnisprüfung) und Regressionstests in einem gemeinsamen Codebaum; parallele Dateien der eigentlichen Features überschneiden sich nicht. Die originalen Detailberichte der fünf PRs stehen direkt unter diesem Eintrag und werden nicht verworfen. Die App-Version 0.8.38+88, SQLite 2 und Export-JSON 1 bleiben unverändert.

**GETESTET:** die jeweiligen Einzel-PR-Workflows waren grün; gemeinsame CI des Integrationsbranches bis zu deren tatsächlichem Abschluss nicht behaupten. **NICHT GETESTET:** finale kombinierten Android-/Flutter-/Backend-Gates und echtes Android-Gerät. **BLOCKIERT:** physischer Gerätetest, Produktionssignierung. **NOCH NICHT IMPLEMENTIERT:** vollständiges SRD-5.2.1-Regelwerk, generelle Positionsverwaltung, semantischer Geheimnisschutz und Mehrinstanz-Backendlimitierung. **NÄCHSTER SCHRITT:** integrale CI grün prüfen; Review und anschließende Integration erst nach explizit geprüfter Freigabe.

---

## 24.10.2026 – Geheimnis-Leak-Schutz am KI-Kampagnenausgang (PR #163)

**IMPLEMENTIERT:** Backend-Guard in `story_secret_guard.ts` und `app.ts`: Beim Story-Start und in Fortsetzungen vollständige wörtliche Enthüllungen des internen Kampagnen-Secrets in sichtbaren Textfeldern fail-closed ablehnen; Normalisierungsvarianten abdecken, aber keine semantische Garantie. Neue HTTP-/Unit-Tests geschrieben; `stateChanges: []` und Regelautorität bleiben unverändert. **GETESTET:** bislang nur vorheriger anderer PR #162 CI #40115897734 vollständig grün. **NICHT GETESTET:** finaler PR-#163-Workflow und realer Android-Test. **BLOCKIERT:** echtes Testgerät, produktive Signatur. **NOCH NICHT IMPLEMENTIERT:** lokal bestätigte Story-Geheimnisfreigabe oder semantische Erkennung. Keine Datenmigration: App 0.8.38+88, SQLite2/JSON1. Eigener [PR #163](https://github.com/ManuEtt/Dnd/pull/163), offene PRs #159–#162 erhalten. [Details](docs/STORY_SECRET_OUTPUT_GUARD_20261024.md). **Nächster Schritt:** gesamte neue CI prüfen und erst nach Erfolg PR reviewbereit machen.

---

## 24.10.2026 – Backend-Rate-Limiter vor aktiver Quotenverdrängung geschützt (PR #162)

**IMPLEMENTIERT:** Der bisher aktive Eintrag in `WindowLimiter` wird bei voller Kapazität nicht mehr verdrängt; abgelaufene Slots werden aufgeräumt, andernfalls neue Schlüssel fail-closed abgelehnt. Vorhandene Schlüssel bleiben begrenzt. Zwei neue Backend-Regressionen schützen Kontingentverbrauch, wechselnde Identitäten, Ablaufgrenzen und Zeitsprünge. Eigenständiger [PR #162](https://github.com/ManuEtt/Dnd/pull/162) basierend auf `main=b60ffe7`, offene PRs #159–#161 erhalten.

**GETESTET:** vorherige [PR-#161-CI #40113090963](https://github.com/ManuEtt/Dnd/actions/runs/40113090963) grün, jedoch anderer Quellstand. **NICHT GETESTET:** endgültige PR-#162-Backend-/Android-CI bis zum echten Nachweis; physisches Android-Gerät und Signierung. **BLOCKIERT:** Geräteabnahme/Produktivschlüssel. **NOCH NICHT IMPLEMENTIERT:** mehrere Backends mit zentral verwalteter Quote. Version 0.8.38+88, SQLite2/Export-JSON1 und SRD-Anforderungsstatus unverändert.

**Ein nächster Schritt:** finalen PR-#162-CI-Lauf auswerten, Fehler beheben, danach zur Review freigeben. [Checkpoint](docs/CODEX_CHECKPOINT.md) · [technischer Beleg](docs/BACKEND_LIMITER_CAPACITY_20261024.md).

---

## 24.10.2026 – Backend-Story-Statuskontinuität, PR #161

**IMPLEMENTIERT:** `parseStoryTurn` verhindert, dass eine Anbieterantwort bestehende `resolved`- oder `abandoned`-Stränge ohne manuelle Spieleränderung in einen anderen Status zurückversetzt; idempotente Notizen und zuvor lokal bestätigtes `open` bleiben erlaubt. Zwei neue Backendtests mit HTTP-Fail-Closed-Prüfung. Eigener [PR #161](https://github.com/ManuEtt/Dnd/pull/161) auf Basis `main=b60ffe7`, PR #159 und #160 unangetastet. **GETESTET:** neue CI ausstehend; die grüne CI von PR #160 ist nur ein älterer, anderer Quellstand. **NICHT GETESTET:** finales Backend/Android-Gesamtergebnis und echtes Gerät. **BLOCKIERT:** physische Geräteabnahme und produktive Signierung. **NOCH NICHT IMPLEMENTIERT:** allgemeine KI-Verwaltung von Spielerentscheidungen, SRD-Vollständigkeit. Keine Änderung an 0.8.38+88 / SQLite2 / JSON1. **Nächster Schritt:** finale PR-#161-CI prüfen, Fehler beheben, für Review freigeben. [Checkpoint](docs/CODEX_CHECKPOINT.md).

---

## 24.10.2026 – Nachtrag: vollständige CI-Abnahme PR #160

**Vollständige GitHub-CI [#40099238901](https://github.com/ManuEtt/Dnd/actions/runs/40099238901): completed/success** auf geprüftem PR-HEAD `5563c60ba0dbbd1f12a19877f62581a51485b6d9` (24.10.2026). **1.514 Flutter-, 100 Python- und 31 Backend-Tests bestanden**; Dart-Formatierung 357 Dateien ohne Änderungen, Flutter-Analyse und Backend-Typecheck/Build erfolgreich. Android-Debug-APK, native Gradle-Tests und ARM64/ARMv7/x64-Alpha-APKs erfolgreich; letzte Artefaktschritte abgeschlossen. Ein echter Android-Gerätetest, ein Altspielstand-Upgrade und produktive Signierung fehlen weiterhin. Dieser Nachtrag berichtet die nach dem damaligen Vorab-Checkpoint eingetroffene finale Abnahme.

[Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40099238901/artifacts/12562551949) · [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40099238901/artifacts/12561909697) · [Alpha-Release](https://github.com/ManuEtt/Dnd/actions/runs/40099238901/artifacts/12562517123) · [Quellcode-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40099238901/artifacts/12562163517). Die SHA256-Digests der GitHub-Artefaktarchive sind **nicht** automatisch Einzel-APK-Prüfsummen.

---

## 24.10.2026 – PR #160: kontrollierter Hinterhältiger Angriff mit Nebenhand-Verbündetenquelle

**IMPLEMENTIERT:** Regel-/Import-Grenze `SneakAttackAllyRules.eligible` und `PendingRoll.fromJson` akzeptieren zulässige Nebenhandangriffe mit separat bestätigtem Verbündeten; echte angreifende Waffe und bereits reservierte Bonusaktion erforderlich. Gleiche Kampagnen-/Ziel-/Wurfbindung, Bestätigungs- und Entfernungs-Controller, UI-Anzeige auch für Nebenhand, unveränderter atomarer SQLite-Kampfabschluss. **GETESTET:** Vorläufer-CI bis einschl. Flutter-Analyse/Widgets, 1.513 bestandene Flutter-Tests, 1 fehlgeschlagene zu breite JSON-Assertion – inzwischen gezielt korrigiert; **keine finale neue CI-Erfolgsbehauptung**. **NICHT GETESTET:** finaler CI-/APK-HEAD, echtes Android-Gerät und Altspielstand-Upgrade. **BLOCKIERT:** lokal kein Flutter/Dart oder eigener Android-Test. **NOCH NICHT IMPLEMENTIERT:** vollautomatische Positions-/Gelegenheitsangriffe und vollständige SRD.

Der Code nutzt SRD 5.2.1 Rogue/Sneak Attack S.61–62, `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt `partial`. App `0.8.38+88`, SQLite 2 / JSON 1 ohne Migration. Branch `feature/sneak-attack-offhand-ally-20261024`, offener [PR #160](https://github.com/ManuEtt/Dnd/pull/160); PR #159 (Sending) bleibt unabhängig und grün. Nächster Schritt: PR160-Code in vollständiger CI inklusive Android nachprüfen, Fehler beheben und für Review freigeben. [Checkpoint](docs/CODEX_CHECKPOINT.md).

---

## 24.10.2026 – Sending-W100-Dialog an autoritative Regelprüfung angeglichen (PR #159)

**IMPLEMENTIERT:** `sending_attempt_dialog.dart` stellt die manuelle Ebenen-W100-Eingabe nur bei bestätigter anderer Ebene **und** bestätigter Nichtblockade bereit. Die Vorschau erhält denselben Vorfilter. Ein Blockadewechsel löscht einen früheren W100 und setzt die explizite Zustimmung zurück. Keine Story- oder Regelmoduländerung; keine KI-Autorität über bestätigte Daten.

**TESTS ERGÄNZT:** Zwei Widgettests sichern unbekannte/blockierte/nicht blockierte Empfänger, Neuprüfung, W100-Löschung, Zurücksetzen der Zustimmung und unveränderten Vorschaufluss ab. **GETESTET:** Quelltextabgleich mit bestehender `SrdSendingRules.assessDelivery`; bisherige Main- und Schurken-CI sind keine Freigabe dieser Änderung. **NICHT GETESTET:** Neue Flutter-Suite, Android-Debug-/APK-Build und physisches Gerät bis zur finalen CI/Abnahme. Ein früherer PR-Lauf scheiterte an Dart-Formatierung; Formatkorrektur am Test wurde vorgenommen, erneuter Lauf ausstehend. **BLOCKIERT:** Lokal kein Flutter-/Dart-SDK; GitHub-Actions-Abnahme notwendig. **NOCH NICHT IMPLEMENTIERT:** echte Sending-Zustellung, Empfängerantwort und automatische 8h-Weltzeitsperre.

**Git:** Basis-main `dcb42c5`, während der Arbeit PR #158 als Main-Merge `b60ffe7` integriert; Feature-Branch ohne Force-Push mit Main zusammengeführt, [PR #159](https://github.com/ManuEtt/Dnd/pull/159) offen. Version 0.8.38+88, SQLite2/JSON1 unverändert, kein Migrationseingriff.

**Nächster konkreter Schritt:** Den vollständigen GitHub-CI-Lauf des finalen PR-#159-HEAD einschließlich Dart-Format, Flutter-Widgettests, Android und SQLite überprüfen, auftretende Fehler beheben, erst dann PR zur Integration freigeben.

---

## 24.10.2026 – 0.8.38+88: tatsächliche Nebenhandwaffe für Hinterhältigen Angriff

Die vorhandene Nebenhandauflösung prüft jetzt ihre bestätigte Inventarwaffe auf Finesse/Fernkampf. Ein Hauptdolch verleiht einer Nebenhandaxt keinen Zusatzschaden; ein Nebendolch verliert seine Eignung nicht durch eine Haupthandaxt. Krit/Miss und bestehende gemeinsame Zugnutzung bleiben erhalten. 27 bestehende/Helper- und acht neue Kampf-/SQLite-Tests erfolgreich. Vollständige lokale Abnahme: 1505 Flutter-,100 Python-,31 Backend- und12 native Tests erfolgreich, Format/Analyse/Importgrenzen ohne Befund. Neue Debug-APK und ARM64-Alpha gebaut und geprüft. Eigene finale GitHub-Checks am PR158 getrennt geführt; Realgerät nicht getestet. SQLite2/JSON1 kompatibel. Details und nächstes Paket: [CODEX_CHECKPOINT](docs/CODEX_CHECKPOINT.md).

---

## 24.10.2026 – Sending-Dialog in der Abenteueransicht (PR-CI ausstehend)

- **IMPLEMENTIERT:** Widget `SendingAttemptDialog` für ausdrücklich bestätigte Nachricht, Empfänger, Klasse, Slot, Kreatur, Komponenten, Aktionsökonomie und beobachtete Blockade/Ebenenfakten. Direkte Verbindung zur vorhandenen, idempotenten SQLite-`confirmSendingAttempt`-API. Bei Textänderung Zustimmung erneut erforderlich; Erfolg nur bei auditierbarem Beleg, keine Zustellungserzählung.
- **GETESTET:** Ausgangsbasis `main` `3b5affde4bf4ff5be24ab31f1c4ec39412f66867`, [GitHub CI #40084074765](https://github.com/ManuEtt/Dnd/actions/runs/40084074765) **success**.
- **NICHT GETESTET:** Neu implementierter UI-Code und fünf Widget-/SQLite-Szenarien bis zur neuen CI; reale Geräteabnahme, Upgrade-/Signierungsversuche.
- **BLOCKIERT:** Flutter-/Android-SDK lokal nicht installiert, reales Android-Gerät nicht verfügbar.
- **NOCH NICHT IMPLEMENTIERT:** Tatsächliche Sender-zu-Empfänger-Zustellung, NPC-Reaktion, 8h-Sperr-Zeitlogik und Sending im Kampf.
- **KOMPATIBILITÄT:** SRD `SPELL-ENTRY-SENDING` bleibt `partial`; Flutter-App 0.8.37+87, SQLite 2, Kampagnen-JSON 1 unverändert.
- **NÄCHSTER SCHRITT:** PR-Head per Android/Flutter-CI abnehmen, Dialog-/Formatfehler beheben, anschließend Merge. Keine unbeaufsichtigte Hintergrundarbeit.

---

## 24.10.2026 – Sending-Versuch mit SQLite-Quittung erfolgreich in GitHub-CI geprüft

- **IMPLEMENTIERT:** Die Regeln verbuchen nach bestätigtem originalen Preview-Snapshot einen Sending-Slot und `spell.sending.attemptConfirmed` atomar; Schutz vor Doppel-IDs, alten Revisionen, unbestätigtem Text und laufenden Kämpfen. Keine KI- oder Netzwerkwirkung.
- **GETESTET:** [PR-CI #40078375498](https://github.com/ManuEtt/Dnd/actions/runs/40078375498), Code-HEAD `2566a84e`, **completed/success**, mit neuen Domain-/SQLite-Regressionen und vollständigem Flutter-/Android-/Backend-/Python-Lauf.
- **NICHT GETESTET:** Reale Installation, historischer Gerätestand, produktive Signierung; nachfolgende Dokumentations-CI noch separat zu prüfen.
- **BLOCKIERT:** Kein Android-Gerät/lokales Android-/Flutter-SDK.
- **NOCH NICHT IMPLEMENTIERT:** UI-Bestätigung und tatsächliche Sending-Nachrichtenübertragung/Antwort.
- **KOMPATIBILITÄT:** SQLite 2, Export-JSON 1, Version 0.8.37+87; `SPELL-ENTRY-SENDING` weiterhin partial.
- **NÄCHSTER SCHRITT:** PR-Review nach Dokumentations-CI; dann eigenständiger Sending-Dialog mit Nutzerbestätigung, 360dp, Abbruch und Replay-Prüfung.

---

## 24.10.2026 – Sending-Cast-Bestätigung/Slot/Journal (Draft-PR #156)

- **IMPLEMENTIERT:** Eigener bestätigter Sending-Versuch außerhalb von Kämpfen und offenen Würfen; Snapshot-/Anfrage-ID-Schutz, Slotverbrauch durch Rule-Engine und lokale atomare SQLite-Journalbuchung. Wiederholte Anfragen nach Neustart über vorhandenen Beleg idempotent. Kein Netzwerk-/KI-Effekt.
- **GETESTET:** Main-CI #40074505420 und ältere unabhängige PR #155 erfolgreich, **nicht** als Test dieses neuen Codes. Neue CI braucht eigenen Erfolgsnachweis.
- **NICHT GETESTET:** Neue Domain-/SQLite-Tests, Formatter, Flutter-Analyse/-Gesamttest, Android-/APK/Realgerät bis CI/Build abgeschlossen ist.
- **BLOCKIERT:** Lokal kein Flutter-/Android-SDK und kein Testgerät.
- **NOCH NICHT IMPLEMENTIERT:** Endnutzer-Dialog und tatsächlicher externer Sending-Transport samt Empfängerantwort; keine Kampfaktualisierung.
- **VERSION UND SICHERHEIT:** SRD `SPELL-ENTRY-SENDING` bleibt partial, App 0.8.37+87, SQLite 2, JSON 1, keine Migration.
- **NÄCHSTER SCHRITT:** PR-#156-CI auf dem letzten Code- und Dokumentations-Head vollständig auswerten, rote Tests reparieren, Review erst nach nachgewiesener Code-Abnahme.

---

## 24.10.2026 – Aktiver Sending-Unicode-Sicherheitszyklus (PR #155)

- **LIVE:** main `b6b0fdb` (PR #154 bereits integriert), neuer Draft-PR [#155](https://github.com/ManuEtt/Dnd/pull/155). Main-Workflow #40074505420 bei Beginn noch aktiv.
- **IMPLEMENTIERT:** Neue Fail-Closed-Sperren gegen unsichtbare Unicode-Zeichen in Nachricht und Empfänger-ID, plus Domain-/Integrationstests; SRD-ID `SPELL-ENTRY-SENDING` weiterhin partial.
- **GETESTET:** JS-RegExp-Sanity-Check. Vorherige vollständige grüne CI [#40072501279](https://github.com/ManuEtt/Dnd/actions/runs/40072501279) auf `05fc6dd` belegt diesen PR nicht.
- **NICHT GETESTET:** Dart-Format, Flutter-Tests/Analyse, Android-/APK-Build und Realgerät auf neuem Branch.
- **BLOCKIERT:** Dart-/Flutter-/Android-SDK und reales Testgerät lokal nicht verfügbar.
- **NOCH NICHT IMPLEMENTIERT:** Persistenter tatsächlicher Sending-Cast und Nachrichtenzustellung.
- **KOMPATIBILITÄT:** 0.8.37+87, SQLite 2 und Export-JSON 1 unverändert.
- **NÄCHSTER SCHRITT:** Finale GitHub-CI für PR #155 auf letzter Revision prüfen und gegebenenfalls reparieren, bevor der PR für Integration freigegeben wird.

---

## 24.10.2026 – Sending-Vorprüfung: vollständige Flutter-/Android-CI erfolgreich

- **GETESTET:** [GitHub-Actions #40071729227](https://github.com/ManuEtt/Dnd/actions/runs/40071729227) **completed/success** auf funktionalem Code `efed3d732459478b072452ab8e92ef3c674e39fd`: Python/Backend, Dart-Format/Analyse, Flutter-Gesamtsuite einschließlich neuer Klassen-/Slot-/Komponenten-/W100-Tests, Android-Debug, native Tests, ABI-APKs, vollständige Release- und Source-Artefakte. [PR #154](https://github.com/ManuEtt/Dnd/pull/154) ist weiterhin offen und konfliktfrei, `main` unverändert.
- **NICHT GETESTET:** echtes Android-Gerät, historische Backups im Upgradepfad und ein tatsächlich verbuchter Sending-Zauber. **BLOCKIERT:** kein lokales SDK/Handy. **NOCH NICHT IMPLEMENTIERT:** Cast-Transaktion, Slot-/Aktionsevent, Nachrichtenzustellung.
- **KOMPATIBILITÄT:** Flutter-App 0.8.37+87, SQLite 2, JSON 1 unverändert. **NÄCHSTER SCHRITT:** PR-Review und separates bestätigtes Cast-Inkrement.

---

## 24.10.2026 – Sending-Rule-Komposition ohne Ressourcenmutation

- **IMPLEMENTIERT:** Reiner `SrdSendingCastPreflightRules` integriert den Sending-Validator mit bestehender `SrdSpellPreflightRules`-Klassen-/Slot-/Komponentenprüfung und danach der Blockade-/Ebenen-W100-Prüfung. Katalogmetadaten werden gegen stille Pflichtkomponenten-Änderungen geschützt; Ergebnis bleibt read-only.
- **TESTS GESCHRIEBEN:** `srd_sending_cast_preflight_test.dart` mit sieben fachlichen Gegenprüfungen. **GETESTET:** Main-Basis `da80d3f2`, GitHub-CI #40069427402 success. **NICHT GETESTET:** neuer Featurecode bis eigener CI, echter Geräteeinsatz. **BLOCKIERT:** kein lokales SDK. **NOCH NICHT IMPLEMENTIERT:** Casting, Ressourcen-/Aktionstransaktion, Zustellung/Antwort und Acht-Stunden-Timer.
- **KOMPATIBILITÄT:** SRD-Arbeits-ID `SPELL-ENTRY-SENDING` bleibt partial. DB 2, JSON 1, Version 0.8.37+87 unverändert. **NÄCHSTER SCHRITT:** PR-CI auf finalem Code-HEAD, Fehler beheben, danach konkretes Cast-Integrationspaket.

---

## 24.10.2026 – Vollständige CI-Abnahme der Sending-Eingabeintegrität

- **GETESTET:** [PR-CI #40068321150](https://github.com/ManuEtt/Dnd/actions/runs/40068321150), Code-HEAD `fb96641db97598a5ee1b59416ad254f5e0e63e29`, **completed/success**: Python, Backend, Dart-Format, Flutter-Analyse, vollständige Flutter-Suite inklusive Unicode-Grenztests, Android-Debug-Build, native Tests, kleine Alpha-APKs, versioniertes Alpha und Source-Checkpoint. [PR #153](https://github.com/ManuEtt/Dnd/pull/153) bleibt für Review offen; `main` unverändert.
- **NICHT GETESTET:** reale Installation/Upgrade und tatsächliche Sending-Zauberausführung. **BLOCKIERT:** kein Testgerät/Flutter-SDK lokal. **NOCH NICHT IMPLEMENTIERT:** vollständige Zauber-Aktions-/Slot-/Kommunikationswirkung. **KOMPATIBILITÄT:** App 0.8.37+87, SQLite 2 und JSON 1 unverändert.
- **NÄCHSTER SCHRITT:** Review des fertig geprüften Sicherheits-PRs; danach getrennte SRD-Spellcast-Implementierung.

---

## 24.10.2026 – Sending-Eingaben gegen verdeckte Zeichen absichern

- **IMPLEMENTIERT:** Die bestehende lesende SRD-Sending-Vorprüfung verwirft versteckte Unicode-Separatoren/Bidi-Kontrollen, Steuerzeichen und Nachrichten über 2048 UTF-16-Einheiten (technischer Grenzwert). Empfängerkennungen mit inneren Leerzeichen/unsichtbaren Zeichen werden gesperrt. 25-Wörter-Regel, Zeilenumbrüche und Umlaute bleiben erhalten.
- **TESTS GESCHRIEBEN:** vier neue Regressionen für 25 reguläre Wörter, versteckte 26-Wort-Kette, problematische Unicode/ASCII-Steuerzeichen, Nachrichtenlänge 2048/2049 und Empfängerkennung. **GETESTET:** Main-CI #40066464900/#40066464899 vor Änderung vollständig grün. **NICHT GETESTET:** neuer Code vor PR-CI, echte Android-Geräte. **BLOCKIERT:** kein lokales Flutter/Android-SDK. **NOCH NICHT IMPLEMENTIERT:** wirklicher Sending-Zauber, Slots, Weltzeit und Nachrichtenzustellung.
- **KOMPATIBILITÄT:** App 0.8.37+87, SQLite 2, JSON-Schema 1 unverändert. **NÄCHSTER SCHRITT:** finale Code-CI prüfen und ggf. reparieren.

---

## 24.10.2026 – Fantasy-Bestätigungsdialog für EP-Belohnungen auf neuer Integrationsbasis

- **IMPLEMENTIERT:** Der Dialog aus PR #151 ist in die erhaltene Abenteueransicht mit Schurken-/Kampflogik, XP-Ereignisschutz und unabhängiger Sending-Vorprüfung integriert: bestätigte Kennung und Betrag, Vorschau, separate Checkbox-Zustimmung, stabile Request-ID und Buchungsquittung nur bei gespeichertem Ereignis.
- **REGRESSIONSTESTS ÜBERNOMMEN:** `app/test/experience_reward_dialog_test.dart` mit Abbruch, 320dp/Schriftvergrößerung, Duplikat-/Neustart und echtem SQLite-Commit. **GETESTET:** der ursprüngliche Branch besitzt nur die jeweils einzeln belegten GitHub-CI-Ergebnisse. **NICHT GETESTET:** der kombinierte neue Stand bis zur vollständigen eigenen CI und reales Android-Gerät.
- **KONSOLIDIERUNG:** PR #150 bietet eine alternative, überlappende Darstellung derselben XP-Interaktion; vor dessen Schließung wird noch der tatsächliche Funktions-/Testumfang mit dem übernommenen PR #151 abgeglichen. Keine doppelte XP-Aktion in der App erzeugen.

## 24.10.2026 – Unabhängigen SRD-Sending-Regelkern übernommen

- **IMPLEMENTIERT:** Die reine Regelvorprüfung für den SRD-5.2.1-Zauber `Sending` prüft bestätigten Kreaturenempfänger, Wissensnachweis, 1–25 Wörter, bestätigte Blockade und den extern nachgewiesenen W100-Ebenenwurf (1–5 verfehlt; 6–100 erfolgreich). Keine KI-generierte Regelwirkung, keine automatische Nachrichtenzustellung und keine SQLite-Mutation.
- **TESTS ÜBERNOMMEN:** `app/test/srd_sending_rules_test.dart`; ursprüngliche vollständige CI von PR #144 auf `83a56383` war erfolgreich. **NICHT GETESTET:** neuer, mit den EP-/Schurkenänderungen vereinter HEAD bis zur eigenen CI.
- **INTEGRATION:** öffentliche Fassade `rules_api.dart`, Anforderungsregister und `docs/SRD_SENDING_MESSAGE_RULES_20261023.md`. Die aktuelle App-Version `0.8.37+87` wird nicht auf die ältere Branch-Version `0.8.36+86` zurückgesetzt.

## 24.10.2026 – Integrierte EP-Sicherung auf aktuellem Schurken-/Kampfstand

- **IMPLEMENTIERT:** Die bisher getrennten Korrekturen aus PR #149 wurden gegen `main` `f99f27ac` als konfliktaufgelöster Merge zusammengesetzt: fehlerhafte Rabenwacht-XP-Marker werden abgelehnt; `GameEngine.confirmExperienceReward` und `GameController.confirmExperienceReward` sichern ausschließlich ausdrücklich bestätigte, idempotente XP-Ereignisse und SQLite-Revisionsrennen.
- **REGRESSIONSTESTS ÜBERNOMMEN:** beschädigte Marker und SQLite-Neustart, Request-ID-Duplikate, abweichende Belohnungen, konkurrierende Controller, Rollback und alte Revision. Die zuvor in `main` integrierte Schurken-/Kampfimplementierung bleibt erhalten.
- **GETESTET:** Vorläufer-PR #149 hatte erfolgreiche GitHub-CI auf `cfea52f2`; `main` hatte erfolgreiche CI auf `f99f27ac`. **NICHT GETESTET:** die jetzt neu zusammengeführte Kombination bis zum eigenen GitHub-Actions-Lauf. Kein reales Android-Gerät geprüft.
- **KOMPATIBILITÄT:** DB-Schema 2 und Export-JSON-Schema 1 bleiben unverändert. Fantasy-EP-Dialoge der alternativen PRs #150/#151 sind noch getrennt zu prüfen; SRD-Sending aus PR #144 bleibt unabhängig.

## 24.10.2026 – Integration des Main-XP-Fixes aus PR #145

Main1c2eeab wird mit dem bestehenden Sneak-Attack-Paket vereinigt. XP-Belohnungs-ID und Betrag müssen bei einer Wiederholung zusammenpassen; beschädigte Belege werden ohne Mutation abgewiesen. Die zwei Main-Regressionstests bleiben erhalten. Neue gemeinsame Prüfung ausstehend; bisherige Nachweise beziehen sich auf bfc991f vor dieser Integration.

---

## Aktuell – 0.8.37+87, 23.10.2026

Basis main5958579, Code0a56aba, Branch feature/sneak-attack-ally-integration-20261023. Operative Fakten und Wiederaufnahme: [docs/CODEX_CHECKPOINT.md](docs/CODEX_CHECKPOINT.md); ältere Einträge unten sind datierte Historie.

**IMPLEMENTIERT:** Hauptwaffen-Sneak-Attack über bestätigten Verbündeten mit echter UI, ziel-/wurfgebundener Speicherung, Schadensauflösung und Revisionsschutz. Die bestehende Regel-/Story-Grenze verhindert narrative Bestätigungen.

**GETESTET:** 1.431 Flutter-Tests der normalisierten Basis, 11 neue Domain-/SQLite- und 6 neue Widgettests, aktuelle Analyse/Formatierung, Python100 und Backend31. Vollständige neue Suite mit **1.448 Flutter-Tests erfolgreich**; Debug-APK inklusive CRC/Metadaten/Signatur und12 native Tests erfolgreich; [PR147](https://github.com/ManuEtt/Dnd/pull/147) erstellt, [Code-CI40056875863](https://github.com/ManuEtt/Dnd/actions/runs/40056875863) auf182f44b vollständig erfolgreich, Realgerät nicht getestet. ARM64-Alpha19,7MB erfolgreich gebaut und geprüft. Frühere Item-WIP-Dateien separat gesichert, kein Überschreiben aktueller Main-Modelle.

**NÄCHSTER KONKRETER SCHRITT:** Tatsächlich angreifende Nebenhandwaffe für Sneak-Attack-Eignung verwenden und denselben sicheren Bestätigungspfad anbinden; aktuelle Hauptwaffe, alte Spielstände und einmalige Zugnutzung regressionsfrei erhalten.

---

## 23.10.2026 – Schurken-Hinterhältiger-Angriff nach SRD 5.2.1 sichern (CI offen)

- **IMPLEMENTIERT:** `ClassCombatFeatures.eligibleSneakAttackDice` verlangt bei Angriff ohne echten Vorteil zwei unabhängige Bestätigungen: ein Verbündeter befindet sich höchstens 5 Fuß vom ZIEL entfernt und er besitzt nicht `Incapacitated`. Kein stilles Auslösen aus bloßer Bewusstheit oder Nähe zur Spielfigur. Ergänzte Negativtests bei gestunnten/fehlpositionierten Verbündeten und beim Aufheben von Vorteil/Nachteil.
- **QUELLE:** SRD 5.2.1, Rogue/Sneak Attack S. 62, CC BY 4.0. Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` ist nur `partial`, keine Vollständigkeitsbehauptung: `GameEngine` hat noch keine Positions- und Ally-Condition-Integration; automatisch nur bestätigte Angriffe mit Vorteil aus ihrem bisherigen Pfad.
- **BASIS:** Main `f71c287e` nach PR #142. Neuer Branch `fix/srd-rogue-sneak-attack-ally-20261023`, Version `0.8.36+86`, CI noch ausstehend. Ohne DB-Migration oder neue Kampagnen-JSON-Version. Kein Geräte-, Altspielstand- und Release-Signaturtest.
- **NÄCHSTER SCHRITT:** neuen CI-Lauf prüfen, Fehler beheben; dann in separatem Inkrement bestätigte Karte/Verbündetenstatus im Kampfdialog und im Journal verarbeiten.

---

## 23.10.2026 – SRD Sight als ausdrücklich bestätigte Zauberreichweite (CI ausstehend)

- **IMPLEMENTIERT:** Reine regeltechnische `Sight`-Vorprüfung für verifiziert sichtbaren Zauberursprung und getrennt bestätigten freien Weg; Kartenprüfer transportiert den vom Spieler/Spielleiter bestätigten Sichtfakt ohne Annahme aus Hindernissen. Keine neuen Zauberwirkungen, Automatikwürfe oder Ressourcenbuchungen. `Unlimited`/`Special` bleiben ausdrücklich nicht freigeschaltet.
- **TESTS GESCHRIEBEN, CI OFFEN:** `app/test/srd_spell_target_rules_test.dart` und `app/test/srd_spell_grid_target_rules_test.dart`, einschließlich weiterhin gesperrter Sonderreichweiten, Sicht-/Deckungsfehler und unveränderter Katalogabdeckung. Keine lokale Flutter-/Geräteausführung. [SRD Sight Dokumentation](docs/SRD_SIGHT_RANGE_PREFLIGHT_20261023.md) und Maschinenregister führen diese Regel als `partial`.
- **BASIS:** `main` `2dac48e0` nach Integration von #140/#141, App `0.8.34+84`. Feature-Branch-Version **0.8.35+85**. Basis-PR-CI #40004287299 erfolgreich; Main-Merge-CI #40008013311 war zu Beginn noch offen.
- **NICHT GETESTET:** neue vollständige CI, Android-Gerät, echte Spellcast-UI und alle übrigen SRD-Regeln. **BLOCKIERT:** kein Android-Gerät. **NÄCHSTER SCHRITT:** neue CI prüfen und Fehler korrigieren; nach Review integrieren, 3D/Sicht- und Spezialreichweiten später einzeln implementieren.

---

## 23.10.2026 – Bestandsmigrationstests mit atomarer Kampagnenlöschung vereinigt

- **IMPLEMENTIERT:** Neue `app/test/populated_legacy_upgrade_test.dart` deckt SQLite-v1→v2-Migration mit tatsächlich gespeicherter Kampagne, Revisionsjournal, Events, Charakterarchiv, Settings und älterer Outbox ab. Zusätzlich erzwingt ein Duplikat-Request-ID-Test den kompletten Upgrade-Rollback.
- **GETESTET:** PR #140 CI [#39968525780](https://github.com/ManuEtt/Dnd/actions/runs/39968525780) erfolgreich; PR #141 auf altem Stand CI [#39994226404](https://github.com/ManuEtt/Dnd/actions/runs/39994226404) vollständig erfolgreich. **NICHT GETESTET:** neuer Merge-HEAD bis zu dessen CI und Android-Geräteupgrade mit altem Spielstand.
- **MAIN:** `a3dec619` nach Integration von #140, App `0.8.34+84`. **BLOCKIERT:** kein reales Gerät / keine lokale Android-Installation; **NOCH NICHT IMPLEMENTIERT:** reale Backup-/Restore-Abnahme. **NÄCHSTER SCHRITT:** CI des auf `main` aktualisierten #141 und endgültigen Main-Merge prüfen.

---

## 23.10.2026 – Kampagnenlöschung schützt gleichzeitig gespeicherte Auswahl (CI ausstehend)

- **IMPLEMENTIERT:** `AtomicCampaignDeletion` mit `SqliteCampaignRepository.deleteCampaignAndReconcileSelection` führt Löschung samt Outbox und selektivem `lastCampaignId`-Cleanup in einer SQLite-Transaktion aus. Der Controller schreibt die Auswahl bei SQLite nicht erneut, wodurch eine andere gleichzeitig gewählte Kampagne nicht überschrieben wird.
- **TESTS ANGELEGT, NICHT LOKAL AUSGEFÜHRT:** `app/test/atomic_campaign_deletion_test.dart`: ausgewählte/nicht ausgewählte Kampagnen, parallele Auswahländerung durch getrennte SQLite-Repository-Instanzen, ausstehende Spielerhandlung, Neustart und ABORT-Trigger für Settings-Rollback.
- **BASIS:** `main` `4061d651`; [Main-CI #39967425937](https://github.com/ManuEtt/Dnd/actions/runs/39967425937) zum Start noch nicht abgeschlossen. Frühere PRs #133–#136 nach `main` integriert; Test-PR #137 geschlossen ohne Merge. **NEUE CODE-CI AUSSTEHEND.**
- **KOMPATIBILITÄT:** App `0.8.34+84`; DB-Schema 2; JSON-Formatversion 1. **NICHT GETESTET:** echter Android-Geräte-/Migrationspfad, produktive Signierung. **NÄCHSTES PAKET:** GitHub-CI auswerten, Fehler beheben; danach reale Altgerät-/Backup-Migration abnehmen.

---

## 23.10.2026 – Vollständigen Spielstand-Reset atomar ausführen (Code-CI erfolgreich)

- **IMPLEMENTIERT:** `AtomicUserDataReset` im CampaignRepository-Kontext; SQLite `deleteAllUserData()` löscht sechs lokale Nutzerdatentabellen in einer Datenbanktransaktion. Controller nutzt diesen Pfad und setzt `currentCampaign` erst nach erfolgreichem Commit auf null; Legacy-/Testimplementierungen behalten das bisherige Verhalten.
- **REGRESSIONSTESTS BESTANDEN IN GITHUB-CI:** `app/test/atomic_full_data_reset_test.dart` prüft eine vollständige Löschung samt Archiv und Eventjournal, Neustart, Wiederholung sowie SQLite-ABORT-Trigger mitten in der Löschfolge: ohne Teilverlust von Kampagne, Held, Settings, Outbox oder Journal. Kein Android-/Flutter-SDK lokal; [GitHub-CI #39946157697](https://github.com/ManuEtt/Dnd/actions/runs/39946157697) auf Code-HEAD `0145108c57c562e3a6635a2ea6440d4649278222` vollständig **success** (Python, Backend, Dart/Flutter, native Android, Debug- und Alpha-APKs). Initiale CI #39945364361 scheiterte an einer gemeinsam geschlossenen Test-DB-Verbindung und wurde durch `singleInstance:false` repariert.
- **BASIS ERFOLGREICH GETESTET:** PR #135 SHA `d8f0cf6958d5c401de9a7f12ae37e69abb45c954`, [Actions #39942663270](https://github.com/ManuEtt/Dnd/actions/runs/39942663270) completed/success. **NICHT GETESTET:** echte Android-Geräteinstallation, Nutzerdaten-Migration auf Geräten und langlebige Release-Signierung. **FORMAT:** DB-Schema 2, Kampagnen-`schemaVersion=1`; App-Version `0.8.33+83`.
- **NÄCHSTES PAKET:** Gestapelte PR-Abhängigkeiten nach Review auflösen, Android-Migration anhand eines gesicherten Altspielstands auf echtem Gerät abnehmen; kein automatisches Testlabel aus früherer CI übernehmen.

---

## 23.10.2026 – Unabhängige Settings-Schreiber transaktional absichern (CI ausstehend)

- **IMPLEMENTIERT im Entwicklungsbranch:** `AtomicSettingsStore` und SQLite-`updateSettingsEntries` speichern selektive Einstellungsfelder innerhalb einer Transaktion. `GameController` (Kampagnen-ID und Backend-Präferenzen) und `BootstrapApp` (Sprachpräferenzen) rufen `repository.patchSettings` auf; übrige Felder bleiben auch bei konkurrierenden Schreibvorgängen erhalten. Bestehender Komplett-Reset behält Full-Replace-Verhalten.
- **DATENRESET-KORREKTUR:** Persistente PlayerActionOutbox-Einträge werden beim Löschen ihrer Kampagne in derselben SQLite-Transaktion entfernt. Ein vollständiger Datenreset entfernt auch verwaiste ausstehende Handlungen; Regressionstests sind ergänzt.
- **TESTS ANGELEGT, CI NOCH OFFEN:** `app/test/atomic_settings_updates_test.dart` mit gleichzeitigen unabhängigen Schlüsseln, 24 Überschneidungen, Feldentfernung, ungültigem Patch/Rollback, PlayerActionOutbox und Neustart der Kampagnenauswahl.
- **KEINE SPEICHERFORMATMIGRATION:** DB-Schema 2 aus #134 bleibt, JSON-Exportschema 1 bleibt, App-Version `0.8.32+82`. **NICHT GETESTET:** neuer finaler CI-HEAD, APK auf Android-Gerät, Langzeitupdate. **BESTÄTIGTE BASIS:** vorangegangene CI #39940517928 ist grün für #134-HEAD `8162388e`, nicht für den neuen Branch.
- **NÄCHSTER SCHRITT:** Github-CI des neuen Stands auswerten und bei Fehlern korrigieren; anschließend gestapelte PRs in Abhängigkeitsreihenfolge reviewen und Geräteprüfung der DB-1→2-Migration separat vorbereiten.

---

## 23.10.2026 – Pending-Action-Outbox von Settings entkoppeln (Code-CI grün)

- **IMPLEMENTIERT:** SQL-Tabelle `pending_player_actions` (DB-Version 2), transaktionales Stage/Remove, Migration gültiger ausstehender Handlungen aus `pendingPlayerActionsV1` samt unveränderter Request-IDs; bestehende übrige Einstellungen bleiben erhalten. `PlayerActionOutbox` nutzt den neuen Vertrag für SQLite, Legacy-`CampaignRepository`-Implementierungen behalten ihren bisherigen Pfad.
- **GETESTET:** konkurrierende SQLite-Verbindungen und Kampagnen, stale Settings, Neustart nach Migration, Rollback bei inkonsistentem Altstand – vollständige [GitHub-Actions-CI #39938760852](https://github.com/ManuEtt/Dnd/actions/runs/39938760852) auf Code-SHA `1ca83e63c5d78c84b1babebcc15c0a392725b7a3` **success** inklusive Python, Backend, Dart/Flutter, nativen Android-Tests, Debug-APK, ABI-Alpha-APKs und Release-/Quell-Artefakten; kein lokales Flutter/Dart-SDK.
- **NICHT GETESTET:** realer Geräte-/Upgradepfad, parallele Drittanbieterabrufe und langfristige Release-Signierung; vollständige SRD-Automatisierung bleibt offen. Dokumentationsnachtrag nach dem grünen Code-Lauf separat betrachten. App `0.8.31+81`, JSON-Sicherung weiterhin `schemaVersion=1`.
- **NÄCHSTER SCHRITT:** Basis-PR #133 nach Review integrieren, #134 auf `main` umstellen und neuen CI-Lauf prüfen; anschließend separate atomare Teilupdates für andere App-Einstellungen planen. Baseline-CI auf `main` #39932399488 gehört zu `b1fa9c67`, nicht zum neuen PR.

---

## 22.10.2026 – SRD 5.2.1: Linien-AoE-Rastervorschau (PR/CI offen)

- **IMPLEMENTIERT:** Regelreine `SrdLineAreaRules` für acht Himmelsrichtungen auf bestätigter 5-Fuß-Karte mit getrennten, vom konkreten Zaubereffekt bestätigten Linienlängen/-breiten, inklusiver Rechteck/Zell-Schnittprüfung, getrenntem Mittelpunkt-/Randmerkmal und expliziter Ursprungsfeldprüfung.
- **IMPLEMENTIERT:** `previewConfirmedSpell` prüft die Zauberreichweite zum Ursprung unabhängig von den bestätigten Maßen der Linienwirkung. Ein gesperrter Zentrumstrahl erfordert Cover-Nachprüfung, ist keine endgültige Immunität.
- **TESTS ANGELEGT, CI OFFEN:** `app/test/srd_line_area_rules_test.dart` prüft Randfälle, acht-Richtungsmodell anhand mehrerer Richtungen, Grenzen, unbekannte Karte, Vollhindernisse und Lightning-Bolt-Ursprung.
- **NOCH OFFEN:** 3D/weitere Winkel, tatsächliche Raster- und Kreaturenwirkungen, Deckungsgrade, Rettungswürfe, Schaden und UI. Keine Zustand-/SQLite-Migration. Audit weiter `partial`; siehe `docs/SRD_LINE_AOE_PREVIEW.md`.

---

## 21.10.2026 – SRD 5.2.1 Kegelfläche auf 5-Fuß-Raster (CI offen)

- **IMPLEMENTIERT:** `SrdConeAreaRules` als deterministische, read-only 2D-Kandidatenauswahl für Kegel in acht ausdrücklich ausgewählten Richtungen; je Feld geometrische Mittelpunktprüfung, mögliche Randüberlappung und Deckungsprüfbedarf. Exakte Reichweite des Zauberursprungs und separat bestätigte Kegellänge werden auseinandergehalten.
- **TESTS ERSTELLT, CI NOCH OFFEN:** `app/test/srd_cone_area_rules_test.dart` mit Grenzen, Richtungen, Blockern, ungültigen/unklaren Daten und katalogisiertem `Burning Hands`. Vollständiger Flutter-/Android-Build muss vor einem Merge grün sein.
- **NOCH NICHT IMPLEMENTIERT:** frei drehbarer oder 3D-Kegel, tatsächliche Ziel-/Deckungsentscheidung, Kartenerfassung, Rettungswürfe und automatischer Schaden. SRD-Flächen/Ziele/Deckung bleiben `partial`; Dokumentation `docs/SRD_CONE_AOE_PREVIEW.md`.

---

## 21.10.2026 – Rabenwacht: Akt VIII, Epilog und Brief von Morgen (konsolidierter Integrationsbranch)

- **Implementiert:** Rat der Zeugen mit Belegschwelle und drei Enden; optionaler Epilog mit Elda, Tarek und Liora sowie drei Dorfvermächtnissen; anschließende optionale Nachgeschichte „Der Brief von Morgen“ mit drei unabhängigen Ermittlungsorten und drei Schlusswegen.
- **Einbindung:** `rabenwacht-voice-v1`, identische Campaign-Persistenz, keine SRD- oder Backend-Modifikation und kein unberechtigter EP-/TP-/Ausrüstungs-Effekt. Bestehende Main-Änderungen am D&D-Regelwerk bleiben erhalten.
- **Tests:** `app/test/rabenwacht_fourteenth_voice_act8_test.dart`, `app/test/rabenwacht_fourteenth_voice_epilogue_test.dart`, `app/test/rabenwacht_fourteenth_voice_morrow_test.dart`; alle drei Entwicklungsstufen und die konsolidierte Android-CI müssen vor Merge grün sein. Echter Geräte-/Balance-Test weiterhin offen.
- **Fachdokumentation:** `docs/RABENWACHT_AKT_VIII_IMPLEMENTIERUNG.md`, `docs/RABENWACHT_EPILOG_IMPLEMENTIERUNG.md`, `docs/RABENWACHT_BRIEF_VON_MORGEN.md`. Die historischen Zwischenstände auf den Featurebranches bleiben nachvollziehbar.

---

## 21.10.2026 – SRD-Feuerball: interaktives Kartenoverlay (CI offen)

- **IMPLEMENTIERT:** In der Abenteueransicht kann ein getrenntes, read-only `SrdFireballGridPreviewDialog` geöffnet werden. Figuren-/Ursprungsfeld und bestätigte Vollhindernisse sind interaktiv auf 12×12, 20×20 oder 32×32 Feldern markierbar. Jede Terrainänderung widerruft die Kartenfreigabe und verwirft veraltete Vorschauen.
- **IMPLEMENTIERT:** Es werden der SRD-Feuerball mit 150 Fuß Reichweite zum Ursprung und eine 20-Fuß-Kugelvorschau kombiniert; mögliche Randfelder und offene Deckungsfragen bleiben ausdrücklich unbestätigte Effekte. Der Dialog verändert keinen Kampf-/Charakter-/SQLite-Zustand.
- **TESTS ERSTELLT, CI NOCH OFFEN:** `app/test/srd_fireball_grid_preview_dialog_test.dart` für unbestätigte Karte, Bearbeitung/Invalidierung, Hindernis zwischen Zauberndem und Ursprung, fremden Zauber und Schließen. Keine echte Android-Geräteabnahme.
- **NOCH NICHT IMPLEMENTIERT:** Echtzeitkarten/Positionierung, tatsächliche 3D-Deckungs-/Sichtregeln, automatische Zielwirkung, Feuerball-Schadenswurf, Dex-Saves und Ressourcenbuchung über diesen Planungsdialog. `RULE-SPELLS-SPELL-AREAS-OF-EFFECT` bleibt `partial`.
- Quelle: `docs/SRD_FIREBALL_PREVIEW_UI.md`.

---

## 21.10.2026 – SRD 5.2.1: konservative Kugel-Flächenvorschau (CI offen)

- **IMPLEMENTIERT:** `SrdSphereAreaRules.preview` erzeugt unveränderliche, mögliche 2D-5-Fuß-Kandidatenfelder einer separat bestätigten SRD-Kugel. Mittelpunktsabstand, mögliche Randüberlappung und offene Deckungsfragen bleiben ausdrücklich unterschiedliche Informationen. Eingaben aus unvollständigen Karten, ungültigen Radien und blockierten Ursprüngen werden gesperrt.
- **IMPLEMENTIERT:** `previewConfirmedSpell` validiert weiterhin die tatsächliche Katalog-Zauberreichweite bis zum bestätigten Ursprung und trennt sie vom separat bestätigten Kugel-Effektradius. `SrdSpellGridTargetRules.hasClearCenterRay` liefert einen konservativen Zeugen für Mitte-zu-Mitte-Weg, nicht den endgültigen Total-Cover-Status.
- **TESTS ERSTELLT, CI OFFEN:** `app/test/srd_sphere_area_rules_test.dart` für Randfälle, Blocker, Unveränderlichkeit, Zauberursprung vs. Effektradius. Keine neue GUI und keine tatsächliche Zielschadensauflösung.
- **NICHT IMPLEMENTIERT:** 3D-AoE, vollständiger SRD-Rasterflächenentscheid, Mehrfeldziele, Flächenverteilung um Ecken, Zauberspezialregel, Zieltypen/Zauberwirkung; Audit `RULE-SPELLS-SPELL-AREAS-OF-EFFECT` bleibt `partial`.
- Siehe `docs/SRD_SPHERE_AOE_PREVIEW.md`.

---

## 21.10.2026 – SRD-5.2.1-Ziele: geprüftes 5-Fuß-Raster und Mittelpunktstrahl (CI offen)

- Ausgangslage: `main` SHA `0f0a82c`, gesamter Build `39572178736` **grün**, offener Story-PR nicht angerührt.
- **IMPLEMENTIERT:** Neuer deterministischer `SrdSpellGridTargetRules` ermittelt Rasterabstände einschließlich Diagonalen und prüft Mitte-zu-Mitte-Verbindungen gegen bestätigte volle Blockerfelder; fehlende Kartenfreigabe, Ecken-Kollisionen und unbekannte Felder werden konservativ abgewehrt. `SrdSpellPreflightRules.preflight(gridTarget: ...)` leitet geprüfte SRD-Reichweitenfakten daraus ab; Kombination mit widersprechender manueller Geometrie verboten.
- **TESTS ANGELEGT, CI OFFEN:** `srd_spell_grid_target_rules_test.dart` deckt Raster, 3D-Grenze, Blockaden, Eckenkontakt, Manipulationsschutz, ungültige Felder und Preflight ab. Der SQLite-Material-Commit-Test verwendet einen geometrisch berechneten Touch-Ursprung.
- **NICHT IMPLEMENTIERT:** reale Kartenaufnahme, vollständige Sichtlinie oder 3D-Höhe, dynamische Hindernisse, genaue Voll-/Teil-Deckung, AoE-Raster, Mehrfeldwesen und Zauberwirkung. SRD-Auditpunkte `RULE-SPELLS-SPELL-RANGE`, `RULE-SPELLS-SPELL-TARGETS`, `RULE-SPELLS-SPELL-ATTACK-COVER` weiterhin ausdrücklich `partial`.
- Details: `docs/SRD_SPELL_GRID_TARGETING.md`.

---

## 21.10.2026 – SRD 5.2.1 Zauberreichweite und Zielursprung (PR, CI offen)

- Basis: letzter `main`-Workflow 39568413044 vollständig **grün** nach Material-/SQLite-Integration (PR #78).
- **IMPLEMENTIERT:** `SrdSpellTargetRules.validateOrigin` trennt Selbstursprung, bestätigte Berührung und feste Reichweiten in Fuß/Meilen, erfordert explizit freien Pfad und weist unbestätigte oder besondere Reichweiten zurück. `SrdSpellPreflightRules` nimmt strukturierte Zielfakten optional auf. Generischer persistierter Material-/Slotcommit verlangt diese Prüfung und protokolliert Ursprung/Abstand im Journal.
- **TESTS ERGÄNZT, CI OFFEN:** `srd_spell_target_rules_test.dart` plus erweiterte SQLite-Persistenztests. Kein behaupteter Geräte- oder vollständiger Effektabgleich.
- **OFFEN:** automatisches Weltkoordinaten-/Sichtlinienmodell, Mehrfachziele, flächenförmige Ursprungsverschiebung, Spezialreichweiten und regelgeprüfte Einzelzauberwirkungen; keine Voll-SRD-Abdeckung. `RULE-SPELLS-SPELL-RANGE` und `RULE-SPELLS-SPELL-TARGETS` als `partial` ausgewiesen.
- Details: `docs/SRD_SPELL_TARGET_RANGE.md`.

---

## 21.10.2026 – SRD-Zaubermaterialien: Revisions-/SQLite-Integration (CI offen)

- Grundlage: Materialpreflight-PR #74 und unveränderlicher Inventar-/Zauberplatz-Commit aus PR #76 sind nach vollständigem grünen GitHub-Workflow in `main` gemergt.
- **IMPLEMENTIERT:** `GameEngine.commitConfirmedSpellMaterialCast` führt extern bestätigten Zaubereffekt und Materialverbrauch im eigenen Revisions-/`spell.materialsCommitted`-Ereignisjournal zusammen. `GameController.commitConfirmedSpellMaterialCast` prüft Kampagnen-ID und Revision, nutzt das vorhandene transaktionale SQLite-Speichern samt Revisionsjournal. Keine reine KI-Erzählung löst diese Aktion aus; generischer Kampfzug wird abgewiesen.
- **TESTS ERSTELLT, CI NOCH OFFEN:** `app/test/srd_spell_inventory_persistence_test.dart` prüft Slot-/Inventarzustand, Journal, Neustart, Wiederherstellung, Wiederholungen, Konflikt und invaliden Materialverbrauch.
- **NICHT IMPLEMENTIERT:** amtlich bestätigte Inventar-/Komponentenidentität, automatische Preise und Materialrezepte, eigenständige überprüfbare Zaubereffekte, Ziel-/Kampfsteuerung und UI. Gerätetest offen.
- Quelle: `docs/SRD_SPELL_INVENTORY_PERSISTENCE.md`; Anforderungsstatus bleibt `partial`.

---

## 21.10.2026 – SRD-Zaubermaterialien/Inventar atomar im Domain-Zustand (CI offen)

- Ausgangspunkt: gemergter PR #74, der die SRD-Materialkomponenten und sichere Vorprüfung ergänzt (GitHub-CI auf seinem HEAD vollständig grün).
- **IMPLEMENTIERT:** Neuer unabhängiger Regelbaustein `SrdSpellInventoryRules.commitConfirmedCast`: auf einen geprüften `SrdSpellCastPlan` folgend werden Materialmengen und Slots nur gemeinsam im zurückgegebenen unveränderlichen Charakter aktualisiert. Ganze Stapel entfernen; Teilstapel und übriges Inventar erhalten. Fehlende/doppelte IDs, negative oder übergroße Mengen, ausgerüstete Items, unbestätigte Wirkung und veraltete Preflight-Snapshots werden abgewiesen.
- **NEUE TESTS (CI-Abnahme offen):** `app/test/srd_spell_inventory_rules_test.dart`, einschließlich JSON-Roundtrip, Doppelcommit-Verweigerung, Fehlerfälle und Schutz nicht konsumierender Zauber.
- **NOCH NICHT IMPLEMENTIERT:** Verlässliche automatische Identitäts-/Preisprüfung der Materialrezepte, UI-Auswahl, gemeinsame persistierte Repositorytransaktion samt Event, konkrete Revivify-Effektausführung, Geräteabnahme und vollständiger SRD-Abgleich.
- **Grenze:** Die Domänenfunktion gibt einen neuen `HeroCharacter` zurück; ein aufrufender Controller muss ihn und sein Ereignis atomar persistieren. Keine Behauptung einer fertigen Ende-zu-Ende-Integration.
- Details: `docs/SRD_SPELL_INVENTORY_ATOMIC.md`.

---

## 21.10.2026 – Spielbarer Kampagnen-Einstieg „Die vierzehnte Stimme“ (Akt VI)

## 21.10.2026 – Rabenwacht Akt VII: Der Chronist (Featurebranch, CI offen)

- **IMPLEMENTIERT:** Akt-VI-Fortsetzung aus PR #77 um Akt VII erweitert: Porträtvergleich, Bibliothek und direkter Chronistenkontakt, freiwillige Verhandlung, endgültige Ablehnung, verdächtige Scheinzusage, gesonderte bewusste Preisbestätigung, vierzehntes Eidblatt und Wahl der Verwahrung; spoilerfreie Hinweisergänzungen.
- **CODE & TESTS ERSTELLT:** `app/lib/story/fourteenth_voice_act7.dart`, Integration in `fourteenth_voice_campaign.dart` und `app/test/rabenwacht_fourteenth_voice_act7_test.dart`; kein Modell-/SQL-Schemawechsel, keine erfundenen SRD-Regeln, EP oder Ressourcenbuchungen.
- **NICHT GETESTET:** Dart-Format, Flutter-Analyse, Flutter-Tests, APK und Android-Geräteprüfung sind in dieser Umgebung nicht ausführbar und brauchen einen vollständigen CI-Lauf. Bestehender Akt-VI-PR #77 bleibt Integrationsvoraussetzung.
- **NOCH NICHT IMPLEMENTIERT:** Akt VIII, Rat der Zeugen, Eidentscheidungen, mögliche Gegnermechanik und finales Balancing. `voice:chronistDebt=pending` ist eine nicht vollstreckte Story-Schuld, keine automatische Löschung einer Spielfigur.
- Technische Übersicht: `docs/RABENWACHT_AKT_VII_IMPLEMENTIERUNG.md`.

---

- Entwicklung: `feature/rabenwacht-voice-act6-20261021`. Neue Datei `app/lib/story/fourteenth_voice_campaign.dart` hinter der bestehenden StoryRulePort-Schnittstelle, die regeltechnischen Modifikatoren kommen aus dem unveränderten Charakter-Regeladapter.
- Sichere Kapiteltransition nur nach bestätigtem `end-*`-Abschluss und mit ausdrücklicher Texteingabe „Fortsetzung beginnen“. Die Story beginnt im neuen Modus `rabenwacht-voice-v1`, ohne alte Fakten oder Quests zu löschen.
- Spielbar: Eröffnung mit Liora, Wahl zwischen Schutz, Beschuldigung oder Belegsuche, drei unabhängige Hinweise mit Regelchecks, gesperrter Hauszugang bei weniger als zwei Belegen, Haus und Porträtgalerie. Enden des Originalspiels beeinflussen Eröffnungstexte; vorhandenes Tarek-Vertrauen beeinflusst sein Auftreten.
- Tests: Start-/Speichersicherheit, vier mögliche Ausgangsenden, Gegner-/Zauberressourcen unverändert, Dialogkonsequenzen, alle drei Wurfpfade, Scheitern, drei Hinweiskombinationen, spoilerfreie Hinweise, originale Quests unverändert.
- **Noch nicht fertig:** Akte VII–VIII und ihre Enden, UI-Kachel für Kapitelwechsel, vollständige Android-/Flutter-CI und Gerätetest.

---

## 21.10.2026 – SRD-Zaubermaterialien als eigenständiger Regelbaustein (CI offen)

- Branch: `feature/srd-spell-material-components-20261021`, basierend auf `main` (`abf30627570095f6b41d34b26d84bda0184bc4f4`).
- **IMPLEMENTIERT:** Metadatenprüfung für ausdrücklich angegebene Kosten und Verbrauch, selektiver Einsatz von Komponentenbeutel/Zauberfokus, Verbot des Ersatzes teurer und verbrauchter Materialien sowie explizite Preflight-/Commit-Bestätigungen ohne Story-Kopplung. `app/lib/domain/srd_spell_component_rules.dart` und `app/test/srd_spell_material_components_test.dart`.
- **GETESTET (bisher):** Projektstruktur-/Python- und Backend-Schritte im CI-Vorlauf bis zur Dart-Formatprüfung bestanden; die neuen Flutter-Tests selbst **noch nicht ausgeführt**.
- **BLOCKIERT:** Ein erster CI-Lauf scheiterte an der Formatierung zweier neuer Dart-Dateien; Korrektur und erneute Prüfung stehen aus.
- **NICHT GETESTET:** Flutter-Analyse, sämtliche Flutter-Tests, Android-Debug-/Release-Build und Gerätetest.
- **NOCH NICHT IMPLEMENTIERT:** automatischer Verbrauch der Inventarobjekte, transaktionale Materialreservierung, komponentenabhängige Hand-/Fokusberechtigung aus konkreter Ausrüstung, allgemeine Zaubereffekte und vollständiger offizieller SRD-Abgleich. SRD-Matrix führt die beiden Komponentenanforderungen weiterhin nur als `partial`.
- Details: `docs/SRD_SPELL_MATERIAL_COMPONENTS.md`.

---

## 21.10.2026 – Regelengine und Story technisch getrennt (0.8.30+80, CI offen)

- Ausgangspunkt `main`: Version 0.8.29+79; die SRD-Regel- und Story-Module existieren bislang nur teilweise als separate APIs.
- Kanonische Rabenwacht-Erzählung und das komplette handgeschriebene Kampagnenskript liegen jetzt in `story/rabenwacht_campaign.dart` statt `domain/rabenwacht_campaign.dart`. Die frühere statische API bleibt durch eine kleine Domain-Fassade unverändert benutzbar.
- Expliziter `StoryRulePort` erlaubt der Handlung Proben und Kampagnen-Meilensteinbelohnungen anzufordern, ohne Klassen-/XP-Regelcode zu importieren. Domain-Adapter behält bestehende SRD-Berechnungen.
- Generative KI-Storytypen aus `domain/ai_story.dart` in kanonische `story/ai_story.dart` verschoben; Legacy-Import bleibt als Export erhalten.
- Versionsübergreifende Speicherformate unverändert. CI-Architekturtests verhindern neue direkte Story-Regel-Importe; Rabenwacht-Port-Tests und bestehende Kampagnen-/Rules-Trenn-Regressionen hinzugefügt.
- Parallel-Branches `feature/rules-*` und `feature/story-*` sowie Port-Integrationspolitik und Aufwand in `docs/ARCHITECTURE_RULES_STORY.md` dokumentiert.
- Weiter offen: weitere 4.500+ Zeilen GameEngine-Orchestrierung aufteilen, Ports für Kampfende/Story-Quest-Übergänge, vollständige getrennte Packages und Android-Gerätetest; Build/CI muss erfolgreich sein.

---

## 21.10.2026 – Zusätzlicher Monsterangriff auf gespeichertes Flächenziel (0.8.29+79, CI offen)

- Vorheriger `main`: 0.8.28+78, PR #60 gemergt und alle CI-Gates einschließlich Android-Alpha erfolgreich.
- Neue `SrdExtraCreatureAttackRules.resolve`: bestätigter einfacher Waffeneinzelangriff mit W20, natürlichen 1/20, Deckung, Vorteil/Nachteil, kritischen zusätzlichen Schadenswürfeln, geprüfter Schadensart und getrennten Ziel-TP.
- Nur lebende SL-gesteuerte Zusatzkreaturen mit aktuellem manuellen Zug und freier Aktion können eine **andere** gespeicherte lebende Zusatzkreatur treffen. Held/Hauptgegner bleiben wegen fehlender vollständiger Reaktions-/Todesrettungsintegration ausdrücklich ausgesperrt.
- `ManualCombatTurnQueue.actionUsed` im abwärtskompatiblen schema-1-JSON (ältere Spielstände ohne Feld implizieren `false`). Revisionsgeschützter Controller, `combat.manualExtraCreatureAttack`-Journal und Schnellaktion/Dialog „Zusatzkreatur-Angriff“.
- Regressionstests für Critical ohne doppelten Flat-Bonus, Decken-RK, einmaligen Angriff/Zug, HP-Journal-Roundtrip, nicht autorisierte Ziele, abgelehnte unbekannte Monsterdaten und UI-Schutz.
- SRD-Anforderungen `RULE-COMBAT-MULTIPLE-OPPONENTS` und `RULE-COMBAT-TURN-STRUCTURE` als `partial` mit Code-/Test-Links; Details `docs/SRD_MANUAL_EXTRA_CREATURE_ATTACK.md`.
- **Offen:** Held-/Hauptgegner-Schaden und Reaktionen, Multiattack, echte gemeinsame Turnqueue, Monsterprofile, Kampfende, Android-Gerätetest. Vollständige CI-Abnahme noch ausstehend.


---

## 21.10.2026 – Rabenwacht: Handlungsentwicklung (Entwicklungsbranch)

- Branch `feature/rabenwacht-namenchor-main-20261021`, Basis `main` nach abgeschlossenem PR #66.
- Neue optionale Kapellenszene `hymn` („Die stumme Strophe“) mit eigenen Dialogen, Belegen, Spielerentscheidung und Quest `rabenwacht-hymn`.
- Geheimes viertes Ende `end-chorus` benötigt `hymnChoice=kept`, `graveOath=remembered`, `alrikConfession=true` und `serenTrust=true`. Keiner dieser Fakten wird nur durch Erzählwunsch erzeugt.
- Oswins Beziehung, Hinweise und Epilog unterscheiden Erhalten/Vernichten; optionaler Auftrag kann ungelöst bleiben; Meilenstein-EP weiterhin nur einmal.
- Story-Bibel: `docs/RABENWACHT_DIE_STUMME_STROPHE.md`. Tests: `app/test/rabenwacht_hymn_story_test.dart`.
- CI, reale Geräteprüfung und spielerische Balance-Abnahme stehen aus. Keine neue SRD-Zaubermechanik.

---

## 21.10.2026 – Rabenwacht: alternative Fertigkeitsproben (Entwicklungsbranch)

- Vorheriger bestätigter Stand: PR #65 erfolgreich in `main` integriert; Änderungen auf `feature/rabenwacht-alternative-checks-20261021`.
- Implementiert: Untersuchung von Bauspuren in der Turmruine (Nachforschungen SG13), Statik der Kryptatreppe (Nachforschungen SG12), historisches Lösungsrätsel an der dreizehnten Tür (Nachforschungen SG14 nur bei belegten Archivrecherchen); bestehende Lösungswege bleiben bestehen.
- Keine eigens erfundenen SRD-Boni. Bestehende `preparedCheck`-Sicherheitsprüfung validiert Fertigkeit, Attribut, SG, Stage und Heldenboni. Ergebnisse bleiben in normalen `Campaign.facts` gespeichert; Fehlschläge respektieren das Fail-forward-Prinzip ohne geheime Erfolgsfakten.
- Schutz vor frei behauptetem Wirken von Zaubern (kein impliziter Zauberplatzverbrauch und keine Pseudowirkung).
- Neue Datei `app/test/rabenwacht_alternative_checks_test.dart`; vollständige Flutter-CI, Debug-APK und Gerätetest sind **noch offen**.
- Nächster Schritt: echte Weltzauber-/Klassenaktions-Unterstützung über bestätigte, ressourcenwirksame Regelaktionen statt textbasiertem Simulieren.

---

## 21.10.2026 – Rabenwacht NPC-Gedächtnis und alternative Route (Entwicklungsbranch)

- Branch: `feature/rabenwacht-npc-memory-20261021` auf Basis von PR #64. Der Hauptbranch wird erst nach CI-Abnahme geändert.
- Implementiert: optionale Kundschafterroute von Tarek mit `tarekSafeRoute` und `crowsBypassed`; vorhandener Krähenalarm bleibt erhalten. Alriks Reue nach belegter Gedenkstein-Entscheidung (`alrikConfession`), danach Maras Versöhnung (`maraReconciled`).
- Rückwärtskompatible Fakten/NPC-Beziehungen statt neuer Schemas; Belohnungen bleiben einmalig. Hinweise sind entdeckungsabhängig, das Finale reagiert auf gesicherte Fakten.
- Testdatei `app/test/rabenwacht_npc_memory_test.dart`: sieben neue Testfälle für Dialogsperren, Persistenz, EP, Konsequenzen und zusammenhängenden Kampagnenpfad.
- Noch ausstehend: CI/Flutter/Android-Geräteprüfung dieses Branches, tieferes Dialogverständnis, echte Klassen- und Zauberlösungen.

---

## 21.10.2026 – Rabenwacht: zusätzliche Gedenkstein-Quest (gestapelter PR)

- Basis: `main` nach erfolgreichem Merge von PR #61. Der neue Gedenkstein-Handlungsstrang liegt isoliert auf `feature/rabenwacht-gedenkstein-main-20261021`; `main` bleibt bis zur Abnahme dieses Inkrements unverändert.
- Implementiert: optionaler Friedhofshandlungsstrang `rabenwacht-memorial`, nachgewiesene Erinnerung versus Verschweigen, irreversible Wahl nur bei eindeutiger Eingabe, sicherer Nachholweg, spoilergeschützte Fakten und unterschiedliche Epiloge.
- Neue `app/test/rabenwacht_memorial_test.dart` prüft Folgen, Persistenz, Hauptpfad und Spielerverneinung.
- **Noch nicht abgenommen:** volle Flutter-Tests und Android-APK der neuen Änderung; Geräteabnahme offen. Keine neue Versionsnummer. Nächste Stufe: dialogfähige NPCs, alternative Fertigkeits-/Zauberlösungen und mechanische Komplikationen.

---

## 21.10.2026 – Rabenwacht, verzweigter Story-Inkrement (Entwicklungsbranch)

- Entwicklung auf `feature/rabenwacht-branching-story-20261021`; `main` bleibt unverändert.
- Implementiert: eigener Mara-Ermittlungszweig, drei Entscheidungspfade, persistente Beziehungen und Hinweisfakten; besuchte Orte mit einmaliger EP-Vergabe und nachholbaren Wegen.
- Implementiert: Kampf nur bei ausdrücklicher Aggression im Wächterraum (Negationen werden berücksichtigt); nach erfolgreichem Überreden Seren-Wahl statt erzwungenem Finale; Epilog-Varianten zu Mara, Seren und Krähenalarm.
- Testdatei: `app/test/rabenwacht_branching_story_test.dart` (Entscheidungen, Persistenz, Reisen, EP-Idempotenz, Kampfverweigerung, finale Wahl, Konsequenzen).
- **Nicht getestet:** kein Flutter-/Dart-SDK in der Ausführungsumgebung; `dart format`, `flutter analyze`, `flutter test`, APK-/Android-Gerätetest stehen aus. Siehe `docs/RABENWACHT_KAMPAGNE.md`.
- **Offen:** vollständige Handlungs-/Dialog-NLU, KI-improvisierte Nebenpfade, dynamische Gegnerkonsequenzen, Zauber-/Werkzeuginteraktionen in allen Szenen, umfassende Balance- und Durchspieltests.

---

## 21.10.2026 – Manuelle Mehrgegner-Zugfolge (0.8.28+78, CI offen)

- Verifizierte Basis: `main` Version 0.8.27+77 (PR #59, Flutter und Android/Alpha-CI erfolgreich).
- `ManualCombatTurnQueue` als optionale immutable Kampf-ID/Akteur-Reihenfolge/Position/Rundenzahl im schema-1-Campaign-JSON mit Importvalidierung und Schutz vor verwaisten Encounter-IDs.
- `SrdInitiativeRosterRules.createManualQueue` bestätigt **alle** lebenden Teilnehmer einmalig, sortiert absteigend und verlangt bewusste Entscheidungen für Gleichstände. Die manuelle Fortsetzung überspringt ausgeschiedene Zusatzkreaturen und erhöht die Rundenzahl beim Umlauf.
- Getrenntes UI für Reihenfolge, Tiebreaker, fortlaufenden Marker; Controller-Revision und eigene Journalereignisse `combat.manualTurnQueueEstablished`/`combat.manualTurnQueueAdvanced`.
- Automatische Invalidierung nach Änderungen an Kreaturen-/Initiativdaten oder Kampfende; Legacy-Kämpfe bleiben unverändert. Regressionstests für Codec, alte Saves, Idempotenz, Tie-Handling und falsche Akteur-IDs.
- **Bewusst noch nur taktischer Marker:** nicht mit `Encounter.activeParticipant` oder Hauptgegner-Angriffen synchronisiert, keine autonomen Aktionen oder Siege für Zusatzgegner. `RULE-COMBAT-INITIATIVE` bleibt `partial`. Siehe `docs/SRD_MANUAL_MULTI_TURN_QUEUE.md`.
- CI/Android-Gerätetest ausstehend.

---

## 20.10.2026 – Initiative zusätzlicher Kreaturen (0.8.27+77, CI offen)

- Vorheriger verifizierter `main`: Version 0.8.26+76 (PR #58, Android-/Flutter- und ZIP-CI erfolgreich). Echtes Gerät bleibt offen.
- `TrackedAreaCreature` kann nun ein optionales bestätigtes Initiative-Gesamtergebnis sowie dessen SL-/Spieler-Kontrolle speichern. Alte schema-1-Kampagnen ohne diese Felder bleiben unverändert lesbar, 0 ist von null unterscheidbar.
- Eigenständige `SrdInitiativeRosterRules.preview`: absteigend sortierte Gruppen, Gleichstände als unentschiedene Gruppen, fehlende Zusatzergebnisse separat. Alte Null-Standardwerte der Hauptinitiative werden **nicht** stillschweigend als bestätigt betrachtet.
- UI „Initiative der Kreaturen“, Engine/Controller `confirmAreaCreatureInitiative`, eigener Journaleintrag `combat.areaCreatureInitiativeConfirmed` und strikte Bestätigungs-/Revisionssperren.
- SRD-Matrix `RULE-COMBAT-INITIATIVE` als `partial` mit Code-/Testnachweisen; Details `docs/SRD_MULTI_CREATURE_INITIATIVE.md`.
- **Grenze:** Turn-Queue, tatsächliche Zusatzgegner-Aktionen, gemeinsame Monstergruppen-Initiative, Auflösung von Gleichständen und Kampfende erst in weiteren Inkrementen. CI und Gerätetest offen.

---

## 20.10.2026 – Persistente Mehrziel-TP für Säurespritzer (0.8.26+76, CI offen)

- Basis: 0.8.25+75 nach PR #57 in `main` integriert; Flutter-, Android- und Alpha-Builds erfolgreich.
- `Campaign.trackedAreaCreatures`: HP- und Identitätsliste für maximal 19 **zusätzliche** separat verfolgte Kreaturen; optionale schemaVersion-1-JSON-Erweiterung, alte Spielstände kompatibel. IDs, TP-Grenzen, doppelte IDs und Namens-/Zustands-Snapshots werden validiert.
- `GameEngine.trackAreaCreature` und Controller erlauben explizit bestätigte HP-Erfassung im laufenden Kampf. Zusätzliche Trefferpunkte bleiben auch nach dem Ende des Hauptkampfes persistent.
- `castAcidSplash`: alle ausgewählten, gespeicherten Kreaturen werden vor Würfelwurf geprüft und bekommen eigene GES-Saves. Ein gemeinsamer Säureschadenswurf; persistiert alle HP, Hauptgegner und Journal in einem revisionsgeschützten Commit.
- Neue manuelle Eingabedialoge für Zusatzkreaturen und per-Ziel-Rettungswurf/Deckung/Vorteil. Neue Regel-, Speicher- und Widgettests.
- **Weiterhin keine vollständige Mehrgegner-Kampfsteuerung:** Zusatz-HP sind nur Flächenziele, nicht eigenständige KI-Akteure mit Turn-Slots/Initiative und Siegbedingungen. Keine Karten-/Monsterdefensivautomatik. Näheres: `docs/SRD_PERSISTENT_AREA_CREATURES.md`.
- CI/APK-Abnahme und echter Android-Gerätetest bei Erstellung noch ausstehend.

---

## 20.10.2026 – Säurespritzer: 2024er Flächenzauber-Regelkern (0.8.25+75, CI offen)

- Ausgangs-`main`: `0.8.24+74`, Heilige Flamme und Rettungswurf-Engine aus PR #56 erfolgreich mit Android-/Flutter-CI integriert.
- `AcidSplashRules`: mehrere selbstständig bestätigte Kreaturen, GES-Saves pro Ziel, 5-Fuß-Radius, Deckungs-Save-Boni relativ zum Ursprung, **ein gemeinsamer** W6-Schadenswurf bei gleichzeitig betroffenen Kreaturen, individueller Schaden/TP und Null-Schaden bei Erfolg, Cantrip-Skalierung auf Stufe 5/11/17.
- Eigenständige Kampfaktion, Dialog, Controller, `spell.acidSplash`-Journal, 0 Slotverbrauch; **im vorhandenen Encounter ist nur ein einzelner aktiver Gegner speicherbar, deshalb absichtlich auf eine einzelne wirklich allein betroffene Kreatur beschränkt**.
- Tests für mehrfach betroffene Kreaturen im reinen Domänenkern, separate Saves, gemeinsame Würfel, Schutz vor unbestätigtem Flächeninhalt, widersprüchlichen Deckungen und Speicher-Regression.
- SRD-Eintrag `SPELL-ENTRY-ACID-SPLASH` als `partial` statt als fertig gewertet. Vollständige Multi-Encounter-HP-/Turn-/Monster-Logik bleibt offen.
- Details: `docs/SRD_ACID_SPLASH_AOE.md`. Versionsbuild muss CI bestehen; echter Android-Gerätetest weiterhin ausstehend.

---

## 20.10.2026 – Heilige Flamme: Rettungswurf-Zauberengine (0.8.24+74, CI ausstehend)

- **Basis:** 0.8.23+73 (PR #55) wurde nach vollständig erfolgreicher GitHub-CI nach `main` gemergt; Android-Gerätetest separat offen.
- **Neue wiederverwendbare Regel:** `SrdSpellSavingThrowRules` (SG = 8 + Proficiency + Zauberattribut, vollständiger bestätigter gegnerischer Saving-Throw-Bonus, Advantage/Disadvantage; natürliche W20 1/20 nicht automatisch Erfolg/Fehlschlag).
- **Erster regelintegrierter Rettungswurf-Zauber:** `SacredFlameRules` (Heilige Flamme): bestätigter Kleriker-Zaubertrick, GES-Save, 1–4W8 Strahlenschaden nach Stufe, keine halb-/dreiviertel-Deckung beim Save, Magieaktion ohne Zauberplatz.
- **End-to-End:** eigener bestätigungspflichtiger Dialog, revisionsgeschützter Controller, `spell.sacredFlame`-Checkpoint mit W20, SG, Schaden und Gegner-TP.
- **Zählbare Anforderung:** `SPELL-ENTRY-SACRED-FLAME` auf `partial` mit Code-/Testnachweis; vollständige SRD-Inventur weiter unvollständig (keine globale Quote).
- **Grenzen:** nur ein bestätigter Kreaturengegner, keine automatisch abgeleiteten Monsterboni, Schäden, Traits, geometrischen Ziele oder Sonder-SG. Weitere Zauber (AoE, Monster-Reaktionen) und Gerätetests offen. Siehe `docs/SRD_SACRED_FLAME_SAVING_THROW.md`.
- **Gate:** Version 0.8.24+74 bleibt vor erfolgreicher vollständiger CI auf dem Featurebranch.

---

## 20.10.2026 – SRD Feuerpfeil-Kampfaktion (0.8.23+73, CI noch offen)

- Basis: SRD-Zauberindex und Vorprüfung 0.8.22+72 erfolgreich per PR #54 nach `main` gemergt (Android-/Flutter-CI bestanden).
- Der Zaubertrick **Feuerpfeil / Fire Bolt** wird nun als eigene bestätigte `spell.fireBolt`-Kampfaktion mit gültiger Zauberklasse, Magieaktion, Sicht/Reichweite, V/S-Komponenten und expliziter Zielabwehrbestätigung ausgeführt.
- Lokaler W20-Zauberangriff inklusive Proficiency/Zauberattribut/Erschöpfung, Deckung und aktiver Schild-RK; natürliche 1/20, Vorteils-/Nachteilsentscheidung, kritische Schadenswürfel, 1–4 W10 nach Gesamtstufe.
- Gegner-TP, magische Aktionsökonomie, Ereignisjournal, Revisionsschutz und JSON/SQLite-Verarbeitung über vorhandene Engine/Controller-Struktur. Neuer Checkbox-Dialog und Schnellaktion.
- Domänentests/Engine- und Widgettests ergänzt: `fire_bolt_rules_test.dart`, `fire_bolt_dialog_test.dart`. Vorprüfungen und Speicherschutz bleiben erhalten.
- **Teilweise SRD-Abdeckung:** keine Objektentzündung, automatischer Feuerresistenz-Abgleich, Kartenpositionen, Mehrfachziele, komplette Monsterreaktionen; Gerätetest ausstehend. Siehe `docs/SRD_FIRE_BOLT_COMBAT.md`.
- Für diese Version GitHub Actions CI vollständig prüfen; vor grünem Gesamtbuild nicht nach `main` mergen.

---

## 20.10.2026 – SRD 5.2.1: Zauberindex/Vorprüfung (0.8.22+72, CI offen)

- Basis: bereits integrierter PR #53 und `main`; neuer Branch `feature/srd-spell-catalog-preflight-20261020`.
- 339 strukturierte Zaubereinträge aus SRD-Transkription in `app/assets/srd_5_2_1_spells.json`: Name, Grad, Schule, Klassen, Zeit, Reichweite, Komponenten und Dauer/Konzentration/Ritual.
- Neue reine Domain-Vorprüfung `SrdSpellPreflightRules`: eigene Klasse und deren Aufstiegsstufe, bestätigte bekannte Zauber, normale/Paktplätze, separate Aktions-/Ziel-/Komponenten-/Ein-Zauberplatz-pro-Zug-Bestätigung sowie veraltete Charakter-Snapshot-Sperre.
- Nur ausdrücklich bestätigtes **manuell aufgelöstes** Zauberereignis erlaubt Ressourcenbuchung; **keine** automatische allgemeine Zauberwirkung. Reaktionen, ausgelöste Bonusaktionen und mehrzügige Zauberzeiten weiterhin gesperrt.
- Tests `srd_spell_catalog_preflight_test.dart`; Altspielstände und bestehende Spezialpfade unverändert. Amtlicher Metadatenabgleich, echte Ziel-/Area-/Kampf-Integration und Android-Geräteabnahme weiterhin offen.
- CI/APK für dieses Inkrement **noch nicht freigegeben**. Details: `docs/SRD_SPELL_CATALOG_PREFLIGHT.md`.

---

## 20.10.2026 – Maschinenlesbare SRD-5.2.1-Anforderungsmatrix (laufendes Review)

- **Entwicklungsbranch:** `feature/srd-countable-requirements-20261020`, Ausgangspunkt `main` `b965efc3e9d337a4ce406b5e3380b79147918c66`; App-Quellversion bleibt `0.8.21+71`.
- **Neu:** `docs/srd_5_2_1_requirements.json` (475 ältere/übergreifende Anforderungen inklusive 282 Klassen-Freischaltungen); `docs/srd_5_2_1_entities.json` (944 zusätzlich benannte Zauber, Monster, Tiere, Magiegegenstände, Talente) und `docs/SRD_5_2_1_COVERAGE_AUDIT.md`.
- **Insgesamt:** 1.419 eindeutig gezählte, aber *nicht vollständig auf mechanische Einzelregeln zerlegte* Arbeitsprüfpunkte. 8 historisch getestet, 11 teilweise, 7 als fehlend dokumentiert, 1.393 unbestätigt. 9 offene Inventur-/Quellenabgleich-Lücken; **kein zulässiger globaler SRD-Prozentsatz**.
- **Qualitätsschutz:** `scripts/srd_coverage.py`, `scripts/tests/test_srd_requirements_matrix.py` prüfen ID-Eindeutigkeit, SRD-Quellreferenzen, 282 Katalogeinträge, Entity-Zahl, keine unbelegten Fertigmeldungen und Abschluss-Gates. Integration über bestehende Python-CI-Tests, GitHub-Actions-Ergebnis für dieses Inkrement **noch ausstehend**.
- **Nächste Schritte in Priorität:** 339 Zaubernamen mit amtlichem SRD abgleichen, jede Wirkung und Vorbereitung/Ziel/Slots/Komponenten einzeln umsetzen; danach 282 Klassen-Freischaltungen mit Effektnachweis, 330 Monster/Tier-Statblocks, restliche Kampf-/Erkundungs-/Magiegegenstandsregeln. **Kein Android-Gerätetest.**

---

## Abnahme / Merge 20.10.2026 – Version 0.8.21+71

**CI- und Merge-Abnahme (20.10.2026):** SRD-Inkrement `0.8.21+71` über [PR #52](https://github.com/ManuEtt/Dnd/pull/52) erfolgreich nach `main` integriert. [GitHub-Actions-CI #39421141308](https://github.com/ManuEtt/Dnd/actions/runs/39421141308) auf finalem Code-HEAD `9156b972d240de4c5a588c09ebb5ac8adeca99ad`: **success**, inklusive Python-/Strukturtests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Tests, Alpha-APK-Pakete und Checkpoint-Artefakt. Merge-Commit [`b87e53591df75bc40b9e9f534529666fb168c6f3`](https://github.com/ManuEtt/Dnd/commit/b87e53591df75bc40b9e9f534529666fb168c6f3). **Nicht getestet:** echte Android-Geräteinstallation; mehrere unabhängige Monster und unterschiedliche Attackenprofile; vollständige SRD-Abdeckung.

---

## 20.10.2026 – Bestätigte Gegner-Mehrfachangriffe und Schilddauer (0.8.21+71)

**Basis:** `main` `ded30b8720140babca7b4841a88a167cd3241665`. **Status: Feature-Branch, CI-/APK-Abnahme noch offen.**

- Einem Gegner dürfen ausdrücklich **1–4 Angriffe pro Zug** zugewiesen werden, etwa anhand eines verifizierten SRD-Statblocks oder einer tatsächlichen Spielentscheidung. Ohne Bestätigung bleibt das bisherige Verhalten **ein Angriff**. Kein KI-Text wird als bestätigte Monsterfähigkeit übernommen.
- Pro Angriff erfolgt ein eigener Angriffswurf; ggf. bleibt der bereits vorhandene echte Post-Hit-Schildentscheid offen. Folgetreffer laufen erst über `Gegnerangriff fortsetzen` weiter, ohne einen vorherigen W20 zu wiederholen. Rundenfortschritt, Zähler und aktiver Gegnerzug bleiben in der Kampagne und dem Journal gespeichert, auch bei SQLite-Neustart.
- Ein bereits gewirkter Helden-Schild bietet +5 RK **für die restlichen Angriffe dieses Gegnerzuges**, verhindert einen zweiten Reaktions-/Zauberplatzverbrauch und endet am Beginn des nächsten eigenen Zuges. Alte Kampagnen haben weder automatisch Mehrfachangriffe noch einen aktiven Shield.
- Die Kampfoberfläche zeigt einen Bestätigungs-Popup zur Anzahl und einen Fortsetzen-Button bei noch offenen Gegnerangriffen; reguläre/ältere Einzelangriffe bleiben kompatibel.
- Tests: `enemy_multiattack_shield_test.dart`, `enemy_multiattack_storage_test.dart` für Rundenzähler, Schild-Reaktionsdauer, zweiten Treffer, W20-Wiederholungsverhinderung, alten JSON-Spielstand, Manipulationsabwehr und SQLite-Fortsetzung. **Testdateien vorhanden ≠ bestanden; vollständiger GitHub-Actions-Nachweis ausstehend.**
- **Grenzen:** Maximal vier gleichartige bestätigte Angriffe **eines** Gegners, keine unabhängigen Angriffsmuster/mehrere Gegner oder automatisch angenommene Monsterfähigkeiten; keine realen Android-Gerätetests.

**Wiederaufnahme:** finalen PR-Code-HEAD in GitHub Actions auf erfolgreiche Projekt-, Backend-, Flutter-, Android- und APK-Tests prüfen, Fehler im Feature-Branch korrigieren, ausschließlich nach voll grünem CI-Run mergen. Danach Statusdateien mit dem echten Merge-Commit und Run aktualisieren und vollständig gemergten Branch sicher löschen.

## Erfolgreiche CI- und Merge-Abnahme – 20.10.2026 (0.8.20+70)

**CI bestätigt (20.10.2026):** [PR #51](https://github.com/ManuEtt/Dnd/pull/51) wurde nach vollständig erfolgreicher [GitHub-Actions-CI #39406260656](https://github.com/ManuEtt/Dnd/actions/runs/39406260656) mit Code-HEAD `011c53826956e609994930c65221bca9c33d9985` nach `main` integriert. Merge-Commit [`ff1b043652e46a99c4ac3038698d047fb0d3f380`](https://github.com/ManuEtt/Dnd/commit/ff1b043652e46a99c4ac3038698d047fb0d3f380). Erfolgreich: Python-Strukturtests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Unit-Tests, Alpha-APK-Erstellung und Build-Artefakte. **Echter Android-Gerätetest, Mehrfachgegner/Mehrfachattacken und Shield gegen gegnerisches Magisches Geschoss bleiben offen.**

---

## 20.10.2026 – Schildreaktion nach tatsächlich getroffenem Gegnerwurf (0.8.20+70)

**Entwicklungsbasis:** `main` `89bd998563c58ae9a8e44a7db6a4ec996219f85d`. **CI und Android-Gerätetest für diese Änderung stehen noch aus.**

- Bei einem **tatsächlich treffenden Gegnerangriff**, wenn der Held Schild vorbereitet und mindestens einen verfügbaren Zauberplatz hat, wird der W20 einschließlich Naturwurf/Bonus atomar als `PendingEnemyShieldHit` gespeichert. **Vor der Entscheidung werden keine Schadenswürfel erzeugt und keine TP verändert.**
- Die UI zeigt das gewürfelte Angriffsergebnis an und bietet `Jetzt Schild wirken` bzw. `Treffer hinnehmen`. Schild setzt weiterhin eine eigene Magier-/Zaubererklasse, einen bestätigten normalen oder Paktplatz und bestätigte verbale/gestische Komponenten voraus.
- Beim Fortsetzen wird **ausschließlich der zuvor gespeicherte Angriff** verarbeitet, ohne zweiten W20-Wurf. Bei Schildentscheidung wird der Zauberplatz auch dann regelkonform verbraucht, wenn der W20 kritisch war oder +5 RK den Treffer nicht verhindert. Der Treffer richtet dann erst jetzt Schaden an. War +5 RK ausreichend, wird der Schaden verhindert.
- Neue `combat.shieldHitResolved`-Ereignisse und Controller-Methode `resolveEnemyShieldHit` haben Revisionsschutz und SQLite-Atomizität. Offene Entscheidungen sind mit gültigen Spielstanddaten gespeichert, während gewöhnliche Aktionen bis zur Entscheidung blockiert bleiben. `Campaign.fromJson` akzeptiert alte Spielstände ohne neues Feld, verwirft jedoch ungültige Würfelwerte, Ziel-IDs und laufende ungültige Reaktionszustände.
- Tests `hero_shield_post_hit_choice_test.dart` und `hero_shield_post_hit_storage_test.dart` sowie Update des Bestandsregressionstests: nachträgliche Schildwahl, Ablehnen, kritischer Treffer, nicht abwendbarer Treffer, Würfel-Nichtwiederholung, JSON, SQLite-Neustart, stale Revision. **CI beim Schreiben noch nicht ausgeführt.**
- **Grenzen:** Gegnerangriff bleibt ein einzelner Attack-Roll-Vorgang; noch keine multiattack-/mehrgegnerfähige Shield-Wirkung über mehrere gegnerische Züge oder gegnerisches Magisches Geschoss auf den Helden. Der zuvor implementierte, rein optionale Vorabautorisierungsweg bleibt zur Spielstandkompatibilität bestehen. Kein vollständiges SRD, kein getestetes echtes Android-Gerät.

**Fortsetzung:** Finalen PR-HEAD formatieren, Projektprüfung, Backend und Flutter Analyse/Tests, Android Debug/Release und native Tests in GitHub Actions prüfen. Gemeldete Probleme beheben, erneute CI; nur vollständiges Grün erlaubt Merge nach `main`. Danach CI, Merge-Commit und offene Grenzen dokumentieren.

## Abnahme und Merge: 0.8.19+69 (20.10.2026)

**CI- und Merge-Abnahme 20.10.2026:** Das eingeschränkte Regelpaket `SPELL-SHIELD-HERO-CONDITIONAL` in Version `0.8.19+69` wurde über [PR #49](https://github.com/ManuEtt/Dnd/pull/49) auf `main` integriert (Merge [`95792bb241c6123e34a1fae97c9fdef31d153ce2`](https://github.com/ManuEtt/Dnd/commit/95792bb241c6123e34a1fae97c9fdef31d153ce2)). Vollständiger [GitHub-Actions-Lauf #39394683773](https://github.com/ManuEtt/Dnd/actions/runs/39394683773) auf dem finalen Code-HEAD `090adb4c5fe21ddfc83d0903d5ef39181c50dd9f` **success**: Struktur-/Python-Tests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Tests und Alpha-APK-Artefakte. **Nicht geprüft:** Gerätetest; eine echte Reaktions-Unterbrechung *nach* dem gegnerischen Angriffswurf; mehrere Angriffe/Gegner und Shield gegen gegnerisches Magisches Geschoss. Diese Grenzen bleiben als offene SRD-Anforderungen bestehen.

---

## 20.10.2026 – SRD Hero Shield (Version 0.8.19+69)

**Basis:** `main` `12b2ddd8e524d674acbb909cc09025bc8ef2cfd9`. Featurebranch: `feature/srd-hero-shield-auto-reaction-20261020`. **Status beim Commit: implementiert, CI noch nicht bestätigt**.

- Neu: `HeroShieldReactionRules` und bedingte Held-Schild-Reaktion im Gegenzug. Voraussetzung sind bestätigter bekannter/vorbereiteter Zauber `Schild`/`Shield`, eigene Magier-/Zaubererklasse (inkl. geprüfter Mehrklassen), freier normaler oder Paktmagie-Platz und ausdrücklich bestätigte V/S-Komponenten.
- Der Benutzer **autorisiert vor dem unmittelbaren Gegnerzug** die Reaktion; beim Angriff entscheidet die Regelengine anhand des gewürfelten W20, ob ein tatsächlich treffender, nicht kritischer Angriff durch +5 RK verfehlt. **Erst beim Eintritt dieses Triggers** wird exakt ein Zauberplatz gebucht; Trefferpunkte bleiben geschützt und die Abwehr erscheint mit Würfelwerten im Ereignisjournal. Bei Fehlangriff, nicht abwendbarem Treffer oder kritischem Treffer wird kein Platz verbraucht. Keine frei erfundenen Trigger oder Würfelergebnisse.
- UI: Neue Aktion `Zug beenden: Schild ggf. wirken`, eigener Dialog mit Klasse, freiem Zauberplatz und V/S-Einwilligungen. Der Controller verwendet `expectedRevision`, `GameEngine.endHeroTurn` validiert vor dem Wurf, Zustand/Slots/Ergebnis landen atomar im bestehenden SQLite-JSON-Journal. Altes Spielstandschema und reguläres `Zug beenden` unverändert.
- Testdateien: `hero_shield_reaction_rules_test.dart` und `hero_shield_reaction_storage_test.dart` prüfen Schildwirkung, kritischen und zu hohen Angriff, fehlenden Platz, fremde Klasse, Zaubername, W20-Zufall, JSON-Roundtrip, SQLite-Neustart und Revisionsschutz. Testergebnis erst nach GitHub-CI dokumentieren.
- **Wichtige Grenze:** Noch keine interaktive Unterbrechung *nach* einem gegnerischen Treffer; die bewusste Vorautorisierung gilt ausschließlich für den **unmittelbar folgenden** automatisierten Gegner-Einzelangriff und nur, wenn die +5 RK den Treffer verhindert. Ein Spieler kann den Schildzauber in anderen SRD-zulässigen Situationen derzeit nicht nachträglich auslösen. Weitere Gegnerattacken pro Runde, Monsterzauber und Magisches Geschoss gegen Helden sind noch offen; das vollständige SRD 5.2.1 bleibt unvollständig.

**Wiederaufnahme:** Feature-PR auf GitHub kontrollieren, CI (Projekt-/Pythonprüfungen, Backend, Dart format/analyze/test, Android-JVM/APK) abwarten; alle Fehler korrigieren. Erst mit vollständig grünem CI-Run konfliktfrei nach `main` mergen, danach CI-ID, Commit und offenen Gerätetest nachtragen.

## Abgeschlossene Branch-Konsolidierung – 20.10.2026

**Branch-Bereinigung verifiziert (20.10.2026):** Alle neun historischen Feature-/Dokumentationsbranches waren bereits in `main` enthalten (`ahead_by=0`) und wurden über den geprüften einmaligen [GitHub-Actions-Lauf #39392381240](https://github.com/ManuEtt/Dnd/actions/runs/39392381240) entfernt. Auch der kurzlebige Maintenance-Branch ist gelöscht. Die GitHub-Branchliste wurde danach erneut gelesen: **nur `main` vorhanden**. Implementierte Features, Merge-Commits und Pull Requests bleiben erhalten; nichts wurde neu gecherry-pickt. Der temporäre Löschworkflow wurde nach erfolgreicher Bereinigung aus dem Hauptbranch entfernt. Prüfdokument: [`docs/BRANCH_RETIREMENT_20261020.md`](docs/BRANCH_RETIREMENT_20261020.md).

---

## CI-Abnahme und Integration – 20.10.2026 (0.8.18+68)

**CI und Merge bestätigt (20.10.2026):** [PR #46](https://github.com/ManuEtt/Dnd/pull/46) nach grünem [GitHub-Actions-Lauf #39386823499](https://github.com/ManuEtt/Dnd/actions/runs/39386823499), geprüfter Code-HEAD `81635c8eccb0d06e5d1bf95d54f5884c62f4a215`, erfolgreich in `main` integriert. Merge-Commit [`45160602b339c35e23e0d445f4e41e98b9b3dd5e`](https://github.com/ManuEtt/Dnd/commit/45160602b339c35e23e0d445f4e41e98b9b3dd5e). Erfolgreich: Struktur-/Python-Prüfung, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Unit-Tests, Alpha-APK-Artefakte und Quellcode-Checkpoint. **Noch offen:** echter Android-Gerätetest, vollständiges SRD, Held-Shield-Reaktion und verifizierte Gegner-Zauberlisten.

---

## 20.10.2026 – Shield-Reaktion des Gegners (0.8.18+68)

**Basis:** `main` `c48e1452a08057ecdc4f9f526b0b6b5d56903bcb`. Branch `feature/srd-enemy-shield-reaction-20261020`. **Status: Implementiert, CI noch nicht nachgewiesen.**

- Neues `Encounter`-Reaktionsmodell: `enemyShieldSlotsRemaining` (**null** = unbekannt, nicht geraten), `enemyShieldReactionUsed`, `enemyShieldActive`. Historische Spielstände bleiben ohne Änderung gültig, gefälschte unplausible Kombinationen werden beim Import abgewiesen.
- Ein Gegner darf Schild (`Shield`) nur als ausdrücklich bestätigte Reaktion auf `Magisches Geschoss` wirken, wenn vorbereiteter Zauber, verbal/gestische Komponenten, freie Reaktion und bestätigte verbliebene Zauberplätze vorliegen. Der gegnerische Zauberplatz wird genau einmal verbraucht, die Treffer verlieren alle Wirkung; der Held verbraucht trotzdem seine Aktion und den eigenen Zauberplatz. Keine Würfel werden für komplett blockierte Geschosse verbraucht.
- `enemyShieldActive` führt +5 RK bis **zum Beginn des nächsten Gegnerzuges**, sperrt weitere Magische Geschosse und wird bei `_enemyTurn` zurückgesetzt; gegnerische Reaktion wird dann erneut verfügbar.
- Der bestehende Magisches-Geschoss-Dialog bietet einen separaten bestätigten Shield-Reaktionszweig mit manueller initialer Gegnerzauberplatzanzahl. Der bisherige Weg ohne Schild bleibt erhalten, damit alte Controller- und Testaufrufe nicht unbemerkt andere Regeln ausführen.
- Tests für Schaden 0, Würfelaufrufe 0, Zauberplatz- und Reaktionsverbrauch, Shield-RK, Dauer bis zum nächsten Zug, Legacy-JSON, ungültige Daten, SQLite-Neustart und Revisionsschutz in `enemy_shield_reaction_rules_test.dart` und `enemy_shield_reaction_storage_test.dart`. CI/Android-Build **noch offen**, nicht als bestanden ausgeben.
- **Weiter offen:** `Shield` als Heldreaktion auf gegnerische Angriffe, Gegner-Zauberplätze aus verifiziertem Monsterstatblock, echte Monster-KI, tatsächliche Kartenpositionen, vollständig generische Reaktions-/Schadensregeln und Gerätetest.

**Wiederaufnahme:** [PR prüfen](https://github.com/ManuEtt/Dnd/pulls), vollständige GitHub-Actions-Ausführung für den **finalen** PR-HEAD abwarten, gemeldete Flutter-/Dart-/Backend-/Android-Probleme im Feature-Branch korrigieren. Erst bei vollständig grünem CI-Lauf konfliktfrei in `main` mergen; dann README, CHANGELOG, CHECKPOINT, Entwicklungsstatus und Matrix mit dem nachgewiesenen Workflow und Merge-Commit aktualisieren.

## CI- und Merge-Abnahme 20.10.2026 – Version 0.8.17+67

**CI-Freigabe und Integration 20.10.2026:** [PR #44](https://github.com/ManuEtt/Dnd/pull/44) wurde nach erfolgreich abgeschlossener [GitHub Actions #39383477544](https://github.com/ManuEtt/Dnd/actions/runs/39383477544) (finaler geprüfter Head `8f703b0002ae6dcb5279893020bea63e14771184`) nach `main` gemergt; Merge-Commit [`fa2ee36caff2c210eabaa651321b9591de46737f`](https://github.com/ManuEtt/Dnd/commit/fa2ee36caff2c210eabaa651321b9591de46737f). Bestanden: Struktur-/Python-Tests, Backend Typecheck/Build/Tests, Dart format, Flutter analyze/test, Android-Debug-Build, native Android-Tests und Release-APK-Artefakte. **Weiter offen:** echter Android-Gerätetest, vollständige Shield-Reaktionsmechanik, allgemeine Monster-Abwehr und komplette SRD-Abdeckung.

---

## Inkrement 0.8.17+67 – Gegnerische Energieschaden-Abwehr (20.10.2026)

**Basis:** `main` `5c0882644283b63225774d4e88f7e7fdd493dafe`, Branch `feature/srd-missile-force-defense-20261020`. **Status beim Erstellen: implementiert, CI-/APK-/Gerätetests noch nicht bestätigt.**

- `Encounter.enemyForceDefense` enthält nun `unknown`, `normal`, `resistant`, `immune` oder `vulnerable`. Historische Spielstände ohne Feld bleiben `unknown`, werden nicht rückwirkend umgedeutet. Falsche/unbekannte Importwerte werden zurückgewiesen. Keine SQLite-Tabellenmigration erforderlich (vorhandenes JSON-Ereignismodell).
- `EnemyForceDefenseRules` integriert `DamageRules` und wendet Resistenz (abrunden), Immunität und Verwundbarkeit auf **jedes einzelne Geschoss** an, nicht auf die Gesamtsumme. Alle Werte werden im `spell.magicMissile`-Journal (roh und angewendet) protokolliert.
- Neue Gegnerabwehr-Auswahl im bestehenden `MagicMissileDialog`: Ohne bestätigten Wert ist das Wirken gesperrt. Ein bereits gespeicherter bestätigter Wert kann beim nächsten Mal wieder verwendet werden; Änderungen müssen erneut bestätigt werden. Getrennte Pflichtbestätigung: Kein wirksamer Schildzauber (Shield). Kein unbestätigtes Gegnerprofil und keine KI-Erzählung erzeugen eine Abwehr.
- Zauberplätze, Runde, HP, Abwehr und Journal werden erst nach der Regelprüfung und der Bestätigung in derselben Repository-Transaktion gespeichert. Altes `noProtectionConfirmed`-API bleibt für bisherige Aufrufer kompatibel, sofern der Nutzer ausdrücklich keine Schutzwirkung bestätigt.
- Tests `enemy_force_defense_rules_test.dart`, `enemy_force_defense_storage_test.dart`, angepasster `magic_missile_dialog_test.dart`: Resistenz-Rundung je Geschoss, Immunität, Verwundbarkeit, unbekannter Altspielstand, manipulierte JSON-Werte, bestätigte UI-Auswahl, SQLite-Neustart, veraltete Revision. Bestehende Magic-Missile-Rollback-Tests bleiben erhalten.
- **Noch offen:** tatsächlich ausgeführter Shield-Reaktionszauber mit Ressourcen und Dauer, generisches getyptes Monster-Immunitätsprofil über alle Schadensarten, vollständiger Mehrzielkampf, Gegnerinventar und Gerätetest.

**Nächster Schritt/Wiederaufnahme:** vollständigen CI-Workflow auf dem finalen PR-HEAD verfolgen (Backend, Python, Dart format, Flutter analyze/test, Android-JVM und APK-Build). Fehler im selben Branch korrigieren; erst nach grünem Endergebnis mergen. Danach Merge-Commit und exakten GitHub-Actions-Lauf hier nachtragen.

## Abnahme- und Merge-Nachtrag 20.10.2026

**CI und Integration bestätigt (20.10.2026):** [PR #42](https://github.com/ManuEtt/Dnd/pull/42) wurde nach vollständig erfolgreicher [GitHub Actions CI #39381087593](https://github.com/ManuEtt/Dnd/actions/runs/39381087593) (geprüfter Head `78d89230281f8196edbff628ca243d591ef092b3`) nach `main` integriert. Merge-Commit: [`259dcf69fa2471c5546e1ba1b1003cef148e1cb9`](https://github.com/ManuEtt/Dnd/commit/259dcf69fa2471c5546e1ba1b1003cef148e1cb9). Erfolgreich: Python-Projektprüfung, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse/Tests, Android-Debug-APK, native JVM-Tests, drei Alpha-APK-Varianten und Artefaktbereitstellung. **Ein realer Gerätefunktionstest und die vollständige SRD-5.2.1-Abdeckung bleiben offen.**

---

## 20.10.2026 – Magisches Geschoss (SRD 5.2.1, Version 0.8.16+66)

**Ausgangsbranch:** `main` `963fe9e0eb38fb3f5595fe4325031cf619782f95`. **Status: Implementiert, GitHub-CI / Geräteabnahme noch offen.** Eine erfolgreiche CI darf erst nach einem beobachteten erfolgreichen Workflow dokumentiert werden.

- `MagicMissileRules`: ausschliesslich bestätigter Zauber eines eigenen Magiers/Zauberers (auch valide Zweitklasse), normale oder Paktmagie-Zauberplätze, 3 Geschosse bei Grad 1 +1 je höherem Zauberplatz, jedes einzeln `1W4+1` Energieschaden mit kontrollierter Zufallsquelle. Französische oder andere nicht nachgewiesene Schreibweisen werden nicht erfunden; Deutsch und Englisch ausdrücklich unterstützt.
- Zielprüfung: aktueller einzelner Gegner, Spieler bestätigt Sicht, max. 120 Fuß Reichweite, V/S-Komponenten und Fehlen bekannter Schutzwirkung; vollständige Deckung sperrt den direkten Effekt. Ungeprüfte Immunität, Resistenz, Schildzauber und Feindposition werden **nicht** automatisch abgeleitet.
- `GameEngine.castMagicMissile`: eigene Magieaktion, maximal ein zum Wirken verbrauchter Zauberplatz pro Zug, Kampfrausch-/Aktionsschub-/Wurfblockaden, Gegner-TP, Questabschlusspfad, Revisionssicherung und `spell.magicMissile`-Ereignis in einer atomaren Änderung.
- `GameController.castMagicMissile` mit `expectedRevision`; `MagicMissileDialog` mit Auswahl einer eigenen Zauberklasse, verfügbarer Plätze, Vorschau und expliziten Kontrollkästchen. Charakterwerte und Inventar bleiben unverändert, wenn die Prüfung fehlschlägt.
- Neue Tests: `magic_missile_rules_test.dart`, `magic_missile_storage_test.dart`, `magic_missile_dialog_test.dart`: Würfel, Skalierung, Klassen und Mehrklassen, Fehler vor Zufall, Spielzug, UI, JSON, SQLite-Neustart, Revisionskonflikt und Rollback. **Testausführung und Android-APK-Prüfung stehen beim Commit dieses Eintrags noch aus.**
- **Abgrenzung:** Nur ein Gegner ohne bekannte defensive Sonderwirkung; keine frei verteilten Geschosse an mehrere Ziele, keine autonome Monster-/Positions-/Gegenzauberlogik, kein Vollständigkeitsanspruch für SRD-Zauber.

**Wiederaufnahme:** PR-HEAD und offenen CI-Lauf ermitteln; `python3 scripts/verify_project.py`, `python3 -m unittest discover -s scripts/tests -v`, Backend `npm ci && npm run typecheck && npm run build && npm test`, Flutter `flutter pub get && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build apk --debug` und Android `./gradlew :app:testDebugUnitTest --no-daemon` kontrollieren. Fehler in eigenem Branch beheben, CI erneut durchführen, erst bei vollständigem Grün PR nach `main` integrieren und Testergebnisse dokumentieren.

## Abnahme- und Integrationsnachtrag – 20.10.2026

**Abnahme nach Merge:** [PR #40](https://github.com/ManuEtt/Dnd/pull/40) vollständig über [CI-Lauf 39378443958](https://github.com/ManuEtt/Dnd/actions/runs/39378443958) am Code-HEAD `3462106592157953473c7d777b0d5b664872243a` mit **success** geprüft: Projekt-/Python-Strukturtests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Unit-Tests, drei Alpha-APK-Varianten und Artefakterstellung. Am 20.10.2026 konfliktfrei nach `main` gemergt: [`f7c6a68c09155880fd9a08b0c2f308d324b27b82`](https://github.com/ManuEtt/Dnd/commit/f7c6a68c09155880fd9a08b0c2f308d324b27b82). **Nicht geprüft:** echter Android-Gerätetest, Langzeitmigration auf Nutzergeräten, vollständiges SRD-Regelwerk.

---

## 20.10.2026 – SRD-Regelinkrement: bestätigtes Kriechen (0.8.15+65)

**Basis:** `main` `f06fb2ffac476ceec0dee2a4c6979d972e0c1a72`; Branch `feature/srd-crawling-20261020`, Code-Commit `72f51dd0b1af24069dc95bdd68f3535908f24024`, Test-Commit `4b0154dc85ad3e1a507baaddf82a018b31a725d1`. **CI-/Geräteabnahme vor Ausführung: offen.** Kein vollständiges SRD beansprucht.

- Neue `CrawlingMovementRules` berechnen die SRD-5.2.1-Bewegungskosten: pro Fuß Kriechstrecke 2 Fuß Bewegungsbudget beziehungsweise 3 Fuß bei bestätigtem schwierigem Gelände.
- `GameEngine.crawl` prüft aktiven eigenen Kampfzug, Liegend, Bewegungsbudget, Würfel-/Todesrettungsstatus und positive Geschwindigkeit. Die Aktion verbraucht weder Aktion noch Bonusaktion; zuvor bestätigte Deckung entfällt. Erzählung allein darf das Gelände nicht bestimmen.
- Neues „Kriechen“-Menü in der Abenteuer-UI: 1,5 m oder 3 m, jeweils normales oder schwieriges Gelände, mit vorab angegebenen Kosten. Auswahl bestätigt genau diese regelgeprüfte Bewegung.
- `GameController.crawl` verwendet Revisionsschutz und atomaren `combat.crawled`-Ereigniseintrag; aktuelles Schema und historische Speicherstände bleiben unverändert.
- Neue Tests `prone_crawling_rules_test.dart` und `prone_crawling_storage_test.dart` für Terrainkosten, Statussperren, Budget, Dezimeter, JSON-Rundlauf, SQLite-Neustart, veraltete Revision und Transaktions-Rollback. **Vor GitHub-Actions-Ausführung nicht als bestanden kennzeichnen.**
- **Offen:** vollständiges Positions-/Kartensystem, Gegnerbewegung, Terrain aus verifizierter Kartengeometrie, umfassende Zauber-/Klassen-/Monsterregeln, Android-Geräteabnahme.

**Prüf- und Wiederaufnahmebefehle:** `python3 scripts/verify_project.py`, `python3 -m unittest discover -s scripts/tests -v`; in `backend/`: `npm ci && npm run typecheck && npm run build && npm test`; in `app/`: `flutter pub get && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build apk --debug`; in `app/android/`: `./gradlew :app:testDebugUnitTest --no-daemon`. CI/PR prüfen, Abweichungen beheben, **erst bei Grün** in `main` mergen. Danach hier Merge-SHA und GitHub-Actions-Lauf dokumentieren.

## 19.10.2026 – Integration statt konkurrierender Entwicklungszweige

Neuer Branch `integration/character-creation-20261019`: PR #11 in `main`, getypte Ausrüstung und Startkampfwerte aus PR #9 ergänzt (drei konfliktfreie Code-Diff3-Dateien plus neue Module und Tests). PR #10 und #11 hatten konkurrierende Aufstiegsassistenten. Einziger verbleibender Dialog ist `SrdClassLevelUpDialog`; die einzigartige ASI-Validierung und rückwirkenden Konstitutions-TP aus PR #10 wurden dort und im Regelmodul eingearbeitet. Die Integrationsregressionen sind neu zu prüfen. Gemeinsame Tests/CI/Android-Build noch ausstehend; keine hundertprozentige SRD-Abdeckung behaupten.

## 19.10.2026 – RK/Bewegung grün im CI

Für PR #9: Verifizierter GitHub-Lauf [39201449428](https://github.com/ManuEtt/Dnd/actions/runs/39201449428), Code-HEAD `2f7ecb15`: Backend-, Dart-Format-/Analyse-, alle Flutter-/Widgettests, Debug-APK, native Android-Tests und kompakte Alpha-APKs erfolgreich. Die vorherige Teststörung (Lazy-ListView Finder bei nicht sichtbarem Bewegungsfeld) wurde korrigiert. Der Sourcecode-Fix inklusive exakter 10,5-m-Spezieswerte ist erfolgreich getestet; Android-Gerätetest und Integration in `main` noch offen.

---

## 19.10.2026 – Fehlerbild Rüstungsklasse und Bewegung ohne Startwerte

Bei der Charaktererstellung wurden `armorClass` und `speed` bisher nicht aus der gewählten SRD-Spezies und den bestätigten Attributen vorbelegt. Der Fix setzt Grund-RK 10 + GE bzw. die relevanten ungerüsteten Klassenmerkmale (Mönch WEI, Barbar KON). Bewegung wird über explizite Speziesnamen gesetzt (meist 9 m, Goliath/Waldelf 10,5 m), mit rückwärtskompatiblem optionalem halben Meter im Hero-JSON. Beim Import alter/anderer Figuren werden keine Werte erraten oder überschrieben; die UI bietet einen gesonderten Button „Fehlende RK und Bewegung berechnen“. Ausrüstung wird weiterhin gesondert angelegt und mit dem bestehenden SRD-EquipmentRules-Dialog berechnet.

Neue Domain-/Widgettests vorhanden, **diese Änderung muss noch durch die neueste CI verifiziert werden**. PR #9 bleibt vorläufig Entwurf, PR #8 ist davon getrennt. Das Gesamt-SRD ist weiterhin nicht vollständig implementiert.

---

## 19.10.2026 – Fehlerbehebung Klassen-Startausrüstung

Root Cause bestätigt in `CharacterEditor._configureSrdClass`: Einträge aus dem SRD-Klassenset wurden bisher ohne `catalogId` und `stats` erstellt, obwohl der SRD-Katalog diese Attribute besitzt. Neuer validierter Resolver `StartingEquipmentImport`: exakte Namen, selektiv geprüfte Aliasnamen, richtige Packgröße für 20 Pfeile, unbekannte Auswahlen ohne erfundene Werte. Der bestehende Katalogimport übernimmt jetzt verfügbare Kataloghinweise. Eingehende Gegenstände mit expliziter `catalogId` und fehlenden Stats werden vervollständigt; Benutzerwerte bleiben immer erhalten. Eigener Bestätigungsdialog für ältere Klasseninventare im Charaktereditor. Domain-/Widgettests ergänzt.

Entwicklungsbranch: `fix/equipment-import-attributes-20261019` ab `82f2786b`, PR #8 bleibt separater ungemergter Entwicklungszweig. Gesamtregelwerk ist nicht vollständig; SRD-5.2.1-Anforderungsmatrix und künftige vertikale Klassen-/Zauber-/Kampf-/Erkundungstests sind nötig. Build-/APK-Abnahme für diesen neuen Fix noch ausstehend.

---



---

## 19.10.2026 – Klassenaufstieg und Erstellungsprüfung (laufender PR)

Branch `feature/srd-character-level-up-20261019`: neue regelgeprüfte Stufe +1 für alle 12 vorhandenen Klassen, inkl. bereits gewählter Zweitklasse, bestätigter fester Trefferpunkte, gültiger XP-Schwelle oder ausdrücklichem Meilenstein, Klassentabellen-Vorschau und Persistenz offener Entscheidungen als Notiz. Neue SRD-Erstellungsprüfung für Stufe-1-Daten mit klaren Hinweisen auf noch nicht implementierte Herkunfts- und Klassenentscheidungen. Tests für Domäne und UI angelegt.

**Stand vor endgültiger CI: NICHT ABGENOMMEN.** Weder alle Klassenmechaniken noch das vollständige SRD 5.2.1 sind implementiert. Offene Regel-ID-Matrix und nächste Arbeiten siehe `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md`.

---

## 19.10.2026 – SRD 5.2.1 Aufstehen aus „liegend“

Nach der Übernahme von PR #7 in `main` wurde der neue Branch `feature/prone-stand-movement-20261019` von `82f2786b` abgezweigt. Implementiert sind ein ausdrückliches Aufstehen mit bestätigter Bewegungsrate, genauem Fuß-Rundungsmodell im vorhandenen Meter-System (Dezimeterrest), Abzug des verbleibenden Budgets, Schutz bei Bewegungsrate 0/Handlungsunfähigkeit/noch aktiver Quelle und ein deutscher Abenteuer-Button. `GameController` prüft die erwartete Revision und persistiert Ereignis + Bewegungsstand gemeinsam in SQLite. Ein Editor kann den Zustand während des Kampfes nicht ohne Bewegungskosten löschen; normales Gehen im Liegen wird nicht als kostenloser Lauf gewertet.

Neue Regeln und Speicherregressionen: `prone_standing_rules_test.dart`, `prone_standing_storage_test.dart`. Schema-Version 1 bleibt erhalten; neue Bewegungsreste sind optional. **Abnahme und Android-Build noch zu überprüfen**, ebenso echte Geräteinteraktion, Kriechen, Fremdziele und Positionen. Dokumentation in README und CHECKPOINT nachführen, sobald der vollständige PR-Workflow erfolgreich ist.

---

## Weiterentwicklung 19.10.2026 – Bewusstlos bewirkt bleibendes Liegend

Der geprüfte Featurebranch `feature/condition-source-ledger-20261018` (PR #7, letzte grüne Basis `c000e78b` / Actions 39165288268) wird um die SRD-5.2.1-Folge `bewusstlos` → `liegend` erweitert: neue Bewusstlosigkeit aus Schaden, Todesrettungen, Quellzuständen und bestätigten Charakteränderungen setzt `liegend` getrennt. Die Folge überlebt das Aufwachen, Quellenende und JSON-/SQLite-Bestätigung; Legacy-Daten werden beim Lesen nicht automatisch migriert. Handlungsunfähigkeit durch bestätigte Charakterbogenänderung beendet Konzentration. Acht neue Testfälle sind unter `unconscious_prone_test.dart` eingereicht.

**Prüfstatus dieses Inkrements: NICHT ABGENOMMEN.** Neue GitHub-Checks, APKs und Gerätetests erst nach verifiziertem Erfolg eintragen. Nächster Schritt: offizielle Dart-Formatierung, kompletter CI-Lauf, eventuelle Testkorrekturen, danach reale Android-Abnahme. Weitere SRD-Folgen (Fallenlassen gehaltener Gegenstände, Aufstehen/Kriechen und Positionsregeln) noch offen.

---

## Laufender GitHub-Entwicklungsbranch – quellgebundene Zustände (18.10.2026)

- PR [#7](https://github.com/ManuEtt/Dnd/pull/7) gegen `main`; kein Merge und keine Veränderung von `main`.
- Quellenabhängige 2024-SRD-Zustände als eigene validierte `ConditionEffect`-Einträge, optionales JSON-Feld, deduplizierte effektive Zustände. Reine Domänenaktionen für Einzelentfernung, Gesamtentfernung und eigenen Zugendpunkt; vorhandene Regelmutatoren bewahren die Trennung.
- Regelanzeige/Quellenanzeige im Charakterbogen; manuelle Einträge bleiben separat editierbar. Neue Domain-/Widgettests wurden eingereicht; Ergebnis des endgültigen PR-CI ist vor Freigabe zu prüfen.
- **Ergänzt im gleichen PR:** bestätigte UI-/Controller-Aktionen für Quellen und Einzelentfernung; neue Handlungsunfähigkeit beendet Konzentration/Rage/Dodge sofort. Domänen-, Dialog- und SQLite-Konflikt-/Rollbacktests ergänzt. README aktualisiert.
- **Noch offen:** erfolgreiche endgültige CI-/APK-Abnahme aller Änderungen, Geräteabnahme, allgemeine Weltzeit und breitere SRD-Effektmechaniken. Keine vollständige SRD-Abdeckung behaupten.
- Checkpoint: PR #7 und dieser Branch. Ein neuer Lauf muss HEAD/PR-Checks erneut abfragen und erst bei grünem Status weiter integrieren. Kein automatischer Codex-Workflow.

## Abschlussprüfung 0.7.9+49 (18.10.2026)

**692 Flutter-, 31 Backend-, 56 Python- und 12 native Androidtests bestanden, 0 Fehler/Skips.** Analyse/Format sauber, korrigierte Debug-APK aus entpacktem geprüftem ZIP gebaut; Integrität, Metadaten, Signatur und 203 Quell-/Test-/Builddateien verglichen. Geprüfter Codecommit `99b8a7bbed9c07132bf49e5eb78be9cfeb391d71`; finale Dokumentation folgt separat. GitHub-Push erneut HTTP403, main unverändert; ZIP/Patch/Importanleitung vorhanden. Exakte Fortsetzung: CHECKPOINT.md, Prüfbericht docs/VALIDATION_0_7_9.md.

Nächster zusammenhängender Schritt: quellgebundene Zustände/Dauern gemäß docs/CONDITION_EFFECT_DESIGN.md implementieren, mit Trennung manueller/abgeleiteter Zustände und echten UI-/Speichertests. Danach Konzentrationswiederholungen/Reaktionen sowie weitere echte Ziele/Zauber-/Monsterwirkungen. Keine vollständige SRD- oder Geräteabnahme behauptet. Vor neuer großer Arbeit einen vollständigen Ausgangscheckpoint sichern; beobachtete frühere Teilagenten-Limitwarnungen nicht durch Credits/Resets umgehen.

## 0.7.9+49 – Todesrettungen mit Klassenentscheidung (18.10.2026)

- Todesrettungen verwenden jetzt Mönch-14-Rettungswurfübung und den Erschöpfungsmalus genau einmal. Natürliche 1/20 behalten ihre Sonderfolgen; Kämpfer-9-Unbeugsam addiert beim Ersatzwurf die tatsächliche Kämpferstufe.
- Ein fehlgeschlagener Wurf mit verfügbarer Wiederholung bleibt vorläufig: deutsche Auswahl zum Annehmen oder Wiederholen, mit Neustart erhaltener Entscheidung. Auch ein drohender dritter Fehlschlag lässt sich ersetzen. Verbrauch und Folgen werden erst gemeinsam bestätigt.
- Im aktiven Solokampf nur eine Todesrettung pro eigenem Zug; anschließend bewusstlos den Zug beenden oder nach natürlicher 20 normal fortsetzen. Gegnerzug, offene Entscheidung, veraltete Oberfläche und manipulierte Importe sind gesperrt.
- Kampfrausch und Ausweichen enden auch bei extern bestätigtem KO und beim Bestätigen handlungsunfähiger Charakterzustände sofort; spätere Heilung reaktiviert keinen alten Kampfrausch.
- 57 neue gezielte Fälle sowie 10 bestehende Erschöpfungsregressionen erfolgreich: 19 Todesrettungs-Domänenfälle, 18 Ablauf-/UI-/SQLite-Fälle und 20 Zuggrenzenfälle. Gesamtprüfung und Android-Build werden separat in CHECKPOINT.md nachgewiesen. Quelle und genaue Grenzen: docs/DEATH_SAVES_0_7_9.md.

## 0.7.8+48 – Korrekte eigene Zuggrenzen (17.10.2026)

- Reines Zugende trotz Handlungsunfähigkeit, auch für stabile bewusstlose Figuren; eigener UI-Button und atomare SQLite-Speicherung. Keine Ausweichaktion durch Textbeimischung.
- Kampfrausch endet vor dem folgenden Gegnerangriff, wenn sein Endzeitpunkt erreicht ist, sowie endgültig bei Handlungsunfähigkeit. Ausweichen verliert Wirkung bei Handlungsunfähigkeit, Sichtverlust oder Bewegungsrate0; positive halbe Meter bleiben positiv.
- Mönchs-Selbstwiederherstellung kann ohne Aktion vor dem eigenen Zugende ausgewählt werden. Feindlicher Initiative-Erstzug löst kein eigenes Zugende aus.
- 17 neue Grenz-/UI-Tests erfolgreich; aktuelle Analyse ohne Befunde. Generische Zustandsdauer bleibt ausdrücklich Entwurf, siehe docs/CONDITION_EFFECT_DESIGN.md.

## Abschlussprüfung 0.7.7+47 (17.10.2026)

**635 Flutter-, 31 Backend-, 56 Python- und 12 native Androidtests erfolgreich**, keine Skips/Fehler; Analyse und Formatierung sauber. Debug-APK tatsächlich aus entpacktem Quell-ZIP gebaut, Integrität/Metadaten/Signatur geprüft. Gerät/Emulator/Updatesignatur nicht abgenommen. GitHub-Write HTTP403; main unverändert. Finale ZIP-/Patch-/Hash-Artefakte und exakte Fortsetzung in CHECKPOINT.md; ausführlicher Prüfbericht docs/VALIDATION_2026_10_17.md. Umfang bleibt eine Teilmenge des SRD5.2.1.

## 0.7.7+47 – Ausführbare Heilzauber im Spiel (17.10.2026)

- Wunden heilen und Heilendes Wort wirken auf den eigenen Charakter: 2024-Würfel (2W8/2W4 pro tatsächlichem Platzgrad), eigenes Klassenattribut, Hochstufung, normale/Pakt-Plätze und Lebensdomänenboni (Kleriker 3/17).
- Deutsche Auswahl mit Klassen-/Platz-/Komponentenbestätigung direkt im Abenteuer/Kampf. Ereignis, TP, Platz und Aktion werden atomar bestätigt; keine automatischen Regeln aus Erzähltext.
- Persistenter Zugschutz: nur ein Platzverbrauch für Zauberwirken je Zug, gemeinsam für normale und Paktplätze; reset erst beim nächsten eigenen Zug. Alte Begegnungen bleiben lesbar. Action Surge erlaubt keine zusätzliche Magieaktion.
- 26 Domain-, 13 Dialog- und 9 Integrationsfälle geprüft. Vollständige Formatbereinigung und verpflichtende Formatprüfung im normalen Test-/Buildworkflow, keine autonome Codex-Action.
- Vollständige Suite und Android-Prüfung werden im aktuellen CHECKPOINT.md getrennt nachgewiesen. Umfang/Grenzen: docs/CHARACTER_EFFECTS_AND_HEALING.md.

## 0.7.6+46 – Ausführbare Charaktereffekte (17.10.2026)

- Gemeinsamer Schaden-/Konzentrationsablauf für bestätigte externe Quellen und Gegnerangriffe: Abwehr vor temporären/echten TP; auch absorbierter Schaden löst Konzentration aus.
- Deutsche Oberfläche für Schaden, Heilung und temporäre TP mit Quelle und bestätigten Abwehrregeln. Atomare Speicherung und Revisionsschutz für offene Dialoge.
- Versteinert-Schadensresistenz und automatische Stärke-/Geschicklichkeitsfehlschläge bei gelähmt/versteinert/betäubt/bewusstlos; betäubt sperrt Bewegung nach 2024 nicht generell.
- 50 gezielte Domain-/Kampfregressionen, 6 Dialogtests und 7 echte UI-/SQLite-Tests erfolgreich; Flutter-Analyse ohne Befunde. Details im Checkpoint.

## 0.7.5+45 – Verifizierte Korrekturen (17.10.2026)

- Basis `b66354f3112165d76aa340a2f2ab5705f8019e1a`, eigener Branch `feature/autonomous-srd-engine-20261016`; keine Änderung von main.
- Erschöpfte offene Proben überleben Speicherung/Neustart. Schaden bei 0 TP mit temporären TP korrigiert. Zwei Backendfehler korrigiert (leere Handlungsstränge, Redirects).
- Flutter 3.35.7/Dart 3.9.2 lokal installiert: Analyse ohne Befunde; Suite 544 erfolgreich, 1 optionaler Backend-Protokolltest übersprungen. 30 gezielte Flutter-Regressionsfälle erfolgreich. Backend unter CI-Node 22.14.0: Typecheck, Build und 31 Tests erfolgreich.
- Ursprüngliche Formatprüfung meldete 84 unformatierte Dateien; Formatbereinigung folgt isoliert nach Integration. Android-Build/Gerät weiterhin gesondert nachzuweisen.
- `docs/RULE_COVERAGE.md` und `CHECKPOINT.md` sind die aktuelle Fortsetzungsbasis. Allgemeine Effekte/Heilzauber folgen als getrennte Inkremente.

## 0.7.4+44 — Tatsächliche Implementierung (16.10.2026)

- **BASIS:** vollständiges Quellprojekt 0.7.3+43; GitHub `main` wurde bei der Entwicklung als 0.7.2+42 (`91ffddd`) gelesen.
- **NEU:** Paladin-Handauflegen (Bonusaktions-/Ressourcenlogik und Entgiftung), Mönch-15-Perfect-Focus in der Initiative, explizite W20-Rettungswürfe mit Mönch-14- und Kämpfer-9-Wiederholungswurf, Speicherung/Ereignisse/UI.
- **GEPRÜFT:** 38 Python-Projekttests, Projektdateistruktur, Patch-/ZIP-Integrität nach Verpackung.
- **OFFEN:** Flutter analyze, Dart-Test-Suite, Android-Build, echte Gruppenmitglieder, automatisch ausgelöste Rettungswürfe aus allen Quellen, verbleibende SRD-Regelengine. Die 1.247 Anforderungen sind keinesfalls vollständig umgesetzt.
- **DETAILS:** `docs/CLASS_ACTIONS_AND_SAVES_0_7_4.md`.

## 0.7.3+43 – Mönch-Selbstwiederherstellung und alle Rettungswurfübungen (16.10.2026)

- **BASIS:** GitHub `ManuEtt/Dnd` main `91ffddd246a3aa07780bf1bbafa9ce2c17726e21` / 0.7.2+42.
- **IMPLEMENTIERT:** Stufe-10-Selbstwiederherstellung am Ende eines bestätigten eigenen Kampfzugs, eindeutige Zustandsauswahl bei mehreren, optional gespeicherte Auswahl und Ereignisnachweis; Stufe-14-Rettungswurfübung (alle sechs, ohne doppelte Berechnung); CI-Fix `monk_flurry_rules.dart` für `int?`.
- **GETESTET:** Projektstruktur, 38 Python-Projekttests, ZIP-/Patchintegrität (siehe Übergabebericht).
- **NICHT GETESTET:** Neue Dart-Domain-/Widgettests, `flutter analyze`, vollständige Flutter-Test-Suite, Android APK und Gerät. Kein Flutter SDK vorhanden.
- **OFFEN:** Disziplinierter-Überlebender-Wiederholungswurf nach fehlgeschlagener Rettung, Hunger-/Durst-Erschöpfungslogik, weitere Klasse- und Ziel-Effekte, voller Android-Build.
- **QUELLE:** SRD 5.2.1, CC BY 4.0. Siehe `docs/MONK_SELF_RESTORATION_0_7_3.md`.

## 0.7.2+42 – Temporäre Trefferpunkte, Monk Heightened Focus (16.10.2026)

- Basis: GitHub `ManuEtt/Dnd`, Commit `73c5bfe5f39b5f3189eec5dc5aeeebe5fc083fa2` (0.7.1+41).
- Implementiert: temporäre TP als getrennte, persistierte Ressource; Schaden absorbieren, HP-Überhang korrekt berechnen, Verlust nach Langrast, Anzeige und Ereignisnachweise.
- Geduldige Verteidigung auf Mönchsstufe 10+: 2 Kampfkunstwürfel für einen Fokuspunkt, Schutz gegen Stapelung.
- CI-Hinweis `unnecessary_non_null_assertion` aus GitHub-Actions-Lauf 38866660863 korrigiert.
- Neue Dart-Domain-/Widgettests enthalten; Flutter-/APK-Tests erst nach CI als bestanden melden.

## 0.7.1+41 – Schlaghagel als ausführbare Bonusaktion (16.10.2026)

- **BASIS:** GitHub `main` `47b549125d95973b2d9e066e9a2401488ef322d2` (0.7.0+40).
- **NEU:** zwei beziehungsweise drei unabhängige Mönchs-Unarmed-Strikes nach SRD 5.2.1; Fokuspunktverbrauch, Bonusaktionslimit, eigener Treffer-/Krit-/Schadenswurf, Mehrklassen-Skalierung, Siegauflösung, UI-Schaltfläche und JSON-Persistenz ohne Schemaänderung.
- **CI-FIX:** Fehler aus Run `38857593290` (473 Tests erfolgreich, 2 fehlgeschlagen) gezielt adressiert: `6 m`-Widget-Erwartung und Eingabe „Ich weiche aus“ in laufender Angriffsaktion.
- **TESTS:** neue Dart-Domain- und Integrationsregressionen vorhanden, Flutter/Android in dieser Umgebung nicht ausgeführt. Weitere Grenzen `docs/MONK_FLURRY_0_7_1.md`.
- **GITHUB:** Repository nicht geschrieben; vollständiges ZIP und Patch separat zur Übergabe. Keine APK behauptet.

## 0.7.0+40 – Mönchsfokus & Rückzug (16.10.2026)

- **Neu**: Patient Defense (0/1 Fokus), Step of the Wind (0/1 Fokus), Flinke Aktion: Rückzug; gemeinsamer Bonusaktionsverbrauch, Speichern/Laden der temporären Kampfzustände, Ausweichnachteil beim Gegnerangriff.
- **Tests**: `app/test/monk_focus_actions_test.dart` ergänzt. Python/Flutter/Android-Ergebnisse gesondert dokumentieren; keine nicht ausgeführten Tests als bestanden ausweisen.
- **Grenzen**: Noch keine Flurry of Blows, Level-10-Temp-TP, Gelegenheitsangriffe oder Sprunggeometrie. Die neuen Flags sind keine Belege für deren vollständige Automatisierung.
- **Ausgangsbasis**: GitHub main 7cd36e9bcb7a4533d34bcc95a77ba83d86c2fc4e / 0.6.9+39.

## 0.6.9+39 — Kampf-Klassenaktionen (2026-10-16)

- **IMPLEMENTIERT:** Barbaren-Kampfrausch (Bonusaktion, Ressource, Rundenablauf, Nahkampfbonus, explizit typisierte Resistenz), Flinke Aktion: Sprinten und bestätigter Hinterhältiger Angriff.
- **GETESTET:** Projektstruktur und 38 Python-Tests; ergänzte Flutter-/Dart-Tests noch nicht ausgeführt.
- **OFFEN:** Vollständiges Rage-/Zauber-/Positions-/Reaktionssystem; siehe `docs/CLASS_ACTIONS_0_6_9.md`.
- **GITHUB:** Projektpaket und Patch vorbereitet; kein Commit oder APK-Build behauptet.

## 0.6.7+37 – Fighter-Ressourcen (16.10.2026)

- Basis: GitHub `main` (`de88027f842a9dca80dd58ffccedb5a961551338`).
- Implementiert: Second-Wind-Ressourcen und Heilung als Bonusaktion; Action-Surge-Ressourcen und reservierte zweite Angriffsaktion im vereinfachten Kampf, Einzel-Zuglimit, Kurz-/Langrast-Regeneration und Speicherkompatibilität.
- Behoben: Flutter-Analyzer meldete `dangling_library_doc_comments` in `damage_rules.dart`; freistehenden Kommentar korrigiert.
- Tests: Neue Unit- und Kampfintegrationstests enthalten; Python-Projekttests lokal bestanden. Flutter analyze/test, Backend-Abnahme und Android-APK **nicht lokal ausgeführt**.
- Grenzen: Action Surge im Demo-Kampf nur zusätzliche Angriffsaktion; Tactical Mind, Tactical Shift, Rage und andere Klassenmerkmale noch offen.
- Importhinweise: `docs/CLASS_RESOURCES_0_6_7.md`.

## 0.6.6+36 – SRD-Klassenfortschritt und Extra Attack (16.10.2026)

- Basis: Repo `ManuEtt/Dnd` Commit `26d1d8b` (enthält 0.6.5+35).
- Klassenstufen-spezifische reguläre Extra-Attack-Mechanik integriert, einschließlich Fighter 11/20 und Mehrklassenregel ohne Stacken.
- Zusätzliche Attacken innerhalb einer Angriffsaktion werden einzeln im Kampfsystem abgewickelt. Verbleibende Angriffe in `Encounter` persistiert; altes Schema 1 weiterhin lesbar.
- Charakterbogen um bestätigte Angriffe pro Angriffsaktion und **nur vorausschauende** Meilensteine ergänzt.
- Testerweiterungen: `class_progression_rules_test.dart`, `class_progression_combat_test.dart`.
- Nicht behauptet: vollständiges Level-up, Unterklassen-/Talentwirkungen, vollständiges Aktionssystem, Flutter-Test, Android-Build oder GitHub-Push.

## 0.6.5+35 – SRD-Schadensauflösung und CI-Korrektur (16.10.2026)

- **BASIS:** GitHub `main` `49c8c39af045c6d0e3a78eba23e95383c3c31a84`, identische ursprüngliche Datei-Blob-SHAs aus Actions-Quell-Checkpoint.
- **CI-BLOCKER-KORREKTUR:** Bewegungsformatierung im Charakterbogen liefert bei ganzzahliger Geschwindigkeit `9 m` statt `9.0 m`; halbe Meter bleiben erhalten. Widget-Regression ergänzt. Basis-CI: 413 Tests bestanden, 1 fehlgeschlagen (Charakterbogen).
- **REGELKORREKTUR:** Konzentrations-SG hat gemäß SRD 5.2.1 eine maximale Schwierigkeit von 30; Grenztests ergänzt.
- **NEUE REGELKOMPONENTE:** `DamageRules` für 13 Schadensarten, Resistenz, Anfälligkeit, Immunität, Nicht-Stapelung, Reihenfolge und Mehrfachkomponenten; bewusste `RulesEngine.damageWithDefenses`-Integration. Keine Spezies-/Monsterresistenz aus Freitext erraten.
- **NACHWEIS:** Projektstruktur und 38 Python-Tests lokal erfolgreich. Neu angelegte Flutter-/Dart-Tests, Analyzer und APK-Build **noch nicht ausgeführt**, weil kein Flutter SDK verfügbar ist.
- **OFFEN:** Automatische Anbindung an Monster/Zauber/Charakter-Defensivdaten; vollständige Klassen- und Zauberengine; GitHub-Push (Schreibrechte verweigert, 403). Kein installierbares APK behauptet. Siehe `docs/SRD_DAMAGE_RULES.md`.

## 0.6.4+34 – Zauberressourcen in der gemeinsamen Regelengine (15.10.2026)

- **BASIS:** vollständiges 0.6.3+33-Quell-ZIP; Entwicklung unabhängig von Codex.
- **IMPLEMENTIERT:** `SpellcastingRules`, getrennte Verbrauchspools für normalen Zauberplatz und Paktmagie, persistierte Konzentration; Eingabe über Charaktereditor; Anzeige im Charakterbogen, Rast- und Kampfintegration, Einbeziehung bestehender Modifikatoren für Konzentrationsrettungswürfe; Sicherung und Importvalidierung ohne Schemawechsel.
- **TESTS ERGÄNZT:** `spellcasting_rules_test.dart` und `spellcasting_dialog_test.dart`.
- **NICHT GETESTET:** Neue Dart-Tests, Flutter-Analyse, Android-/Geräte-Build. Kein Flutter SDK vor Ort. Projekt-/Python-Tests getrennt prüfen.
- **OFFEN:** SRD-Zauberkatalog und Zaubergradvalidierung, Aktionsökonomie, Zauberwirkungen, manuelle Konzentrationsrettungen, sonstige Schadensquellen. `docs/SPELLCASTING_RESOURCES.md`.
- **GITHUB:** Kein Push behauptet, keine Codex-Action hinzufügen.

## 0.6.3+33 – bereichsübergreifende D&D-Regelengine (15.10.2026)

- **AUSGANGSBASIS:** Vollständiges Quell-ZIP 0.6.2+32; unabhängig von Codex fortgeführt. Keine GitHub-Änderungen vorgenommen.
- **IMPLEMENTIERT:** Gemeinsamer `CharacterRuleEngine`-Zugriff auf bestätigte Charakterdaten für Initiative, Angriffe, Fertigkeits-/Attributsproben, Rettungswürfe und effektive Bewegung. Erschöpfung, wichtige Zustandsfolgen, Rüstungs-/Waffen-Grenzen und Vorteils-/Nachteilsregeln werden berücksichtigt.
- **KOMPONENTEN:** `GameEngine`, `DiceEngine` via versioniertem `PendingRoll`, Charakterbogen, Ausrüstungsvorschau, Charaktermodell und Eventjournal angeschlossen. Ältere PendingRoll-JSON-Daten enthalten keine neuen Pflichtfelder. Ein AI-Erzähler kann keine eigenen Regelwerte bestätigen.
- **GETESTET:** Projektstruktur und 38 Python-Tests lokal. Neue Dart-Domain- und Widgettests vorhanden. **NICHT GETESTET:** Flutter Analyze, Flutter Unit-/Widgettests, Backend-CI, neue APK und physische Geräteabnahme; Flutter-SDK fehlt in lokaler Umgebung.
- **OFFEN:** Kontextabhängige Zustände/Zauber, Konzentration, begrenzte Zauberplätze, Ressourcen, vollständige Aktionsökonomie, alle SRD-Monster-/Klassenaktionen; schrittweise mit auditierbaren Tests ergänzen.
- **DETAILS:** `docs/UNIFIED_RULE_ENGINE.md`.

## 0.6.2+32 – SRD-Zustände und Erschöpfung (15.10.2026)

- **Basis:** Vollständiges ZIP 0.6.1+31, mit aktuellem GitHub-`main` 45862495f9da abgeglichen. Android CI #38749928875 für 0.6.1+31 war erfolgreich.
- **IMPLEMENTIERT:** Optionale Erschöpfungsstufe 0–6 im Charaktermodell, sichere Importvalidierung, Unveränderlichkeit historischer Snapshots, Tod bei Stufe 6; W20-Mali bei Angriff/Initiative/Wahrnehmung/Todesrettung und reduziertes Kampfbewegungsbudget. Lange Rast reduziert Erschöpfung um eine Stufe. Konservative Auflistung von 14 weiteren SRD-Zuständen mit ausgewählten Aktions-/Bewegungsblockaden; eigener Editorbereich.
- **EINGESCHRÄNKT:** Keine automatisch bestätigte Spielzeit/Dauer, keine automatische Erschöpfungsursache, nicht alle Zauber/Rettungswürfe/Zustandsregeln flächendeckend in jeder Engineaktion angebunden; siehe `docs/CONDITIONS_EXHAUSTION.md`.
- **GETESTET:** Python-Projektstruktur und 38 Python-Regressionstests; neue Dart-Tests ergänzt. **NICHT GETESTET:** Dart-Analyse, neue Dart-Tests, Android-APK und reale Geräteinstallation mangels Flutter-Toolchain.
- **Nächster Schritt:** Gegen laufende Codex-Änderungen auf eigenem Branch zusammenführen, GitHub-CI ausführen, Fehler beheben, danach Gerätetest.

## 0.6.1+31 – Flutter-Analyzer und Rast-Testfixtures (15.10.2026)

- **BEHOBEN:** `srd_equipment_catalog.dart` verwendet für das Gewicht eine einfache Stringinterpolation (`$weightLb`), wodurch der in CI reproduzierte Analyzer-Lint `unnecessary_brace_in_string_interps` entfällt. Keine Änderung der Ausrüstungswerte.
- **BEHOBEN:** Die `HeroCharacter.fromJson`-Fixture in `app/test/rest_rules_test.dart` enthält wieder die erforderliche `species`-Angabe `Mensch`. Sieben vorangegangene Testfehler waren `FormatException: Spezies ist ungültig.` beim Aufbau der Fixture, nicht Regel-Aussagen. Der produktive Importvalidator bleibt unverändert.
- **BASIS:** `main` `0963303fe4802aae9c42739b267e6d33057ef63d`, GitHub Actions #38746011222 (Analyzer-Fehler); früherer Rast-Testlauf #38734808085. Die geänderten Ausgangsdateien wurden gegen ihre Git-Blob-SHAs geprüft.
- **PRÜFUNG:** Projektstruktur, Python-Tests, ZIP/SHA256 sowie saubere Anwendung des Git-Patches auf `0.6.0+30`. Flutter SDK ist in dieser Umgebung nicht vorhanden: `flutter analyze`, `flutter test` und Android-APK-Build sind für 0.6.1+31 **noch nicht nachgewiesen**.
- **NÄCHSTES:** Auf separatem Branch übernehmen, kompletten GitHub-CI-Lauf ausführen; bei neuen Testproblemen Logs analysieren und beheben; bei grünem Lauf APK verwenden. Codex-Actions nicht reaktivieren.

## 0.6.0+30 – Bestätigtes SRD-Ausrüsten (15.10.2026)

- **IMPLEMENTIERT:** Domain-Modul `equipment_rules.dart` mit reiner Vorschau und erneuter Berechnung bei Bestätigung; Inventory-basiertes Anlegen von Rüstungen/Schilden/Waffen und RK-/Waffenwert-Updates im Editor; optionale Felder für ausgerüstete Inventar-Instanz-IDs. Kein heimlicher Goldabzug/Magieeffekt. Quellen/Ausnahmen: `docs/EQUIPMENT_RULES.md`.
- **TESTS ERGÄNZT:** Unit-/Widgettests für AC, Trainingsfolgen, Waffenauswahl, Fähigkeitsschwellen, ungültige Referenzen und Savegames. Sie sind **noch nicht mit Dart/Flutter ausgeführt**.
- **VOR FREIGABE:** Vollständige Flutter-Analyse, alle Widget-/Domain-Tests, Backend, Android-APK-Build, Installations- und Spielstandsprüfung. Codebasis ist das vorherige lokale 0.5.9+29-ZIP; es kann Codex-Änderungen überschneiden, daher kein blinder Merge.
- **ALS NÄCHSTES:** SRD-Effekte von Erschöpfung und Zuständen implementieren; danach begrenzte Zauber- und Klassenressourcen. Vorher neue Tests grün bekommen.

## 0.5.9+29 – SRD-Ausrüstungskatalog (15.10.2026)

- **Ausgang:** Separater Projektzweig auf dem Quellstand `0.5.8+28`, basierend auf GitHub `main` `c635ee376649d02ec37017c01805f2fa4d1a9806`. Parallel zu einer möglichen Codex-Weiterentwicklung, **nicht** direkt in GitHub eingecheckt.
- **IMPLEMENTIERT:** 38 Standardwaffen, 13 Rüstung/Schild-Einträge, Abenteuerausrüstung/Werkzeuge sowie 79 katalogisierte magische Namen, Suchfunktion nach Deutsch/Englisch, Kategorienfilter, Item-Auswahl, optionale Inventar-`catalogId`, Preise in Kupferstücken und reine Rüstungs-KV/RK-Berechnungs-Vorschau.
- **NICHT IMPLEMENTIERT:** Automatisches Anlegen, Rüstungsübung/Einschränkungen in Kämpfen, Einkaufs-Geldtransaktion, vollständige magische Gegenstandseffekte und alle Items aus nicht-SRD-Quellen. Magische Namen sind ausdrücklich nur Katalog/Referenz.
- **GETESTET:** Python-Projektstruktur + 38 Python-Tests, ohne Flutter-SDK. Zusätzliche Dart-Unit- und Widgettests sind erstellt, aber **NICHT ausgeführt**. ZIP, SHA-256 nach Verpackung prüfen.
- **BESTEHENDER CI-BLOCKER AUF BASIS 0.5.8:** GitHub-Lauf #38734808085 mit 355 Flutter-Tests bestanden, 7 Rast-Tests fehlgeschlagen. Der vorherige Quellstand 0.5.7+27 war erfolgreich. Diese Rast-Testfehler wurden im Item-Inkrement nicht bearbeitet.
- **NÄCHSTER SCHRITT:** Katalogänderungen auf einem eigenen Branch mit dem aktuellen Codex-HEAD konfliktbewusst zusammenführen, erst dann `flutter analyze`, alle `flutter test` und Android-APK-Build; die Rast-Testfehler getrennt beheben. Magic-Item-Metadaten pro Eintrag gegen das SRD verifizieren, bevor automatisierte Effekte aktiviert werden.

## 0.5.8+28 – Rast- und Trefferwürfelregeln (15.10.2026)

- **Ausgangsstand:** GitHub `main` `96ae347f61ad4e1c132caa848c1904444976f7d5` (0.5.7+27); die wesentlichen Model-/Engine-Quelldateien anhand ihrer Git-Blob-SHAs mit dem vollständigen lokalen Quellarchiv abgeglichen. Der GitHub-CI-Lauf #38731206833 für **0.5.7+27 ist inzwischen erfolgreich abgeschlossen** (Flutter, Backend und Android-APK). 0.5.8+28 bleibt ungeprüft.
- **IMPLEMENTIERT:** Kurze Rast mit begrenztem klassenspezifischem Trefferwürfelpool (auch zwei Klassen), Konstitution, HP-Maximum und Würfeljournal. Lange Rast regeneriert TP und alle verbrauchten Trefferwürfel. Blockade bei 0 TP, Tod, Kampf, ausstehender Probe, fehlenden Werten und unklarer Rast. Neues Character-Sheet-Detail für freie/gesamte Würfel.
- **Speicher:** Optionale Karte `spentHitDice` mit Sicherheitsvalidierung; alte Schema-1-Daten bleiben lesbar. Die KI kann keinen der Werte setzen.
- **TESTS:** Neue Dart-Domain-, GameEngine- und Flutter-Widgettests geschrieben, aber Flutter/Dart hier nicht installiert. Lokale Python-Tests/Struktur sowie ZIP/Prüfsumme getrennt zu dokumentieren. Keine neue Android-APK als bestanden melden.
- **Offene Arbeit:** Flutter-Analyse und alle Dart-Tests in GitHub Actions; Arbeitszeit/Rastunterbrechungen, 16-h-Regel, Erschöpfung und aufladen klassenspezifischer Ressourcen fehlen noch.
- **Nächster Schritt:** Quelländerungen auf einem neuen GitHub-Branch übernehmen, CI vollständig ausführen, Fehler beheben; bei grüner Pipeline ARM64-APK freigeben.

## Version 0.5.7+27 – CI-Inventartest-Fix (15.10.2026)

- **Ausgangs-HEAD:** `42b9ad37efcfce29bab62a1eae6fcbcc47a7ef73` (`main`), GitHub Actions #38729844876.
- **Vorbefund:** Flutter-Analyse, Backend und Struktur erfolgreich, 351 Flutter-Tests bestanden, 1 Test fehlgeschlagen (`ui_character_editor_test.dart`: „Inventory can be added with quantity through accessible fields“). Die zuvor gescheiterten Schnellaktionstests sind bereits grün.
- **Ursache/Behebung:** Schrittweite 500 beim `scrollUntilVisible` des kurzen Inventarbuttons in langer `ListView` konnte dessen Aufbau/Sichtbarkeit verfehlen. UI-Inventarbutton mit stabilem Key identifizierbar, Test scrollt den Editor mit kurzen Schritten und prüft Hit-Testbarkeit vor `tap`.
- **Lokale Prüfungen:** Projektstruktur, Python-Unittests, Archivintegrität. Flutter/Android-SDK vor Ort nicht vorhanden; kompletter Flutter-/Android-Build erst nach GitHub-Import.
- **Nächster Schritt:** Änderungen gegen den aktuellen GitHub-HEAD prüfen/importieren, anschließend `flutter analyze`, `flutter test`, Android-Build und native Tests in Actions. Bei Fehlschlag Logs ansehen, keine APK als fertig behaupten.
- **Codex:** Der separate automatische Codex-Workflow bleibt gelöscht; nur normaler Android-Build unter `.github/workflows/android-build.yml`.

## Stand 0.5.6+26 – lokale Korrektur der drei CI-Widgettestfehler (15.10.2026)

- **GitHub-Basis:** `main` `a8e77778c171132c9d9cabdb56d5a19c9e170953` (0.5.5+25), Actions-Lauf https://github.com/ManuEtt/Dnd/actions/runs/38728029583. Keine externen Dateien überschrieben.
- **Bestätigter Vorfehler:** 349 bestandene und drei fehlgeschlagene Flutter-Tests. Fehler: Tastatur-Erkennung der Docküberschrift; Layout-Overflow bei 320dp und Schrift 180%; Inventar-Button außerhalb 800x600-Testviewport.
- **Implementiert:** Behebung der drei Ursachen in `fantasy_art.dart`, `ui_character_editor_test.dart` sowie erweiterten Schnellaktions-Regressionstests. Eine separate `app/pubspec.yaml`-Versionsnummer `0.5.6+26` identifiziert diesen Quellstand. Keine Änderungen an Regellogik, SQLite-Daten, API-Verträgen oder App-Paket-ID.
- **Getestet:** Python-Projektstruktur, Python-Regressionstests, Archive-/SHA-256-Integrität lokal zu prüfen und separat zu dokumentieren. **Flutter SDK und Android SDK nicht verfügbar; Flutter-Test/Analyse und Android-APK dieser Version in CI noch offen.**
- **Letzter grüner GitHub-CI-Stand:** 0.5.1+21, Lauf https://github.com/ManuEtt/Dnd/actions/runs/38706060048. Neuere Alpha-Versionen nicht als bestätigt bezeichnen.
- **Codex:** Workflow `autonomous-development.yml` ist auf dem GitHub-Branch entfernt, nur regulärer Android-Workflow vorhanden.
- **Nächster Schritt:** Vollständiges Projekt auf eigenem Branch einspielen, GitHub Actions prüfen. Falls weiterer Widgettest scheitert, Logs lesen und nachbessern. Danach ARM64-APK aus dem bestätigten Build abrufen und Android-Gerätetest durchführen.
- **Schreibberechtigung:** GitHub-Connector hatte bei früheren Create/Delete-Versuchen HTTP 403; es wird kein Push als erfolgreich behauptet.

## 0.5.5+25 – untere Schnellaktionsleiste (15.10.2026)

- **Implementiert:** Abenteuer-Schnellaktionen `Sprache`, `Untersuchen`, `Angriff`, `W20` als feste `Scaffold.bottomNavigationBar` auf der Abenteuerseite, zwischen Eingabebereich und Hauptnavigation. Doppelte `Sprechen`- und `Würfeln`-Bedienelemente im Composer entfernt. `Rückblick` bleibt verfügbar.
- **Tests:** Widgettests für Klicks/Scrollen/Tastatur bereits vorhanden und an eindeutige Schnellaktions-Keys angepasst. Vollständige Flutter-/Android-Abnahme steht mangels Flutter SDK in dieser Ausführungsumgebung aus. Nicht als kompilierte APK deklarieren.
- **Speicher:** Keine Änderungen an SQLite, Modellen, Versionierung der gespeicherten Daten oder KI-Schnittstellen.
- **GitHub:** Direkter Schreibzugriff zuvor 403; ZIP muss bei Verwendung mit dem aktuellen Branch abgeglichen werden. Codex-Action bleibt aus den Workflows entfernt.

## CI-Anpassung 15.10.2026 – Codex aus GitHub Actions entfernt (0.5.4+24)

- **IMPLEMENTIERT:** Nur der normale Android-Build bleibt im vollständigen ZIP unter `.github/workflows/`; der separate autonome Codex-Workflow wurde entfernt.
- **ERHALTEN:** Python-, Backend-, Flutter-, Android-Tests, APK-Release und nicht freigegebene Quellcode-Checkpoints.
- **GETESTET:** Projektstruktur, Python-Tests und ZIP-Prüfung. Flutter-/Android-Abnahme weiterhin offen.
- **GitHub:** Der Löschversuch via Connector auf `main` scheiterte an HTTP 403; das GitHub-Repository bleibt unverändert. Für die wirksame Abschaltung bestehender Actions bei GitHub ist ein Lösch-Commit der dort vorhandenen Datei nötig.

## 0.5.4+24 – Bestätigungsschutz und vollständige ARM64-Release-Artefakte (15.10.2026)

**Quelle:** Verifizierbares vollständiges Arbeitsarchiv 0.5.3+23 aus dem letzten Entwicklungszyklus, **nicht** als GitHub-Commit veröffentlicht. Android-Paket-ID und Datenbankschema unverändert. Ein GitHub-Schreibversuch wurde zuvor mit HTTP 403 verweigert; daher keine Behauptung eines Pushs.

**IMPLEMENTIERT:** Zweitklassen-Vorschläge binden sich an den Helden und die regelrelevanten bestätigten Eingangsdaten. Wird der Charakter zwischen Vorschlag und Bestätigung verändert, wird der veraltete Vorschlag sicher abgelehnt; zwischenzeitlicher Schaden darf übernommen werden. Inkompatible direkt konstruierte Mehrklassenstufen werden abgewiesen.

**IMPLEMENTIERT:** GitHub-CI kann nach komplett grüner Test- und Buildkette ein gemeinsam versioniertes ZIP/APK/SHA256/ReleaseNotes-Artefakt mit Architektur-/ZIP-Prüfung ausgeben; `scripts/prepare_alpha_release.py` ist ohne Flutter separat testbar. Release-APKs bleiben intern mit **Debug-Testschlüssel** signiert und sind keine produktiven, langfristig verlässlich aktualisierbaren Builds. Quellen-Checkpoint bei CI-Fehlschlag bleibt erhalten.

**GETESTET:** Python-Archiv-, Struktur-, Paket- und Release-Tests lokal; Projektstruktur erfolgreich. Alle sieben neuen Paket-/Fehlerfalltests bestanden (zusätzlich zu den bisherigen 25). **NICHT GETESTET:** fünf neue Dart-Tests, Flutter-Analyse und Flutter-Widgets, native Android-Tests, Geräteinstallation und neue APK; dafür wird GitHub Actions benötigt. Offline-Backend-Abhängigkeiten konnten wegen fehlendem `undici-types`-Cache nicht installiert werden; deshalb keine Behauptung bestandener Backend-Tests.

**Version:** `0.5.4+24` (neues vollständiges Import-ZIP, noch kein CI-bestätigter Release). **Letzter grüner GitHub-Build:** 0.5.1+21 / Actions #23 vom 15.10.2026. **Nächster Schritt:** Import des ganzen Archivs auf neuem Branch, vollständigen CI-Lauf prüfen und gegebenenfalls korrigieren; erst dann ARM64-APK freigeben.

## Komplette Quellcode-Übergabe – 15.10.2026 (0.5.3+23)

Alle zuvor gesicherten Dateien der 0.5.3+23-Quelle inklusive neuer UI-Schnellaktionsleiste sind in diesem ZIP enthalten. Zusätzlich wurden Codex-/Checkpoint-Workflows, ein `pubspec.yaml`-Regressionstest sowie Fortsetzungs- und Importdokumentation ergänzt. **Keine verifizierte neue Android-APK** und **kein GitHub-Push**; GitHub-`main` war 0.5.2+22. Letzter grüner CI-Build ist weiterhin 0.5.1+21. Für Details siehe `docs/AUTONOMOUS_DEVELOPMENT_STATE.md`.

## Aktuell: Würfelraunen 0.5.3+23 – Untere Schnellaktionsleiste

Die vier Schnellaktionen befinden sich nun als nicht scrollbar mit dem Abenteuerinhalt verknüpfter Footer direkt oberhalb der Hauptnavigation. Die Erzählung ist separat scrollbar; der Eingabebereich bleibt an Ort und Stelle. Die Aktionen bleiben auch bei geöffnetem Keyboard sichtbar, mit kompakter Darstellung. Ein Buildfehler aus der Vorversion wegen YAML-Doppelpunkt in `app/pubspec.yaml` wurde korrigiert.

**Verifiziert:** Projektstruktur, 22 Python-Tests, gültiges `pubspec.yaml`, vollständiges Quellcode-Paket. **Noch nicht verifiziert:** Flutter-Analyse, Widgettests und Android-APK in GitHub Actions. Neue Tests in `app/test/fantasy_pinned_actions_test.dart` und `app/test/ui_app_test.dart`.

## 0.5.2+22 – Würfelraunen / Zweitklasse

Der Projektname wurde in den Benutzeroberflächen zu **Würfelraunen** geändert. Die technische Paket-ID und historischen Weltdaten bleiben erhalten. Mehrklassenregeln (zwei Klassen, Voraussetzungen, fester Trefferpunkte-Zuwachs, Fertigkeitswahl) sind in `app/lib/domain/multiclass_rules.dart` implementiert und an den Charaktereditor angebunden. Vollständige Klassenfähigkeiten sowie Ressourcen- und Rüstungsregeln fehlen noch und müssen in weiteren Zyklen ergänzt werden. Aktuell steht die Flutter-/Android-CI-Abnahme für 0.5.2+22 aus.

## 0.5.1+21 – Flutter-CI-Abnahme des illustrierten Designs (15.10.2026)

- **CI-Ursache:** Letzter GitHub-Actions-Lauf für `0.5.0+20` (`a3a05d3888a9c0e19d3e43d2469cc849f5e1a4eb`) scheiterte trotz 328 bestandener Flutter-Tests an zwei veralteten Widgettest-Interaktionen.
- **Charakterbogen:** Der Test für unbekannte Angaben scrollt zur verzögert aufgebauten Tab-Navigation, bevor er die Tabs antippt. `ensureVisible` allein konnte den zunächst noch nicht aufgebauten Tab nicht finden.
- **Startseite:** Der 360-dp-Navigationstest scrollt zum echten Demo-Button unter dem illustrierten Header, überprüft die Antippbarkeit und startet dann die Demo. Keine Hit-Test-Warnungen unterdrückt und keine Tests deaktiviert.
- **Umfang:** Nur Widgettests, Versionsnummer und Dokumentation geändert. Alle zwölf neuen Illustrationen, UI-Widgets, Spiellogik, Backend und gespeicherte Daten bleiben unverändert.
- **Status:** Lokale Python-/Paketprüfungen durchgeführt; Flutter-Analyse, Flutter-Tests und APK-Build müssen die neue Version in GitHub Actions bestätigen. Ohne grünen Build noch keine Freigabe.

## Aktuell: Aetheria 0.5.0+20 – Illustriertes Dark-Fantasy-UI

Basierend auf dem nachweislich erfolgreichen GitHub-CI-Stand `a85cf97c113d397259677d7a3612f3b229045315` (0.4.3+19). Erweitert wurde ausschließlich die Präsentationsschicht durch 12 lokal eingebundene WebP-Grafiken, ein responsives Bild-/Rahmen-/Aktions-Widgetsystem und Anpassungen an Startseite, Kampagnen, Abenteuer, Helden, Charakterbogen, Chronik und Inventar. Neue Regressionstests in `app/test/fantasy_art_ui_test.dart`. Details: `docs/ILLUSTRATED_UI.md`.

**Status:** Quellcode erstellt und ZIP-Struktur/Python-Tests geprüft; Flutter SDK und Android SDK in dieser Arbeitsumgebung nicht vorhanden. Ein erfolgreicher Flutter-/Android-Build dieses neuen Stands wurde **nicht** behauptet. GitHub `main` unverändert.

## Aktuell: 0.4.3+19 – Attributkartenlayout korrigiert

**Basis:** GitHub `main` `9a75719b07fb2607f49818e12018a277e0b5f5dc`. Der letzte CI-Lauf stoppte nach 319 bestandenen, vier fehlgeschlagenen Widgettests (`fantasy_character_sheet_test.dart`); Ursache und Testselektor im Quellcode korrigiert. Kotlin/Android-APK noch nicht überprüft. Kein direkter GitHub-Push ausgeführt.

## Stand 0.4.2+18 – Flutter-Compilefix, noch nicht CI-validiert (15.10.2026)

Das Release 0.4.1+17 erreichte `flutter analyze` nicht: `mainAxisExtent` wurde irrtümlich an `GridView.count` übergeben (GitHub Actions Run 38691911056). 0.4.2+18 setzt stattdessen `GridView(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(mainAxisExtent: ...))` ein. Regressionstest ergänzt. Die neuen Zeilenhöhen gegen UI-Überlauf bleiben erhalten. Backend, Datenbank und Spiellogik unverändert. Vollständig grüner CI-Lauf steht für dieses Inkrement aus.

## Aktueller Stand: 0.4.1+17 – Fehlerkorrektur im Charakterbogen

Aufbauend auf `main`-Commit `c4d0dedd851ae1085d01a26afb6c0c7ff78c8830`.
Der CI-Lauf `38690872031` hatte 22 erfolgreiche Python-, 29 erfolgreiche Backend- und 316 erfolgreiche Flutter-Tests, aber drei Layout-Fehler durch zu niedrige Statistik-Kacheln in `fantasy_character_sheet.dart`. Die Kachelhöhe wurde vom starren Seitenverhältnis auf eine skalierbare feste Hauptachsengröße umgestellt; die Widgettests wurden erweitert.

**Status:** Quellcode-Korrektur und ZIP fertig; Flutter/Android-Tests müssen noch über GitHub Actions laufen. Keine Veränderungen an Spielregeln, KI oder Datenformaten.

## Aktueller Stand: 0.4.0+16 (vollständiger UI-Redesign-Stand)

Die deutsche Dark-Fantasy-Designsprache des Charakterbogens ist im existierenden App-UI vereinheitlicht. Status: vollstaendiges Quellcode-Inkrement für GitHub-Import, **nicht als grüner Flutter-/Android-Build nachgewiesen**. In dieser Umgebung bestanden die Strukturprüfung und 22 Python-Tests. Die Widgettests und Android-APK müssen in GitHub Actions laufen. Siehe `docs/UI_DESIGN_SYSTEM.md`.

## Status 0.3.9+15 – Oberflächengestaltung (15.10.2026)

**Integriert:** Neue native, responsive Flutter-Charakterbogenansicht mit vollständigen deutschen Labels und drei Bereichen; App-Farb- und Typografie-Thema angepasst. Einstieg aus Heldenliste und aktiver Kampagne, Weiterleitung zum bisherigen Editor. Kein geändertes Speicherformat, keine Hintergrundmigration, keine neuen Laufzeitabhängigkeiten. Das Mockup ist eine visuelle Referenz; die Android-App zeigt weiterhin echte, gespeicherte Daten.

**Ausstehend:** Flutter-/Dart-Analyse, vollständige Widgettests, Android-APK-Build, Smartphone-Abnahme und Prüfung des Designs mit Schriftgrößen-/Barrierefreiheitseinstellungen. Der jüngste GitHub-Workflow von `125fc3630722002a955a4e3479395edd6bfb6635` stoppte im Backend-Test durch eine veraltete Versionserwartung `0.3.0` statt `0.3.1`; diese Assertion ist in dieser ZIP korrigiert. CI muss diesen und die neuen UI-Tests bestätigen.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## 0.3.7+13 – KI-Kampagnen (15.10.2026)

Die neue Funktion erfordert einen verbundenen Backend-Erzähler. Im Testmodus erzeugt der Mock lediglich eine feste Story-Variante; kreative Kampagnen benötigen den ausdrücklich genehmigten OpenAI-Anbieter (`AI_PROVIDER=openai`, `ALLOW_PAID_AI=true`, serverseitig API-Key und Modell). Die App verbraucht pro Start und freiem Zug eine freigegebene Backend-Anfrage, zählt sie lokal mit und nutzt serverseitige Limits. Bei Abbruch bleibt der letzte bestätigte Spielstand erhalten.

Aktuelle Grenzen: kein autonomes Training der Modellgewichte, keine Live-Sprach-KI, kein KI-berechneter Kampf und keine garantierte Korrektheit freier KI-Prosa. Stattdessen kontextbasierte Story-Entwicklung aus persistenter Story-Bibel, NPC- und Handlungsstrangstatus und begrenzten früheren Entscheidungen. Die „geheime“ Wendung bleibt im lokalen gespeicherten Story-Kontext und damit beim Export sichtbar.

Grundlage: Repository `main` Commit `ea486481d28856228abf65dd209857028b3b3c45`. Dieser Stand scheiterte im CI mit 299 erfolgreichen und 2 fehlerhaften Flutter-Tests (Widget-Selektor / Tagebuch-Scrollen); die betreffenden Tests wurden im Quellpaket korrigiert. Die Korrekturen sind mangels Flutter noch nicht in CI bestätigt. Vor Übergabe lokal 22 Python-Tests und TypeScript-Syntax erfolgreich; vollständige Test- und APK-Abnahme ausschließlich in GitHub Actions.

## 0.3.6+12 – Erweiterung des Kampagnengedächtnisses (15.10.2026)

**Implementiert:** Drei neue Bereiche im Tagebuch für speicherbare Sitzungsschnappschüsse, Status und Beschreibung offener Handlungsstränge sowie protokollierte NPC-Beziehungen. Alle Änderungen erfordern eine Benutzeraktion. Neue Ereignistypen `memory.sessionRecapSaved`, `memory.npcRelationshipRecorded`, `memory.storyThreadSaved`; Änderungen liegen im bestätigten SQLite-Revisionsjournal und JSON-Export. Die lokale Erinnerungssuche berücksichtigt diese Einträge. Automatische generative Lore- und Beziehungsentscheidungen bleiben ausgeschlossen.

**Kompatibilität:** Alte `schemaVersion: 1`-Kampagnen dürfen die neuen optionalen Felder weglassen; dann werden leere Sammlungen angenommen. Keine SQLite-Migration und keine neuen Laufzeitabhängigkeiten. Maximal 60 Zusammenfassungen, 100 Handlungsstränge, 300 Beziehungseinträge sowie strenge Text-/Statusvalidierung. Es handelt sich um benutzergeführte Notizen, nicht um eine autonome semantische Gedächtnis-KI.

**Bekannter Vorfehler:** GitHub Actions für `6e967080baba7de252fac378d51758a20f6556ae` (`https://github.com/ManuEtt/Dnd/actions/runs/38683059572/job/116251682233`) zeigte erfolgreiche Analyse und 290 bestandene Flutter-Tests, aber einen Hit-Test-Fehler in `ui_app_test.dart` beim Button „Vervollständigen“ auf 360 px. Der Test scrollt nun kontrolliert zu diesem Button. Kein neuer GitHub-CI-Lauf für die 0.3.6-Änderungen erfolgt.

**Prüfungen:** Vollständige Projektstrukturprüfung und 22 Python-Tests erfolgreich. Neue Dart-Domain-, Widget- und SQLite-Testfälle sind im Quellcode vorhanden, jedoch ohne Flutter-SDK in dieser Umgebung noch nicht ausführbar; Android-APK-Build und reale Geräteabnahme stehen aus.

**Basis:** GitHub `main` Commit `6e967080baba7de252fac378d51758a20f6556ae` (0.3.5+11). Vollständige ZIP-Übergabe, der Hauptbranch wurde nicht verändert.

## 0.3.5+11 – Neues Inkrement (15.10.2026)

**IMPLEMENTIERT:** Lokaler Rückblick via GameEngine/MemoryEngine, thematisch gefilterte bestätigte Erinnerungen für D&D-Kampagnen, Schaltfläche „Rückblick“ mit Erhalt eines ungesendeten Entwurfs, und zustandsabhängige Mira-Antworten im Demo-Abenteuer.

**SICHERHEIT/DATEN:** Abfragen verwenden ausschließlich bereits bestätigte Kampagnenfakten, NPCs, Quests, Inventar und Orte. Unbestätigte Szene-/Nachrichtentexte werden nicht übernommen; Rückblicke verändern weder TP, Würfel, Inventar, Quests noch ausstehende Proben. Speicherung/Import/Export bleiben Version 1; keine neuen Server- oder Netzwerkrechte. Komplexe, freie KI-Erzählungen und semantische Gedächtnissuche sind weiterhin nicht implementiert.

**CODETESTS:** `app/test/memory_recall_test.dart` ergänzt; `app/test/ui_app_test.dart` erweitert. **Vorbereitete** Dart-/Flutter-Tests sind noch keine bestandenen Laufzeittests. Python-Projektprüfungen und Backend-Prüfungen sind separat nach Ausführung zu dokumentieren. Lokale Umgebung hat kein Flutter/Dart-/Android-SDK. GitHub Actions muss die neuen Dart-Tests und APK-Builds nach Import ausführen.

**GITHUB-BASIS:** `239ee5f7d333a6388159e7d431039abb92e936b7` vom 15.10.2026. Keine Änderungen direkt in den Hauptbranch geschrieben; ZIP kann in einem neuen Branch importiert werden. Vor Merge prüfen, ob GitHub seit dem Basisstand weiterentwickelt wurde.

## 0.3.4+10 – Fehlerkorrektur und Attribut-Modifikatorvorschau (15. Oktober 2026)

Basis fuer diesen Quellstand ist der per Git-Tree-SHA bestaetigte main-Commit
`3b91a9778abe14184f35ac1db16f5acf121a84b5`. Dessen GitHub-Actions-Job
`116229696416` schlug im Flutter-Test `new manually changed score requires explicit
house-rule consent` fehl: `scrollUntilVisible` suchte vorwaerts, obwohl die
Hausregel-Checkbox nach einem Speicherversuch oberhalb lag (281 erfolgreich,
1 fehlgeschlagen). Der Test verwendet nun einen negativen Scroll-Schritt.

Weiterentwicklung: Gueltige Attributwerte zeigen ihre regelkonform berechneten
Modifikatoren direkt im Charaktereditor. Vorschau, keine neue Spielzustandsquelle;
bei leeren oder ungueltigen Attributen wird kein Wert angenommen. Ein separater
Widgettest prueft `14/+2`, `9/-1`, Zuruecksetzen auf leer und kein Speichern.

Status: Quellcode integriert, Python-/Backend-Pruefungen separat dokumentiert.
Flutter-Analyse, Widgettests und Android-APK dieser Version sind **nicht**
lokal verifiziert. GitHub-Actions erneut durchlaufen lassen. Bei Erfolg APK
auf einem echten Android-Geraet einschliesslich Import/Export und Sprache pruefen.

## 0.3.3 – CI-Korrektur (15. Oktober 2026)

- Im offiziellen GitHub-Actions-Lauf [38675268449](https://github.com/ManuEtt/Dnd/actions/runs/38675268449) für Commit `02380c2180f98de9a31d1759fee8566d7575f3ce` wurden Projektstruktur, 22 Python- und 22 Backend-Tests erfolgreich geprüft. `flutter analyze` stoppte mit genau einem Dart-Hinweis `dangling_library_doc_comments` in `app/lib/domain/srd_character_classes.dart:1:1`; nachfolgende Flutter-Tests und APK-Builds wurden übersprungen.
- Diese ZIP behebt den Kommentarfehler ohne eine fachliche Codeänderung. Der Korrekturstand muss erneut in GitHub importiert und durch die gesamte Actions-CI geprüft werden. Ein Erfolg der noch ausstehenden Flutter-Tests und APK-Builds wird nicht behauptet.

## 0.3.3 – Stand der ergänzten Klassenwahl, 14. Oktober 2026

- BASIS: vollständig exportierte 0.3.2-Version aus GitHub `4007b2b65f3413238c0a828813d57b98c4498732`, bereits durch Actions für Flutter/Android getestet. Letzter freigegebener Gerätebericht: Attributverteilung, Spracheingabe, Sprachausgabe, Stufe-1-TP funktionieren.
- IMPLEMENTIERT (0.3.3): 12 SRD-5.2.1-Klassenprofile mit Rettungswurf-Übungen, Fertigkeitswahl, optionalem Startpaket/Startgold; UI-Klassenassistent mit Vorschau/Bestätigung, bestehende Werte nicht automatisch überschreiben; neuer manueller Hausregelweg für abweichende Startattribute bei neuen Charakteren. Keine Schema- oder Backend-Änderung.
- SOURCE-QA: neues Paket mit zusätzlichen Unit-/Widgettests; Gesamtprojektstruktur und vorhandene Python-Tests werden vor ZIP-Abgabe separat geprüft.
- OFFEN: Flutter-Analyse, Flutter-Tests und Android-Build für Version 0.3.3 können in der aktuellen Dateiumgebung ohne Flutter-SDK nicht ausgeführt werden. Nach GitHub-Import über Actions prüfen; 0.3.3 nicht bereits als Gerätetest ausgeben.
- REGELGRENZE: keine automatische Hintergrunderfahrung, Klassenmerkmale, aufgenommene Ausrüstung/Rüstungsklasse, Zauberplätze, Level-Ups oder Mehrklassenregeln. Mit zusätzlichen Stufe-1-Klassenübungen werden bestehende Einträge optional zusammengeführt; Ursprung der üblichen Mehrfach-Übungen ist in den bestehenden Listen noch nicht separat nachverfolgbar.

# Entwicklungsstatus

## Entwicklungsinkrement: SRD-5.2.1-Start-Trefferpunkte (0.3.2+8, im Quellstand integriert)

- Neue reine Dart-Regellogik `StartingHitPoints.propose` für die zwölf
  SRD-5.2.1-Klassen (deutsche/englische Namen): Stufe 1 = maximaler
  Klassen-Trefferwürfel + bestätigter Konstitutionsmodifikator, mindestens 1 TP.
- Im Charaktereditor ein separater, ausdrücklich zu bestätigender Vorschlag.
  Abbrechen, unbekannte Werte und Stufen größer 1 ändern keine Charakterwerte.
- Neue Domänen- und Widgettests hinzugefügt; **in diesem Übergabepaket nicht
  ausgeführt**, da die aktuelle Arbeitssitzung keine Flutter-/Dart-Toolchain hat.
- **Vollständiger Quellstand direkt integriert**: Alle 103 Originaldateien aus
  GitHub-main `4a8cfe9` über ihre Git-Blob-SHA geprüft, dazu fünf direkte
  HP-Code-/Test-/Statusänderungen und die Versions-/Dokumentationsaktualisierung.
  Projektstrukturprüfung und 22 Python-Tests erfolgreich.
- **Noch nicht nach GitHub geschrieben**: Die GitHub-Integration verweigert
  Branch-Erstellung mit 403. Nach Import `flutter analyze`, `flutter test`
  und GitHub-CI ausführen; erst danach als getestet melden.
- Nächstes Inkrement: Verteilungsmethode/Basiswerte/Boni persistieren und
  freie Attributbearbeitung bei regelkonform neu erstellten Charakteren
  gegen Umgehung des 27-Punkte-Budgets absichern, Altimporte schützen.

Hinweis zum vorherigen Stand: Der GitHub-Actions-Lauf `38582180726`
auf `4a8cfe9` war tatsächlich erfolgreich: 254 Flutter-Tests, Backend- und
Python-Tests sowie Debug-/ARM64-/ARM32-/x86_64-APKs. Diese Ergebnisse
gelten für 0.3.1, **nicht** als Abnahme des neuen 0.3.2-Codes.

Stand: 14. Oktober 2026. Aktuelle Etappe: App 0.3.1 mit Android-Sprachkorrekturen, Geräte-Rückmeldung und nachgewiesener GitHub-CI-Ursache; autonome Entwicklung mit gesicherten Inkrementen für `ManuEtt/Dnd`.

Der Lesezugriff auf GitHub ist jetzt vorhanden. Der hochgeladene main-Stand
`bc6c942483189acdcd82b37005de1040b49b36b8` stimmt in allen Dateiinhalten mit dem
gesicherten lokalen 0.3.0-Stand überein; nur vier Ausführungsrechte unterscheiden
sich. Der bestehende Actions-Lauf ist geprüft, direkte Schreiboperationen
erhalten weiterhin HTTP 403. Neue Korrekturen sind deshalb zusätzlich als ZIP
zu übernehmen; ein neuer GitHub-Lauf oder Pull Request ist noch nicht bestätigt.

## IMPLEMENTIERT

- Flutter-/Android-Projekt mit Material 3 und deutscher Navigation: Start, Charaktere, Abenteuer, Journal und Einstellungen.
- Flaches Korrektur-ZIP ohne äußeren Dnd-Ordner, Projektprüfung vor SDK-Installation und 22 Python-Paket-/Strukturtests. Kleine optimierte interne Alpha-APKs für ARM64, ARM32 und x86_64, weiterhin mit Testsignatur.
- Explizite Attributstarthilfe: Standardsatz oder Punktekauf bis 27 Punkte, vier SRD-Hintergründe, getrennte Grund-/Bonus-/Endwerte mit Modifikatorvorschau. Bekannte Werte benötigen Ersetzbestätigung; Öffnen/Abbruch bewahrt historische und ungespeicherte Eingaben. Nur Attribute und Hintergrundname werden übernommen.
- Charaktereditor mit nullable, ausdrücklich unbestätigten Werten; JSON-Export/-Import, Kampagnenauswahl und lokale Löschfunktionen. Seit 0.2.2 direkte Android-Dokumentauswahl und Dateisicherung, explizite Importbestätigung sowie Zwischenablage als Fallback.
- Deterministischer deutscher Spielleiter als kostenlose Voreinstellung. Optionaler HTTPS-Backend-Erzähler für freie Texte; lokale Regeln, Würfel und bestätigte Daten bleiben maßgeblich. Anbieterantworten ersetzen ausschließlich die neue Erzählung und ihren Ereignis-Checkpoint.
- Demo „Das Licht von Mooswacht“ in Lunaris mit Liora, Erkundung, Schlüssel, Quest und einfacher Gegnerbegegnung.
- Historischer Arescan-Zustand „Das Herz der Ewigkeit“: bekannte Geschichte, fehlende Attribute, historische Werte 19/14 und ungeprüfter Modifikator +7; keine erfundenen Helden- oder Gegnerkampfwerte.
- Würfel W4/W6/W8/W10/W12/W20/W100, natürliche Ergebnisse getrennt von Gesamtergebnissen, Vorteil/Nachteil und kontrollierbare Zufallsquelle.
- Regelgrundlagen für Attributmodifikatoren, Übungsbonus, Initiative, Angriffe, kritischen Schaden, Trefferpunkte, Heilung und Todesrettung. Demo-Kampf mit automatischer Gegenrunde; kein vollständiges SRD-Kampfsystem.
- SQLite-Schema 1, gemeinsame Speicherung von Snapshot und Ereignissen, Revisionsjournal, Konfliktprüfung, Idempotenz und Wiederherstellung bestätigter Zustände.
- Grundlegender Kurzzeitkontext, faktengestützte Sitzungsübersicht und Langzeitfakten zu NPCs, Quests und Inventar; Checkpoint-Ereignisrekonstruktion.
- Deutsche Systemspracherkennung mit bearbeitbarem Transkript, TTS, Stimmwahl, optionaler automatischer Ausgabe und Unterbrechung. Seit 0.3.1 geprüfte Anbieterergebnisse, deutsche Locale-Rangfolge, deduplizierte Stimmmetadaten und erneute Prüfung ohne Mikrofonzugriff. Fehlende Daten/Netzwerkprobleme erhalten verständliche Meldungen; nicht antwortende Dienste und Wiedergabe haben Zeitgrenzen. Lokale Oberfläche startet vor der Sprachdienstprüfung. Kein automatischer Mikrofon-Neustart.
- Fastify-/TypeScript-Backend mit validierter, ausschließlich erzählender API, eigenen kurzlebigen Read-only-Tokens, In-Memory-Anfragelimits und kostenlosem Mock. Optionaler OpenAI-Responses-Provider ausschließlich serverseitig und mit ausdrücklichem Kosten-Opt-in. Kein Realtime-Token.

Zusätzlich seit 0.2.0: HTTPS-Transport mit begrenzten JSON-Antworten, verweigerten Weiterleitungen, Ablaufprüfung, ausdrücklicher Kostenfreigabe und lokalem Anfragenversuchslimit. Token und Kostenfreigabe werden nicht gespeichert. Sitzungstest per authentifiziertem GET ohne Modellaufruf; neue Server-CLI gibt nur kurzlebige Sitzungstokens aus. Fehler führen ohne automatischen POST-Retry zur lokalen Demo. Ein Replay-Fehler durch unterschiedliche JSON-Objektschlüsselreihenfolge wurde behoben, ohne veränderte Werte oder Listen als identisch zuzulassen. Seit App 0.2.1 wählt MemoryEngine.retrieve bis zu 20 bestätigte Fakten, NPC-, Quest-, Inventar- und Ortsinformationen anhand deutscher Worttreffer und wichtiger Zustände aus. Keine Modelltexte oder Spielerbehauptungen werden als Faktenquelle verwendet; Datenbankschema und Importe bleiben Version 1.

Seit App 0.2.2 trennt BackupFiles die Dateiverarbeitung von Oberfläche und Repository. Die native Android-Brücke verwendet das Storage Access Framework ohne allgemeine Speicherrechte, prüft Dateinamen und tatsächliche Datenmenge bis 10 MiB und arbeitet im Hintergrund. Dart prüft striktes UTF-8 und erlaubt ein anfängliches BOM. Abbruch und Fehler speichern keine Importdaten; Erfolg beim Export setzt einen geschlossenen Stream voraus. Die echte Geräte-Dateiauswahl ist noch nicht abgenommen. Einrichtung und Grenzen: docs/SAVE_BACKUPS.md.

Der Workflow `.github/workflows/android-build.yml`, Projekt- und Übergabedokumentation liegen vor. CI verwendet Flutter 3.35.7, Dart 3.9.2, Java 17 und Node.js 22.14.0.

Seit 0.3.1 installiert CI Android Commandline Tools mit
android-actions/setup-android@v3, festgelegtem Build 12266719, vor dem
sdkmanager-Aufruf. Die Ursache des alten APK-Ausfalls ist durch GitHub-Logs
bestätigt, der korrigierte Workflow bleibt bis zur Übernahme separat zu prüfen.

## GERÄTERÜCKMELDUNG

Der Benutzer berichtet funktionierenden App-Betrieb auf einem **Samsung Galaxy
S26 Ultra**, aber Probleme bei einigen Sprachen. Das ist ein Benutzerbericht,
kein vollständig dokumentierter Entwickler-Gerätetest. App-/Android-/One-UI-
Version, Sprachdienst, genaue betroffene Sprache und Eingabe beziehungsweise
Ausgabe sind noch offen. 0.3.1 verbessert konkrete im Paketcode bestätigte
Fehlerpfade; deren Behebung auf dem Samsung ist noch nicht bestätigt. Die
Hauptsprache ist Deutsch, weitere Spielsprachen sind nicht implementiert.
Anleitung und Diagnosedaten: docs/SPEECH_TROUBLESHOOTING.md.

## GETESTET

Gezielte Sprachprüfung 0.3.1: **31 Controller-Tests** (24 neu) und **7 neue
Widgettests** bestanden, gezielte Analyse ohne Befunde. Geprüft sind 0/false
bei TTS-Kommandos, fehlende/doppelte Stimmendaten, lokale/Netzwerk-Metadaten,
gespeicherte entfernte Stimmen, Wiederholung nach Paketinstallation,
hängende Sprachabfrage/Wiedergabe, Fehlercallbacks, Abbruch und verzögerte
Ergebnisse. Die Einstellungen bestehen auf 360 px mit 1,3- und 2-facher
Schriftgröße. Die neue Startprüfung mit echter temporärer SQLite-Datenbank
zeigt die lokale Oberfläche während einer offenen nativen Stimmabfrage.

Abschließende Prüfungen für 0.3.1: **254 Flutter-Tests** einschließlich lokalem
Node-/Dart-Protokolltest erfolgreich mit Node 22.14.0 und RUN_BACKEND_SMOKE=1;
**22 Backend- und 22 Python-Tests**, Backend-Typecheck/Build und saubere
Flutter-Analyse. Insgesamt 32 neue Flutter-Tests. Universeller Debug-Build
0.3.1+7 erfolgreich; Version, API 24/36 und gleiche lokale Testsignatur geprüft.
Keine kostenpflichtigen Modellaufrufe. Native Dateisicherungsquellen unverändert,
deren bestehender Nachweis bleibt 12 JVM-Tests.

Der reale GitHub-Lauf **38560369343** auf main `bc6c942` besteht Strukturprüfung,
22 Python-, 22 Backend- und 222 Flutter-Tests sowie Codeanalyse. Job
115839661846 scheitert danach beim SDK-Schritt mit **sdkmanager: command not
found**, Exit 127. Alle APK-Schritte sind übersprungen. Dies ist ein tatsächlich
beobachteter Remote-Testlauf, aber kein erfolgreicher Remote-APK-Build.

Gesamter scripts/check.sh-Lauf für 0.3.0 erfolgreich: **222 Flutter-Tests** einschließlich lokalem Node-/Dart-Protokolltest, **22 Backend-Tests**, **22 Python-Paket-/Strukturtests** und Flutter-Analyse ohne Befunde mit der festgehaltenen Toolchain/Node 22.14.0. Zusätzlich nach Ergänzung der beiden neuen Pflichtdateien Python-Prüfer und alle 22 zugehörigen Tests erneut bestanden. 44 neue Flutter-Tests: 24 Domain-Regeltests, 7 echte SQLite-/Controller-Tests und 13 Widgettests. Der Debug-APK-Build 0.3.0+6 ist erfolgreich, Metadaten und Testsignatur geprüft.

Die Regeltests prüfen alle 720 Standardsatz-Zuweisungen, Punktekostentabelle, Budget und jede erlaubte Hintergrundsteigerung. Die UI-Prüfung umfasst 360 px, explizite Auswahl, Restpunkte, Basis-/Bonusvorschau, Modifikator 17→+3, Bestätigung und Abbruch. SQLite prüft Neustart/Export/Import, keine doppelten Boni, Arescan 19/14 und unbestätigten +7 sowie unveränderte Welt-/Inventardaten und ungültig gewordene alte Würfelproben. Ein echter später SQLite-Triggerfehler bestätigt vollständigen Rollback von Ereignis/Snapshot und Anzeige; erneutes Speichern gelingt. Statische zusätzliche Regel-/UI-Prüfung ohne Blocker. Kein realer Geräte-/Sprach-/GitHub-Test dadurch behauptet.

Erneuter kompletter scripts/check.sh-Lauf für 0.2.3 erfolgreich: Projektstrukturprüfung, **22 Python-Paket-/Strukturtests**, Backend-Typecheck/Build und **22 Backend-Tests** mit Node.js 22.14.0, saubere Flutter-Analyse sowie **178 Flutter-Tests** mit RUN_BACKEND_SMOKE=1. Neue Tests prüfen beide ZIP-Wurzeln, Byte-Erhalt, Geheimnis-/Cache-Ausschluss, Symlinkablehnung, unvollständige Uploads, Gradle-JAR-CRC und Unix-Zeilenenden. Keine kostenpflichtigen Modellaufrufe.

Drei optimierte Alpha-APKs lokal erfolgreich gebaut und geprüft: arm64-v8a 17.382.068 Byte, armeabi-v7a 14.861.712 Byte, x86_64 18.554.326 Byte. Alle Version 0.2.3, Buildcode 5, API 24+, richtige ABI und gleiche verifizierte lokale Debug-Testsignatur wie die bisherige 0.2.2-APK. Je ABI --target-platform verwendet, damit keine ABI-Codeoffsets spätere Updates verhindern. Kein Store-Release. ARM64 und ARM32 privat auf Google Drive erstellt und per Metadaten mit korrekter Größe/MIME/Owner-Recht gelesen; ARM64 zusätzlich über die Drive-Download-API abgerufen und byteidentisch per SHA-256 mit dem Original verglichen. Der Benutzerdownload und die Installation auf einem echten Gerät bleiben separat abzunehmen.

Flutter 3.35.7/Dart 3.9.2: Codeanalyse ohne Befunde und **178 Tests bestanden** mit RUN_BACKEND_SMOKE=1. Enthalten sind 74 bisherige Tests, 23 Transporttests, 13 Erzähl-/Replay-Tests, 13 SQLite-/Backend-Controller-Tests, 7 Backend-Widgettests, 13 Abruf-/Konsistenztests, 21 Dateikanal-/UTF-8-Tests, 13 Datei-Widgettests und ein echter lokaler Protokolltest. Der aktuelle Gesamtlauf verwendet Node 22.14.0 auch für den realen Protokolltest. Der Protokolltest startet den kompilierten Node-Server, stellt mit der Server-CLI einen synthetischen Sitzungstoken aus und prüft Dart-Transport, Backend-Erzählung, SQLite-Bestätigung und den Rückfall nach Serverabschaltung. Er verwendet ausschließlich lokale Mock-Dienste und Testdaten.

Backendquellen unverändert seit 0.2.0: Typecheck, Produktionsbuild und **22 Tests** erfolgreich mit Node.js 22.14.0 und 24.19.0. Geprüft sind neue Sitzungsprüfung, verbindliches outcome, Provider-/Tool-Abweisung, Authentifizierung, Eingabevalidierung, Nutzungslimits und sichere Fehler. Die historischen 0.1.0-Prüfungen und Quellenangaben bleiben im Änderungsprotokoll nachvollziehbar. Es wurden keine kostenpflichtigen Modellaufrufe ausgeführt.

Native Android-JVM-Prüfung mit Java 17 und Gradle 8.12: **12 Tests bestanden**, keine Fehler, keine übersprungenen Fälle. Geprüft sind reale Byte-Grenze statt Provider-Metadaten, Dateinamen, Lesen/Schreiben, Streamschluss und I/O- beziehungsweise Abbruchfehler. Lebenszyklus und SAF-Ergebniszustellung sind statisch geprüft, nicht durch diese JVM-Tests oder auf einem Gerät nachgewiesen.

Die Abschlusskorrektur ist ebenfalls abgenommen: Trennung und Dispose beenden ausstehende Backend-Wartevorgänge sofort; aktive HTTP-Verbindungen werden geschlossen, und verspätete Antworten bleiben wirkungslos. Der Abbruchknopf ist während einer laufenden Anfrage bedienbar. Bereits ausgelöste Anbieteraufrufe werden dadurch nicht automatisch erstattet.

## NICHT GETESTET

- Vollständig dokumentierter End-to-End-Ablauf auf einem echten Android-Gerät, einschließlich neuer Attributshilfe mit großer Schrift/Screenreader; Benutzer meldet App-Betrieb auf Samsung Galaxy S26 Ultra.
- Echte Android-Dokumentauswahl, Dokumentanbieter, Berechtigungsübergabe, Schreibfehler und Aktivitätsende während einer Dateisicherung. Die Dateibrücke ist kompiliert; Dart-Kanal, Oberfläche und native I/O-Helfer werden getrennt automatisiert geprüft.
- Deutsche Mikrofoneingabe und Sprachausgabe mit einem konkreten Android-Sprachanbieter.
- Unterbrechung, Berechtigungsablehnung und Ausfall von echten Gerätesprachdiensten; die zugehörige App-Logik ist mit Mocks getestet.
- GitHub-Actions-Lauf mit der SDK-Korrektur 0.3.1 und Herunterladen eines neuen APK-Artefakts; bisheriger Lauf scheitert nach erfolgreichen Tests.
- Reale, kostenpflichtige OpenAI-Aufrufe und eine mobile HTTPS-Verbindung zu einem produktiven Server.

## BLOCKIERT

- Direkte Übertragung der Änderungen: Lesen funktioniert, tatsächlicher Push auf fix/android-voice-reliability erhält HTTP 403 „Permission to ManuEtt/Dnd.git denied to ManuEtt“. Connector-Branchanlage erhält ebenfalls403 „Resource not accessible by integration“. Allgemeines push:true in Repository-Metadaten bestätigt nicht die Integrationsberechtigung. ZIP und docs/UPLOAD_TO_GITHUB.md ermöglichen die Übernahme durch den Eigentümer. Actions-Ursache ist inzwischen bestätigt und lokal korrigiert.
- Eine vollständige Prüfung auf einem Android-Gerät benötigt ein Gerät beziehungsweise einen geeigneten Emulator mit Sprachdiensten.
- Produktive KI-Anbindung benötigt sichere Serverkonfiguration und Anbieterzugang; der Demo-Modus bleibt unabhängig davon.

## NOCH NICHT IMPLEMENTIERT

- Vollständiges SRD-5.2.1-Regelsystem einschließlich regelkonformer automatischer Charaktererstellung, aller Klassen, Zauber, Ressourcen, Bonus- und Reaktionsaktionen sowie automatischem Stufenaufstieg.
- Regelkonforme Fortsetzung des historischen Arescan-Kampfs bei weiterhin unbekannten Gegnerwerten.
- Durchgängiger geprüfter mobiler OpenAI-Realtime-WebRTC-Sprachpfad und Ausstellung von OpenAI-Realtime-Credentials.
- Öffentlicher Mehrspielerdienst, PostgreSQL-Synchronisierung und Benutzerverwaltung.
- Vollständige mehrstufige Erinnerungsverdichtung und semantische Langzeitabrufe.
- Automatische sichere Sitzungserneuerung; Tokens müssen derzeit nach Ablauf neu ausgestellt werden.
- Signierter Veröffentlichungsbuild und Store-Veröffentlichung.
- Abgenommene Windows- und iOS-Versionen.

## Letzter Build und nächste Aufgabe

**App 0.3.1+7: universeller Android-Debug-Build erfolgreich**, API 24+, Ziel 36,
gleiche Paket-ID und verifizierte lokale Testsignatur wie 0.3.0. Drei optimierte
Alpha-APKs erfolgreich gebaut und geprüft: ARM64 17.447.960 Byte, ARM32
14.927.604 Byte, x86_64 18.685.754 Byte. Alle normaler Buildcode 7, richtige ABI,
gleiche lokale Testsignatur; neue Sprachtexte im kompilierten AOT-Code geprüft.
Toolchain unverändert;
kein Entwickler-Gerätetest und kein erfolgreicher neuer Remote-APK-Build.

**App 0.3.0+6: universeller Android-Debug-Build erfolgreich**, API 24+, Ziel 36, gleiche Paket-ID, Metadaten und Debug-Signatur geprüft. Drei optimierte kleine Alpha-APKs wurden mit normaler Buildnummer 6 erstellt und per Metadaten, Architektur und gleicher lokaler Testsignatur geprüft; alle unter 25 MiB. Toolchain unverändert wie im historischen Debugnachweis unten; letzte Gerätemessung weiterhin nicht vorhanden.

**App 0.2.3+5: drei optimierte kleine Alpha-APKs erfolgreich gebaut**, Release-AOT mit interner Debug-Testsignatur; Toolchain wie im folgenden Debugnachweis. Die CI-Konfiguration baut zusätzlich weiterhin die universelle Debug-APK, prüft die Struktur früh und hält die kleinen Artefakte 30 Tage bereit. YAML und lokale Befehle sind geprüft; der tatsächliche GitHub-Lauf ist weiterhin blockiert.

**App 0.2.2+4: Android-Debug-Build erfolgreich** mit Flutter 3.35.7/Dart 3.9.2, Temurin-JDK 17.0.20.1, Gradle 8.12, AGP 8.9.1, Kotlin 2.1.0, SDKs 34/35/36, Build Tools 35.0.0, NDK 27.0.12077973 und CMake 3.22.1. Paket-ID `de.aetheria.lebendiger_spielleiter`, Android ab API 24 (7.0), Ziel-API 36. APK-Metadaten (Version 0.2.2, Code 4), erforderliche Rechte und Debug-Signatur wurden geprüft. Keine allgemeine Speicherberechtigung hinzugefügt. Die Debug-Signatur entspricht der vorherigen 0.2.0-APK; ein Update ist damit grundsätzlich möglich, aber noch nicht auf einem Gerät geprüft. Der abschließende Build nach Dateiintegration war erfolgreich.

Anfangs fehlten ein vollständiger Java-Compiler, die Sprachplugin-SDKs und CMake. Diese Entwicklungswerkzeuge wurden installiert. Proxy-/CA-Vertrauen wurde ausschließlich in der lokalen Cloud-Werkzeugumgebung konfiguriert, ohne TLS-Prüfung zu deaktivieren. Lokale Werkzeugpfade und Cloud-Konfiguration gehören nicht zum ZIP. Die CI installiert die benötigten SDK-Komponenten ausdrücklich. Der erfolgreiche lokale Build ist **kein** ausgeführter GitHub-Actions-, Emulator- oder Gerätetest.

## Gesicherter Stand und Fortsetzung

- Letzter gesicherter Funktionsstand: `07c98db` (0.3.1), davor `8dc38b6` für CI-Werkzeuge. Branch `fix/android-voice-reliability` basiert auf dem tatsächlich gelesenen GitHub-main `bc6c942`; keine fremden Dateiinhalte überschrieben. Die frühere unabhängige Historie bleibt lokal als feat/solo-alpha erhalten. Abschließende Dokumentationscommits stehen im tatsächlichen Git-HEAD.
- Zuletzt fertiggestellt: Sprachkorrekturen, robuste Einstellungen und unabhängiger lokaler App-Start 0.3.1; fehlendes sdkmanager als echte CI-Ursache korrigiert. 254 Flutter-, 22 Backend- und 22 Python-Tests, Analyse und Debug-/drei optimierte APK-Builds erfolgreich. Bestehende native I/O-Tests bleiben 12 bestanden, unveränderter Code.
- Aktueller Abschluss: Code, Anbieterfehler und Historie geprüft; lokale APKs mit Version/Architektur/Signatur und neuen Sprachtexten im AOT-Code abgenommen. ARM64 und ARM32 privat auf Drive erstellt und per Größe/MIME/Rechten bestätigt. ARM64 erneut heruntergeladen und byteidentisch per SHA-256 geprüft. Flaches Quell-ZIP enthält 103 Dateien; Webupload in mindestens zwei Stapeln. Keine Schemaänderung, neue Laufzeitabhängigkeit oder kostenpflichtige Modellaufrufe. ZIP-Prüfung und endgültige Downloadlinks/Prüfsummen im externen Checkpoint.
- Bekannte Grenzen: genaue betroffene Sprache und Android-Anbieter unbekannt; Samsung-Sprachkorrektur nicht am Gerät bestätigt. Native TTS-Callbacks besitzen keine Wiedergabe-ID, sehr späte Ereignisse lassen sich deshalb nicht perfekt zuordnen. Kein automatischer Token-Refresh, kein vollständiges Regelwerk, keine abgenommenen produktiven OpenAI-/neuen Actions-APK-Tests. Bestätigte Spielstände bleiben in den ausgeführten Tests erhalten.
- Nächster konkreter Schritt: 0.3.1 auf dem Samsung getrennt für Erkennung und Vorlesen prüfen und ZIP mit CI-Korrektur übernehmen; neuen GitHub-Lauf/Artefakte abnehmen. Ohne Geräte-/Schreibzugriff anschließend Stufe-1-Trefferpunkte aus ausdrücklich gewählter Klasse und bestätigtem Konstitutionsmodifikator vorschlagen: vorher offizielle SRD-Quellen lesen, historische Werte erhalten, Vorschlag/Bestätigung/Persistenz testen.
- Übergabepakete: Dnd-Projekt-0.3.1.zip mit Dateien direkt in der Wurzel sowie Der-lebendige-Spielleiter-0.3.1-arm64.apk/arm32.apk. Externer Dnd-0.3.1-status.json erfasst abschließenden Git-HEAD, SHA-256 und bestätigte private Drive-Links. Alte Übergabepakete bleiben erhalten.
- Der tatsächliche Git-HEAD wird vor jeder Fortsetzung mit `git log -1 --oneline` geprüft. Keine zusätzlichen Credits oder Limit-Zurücksetzungen wurden ausgelöst. Ein erkennbares Kontingentlimit wird nicht aus nicht vorhandenen Messwerten abgeleitet.

## 0.6.8+38 – SRD-Klassenmerkmalregister (16.10.2026)

- **BASIS:** unveränderte Vollversion 0.6.7+37.
- **NEU:** `SrdClassFeatureCatalog` für zwölf Grund- und SRD-Unterklassen, `ClassResourceRules` für Ressourcenstände und Rastregeneration, `ClassCombatFeatures` für Champion-Krit und Schurken-Voraussetzungen.
- **INTEGRATION:** Charakterbogen, Speichermodell, Rast und bestätigte Kampfangriffe; passive Klassenmerkmale bei Bewegung und Initiative.
- **TESTS:** Vorhandene Python-Projekttests ausgeführt; neue Dart-Tests hinzugefügt, aber ohne Flutter-SDK hier nicht ausführbar.
- **OFFEN:** Vollständige automatische Implementierung sämtlicher Klasse-/Unterklassenwirkungen, komplexer Zauber und Entscheidungen – siehe `docs/CLASS_FEATURES_0_6_8.md`.
- **GITHUB:** Kein Push; GitHub-App hat bislang Schreiben mit HTTP 403 abgewiesen.

## Neues Inkrement: Kämpfer-Erstellung und EP (18.10.2026)

Implementiert im separaten Arbeitsstand: SRD-5.2.1-Erfahrungstabelle für
Gesamtstufen 1–20, Übungsbonus-Vorschau und Stufe-1-Kämpferauswahl mit
explizitem Kampfstil, drei Waffenmeisterschaften und Startpaket. Keine
rückwirkende Neuberechnung bestehender Spielstände. Für Kampfstil/Meisterschaft
wird ausschließlich die Wahl dokumentiert; vollständige Kampfeffekte werden
nicht durch die Wahl eines Merkmaltexts aktiviert.

Lokale Python-Projekttests ausgeführt; Flutter-Test, Flutter-Analyse und
Android-Build noch auf GitHub mit Flutter-SDK ausführen. Neues Inkrement
nicht als abgenommene Android-Version bezeichnen.


## Übernommener Status aus Main145 (historisch)

## 23.10.2026 – XP-Belohnungs-ID-Konflikt fail-closed (Branch `fix/xp-reward-id-conflict-20261023`)

- **IMPLEMENTIERT:** Identische XP-Belohnungs-ID wird in `ExperienceProgression.grant` nur bei exakt gleichem gespeichertem Betrag idempotent bestätigt. Anderer/defekter Betrag löst `FormatException` aus; ursprüngliche Kampagne bleibt unverändert.
- **REGRESSIONSTESTS ERSTELLT:** `app/test/experience_progression_test.dart` prüft Roundtrip-Duplikat, Widerspruch und beschädigten Historieneintrag.
- **GETESTET:** Main-Baseline `5958579e5321338bb7b4e46abb859fd3bfd1515f` mit GitHub-CI [#40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485) erfolgreich, nicht neuer Branch. **NICHT GETESTET:** neuer Flutter-Code-HEAD bis CI fertig ist. **BLOCKIERT:** Flutter/Android lokal nicht installiert; reales Android-Gerät nicht verfügbar.
- **KOMPATIBILITÄT:** Keine SQLite-/JSON-Migration, unveränderte SRD-Regelmechanik und KI-/Story-Grenze. `0.8.36+86` bleibt vorerst unverändert wegen parallelem PR #144.
- **NÄCHSTER KONKRETER SCHRITT:** Finale PR-CI/Flutter-Tests auswerten, dann idempotentes persistentes XP-Gutschriftjournal inklusive GameController-/SQLite-Revisionen gesondert testen.

---
