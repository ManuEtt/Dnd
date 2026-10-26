## 26.10.2026 – 0.8.42+92: sechs Entwicklungsbranches zusammenführen

Sieben Köpfe einschließlich Main vorab remote per Archivtag und lokal per geprüftem Bundle gesichert. Eldritch-Klassenprüfung, NPC-ID-Wire-Vertrag (Android-Durchreichung noch offen), barrierearme Kampf-/Würfelanzeige und no-follow Checkpoint-Manifeste gemeinsam integriert. Formatfehler der Würfeltestdatei behoben;155 Python-Tests bisher grün, vollständige kombinierte Abnahme noch offen. SQLite2/JSON1 unverändert. [Checkpoint](docs/CODEX_CHECKPOINT.md). Ältere Einträge unten sind Historie.

---

## 26.10.2026 – Chat A: Eldritch-Blast-Zweitklassenvalidierung (CI offen)

Unbekannte Hauptklasse vor dem Wirken von `Eldritch Blast` zurückweisen, auch bei gültiger Hexenmeister-Zweitklasse. Neue deterministische Positiv-/Negativtests; keine Ressourcen-/Speicherformatänderung oder neue Spielregel. Bis zur vollständigen GitHub-CI als nicht abgenommen behandeln. [Fachbeleg](docs/parallel/CHAT_A_ELDRITCH_PRIMARY_VALIDATION_20261026.md).

---

## 26.10.2026 – 0.8.41+91: Heilige Flamme mit gültigen Klassenwerten

Geprüften Klassenwerte-Rechner aus PR #184 in den echten Zauberablauf integriert. Alias-Doppelklassen, unbekannte Partner und ungültige Stufen lösen keine Würfel/Aktion/HP-Änderung aus. Bestehende Importe bleiben lesbar; WIS-/Gesamtstufen-Übung gültiger Profile erhalten. Bestätigungsgebundene SG-Vorschau und scrollbar bedienbarer Android-Dialog. 1.703 Flutter-, 141 Python-, 57 Backend- und zwölf native Android-Tests bestanden; Format/Analyse/Backend-Build sowie Debug-/ARM64-APKs erfolgreich. Codequelle `7c9441e`, PR #217. Realgerät/Produktivsignierung offen. SQLite 2 / JSON 1 kompatibel. [Fachbericht](docs/SACRED_FLAME_CLASS_VALIDATION_20261026.md) · [Checkpoint](docs/CODEX_CHECKPOINT.md). Ältere Einträge unten sind Historie.

Main `d03faea` regulär integriert; geerbte ZIP-Modus-/Rollback-Testfehler mit Originalkorrekturen aus PR #215 übernommen, NPC-Analyzer-/Formatfehler behoben. Gesamtabnahme auf Kombination vollständig lokal erfolgreich: 1.703 Flutter-, 141 Python-, 57 Backend- und zwölf native Tests; Debug/ARM64-Alpha geprüft.

---

## 25.10.2026 – 0.8.40+90: persistierte Bewegungsunterbrechung

Bestätigter Auslöser einer Gelegenheitsreaktion wird im Abenteuer als revisionsgebundene Entscheidung gespeichert. Neustart, expliziter Verzicht, Gegnerzug-Sperre und Schutz vor alten UI-/Controller-Antworten. Keine Würfel/Schäden/Reaktionskosten, daher weiter `partial`. SQLite2/JSON1 bleiben kompatibel. Gezielte Domain-/SQLite-/Widgettests erfolgreich; vollständige neue Abnahme separat ausstehend. [Fachlicher Umfang](docs/SRD_OPPORTUNITY_MOVEMENT_20261025.md), [operativer Checkpoint](docs/CODEX_CHECKPOINT.md). Ältere Einträge unten sind Historie.

---

## 25.10.2026 – SRD-5.2.1-Gelegenheitsangriff: nur bestätigte Auslöser vorbereiten (#174)

