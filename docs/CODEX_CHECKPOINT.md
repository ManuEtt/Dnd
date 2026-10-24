## Integration 24.10.2026 – PR #155 übernommen, PR #156 rebasiert

- **LIVE:** `main` enthält PR #155 seit Commit `4c6040c063c96444d75523cacbfa84c4b36800fa` (Unicode-Formatzeichenschutz). Beide unabhängigen Codeänderungen wurden in diesem Integrations-Merge zusammengeführt; keine Variante entfernt.
- **TESTS:** Vorläufer-CI #40076142566 und #40079373346 jeweils erfolgreich auf getrennten Heads. **Die neue Kombination ist NICHT getestet**, bis GitHub Actions auf dem Merge-HEAD erfolgreich abgeschlossen ist.
- **KOMPATIBILITÄT:** App 0.8.37+87, SQLite-Schema 2, Export-JSON 1 unverändert; Sending-Zustellvorgang und UI bleiben offen.
- **NÄCHSTER SCHRITT:** Neue kombinierte CI einschließlich Flutter, Backend, SQLite und Android abnehmen; danach PR #156 integrieren.

---

## CI-Abnahme 24.10.2026 – bestätigter Sending-Versuch (PR #156)

- **LIVE:** Unveränderte Ausgangsbasis `main` `b6b0fdb433330fec2a7b98fe62451ebfbfbec822`. [PR #155](https://github.com/ManuEtt/Dnd/pull/155) ist separat grün und reviewbereit, aber nicht gemergt. Neues Inkrement [PR #156](https://github.com/ManuEtt/Dnd/pull/156), ausführbarer Code-HEAD `2566a84e9a5f3c374c0ca0efd2f0ec558cc5bbfe`.
- **IMPLEMENTIERT:** Explizit bestätigter Sending-Versuch nur außerhalb aktiver Kämpfe/offener Würfe, originaler Hero-Snapshot vor Ressourcenverbrauch, gesicherter Zauberplatzverbrauch, lokale `spell.sending.attemptConfirmed`-Quittung, Anfrage-ID-Duplikatschutz und Revisionsschutz. Kein Zustell- oder KI-Effekt.
- **GETESTET:** [Vollständige GitHub Actions #40078375498](https://github.com/ManuEtt/Dnd/actions/runs/40078375498) auf dem ausführbaren Commit `2566a84e` **completed / success**, 34 erfolgreiche Jobschritte einschließlich Python/Struktur, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse, gezielte Flutter-Dialogtests, **komplette Flutter-Suite mit neuen Sending-Domain-/SQLite-Regressionen**, Android-Debug-APK, nativer Android-Dateisicherungstests, kleinen ABI-Alpha-APKs, versioniertem Alpha-Paket und Quellcode-Checkpoint. Frühere rote CI-Befunde (Dart-Formatierung und versehentlich duplizierte Quellcodeabschnitte) wurden korrigiert. Temporärer Diagnoseworkflow ist entfernt.
- **CI-ARTEFAKTE:** [Source-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40078375498/artifacts/12554527162) (GitHub-Archiv-SHA256 `e61adb24a44e1cba632df308d3d09153f8b2c2e1358fa31d0f86d77e56737227`), [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40078375498/artifacts/12554522162) (Archiv-SHA256 `665f29a1b510c3df2921e62963418ccaa15c14686306c1b177bd169d9cbb9af1`), [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40078375498/artifacts/12554482327) und [versioniertes Alpha-Paket](https://github.com/ManuEtt/Dnd/actions/runs/40078375498/artifacts/12554626816). Artefaktnamen nutzen den generierten PR-Test-Merge-SHA; GitHub-Archiv-Digest ist **nicht** der SHA einer einzelnen APK.
- **NICHT GETESTET:** Echte Android-Geräteinstallation, Upgrade historischer Spielstände und produktive Release-Signierung. Der folgende reine Dokumentationsnachtrag ist **kein** weiterer ausführbarer Code-Commit; separate finale PR-Checks müssen ebenfalls beobachtet werden.
- **BLOCKIERT:** Kein physisches Gerät für direkte Abnahme, lokal kein Flutter-/Android-SDK. **NOCH NICHT IMPLEMENTIERT:** Sending-UI-Bestätigungsdialog, tatsächliche magische/Netzwerk-Zustellung, Antwort, empfängerbezogene Weltuhr-Sperre sowie allgemeine Zauberaktion im Kampf.
- **KOMPATIBILITÄT:** App `0.8.37+87`, SQLite 2, Kampagnen-JSON 1, Rule-/Story-/KI-Grenzen unverändert; SRD-5.2.1-`SPELL-ENTRY-SENDING` bleibt `partial`.
- **NÄCHSTER KONKRETER SCHRITT:** PR #156 nach finalen Dokumentations-CI-Checks reviewen und sicher integrieren; anschließend als **separates** Paket einen expliziten deutschen Sending-Dialog mit bestätigter Nachricht, Kostenanzeige, Abbruch- und Revisionsschutz auf 320–360dp bauen und testen. Kein automatischer Hintergrundlauf.

---

## Zyklus 24.10.2026 – Sending-Slotbuchung mit bestätigtem Ereignis (PR #156)

- **LIVE-BASIS:** main `b6b0fdb433330fec2a7b98fe62451ebfbfbec822`, letzte Main-CI [#40074505420](https://github.com/ManuEtt/Dnd/actions/runs/40074505420) erfolgreich. PR [#155](https://github.com/ManuEtt/Dnd/pull/155) bleibt offen, war auf Head `d73f3cf` vollständig [CI-grün](https://github.com/ManuEtt/Dnd/actions/runs/40076142566), inzwischen zur Review bereit. Neues unabhängiges Inkrement: [Draft-PR #156](https://github.com/ManuEtt/Dnd/pull/156) auf `feat/sending-confirmed-slot-journal-20261024`; keine direkte Main-Mutation.
- **PRODUKT:** Würfelraunen 0.8.37+87; `SPELL-ENTRY-SENDING` weiter **partial** nach SRD 5.2.1, *Sending*, S. 161 (CC BY 4.0).
- **IMPLEMENTIERT:** Vorher rein lesende Vorschau hält intern den ursprünglichen `SrdSpellCastPlan` (Hero-Snapshot). Der separate bestätigte Versuch verbucht höchstens einen zulässigen Zauberplatz über `SpellcastingRules.cast`, verweigert abgelehnte und veraltete Vorschauen. `GameEngine.confirmSendingAttempt` sperrt aktive Kämpfe/offene Würfe und identitätskollidierende Handlungen; `GameController.confirmSendingAttempt` prüft Revisionen und kann bereits bestätigte Belege idempotent nach Neustart oder verlorenem ACK laden. Das Ereignis `spell.sending.attemptConfirmed` dokumentiert Versuch, Nachricht, Empfänger und unverifizierten/gesperrten/fehlgeschlagenen Zustellstatus; **keine Nachrichtenzustellung oder KI-Antwort**.
- **TESTS GESCHRIEBEN:** `app/test/srd_sending_cast_commit_test.dart` mit Domain-Verbrauch und Ablehnung, alter Hero-Snapshot, doppelter ID, bestätigtem SQLite-Restart und erneutem Aufruf, abweichender Nachricht, veralteter Revision sowie SQL-Trigger-Rollback. Bestehende Sending-Preflight-/Spellcasting-Suites sollen unverändert bleiben.
- **GETESTET:** Bisher grüne Basis-CI und PR #155 für jeweils ältere/andere Commits; **keine neue erfolgreiche CI für PR #156 behauptet**, bis dieser HEAD tatsächlich abgenommen ist.
- **NICHT GETESTET:** Neue Dart-/Flutter-Tests, Flutter-Format und Analyse, native Android-Tests, APK/Alpha, reales Android-Gerät bis jeweiliges Ergebnis verifiziert wurde.
- **BLOCKIERT:** Kein lokales Flutter/Android-SDK oder reales Gerät in der aktiven Umgebung; GitHub-CI übernimmt Build/Tests.
- **NOCH NICHT IMPLEMENTIERT:** UI-Bestätigungsdialog, Provider-Zustellung, Empfängerantwort, 8h-Sperr-Weltuhr, Sending im Kampf, allgemeine vollständige SRD-Automatik.
- **DATEN/ARCHITEKTUR:** SQLite 2, Kampagnen-JSON 1 und App-Version unverändert. Regel-Entscheidung ausschließlich lokal, Event+Heldensnapshot in Repositorytransaktion. Story/KI löst keine Ressourcenänderung aus. Quelldateien: `app/lib/domain/srd_sending_cast_preflight_rules.dart`, `app/lib/domain/game_engine.dart`, `app/lib/services/game_controller.dart`, neuer Test und diese Dokumentation.
- **NÄCHSTER KONKRETER SCHRITT:** Auf finalem PR-#156-HEAD vollständige CI-Format-, Flutter- und Android-Prüfungen kontrollieren, Fehler reparieren und erst dann Review/Integration erwägen. Danach eigener UI-Schritt mit ausdrücklicher Casting-Zustimmung und offener Zustellanzeige. Keine automatische Hintergrundfortsetzung.

---

## CI-Abschluss 2026-10-24T09:56+02:00 – Sending-Unicode-PR #155

- **IMPLEMENTIERT:** Die auf dem Branch `fix/sending-unicode-format-controls-20261024` ergänzten Unicode-Formatzeichen-Sperren und die Regressionstests sind unverändert. Letzter ausführbarer Commit: `1db4830778d69b5d2f8c8903bb71e75cc211919f`; Basis-main: `b6b0fdb433330fec2a7b98fe62451ebfbfbec822`. [PR #155](https://github.com/ManuEtt/Dnd/pull/155) bleibt ungemergt.
- **GETESTET:** [Vollständige GitHub-Actions-CI #40075349670](https://github.com/ManuEtt/Dnd/actions/runs/40075349670) auf exakt `1db4830`: **completed/success**. Python-/Strukturprüfungen, Backend-Typecheck/Build/Tests, Dart-Format, Flutter-Analyse, gezielte und vollständige Flutter-Tests, Android-Debug-APK, native Android-Tests, kleine Alpha-APKs und versioniertes Alpha-/Source-Artefakt bestanden. Ein früherer CI-Formatfehler auf `6080017` wurde mit `1db4830` nachweislich behoben; vollständige Abnahme enthält 34 erfolgreiche Jobschritte.
- **BELEGTE ARTEFAKTE:** [Quell-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40075349670/artifacts/12553435809) (Archiv-SHA256 `fc6fe1a7930f42f0231ecc4b878a843bee39492f15844e55cbdd7e571d236443`), [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40075349670/artifacts/12553380888) (Archiv-SHA256 `6e03bcaad2af27212daea7df5571803ffdab1044608250eac32303d59ae3c0ff`), [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40075349670/artifacts/12552987060), [versioniertes Alpha](https://github.com/ManuEtt/Dnd/actions/runs/40075349670/artifacts/12552987062). Artefakte sind zeitlich befristet; Archiv-SHA ist nicht die SHA einer individuellen APK.
- **NICHT GETESTET:** Physisches Android-Gerät, Installation/Upgrade mit Altspielstand, produktive Signierung; die nachfolgende Dokumentationskorrektur selbst besitzt keinen eigenen vollständigen Code-Test.
- **BLOCKIERT:** Lokale Flutter-/Android-SDKs und Testgerät fehlen weiterhin. **NOCH NICHT IMPLEMENTIERT:** Tatsächlicher Sending-Cast samt atomarem Slot-/Aktionsereignis; `SPELL-ENTRY-SENDING` bleibt **partial**.
- **KOMPATIBILITÄT:** Version 0.8.37+87, SQLite 2, Kampagnen-JSON 1, KI-/Story-Grenzen unverändert. Dieser Nachtrag ändert nur die Dokumentation, nicht den erfolgreich getesteten ausführbaren Stand.
- **NÄCHSTER KONKRETER SCHRITT:** PR #155 anhand der finalen Statusprüfungen reviewen und konfliktfrei integrieren; vor neuem Casting-Paket den aktualisierten main-HEAD als Basis nachweisen.

---

## Zyklus 2026-10-24T09:40+02:00 – Sending-Unicode-Eingabeintegrität (PR #155)

- **LIVE:** main `b6b0fdb433330fec2a7b98fe62451ebfbfbec822`, PR #154 inzwischen gemergt; beim Start keine offenen PRs. Eigener [Draft-PR #155](https://github.com/ManuEtt/Dnd/pull/155), Branch `fix/sending-unicode-format-controls-20261024`. Main-Actions [#40074505420](https://github.com/ManuEtt/Dnd/actions/runs/40074505420) beim Start **in_progress**.
- **VERSION/REGEL:** Würfelraunen `0.8.37+87`; `SPELL-ENTRY-SENDING` weiter **partial**. Quelle: offizielles SRD 5.2.1, *Sending*, S. 161 (CC BY 4.0). Rein technische Eingabesicherung, keine zusätzliche SRD-Regel.
- **IMPLEMENTIERT:** `app/lib/domain/srd_sending_rules.dart` sperrt zusätzlich U+00AD, U+034F, U+061C, U+180E, U+2061–U+206F und U+FFF9–U+FFFB in Nachrichten und Empfängerkennungen. Die 25-Wort-SRD-Grenze und technische 2048-UTF-16-Grenze bleiben unverändert. Neue Gegenbeispiele in `app/test/srd_sending_rules_test.dart` und `app/test/srd_sending_cast_preflight_test.dart` einschließlich 26 durch U+2063 verbundener Wörter, manipulierter ID und kombinierter Sending-Vorschau.
- **GETESTET:** Lokaler JavaScript-RegExp-Sanity-Check auf die neu gesperrten Codepunkte und normale deutsche Zeichen. Vorherige vollständige [PR-CI #40072501279](https://github.com/ManuEtt/Dnd/actions/runs/40072501279) auf Quell-HEAD `05fc6dde3c8d05748ce010e2d39b6fe909aba729` erfolgreich; sie belegt **nicht** PR #155.
- **NICHT GETESTET:** Neue Dart-/Flutter-Tests, Dart-Formatter, Flutter-Analyse, Android/native Tests, Debug/Alpha-APK, echte Geräteinstallation und Update alter Spielstände bis eigener PR-CI. Keine APK für PR #155 behauptet.
- **BLOCKIERT:** Aktive lokale Umgebung ohne Dart-/Flutter-/Android-SDK; Java 21 statt CI-Java 17. GitHub Actions muss die neue Codebasis verifizieren.
- **NOCH NICHT IMPLEMENTIERT:** Transaktionaler Sending-Cast mit Slot-/Aktionsereignis und tatsächlicher Nachrichtenzustellung; vollständiges SRD 5.2.1.
- **KOMPATIBILITÄT:** Keine Änderung an SQLite 2, Kampagnen-JSON 1, App-Version, KI-/Storygrenzen, API-Anbietern oder gespeicherten Charakteren. Main bleibt unverändert, keine Branchlöschungen.
- **DATEIEN:** `app/lib/domain/srd_sending_rules.dart`, zwei Sending-Testdateien, `docs/SRD_SENDING_MESSAGE_RULES_20261023.md`, diese Checkpoint-Datei, `README.md`, `CHANGELOG.md` und `DEVELOPMENT_STATUS.md`.
- **GENAU EIN NÄCHSTER SCHRITT:** Finale GitHub-CI von PR #155 am letzten Branch-HEAD kontrollieren (Format, beide Sending-Tests, Flutter-Gesamtsuite, Android); fehlgeschlagene Schritte reparieren. Erst nach vollständig belegter Abnahme über Integration entscheiden. Keine automatische Ausführung nach Sitzungsende.

---

## 24.10.2026 – Sending-Ressourcen-Vorprüfung vollständig in GitHub-CI abgenommen

- **IMPLEMENTIERT:** Explizit bestätigte Sending-Empfänger-/Nachrichtenfakten kombiniert mit vorbereiteter eigener Klasse, Zaubergrad/-platz, Komponenten, Action und Slot-Zuglimit; danach spezielle Blockade-/Ebenen-W100-Prüfung. Rein lesende Vorschau. Zusätzlicher reiner Spellcasting-Dry-run verhindert Vorschauen bei 0 TP/kampfunfähig/untrainierter Rüstung. Gefälschte Sending-Elemente/Klassen werden abgewiesen.
- **GETESTET:** [PR-CI #40071729227](https://github.com/ManuEtt/Dnd/actions/runs/40071729227) auf tatsächlichem ausführbarem Branch-Commit `efed3d732459478b072452ab8e92ef3c674e39fd` **completed/success**. Erfolgreich: Python-Projekt- und Strukturprüfungen, Backend-Typen/Build/Tests, Dart-Format, Flutter-Codeanalyse, gezielte Dialogtests, **gesamte Flutter-Suite inkl. acht neuer Sending-Cast-Regressionstests**, Android-Debug-APK, native Android-Dateisicherung, kleine ABI-Alpha-APKs, vollständiges versioniertes Alpha-Release sowie Source-Checkpoint.
- **CI-ARTEFAKTE:** [Kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40071729227/artifacts/12551981345) (ZIP-Digest SHA-256 `6509696aec9d3a5e35445e5c5bad30f842363ee2b824c9dbf13237bc4e2cf95c`), [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40071729227/artifacts/12552046040), [versioniertes Alpha-Paket](https://github.com/ManuEtt/Dnd/actions/runs/40071729227/artifacts/12551812328), [vollständiger Source-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40071729227/artifacts/12551424474). Die Artefaktnamen tragen den generierten PR-Test-Merge-SHA `d9c4ad2f...`, nicht den Source-Head. GitHub-Artefakte sind zeitlich befristet.
- **LIVE-GIT:** [PR #154](https://github.com/ManuEtt/Dnd/pull/154) offen/mergeable, `main` zuletzt `da80d3f2895098952b701fffe31586f8be07be1e`. **Kein** Merge nach `main`; keine unerlaubte Branch-Löschung. Der temporäre Format-Diagnoseworkflow war nicht Bestandteil des erfolgreich geprüften Codes und wurde bereits vorher gelöscht.
- **NICHT GETESTET:** physische Android-Installation oder Update eines echten Spielstands; produktive Signierung; Live-Nachricht oder NPC-Antwort. **BLOCKIERT:** kein lokales Android-Gerät/Sdk. **NOCH NICHT IMPLEMENTIERT:** atomarer tatsächlicher Sending-Cast mit Ressourcen-/Actionbuchung und persistiertem Ereignis, Weltzeit für Empfängersperre, alternative Zielebenen-Entdeckung.
- **KOMPATIBILITÄT:** SQLite 2, Kampagnen-JSON 1, App-Version `0.8.37+87` unverändert. Arbeits-ID `SPELL-ENTRY-SENDING` weiterhin `partial` (vollständiges SRD nicht abgedeckt). Das folgende Dokumentationsupdate ändert keinen ausführbaren Code; eigene CI für den neuen PR-Head ist getrennt von dieser vollständigen Code-Abnahme zu beurteilen.
- **NÄCHSTER KONKRETER SCHRITT:** PR #154 nach Review ggf. in main integrieren, dann als eigenes Regel-/Integrationspaket explizite Zauber-Aktions- und Slotverausgabung mit SQLite und Spielstandsrevision sicher implementieren und prüfen.

---

## 24.10.2026 – Sending-Regelverbund aus Empfänger und Zauberressourcen

- **Formatter-Abgleich abgeschlossen:** Zweiter rein lesender Format-Diagnoselauf #40071595620 bestätigte, dass nur der Slot-Map-Zugriff in `srd_sending_cast_preflight_rules.dart` exakt auf mehrere Zeilen aufzuteilen war; die neue Testdatei ist bereits formatterkonform. Diese letzte Korrektur wird gesichert und der temporäre Workflow aus dem Repositorybaum entfernt. Eine neue vollständige CI muss den finalen ausführbaren Code bestätigen.

- **Korrektur nach CI-Analyse:** Der Validator nutzt zusätzlich einen nicht gespeicherten `SpellcastingRules.cast`-Dry-run. Er verweigert eine positive Vorschau für kampfunfähige Figuren, 0 Trefferpunkte oder ungeübte angelegte Rüstung. Der hypothetische Held wird nicht gespeichert. Die erlaubten drei Sending-Klassen sind gegen Katalogmanipulation fixiert; Negativtests ergänzt. Die erste/zweite CI endete am Dart-Formatgate (#40070752407 / #40071043289). Die exakte Formatter-Differenz wurde einmalig durch einen nur lesenden temporären GitHub-Workflow ermittelt, der in diesem Commit entfernt wird. Neue vollständige CI erforderlich.

- **CI-Fix:** Erste Code-Push-CI [#40070752407](https://github.com/ManuEtt/Dnd/actions/runs/40070752407) auf `99ff7626057f60a0cf7d47cd42ba1859f8d02e42` stoppte bei `dart format`: zwei neue Dateien mussten formatiert werden; spätere Flutter-/Android-Checks nicht ausgeführt. Den langen ternären Ausdruck in kurze Zwischenvariable zerlegt und den langen Testtitel gekürzt. Vollständige neue CI des nächsten Code-Commits notwendig.

- **LIVE-BASIS:** Main `da80d3f2895098952b701fffe31586f8be07be1e`, [Main-GitHub-CI #40069427402](https://github.com/ManuEtt/Dnd/actions/runs/40069427402) vollständig success. PR #153 bereits in main integriert, am Sitzungsbeginn keine offenen PRs. App-Version `0.8.37+87`, SQLite 2, Export-JSON 1.
- **REGELQUELLE/ARBEITS-ID:** SRD 5.2.1, S. 161, *Sending* plus *Casting Spells/Components/Spell Slots*, CC BY 4.0; `SPELL-ENTRY-SENDING` bleibt **partial**, weil nur die Vorprüfung erweitert wird.
- **IMPLEMENTIERT:** `app/lib/domain/srd_sending_cast_preflight_rules.dart` mit `SrdSendingCastPreflightRules.preview`. Es kombiniert `SrdSendingRules.prepare`, `SrdSpellPreflightRules.preflight` und `SrdSendingRules.assessDelivery` ohne Story- oder UI-Import. Strikte Katalogmetadaten, Klasse, Vorbereitung, Mindeststufe, Slot/Slot-pro-Zug, bestätigte Aktion/V/S/M, Kupferdraht/Fokusrecht, empfängerbezogene `Unlimited`-Validierung und korrekt abgegrenzte Blockade-/Ebenenprüfung. Hypothetischen Restslot anzeigen; Held/DB/Ereignisse bleiben unverändert.
- **TESTS GESCHRIEBEN:** sieben Domain-Regressionsgruppen in `app/test/srd_sending_cast_preflight_test.dart` – Barde/Kleriker/Magier, falsche Klasse/vorbereiteter Zauber/Level, Slots 2/9/aufgebraucht, Aktion/V/S/M/Fokus, Empfänger-25-Wörter/Unicode, bestätigte W100/Blockade/unbekannte Lage und gefälschte Zaubermetadaten.
- **GETESTET:** Die Ausgangsversion Main mit [#40069427402](https://github.com/ManuEtt/Dnd/actions/runs/40069427402) vollständig grün. **NICHT GETESTET:** neuer Branch-Code bis eigener CI, echte Android-Installation und vollständiger Sending-Zaubervollzug. **BLOCKIERT:** kein lokales Flutter/Android-SDK und kein physisches Testgerät. **NOCH NICHT IMPLEMENTIERT:** atomarer Zauberplatz- und Aktionsverbrauch, konkreter Liefer-/Sperrbeleg, Empfängerantwort und Acht-Stunden-Weltuhr.
- **KOMPATIBILITÄT:** keine Änderung an Existing-Rule APIs, generischen `Unlimited`-/`Special`-Sperren, SQLite 2, JSON 1 oder Version `0.8.37+87`. Kein bezahlter KI-Provider.
- **NÄCHSTER KONKRETER SCHRITT:** Branch-PR auf `main` mit vollständiger Python-/Backend-/Dart-/Flutter-/Android-/APK-CI verifizieren. Erst danach als eigenes Feature einen ausdrücklich bestätigten Sending-Cast mit atomarer DB- und Ressourcenbuchung betrachten.

---

## 24.10.2026 – Abnahme der SRD-Sending-Eingabeintegrität (CI vollständig erfolgreich)

- **IMPLEMENTIERT:** Validierte Sendernachrichten gegen unsichtbare Unicode-Trenner, Bidikontrollen, ASCII/C1-Steuerzeichen sowie technisch unbeschränkte Eingaben; 25-Wörter-SRD-Grenze und normaler deutscher Text bleiben unverändert. Rein lesende Vorprüfung.
- **GETESTET:** [GitHub Actions PR-Workflow #40068321150](https://github.com/ManuEtt/Dnd/actions/runs/40068321150) mit gemeldetem PR-Code-HEAD `fb96641db97598a5ee1b59416ad254f5e0e63e29`: **completed/success**. Erfolgreich: Python-Projektprüfungen, Backend-Typen/Build/Tests, Dart-Format, Flutter-Analyse, gezielte Dialogtests, **gesamte Flutter-Test-Suite inkl. neuer Sending-Regressionen**, Android-Debug-APK, native Android-Dateisicherungstests, kleine Alpha-APKs und vollständige versionierte Alpha-/Quellcode-Artefakte. Frühere Formatrots auf `eaa3b67b...` und `6bbfbeb5...` wurden über den Commit `fb96641db97598a5ee1b59416ad254f5e0e63e29` behoben.
- **ARTEFAKTE:** [Versioniertes Alpha-Paket](https://github.com/ManuEtt/Dnd/actions/runs/40068321150/artifacts/12550461977) (ZIP-Digest SHA-256 `47e86a1cc0c854b648369d63078930ccce4c132b144863ce0c919f62aa3e8e70`); [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40068321150/artifacts/12549624430), [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40068321150/artifacts/12549499860), [Quellcode-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40068321150/artifacts/12549798592). Der Präfix `bc315e3c...` in Dateinamen ist der vom PR-Workflow ausgecheckte Test-Merge-Commit, kein anderer Code-Branch-HEAD. Artefakte sind zeitlich befristet.
- **LIVE-GIT:** `main` zuletzt `d2a8dca87f5dd7ee76fd926de6c213d344f235fc`, offener [PR #153](https://github.com/ManuEtt/Dnd/pull/153), Code-HEAD `fb96641db97598a5ee1b59416ad254f5e0e63e29`, mergeable true. **Keine** Änderung an `main` und kein automatischer Merge.
- **NICHT GETESTET:** echte Android-Geräteinstallation/-Aktualisierung, produktive Signierung und vollständiger Sending-Spellcast. **BLOCKIERT:** kein Gerät/SKD für lokale Abnahme. **NOCH NICHT IMPLEMENTIERT:** Sending-Slot-/Aktionsverbrauch, Nachrichtenzustellung, Empfängerantwort, Acht-Stunden-Sperrzeit.
- **DATENFORMAT:** App `0.8.37+87`, SQLite 2, Export-JSON 1 unverändert. Das nun folgende reine Dokumentationsupdate enthält keine Änderungen an dem vollständig getesteten ausführbaren Code.
- **NÄCHSTES INKREMENT:** Nach PR-Review neuen eigenständigen Sending-Spellcast-Vertrag mit ausdrücklicher Ressourcen-/Aktionsbestätigung und atomarer SQLite-Ereignisverbuchung planen und mit SRD-Quelle prüfen; keine Ausführung als gegeben behaupten.

---

## 24.10.2026 – Sicherheitsgrenzen der SRD-Sending-Nachrichten

- **CI-Befund und Korrektur:** Erster [Push-Lauf #40068069124](https://github.com/ManuEtt/Dnd/actions/runs/40068069124) (SHA `eaa3b67b8e4e5b0f6f0263156a86b63358081c81`) scheiterte beim strikt geprüften Dart-Formatter: zwei geänderte Dateien, Folgeschritte noch nicht ausgeführt. Im Anschluss die zusätzliche Leerzeile in der Domain entfernt sowie mehrzeilige Testzeichenkette und langen Testtitel auf formattergerechte kurze Ausdrücke umgestellt. Der neue Code-Head benötigt erneut eine vollständige eigene CI.

- **LIVE-BASIS:** `main` `d2a8dca87f5dd7ee76fd926de6c213d344f235fc`, nach PRs #144/#149/#151 und Konsolidierung #152. Zum Start keine offenen PRs. Beide letzten Main-CI-Läufe [#40066464900](https://github.com/ManuEtt/Dnd/actions/runs/40066464900) und [#40066464899](https://github.com/ManuEtt/Dnd/actions/runs/40066464899) auf genau diesem SHA **completed/success**. App `0.8.37+87`.
- **PROBLEM:** Bisher zählte der Sending-Validator nur durch Leerraum getrennte Tokens. Unsichtbare Zeichen wie U+200B/2060 und Richtungssteuerung konnten die Prüfung des vom Spieler wahrgenommenen Textes umgehen; auch eine Einwort-Nachricht von Millionen Zeichen war zulässig. Manipulierte Empfängerkennungen mit Kontrollzeichen waren nicht gesperrt.
- **IMPLEMENTIERT:** `SrdSendingRules.prepare` verbietet unsichtbare Steuer-, Trenn- und Bidizeichen und begrenzt die Nachricht auf technisch 2048 UTF-16-Codeeinheiten. Die 25-Wörter-SRD-Grenze, bestätigte Empfängeridentität, deutsche Umlaute, normale Zeilenumbrüche und Tabulatoren sind unverändert. Rein lesende Validierung, kein Zauber-Commit.
- **TESTS GESCHRIEBEN:** vier Domain-Testgruppen in `app/test/srd_sending_rules_test.dart` (zulässige 25 deutsche Wörter mit Zeilenumbrüchen; unsichtbare 26-Wort-Kette, NUL/ESC/Bidi; exakt 2048 vs 2049; manipulierte Empfängerkennungen). Positiv- und Manipulationspfade vorhanden.
- **GETESTET:** Nur die beiden grünen Basis-CI-Läufe #40066464900/#40066464899. **NICHT GETESTET:** neuer Code vor eigenem CI, reales Android-Gerät und ausführbarer Sending-Zauber. **BLOCKIERT:** keine lokale Flutter-/Android-Toolchain. **NOCH NICHT IMPLEMENTIERT:** Sender-Zauberkosten, Ausführung, Slots, Antwort, Acht-Stunden-Weltuhr; vollständige SRD-Automatik.
- **KOMPATIBILITÄT:** DB 2, JSON 1 und App-Version `0.8.37+87` unverändert. 2048-Einheiten sind ausdrücklich **technisches App-Limit**, keine SRD-Regel. Regelregister bleibt partiell, keine globale Vollständigkeitsbehauptung.
- **NÄCHSTER KONKRETER SCHRITT:** neuen PR gegen main erstellen, CI auf finalem HEAD inkl. Dart-Format, Flutter-Tests und Android-APK abnehmen; Fehler vollständig beheben. Später separate vollständige Sending-Spellcast-Aktion.

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

## Aktiver Integrationsabschluss – 24.10.2026

Während der abschließenden CI wurde PR #145 nach main1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd übernommen. Dokumentationskonflikte werden unter Erhalt beider Historien aufgelöst; XP-Code und beide Tests unverändert integriert. Keine neue Regelphase begonnen. Die bisher unten belegte grüne CI40057898163 auf bfc991f prüft den Vorintegrationsstand. Die neue Kombination muss erneut vollständig geprüft und als eigenes ZIP/Patch gesichert werden. APKs des alten Standes bleiben erhalten und gelten nicht automatisch für diesen neuen Source-Stand.

Nächste notwendige Aktion: Integration committen, Format/Analyse/Flutter/Backend/Python und Android aus neuem Quell-ZIP abnehmen, PR147 aktualisieren. Alte geprüfte Artefakte liegen unverändert in /workspace/artifacts, vollständige ZIPs+Patches vorhanden. Neue Binaries unter /workspace/artifacts/0.8.37+87_main_1c2ee erzeugen; keine alten Dateien überschreiben.

---

# CODEX-CHECKPOINT – Würfelraunen

Stand **2026-10-24T03:20:14+00:00**, aktive Sitzung. Vollständige vorige Übergabe: [Historie](history/main_0.8.36_20261023/CODEX_CHECKPOINT.md). Vor Wiederaufnahme tatsächliches main, PRs und CI erneut abfragen.

## Git und Produkt

- Basis-main: `5958579e5321338bb7b4e46abb859fd3bfd1515f` (PR143 integriert).
- Arbeitsbranch: `feature/sneak-attack-ally-integration-20261023`.
- Formatnormalisierung: `309b07e`; funktionaler Code: `0a56aba7057dc12d80750759443f6d70ed510dc1`.
- Version: **0.8.37+87**, Android-Alpha. Auf GitHub gesichert; [PR147](https://github.com/ManuEtt/Dnd/pull/147) offen und konfliktfrei gegen Basis5958579. Veröffentlichter Dokumentationsstand vor Abschluss:182f44bee57a0b7531396fd2893cd7f077256179.
- Offener Fremd-PR bei Bestandsaufnahme: [144 / Sending](https://github.com/ManuEtt/Dnd/pull/144), nicht dupliziert.
- Vollständige Code-CI: [40056875863](https://github.com/ManuEtt/Dnd/actions/runs/40056875863), **completed/success** auf PR-HEAD `182f44bee57a0b7531396fd2893cd7f077256179`; geprüfter Merge-Teststand `de67cd3d0899c8aec351e3fcc77905179450080f`. Alle Projekt-/Backend-/Flutter-/Android-/Alpha-/Artefaktschritte erfolgreich. Der nachfolgende reine Dokumentationscommit enthält denselben ausführbaren Code. Aktuellen PR-HEAD und neueste Checks bei Wiederaufnahme erneut lesen.
- Letzter vollständig erfolgreicher Basisworkflow: [40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485), geprüftes SHA5958579. Kein Nachweis für neuen Code.

## IMPLEMENTIERT

Hinterhältiger Angriff mit manuell bestätigtem Verbündeten für einen offenen Hauptwaffenangriff. Beide Fakten (5Fuß zum Ziel, nicht Incapacitated) werden separat erfasst und an Kampagne/Ziel/Wurf gebunden. Vorbereitung würfelt nicht und verbraucht keine Ressourcen; erst der gültige Treffer erzeugt Zusatzwürfel und Nutzung. Entfernen, Krit, Miss und neue Probe sind angebunden. Keine aus KI-Text erfundenen Werte. Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt partial.

Import und Ausführung prüfen dieselbe Bindung, eigene Zugberechtigung, Finesse/Fernkampf und Nutzung. Gespeicherter Angriffsbonus kommt aus RulesEngine einschließlich Bogenschießen. Story darf pendingRoll nicht verändern. SQLite 2 und Kampagnen-JSON 1 bleiben erhalten; optionales PendingRoll.sneakAttackAlly hat nestedVersion1, Alt-JSON bleibt gültig.

Dateien: neue Domain `app/lib/domain/sneak_attack_ally_rules.dart`, Models, GameEngine, Controller, rules_api, Abenteuer-UI, neuer Dialog und zwei neue Testdateien; App-Version, CI-Formatgate, Requirement-Register und Statusdokumentation. Backend, Outbox und Berechtigungen unverändert.

## GETESTET

- Normalisierte Basis: scripts/check.sh vollständig erfolgreich; **1.431 Flutter-Tests**, **100 Python-Tests**, Backend-Typecheck/Build/**31 Tests**, Analyse und Formatierung.
- Android: Debug-APK erfolgreich aus dem geprüften ZIP gebaut; CRC, aapt-Metadaten/minSdk24/targetSdk36/Build 87, drei ABIs und apksigner-Signatur erfolgreich. **12 native JUnit-Tests** ohne Fehler, Gradle BUILD SUCCESSFUL. 461 Dateien zwischen ZIP, Buildkopie und Arbeitsstand per SHA256 identisch.
- ARM64-Alpha: 19.728.422 Bytes, Build 87 ohne ABI-Offset, CRC/Metadaten/Signatur erfolgreich.
- Neuer Code gezielt: **11 Domain-/SQLite-Tests** und **6 Widgettests** erfolgreich. Abgedeckt: vor Zufall validieren, Treffer/Miss/Krit, 1x-pro-Zug, Datenmanipulation, verbrauchte/fremde Ziele, Storygrenze, Neustart, Export/Import, Rekonstruktion, stale Dialog, verspäteter Eventfehler/Rollback, Abbruch, Eingabeentwurf, 360dp/Schrift1,8/Tastatur260dp.
- Neuer vollständiger Lauf erfolgreich: **1.448 Flutter-Tests**, Format 344-Dateien/Analyse ohne Befunde, Backend 31 und Python 100 erfolgreich.
- Prüfprotokolle: `/workspace/validation/20261023-sneak-full-check.log`, `20261023-sneak-domain.log`, `20261023-sneak-ally-ui-final.log`.

## NICHT GETESTET

Reales Gerät und sicherer App-Updatepfad nicht getestet. Die dokumentierte Code-CI ist vollständig grün; nachfolgende Dokumentationsstände sind getrennt zu identifizieren. Keine fremde grüne CI als neue Freigabe ausgeben.

## BLOCKIERT

Kein erreichbares Android-Realgerät und keine produktive Release-Signierung. Flutter3.35.7/Dart3.9.2, Node22.14, Java17 und Android-SDK sind lokal verfügbar; fehlende SDKs aus älteren Übergaben gelten hier nicht.

## NOCH NICHT IMPLEMENTIERT

Allgemeine Verbündeten-/Positionsverwaltung, bestätigter Nebenhandkontext und allgemeine Gelegenheitsangriffe; vollständiges SRD. Keine globale Abdeckungsquote (1.419 Prüfaufträge, neun Inventurlücken). Frühere Item-Arbeit separat in `/workspace/Dnd-current` und `/workspace/artifacts` gesichert; sie basiert auf b965efc und muss vor Übernahme mit neuerem main abgeglichen werden. Dort letzter Gesamtversuch: zwei überholte Python-Quellstring-Vertragstests fehlgeschlagen; kein neuer Android-Build behauptet.

## Noch laufender Abschluss / Artefakte

Gesamtlauf, Debug-APK und native Tests erfolgreich. Lokale Prüfungen und vollständige GitHub-Code-CI erfolgreich. Branch/PR147 sind erstellt. Abschließender Dokumentationsnachtrag, aktualisiertes Quell-ZIP/Patch und tatsächliche finale PR-Checks sind getrennt vom bereits geprüften Code zu sichern. Main nicht ungeprüft verändern. ZIP/Patch entstehen mit scripts/create_checkpoint.py gegen Basis5958579. Tatsächlich geprüftes Build-Quell-ZIP: `/workspace/artifacts/Wuerfelraunen_0.8.37+87_20261023T194739479771Z_sneak-attack-vor-android_Vollprojekt.zip`, SHA256 `3df17f778c328594ec093b3c9aebdceccd62d7f41ae00a7edb5a991f658fc832` (617 Dateien). Finales ZIP wird mit aktueller Dokumentation erneuert; Hash steht separat in SHA256SUMS.txt.

ARM64-Alpha: `/workspace/artifacts/Wuerfelraunen_0.8.37+87_arm64-v8a_Alpha.apk`, SHA256 `7347f06e25ce2fcf02f06c6d25ceef6f41c114dd3bc916dbf4118c5ed89d7f03`, Metadaten `Wuerfelraunen_0.8.37+87_ARM64_Alpha_Pruefung.json`. Releaseoptimierung mit derselben lokalen Debug-Testsignatur, keine Gerätefreigabe.

Debug-APK: `/workspace/artifacts/Wuerfelraunen_0.8.37+87_Debug.apk`, 144077056 Bytes, SHA256 `3d3ac043c4f9cbc2342fda8524cd6a0bccbdb0cc0e35eba3fc2ab8f642307fb7`. Metadaten: `Wuerfelraunen_0.8.37+87_APK_Pruefung.json`; Gesamtprotokoll: `Wuerfelraunen_0.8.37+87_Pruefergebnisse.json`. Workspace-Dateien sind keine behaupteten externen Uploads. Beobachtete GitHub-Artefakte aus grünem Lauf40056875863 (nicht abgelaufen):

- [Quell-ZIP](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546510086), GitHub-Archiv-Digest `eea30931ca5b8197a73fb6b57e039e74bf2914f3cf538f4b887bde18ccab499c`.
- [Drei Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546286030), GitHub-Archiv-Digest `32b497ac50103416f8a115bad20ac1bb5616ee84bc152481e87e9b31b3983d69`.
- [Versioniertes Alpha-Release-Paket](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546311528).
- [PR-Gesamtpatch](https://github.com/ManuEtt/Dnd/pull/147.diff); lokale versionierte ZIP/Patch/SHA256-Paare in /workspace/artifacts.

GitHub-Artefakte haben begrenzte Aufbewahrung und eigene Build-/Signaturherkunft. Ihre Digests gehören zum GitHub-Archiv, nicht zu den separat lokal gebauten Dateien. Import: [ARTIFACT_IMPORT_20261024.md](ARTIFACT_IMPORT_20261024.md).

## Genau ein nächster fachlicher Schritt

**Nebenhand-Sneak-Attack am tatsächlich angreifenden Inventargegenstand prüfen und bestätigen.** Akzeptanz: Finesse/Fernkampf der wirklichen Waffe, einmal pro Zug, fehlende Fakten ablehnen, separate Haupt-/Nebenhand, Krit und Miss, JSON/SQLite-Neustart, alte Hauptwaffenprobe unverändert. Gelegenheitsangriffe bleiben eigener Scope.

Prüfung: `bash scripts/check.sh`; `python3 scripts/check_domain_boundaries.py`; `python3 scripts/srd_coverage.py --json`; `cd app && flutter build apk --debug`; `cd android && bash ./gradlew :app:testDebugUnitTest --no-daemon`. SDK-/SQLite-Pfade dieser Umgebung: `/workspace/validation/TOOLCHAIN.md`.

Keine automatische Wiederaufnahme außerhalb einer tatsächlich laufenden Sitzung.


## Übernommener Status aus Main145 (historisch)

## Zyklus 2026-10-23 (Europe/Berlin) – Widersprüchliche XP-Belohnungs-ID ablehnen (PR-/CI-Prüfung)

- **LIVE-BASIS:** `main` `5958579e5321338bb7b4e46abb859fd3bfd1515f`, GitHub Actions [#40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485) **completed / success** ausschließlich auf diesem Main-SHA. Bei Beginn war [PR #144](https://github.com/ManuEtt/Dnd/pull/144) zum Zauber `Sending` offen; dessen [CI #40012034969](https://github.com/ManuEtt/Dnd/actions/runs/40012034969) erfolgreich für einen **anderen** Code-HEAD. Arbeitsbranch `fix/xp-reward-id-conflict-20261023`, Ausgangsversion `0.8.36+86`; kein paralleler Versionssprung wegen offenem PR #144.
- **IMPLEMENTIERT:** `ExperienceProgression.grant` bestätigt eine wiederholte ID nur noch bei **exakt gleichem** bereits gespeicherten XP-Betrag; abweichende oder unlesbare Bestandswerte führen zu `FormatException` ohne Zustandsänderung. Bekannte identische Bestätigungen bleiben idempotent. **Kein geänderter SRD-Mechanismus:** Es handelt sich um Konsistenzprüfung der lokalen Belohnungsbelege.
- **TESTS GESCHRIEBEN:** `app/test/experience_progression_test.dart` – bestätigte Duplikate nach JSON-Roundtrip, ID-Kollision mit abweichendem Betrag und manipulierter Legacy-Beleg ohne Veränderung von Held/XP/Fakten. Die lokale Ausführungsumgebung hat **kein Dart-/Flutter-SDK**; Tests werden erst nach tatsächlichem erfolgreichem CI-Lauf als bestanden bezeichnet.
- **KOMPATIBILITÄT:** SQLite-Schema 2 und Kampagnen-JSON `schemaVersion=1` unverändert, kein KI-Provider, keine Migration. Widersprüchliche Altdaten werden nicht automatisch überschrieben.
- **GETESTET:** Main-CI #40012217485 nur als Vorher-Baseline. **NICHT GETESTET:** Neue Branch-CI und Android-Gerät bis eindeutige Ergebnisse vorliegen. **BLOCKIERT:** Lokale Flutter-/Android-/Geräteprüfungen mangels SDK/Gerät. **NOCH NICHT IMPLEMENTIERT:** Vollständige SRD-5.2.1-Regelabdeckung sowie Validierung externer Erzählungs-/Belohnungsquellen.
- **NÄCHSTER KONKRETER SCHRITT:** Den PR-Workflow auf dem **finalen** Branch-SHA auswerten und Fehler beheben; anschließend separat eine bestätigte, revidierbare XP-Belohnungsaktion von GameEngine/GameController bis SQLite-Journal auf Doppel-IDs und Neustart prüfen. Keine automatische Integration in `main` ohne PR-Abnahme.

---
