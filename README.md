# Würfelraunen – Der lebendige Spielleiter

**Deutschsprachige Android-Fantasy-Rollenspiel-App mit Soloabenteuern, Charakterverwaltung, D&D-Regelunterstützung und optionalem KI-Erzähler.**

> **Projektstatus (23. Oktober 2026):** Aktive **Android-Alpha**. der Ausgangs-`main`-Stand dieses Zyklus trägt Version **0.8.33+83** (`4061d651`, CI #39967425937 noch offen), der neue Entwicklungsbranch Version **0.8.34+84** mit erfolgreich geprüfter [PR-CI #39946157697](https://github.com/ManuEtt/Dnd/actions/runs/39946157697). Keiner dieser Läufe belegt einen echten Geräte-Test oder ein vollständiges SRD-5.2.1-Regelwerk.

## Aktueller Stand und autonome Fortsetzung (23.10.2026)

> **Entwicklungszyklus 6 – 23.10.2026, Version `0.8.34+84` (neuer PR-Branch):** `AtomicCampaignDeletion` verhindert, dass beim Löschen einer Kampagne ein veralteter `lastCampaignId`-Verweis gespeichert bleibt oder eine parallel neu gewählte Kampagne überschrieben wird. Kampagne, ausstehende Handlung und gegebenenfalls die gespeicherte Auswahl werden in derselben SQLite-Transaktion aktualisiert; die übrigen Einstellungen bleiben erhalten. Neue Tests prüfen mehrere SQLite-Verbindungen, Neustart und einen gezielt ausgelösten Rollback. **Neue CI steht aus; reale Android-Geräteabnahme offen.** Zu Beginn dieses Pakets stand `main` auf `4061d651`, mit noch laufender [Main-CI #39967425937](https://github.com/ManuEtt/Dnd/actions/runs/39967425937). Die PRs #133–#136 sind inzwischen integriert; der vorherige reine Test-PR #137 wurde ohne Merge geschlossen. SQLite-Schema 2 und Kampagnen-JSON-Version 1 bleiben unverändert.


> **Entwicklungszyklus 3 (23.10.2026, Version `0.8.33+83`, [PR #136](https://github.com/ManuEtt/Dnd/pull/136)):** Der vollständige Datenreset entfernt Kampagnen, Revisionsjournal, Spielereignisse, Charakterarchiv, Einstellungen und offene Spielerhandlungen jetzt in **einer SQLite-Transaktion**. Bei Abbruch bleiben alle ursprünglichen Daten erhalten; ein zweiter Löschversuch und Neustart sind getestet. Die erste CI fand einen Fehler in der Testverbindung; nach dessen Behebung sind **sämtliche Tests und Android-APK-Builds erfolgreich**: [GitHub Actions #39946157697](https://github.com/ManuEtt/Dnd/actions/runs/39946157697) auf Head `0145108c57c562e3a6635a2ea6440d4649278222`. [Alpha- und Quellcode-Artefakte](https://github.com/ManuEtt/Dnd/actions/runs/39946157697) sind verfügbar. **Nicht geprüft:** Realgerät, altes Android-Update, langfristige Release-Signierung. #136 baut auf den offenen PRs #133–#135 auf und ist nicht in `main` integriert. Nächster Schritt: Reviews/Merges der PR-Reihe und reale Geräteabnahme.


> **Entwicklungszyklus 2 (23.10.2026, Version `0.8.32+82`, Branch `fix/atomic-settings-updates-20261023`):** SQLite übernimmt jetzt **atomare Teilupdates** für Spracheinstellungen, zuletzt gewählte Kampagne und Backend-Präferenzen. Die Änderungen schützen verschiedene Felder vor gegenseitigem Überschreiben bei paralleler Speicherung, ohne Datenbankschema 2 oder das JSON-Spielstandsformat zu ändern. Neue Tests prüfen konkurrierende SQLite-Verbindungen, Rollback, Neustart und unveränderte Outbox. Zusätzlich beseitigt PR #135 einen Datenreset-Fehler: Das Löschen einzelner Kampagnen bzw. aller App-Daten bereinigt jetzt die eigenständige Outbox mit, ohne andere Kampagnenaufträge zu löschen. **CI dieser neuen Änderungen ist bis zum erfolgreichen finalen Workflow noch nicht nachgewiesen; die zuvor bestandene #134-CI [#39940517928](https://github.com/ManuEtt/Dnd/actions/runs/39940517928) betrifft ausschließlich den bisherigen Code-HEAD `8162388e`.** Nächster Schritt: vollständige neue CI, gestapelte Pull Requests nach Review integrieren, danach reale Android-Upgrade-/Sicherungsprüfung.


> **Entwicklungspaket 23.10.2026 – Version 0.8.31+81, [PR #134](https://github.com/ManuEtt/Dnd/pull/134):** Pending-Spielerhandlungen sind in einer eigenständigen transaktionalen SQLite-Outbox gespeichert; die Datenbankmigration **1 → 2** bewahrt gültige ältere Aufträge (Request-ID/Text) und übrige Einstellungen, bei beschädigtem Legacy-Auftrag erfolgt kein stiller Verlust. Regressionstests für parallele SQLite-Verbindungen, Settings-Kollisionen und Altstand-Neustarts sind enthalten. **Vollständige Code-CI [#39938760852](https://github.com/ManuEtt/Dnd/actions/runs/39938760852) ist auf SHA `1ca83e63c5d78c84b1babebcc15c0a392725b7a3` erfolgreich**: Python, Backend, Dart/Flutter, native Android-Tests, Debug- und ABI-Alpha-APKs samt Quellcode-Artefakten. **Nicht abgenommen:** Installation/Update mit echtem Android-Altspielstand und produktive Signierung. PR #134 ist von offenem Docs-PR #133 abhängig und bleibt bis Integration/aktueller CI als Review-PR offen. Der nachträgliche reine Markdown-Status-Commit ist nicht identisch mit dem getesteten Code-SHA. **Nächster Schritt:** PR #133 integrieren, #134 auf `main` neu prüfen; danach atomare Einstellungen-Teilupdates mit konkurrierenden Schreibtests.


**Neuer Einstieg für Codex:** [`docs/CODEX_CONTINUATION_PROMPT.md`](docs/CODEX_CONTINUATION_PROMPT.md) ist die aktuelle, direkt verwendbare Entwicklungsanweisung. Sie startet mit einer neuen Git-/CI-Bestandsaufnahme, wählt **ein** überprüfbares Arbeitspaket, setzt es einschließlich Regel-/Story-/UI-/Android-Tests um und aktualisiert am Zyklusende **Checkpoint und README**. Der ältere [Master-Prompt](docs/CODEX_MASTER_PROMPT.md) beschreibt historische Langfristziele; tatsächliche GitHub-Fakten dürfen daraus nicht ungeprüft übernommen werden.

**Lebender Übergabe-Checkpoint:** [`docs/CODEX_CHECKPOINT.md`](docs/CODEX_CHECKPOINT.md). Darin stehen der letzte beobachtete Main-HEAD und CI-Nachweis, abgeschlossene Funktionen, ausdrücklich nicht getestete Teile, Risiken, Blocker und der **konkrete nächste Entwicklungsschritt**. Codex muss diesen Checkpoint nach jedem aktiven Entwicklungszyklus aktualisieren. [`CHECKPOINT.md`](CHECKPOINT.md) bleibt als ältere technische Entwicklungschronik erhalten. Ein Checkpoint ist **kein** Ersatz für ein tatsächliches Quell-ZIP oder eine erfolgreiche APK.

**Zuletzt integrierte Stabilisierung:** PRs [#128](https://github.com/ManuEtt/Dnd/pull/128)–[#132](https://github.com/ManuEtt/Dnd/pull/132) ergänzen kontextgeprüfte Schnellaktionen, idempotente Handlungskennungen, das dauerhafte Wiederaufnehmen ausstehender Aktionen, UI-/SQLite-Regressionstests und den Abgleich paralleler Bestätigungen. Ein verloren gegangenes Spieler-Action-Acknowledgement soll **keine zweite bestätigte Regelaktion** auslösen. Ein externer KI-Provider ist damit **nicht** kosten-idempotent; vor Commit erfolgte Anfrage kann bei bewusster Wiederholung erneut kosten.

**Empfohlenes nächstes Arbeitsziel:** die bisher im Settings-JSON liegende Outbox bei konkurrierenden Einstellungen-Schreibern transaktional absichern, inklusive Alt-SQLite-Migration, Rollback-/Neustart-Tests und grünem Android-CI-Nachweis. Stellt Codex beim Neustart wichtigere rote CI-Fehler fest, haben diese Vorrang. Das vollständige D&D-SRD 5.2.1, universelles NPC-Langzeitgedächtnis, Geräteabnahme und produktive Signierung bleiben offene Arbeit.

**Ausführung:** Ein Codex-Agent arbeitet nur innerhalb einer gestarteten Sitzung mit tatsächlichem Repository-Zugriff selbstständig. Dieses Repository führt bewusst **keine unbeaufsichtigte kostenpflichtige Codex-Entwicklung in GitHub Actions** aus. Die Actions dienen Builds, Tests und validierten ZIP-/APK-Artefakten. Für rein dokumentarische PRs startet die normale Android-CI wegen ihrer Pfadfilter nicht automatisch.

## GitHub-Branch-Bereinigung (20.10.2026)

**Branch-Bereinigung verifiziert (20.10.2026):** Alle neun historischen Feature-/Dokumentationsbranches waren bereits in `main` enthalten (`ahead_by=0`) und wurden über den geprüften einmaligen [GitHub-Actions-Lauf #39392381240](https://github.com/ManuEtt/Dnd/actions/runs/39392381240) entfernt. Auch der kurzlebige Maintenance-Branch ist gelöscht. Die GitHub-Branchliste wurde danach erneut gelesen: **nur `main` vorhanden**. Implementierte Features, Merge-Commits und Pull Requests bleiben erhalten; nichts wurde neu gecherry-pickt. Der temporäre Löschworkflow wurde nach erfolgreicher Bereinigung aus dem Hauptbranch entfernt. Prüfdokument: [`docs/BRANCH_RETIREMENT_20261020.md`](docs/BRANCH_RETIREMENT_20261020.md).

**Branch-Konsolidierung:** Der Feature-Branch aus PR #52 wurde nach erfolgreichem Merge über [GitHub Actions #39422591208](https://github.com/ManuEtt/Dnd/actions/runs/39422591208) sicher gelöscht. Die erneute GitHub-Branchliste zeigt ausschließlich `main`. Die privilegierte einmalige Bereinigungsaktion wurde anschließend entfernt.

## Neue SRD-Regeln 0.8.21+71: bestätigte Mehrfachangriffe

Gegner können nach ausdrücklicher Auswahl im Kampfmenü **1 bis 4 Angriffe je Zug** durchführen. Jeder Angriff wird einzeln geprüft; ein Treffer kann weiterhin die echte Schild-Reaktionsentscheidung auslösen. Ein bereits gewirkter Schild schützt mit **+5 Rüstungsklasse** vor weiteren Angriffen dieses Gegnerzuges und kostet keinen zweiten Zauberplatz. Die Kampfoberfläche bietet „Gegnerangriff fortsetzen“, bis der Gegnerzug abgeschlossen ist. Fortschritt und Schilddauer werden gespeichert. **CI- und Merge-Abnahme (20.10.2026):** SRD-Inkrement `0.8.21+71` über [PR #52](https://github.com/ManuEtt/Dnd/pull/52) erfolgreich nach `main` integriert. [GitHub-Actions-CI #39421141308](https://github.com/ManuEtt/Dnd/actions/runs/39421141308) auf finalem Code-HEAD `9156b972d240de4c5a588c09ebb5ac8adeca99ad`: **success**, inklusive Python-/Strukturtests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Tests, Alpha-APK-Pakete und Checkpoint-Artefakt. Merge-Commit [`b87e53591df75bc40b9e9f534529666fb168c6f3`](https://github.com/ManuEtt/Dnd/commit/b87e53591df75bc40b9e9f534529666fb168c6f3). **Nicht getestet:** echte Android-Geräteinstallation; mehrere unabhängige Monster und unterschiedliche Attackenprofile; vollständige SRD-Abdeckung.

## SRD 5.2.1: echte Schildwahl nach Angriffstreffer (20.10.2026)

**Version 0.8.20+70:** Der Gegner würfelt zuerst. Bei einem tatsächlich treffenden Angriff wird der Zustand ohne Schadenswurf gespeichert und eine Entscheidung angezeigt: **Schild wirken oder Treffer hinnehmen**. Der Spieler sieht das Angriffsergebnis. Ein bestätigter Schildzauber verbraucht einen Zauberplatz, selbst wenn ein kritischer Treffer oder sehr hoher Wurf trotz +5 RK trifft. Das ursprüngliche W20-Ergebnis wird ohne erneutes Würfeln fortgesetzt. Die neue Auswahl unterstützt SQLite-Neustart und Revisionsschutz. **CI bestätigt (20.10.2026):** [PR #51](https://github.com/ManuEtt/Dnd/pull/51) wurde nach vollständig erfolgreicher [GitHub-Actions-CI #39406260656](https://github.com/ManuEtt/Dnd/actions/runs/39406260656) mit Code-HEAD `011c53826956e609994930c65221bca9c33d9985` nach `main` integriert. Merge-Commit [`ff1b043652e46a99c4ac3038698d047fb0d3f380`](https://github.com/ManuEtt/Dnd/commit/ff1b043652e46a99c4ac3038698d047fb0d3f380). Erfolgreich: Python-Strukturtests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Unit-Tests, Alpha-APK-Erstellung und Build-Artefakte. **Echter Android-Gerätetest, Mehrfachgegner/Mehrfachattacken und Shield gegen gegnerisches Magisches Geschoss bleiben offen.** Mehrere Gegner/Angriffe bleiben noch offen.

## Inhaltsverzeichnis

- [Aktueller Stand und autonome Fortsetzung](#aktueller-stand-und-autonome-fortsetzung-23102026)
- [Funktionsstand](#funktionsstand)
- [Klassenaufstieg und Erfahrungspunkte](#klassenaufstieg-und-erfahrungspunkte)
- [Technik und Projektstruktur](#technik-und-projektstruktur)
- [Projekt lokal starten und testen](#projekt-lokal-starten-und-testen)
- [Build- und Teststand](#build--und-teststand)
- [Bekannte Grenzen und nächste Schritte](#bekannte-grenzen-und-nächste-schritte)
- [Regelgrundlage, Dokumentation und Chronik](#regelgrundlage-dokumentation-und-chronik)

## Neues SRD-Regelpaket: bedingte Schildreaktion des Helden (20.10.2026)

**Version `0.8.19+69`:** Der Spieler kann beim Beenden seines Kampfzugs ausdrücklich **Schild als bedingte Reaktion** gegen den unmittelbar folgenden Gegnerangriff freigeben. Nur wenn die Attacke trifft und der RK-Bonus von +5 sie abwehren würde, wird der bekannte Zauber mit validierten Komponenten und einem vorhandenen Zauberplatz gewirkt. Andernfalls bleiben sämtliche Ressourcen erhalten; bestehende Spielstände bleiben kompatibel. Neue Domain-/SQLite-Tests und Dialog sind vorhanden. **Vollständige CI dieses Inkrements bestanden (Lauf #39394683773); Android-Gerätetest offen.** Es handelt sich noch nicht um eine allgemeine, nach dem Treffer interaktiv bestätigte Reaktionsengine.

## SRD-Inkrement: Shield als bestätigte Gegnerreaktion (20.10.2026)

**Version 0.8.18+68** führt gegnerische Schildzauber-Reaktionen auf Magisches Geschoss aus: Der Spielende muss Vorbereitung, Komponenten, freie Reaktion und den tatsächlich verfügbaren gegnerischen Zauberplatz bestätigen. Die Regelengine bucht gegnerischen und eigenen Platz, verhindert den Zauberschaden ohne Schadenswürfel und speichert den aktiven Schild (+5 RK) bis zum Beginn des nächsten Gegnerzuges. Alte Speicherstände ohne gegnerische Zauberplätze bleiben ausdrücklich unbekannt. Die neue UI und SQLite-/Domain-Tests sind im Feature-Branch enthalten. **CI und Merge bestätigt (20.10.2026):** [PR #46](https://github.com/ManuEtt/Dnd/pull/46) nach grünem [GitHub-Actions-Lauf #39386823499](https://github.com/ManuEtt/Dnd/actions/runs/39386823499), geprüfter Code-HEAD `81635c8eccb0d06e5d1bf95d54f5884c62f4a215`, erfolgreich in `main` integriert. Merge-Commit [`45160602b339c35e23e0d445f4e41e98b9b3dd5e`](https://github.com/ManuEtt/Dnd/commit/45160602b339c35e23e0d445f4e41e98b9b3dd5e). Erfolgreich: Struktur-/Python-Prüfung, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Unit-Tests, Alpha-APK-Artefakte und Quellcode-Checkpoint. **Noch offen:** echter Android-Gerätetest, vollständiges SRD, Held-Shield-Reaktion und verifizierte Gegner-Zauberlisten.

## Nächstes SRD-Inkrement: Gegnerabwehr gegen Magisches Geschoss (20.10.2026)

Die neue Version `0.8.17+67` speichert ausdrücklich bestätigte Gegner-Resistenzen, -Immunitäten und -Verwundbarkeiten gegen Energieschaden. Jeder Geschoss-Schadenswurf wird **separat** über die bestehende getypte Schadensregelengine berechnet; die Bestätigung kann im Zauberdialog gewählt und im Begegnungsspeicher wiederverwendet werden. Ein Altspielstand ohne Angaben bleibt ausdrücklich **unbekannt**. Die fehlende Shield-Reaktionslogik wird nicht erfunden: Der Spieler muss weiterhin das Fehlen eines wirksamen Schildzaubers bestätigen. Domain-, Widget- und SQLite-Regressionstests liegen im Branch vor. **GitHub-CI für diesen Commit bestanden; echter Android-Gerätetest weiterhin offen**; grüne frühere Läufe betreffen nur 0.8.16+66.

## Neues SRD-5.2.1-Inkrement: Magisches Geschoss (20.10.2026)

Die Flutter-Version ist `0.8.16+66`. Implementiert sind die **tatsächlichen Würfel- und Schadensregeln** für Magisches Geschoss (`Magic Missile`): bei einem Zauberplatz Grad 1 drei Geschosse, je höherem Platz ein weiteres, je Geschoss `1W4+1` Energieschaden. Die neue Kampfaktion validiert bekannte Zauber, Zauberklasse und Plätze, Magieaktion, Sicht und 120-Fuß-Reichweite, Komponenten, vollständige Deckung und ausdrücklich bestätigte fehlende Schutzwirkung des einzigen gegnerischen Ziels. Gegner-TP, Zauberplätze und Ereignisse werden zusammen mit Revisionsschutz gespeichert; unbestätigte KI-Angaben ändern keine Kampfwerte. UI, Domain-/Widget- und SQLite-Tests sind im Entwicklungsbranch enthalten.

**CI und Integration bestätigt (20.10.2026):** [PR #42](https://github.com/ManuEtt/Dnd/pull/42) wurde nach vollständig erfolgreicher [GitHub Actions CI #39381087593](https://github.com/ManuEtt/Dnd/actions/runs/39381087593) (geprüfter Head `78d89230281f8196edbff628ca243d591ef092b3`) nach `main` integriert. Merge-Commit: [`259dcf69fa2471c5546e1ba1b1003cef148e1cb9`](https://github.com/ManuEtt/Dnd/commit/259dcf69fa2471c5546e1ba1b1003cef148e1cb9). Erfolgreich: Python-Projektprüfung, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse/Tests, Android-Debug-APK, native JVM-Tests, drei Alpha-APK-Varianten und Artefaktbereitstellung. **Ein realer Gerätefunktionstest und die vollständige SRD-5.2.1-Abdeckung bleiben offen.** Vollständige Gegnerimmunitäten, Schildzauber, Entfernungen anhand einer Karte und Verteilung auf mehrere Ziele bleiben unimplementiert. [SRD-Matrix](docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md) und [Entwicklungsstatus](DEVELOPMENT_STATUS.md) beschreiben die Grenzen.

## Erstes SRD-5.2.1-Inkrement: Kriechen (20.10.2026)

**Version 0.8.15+65 – Entwicklungsbranch `feature/srd-crawling-20261020`**, Basis-`main` `f06fb2ffac476ceec0dee2a4c6979d972e0c1a72`, Code-Commit `72f51dd0b`, Test-Commit `4b0154dc8`. In der Abenteueransicht kann ein **liegender Held** im aktiven eigenen Kampfzug 1,5 oder 3 m kriechen und normales beziehungsweise schwieriges Gelände ausdrücklich bestätigen. Die Regelengine berechnet Bewegungskosten von **2 oder 3 Fuß pro Fuß**; unzureichende Bewegung, blockierende Zustände, fremde Züge und offene Proben werden abgewiesen. Bewegung und `combat.crawled`-Ereignis werden mit Revisionsschutz atomar gespeichert, ohne den Status „Liegend“ aufzuheben. Die bisherige Deckungsposition endet.

**Abnahme nach Merge:** [PR #40](https://github.com/ManuEtt/Dnd/pull/40) vollständig über [CI-Lauf 39378443958](https://github.com/ManuEtt/Dnd/actions/runs/39378443958) am Code-HEAD `3462106592157953473c7d777b0d5b664872243a` mit **success** geprüft: Projekt-/Python-Strukturtests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Unit-Tests, drei Alpha-APK-Varianten und Artefakterstellung. Am 20.10.2026 konfliktfrei nach `main` gemergt: [`f7c6a68c09155880fd9a08b0c2f308d324b27b82`](https://github.com/ManuEtt/Dnd/commit/f7c6a68c09155880fd9a08b0c2f308d324b27b82). **Nicht geprüft:** echter Android-Gerätetest, Langzeitmigration auf Nutzergeräten, vollständiges SRD-Regelwerk. Ein vollständiges SRD-5.2.1-Regelwerk ist weiterhin nicht implementiert. Siehe `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md`, `DEVELOPMENT_STATUS.md`, `CHANGELOG.md` und `CHECKPOINT.md`.

## Funktionsstand

| Bereich | Aktueller Stand |
| --- | --- |
| **Android-Oberfläche** | Deutsche Flutter-Oberfläche in Fantasy-Optik mit Charakterbogen, Heldenverwaltung, Porträts, Abenteuer-/Kampagnenansicht und Schnellaktionen. Layout-/Grafiktests vorhanden; reale Geräteabnahme weiterhin nötig. |
| **Solo-Abenteuer** | Lokaler Demo-Spielleiter und vorgefertigte Kampagne **Rabenwacht** mit Szenen, NPCs, Entscheidungen, Journal und mehreren möglichen Ausgängen. Der geplante Umfang von 2–3 Stunden ist kein gemessener Mindestwert. |
| **Spielstand und Gedächtnis** | Kampagnen-, Charakter- und Ereignisdaten lokal mit SQLite, versioniertem JSON-Import/-Export und bestätigten Zustandsänderungen. Historische unbekannte Werte werden nicht ungefragt erfunden. |
| **Charaktererstellung** | Unterstützung der zwölf SRD-5.2.1-Klassen, Attributswerte, ausgewählter Hintergründe, Ausrüstung, Kampfgrundwerte und Klassenwahlen. **Nicht alle Optionen und Regeleffekte sind automatisiert.** |
| **Klassenaufstieg** | Gesamtstufe 1–20, Haupt-/bestehende Zweitklasse, einzelne bestätigte Aufstiege, Trefferpunkte, Übungsbonus, ausgewählte Unterklassen und zulässige Attributsverbesserungen; offene Regeln bleiben markiert. |
| **Erfahrungspunkte** | Kumulative XP, SRD-Schwellen, Fortschrittsbalken, wiederholungsfeste bestätigte Kampagnenbelohnungen und mehrere **einzeln zu bestätigende** Aufstiege bei XP-Überschuss. |
| **Kampf und Regeln** | Regelengine mit Würfelproben, Teilen der Angriffs-/Schadens-/Zustands-/Rast-/Zauber- und Klassenressourcenregeln. Die [Regelabdeckung](docs/RULE_COVERAGE.md) ist nur **teilweise** vollständig. |
| **Sprache und KI** | Gerätebasierte Spracherkennung und Sprachausgabe; optionaler Fastify-/TypeScript-Erzähler-Backenddienst. Eine kostenlose lokale Demo ist ohne externen KI-Dienst möglich. Geräte- und Anbieterfunktionen können zusätzliche Berechtigungen/Verbindungen erfordern. |
| **Grafiken** | Lokale Fantasy-Motive, Goldornamente und Charakterporträts; eigene Porträtbilder über den Android-Bildwähler. Einzelne hochauflösende Originalassets und reale Anzeigeprüfungen sind noch offen. |

### Grundprinzip der Spielleitung

**Erzähltext verändert niemals eigenmächtig den Regelzustand.** Würfel, Trefferpunkte, Gegenstände, Ressourcen, Erfahrungspunkte und bestätigte Spielereignisse werden von der lokalen Regelengine geprüft und gespeichert. Der optionale KI-Erzähler darf Erzählungen und validierte Story-Vorschläge liefern, aber keine ungeprüften Kampf- oder Inventarwerte setzen.

## Klassenaufstieg und Erfahrungspunkte

**Letzter funktionaler Ausbau:** [Pull Request #39](https://github.com/ManuEtt/Dnd/pull/39), am **20.10.2026** nach `main` übernommen (Merge-Commit `25dab9b3cb38ff3342422b8d25f516cae2aed38a`).

Neu beziehungsweise jetzt gemeinsam integriert:

- XP-Schwellen nach **SRD 5.2.1** und eine einheitliche Berechnung von erreichbarer Stufe, bis zur nächsten Stufe fehlenden XP und Fortschrittsanzeige.
- Bei ausreichend XP für mehrere Stufen kann der Charakter im Editor **mehrmals nacheinander** aufsteigen, ohne nach jeder Stufe separat zu speichern. **Jede Zwischenstufe wird einzeln bestätigt**; weder XP noch Stufen werden automatisch verbucht.
- Vorschau des Zuwachses an **aktuellen und maximalen Trefferpunkten** sowie des **Übungsbonus** vor dem Aufstieg.
- Heldenübersicht, Abenteuer-HUD und Kampagnenerzählung können **mehrere verfügbare Aufstiege** anzeigen.
- Der Aufstiegsassistent erlaubt **Erfahrung** oder ausdrücklich gewählte **Meilensteine**. Unzulässige Stufen, unbestätigte Werte und veraltete Vorschläge werden zurückgewiesen.
- Die Hauptklasse und eine bereits gewählte Zweitklasse besitzen eigene Klassenstufen. Unterklassenwahl und Attributsverbesserungen erfolgen nur dort, wo das hinterlegte SRD-Regelmodell sie zulässt.
- XP bleiben beim Klassenaufstieg **erhalten**. Unbekannte historische XP gelten nicht stillschweigend als null; Kampagnenbelohnungen werden nicht mehrfach gutgeschrieben.

**Beispiel:** Ein Held auf Gesamtstufe 1 mit **900 XP** kann Stufe 2 und anschließend Stufe 3 **separat** bestätigen. Die 900 XP werden nicht verbraucht. Neue Merkmals-/Unterklassenentscheidungen, die noch nicht automatisch regelkonform aufgelöst werden können, bleiben sichtbar offen.

Die 20 Stufen und zwölf Klassen sind als Regelgrundgerüst vorhanden. Ein Eintrag im Klassenmerkmalskatalog ist **kein Beweis**, dass die dazugehörige aktive Wirkung vollständig implementiert ist. Weitere Details: [`docs/LEVEL_UP_0_8_9.md`](docs/LEVEL_UP_0_8_9.md) und [SRD-Anforderungsmatrix](docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md).

## Technik und Projektstruktur

| Pfad | Inhalt |
| --- | --- |
| [`app/`](app/) | Flutter-/Dart-Anwendung für Android mit Oberfläche, Domänen-/Regelengine, SQLite, Geräteintegration und Tests |
| [`backend/`](backend/) | Optionaler Fastify-/TypeScript-Erzählserver, Mock- und optionale KI-Anbindung, serverseitige Zugriffskontrolle |
| [`scripts/`](scripts/) | Strukturprüfung, Paketierung, Checkpoints und Release-Hilfsprogramme |
| [`.github/workflows/`](.github/workflows/) | CI, Tests und Android-Alpha-Builds |
| [`docs/`](docs/) | Architektur-, Regel-, Bedienungs-, Grafik-, Test- und Migrationsdokumentation |

**CI-Toolchain:** Flutter **3.35.7**, Dart **3.9.2**, Java **17** und Node.js **22.14.0**. Die Flutter-App nutzt unter anderem `sqflite`, `flutter_tts`, `speech_to_text` und `image_picker`. Der optionale Server verwendet Fastify und TypeScript. Die jeweils maßgeblichen Abhängigkeiten stehen in [`app/pubspec.yaml`](app/pubspec.yaml) und [`backend/package.json`](backend/package.json).

## Projekt lokal starten und testen

### Android-App

Flutter und Android-SDK entsprechend der [Flutter-Installationsanleitung](https://docs.flutter.dev/get-started/install) bereitstellen, dann im Repository ausführen:

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

Eine lokale Debug-APK lässt sich mit folgendem Befehl bauen:

```bash
cd app
flutter build apk --debug
```

**Hinweis:** Ein erfolgreicher CI-APK-Build ersetzt keine Installation und keinen Funktionstest auf einem echten Android-Gerät.

### Optionalen Backend-Erzähler starten

Node.js ab 22.14 installieren. Der Backenddienst ist für die lokale Demo **nicht notwendig**:

```bash
cd backend
npm ci
npm run typecheck
npm run build
npm test
```

Für den tatsächlichen Serverbetrieb die [Backend-Anleitung](backend/README.md) und die [Verbindungsanleitung](docs/BACKEND_CONNECTION.md) beachten. Zugangstoken, `OPENAI_API_KEY` und andere Schlüssel **niemals** ins Repository oder in die APK schreiben. Ein kostenpflichtiger KI-Anbieter wird nur mit ausdrücklicher Konfiguration verwendet.

### Zusätzliche Projektprüfungen

```bash
python3 scripts/verify_project.py
python3 -m unittest discover -s scripts/tests -v
```

Auf Linux benötigen die SQLite-Tests gegebenenfalls `libsqlite3-dev`. Weitere Details: [`TESTING.md`](TESTING.md) und [`AGENTS.md`](AGENTS.md).

## Build- und Teststand

**Aktuelle CI-Abnahme auf `main` (23.10.2026):** [Android-Alpha GitHub Actions #39932399488](https://github.com/ManuEtt/Dnd/actions/runs/39932399488) für [Commit `b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9`](https://github.com/ManuEtt/Dnd/commit/b1fa9c67b2ee0eec9571c2bdf25e52a8ec8349d9) **completed / success**. Projekt-/Python-Prüfungen, Backend-Typen/Build/Tests, Dart-Format, Flutter-Analyse und -Tests, Android-Debug-APK, native Android-Unit-Tests, ARM64/ARM/x64-Alpha-APKs und Release-/Quell-ZIP-Artefakt-Schritte wurden erfolgreich ausgeführt. Ohne separaten Gerätetest keine Gerätefreigabe.

### Historische CI-Einträge (Stand 20.10.2026)

**Letzter erfolgreicher Code-CI-Lauf (0.8.20+70):** [#39406260656](https://github.com/ManuEtt/Dnd/actions/runs/39406260656) auf finalem PR-Head `011c53826956e609994930c65221bca9c33d9985` und Merge `ff1b043652e46a99c4ac3038698d047fb0d3f380`. Flutter, Backend, Python, Android-Debug, native Unit-Tests und Alpha-APKs bestanden. Gerätetest offen. Diese zusätzliche Statusaktualisierung enthält nur Markdown.


**Neuester vollständig grüner Workflow für 0.8.19+69:** [#39394683773](https://github.com/ManuEtt/Dnd/actions/runs/39394683773), finaler Code-HEAD `090adb4c5fe21ddfc83d0903d5ef39181c50dd9f`, [PR #49](https://github.com/ManuEtt/Dnd/pull/49) gemergt nach `main` (Merge `95792bb241c6123e34a1fae97c9fdef31d153ce2`). Alle Projekt-, Backend-, Flutter-, Android-JVM- und APK-Prüfungen grün; realer Android-Gerätetest noch offen.


**Aktuellster vollständig erfolgreicher Code-CI-Lauf für 0.8.18+68:** [#39386823499](https://github.com/ManuEtt/Dnd/actions/runs/39386823499) auf finalem PR-HEAD `81635c8eccb0d06e5d1bf95d54f5884c62f4a215`, danach Merge nach `main` (`45160602b339c35e23e0d445f4e41e98b9b3dd5e`). Flutter, Backend, Python, native Android-Tests und APK-Builds bestanden. Keine reale Geräteabnahme; der spätere reine Markdown-Nachtrag ändert keinen ausführbaren Code.


**0.8.17+67 verifiziert:** [CI #39383477544](https://github.com/ManuEtt/Dnd/actions/runs/39383477544) (Code-HEAD `8f703b0002ae6dcb5279893020bea63e14771184`), PR #44, Merge `fa2ee36caff2c210eabaa651321b9591de46737f`. Python, Backend, Flutter, Android-JVM und Android-APKs grün. Reale Geräteabnahme steht aus.


**Neuester geprüfter Workflow für 0.8.16+66:** [39381087593](https://github.com/ManuEtt/Dnd/actions/runs/39381087593) ist auf dem finalen Code-HEAD von PR #42 vollständig grün (Flutter, Backend, Android-Debug, native Android-Tests und Alpha-APKs). Integration: `259dcf69fa2471c5546e1ba1b1003cef148e1cb9`. Kein realer Gerätetest. Der Dokumentationsnachtrag selbst enthält ausschließlich Markdown und verändert keine Builds.


**Neuester nachgewiesener vollständiger CI-Lauf für 0.8.15+65:** [39378443958](https://github.com/ManuEtt/Dnd/actions/runs/39378443958), abgeschlossen mit **success**, vor Merge in [PR #40](https://github.com/ManuEtt/Dnd/pull/40), Code-HEAD `3462106592157953473c7d777b0d5b664872243a`. Backend, Dart, Flutter, native Android-Tests und APK-Builds grün. `main` wurde als Merge-Commit `f7c6a68c09155880fd9a08b0c2f308d324b27b82` aktualisiert; kein neuer separater Gerätefunktionstest durchgeführt.

**Verifiziert für den integrierten XP-/Aufstiegs-Pull-Request #39:** Der GitHub-Actions-Lauf [39374739010](https://github.com/ManuEtt/Dnd/actions/runs/39374739010) ist mit **success** abgeschlossen. Bestanden wurden unter anderem Backend-Tests, Dart-Formatierung, Flutter-Codeanalyse, sämtliche Flutter-Tests, Android-Debug-APK-Build und die Bereitstellung der kleinen Alpha-APKs.

**Erfolgreicher vollständiger Build auf `main`:** [39375312975](https://github.com/ManuEtt/Dnd/actions/runs/39375312975), Commit `25dab9b` – GitHub Actions meldet **completed / success**. Backend-Tests, Dart-Formatierung, Flutter-Codeanalyse, sämtliche Flutter-Tests und Android-Debug-APK-Build waren erfolgreich. Der erfolgreiche CI-Abschluss bestätigt den geprüften Quellstand, ersetzt aber keine Geräteabnahme.

**Nicht als geprüft ausgeben:** Installation/Update auf einem echten Android-Gerät, TTS-/Spracherkennungsqualität, System-Bildwähler, Langzeit-Speicherstandmigration, produktiver kostenpflichtiger KI-Anbieter und langfristig konsistente Release-Signierung.

Die bereitgestellten APKs sind **interne Test-/Alpha-Builds**, keine Store-Freigabe. APK-/ZIP-Artefakte ausschließlich aus einem erfolgreichen Workflow und mit den jeweiligen Prüfhinweisen beziehen: [GitHub Actions](https://github.com/ManuEtt/Dnd/actions) · [Anleitung zu Alpha-Releases](docs/ALPHA_RELEASES.md) · [APK-Downloadhinweise](docs/APK_DOWNLOAD.md).

## Bekannte Grenzen und nächste Schritte

1. **SRD-Charakterentwicklung vertiefen:** weitere aktive Klassen- und Unterklassenmerkmale, Talententscheidungen, Zauberwahl, Klassenressourcen und regelkonforme Mehrklassen-Sonderfälle. Ungeklärte Optionen weiterhin ausdrücklich offen lassen.
2. **XP- und Kampagnenhistorie ausbauen:** nachvollziehbare Aufschlüsselung der bestätigten Belohnungen und zusätzliche Tests für Speichern, Import/Export sowie mehrfach freigeschaltete Stufen.
3. **Kampf-, Magie- und Erkundungsregeln vervollständigen:** noch fehlende Auswirkungen, Ziel-/Positionsregeln, Zauber, Monster- und NPC-Mechaniken getrennt und mit Tests ergänzen.
4. **Geräteabnahme:** auf einem realen Android-Gerät Porträtauswahl, Sprache, Layout bei verschiedenen Displaygrößen, Spielstandsicherung und App-Update mit Altspielstand testen.
5. **Alpha-Veröffentlichung absichern:** vollständige CI pro geändertem Commit, validierte APK-Artefakte und geeignete konsistente Signierung für spätere Updates.

Eine vollständige, autonom lernende KI-Spielleitung und ein vollständiges D&D-5e-Regelwerk sind **keine bereits abgeschlossenen Funktionen**.

## Regelgrundlage, Dokumentation und Chronik

Das Projekt verwendet ausgewählte Inhalte des **System Reference Document 5.2.1** von Wizards of the Coast unter **CC BY 4.0**. Die erforderliche Namensnennung und Lizenzverweise stehen in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). Nicht frei lizenzierte Zusatzbücher oder Illustrationen werden durch die SRD-Lizenz nicht automatisch abgedeckt.

- [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Changelog](CHANGELOG.md) · [Checkpoint](CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Roadmap](ROADMAP.md) · [Regelabdeckung](docs/RULE_COVERAGE.md)
- [SRD-5.2.1-Anforderungsmatrix](docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md) · [Klassenaufstieg](docs/LEVEL_UP_0_8_9.md)
- [Rabenwacht-Soloabenteuer](docs/RABENWACHT_KAMPAGNE.md) · [Grafiken](docs/FANTASY_ASSETS_INTEGRATION.md)
- [Branch-Migration vom 20.10.2026](docs/LEGACY_BRANCH_MIGRATION_20261020.md)

**Historische README vollständig archiviert:** [`docs/README_HISTORIE_BIS_20261020.md`](docs/README_HISTORIE_BIS_20261020.md). Dort stehen ältere Zwischenstände und Branchangaben, die **nicht** als aktueller Projektstatus gelesen werden dürfen.

---

*Aktueller Überblick zuletzt am 23.10.2026 anhand von Main-Commit `b1fa9c67` und CI #39932399488 überarbeitet. Historische Meilensteine weiter unten sind datierte Nachweise, keine Beschreibung des aktuellen HEAD; bei Folgesitzungen neu verifizieren.*