Im neuen [PR #174](https://github.com/ManuEtt/Dnd/pull/174) reine `SrdOpportunityAttackRules.prepare`-Regelprüfung eingeführt. Prüft explizite Bewegungsstrecke von innerhalb nach außerhalb der Reichweite, Sicht, Spielerzustimmung, freie Reaktion, Encounter-/Revisionszuordnung, Nahkampfwaffe oder waffenlosen Schlag; Disengage, Teleport und erzwungene Bewegung gesperrt. Positiv- und Negativregressionen inklusive JSON-Roundtrip. Status `RULE-COMBAT-OPPORTUNITY-ATTACKS=partial` (SRD 5.2.1, S. 15, CC BY 4.0). Keine Android-Auslösung, noch keine Reaktions-/Schadensbuchung oder Speicherung, keine Versionserhöhung. Finaler GitHub-CI-Nachweis getrennt abwarten. [Fachnotiz](docs/SRD_OPPORTUNITY_ATTACK_PREFLIGHT_20261025.md).

---

## 25.10.2026 – GitHub-Integration PR #171 tatsächlich nach main gemergt

Der verifizierte Integrationskopf `255a5a0` wurde als normaler Merge (kein Squash) mit Main-Commit `635773db33724f543d61bacde9a9ebe679b9b1e9` übernommen. Vollständige [PR-CI #40192473811](https://github.com/ManuEtt/Dnd/actions/runs/40192473811) erfolgreich; unabhängige [Main-CI #40193476536](https://github.com/ManuEtt/Dnd/actions/runs/40193476536) vollständig erfolgreich auf dem Merge-Commit. 19/19 Archive-Tag-SHAs und 19/19 Vorfahren im GitHub-Commitvergleich bestätigt. Die sechs bereits in Main enthaltenen gestapelten Vorgänger-PRs #165/#166/#167/#168/#169/#172 wurden danach ohne Doppel-Merge geschlossen. Remote-Branches noch nicht gelöscht. App 0.8.39+89, SQLite2 und Kampagnen-JSON1.

---

## 25.10.2026 – alle Branches integriert und lokal abgenommen

Sending-W100-Validierung, Verbündetenbestätigung bei zulässigen Nebenhandangriffen, allgemeine Light-Nahkampfbonusangriffe, Schutz abgeschlossener Storyfäden, lokale und serverseitige ID-Kollisionssperren, Plot-Geheimnisschutz, Backend-Limiter und sichere Projektarchive sind vereinigt. Der bei der Integration gefundene Casefold-Fehler für generierte/Systemdateien ist mit Regressionstest behoben. Fehler beim ZIP-Schreiben oder Veröffentlichen der Prüfsumme bewahren das zuvor vorhandene Archiv; keine Zusage einer absturzübergreifend atomaren Dateipaar-Transaktion.

**1.552 Flutter-, 106 Python-, 40 Backend- und 12 native Android-Tests bestanden.** Dart-Formatierung: 360 Dateien unverändert; Flutter-Analyse sowie Backend-Typecheck und -Build erfolgreich. Debug-APK und ARM64-Alpha gebaut; Version, ZIP-CRC, ABI und lokale Debug-Signatur geprüft. Funktionscommit `cd724629c79a169ff1a078517031a33cf73ae130`, [PR #171](https://github.com/ManuEtt/Dnd/pull/171); Main-CI und sichere Bereinigung noch ausstehend. 19 Köpfe gesichert und als Vorfahren erhalten, 42 Dokumentvarianten archiviert. Version 0.8.39+89 / SQLite2 / JSON1. Operativer Stand: [CODEX_CHECKPOINT](docs/CODEX_CHECKPOINT.md).

---

## 25.10.2026 – vollständige Branch-Migration, gemeinsame Abnahme offen

Alle18 initialen Remote-Köpfe remote per Archivtag und lokal per geprüftem Bundle gesichert. Funktionsstände164/165/166 vereinigt, bereits enthaltene Squash-/Historienvarianten anhand konkreter Bäume/Patches erkannt und ohne Rücksetzen aktuellen Codes in die Historie aufgenommen. Alle Originalköpfe Vorfahren des Kandidaten;20 Dokumentkonflikt-/Altdateien historisch gesichert. Neue Gesamt-/Android-/CI-Abnahme vor Main-Merge und Branchlöschung verpflichtend. Version0.8.39+89, SQLite2/JSON1 unverändert.

---

## 25.10.2026 – Lokaler Schutz geschlossener Story-Fäden (PR #165)

- Ergänzt die bereits serverseitige Schutzprüfung aus PR #161 in `app/lib/story/ai_story.dart`: generative `threadUpdates` können einen vom Spieler zuvor `resolved`/`abandoned` markierten Strang nicht automatisch wieder öffnen oder umklassifizieren.
- Spieler kann manuell durch `saveStoryThread` erneut auf `open` setzen; danach normale KI-Fortsetzung. Bestehende zweite Importprüfung bei `applyAiStoryStep` blockiert veraltete KI-Antworten.
- Drei neue Domain-/JSON-/Eventtests; **finale neue CI auf PR #165 ausstehend**, grüne Basis aus PR #164 ist kein Nachweis. Keine Versions-/Schemaänderung.
- [PR #165](https://github.com/ManuEtt/Dnd/pull/165) · [Fachlicher Beleg](docs/STORY_LOCAL_TERMINAL_GUARD_20261025.md).

---

## 24.10.2026 – Integrationsprüfung PR #159–#163

Der technische Integrationsbranch bündelt fünf einzeln CI-geprüfte Pakete aus Sending-W100, Nebenhand-Verbündetenbestätigung, Abschlussstatus-Schutz, Backend-Quotenschutz und verbatim Plot-Secret-Schutz. Detaillierte Änderungen stehen in den folgenden überlieferten PR-Changelog-Abschnitten und in `docs/INTEGRATION_PR159_163_20261024.md`. **Die gemeinsame CI ist ein eigenständiges Gate und ist vor Abschluss des Integrations-PR erneut zu prüfen; `main` bleibt unverändert.** Spielstandsformate 0.8.38+88 / SQLite2 / JSON1 unverändert.

---

## 24.10.2026 – Backend-Erzähler: wörtliche Geheimnisoffenlegung sperren (PR #163)

- `/v1/story/start` und `/v1/story/advance` validieren neu, dass sichtbare Erzählfelder den intern gespeicherten Plot-Secret-Text nicht vollständig wörtlich enthalten. Normalisierter Case-/Whitespace-/Unicode-Abgleich und Wortgrenzen; bei Verstoß 502 ohne Durchreichen des Geheimnisses.
- Eigener reiner Backend-Guard und neue positive/negative Fastify-/Unit-Regressionen, keine externen Anbieteraufrufe. **CI auf finalem HEAD noch ausstehend**; keine Behauptung vollständiger semantischer Spoilererkennung.
- Version, Android-App und lokale Spielstände unverändert. [PR #163](https://github.com/ManuEtt/Dnd/pull/163) · [Details](docs/STORY_SECRET_OUTPUT_GUARD_20261024.md).

---

## 24.10.2026 – Backend-Anfragelimits fail-closed bei voller Kapazität (PR #162)

- Sicherheitskorrektur: der `WindowLimiter` verwirft bei Überfüllung nicht länger gültige Quoten anderer Anfrageschlüssel. Stattdessen werden nur abgelaufene Einträge bereinigt; falls alle aktiv sind, wird die zusätzliche Anfrage sicher abgelehnt.
- Zwei deterministische Backend-Regressionen für Quoten-Wahrung, Wiederholungen/Schlüsselwechsel, exakten Ablauf, partielle Bereinigung und zurücklaufende Uhr; veraltete unsichere Testerwartung korrigiert.
- Keine Änderung der Rate-Werte, Backend-API oder `Retry-After`, keine SRD-Regeländerung oder SQLite-/JSON-Migration. Verteilte Backendinstanzen benötigen weiterhin einen gemeinsamen persistenten Limitspeicher.
- Tests der neuen Version ausschließlich nach tatsächlicher PR-#162-GitHub-CI als bestanden ausweisen; reale Android-Geräteabnahme offen. [PR #162](https://github.com/ManuEtt/Dnd/pull/162) · [technische Notiz](docs/BACKEND_LIMITER_CAPACITY_20261024.md).

---

## 24.10.2026 – Verlässliche Handlungsstrang-Statuswerte im Backend (PR #161)

- Abgeschlossene (`resolved`) oder aufgegebene (`abandoned`) Handlungsstränge werden nicht mehr durch eine unbestätigte Erzählerantwort stillschweigend wieder geöffnet oder gegenseitig umklassifiziert.
- Gleichbleibender Terminalstatus mit neuer narrativer Notiz weiterhin zulässig; manuelles Wiederöffnen durch den Spieler im vorhandenen Editor bleibt möglich.
- Zwei neue Backend-Regressionsfälle für erlaubte/verbotene Übergänge und API-Fehlerantworten ohne Anbieter-Geheimnisse. Backend-/Android-/Gesamt-CI beim Dokumentationszeitpunkt noch ausstehend.
- Keine SQLite-/JSON-Migration, keine SRD-Regeländerung und keine externe Anbieter-Kostenfreigabe. [Details](docs/STORY_TERMINAL_THREAD_GUARD_20261024.md) · [PR](https://github.com/ManuEtt/Dnd/pull/161).

---

## 24.10.2026 – PR #160: neue Verbündeten-Nebenhandregeln vollständig in CI geprüft

**Vollständige GitHub-CI [#40099238901](https://github.com/ManuEtt/Dnd/actions/runs/40099238901): completed/success** auf geprüftem PR-HEAD `5563c60ba0dbbd1f12a19877f62581a51485b6d9` (24.10.2026). **1.514 Flutter-, 100 Python- und 31 Backend-Tests bestanden**; Dart-Formatierung 357 Dateien ohne Änderungen, Flutter-Analyse und Backend-Typecheck/Build erfolgreich. Android-Debug-APK, native Gradle-Tests und ARM64/ARMv7/x64-Alpha-APKs erfolgreich; letzte Artefaktschritte abgeschlossen. Ein echter Android-Gerätetest, ein Altspielstand-Upgrade und produktive Signierung fehlen weiterhin. Dieser Nachtrag berichtet die nach dem damaligen Vorab-Checkpoint eingetroffene finale Abnahme.

[Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40099238901/artifacts/12562551949) · [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40099238901/artifacts/12561909697) · [Alpha-Release](https://github.com/ManuEtt/Dnd/actions/runs/40099238901/artifacts/12562517123) · [Quellcode-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40099238901/artifacts/12562163517). Die SHA256-Digests der GitHub-Artefaktarchive sind **nicht** automatisch Einzel-APK-Prüfsummen.

---

## 24.10.2026 – SRD-Sneak-Attack: Verbündeter auch bei bestätigtem Nebenhandwurf (PR #160)

Die vorhandene manuelle Verbündetenbestätigung wird auf bereits erlaubte Nebenhandangriffe erweitert. Der Berechtigungscheck verwendet die angreifende Inventarwaffe, kontrolliert den bestehenden Bonusaktions-/Zugstatus, die fehlende einmalige Nutzung des Sneak Attack sowie bestätigte Nähe zum Ziel und Nicht-Incapacitated. Version 0.8.38+88, SQLite 2 und Export-JSON 1 unverändert; keine automatische Kampfposition oder KI-Regelentscheidung.

Neue Domain-/JSON-/SQLite- und zwei Widgetregressionen. Frühe CI: 1.513 Flutter-Tests bestanden, **ein Test wegen zu breitem Legacy-Inventar-JSON-Vergleich fehlgeschlagen**; Test präzisiert und Format korrekt nach GitHub-Dart-Formatter angewandt. Abschließende CI/Android-APK für korrigierten Commit noch ausstehend, reale Android-Abnahme und produktive Signierung weiterhin offen. [PR #160](https://github.com/ManuEtt/Dnd/pull/160) · [Details](docs/SRD_SNEAK_ATTACK_OFFHAND_ALLY_20261024.md).

---

## 24.10.2026 – Sending-W100-Dialog nur bei bestätigter Nichtblockade (PR #159)

- **IMPLEMENTIERT:** Der manuelle W100 zur bestätigten anderen Ebene erscheint nur nach explizit bestätigter Nichtblockade; bei unbestätigter oder bestätigter Blockade bleibt das Feld verborgen. Der Wert wird auch nur unter genau diesen Bedingungen an die unverändernde Sending-Vorschau weitergereicht.
- Jede Änderung der Blockadeauskunft verwirft den zuvor eingegebenen W100 und die Zustimmung. Zwei neue Widget-Regressionsfälle betreffen Statuswechsel und das Verbot der stillschweigenden Wiederverwendung.
- **GETESTET:** Vorherige erfolgreiche Main-CI #40092582286 (auf dcb42c5) und PR-#158-CI #40093571340 (auf 80b615e) gelten nur für ihre jeweiligen Quellstände.
- **NICHT GETESTET:** Neue PR-#159-CI sowie echtes Gerät bis zu eigenständigem Nachweis. Version 0.8.38+88, SQLite 2 und JSON 1 unverändert; kein Sender-/Empfängertransport, keine neue SRD-Regel.

---

## 24.10.2026 – 0.8.38+88: tatsächliche Nebenhandwaffe für Hinterhältigen Angriff

Die vorhandene Nebenhandauflösung prüft jetzt ihre bestätigte Inventarwaffe auf Finesse/Fernkampf. Ein Hauptdolch verleiht einer Nebenhandaxt keinen Zusatzschaden; ein Nebendolch verliert seine Eignung nicht durch eine Haupthandaxt. Krit/Miss und bestehende gemeinsame Zugnutzung bleiben erhalten. 27 bestehende/Helper- und acht neue Kampf-/SQLite-Tests erfolgreich. Vollständige lokale Abnahme: 1505 Flutter-,100 Python-,31 Backend- und12 native Tests erfolgreich, Format/Analyse/Importgrenzen ohne Befund. Neue Debug-APK und ARM64-Alpha gebaut und geprüft. Eigene finale GitHub-Checks am PR158 getrennt geführt; Realgerät nicht getestet. SQLite2/JSON1 kompatibel. Details und nächstes Paket: [CODEX_CHECKPOINT](docs/CODEX_CHECKPOINT.md).

---

## 24.10.2026 – Sending-Bestätigungsdialog (neuer Entwicklungsbranch, CI offen)

- Deutschsprachiger, scrollbarer Dialog für Empfänger, Nachricht, Klasse/Zauberplatz und manuell bestätigte SRD-Fakten. Vor Bestätigung keine Zustandänderung, Eingabeänderung widerruft Zustimmung.
- Statusvorschau für verbleibende Slots und unbekannte/blockierte/planar fehlgeschlagene Zustellung; `Sending` in der Abenteueransicht nur außerhalb aktiver Kämpfe/offener Würfe.
- Bestehender Controller schreibt ausschließlich lokale Slot-/SQLite-Quittung; UI zeigt Erfolg nur bei gespeichertem passendem Ereignis. Keine echte magische Zustellung.
- Neue Widget- und SQLite-Integrationsregressionen; `main` vor der Änderung vollständig grün in CI #40084074765, neue PR-CI noch ausstehend.
- Keine Änderung an App-Version, Datenbankschema, Export-JSON oder SRD-`partial`-Status.

---

## 24.10.2026 – Sending-Slot-/Journal-Code vollständig CI-grün (PR #156)

- [Workflow #40078375498](https://github.com/ManuEtt/Dnd/actions/runs/40078375498) auf ausführbarem SHA `2566a84e` erfolgreich: Python/Backend, Dart/Flutter inklusive neuer SQLite-Regressionen, nativer Android-Test, Debug-/ABI-Alpha-Artefakte und Source-ZIP.
- Frühe Format- und Quelltextduplikationsfehler vor dieser Abnahme repariert. Kein temporärer Diagnoselauf im finalen Quellbaum.
- Keine geänderten Datenbankschemas, kein echter Nachrichtenversand, keine Geräteabnahme. Nachtrag nur Dokumentation.

---

## 24.10.2026 – Sending-Versuch nach expliziter Bestätigung buchen (PR #156)

- Vorschaugebundenes Helden-Snapshot verhindert veraltete Zauberplatzbuchung.
- GameEngine/Controller protokollieren bestätigten Sending-Versuch und Slotverbrauch atomar als lokales SQLite-Ereignis; kein magischer Nachrichtentransport.
- Übergreifende Anfrage-ID schützt vor Duplikat und widersprüchlicher Bestätigung, auch bei erneutem Aufruf/SQLite-Neustart.
- Neue Domain-/Persistenztests für Bestätigung, Ablehnung, Revision, IDs und SQL-Rollback. Vollständige Flutter-/Android-CI dieses PRs zunächst ausstehend.
- Keine Änderung an Version, Schema, SRD-Vollständigkeitsstatus oder produktiver Signierung.

---

## 24.10.2026 – Sending-Unicode-Formatsteuerung absichern (Draft-PR #155)

- U+00AD, U+034F, U+061C, U+180E, U+2061–U+206F und U+FFF9–U+FFFB werden zusätzlich als unsichtbare Format-/Annotationszeichen in Sending-Nachrichten und Empfänger-IDs abgewiesen.
- Neue Domain-/Casting-Preview-Regressionen: versteckte 26-Wort-Nachrichten und manipulierte Empfängeridentitäten.
- Version `0.8.37+87`, SQLite 2 und Export-JSON 1 unverändert; keine Zauberausführung und keine neue SRD-Mechanik.
- Lokaler Regex-Sanity-Check erfolgreich; vollständige neue Dart-/Flutter-/Android-CI noch nicht abgenommen. Vorherige grüne CI gehört zu einem anderen Commit.

---

## 24.10.2026 – Sending-Resource-Preflight vollständig CI-validiert

- Vollständige [PR-CI #40071729227](https://github.com/ManuEtt/Dnd/actions/runs/40071729227) grün auf Code-Commit `efed3d732459478b072452ab8e92ef3c674e39fd`: Flutter, Python/Backend, native Android-/APK-Builds und Alpha-/Source-Artefakte.
- Der neue reine Rule-Preflight führt weiterhin weder eine Nachrichtenzustellung noch eine Spielstandbuchung aus; reine Dokumentationsfortschreibung nach der erfolgreichen Code-Abnahme. Kein reales Android-Gerät getestet.

---

## 24.10.2026 – Sending-Vorprüfung mit bestätigter Zauberressource

- `SrdSendingCastPreflightRules.preview` verbindet Ziel-/Nachrichtenprüfung mit Klassen-, Stufen-, vorbereiteter Zauber-, Slot-, Komponenten- und Aktionsbestätigung; keine Zustandsmutation.
- Manipulierte Sending-Metadaten und fehlender Kupferdraht-/Fokusbeleg werden verweigert. Bekannte andere Ebene verlangt belegten W100, unbekannte Fakten bleiben unbekannt.
- Sieben neue Rule-Domain-Regressionsgruppen; CI für den neuen Stand noch ausstehend. Keine Datenmigration oder App-Versionserhöhung.

---

## 24.10.2026 – Abnahme der Sending-Input-Regressionsfälle

- Vollständige [GitHub-Actions-CI #40068321150](https://github.com/ManuEtt/Dnd/actions/runs/40068321150) auf Code-HEAD `fb96641db97598a5ee1b59416ad254f5e0e63e29` erfolgreich, inklusive Flutter-/SQLite, Android-Debug/native Tests, kleiner Alpha-APKs und versioniertem Alpha-Artefakt.
- Nur Dokumentationsnachtrag nach dem grünen Code-Lauf. Android-Gerätetest und vollständiger Spellcast bleiben offen.

---

## 24.10.2026 – SRD-Sending: Nachrichten- und Kennungsintegrität

- Versteckte Wortseparatoren, Bidi- und ASCII-Kontrollzeichen werden vor dem Zählen abgewiesen.
- Technische App-Grenze 2048 UTF-16-Einheiten statt unbeschränkt langer Tokens; dies ist keine zusätzliche SRD-Regel. Whitespace-25-Wort-Regel weiterhin unverändert.
- Domain-Manipulations- und Positivtests ergänzt. Neue PR-CI und reale Android-Abnahme noch offen.
- Keine Änderung an Slots, Kampagnen, SQLite/JSON oder Version.

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

## 23.10.2026 – 0.8.37+87: Hinterhältiger Angriff mit bestätigtem Verbündeten

- Tatsächliche Hauptwaffen-Kampfintegration statt ausschließlich Helper: explizite Nähe zum Ziel und fehlende Handlungsunfähigkeit, pro Kampagne/Ziel/Probe gespeichert, vor dem Würfeln entfernbar.
- Zusatzschaden, kritische Treffer und einmalige Nutzung im eigenen Zug über bestehende Engine; keine aus Erzählung abgeleiteten Fakten.
- SQLite-Neustart, Backup, Journal, stale Revision und später Speicherfehler durch 11 neue Domain-/Integrationstests; 6 neue Widgettests einschließlich 360dp, großer Schrift und Tastatur.
- Gespeicherte Angriffsboni verwenden dieselbe Berechnung wie die Ausführung (einschließlich Mehrklassen-Bogenschießen).
- Vollständige Dart-Formatprüfung in CI wiederhergestellt; reine Normalisierung bestehender Dateien separat in 309b07e.
- SQLite2/JSON1 bleiben kompatibel. Lokaler Gesamtcheck mit 1.448 Flutter-, 100 Python- und 31 Backend-Tests erfolgreich. Debug-APK und12 native Tests erfolgreich; GitHub-Code-CI40056875863 auf182f44b vollständig grün, ARM64-Alpha geprüft, Realgerät offen; Ergebnis siehe docs/CODEX_CHECKPOINT.md.

---

## 23.10.2026 – 0.8.36+86: Schurken-Hinterhältiger-Angriff – bestätigter Verbündeter (CI offen)

- Der bisherige reine Helper-Check für einen nahen, bewussten Verbündeten genügt nicht mehr allein. Der alternative SRD-5.2.1-Weg zum Hinterhältigen Angriff verlangt nun zusätzlich bestätigte Nähe des Verbündeten **zum Ziel** und das bestätigte Fehlen des Zustands `Incapacitated`.
- Direkter Angriffsvorteil qualifiziert weiterhin unabhängig; bei aufgehobenem Vorteil/Nachteil genügt ein bloß anwesender oder kampfunfähiger Verbündeter nicht.
- Zusätzliche Unit-Regressionen und präziser `partial`-Eintrag in der SRD-Anforderungsmatrix. Keine frei erfundene Verbündetenposition. Die Kampfengine besitzt noch keine bestätigte Positionsintegration und setzt ihre bisherige Verbündetenangabe unverändert auf `false`.
- SQLite-Version 2, JSON-Spielstandsformat 1 unverändert; neue CI und Realgerät-Abnahme noch offen.

---

## 23.10.2026 – 0.8.35+85: Bestätigte Sicht für SRD-Zauberreichweite „Sight“ (CI ausstehend)

- SRD-5.2.1-Zielvorprüfung akzeptiert `Sight` nur mit explizit bestätigter Sicht, zulässiger räumlicher Ursprungsklasse und unabhängig bestätigtem freiem Weg.
- Taktische Rasterkarten übermitteln eine eigene Sichtbestätigung, ohne aus einem nicht blockierten Strahl Sicht zu folgern. Unbestätigte Sicht und Blocker bleiben fail-closed.
- Ziel-/Rasterregressionen erweitert; `Unlimited` und `Special` weiterhin unimplementiert, `Mirage Arcane` kann wegen 10-minütiger Zauberzeit nicht als Ein-Aktions-Zauber ausgeführt werden.
- Ohne Änderung an Datenbankversion 2, Spielstandsschema 1, Ressourcen, KI und Story. Neue CI-/Geräteabnahme noch offen.

---

## 23.10.2026 – Aus Alt-PR übernommene Bestandsmigrationstests (#141)

- Tests für gefüllte SQLite-v1-Spielstände, inklusive Kampagne, Revisionen, bestätigtem Ereignisjournal, Heldenarchiv und Einstellungen, auf aktuellem Main-Stand wiederhergestellt.
- Weitere Regression auf doppelte ausstehende Request-IDs mit vollständig rückgängig gemachter Version-1→2-Migration, ohne Daten- oder Journalverlust.
- Die PR-CI #39994226404 war vor Merge-Konflikt-Auflösung vollständig erfolgreich; neuer kombinierter HEAD verlangt erneute CI. Produktversion bleibt **0.8.34+84**, SQLite-Version 2, JSON-Exportschema 1.

---

## 23.10.2026 – 0.8.34+84: Atomare Kampagnenlöschung und Auswahlbereinigung (CI ausstehend)

- Beim gezielten Kampagnenlöschen werden Kampagnenstand, ausstehende Spielerhandlung und ein eventuell auf sie verweisendes `lastCampaignId` atomar bereinigt. Neuere, auf eine andere Kampagne gerichtete Auswahl und unabhängige Einstellungen bleiben bestehen.
- `GameController` nutzt den neuen `AtomicCampaignDeletion`-Vertrag für SQLite und verhindert das alte zweite Schreiben mit `_remember(null)`; bisheriges Verhalten für Test-/Legacy-Repositories bleibt verfügbar.
- Regressionstests für gleichzeitige SQLite-Verbindungen, Neustart, unveränderte andere Auswahl und vollständigen Rollback bei einem fehlgeschlagenen Settings-Update.
- Ohne DB- oder Kampagnen-JSON-Schemamigration, ohne zusätzliche Regel-, KI-, Story- oder Berechtigungsänderungen. Neue CI und Realgerätetest noch offen.

---

## 23.10.2026 – 0.8.33+83: Atomarer vollständiger Datenreset (Code-CI erfolgreich)

- SQLite-Implementierung von `AtomicUserDataReset`: Kampagnen, bestätigte Events, Revisionshistorie, Charaktere, Einstellungen und PlayerActionOutbox werden im gleichen Transaktionscommit gelöscht oder bei einem Fehler vollständig erhalten.
- `GameController.deleteAllData` nutzt den atomaren SQLite-Vertrag; Test-/Legacy-Repositories behalten den bisherigen Fallback.
- Neuer SQLite-Regressionstest prüft Erhalt der Daten und Controlleransicht bei einem erzwungenen späten Löschfehler, erneutes Löschen sowie Neustart ohne zurückgebliebene Einträge.
- Keine Migration von Datenbankschema 2 oder JSON-Spielstandsformat 1, keine SRD-Regeländerung. Die erste CI #39945364361 deckte einen Fehler in der Testverbindung auf; nach getrennten SQLite-Testverbindungen ist [GitHub-Actions-Lauf #39946157697](https://github.com/ManuEtt/Dnd/actions/runs/39946157697) auf Code-HEAD `0145108c` mit Flutter-, Backend-, nativen Android-Tests sowie Debug-/Alpha-APKs erfolgreich. Reale Geräteabnahme weiterhin offen.

---

## 23.10.2026 – 0.8.32+82: atomare Änderungen der App-Einstellungen (CI ausstehend)

- Campagneauswahl, Narrator-Verbindung und Sprachpräferenzen nutzen statt veralteter kompletter Settings-Snapshots transaktionale Teilupdates in SQLite.
- Gleichzeitige Änderungen unabhängiger Schlüssel werden nicht mehr durch den zuletzt schreibenden alten Snapshot verworfen. Explizite Löschung einzelner Felder wird unterstützt; `saveSettings({})` für absichtliches Datenlöschen bleibt bestehen.
- Korrektur: Die eigenständige Outbox wird beim gezielten Löschen einer Kampagne beziehungsweise beim vollständigen Datenreset ebenfalls bereinigt; andere Kampagnen bleiben erhalten.
- Regressionstests für konkurrierende DB-Verbindungen, beschädigte Patch-Eingaben/Rollback, Outbox-Isolation und Laden der Kampagne nach Neustart. Bestehende Datenbankschema-Version 2 und Kampagnen-Exportversion 1 bleiben unverändert. GitHub-CI des neuen Branches und reale Geräteabnahme noch offen.

---

## 23.10.2026 – 0.8.31+81: transaktionale Spielerhandlungs-Outbox (Code-CI grün)

- SQLite-DB-Schema 2 hält ausstehende Handlungen getrennt von übrigen Einstellungen; Eindeutigkeit der Aktionskennung und Kampagnenbindung werden in Transaktionen geprüft.
- Upgrade der Datenbank von Version 1 übernimmt gespeicherte Aufträge und Settings ohne stillen Datenverlust, verweigert beschädigte Altaufträge; JSON-Kampagnenexportformat bleibt bei Version 1.
- Tests ergänzt für gleichzeitige SQLite-Schreiber, veraltete Einstellungen, Recovery und fehlerhafte Migration. Vollständige [GitHub-Code-CI #39938760852](https://github.com/ManuEtt/Dnd/actions/runs/39938760852) auf SHA `1ca83e63` erfolgreich einschließlich Flutter-Tests, Android-Debug- und Alpha-APKs; echte Geräteabnahme steht aus.

---

## 22.10.2026 – SRD-5.2.1-Linienvorschau (CI offen)

- Neue read-only-2D-Vorschau für Linienflächen mit bestätigter Länge, Breite, Richtung und geprüftem Zauberursprung.
- Separate Randkandidaten, Ursprungspunktregel, Blocker-Review; keine automatisch behaupteten Treffer/Schäden.
- Domain-Regressionstests, SRD-Abdeckungsmatrix und Regel-API ergänzt.

---

## 21.10.2026 – SRD-Kegelflächen (Entwicklungs-PR, CI offen)

- 5-Fuß-Raster erhält konservative Kegel-Kandidatenvorschau in acht Himmelsrichtungen. Geometrische Rand-/Mittelpunktüberlappung, Startpunktentscheidung und fehlende Cover-Auflösung werden separat ausgegeben.
- Bestätigter SRD-Zauberursprung und bestätigte Kegellänge werden getrennt validiert; weder Treffer noch automatische Zauberwirkung.
- Neue Regeltests und `rules_api.dart`-Export; vollständige SRD- und Android-Geräteprüfung bleiben offen.

---

## Unveröffentlicht – Rabenwacht, drei neue spielbare Kapitel (21.10.2026)

- Akt VIII führt den Rat der Zeugen sowie drei Beweis- und Entscheidungswege zu einem nichtlinearen Finale.
- Der optionale Epilog macht drei NPC-Gespräche und drei dauerhafte Dorfvermächtnisse spielbar.
- „Der Brief von Morgen“ setzt freiwillig danach ein: drei unabhängige Spuren und drei alternative Ausgänge. Savegame, Held und altes Kampagnenende bleiben unverändert.
- SRD-Regelengine und parallele Material-/Flächenzauberentwicklung bleiben unberührt; vollständige konsolidierte CI vor Merge offen.

---

## 21.10.2026 – Read-only Feuerball-Kartenvorschau im Abenteuer (CI offen)

- Interaktive 5-Fuß-Rasterplanung mit veränderbaren Figuren-/Ursprungspositionen und Vollhindernissen, bestätigter Kartenvollständigkeit und automatisch verworfenen alten Ergebnissen.
- Anzeigen von möglichen Kugel-Randfeldern, freien Mittelpunktsstrahlen und unklarer Deckung ohne falsche automatische Treffer- oder Schadensannahmen.
- Neue Widgettests, SRD-Audit- und Architekturhinweise; keine Änderungen an persistiertem Kampf-, Material- oder Zauberzustand.

---

## 21.10.2026 – Konservative Vorschau kugelförmiger SRD-Zaubereffekte (CI offen)

- 2D-Rasterkandidaten für separat bestätigte Kugelradien inklusive überlappender Randfelder; geprüfter Ursprung und Zauberreichweite.
- Explizite Unterscheidung zwischen freien Mittelpunktstrahlen und ungeklärtem Cover; keine unbestätigten Treffer/Zauberschäden.
- Neue Regressionstests, öffentliche Regel-API und Audit-Nachweise; keine Speicherformatmigration.

---

## 21.10.2026 – Kartengestützte SRD-Zauberursprünge (Integrations-PR, CI offen)

- 5-Fuß-Raster mit konservativer Eckensperre und bestätigten Blockern berechnet Entfernungen und freie geradlinige Mittelpunktverbindungen deterministisch.
- Preflight unterstützt kartengestützte statt nur manuell angegebene Distanzen; Touch-Integration samt SQLite-Ereignis-Replay über Regressionen abgesichert.
- Noch keine vollständige Sicht-/Deckungs-/3D- und Zielwirkungsberechnung; unbekannte Felder bleiben unzulässig.

---

## 21.10.2026 – Strukturierte SRD-Zauberreichweite (Entwicklungs-PR; CI offen)

- Neue konservative Prüfung von Ursprung, Reichweite, Touch/Self und direktem Zielweg; Sonderreichweiten bleiben gesperrt.
- Vor dauerhaftem Material-/Slotverbrauch ist nun ein überprüfter räumlicher Ursprung erforderlich; das SQLite-Ereignis speichert die Bestätigung. Die bestehenden dedizierten Zaubereffekte bleiben separat.
- Neue Regressionstests mit Grenzwerten und unzulässigen Konstellationen; keine automatische Karten-/Sichtliniengeometrie behauptet.

---

## 21.10.2026 – SRD-Zaubermaterialien in Kampagnenrevisionen (Integrations-PR, CI offen)

- Verbinde bestätigte Material-/Slot-Regeländerung mit `GameEngine`-Audit-Ereignis `spell.materialsCommitted` und bestehendem `GameController`-SQLite-Revisions-Commit.
- Regressionen für Neustart, Revisionen, doppelte Anfragen, fehlende Materialien, konkurrierende Schreibzugriffe und Blockierung im laufenden Kampf ergänzt.
- Keine automatische Zauberwirkung oder freie Materialnamen-/Preisinterpretation; kein neues Speicherformat.

---

## 21.10.2026 – SRD Materialinventar atomar (eigener Entwicklungsbranch, CI offen)

- Nach PR #74 neuer reiner Domain-Baustein für gemeinsam geprüften Zauberplatz- und verbrauchbaren Materialabzug aus einer bestätigten Inventarinstanz.
- Sicherheitsprüfungen für doppelte IDs, fehlende oder ungenügende Mengen, ausgerüstete Gegenstände, alte Zauberfreigaben und doppelte Verbuchung. Keine Änderungen am ursprünglichen Charakter bei Fehlern.
- Neue Dart-Regressionstests und SRD-Matrix-Belege; kontrollierte Übergabe an Controller offen. Keine fertige automatische Materialrezept- oder Persistenz-Integration behauptet.

---

## 21.10.2026 – Rabenwacht: Die vierzehnte Stimme, spielbarer Akt VI (Entwicklungsbranch)

## Unveröffentlicht – Rabenwacht Akt VII (Entwicklungsbranch, 21.10.2026)

- Optionale Fortsetzung „Die vierzehnte Stimme“ um die interaktive Chronistenbibliothek, Eidblatt-Ermittlungen und drei eindeutig gespeicherte Antworten auf das gefährliche Angebot erweitert; bewusster Preisdialog verlangt einen exakten Bestätigungssatz.
- Spielerkontrolle, frühere Quests, EP, Inventar, Held und bestätigte Kampfregeln bleiben unverändert. Eigenständige Regressionstests geschrieben; vollständige CI und Geräteabnahme stehen aus. Baut auf dem noch offenen Akt-VI-PR #77 auf.

- Expliziter Start der Fortsetzung über „Fortsetzung beginnen“ nach einem abgeschlossenen Original-Finale, mit Erhalt von Held, Erinnerungen, NPCs und altem Queststatus.
- Eigenständiges Story-Modul `app/lib/story/fourteenth_voice_campaign.dart` samt eigenem Modus `rabenwacht-voice-v1` (Trennung Story/Regeln).
- Drei frei kombinierbare Ermittlungsstränge bei Elda, Tarek und dem namenlosen Grab, gespeichert mit echten SRD-Fertigkeitsproben; zwei unabhängige Belege öffnen das Haus ohne Türen.
- Lioras Vertrauen wird anhand einer echten Entscheidung persistiert. Spoilerfreies Journal, neue Quests, optionaler Einstieg in die Porträtgalerie, JSON-Speicherrundlauf.
- Kein automatisch gewährter Zauber, keine improvisierten Gegnerwerte oder zusätzlichen Erfahrungspunkte. Spätere Akte VII–VIII noch nicht implementiert.
- Tests in `app/test/rabenwacht_fourteenth_voice_act6_test.dart`; vollständige CI/Android-Build stehen aus.

---

## 21.10.2026 – SRD 5.2.1 Materialkomponenten (Teilregel, CI offen)

- Neue reine Regelprüfung für konkrete, kostspielige und verbrauchte Zaubermaterialien; teure oder konsumierte Komponenten dürfen nicht durch Komponentenbeutel oder Fokus ersetzt werden.
- Vorprüfung verlangt bei Bedarf bestätigte teure Materialien, Reservierung und separaten Verbrauch, bevor der Zauberplatz verbucht wird. Das Inventar wird noch nicht automatisiert verändert.
- Neue Domain-Regressionsfälle, öffentliche Regel-Fassade und aktualisierte SRD-Anforderungsmatrix; Spielstände, Story und bestehende Spezialzauber bleiben unverändert.
- **Offen:** Formatierung/CI-Gesamtabnahme, effektiver Materialabzug, vollständiger offizieller SRD-Abgleich und Android-Gerätetest.

---

## 21.10.2026 – Version 0.8.30+80 (Regelengine/Story-Modultrennung, CI offen)

- Rabenwacht-Kampagnencode vollständig unter `app/lib/story/rabenwacht_campaign.dart` verschoben. Bestehende statische Domain-API als kurze Kompatibilitätsfassade mit identischen Rückgabetypen/Speicherformaten erhalten.
- Direkte Rabenwacht-Klassenproben- und XP-Aufrufe durch neuen `StoryRulePort` ersetzt. Die Regelimplementierung und bestätigten XP-Schwellen verbleiben im Domain-Regeladapter.
- KI-Storyparser `AiStoryPlan`/`AiStoryStep` nach `story/ai_story.dart` verlagert, bisheriger Domain-Import exportiert die kanonische Implementierung.
- Klare öffentliche `story_api.dart`-/`rules_api.dart`-Grenzen, Architekturregression in `scripts/tests/test_module_dependencies.py`, separate Testdouble-/Kompatibilitätstests.
- Zwei unabhängige Entwicklungsstränge mit kleinen Integrations-PRs in `docs/ARCHITECTURE_RULES_STORY.md` beschrieben, einschließlich realistischem Restaufwand.
- Noch nicht vollständig entkoppelt: historische `GameEngine` vereint weiterhin Story-/Regelkoordination; vollständige Flutter-/Android-CI und Gerätetest stehen aus.

---

## 21.10.2026 – Version 0.8.29+79 (zusätzliche Kreaturenangriffe, CI offen)

- Erster **tatsächlicher** Waffenangriff einer lebenden SL-gesteuerten Zusatzkreatur während ihres manuell aktiven Zuges, vorerst gegen eine andere gespeicherte Zusatzkreatur.
- Getrennt bestätigte Angriff-/Schadenswerte und Schadensart, Reichweite, Deckung/RK, Vor-/Nachteil, Reaktionen und fehlende Sonderfähigkeiten. D20-Naturwurf 1/20, kritische zusätzliche Schadenswürfel ohne doppelte statische Boni.
- Ein Angriff pro manuellem Zug mit persistentem `manualTurnQueue.actionUsed`, Zurücksetzen bei Zugwechsel. Ein gemeinsamer revisionsgeschützter Commit für Ziel-TP, Aktionsverbrauch und `combat.manualExtraCreatureAttack`-Ereignis.
- Neue Dialog-/Schnellaktion und Tests für Legacy-Speicherung, Treffer/Fehlschlag/Krit, Deckung, mehrfachen Aktionseinsatz, ungültige Ziele und unbestätigte Werte.
- **Weiterhin partial:** Keine Attacken auf Held/Hauptgegner oder vollständige zusätzliche Monsterzüge, keine automatische Verifikation von Statblocks oder Resistenzfähigkeiten. Android-Geräteprüfung ausstehend.


---

## 21.10.2026 – Rabenwacht: Die stumme Strophe und vierter Ausgang (Story-Branch)

- Spielbarer neuer Kapellenstrang mit Bruder Oswin, verlorener Liedstrophe, moralischer Bewahren-/Vernichten-Entscheidung und nachholbaren Belegen.
- Neues geheimes Finale `end-chorus` bei vier tatsächlich erreichten Story-Voraussetzungen. Bestehende drei Enden bleiben verfügbar.
- Sofortige NPC-Reaktionen, Journal, offener/abgeschlossener/gescheiterter Nebenauftrag und einmalige Abschluss-EP.
- Zehn neue Regressionstests für Spoilerschutz, Zweigentscheidungen, Speicherstände, viertes Ende und klassische Enden.
- Technische CI- und Android-Freigabe noch offen.

---

## 21.10.2026 – Rabenwacht: alternative Fertigkeitswege (CI offen)

- Turmruine, Kryptatreppe und dreizehnte Tür bieten jeweils einen neuen Rechercheweg über Nachforschungen, ohne die bisherigen Arkane-Kunde-/Athletik-Proben zu ersetzen.
- Belegprüfung vor dem historischen Lösungsweg; Ergebnisfakten unterscheiden den eingeschlagenen Weg, und Fehlschläge verraten keine Geheimnisse.
- Ausgesprochene Zauberwünsche verändern keine Ressourcen oder Ergebnisse ohne bestätigte Zauberaktion.
- Zehn neue Flutter-Regressionsfälle; CI/Android-Abnahme und Gerätetest stehen noch aus.

---

## 21.10.2026 – Rabenwacht: NPC-Erinnerungen und alternativer Waldpfad (Entwicklungsbranch)

- Tarek gibt seinen geheimen Kundschafterpfad nur nach ausdrücklicher Bitte preis; der Weg lässt sich bei der Rabenschlucht tatsächlich benutzen und respektiert frühere Krähenalarme.
- Alrik gesteht nach der bewiesenen Gedenkstein-Quest seine Vertuschung; Mara überdenkt daraufhin ihr Schweigen und ihr Verhältnis zum Helden.
- Hinweise, gespeicherte Beziehungen, reaktive Dialoge und Epilog erweitern sich um bestätigte Ereignisse ohne neue SRD-Werte oder wiederholbare Meilenstein-EP.
- Sieben weitere Regressionstests für Geheimweg, Sperren, Reise, EP, Geständnis, Versöhnung und kompletten Charakterpfad; Flutter-/Android-CI offen.

---

## 21.10.2026 – Rabenwacht: Die ausgelöschten Namen (Entwicklungsbranch auf main)

- Optionaler Gedenkstein am Friedhof mit neuer Quest, Erinnerungsentscheidung und spoilerfreien Fakten.
- Zur Bewahrung der Namen sind tatsächlich gefundene Belege notwendig. Verschweigen, Rückkehr und ungelöste Nebenquest bleiben möglich.
- Beide Entscheidungen beeinflussen gespeicherten Queststatus und drei Epiloge; keine zusätzlichen SRD-Regelwerte oder doppelte EP.
- Neue Flutter-Domaintests `rabenwacht_memorial_test.dart`; CI-/APK-Ergebnis bis zum Prüflauf offen.

---

## 21.10.2026 – Rabenwacht: verzweigte Ermittlungen (unversionierter Entwicklungsbranch, CI offen)

- Mara Voss erhält eine eigene Ratsstuben-Szene: Verschwiegenheit und Brief an Alrik, Konfrontation und Vertrauensverlust oder der direkte Ermittlungsweg über Fina.
- Bereits entdeckte Orte können ohne doppelte EP erneut aufgesucht werden; Besuche und neue Entscheidungen bleiben in bestehenden Kampagnenfakten gespeichert.
- Bewusste Kampfentscheidung beim Skelettwächter: verneinte Angriffe und bloße Schlüsselinteressen starten keinen Kampf.
- Erfolgreiches Überreden von Seren führt zur **Wahl** statt zum sofortigen Ende. Maras Beziehung und der Krähenalarm verändern den Epilog.
- Neue Tests in `app/test/rabenwacht_branching_story_test.dart`. **Flutter-Tests und Android-Build vor CI nicht bestätigt**; keine Versionsnummer erhöht.

---

## 21.10.2026 – Version 0.8.28+78 (manuelle Mehrgegner-Zugfolge; CI offen)

- Optionale, gespeicherte manuelle Zugfolge mit Kampf-ID, eindeutigen Akteur-IDs, Position und eigener Rundenzählung. Alte Kampagnen ohne Feld bleiben unverändert gültig.
- Vollständige bestätigte Initiativen aller lebenden Beteiligten und ausdrücklich entschiedene Gleichstände erforderlich. Nur gleich hohe Initiative darf umsortiert werden.
- Neue Schnellaktion „Manuelle Zugfolge“ mit visueller Tiebreaker-Auswahl und manueller Marker-Fortsetzung. Besiegte Zusatzkreaturen werden übersprungen; eine neue Runde wird erkannt.
- Revisionsgeschützte Engine-/Controller-Aktionen, überprüfbares Kampfjournal, Invalidierung nach Initiativ-/Akteuränderung oder Kampfende sowie Regressionstests.
- **Keine vorgetäuschte neue automatische Mehrgegner-Kampfengine:** Der Marker verleiht weder Aktionen noch erzeugt er Gegnerangriffe und beeinflusst die bestehende `Encounter`-Reihenfolge nicht.
- PR/CI- und echter Android-Gerätetest noch ausstehend.

---

## 20.10.2026 – Version 0.8.27+77 (Mehrgegner-Initiativverwaltung, CI offen)

- Weitere bestätigte Kreaturen speichern ein optionales Initiative-Gesamtergebnis sowie die zuständige SL-/Spieler-Kontrolle im abwärtskompatiblen schema-1-Kampagnenformat.
- Neue SRD-5.2.1-Initiativvorschau: absteigende Gruppen; bei Gleichstand wird **keine** künstliche Reihenfolge erfunden. Fehlende und bisher nicht bestätigte Initiativewerte werden angezeigt.
- Neue Kampf-Schnellaktion „Initiative der Kreaturen“ samt Eingabe, revisionsgeschütztem Controller-Commit und Ereignisjournal. Ausgeschiedene Kreaturen werden in der Runden-Vorschau ausgeblendet.
- Regressionstests für alte Kampagnen, 0-Initiative, Ungültigkeitsprüfungen, Unentschieden, Roundtrip, UI und unveränderte Trefferpunkte.
- **Noch kein vollständiger Mehrgegner-Zugscheduler:** Zusatzkreaturen besitzen weiterhin keine automatisch ausgelösten Angriffe oder Initiative-Zugrechte. Kein Gerätetest; CI zur Version ausstehend.

---

## 20.10.2026 – Version 0.8.26+76 (Zusätzliche Kreaturen für Flächenzauber – CI offen)

- Separate bestätigte Kreaturen mit ID/Name/TP können im Kampagnen-Spielstand erfasst und von Säurespritzer gemeinsam mit dem Hauptgegner getroffen werden. Eindeutige IDs, unveränderliche Speicherlisten, alte schema-1-Speicherstände.
- Individuelle GES-Rettungswürfe/Deckung, ein gemeinsamer Flächenschadenswurf, separate neue TP und gemeinsamer persistenter Kampfjournal-Eintrag.
- Neue UI für HP-Erfassung, zusätzliche Zielauswahl und pro-Ziel-Prüfung; Tests für Duplikate, veraltete Werte, ältere Spielstände und gleichzeitige HP-Änderungen.
- Kein bereits vollständiger Mehrgegnerkampf: zusätzliche Kreaturen bleiben HP-geführte Flächenziele ohne automatische Aktionen und Initiative. Android-Geräteabnahme noch offen.

---

## 20.10.2026 – Version 0.8.25+75 (Säurespritzer / Mehrziel-Regelkern, CI ausstehend)

- Neues reines Regelmodul `AcidSplashRules`: 2024er 5-Fuß-Radius-Kugel mit eigenen GES-Rettungswürfen pro bestätigter Kreatur, nur **einem** gemeinsam verwendeten 1–4W6-Säureschadenswurf pro gleichzeitiger Wirkung und individueller HP-Berechnung.
- Deckungsboni relativ zum Flächenursprung; maximale 20 Prüfeinträge als technischer Schutz, nicht als SRD-Regel. Keine erratenen Positionen, Monsterfähigkeiten oder Abwehrwerte.
- Kampflogik/Controller/UI/Journal implementiert, **vorerst nur wenn der eine aktive Gegner nachweislich die einzige Kreatur in der Kugel ist**. Weitere Ziele werden nicht stillschweigend ignoriert; echte Mehrgegner-Persistenz folgt separat.
- Domain-/Engine-/Widgettests; Anforderungs-Mapping `SPELL-ENTRY-ACID-SPLASH` als `partial` und ausführliche Grenzen dokumentiert.
- CI-/APK-Abnahme und Android-Gerätetest bei diesem Eintrag ausstehend.

---

## 20.10.2026 – Version 0.8.24+74 (Heilige Flamme / Rettungswürfe, CI ausstehend)

- Wiederverwendbare `SrdSpellSavingThrowRules` für Zauber-SG und bestätigte gegnerische Rettungswurfboni mit W20, Vorteil/Nachteil und 2024-Regeln für natürliche 1/20.
- Neue Kleriker-Kampfaktion `Heilige Flamme` mit V/S, Sicht/Reichweite, Geschicklichkeitsrettungswurf, deckungsunabhängigem Rettungswurfbonus (halbe/3⁄4 Deckung) und Strahlenschaden 1–4W8 nach Gesamtstufe; Erfolg 0 Schaden.
- Bestätigungsdialog, Controller-Revisionsschutz, lokaler RNG, Gegner-Trefferpunkte, Magieaktion und persistiertes Ereignis `spell.sacredFlame`.
- Kein Gegnerstatblock geraten, keine versteckten magischen SG- oder Schadensanpassungen. Nur Einzelziel und Teilabdeckung; neue Domänen-/Engine-/Dialogtests.
- PR-/Android-CI und echter Gerätetest bei Anlage dieses Eintrags noch nicht freigegeben.

---

## 20.10.2026 – Version 0.8.23+73 (Feuerpfeil – CI ausstehend)

- Erste neue vollständig durch Engine/Controller/UI integrierte Schadens-Zaubertrick-Aktion `spell.fireBolt` mit W20-Angriff, Deckung, Trefferlogik, kritischen Treffern und stufenabhängigen Feuer-Schadenswürfeln.
- Prüft bestätigte Zauberklassen/Verfügbarkeit, Komponenten, Sicht, Reichweite, Angriffsumstände und bekannte gegnerische Feuer-/Schildabwehr. Keine erfundenen Monsterwerte.
- Verbraucht Magieaktion, **keinen** Zauberplatz. Gegner-TP und Würfel werden atomar protokolliert. Neue Engine-/Domänen- und UI-Regressionstests.
- Keine generische Zauberengine-Abnahme: Objektentzündung, automatische Feuerabwehr und komplexe Monsterreaktionen bleiben offen.

---

## 20.10.2026 – Version 0.8.22+72 (SRD-Zauberindex und Vorprüfung, CI ausstehend)

- Bundling und striktes Einlesen von 339 vorläufigen SRD-5.2.1-Zauberdefinitionen mit Metadaten zu Klasse, Zaubergrad, Zeit, Reichweite, Komponenten, Wirkungsdauer, Konzentration und Ritual.
- Neue bestätigungspflichtige, unverändernde Zaubervorprüfung mit Klassenstufe, normalen/Paktplätzen, Komponenten, Zielbedingungen, Ein-Platz-pro-Zug-Bestätigung und Schutz gegen veraltete Pläne.
- Das Buchen einer bestätigten Wirkung ändert lediglich Ressourcen und Konzentrationszustand; keine Behauptung einer generischen automatischen Zauberauflösung. Komplexe Reaktionen, ausgelöste Bonusaktionen und länger dauernde Zauber werden explizit abgewiesen.
- Neue Tests und Dokumentation, Flutter-/Android-CI dieses Branches ausstehend.

---

## 20.10.2026 – SRD-5.2.1-Regelinventur (noch nicht merged)

- 1.419 eindeutig identifizierte Arbeitsanforderungen in zwei maschinenlesbaren, quellenreferenzierten JSON-Registern; davon 282 bestehende Klassen-Freischaltungen. 339 Zaubertitel, 330 Monster-/Tier-Statblocks, 260 Magiegegenstandseinträge und 17 Talente als gezielte zusätzliche Inventare erfasst.
- Python-CLI und Regressionstests für ID-Dubletten, SRD-Level und Inventur-Vollständigkeitsgates hinzugefügt. 9 explizite Prüflücken verhindern eine erfundene globale SRD-Fertigstellungsquote.
- Keine Regelengine-Funktionen oder App-Version geändert. Verifizierung gegen amtliches Gesamt-SRD und GitHub-CI für den neuen Branch noch offen.

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

## 0.8.14+64 – Abenteuer-Status und Auftragsübersicht (19.10.2026)

- Neuer Fantasy-HUD im Abenteuerbildschirm mit 2- bis 4-spaltigem, responsivem Raster für tatsächlich bestätigte Trefferpunkte, Rüstungsklasse, Bewegungsrate und Erfahrungspunkte. Trefferpunkte- und EP-Fortschritt erscheinen nur bei bestätigten Werten.
- Temporäre TP, dokumentierte Zustände, Konzentration und regelgeprüfter Stufenaufstieg werden angezeigt, ohne Spielwerte oder Zustände zu verändern.
- Neue aufklappbare Auftragsübersicht liest ausschließlich die bestätigten `Campaign.quests`, unterscheidet aktiv/abgeschlossen/gescheitert und bietet einen direkten Tagebuchaufruf.
- Der Abenteuerkopf führt Aktionen auf schmalen Displays in einer separaten, umbrechenden Leiste; Import/Export, Charakterbogen, Ausrüstung, Zustände und Heilung bleiben auf ihren bisherigen Controller-Aktionen.
- Tests für kleine und breite Displays, große Schrift, unbekannte Werte, Queststatus und Tagebuchnavigation. Vollständige GitHub-CI-/APK-Abnahme für den finalen Commit gesondert prüfen; ein echter Android-Gerätetest steht noch aus.

## 0.8.13+63 – Illustrierte Heldenübersicht (19.10.2026)

- Neuer Fantasy-Dashboard-Bereich auf der Startseite bei vorhandenen Kampagnen: gespeichertes Charakterporträt, Name, Klasse, Stufe und Kampagnentitel.
- Trefferpunkte mit tatsächlichem Maximum und visualisiertem Zustand, Rüstungsklasse, bestätigte Bewegung einschließlich 0,5 m, EP-Fortschritt und regelgebundener Aufstiegshinweis. Historisch unbekannte Werte bleiben sichtbar unbekannt.
- Direktaktionen „Abenteuer fortsetzen“ und „Helden verwalten“ nutzen die vorhandenen Controller- und Navigationswege ohne zusätzliches Datenbankschema.
- Neue Widgettests mit 320/360/960 dp, echten/fehlenden Werten, Touch-Aktionen und Stufenaufstieg. Android-CI und Geräteprüfung sind getrennt nachzuweisen; der erste erfolgreiche CI-Lauf auf dem finalen Commit entscheidet über die technische Freigabe.

## Unveröffentlicht – Version 0.8.6+56 / ausdrückliche SRD-Startpaketwahl (19.10.2026)

- Barden: konkrete Auswahl eines SRD-Musikinstruments; Mönche: konkrete Auswahl eines SRD-Handwerkszeugs oder -Musikinstruments statt eines untypisierten Platzhalters.
- Auswahl-ID wird gegen die jeweilige Klassenset-Kategorie geprüft und beim Übernehmen als strukturierter Kataloggegenstand mit Preis und Gewicht geschrieben; manipulierte/stale IDs werden abgewiesen, Wechsel der Klasse/Startausrüstung setzt Auswahl zurück.
- Unbekannte, nicht im SRD-Katalog abgedeckte Gegenstände bleiben explizit ohne erfundene Eigenschaften; keine automatische Ausrüstung.
- Regressionstests für alle zwölf Sets und echte Klassenassistenten-Auswahl. Version in `pubspec.yaml` erhöht; Anzeige im Einstellungsbildschirm folgt automatisch.
- Neuer PR wird vor Android-Gerätetest, CI-Abnahme und Review nicht als fertig freigegeben.

## Unveröffentlicht – Versionsanzeige, Porträt-CI und Repositorypflege (19.10.2026)

- **Optionen → App-Version:** Paketversion und Android-Buildnummer aus der gebündelten `app/pubspec.yaml`; kein hartcodierter zweiter Versionsstand. Unit- und Bundle-Test hinzugefügt.
- Porträt-Regressionstests wieder kompilierbar: `HeroCharacter` ist keine const-Klasse; fehlerhafte const-Fixtures korrigiert.
- Nach belegtem Merge-Nachweis und exaktem Branch-HEAD zehn erledigte GitHub-Feature-/Integrationsbranches gelöscht. Main und nicht zusammengeführte Arbeitszweige bleiben.
- Integration in `main` erst nach grüner vollständiger CI dieses separaten Fixes.

## Unveröffentlicht – Fantasy-UI und Charakterporträt (19.10.2026)

- Neun bestätigte Fantasy-Charakterporträts als offline eingebetteter WebP-Atlas, Galerie mit Vorschau, Übernehmen/Abbrechen, Auswählen/Entfernen und eigener Bildwahl via Android-System-Bildwähler.
- Selbsterstellte Bilder werden klein in den Character-JSON-Daten statt in temporären Cachepfaden gespeichert; sichere ID-/Größenprüfung, ältere Savegames unverändert.
- Nächtliche Burgkulisse und echte goldene Icons aus den freigegebenen UI-Grafiken; wiederverwendbare Ornamentrahmen für FantasyPanel.
- Charaktereditor: stets sichtbare Schaltflächen Speichern/Abbrechen; Porträt auf Charakterliste und Charakterbogen.
- Neue Domain- und Widgettests; CI-/Geräteabnahme für diesen Entwicklungszweig noch offen.

## Integration 19.10.2026 – PR #11 und PR #9

- SRD-Klassenaufstieg und Erstellungsprüfung aus PR #11 mit der Startausrüstung/RK/Bewegungs-Korrektur aus PR #9 auf separatem Integrationsbranch zusammengeführt. Integrationstest und Merge nach `main` stehen aus. Die gegenüber PR #11 neue Funktion aus PR #10 – validierte ASI (+2/+1+1) mit rückwirkender KO-TP-Berechnung – wurde in den vorhandenen Klassenaufstiegsdialog übernommen. Der alternative doppelte Dialog wird nicht eingebaut.

**Prüfnachweis (19.10.2026):** RK-/Bewegungs-Fix im vollständigen GitHub-Lauf [39201449428](https://github.com/ManuEtt/Dnd/actions/runs/39201449428) auf `2f7ecb15` erfolgreich; echte Android-Geräteabnahme und Merge noch offen.

## Unveröffentlicht – Start-RK und Spezies-Bewegung (19.10.2026)

- Vorher fehlende `Rüstungsklasse` und `Bewegung` bei der Erstellung werden nach tatsächlich bestätigten Klassen-, Spezies- und Attributwerten vorgeschlagen (10 + GE; bei ungerüstetem Barbar KON und ungerüstetem Mönch WEI).
- SRD-2024-Spezies: 9 m / 30 Fuß üblich, 10,5 m / 35 Fuß für Goliath/Waldelf; optionales Feld `speedRemainderDecimeters` für exakte halbe Meter und alte Spielstände unverändert.
- Automatische Berechnung beim Neuanlegen bzw. Bestätigen der Attribute; ältere Figuren erhalten einen expliziten Button für fehlende Werte. Manuelle Werte und ungeklärte Spezies werden nicht überschrieben/erraten.
- Angelegte Rüstung/Schilde weiterhin nur nach separater ausdrücklicher Bestätigung wirksam. Domain-/Widgettests ergänzt, Android- und CI-Prüfung für diese neue Änderung ausstehend.

## Unveröffentlicht – Ausrüstung im Klassenassistenten/Import (19.10.2026)

- Fehlerursache: SRD-Startsets wurden bisher nur als Name/Menge, ohne `catalogId` und `InventoryItemStats`, übernommen.
- Neue `StartingEquipmentImport`-Zuordnung für eindeutige SRD-Katalogeinträge in allen zwölf Startklassen. Ungeklärte Optionen bleiben ohne erfundene Werte; 20 Pfeile werden als genau eine 20er-Packung gespeichert.
- Vorhandene `catalogId`-Importe ohne `stats` werden rekonstruiert, **eigene Stats werden nie überschrieben**. Bereits gespeicherte freie Altgegenstände können nach explizitem Preview und Bestätigung im Charaktereditor sicher ergänzt werden.
- SRD-Katalogtexte werden, falls vorhanden, als Beschreibung übernommen. Ausrüstung und magische Wirkung werden nicht stillschweigend aktiviert.
- Regressionstests für alle Klassensets, Inventar/Altimport und Editor nachgerüstet. **CI-/APK-Abnahme für diesen Fix ausstehend.** Komplettimplementierung des SRD nicht behauptet.



---

## Unveröffentlicht – Klassenentwicklung und SRD-Erstellungsprüfung (19.10.2026)

- `SrdClassLevelUpRules`: fixer klassenspezifischer TP-Zuwachs, 1-stufiger Aufstieg in eine der vorhandenen Klassen, EP-Schwellenprüfung oder expliziter Meilenstein, Schnappschuss-/Stale-Prüfung und Level-20-Grenze.
- SRD-Klassenmerkmale des nächsten Levels werden nur als Vorschau gezeigt. Nicht automatisierbare Talente/Unterklassen/-fähigkeiten bleiben als offene Wahl notiert statt ungeprüft gewährt; explizite Hauptklassen-Unterklasse auf Stufe 3 aus lizenzierter Auswahl.
- Neuer deutscher Dialog im Charaktereditor, finaler Spielstandswechsel erst nach Charakterbogen-Speichern.
- SRD-Erstellungsprüfung mit fehlenden und technisch noch nicht automatisierten Schritten für alle zwölf Basisklassen.
- Tests der gesamten 12-Klassen-Festwertprogression, Meilensteine, Talente, Zweitklassenaufstieg, Datenänderungen, Grenzen und UI. **CI-/APK-Abnahme ausstehend; vollständige 5.2.1-Abdeckung weiterhin offen.**

## Unveröffentlicht – Prone: regelkonformes Aufstehen (19.10.2026)

- Explizite Aufstehen-Aktion mit Bewegungskosten in Fuß: Hälfte der bestätigten aktuellen Bewegungsrate, abgerundet, keine Aktion/Bonusaktion. 
- Dezimetergenaues Bewegungsrestfeld im bestehenden Begegnungs-JSON (Schema 1, optional; alte Spielstände bleiben lesbar). 30 Fuß: 4,5 m; 25 Fuß: 3,6 m.
- Deutsche Schaltfläche im Abenteuer, revisionsgeschützte Controller-Aktion, atomarer SQLite-Ereignischeckpoint.
- Kein Aufstehen bei fehlendem Budget, Bewegungsrate 0, Bewusstlosigkeit, fremdem Zug oder aktiver verbleibender Zustandsquelle; Editor kann aktive Kampfbewegung nicht umgehen. Normales Laufen im Zustand `liegend` wird geblockt, Kriechen ist noch offen.
- Neue Domain- und SQLite-/Revisions-/Rollbacktests in `prone_standing_rules_test.dart` und `prone_standing_storage_test.dart`. **Vollständige CI-/APK-Abnahme ausstehend**; keine Gerätefreigabe.

## Unveröffentlicht – SRD 5.2.1: Bewusstlos hinterlässt Liegend (19.10.2026)

- Bestätigtes Bewusstloswerden setzt `liegend` als unabhängige, persistierte Folge; bei Erwachen durch Heilung/natürliche Todesrettungs-20 oder Ende einer separaten Quelle bleibt der Zustand erhalten.
- Altdaten werden beim Lesen nicht verändert; neue bestätigte Regelaktionen ergänzen die Folge. Bewusstlos-Quellen behalten weiterhin eigene IDs und Ablaufgrenzen.
- Manuell bestätigte Handlungsunfähigkeit beendet nun auch bei Änderungen im Charakterbogen die Konzentration.
- Neue Regressionstests in `app/test/unconscious_prone_test.dart`. Der Gesamtworkflow für dieses neue Inkrement ist **noch nicht als erfolgreich dokumentiert**; letzte grüne Vorversion: `c000e78b` / Actions `39165288268`.

## Unveröffentlicht – PR #7: Ursachengetrennte Zustände (18.10.2026)

- Optionales Zustandseffekt-Register mit eindeutigen IDs, Quellen und eigenen Zugendpunkten; manuelle/Legacy-Zustände bleiben getrennt. Effektiver Regelzustand dedupliziert die Ursachen ohne sie zu verlieren.
- Quellenpersistenz, Validierung, Schaden/Heilung, Todesrettung und Erschöpfung auf Eigentümertrennung angepasst; Paladin/Mönch beenden nach bestätigter Regel sämtliche Ursachen eines ausgewählten Zustands.
- Zugendgültige Effekte nur in der jeweiligen Begegnung ablaufen lassen; Anzeige der Quellen im Charakterbogen und effektiver Zustände im Abenteuerbereich.
- Neue bestätigte Bedienoberfläche und revisionsgesicherte GameEngine-/GameController-Aktionen zum Anlegen und gezielten Entfernen einzelner Quellen. Neue handlungsunfähige Zustände beenden Konzentration und Kampfrausch/Ausweichen sofort.
- Domänen-, Widget- und echte SQLite-Neustart-/Rollback-/Konflikttests ergänzt. Status: **nicht freigegeben, CI-/APK-Abnahme ausstehend**; allgemeine Weltzeit und Geräteszenarien bleiben offen.

## 0.8.1+51 – Kein fest eingebauter Arescan-Spielstand (18.10.2026)

- Festen Startknopf und Startgeschichte von Arescan entfernt; keine automatische
  Generierung oder eingebettete JSON-Datei mehr im Android-App-Asset-Paket.
- Testdaten nur noch in `app/test/fixtures/arescan_legacy.json`. Tests importieren
  sie manuell, statt einen Produktionscodepfad zu verwenden.
- Historische Nutzerspielstände bleiben über SQLite / JSON-Import erhalten,
  werden aber nicht automatisch gelöscht oder wiederhergestellt.
- Für andere importierte Kampagnen keine festen Mooswacht-Demo-Ereignisse mehr;
  regelunklare Kämpfe blockieren ohne erfundene Werte.
- Regressionstests für Startbildschirm und importierte Alt-Daten ergänzt.

## 0.7.9+49 – Todesrettungen mit Klassenentscheidung (18.10.2026)

- Todesrettungen verwenden jetzt Mönch-14-Rettungswurfübung und den Erschöpfungsmalus genau einmal. Natürliche 1/20 behalten ihre Sonderfolgen; Kämpfer-9-Unbeugsam addiert beim Ersatzwurf die tatsächliche Kämpferstufe.
- Ein fehlgeschlagener Wurf mit verfügbarer Wiederholung bleibt vorläufig: deutsche Auswahl zum Annehmen oder Wiederholen, mit Neustart erhaltener Entscheidung. Auch ein drohender dritter Fehlschlag lässt sich ersetzen. Verbrauch und Folgen werden erst gemeinsam bestätigt.
- Im aktiven Solokampf nur eine Todesrettung pro eigenem Zug; anschließend bewusstlos den Zug beenden oder nach natürlicher 20 normal fortsetzen. Gegnerzug, offene Entscheidung, veraltete Oberfläche und manipulierte Importe sind gesperrt.
- Kampfrausch und Ausweichen enden auch bei extern bestätigtem KO und beim Bestätigen handlungsunfähiger Charakterzustände sofort; spätere Heilung reaktiviert keinen alten Kampfrausch.
- 57 neue gezielte Fälle sowie 10 bestehende Erschöpfungsregressionen erfolgreich: 19 Todesrettungs-Domänenfälle, 18 Ablauf-/UI-/SQLite-Fälle und 20 Zuggrenzenfälle. Gesamtprüfung erfolgreich: 692 Flutter-, 31 Backend-, 56 Python- und 12 native Tests; Analyse/Format sauber und korrigierte Debug-APK aus geprüftem ZIP gebaut. Nachweise in CHECKPOINT.md. Quelle und genaue Grenzen: docs/DEATH_SAVES_0_7_9.md.

## 0.7.8+48 – Korrekte eigene Zuggrenzen (17.10.2026)

- Reines Zugende trotz Handlungsunfähigkeit, auch für stabile bewusstlose Figuren; eigener UI-Button und atomare SQLite-Speicherung. Keine Ausweichaktion durch Textbeimischung.
- Kampfrausch endet vor dem folgenden Gegnerangriff, wenn sein Endzeitpunkt erreicht ist, sowie endgültig bei Handlungsunfähigkeit. Ausweichen verliert Wirkung bei Handlungsunfähigkeit, Sichtverlust oder Bewegungsrate0; positive halbe Meter bleiben positiv.
- Mönchs-Selbstwiederherstellung kann ohne Aktion vor dem eigenen Zugende ausgewählt werden. Feindlicher Initiative-Erstzug löst kein eigenes Zugende aus.
- 17 neue Grenz-/UI-Tests erfolgreich; aktuelle Analyse ohne Befunde. Generische Zustandsdauer bleibt ausdrücklich Entwurf, siehe docs/CONDITION_EFFECT_DESIGN.md.

## 0.7.7+47 – Ausführbare Heilzauber im Spiel (17.10.2026)

- Wunden heilen und Heilendes Wort wirken auf den eigenen Charakter: 2024-Würfel (2W8/2W4 pro tatsächlichem Platzgrad), eigenes Klassenattribut, Hochstufung, normale/Pakt-Plätze und Lebensdomänenboni (Kleriker 3/17).
- Deutsche Auswahl mit Klassen-/Platz-/Komponentenbestätigung direkt im Abenteuer/Kampf. Ereignis, TP, Platz und Aktion werden atomar bestätigt; keine automatischen Regeln aus Erzähltext.
- Persistenter Zugschutz: nur ein Platzverbrauch für Zauberwirken je Zug, gemeinsam für normale und Paktplätze; reset erst beim nächsten eigenen Zug. Alte Begegnungen bleiben lesbar. Action Surge erlaubt keine zusätzliche Magieaktion.
- 26 Domain-, 13 Dialog- und 9 Integrationsfälle geprüft. Vollständige Formatbereinigung und verpflichtende Formatprüfung im normalen Test-/Buildworkflow, keine autonome Codex-Action.
- Abschluss: 635 Flutter-, 31 Backend-, 56 Python- und 12 native Androidtests bestanden; saubere Analyse/Formatierung und Debug-APK aus dem Quell-ZIP gebaut und geprüft. Umfang/Grenzen: docs/CHARACTER_EFFECTS_AND_HEALING.md.

## 0.7.6+46 – Ausführbare Charaktereffekte (17.10.2026)

- Gemeinsamer Schaden-/Konzentrationsablauf für bestätigte externe Quellen und Gegnerangriffe: Abwehr vor temporären/echten TP; auch absorbierter Schaden löst Konzentration aus.
- Deutsche Oberfläche für Schaden, Heilung und temporäre TP mit Quelle und bestätigten Abwehrregeln. Atomare Speicherung und Revisionsschutz für offene Dialoge.
- Versteinert-Schadensresistenz und automatische Stärke-/Geschicklichkeitsfehlschläge bei gelähmt/versteinert/betäubt/bewusstlos; betäubt sperrt Bewegung nach 2024 nicht generell.
- 50 gezielte Domain-/Kampfregressionen, 6 Dialogtests und 7 echte UI-/SQLite-Tests erfolgreich; Flutter-Analyse ohne Befunde. Details im Checkpoint.

## 0.7.5+45 – Prüfbare Speicher- und Backendkorrekturen (17.10.2026)

- Erschöpfte Angriffs-, Wahrnehmungs- und Fluchtproben bleiben beim JSON-/SQLite-Neustart gültig; manipulierte Boni werden weiterhin abgewiesen.
- Schaden bei 0 TP beendet Stabilität und verursacht Todesrettungsfehlschläge auch bei vollständiger Absorption durch temporäre TP; kritische Treffer und sofortiger Tod werden getrennt geprüft.
- Gültige leere Tagebuchbeschreibungen verursachen im Backend-Mock keinen HTTP 502 mehr. OpenAI-POSTs weisen Redirects ab.
- Reproduzierbares Checkpointwerkzeug mit vollständigem ZIP, Binärpatch, Dateimanifest, Prüfsummen und tatsächlicher Wiederherstellungsprüfung; lokale Regelabdeckungsmatrix ergänzt.
- Gezielte Flutter-Regressionsprüfung: 30 bestanden; vollständiger lokaler Lauf: 544 bestanden, 1 optionaler Protokolltest übersprungen. Backend mit Node 22.14.0: 31 bestanden. Details im Checkpoint.

## 0.7.4+44 – Klassenaktionen, Rettungswürfe und Ressourcen (16.10.2026)

- Paladin-Handauflegen als ausführbare Heil-/Entgiftungs-Bonusaktion, eigener Heilpunktevorrat, UI-Schaltflächen, Rastregeneration und Ereignisjournal.
- Mönch 15: Perfekter Fokus beim Initiativewurf, für Demo- und KI-Begegnungen mit überprüfbaren Freischalt-/Regenerationsbedingungen.
- Manuelle, explizit angeforderte Rettungswürfe samt optionalem Mönch-14-/Kämpfer-9-Wiederholungswurf; Ressource `indomitable` nach Kämpfer-Klassenstufe und verbindlichem Zweitergebnis.
- Charakterbogen zeigt Handauflegen und Unbeugsam. Legacy-Speicherschema unverändert; neue Dart-Domain-/Integrationsfälle hinzugefügt.
- Python-Tests und Integritätsprüfungen ausgeführt; Flutter- und APK-Verifikation steht noch aus. Keine Behauptung vollständiger 1.247-SRD-Anforderungen.

## 0.7.3+43 – Mönch-Selbstwiederherstellung und disziplinierter Überlebender (16.10.2026)

- Selbstwiederherstellung ab Mönchsstufe 10 zur gezielten Entfernung eines von drei Zuständen am Ende des eigenen Zugs, mit Entscheidung bei mehreren Zuständen, UI-Auswahl, Kampfjournaleintrag und rückwärtskompatiblem Encounter-JSON.
- Alle sechs Rettungswurfübungen ab Mönchsstufe 14 berechnet, ohne Proficiency zu verdoppeln oder vorhandene Charakterbögen umzuschreiben.
- GitHub-Actions-Compilerfehler `monk_flurry_rules.dart` (`int?` statt `int`, Commit 91ffddd) gezielt korrigiert; Regressionen für nur ein bestätigtes Angriffsattribut ergänzt.
- Flutter-/Android-Test noch ausstehend. Dokumentation `docs/MONK_SELF_RESTORATION_0_7_3.md`.

## 0.7.2+42 – Temporäre TP und Mönch: erhöhter Fokus (16.10.2026)

- Verstärkte Geduldige Verteidigung ab Mönchsstufe 10: zwei Kampfkunstwürfel temporäre TP für einen Fokuspunkt; Kampfrunden- und Ereignisintegration.
- Eigenes rückwärtskompatibles Speicherfeld für temporäre Trefferpunkte, Schadenspuffer vor echten TP, Heil- und Rastregeln sowie Anzeige in der UI.
- CI-Lint für `monk_flurry_rules.dart` korrigiert. Neue Dart-Domain- und Widget-Regressionsprüfungen hinzugefügt.
- Siehe `docs/TEMP_HP_MONK_HEIGHTENED_FOCUS_0_7_2.md`; Flutter-/APK-Prüfung noch offen.

## 0.7.1+41 – Mönch: Schlaghagel und letzte CI-Regressionen (16.10.2026)

- Ausführbarer Schlaghagel für Mönchsstufe 2+ (2 Unarmed Strikes) und 10+ (3 Unarmed Strikes), Fokusverbrauch und Aktionsturn-Reihenfolge; Treffer/Krits und Schadenswürfe einzeln protokolliert.
- Bonusaktion vor oder nach der normalen Attack action; Quest-/Kampfsieg auch über Schlaghagel, Mehrklassen-Klassenstufe und Persistenz unverändert im Schema 1.
- Behebung der in GitHub Actions `38857593290` bestätigten Regressionen: Widget-Test `6.0 m` versus `6 m`, blockierte Zweitaktion bei Eingabe „Ich weiche aus.“.
- Neue Dart-Tests und Dokumentation. Python-Strukturprüfungen separat. Keine ungeprüfte Behauptung eines erfolgreichen Flutter-/APK-Builds. Details: `docs/MONK_FLURRY_0_7_1.md`.

## 0.7.0+40 – Mönchsfokus: defensive Bonusaktionen (2026-10-16)

Geduldige Verteidigung und Schritt des Windes mit kostenlosen und fokussierten Varianten. Persistente, am Zugende automatisch zurückgesetzte Dodge-/Disengage-/Sprungstatus; Rogue Cunning Action Disengage. Separate Domain- und Kampf-Regressionstests. Kein Gelegenheitsangriffs-/Sprunggeometriesystem; keine Flurry-Ausführung. Flutter-/Android-Build noch nicht ausgeführt. Siehe docs/MONK_FOCUS_0_7_0.md.

## 0.6.9+39 — Ausführbare Kampf-Klassenaktionen (2026-10-16)

Kampfrausch-Runden und gesonderter Ressourcenverbrauch, bestätigter Stärke-Nahkampfbonus, optional bestätigte körperliche Schadensresistenz, Flinke Aktion: Sprinten und Hinterhältiger Angriff auf Treffern mit bestätigtem Vorteil. Neue Regressionstests, Speicherkompatibilität und Dokumentation. Flutter/Android nicht lokal getestet.

## 0.6.7+37 – Fighter resource engine (16.10.2026)

- Second Wind: resource pool by Fighter class level; 1d10 + class level as Bonus Action, rest recovery, save-state validation.
- Action Surge: resource pool, once-per-turn reservation of an additional Attack action in the simplified combat system; restored on Short/Long Rest.
- Character sheet now shows remaining Fighter resources. Old schema 1 saves remain readable.
- Flutter analyze CI fix for `damage_rules.dart` dangling library doc comment.
- Added Dart regression tests; **Flutter/Android execution pending**. See `docs/CLASS_RESOURCES_0_6_7.md`.

## 0.6.6+36 – Klassenmeilensteine & Mehrfachangriffe (16.10.2026)

- SRD-5.2.1-Klassenstufen: Vorschau der Unterklassen-, Talent- und Kämpfer-Meilensteine; keine automatischen freien Klassenmerkmale behauptet.
- Mehrfachangriffe je Angriffsaktion: fünf Grundklassen ab Klassenstufe 5, Kämpfer ab 11 drei, ab 20 vier; Mehrklassen-Merkmale nicht kumulativ.
- Demo- und KI-Kampfsystem: einzelne Attacken nacheinander mit eigenem W20, kritischem Treffer und Schaden; Gegnerzug erst nach Abschluss oder freiwilligem Zugende.
- Laufende Angriffsaktion rückwärtskompatibel speichern; Anzahl möglicher Angriffe und nächste Meilensteine im Charakterbogen anzeigen.
- Tests ergänzt, Flutter-CI/APK nicht vor Ort ausgeführt. Details: `docs/CLASS_PROGRESSION_0_6_6.md`.

## 0.6.5+35 – Regelengine: Schadensarten + bekannte CI-Blockade (16.10.2026)

- Bewegungsanzeige im Charakterbogen korrekt formatiert, einschließlich halber Meter; Regressionstests ergänzt.
- Konzentrations-SG auf SRD-Maximum 30 begrenzt; zusätzliche Grenzwerttests.
- Neues Modul für typisierten Schaden, Resistenz/Anfälligkeit/Immunität und mehrere Schadenskomponenten; eigene Domänentests, bewusster Einstieg in die zentrale TP-Regelengine.
- **Nicht als fertig freigegeben:** automatische Integration in alle Kämpfe, Charakter-/Monsterdefensiven, Dart-Tests und APK-Build ausstehend. GitHub-`main` unverändert; Import separat erforderlich.

## 0.6.4+34 – Zauberplätze, Paktmagie und Konzentration (15.10.2026)

- Persistente und stufenvalidierte Zauberplatzverbräuche, separate Hexenmeister-Paktmagie und aktiver Konzentrationszauber im weiterhin kompatiblen Schema 1.
- Charaktereditor-Dialog mit bestätigter Zauber-/Gradwahl, Charakterbogen zeigt verbleibende Plätze; keine unbestätigte Zauberwirkung.
- Kurze Rast erneuert Paktmagie, lange Rast alle Plätze; Kampfschaden löst dokumentierte Konzentrationsrettungswürfe aus. 0 TP/Tod beendet Konzentration.
- Tests ergänzt, Flutter-/Android-CI ausstehend; lokale Python-/Strukturprüfungen werden separat aufgeführt. Grenzen und SRD-Quellen: `docs/SPELLCASTING_RESOURCES.md`.

## 0.6.3+33 – gemeinsame Regelengine für Spiel und Oberfläche (15.10.2026)

- `CharacterRuleEngine` als rein lesende Quelle für Kampf-, Proben-, Rettungswurf- und Bewegungsmodifikatoren einschließlich Erschöpfung, Zustand und bestätigter Ausrüstung.
- Kampf, Initiative, Wahrnehmung, Flucht und Gegenangriffe mit dokumentierten Vorteils-/Nachteilquellen verbunden. PendingRoll speichert Vorteil/Nachteil optional, ältere Spielstände bleiben lesbar.
- Charakterbogen zeigt effektive Initiative, effektive Bewegung, erschöpfungsbereinigte Rettungswürfe und Zustandserklärungen; Ausrüstungsvorschau erläutert vorübergehende Angriffsabzüge.
- Achtung: Nicht alle situativen SRD-Effekte werden ohne zusätzliche bestätigte Eingabedaten erraten. Datenbank und Backend-Verträge unverändert.
- Neue Domain- und Widgettests ergänzt; 38 Python-Tests und Projektstruktur lokal erfolgreich. Flutter-/Android-CI für diese Version **noch ausstehend**. Details: `docs/UNIFIED_RULE_ENGINE.md`.

## 0.6.2+32 – Zustände und Erschöpfung (15.10.2026)

- Persistente, validierte Erschöpfungsstufen 0–6 nach SRD 5.2.1: −2/Stufe auf W20-Tests, −1,5 m/Stufe, Tod bei Stufe 6 und Wiederherstellung um eine Stufe nach langer Rast.
- Charaktereditor mit Anzeige der Erschöpfung und der rechnerischen Auswirkungen; alte Spielstände bleiben kompatibel.
- Initiative, Waffenangriff, Wahrnehmung und Todesrettungen nutzen den bestätigten W20-Abzug; Kampftempo und elementare Zustandsverbote werden berücksichtigt.
- `ConditionRules` enthält 14 SRD-Zustandsüberblicke; kontextabhängige Effekte bleiben ausdrücklich offen.
- Neue Domänentests; Flutter-/Android-CI für diesen Stand noch ausstehend. Siehe `docs/CONDITIONS_EXHAUSTION.md`.

## 0.6.1+31 – Flutter-Analyzer und Rast-Testfixtures (15.10.2026)

- **BEHOBEN:** `srd_equipment_catalog.dart` verwendet für das Gewicht eine einfache Stringinterpolation (`$weightLb`), wodurch der in CI reproduzierte Analyzer-Lint `unnecessary_brace_in_string_interps` entfällt. Keine Änderung der Ausrüstungswerte.
- **BEHOBEN:** Die `HeroCharacter.fromJson`-Fixture in `app/test/rest_rules_test.dart` enthält wieder die erforderliche `species`-Angabe `Mensch`. Sieben vorangegangene Testfehler waren `FormatException: Spezies ist ungültig.` beim Aufbau der Fixture, nicht Regel-Aussagen. Der produktive Importvalidator bleibt unverändert.
- **BASIS:** `main` `0963303fe4802aae9c42739b267e6d33057ef63d`, GitHub Actions #38746011222 (Analyzer-Fehler); früherer Rast-Testlauf #38734808085. Die geänderten Ausgangsdateien wurden gegen ihre Git-Blob-SHAs geprüft.
- **PRÜFUNG:** Projektstruktur, Python-Tests, ZIP/SHA256 sowie saubere Anwendung des Git-Patches auf `0.6.0+30`. Flutter SDK ist in dieser Umgebung nicht vorhanden: `flutter analyze`, `flutter test` und Android-APK-Build sind für 0.6.1+31 **noch nicht nachgewiesen**.
- **NÄCHSTES:** Auf separatem Branch übernehmen, kompletten GitHub-CI-Lauf ausführen; bei neuen Testproblemen Logs analysieren und beheben; bei grünem Lauf APK verwenden. Codex-Actions nicht reaktivieren.

## 0.6.0+30 – SRD-Waffen und -Rüstungen anlegen (15.10.2026)

- Reine Vorschau plus bestätigte Übernahme von Katalog-Waffen/Rüstungen/Schilden in Kampfwerte. Waffenattribute, Würfel, Übung, RK-Berechnung, STR-Grenzen, Finesse, Wurf-/Zweihand-/schwere Waffen mit Regeln und Warnungen.
- Optionale Instanzreferenzen/Übungsbestätigungen für Savegames; alte Schema-1-Daten bleiben ohne Änderung lesbar. Ungültige Referenzen blockieren Importe; keine Magie-/Gold-/Munitionsbuchung.
- Regeltests und Widgettest für Dialog ergänzt. Flutter-/Android-CI und Geräteabnahme für diesen Stand noch offen, siehe docs/EQUIPMENT_RULES.md.
- Eigener Entwicklungsstand aus vollständigem ZIP 0.5.9+29. Keine Übernahme auf Codex-Branch oder GitHub behauptet; GitHub-Schreibberechtigung noch nicht bestätigt.

## 0.5.9+29 – SRD 5.2.1: Waffen-, Rüstungs- und Gegenstandskatalog (15.10.2026)

- **Ausrüstung:** 38/38 Standardwaffen, 13/13 Rüstungen/Schilde sowie Werkzeuge, Abenteuerausrüstung, Munition, Foki, Reittiere, Fahrzeuge und eine ausdrücklich unvollständige Magie-Gegenstandsauswahl: insgesamt **272 Einträge**.
- **SRD-Werte:** Waffen mit Schaden, Typ, Eigenschaften, Meisterschaft, Reichweite, Kosten und Gewicht; Rüstung mit Basis-RK, GE-Beschränkung, ST-Mindestwert und Heimlichkeitsnachteil. Reine, explizite RK-Vorschau ohne ungeprüfte Boni.
- **Charaktereditor:** Such-/Kategoriedialog auf Deutsch und Englisch, bewusstes Hinzufügen aus dem Katalog; bestehender Freitext-Inventardialog bleibt erhalten. Optionale `catalogId` ohne Änderung der bisherigen gespeicherten Pflichtfelder; ältere Daten bleiben kompatibel.
- **Sicherheit:** Kein automatischer Goldabzug, kein automatisches Anlegen oder Überschreiben von AC/Waffenwerten; magische Effekte, Ladungen und Einstimmung sind noch nicht automatisiert. Lizenz/Quellen: `docs/SRD_AUSRUESTUNGSKATALOG.md` und `THIRD_PARTY_NOTICES.md`.
- **Tests:** Dart-Domain-, Widget- und Editor-Tests angelegt (Flutter CI ausstehend); 38 lokale Python-Tests und Strukturprüfung bestanden. Ausgangsbasis 0.5.8+28; deren GitHub-CI hatte sieben fehlschlagende Rast-Tests. Neue Änderungen auf GitHub noch nicht übertragen.

## 0.5.8+28 – SRD-5.2.1-Rasten und Trefferwürfel (15.10.2026)

- Eigenständiges `RestRules`-Modul implementiert kurze Rast mit klassenspezifischen Trefferwürfeln, Konstitutionsbonus, Mindestheilung und TP-Limit; keine unbegrenzte Pauschalheilung mehr.
- Lange Rast stellt TP und ausgegebene Trefferwürfel wieder her. Rasten bei 0 TP, Tod, aktiver Begegnung und offener Würfelprobe blockiert; unklare Rastbefehle erfordern explizite Wahl.
- Optionale `spentHitDice`-Karte in bestehenden JSON-Spielständen (Schema 1) und SQLite-Snapshots; keine Datenmigration, vorhandene Speicherstände laden ohne Würfelverlust.
- Neue Journalereignisse `character.shortRest` / `character.longRest` sowie Trefferwürfelanzeige im Charakterbogen. Dart-Tests für Mehrklassen, Speicherung, Sicherheitsgrenzen und Spielaktionen hinzugefügt.
- **Status:** Projektstruktur und Python-Tests lokal geprüft. Flutter/Dart-Analyse, Widgettests, Android-APK und Gerätetest für diesen Stand nicht durchgeführt. Nur Android-Actions-Workflow, keine Codex-Action.
- **Referenz:** `docs/REST_RULES.md`, SRD 5.2.1 unter CC BY 4.0.

## 0.5.7+27 – Inventar-Widgettest robuster gemacht (15.10.2026)

- **CI-Ursache (Lauf #38729844876, Commit `42b9ad37`):** 351 Flutter-Tests erfolgreich, ein Inventar-Widgettest fehlgeschlagen (`StateError: Bad state: No element`). Flutter-Analyse und Backend-Prüfungen waren erfolgreich.
- **Korrektur:** Die Aktion „Gegenstand hinzufügen“ besitzt einen stabilen `ValueKey`. Der Test scrollt die tatsächliche Charaktereditor-`ListView` mit kleinen Schritten bis die Schaltfläche wirklich antippbar ist. Er verschluckt keine Fehler und deaktiviert keine Tests.
- **Status:** Quellcode korrigiert, Projektstruktur und Python-Tests lokal geprüft. Flutter-Testlauf und Android-APK auf GitHub noch **nicht** bestätigt. Datenmodell und Spielstandschema unverändert.
- **GitHub:** Änderungen nur lokal gesichert; bei verweigerten Schreibrechten kein Commit auf `main`.

## 0.5.6+26 – CI-Fixes: Schnellaktionen und Inventar (15.10.2026)

- **Schnellaktionen:** Beim Öffnen der Android-Tastatur erkennt der feste Dock über `View.of(context).viewInsets` den tatsächlichen IME-Bereich auch hinter einem verschachtelten `Scaffold`. Die Überschrift wird ausgeblendet, die vier Aktionen bleiben erhalten.
- **Große Schrift:** Die Docküberschrift verwendet ein flexibles, auf eine Zeile begrenztes Textfeld; die Höhe der vier Buttons skaliert ausreichend mit bis zu zwei Zeilen großer Schrift. Behebt die CI-Overflows bei 320dp/180%.
- **Charaktereditor:** Der Inventartest scrollt den tatsächlichen `OutlinedButton` vollständig ins sichtbare Fenster und prüft vor dem Antippen die Trefferfläche. Keine Funktion oder Inventarlogik geändert.
- **Regression:** Der Tastaturtest prüft nun alle vier betätigbaren Schnellaktionen.
- **Eingangslage:** CI #38728029583 für 0.5.5+25: 349 Flutter-Tests grün, 3 rot; Flutter-Analyse, Backend und Python erfolgreich. **Neuer Flutter-CI-Lauf für 0.5.6 steht aus**, eine APK-Freigabe wird nicht behauptet.
- **Workflow:** Nur `.github/workflows/android-build.yml`; kein Codex in Actions. Datenbankschema 1 und historische Spielstände unverändert.

## 0.5.5+25 – feste Schnellaktionen am unteren Bildschirmrand (15.10.2026)

- Die Abenteuer-Schnellaktionen sind nun im `Scaffold.bottomNavigationBar` der Abenteueransicht verankert, nicht im scrollbaren Inhalt oder im Composer. Sie stehen unter dem Texteingabefeld und direkt über der allgemeinen App-Navigation.
- Die doppelten Sprach- und Würfel-Schaltflächen aus dem Composer entfernt. **Sprache/Stopp**, **Untersuchen**, **Angriff** und **W20** bleiben unten einheitlich erreichbar; **Rückblick** bleibt separat neben dem Eingabebereich.
- Bei offener Android-Tastatur bleibt die Leiste angedockt; die vorhandene Tastaturkompaktansicht bleibt erhalten. Funktionalität und gespeicherte Spielstände unverändert.
- Flutter-Widgettests auf die neuen Schnellaktions-Selektoren umgestellt und Integrationstest erweitert. Python- und Projektstrukturprüfungen werden getrennt protokolliert; Flutter-CI-Abnahme für 0.5.5 noch erforderlich.
- Keine Codex-Entwicklung in GitHub Actions; regulärer Android-/Release-Workflow bleibt vorhanden.

## Prüf- und Analysekorrekturen 0.5.4+24 – 15.10.2026 (nicht Flutter-CI-validiert)

- Automatischer Codex-Workflow bleibt aus dem vollständigen Import-ZIP ausgeschlossen; normaler Android-Workflow erhalten.
- Flutter-Analysefehler im Test der fixierten Schnellaktionen (`const NavigationBar`) korrigiert.
- Zwei Dart-Lint-Hinweise zu fehlenden Blockklammern in Charaktereditor und Zweitklassen-Dialog korrigiert.
- Projektprüfung und 35 Python-Tests erfolgreich; Flutter/Android-Build bleibt ausstehend.
- Live-GitHub enthält die alte Codex-Datei weiterhin; dortige Löschung noch erforderlich.

## 0.5.4+24 – GitHub Actions ohne automatische Codex-Entwicklung (15.10.2026)

- `.github/workflows/autonomous-development.yml` aus dem vollständigen Projekt entfernt. Es gibt im neuen Archiv keinen Zeitplan, keinen `openai/codex-action`-Aufruf und keinen automatischen Codex-PR-Job mehr.
- `.github/workflows/android-build.yml` und die regulären Flutter-, Backend-, Python-, Android- und Release-/Checkpoint-Jobs unverändert erhalten. Manuelle Codex-Verwendung außerhalb von GitHub Actions bleibt möglich.
- Import- und Fortsetzungsdokumentation aktualisiert; ein neuer Python-Regressionstest verhindert, dass versehentlich wieder ein Codex-Workflow in `.github/workflows` landet.
- **Keine App-Änderung und keine neue APK-Abnahme.** Die Versionsnummer `0.5.4+24` bleibt unverändert. GitHub-Commit nicht ausgeführt: Contents-API gibt HTTP 403 zurück. Bestehende Workflow-Datei auf GitHub muss gesondert mit `git rm` entfernt werden.

## 0.5.4+24 – Mehrklassen-Aufstieg absichern und versionierte Alpha-Auslieferung vorbereiten (15.10.2026)

- **Mehrklassen:** Vor dem Übernehmen einer Zweitklassen-Stufe wird jetzt überprüft, ob der Vorschlag noch zum selben Helden und zu denselben bestätigten Attributen, Fertigkeiten, maximalen Trefferpunkten und Klassenstufen gehört. Nachträglich ungültige Vorschläge werden ohne stillen Charakterfehler zurückgewiesen. Erlittener Schaden zwischen Vorschlag und Bestätigung bleibt erhalten und wird korrekt zum TP-Zuwachs berücksichtigt.
- **Defensive Validierung:** Direkte inkonsistente Primär-/Sekundärklassenstufen werden abgewiesen. Fünf Dart-Regressionstests ergänzen die bestehenden Mehrklassen-Tests.
- **Release-Automatisierung:** Neues `scripts/prepare_alpha_release.py` erzeugt nach **vollständig erfolgreichem CI-Lauf** ein versioniertes vollständiges Quellarchiv, die zuvor gebaute ARM64-APK, Release-Notizen und SHA-256-Prüfsummen. ARM64-Bibliotheken und APK-ZIP-Integrität werden vor Freigabe geprüft; die bestehende interne Debug-Testsignierung ist eindeutig gekennzeichnet.
- **Tests:** Sieben neue Python-Fälle decken die sichere Auslieferung ab. GitHub-Actions-Workflow nutzt das Skript und lädt die versionierten Dateien als gemeinsames Release-Artefakt hoch. Fehlerhafte Builds behalten die bisherige gesonderte **nicht freigegebene** Quell-Checkpoint-Veröffentlichung.
- **Abnahme:** Lokale Python- und Projektstrukturtests bestanden; Flutter-/Dart-Tests und Android-Build sind ohne SDK lokal **nicht ausgeführt**. Backend-`npm ci --offline` war wegen fehlendem Cache für `undici-types` nicht ausführbar. GitHub-`main` wurde nicht verändert. Dieser Entwicklungsstand bleibt ein *unverifizierter Quellcode-Checkpoint*, bis CI vollständig erfolgreich ist.

## Ergänzung zur Quellcodeübergabe 0.5.3+23 – 15.10.2026

- Vollständigen Quellstand mit bereits vorhandenen fixierten Schnellaktionen (0.5.3+23) übernommen; keine Spielstands-/Schemaänderung.
- Python-Regressionstest gegen ungültige `pubspec.yaml`-Beschreibung ergänzt.
- GitHub-Actions-Quellencheckpoint und einen getrennten, zunächst deaktivierten Codex-Workflow vorbereitet.
- `docs/AUTONOMOUS_DEVELOPMENT_STATE.md` und Importanleitung ergänzt. Neue APK/Flutter-CI-Abnahme noch ausstehend.

## 0.5.3+23 – Fixierte Schnellaktionen im Abenteuer (15.10.2026)

- **Navigation:** Die vier Schnellaktionen **Sprache, Untersuchen, Angriff und W20** wurden aus der scrollbaren Abenteuerszene in eine stets am unteren Rand sichtbare Aktionsleiste direkt **über der Hauptnavigation** verschoben. Sie sind auch in der Kampfübersicht erreichbar.
- **Responsive Darstellung:** Kompakte Fantasy-Kacheln passen nebeneinander auf 320/360/400 dp; bei eingeblendeter Tastatur entfällt nur die Leistenüberschrift. Doppelte Buttons im Eingabebereich werden bei geöffneter Tastatur ausgeblendet, um Platz zu schaffen.
- **Bestehende Funktionalität:** Die Schnellaktionen verwenden dieselben Methoden zur Mikrofonsteuerung, Untersuchung, Angriffseingabe und Würfelfunktion. Keine Änderungen an D&D-Regeln, KI, SQLite oder Spielstandformat.
- **Buildblocker korrigiert:** `app/pubspec.yaml` hatte seit der Umbenennung eine nicht maskierte zweite Doppelpunkt-Sequenz in `description`. Die Beschreibung ist jetzt gültig in Anführungszeichen gesetzt, damit `flutter pub get` nicht mehr bei der YAML-Analyse scheitert. Ursprünglicher Fehler: GitHub Actions Commit `bb5383b7a52b5052a5c2e8ce4714fe16b0e600da`.
- **Tests:** Neue Widgettests für fixierte Position bei Scrollbewegungen, Bedienbarkeit, schmale Bildschirme und geöffnetes Keyboard; Integrationstest mit echter Kampagnenseite. 22 Python-Tests und Strukturprüfung bestanden, YAML erfolgreich geparst. Flutter-Tests und APK-Build stehen auf GitHub Actions noch aus.

## 0.5.2+22 – Neuer Name und SRD-Zweitklassen-Assistent (15.10.2026)

- Neuer Produktname **Würfelraunen – Der lebendige Spielleiter** in Startseite, Android-Launcher, App-Titel, Sprecherprobe, Lizenzansicht und KI-Prompt; technische App-ID bleibt zur Update-Kompatibilität unverändert.
- Automatisierte Zweitklasse beim Stufenaufstieg (maximal zwei Klassen, Gesamtstufe bis 20): Primärattribut-Voraussetzungen beider Klassen, feste zusätzliche TP nach Trefferwürfel und Konstitution, gezielte neue Klassenfertigkeit bei Barde/Schurke/Waldläufer.
- Optionale Mehrklassenfelder in den bestehenden `schemaVersion:1`-Heldendaten; vorhandene Speicherstände und Importe bleiben lesbar, keine SQLite-Migration.
- Kein fälschliches Gewähren von Startausrüstung, neuem Start-TP-Maximum oder Rettungswurf-Übungen. Anzeige im Charakterbogen, Heldenliste und KI-Kontext; Regel-/Widgettests ergänzt.
- Grenzen: Klassenspezialfähigkeiten, Rüstung-/Waffen- und Werkzeugübungen sowie Zauberressourcen sind nicht vollständig automatisiert; ermittelte Zauberplätze dienen vorerst der Vorschau.
- Neues Quellpaket erstellt, Flutter/Android-CI für diese Version noch nicht ausgeführt.

## 0.5.1+21 – Flutter-CI-Abnahme des illustrierten Designs (15.10.2026)

- **CI-Ursache:** Letzter GitHub-Actions-Lauf für `0.5.0+20` (`a3a05d3888a9c0e19d3e43d2469cc849f5e1a4eb`) scheiterte trotz 328 bestandener Flutter-Tests an zwei veralteten Widgettest-Interaktionen.
- **Charakterbogen:** Der Test für unbekannte Angaben scrollt zur verzögert aufgebauten Tab-Navigation, bevor er die Tabs antippt. `ensureVisible` allein konnte den zunächst noch nicht aufgebauten Tab nicht finden.
- **Startseite:** Der 360-dp-Navigationstest scrollt zum echten Demo-Button unter dem illustrierten Header, überprüft die Antippbarkeit und startet dann die Demo. Keine Hit-Test-Warnungen unterdrückt und keine Tests deaktiviert.
- **Umfang:** Nur Widgettests, Versionsnummer und Dokumentation geändert. Alle zwölf neuen Illustrationen, UI-Widgets, Spiellogik, Backend und gespeicherte Daten bleiben unverändert.
- **Status:** Lokale Python-/Paketprüfungen durchgeführt; Flutter-Analyse, Flutter-Tests und APK-Build müssen die neue Version in GitHub Actions bestätigen. Ohne grünen Build noch keine Freigabe.

## 0.5.0+20 – Illustriertes Aetheria-Design (15.10.2026)

- Echte, kompakte App-Grafiken aus den zuvor entworfenen Aetheria-Illustrationen als lokale WebP-Assets (`app/assets/art/`, 12 Motive). Keine eingebetteten Bildschirm-Screenshots als UI.
- Neues `FantasyIllustratedBanner` mit realen Kampagnendaten und Fortsetzen-Aktion; gerahmte Kampagnenkarten mit regionalen Motiven; horizontale Schnellzugriffe zu bestehenden Funktionen.
- Abenteueransicht mit atmosphärischer Szene, weiterhin gespeicherter Szenentext und bestehende Spielaktionen. Zusätzliche Aktionskacheln verwenden die realen Spiel-/Sprach-/Würfelmethoden.
- Heldenarchiv mit individuellen Initialenmedaillons (kein erfundenes Porträt); Charakterbogen mit Burgenillustration, dekorativen Rahmen.
- Inventar mit einzelnen bebilderten Gegenständen auf Basis von `hero.inventory`: Anzahl und Name aus gespeicherten Daten, Detaildialog nur informativ, keine vorgetäuschte Anlegen-/Ablegen-Funktion.
- Chronik-Banner und einheitlicher Fantasy-Startbildschirm.
- Neues Testmodul zu Bild-Assets, Darstellung bei 320/360/400/950 dp und echten Inventargegenständen.
- Keine Änderungen an Backend, SQLite, Spielregeln oder den vorhandenen Import-/Exportformaten.
- Paket-/Strukturtests erfolgreich. Flutter-Analyse, Flutter-Widgettests und Android-APK müssen über GitHub Actions noch bestätigt werden.

## 0.4.3+19 – CI-Fix: überlaufende Attributkarten und mehrdeutige Widgettests (15.10.2026)

- GitHub Actions `38692820652`: Flutter-Analyse erfolgreich, 319 Tests erfolgreich, vier neue Layouttests rot. Drei Ursachen: `_AbilityCard`-Spalten bei 320 dp und 1.4x-Schrift überlaufen; bei 360/400 dp suchten Tests mehrdeutig nach `GridView` und warfen `Bad state: Too many elements`.
- Die sechs Attributkarten verwenden jetzt statt `GridView.count(childAspectRatio: ...)` einen expliziten `SliverGridDelegateWithFixedCrossAxisCount(mainAxisExtent: ...)`. Die Höhe passt sich mittels `MediaQuery.textScalerOf` an Systemschriftgrößen an. Keine Werte werden abgeschnitten oder verworfen.
- Übersichts- und Attributgrids haben eindeutige `ValueKey`s; Widgettests suchen gezielt das jeweilige Grid und scrollen bis zu den Rettungswürfen, um alle sechs Attributkarten zu rendern. Extra Test für TextScaler 1.4.
- Keine Änderungen an Spielregeln, Speicher, Backend oder Sicherheitsmodell; keine neuen Pakete.
- Prüfstatus: Projektstruktur, Python-Tests und ZIP-Integrität lokal; `flutter analyze`, `flutter test` und APK-Build erst durch GitHub Actions belegbar.

## 0.4.2+18 – Korrektur des CI-Kompilierfehlers (15.10.2026)

- `app/lib/ui/fantasy_character_sheet.dart`: `GridView.count` durch `GridView` mit `SliverGridDelegateWithFixedCrossAxisCount` ersetzt. Der Parameter `mainAxisExtent` befindet sich nun am richtigen Delegate.
- Bestehender Schutz vor `RenderFlex overflow` auf schmalen Displays und bei größerer Systemschrift bleibt erhalten.
- Regressionstest prüft Grid-Delegate, Anzahl Spalten und feste Kachelhöhe.
- Basiert auf `main` Commit `35a7b4062c5248b288598b587da6c606bf80122d` (0.4.1+17).
- Auslöser: GitHub Actions Build 38691911056 schlug am 15.10.2026 bei `flutter analyze` fehl (`undefined_named_parameter` in Zeile 237).
- Projektstruktur/Python-Tests hier geprüft; vollständige Flutter-/Android-Abnahme über GitHub Actions steht aus.

## 0.4.1+17 – Korrektur der Charakterbogen-Kacheln (15.10.2026)

- Die vier Statistik-Kacheln verwenden jetzt eine von Schriftgröße und Layout unabhängige Mindesthöhe statt eines festen Seitenverhältnisses. Dies behebt die drei `RenderFlex overflowed`-Fehler aus GitHub Actions beim Charakterbogen und beim Öffnen des Bogens aus dem Abenteuer.
- Große Textdarstellung wird durch eine an den TextScaler gekoppelte Höhe berücksichtigt. Lange Beschriftungen dürfen auf zwei Zeilen umbrechen; Zahlen werden bei Platzmangel horizontal skaliert.
- Zusätzliche Widget-Regressionstests für 320, 360, 400 logische Pixel und 140 % Schriftgröße.
- Keine Änderung an Regeln, Datenbank, KI-Backend oder gesicherten Charakterwerten. Der GitHub-Actions-Build muss die Korrektur bestätigen.

## 0.4.0+16 – 15.10.2026 – Gesamtes App-Design vereinheitlicht

- Das vollständige bestehende Flutter-UI orientiert sich jetzt am deutschen Dark-Fantasy-Charakterbogen. Zentrales Material-3-Theme und wiederverwendbare Widgets in `app/lib/ui/fantasy_ui.dart`.
- Einheitliche Farben, Serif-Überschriften, goldene/silberblaue Rahmen, einheitliche Buttons, Panels, Formulare, Dialoge, Chips, Listen, Erweiterungsfelder und Bottom Sheets.
- Hauptansichten **Start/Kampagnen**, **Abenteuer/Kampf**, **Helden/Charakterbogen**, **Tagebuch/Gedächtnis** und **Einstellungen/Backend** optisch angepasst. Inventar-Bottom-Sheet und Charaktereditor ebenfalls einbezogen.
- Responsive Navigation: unter 920 Pixel unten, ab 920 Pixel mit seitlicher Navigationsleiste. Keine künstlichen Inhalte oder nicht vorhandenen Karten-/Regel-Seiten.
- Zusätzliche Widgettests für Theme und Komponenten auf 320/360/1000 Pixeln sowie Dokumentation `docs/UI_DESIGN_SYSTEM.md`.
- Keine Spielregel-, Kampagnen-, Speicher-, API-, Kosten- oder Paketabhängigkeitsänderungen. Weiterhin echte bestätigte Daten und sichere Exportfunktionen.
- GitHub-Basis `ce64d5bd10288611bd3a8482b01a32939a309f76` (0.3.9+15). Strukturprüfung und 22 Python-Tests hier erfolgreich. **Flutter-/Android-Tests nicht lokal durchführbar.** Kein direkter Push auf `main`.

## 0.3.9+15 – 15.10.2026 – Neuer deutscher Fantasy-Charakterbogen

- Eigenständiger, deutschsprachiger Charakterbogen nach der abgestimmten Dark-Fantasy-Vorlage: dunkelblaue Flächen, goldene Kanten, farbige Attributkarten, Trefferpunktebalken und responsive Karten für Übungsbonus, Bewegung, Initiative und Rüstungsklasse.
- Aus der **Heldenverwaltung** („Bogen ansehen“) und aus dem **Abenteuer** („Charakterbogen ansehen“) erreichbar; vom Bogen aus ist der bisherige Charaktereditor weiterhin verfügbar.
- Abschnitte für Attribute/Rettungswürfe/Fertigkeiten, Zustände/Merkmale und Verteidigungsinformationen. Alle Informationen stammen aus dem echten `HeroCharacter`; unbekannte Werte bleiben als Strich bzw. „Nicht erfasst“ stehen. Mangels gespeicherter Portraitdaten wird ein Initialen-Avatar gezeigt, kein erfundenes Charakterporträt.
- Übungsbonus wird ausschließlich aus gültiger Stufe 1–20 berechnet, Attributmodifikatoren aus bestätigten Werten. Rettungswürfe addieren nur die explizit gespeicherte Übung; andere Effekte werden nicht erfunden. Die bestehende Bewegungseinheit bleibt **Meter**.
- Globales Designsystem an die neue Ansicht angepasst: marineblaue Karten/Hintergründe, Goldakzent, kontrastreichere Schriften und Buttons; Datenbankformat, Sprachausgabe, Kampagnen und Regel-Engine unverändert.
- Neue Flutter-Widgettests für deutsche Bezeichnungen, responsives Layout bei 320/360 px, Modifikatoren, fehlende Werte und Bearbeitungsaktion. Tests können hier mangels Flutter-SDK nur als Quellcode geprüft werden; sie müssen in GitHub Actions laufen.
- Korrektur des vorherigen Backend-CI-Testfehlers: Versionsassertion im Health-Test auf die tatsächliche Backend-Version `0.3.1` aktualisiert (vorher erwartete `0.3.0`).
- GitHub-Basis `125fc3630722002a955a4e3479395edd6bfb6635` (0.3.8+14). Kein direkter Push in `main`.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## 0.3.7+13 – 15.10.2026 – KI-gestützte eigene Kampagnen und Entscheidungen

- Optionaler Start neuer Kampagnen mit Wunschthema und bereits angelegtem Helden. Der verbundene OpenAI-Dienst erzeugt ein neues Abenteuer mit Welt, Einstiegsszene, verborgenem Plot, Ziel, 2–4 offenen Handlungssträngen, NPCs und Orten. Der Mock-Dienst bietet ausdrücklich nur eine deterministische Testgeschichte.
- Beim Weiterspielen berücksichtigt die KI die aktuelle Szene, gespeicherten Plot, bisherige Handlungsstränge, NPC-Beziehungen, geeignete bestätigte Erinnerungen und letzte sechs Spieleraktionen. Sie schlägt eine neue Szene, Statusänderungen, neue Fäden und Beziehungsentwicklungen vor. Die lokale Engine prüft die Struktur und übernimmt erlaubte erzählerische Daten als ein einziges atomar gespeichertes Ereignis.
- Persistenter `storyBible`-Block im Kampagnen-JSON (optional, alte Spielstände gültig), ohne neue SQL-Migration. Verborgene Wendungen stehen **nicht** in der allgemeinen Faktensuche oder im sichtbaren Tagebuch, wohl aber im privaten JSON-Export. Fortschritt, Beziehungen und Entscheidungen bleiben über Neustart und Export erhalten. Keine Gewichtsänderung oder lokale Modellschulung: **„lernend“ bedeutet kontext- und erinnerungsbasiert**.
- Neue authentifizierte, limitierte Backend-Endpunkte `POST /v1/story/start` und `POST /v1/story/advance`. Bestehende Sitzungstokens, HTTPS-Vorgaben und ausdrückliche OpenAI-Kostenfreigabe gelten auch hier; gemeinsames Minuten-/Tageslimit. Kein OpenAI-Schlüssel in der App, keine Server-Schreibrechte auf Spielstände.
- **Sicherheitsgrenze:** NPC-Beziehungs- und Story-Status dürfen sich entwickeln; HP, Würfelergebnisse, Attribute, Questbelohnungen und Inventar nicht. Ein Angriff auf einen nicht regeltechnisch erfassten Gegner wird blockiert, nicht von der KI ausgewürfelt. Das sind noch keine vollständigen frei generierten Kämpfe.
- Demo/Story getrennt: Die KI-Kampagne kann niemals automatisch auf das Mooswacht-Schlüssel-/Schrein-Skript zurückfallen. Provider-Ausfälle erhalten den bestätigten lokalen Spielzug; misslungener Kampagnenstart speichert gar nichts.
- Neue Domain-, SQLite-Integrations- und Backend-Tests zur Story-Erzeugung, ID-Validierung, deterministischen Testantworten, persistierten Beziehungen, falschen Providerantworten, Rate-Limits und verlorener Verbindung. Bekannte CI-Widgettestprobleme aus `ea486481d288...` (zweimaliger Dialogtitel und spätes Tagebuch-Scrolling) korrigiert.
- GitHub-Ausgangsbasis `ea486481d28856228abf65dd209857028b3b3c45` (0.3.6+12, 117 Dateien). **Hier ausgeführt:** Strukturscan, 22 Python-Tests, isolierter TypeScript-Parser und TypeScript-Syntaxcheck. Flutter-SDK und vollständige npm-Abhängigkeiten fehlen; Flutter-, komplette Backend-, APK- und Geräteprüfungen stehen aus.

## 0.3.6+12 – 15.10.2026 – Dauerhaftes Kampagnengedächtnis

- Im Tagebuch drei neue Bereiche: Sitzungsrückblicke dauerhaft speichern, Handlungsstränge mit Offen/Gelöst/Aufgegeben verwalten und Veränderungen der NPC-Beziehungen samt Notiz dokumentieren.
- Rückblicke werden ausschließlich aus strukturierten, bestätigten Quests, NPCs, Fakten und Handlungssträngen gebildet; freie KI-Erzähltexte und rohe Nutzereingaben sind keine Faktenquelle. Einträge gelangen in die lokale Erinnerungssuche und den Kontext des optionalen Backend-Erzählers.
- Neue optionale Felder `sessionRecaps`, `storyThreads`, `npcRelationshipNotes` in der bestehenden Kampagnen-JSON-Struktur. Vorhandene Sicherungen bleiben mit dem Parser kompatibel, SQLite-Schema bleibt Version 1. Maximal 60 Rückblicke, 100 Handlungsstränge und 300 Beziehungsnotizen.
- Alle Notizänderungen werden mit Revision und überprüfbarem Ereignis-Checkpoint atomar gespeichert. Regelwerte, HP, Würfel- und Questbelohnungen werden durch diese Verwaltungsaktionen nicht verändert.
- Zusätzliche Domänen-, Widget- und SQLite-Tests mit Testcode für Altimporte, Begrenzungen, Wiederherstellung, Replay, Beziehungshistorie und Eingabevalidierung.
- Vorherigen GitHub-CI-Fehler im Test `ui_app_test.dart` (Button „Vervollständigen“ auf 360-px-Bildschirm überlagert) durch Scrollen vor der Interaktion korrigiert. Auf Basis-Commit `6e967080baba7de252fac378d51758a20f6556ae` waren 290 Flutter-Tests erfolgreich, einer fehlgeschlagen; Flutter-Analyse, Python und Backend bestanden, APK-Schritte übersprungen.
- **Prüfstatus dieser Version:** Projektstruktur und alle 22 Python-Tests lokal bestanden. Mangels Flutter-/Dart-SDK und offline nicht verfügbarer npm-Abhängigkeiten sind Flutter/Backend-/APK-Prüfungen für 0.3.6 noch offen. Erfolgreiche CI vor Verwendung als installierbare APK erforderlich.

## 0.3.5+11 – 15.10.2026 – Kampagnenrückblick und NPC-Reaktionen

- Im Abenteuer gibt es einen direkt erreichbaren Button **Rückblick**. Ein noch nicht abgesendeter Handlungstext bleibt unverändert; Spracheingabe/-ausgabe wird vor der Aktion kontrolliert gestoppt.
- Erinnerung an bestätigte Fakten, NPC-Zustände, Queststatus, Inventar und bekannte Orte aus SQLite. Bei gezielten Fragen („Was weißt du über Mira?“, „Erinnere dich an den Waldschrein“) werden **nur thematisch passende** Erinnerungen ausgegeben, niemals ungefragte, unrelated Ereignisse.
- Bei allgemeinen Rückblicken werden bis zu vier relevante bestätigte Einträge angezeigt; die Ausgabe ist begrenzt und liefert explizit „keine passende Erinnerung“, wenn keine bestätigten Fakten zur Frage existieren. Unbestätigte Erzähltexte, Nutzereingaben und externe KI-Antworten werden nicht als bestätigte Fakten gelesen.
- Mira spricht im Demo-Modus jetzt abhängig vom bestätigten Verlauf: Schlüssel bereits gefunden, Dornenwächter besiegt, Waldlicht wieder entzündet. Erledigte Aufgaben werden nicht erneut verlangt.
- Neue Domänen- und Widgettests für thematische Abfragen, unbekannte Fakten, Unveränderlichkeit von Charakter-/Kampfwerten und Questzuständen sowie den Rückblick-Button.
- Ausgangsbasis `ManuEtt/Dnd` main `239ee5f7d333a6388159e7d431039abb92e936b7` (0.3.4+10); keine Schema-, Backend-, API- oder Paketabhängigkeitsänderungen. Flutter-/Android-Abnahme für dieses Inkrement muss nach GitHub-Import erfolgen.

## 0.3.4+10 – 15.10.2026 – Widgettest-Fix und Attribut-Vorschau

- Behebt den fehlerhaften Scrollweg im Widgettest `ui_srd_class_selection_test.dart`, der nach einem blockierten Speicherversuch die Hausregel-Checkbox nicht mehr fand (`StateError: Bad state: No element`). Bei Rueckspruengen wird jetzt negativ gescrollt.
- Neuer Komfort: Sofortige, unverbindliche Modifikatoranzeige unter Attributwerten im Charaktereditor, ueber dieselbe `RulesEngine.abilityModifier` berechnet wie regelgebundene Proben; unbestaetigte/ungueltige Werte bekommen keinen fiktiven Modifikator.
- Widgettest zur Aenderung, negativen Modifikatoren und Leereingabe ergaenzt.
- Basis ist unveraendert der GitHub-main-Commit `3b91a9778abe14184f35ac1db16f5acf121a84b5`. Keine Aenderung am Datenbankschema, Backend, Charakter-Speicherformat oder an bestehenden Charakterwerten.
- **Pruefung:** Python-Pakettests und Backend-Tests nach Moeglichkeit lokal; Flutter/Dart und Android SDK sind in dieser Ausfuehrungsumgebung nicht installiert. Neuer GitHub-Actions-Lauf nach Import erforderlich.

# Änderungsprotokoll

## 0.3.3 – Klassenwahl, Fertigkeiten und Startausrüstung (14. Oktober 2026)

- CI-Korrektur (15. Oktober 2026): Ungebundenen Dart-Dokumentationskommentar am Dateianfang von `app/lib/domain/srd_character_classes.dart` in reguläre Kommentare umgewandelt. GitHub-Actions-Lauf 38675268449 scheiterte ausschließlich an `dangling_library_doc_comments`. Flutter-Tests und Android-Build für diesen korrigierten Stand stehen nach Upload noch aus. Keine Änderungen an Spielregeln, Charakterdaten oder SQLite.


- Neue Klasse `SrdCharacterClass` mit den zwölf SRD-5.2.1-Klassen: Trefferwürfel, beide Rettungswurf-Übungen, zulässige Fertigkeitslisten und Auswahlanzahl (2–4) sowie Startpakete bzw. Startgold.
- Neuer Assistent „D&D-Klasse und Fertigkeiten wählen“ im Charaktereditor für Stufe-1-Charaktere. Ungültige oder doppelte Fertigkeitswahlen können nicht übernommen werden.
- Charakterausrüstung mit Inventargegenständen und Startgold kann **optional nur bei neuen noch unversorgten Charakteren** explizit übernommen werden; Wahl wird weder automatisch wiederholt noch Rüstung direkt angelegt.
- Start-TP-Vorschlag aus 0.3.2 im Assistenten nutzbar; vorhandene TP werden nur auf ausdrückliche Bestätigung ersetzt. Bestehende Fertigkeiten und Rettungswürfe bleiben beim Ergänzen erhalten; vollständiger Ersatz ist eine bewusste Option.
- Im neuen Charaktereditor werden freihändige Startattribute bzw. nachträgliche manuelle Änderungen an einer regelkonformen Verteilung nur nach Kennzeichnung als Hausregel gespeichert. Leere noch unbestätigte Attribute und historische/importierte Charaktere bleiben zulässig.
- Neue Domänen- und UI-Tests für sämtliche Klassentabellen, Fertigkeitsvalidierung, Aliasnamen, Altcharaktere und neue UI-Flows.
- Kein neues Backend, keine neuen Laufzeitabhängigkeiten und **keine Änderung am persistenten Charakter-JSON-Schema**. Klasse, Fertigkeiten, Rettungswürfe, Gold und Gegenstände verwenden die bereits vorhandenen Felder.
- Neue 0.3.3-Funktionen in dieser Übergabe **nicht mit Flutter auf Android kompiliert oder auf einem Gerät geprüft**; GitHub Actions führt die verbindlichen Flutter- und Android-Prüfungen nach dem Import aus.


## 0.3.2 – Vorbereitung, 14. Oktober 2026 (Start-Trefferpunkte nach SRD 5.2.1)

- Regelklasse `StartingHitPoints`: maximaler Klassen-Trefferwürfel plus KO-Modifikator für Stufe 1; zwölf SRD-Klassen, mindestens 1 TP.
- Neuer Button „Start-TP nach D&D vorschlagen“ im Charaktereditor mit eigener Vorschau und ausdrücklicher Bestätigung.
- Bisherige, importierte oder historische Trefferpunkte werden nur nach Bestätigung ersetzt; keine automatische Neuberechnung bei höherer Stufe.
- 19 neue Dart-Domänentests und ein Flutter-Widgettest im Quellcode; **Flutter-Test und Android-Build für 0.3.2 noch nicht ausgeführt**.
- Vollständiger Quellstand aus GitHub-Commit `4a8cfe9` geprüft und in das direkt importierbare ZIP integriert. Strukturprüfung und 22 Python-Tests nach Integration bestanden.
- Kein zusätzlicher API-Aufruf, keine neue Laufzeitabhängigkeit, keine SQLite-Schemaänderung.


## 0.3.1 — 14. Oktober 2026 (Sprache und CI; Backend bleibt 0.2.0)

- Abgewiesene TTS-Kommandos (0/false) werden als Fehler behandelt. Fehlgeschlagene Stimmwahl speichert keine ungültige Auswahl; entfernte Stimmen fallen bei der Neusuche auf einen verfügbaren deutschen Standard zurück.
- Deutsche Stimm-IDs normalisiert verglichen, native IDs erhalten, doppelte/fehlerhafte und als nicht installiert gemeldete Einträge entfernt. Anbieter-Metadaten für lokale und Netzwerkstimmen sichtbar.
- Stimmensuche ohne Mikrofonzugriff, Anbieter- und Locale-Anzeige, verständliche Paket-/Verbindungsfehler und unterbrechbare Ausgabe. Auswahl auf 360 px mit bis zu doppelter Schriftgröße geprüft.
- Hängende Android-Sprachabfragen und Wiedergabe begrenzt; unvollständige Erkennungsliste erlaubt ausdrücklichen de-DE-Versuch. Fehler-/Abbruchcallbacks geben lokale Wartevorgänge frei; keine automatische Mikrofonwiederholung.
- App-Start wartet auf lokale Spielstände, während der Sprachdienst danach unabhängig geprüft wird. Startprüfung mit echter SQLite-Datenbank und offener nativer Stimmabfrage ergänzt.
- Repositorystand erstmals gelesen und mit 0.3.0 verglichen: Dateiinhalte identisch, vier Ausführungsrechte verschieden. GitHub-Job bestätigt fehlendes sdkmanager nach erfolgreichen Tests; explizite Commandline-Tools-Installation in CI ergänzt. Git- und Connector-Schreibversuche weiterhin403, daher ZIP-Übergabe.
- Benutzerbericht zum App-Betrieb auf Samsung Galaxy S26 Ultra dokumentiert. Genaue betroffene Sprache/Anbieterfunktion bleibt offen; Sprachkorrektur auf dem Gerät separat abnehmen. Hauptsprache weiterhin Deutsch.

254 Flutter-Tests einschließlich 31 Sprachcontroller-, 7 neuen Einstellungen-
und 1 Starttest sowie 22 Backend- und 22 Python-Tests bestanden. Analyse ohne
Befunde, Backend- und universeller Debug-Build erfolgreich. Kleine APKs und
Übergabenachweise: DEVELOPMENT_STATUS.md.

## 0.3.0 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Explizite Stufe-1-Attributshilfe mit Standardsatz und Punktekauf bis 27 Punkten im Charaktereditor ergänzt.
- Vier SRD-Hintergründe mit erlaubten +2/+1- beziehungsweise +1/+1/+1-Steigerungen. Grundwerte, Boni, Endwerte und Modifikatoren getrennt dargestellt; Boni einmal angewendet.
- Vorhandene Werte benötigen Bestätigung zum Ersetzen. Öffnen/Abbrechen erhält historische und noch ungespeicherte Angaben.
- Nur Attribute und die gewählte Hintergrundbezeichnung werden übernommen; Talente, Fertigkeiten, Ausrüstung und Klassenwerte bleiben gesonderte Aufgaben. Keine Schemaänderung.
- Regeln anhand offizieller englischer/deutscher SRD 5.2.1-Quellen geprüft; 24 Domain-, 7 echte SQLite- und 13 neue Widgettests ergänzt und gezielt bestanden. Gesamter Check mit 222 Flutter-, 22 Backend- und 22 Python-Tests sowie Analyse und universeller Debug-Build erfolgreich. Drei optimierte Alpha-APKs gebaut, Metadaten/ABI und gleiche lokale Testsignatur geprüft. Geräteabnahme bleibt offen.

## 0.2.3 — 14. Oktober 2026 (Übergabe und Download; Backend bleibt 0.2.0)

- Quell-ZIP wahlweise ohne äußeren Dnd-Ordner; Byte-Erhalt, Dateiausschlüsse und sichere Paketpfade durch sechs Tests abgesichert.
- Projektprüfung vor SDK-Installation für fehlende/verschachtelte Dateien, Lockdateien, beschädigten Gradle-Wrapper und falsche Zeilenenden; 16 Regressionstests ergänzt.
- Kleine optimierte Alpha pro ARM64, ARM32 und x86_64 mit normalem Buildcode 5 sowie gleicher lokaler Testsignatur gebaut. Kein Store-Release. Dateien liegen jeweils unter 25 MiB.
- Kleine Alpha-Artefakte zusätzlich zur universellen Debug-APK in CI vorbereitet; 30 Tage Aufbewahrung.
- GitHub-Zugriff erneut überprüft: richtiger Benutzer ManuEtt, keine sichtbare App-Installation, Repository404 und Git403. Uploadursache ohne konkreten Fehlertext nicht als bestätigt behandelt.
- Upload-, Download- und Verbindungsanleitungen für die tatsächlichen Einschränkungen ergänzt.

## 0.2.2 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Charaktere und Kampagnen direkt als JSON-Dateien über Androids Systemauswahl sichern und öffnen; keine allgemeine Speicherberechtigung.
- Austauschbare Datei-Schnittstelle mit 10-MiB-Grenze, striktem UTF-8, sicheren vorgeschlagenen Dateinamen und verständlichen Fehlern.
- Ausgewählte Importdatei vor ausdrücklicher Bestätigung nur als bearbeitbaren Text anzeigen; Abbruch und Fehler erhalten bestehende SQLite-Daten. Zwischenablage bleibt verfügbar.
- 21 Kanal-/Sicherheitstests und 13 Datei-Widgettests ergänzen die Prüfung: 178 Flutter-Tests und Codeanalyse bestanden; Android-Debug-Build 0.2.2+4 erfolgreich. 12 native JVM-Tests für begrenztes I/O, Namen, Streamschluss und Abbruch bestanden; CI-Schritt ergänzt. Echte Dateiauswahl auf einem Gerät noch offen.

## 0.2.1 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Relevante bestätigte Erinnerungen für Backend-Erzählungen nach deutschen Worttreffern, NPC-Lebenszuständen, Queststatus und Inventarmengen ausgewählt.
- Unabhängige kurze Fakten und Flags bleiben beim Deduplizieren erhalten; Texte werden Unicode-sicher auf den erlaubten Kontext begrenzt.
- 13 neue Abruf-/Konsistenztests und ein Controller-Test mit mehr als 100 irrelevanten Fakten ergänzen die Prüfung: 144 Flutter-Tests, Analyse und Android-Debug-Build erfolgreich.

## 0.2.0 — 14. Oktober 2026

- Optionalen HTTPS-Backend-Erzähler mit temporärem Sitzungstoken, ausdrücklicher Kostenfreigabe und Anfragenversuchslimit in die App integriert.
- Backend-Sitzung ohne Modellaufruf prüfbar; neue Server-CLI zur Ausstellung kurzlebiger Tokens und Einrichtungshinweise ergänzt.
- Lokale Regelaktionen bleiben maßgeblich. Nur freie Erzählung und zugehöriger Checkpoint werden ersetzt; Ausfall, Tokenablauf und unzulässige Antworten führen zur lokalen Demo zurück.
- Fehler beim Ereignis-Replay behoben: Die Reihenfolge von JSON-Objektschlüsseln beeinflusst die Duplikatprüfung nicht mehr. Veränderte Werte und Listen werden weiter abgewiesen.
- Backend-Einstellungen, kleine Displays, Kostenfreigabe, echte lokale Node-/Dart-Kommunikation und Geheimnisfreiheit im SQLite-Speicher zusätzlich geprüft.

130 Flutter-Tests einschließlich echtem lokalem Protokolltest, 22 Backend-Tests, Codeanalyse und Android-Debug-Build bestanden. Ausstehende Backendanfragen lassen sich sofort trennen. Gerätetests bleiben separat offen. Details stehen in `DEVELOPMENT_STATUS.md`.

## 0.1.0 — 13. Oktober 2026

Eigenständiger Alpha-Projektstand zur ZIP-Übergabe für `ManuEtt/Dnd`. Ein Vergleich mit bestehendem Repositorycode war mangels Zugriff noch nicht möglich.

- Flutter-/Android-App mit Fantasy-Farben, Navigation, Charaktereditor, Abenteuer, Journal, Kampfgrundansicht und Einstellungen ergänzt.
- Deterministischen lokalen Spielleiter sowie Demo „Das Licht von Mooswacht“ mit Liora, Schlüssel, Waldschrein und einfacher Begegnung implementiert.
- Historische Kampagne „Das Herz der Ewigkeit“ als importierbaren Zustand mit ausdrücklich unvollständigem Arescan-Bogen ergänzt. Werte 19, 14 und der ungeprüfte Modifikator +7 bleiben historische Daten.
- Würfelregeln mit getrennten natürlichen Ergebnissen und Gesamtergebnissen, Angriffen, Schaden, Heilung und Todesrettung ergänzt.
- SQLite-Transaktionen für Charaktere, Kampagnensnapshots, Ereignisse und Revisionsjournal sowie JSON-Export/-Import eingerichtet.
- Grundlegende Kurzzeit-, Sitzungs- und Langzeitkontexte sowie Ereignisrekonstruktion ergänzt.
- Deutsche Gerätespracherkennung, bearbeitbares Transkript und unterbrechbare TTS integriert; Geräteprüfung steht noch aus.
- Optionales Fastify-/TypeScript-Backend mit validierter Erzähl-API, signierten Read-only-Sitzungstokens, Nutzungslimits und kostenlosem Mock eingerichtet. OpenAI Responses ist serverseitig optional; die mobile App nutzt weiterhin den lokalen Spielleiter.
- GitHub Actions für Backend- und Flutterprüfungen sowie Debug-APK eingerichtet.
- Architektur-, Status-, Test- und Übergabedokumentation sowie die geforderte SRD-5.2.1-Namensnennung ergänzt.

Erfolgreich geprüft: Flutter-Analyse ohne Befunde, 74 Flutter-Tests, 17 Backend-Tests und ein Android-Debug-APK-Build. Eine Prüfung auf einem echten Android-Gerät steht noch aus.

Überprüfte Ergebnisse stehen in `DEVELOPMENT_STATUS.md`. Vollständige SRD-Charakterbaulogik, öffentlicher Mehrspielerbetrieb, mobiler Realtime-WebRTC-Pfad, vollständige Erinnerungsverdichtung und weitere Plattformabnahmen bleiben offen.

## 0.6.8+38 – SRD-Klassenmerkmalregister und Klassenressourcen (16.10.2026)

- Alle zwölf SRD-Grundklassen und die zwölf SRD-Unterklassen als stufenbezogener Merkmalkatalog, einschließlich Automatisierungskennzeichen und Mehrklassen-Stufenabgleich.
- Mehrere Klassenressourcen separat persistiert und hinsichtlich Kurz-/Langrastregeneration verarbeitet; Altspeicher kompatibel.
- Regelbasierte Berechnungen für Schurken-Schadenswürfel, Kampfrauschwerte, Mönchskampfkunst und bardische Inspirationswürfel; Champion-Krit-Bereich in Angriffsauflösung; passive Bewegung/Initiative ergänzt.
- Neue Dart-Domain-Tests; kein Anspruch auf vollständige Ausführung aller Merkmalswirkungen oder validierten Flutter-/APK-Build.

## In Vorbereitung – strukturierte Inventarwerte (18.10.2026)

- Individuelle, typisierte Werte für Waffen, Rüstungen, Schilde, Verbrauchs- und magische Gegenstände gespeichert (`InventoryItem.stats`). Bestehende Spielstände ohne diese optionalen Werte bleiben lesbar.
- Eigene Eingabefelder im Charaktereditor, Katalogwerte als getrennte Datensätze übernommen, kompakte Werte-Vorschau im Inventar.
- Validierung verhindert negative Preise/Gewichte, unmögliche Ladungen und unzulässige Reichweiten; unbekannte Angaben bleiben unbestimmt.
- Neue Tests für JSON, SQLite, Katalogübernahme und UI ergänzt; **Flutter-Tests und Android-Build für diesen Stand noch nicht ausgeführt**.
- Individuelle Werte dienen vorerst der Verwaltung; für Kampfmechaniken gilt weiterhin der geprüfte SRD-Katalog. Kein automatisches Ausführen von Freitext-Effekten.

## In Vorbereitung – neue Charaktere: Erfahrungspunkte und Kämpfer-Stufe 1 (18.10.2026)

- EP-Vorgaben aus den D&D-SRD-5.2.1-Stufengrenzen, inklusive manueller Werteprüfung bei der Neuerstellung.
- Kämpfer Stufe 1: Pflichtwahl von Kampfstil und drei unterschiedlichen Waffenmeisterschaften, Startausrüstung und Vorschlag für W10 + KO-Start-TP.
- Zweite Luft wird als dokumentiertes Merkmal mit zwei Anwendungen sichtbar; bestehende Spiele und importierte Charakterbögen bleiben unverändert.
- Neue Domain- und UI-Tests für die Charaktererstellung. CI- und Android-Ergebnisse sind erst nach einem Branch-Build bestätigt.


## Übernommener Status aus Main145 (historisch)

## 23.10.2026 – XP-Belohnungsbelege: doppelte ID mit widersprüchlichem Betrag abweisen

- `ExperienceProgression.grant` akzeptiert bestätigte identische Wiederholungen weiterhin ohne doppelte XP-Gutschrift.
- Derselbe Belohnungs-Identifier mit abweichendem oder beschädigtem gespeicherten Betrag wird nun als Datenkonflikt abgewiesen, statt als erfolgreicher Aufruf zu gelten.
- Regressionstests für JSON-Roundtrip, unveränderte Originaldaten und widersprüchliche Duplikate. Eigene CI/Flutter-/Android-Tests müssen für den neuen Code-HEAD erst nachgewiesen werden; bestehender Main-Lauf #40012217485 gehört zum Vorher-Stand.
- Keine Änderung am SQLite-Schema 2 oder JSON-Spielstandsformat 1, keine neue App-Version im parallel entwickelten Branch.

---
