# Würfelraunen – Der lebendige Spielleiter

### Abgenommener Sending-Versuch: Slot & Ereignis (24.10.2026)

[PR #156](https://github.com/ManuEtt/Dnd/pull/156) wurde auf ausführbarem Code-Commit `2566a84e9a5f3c374c0ca0efd2f0ec558cc5bbfe` in der [vollständigen GitHub-CI #40078375498](https://github.com/ManuEtt/Dnd/actions/runs/40078375498) erfolgreich geprüft: Python, Backend, Dart-Format, Flutter-Analyse und komplette Tests, Android-Debug/native Tests, kleine Alpha-APKs und Quell-Checkpoint. Eine versehentlich duplizierte Quellcodepassage und anfängliche Dart-Formatfehler wurden vor der grünen Abnahme behoben; der temporäre Diagnoseworkflow ist entfernt. [Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40078375498/artifacts/12554522162) · [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40078375498/artifacts/12554482327) · [Source-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40078375498/artifacts/12554527162).

Die neue API bestätigt nur **Sending-Versuch und Slotverbrauch mit atomarem SQLite-Ereignis**, ausdrücklich keine echte Zustellung oder NPC-Antwort. Die UI-Anbindung sowie Installation/Update auf einem echten Gerät fehlen weiterhin. Version `0.8.37+87`, SQLite 2 und Kampagnen-JSON 1 bleiben unverändert. Dieser Nachtrag ist nur Dokumentation; CI des finalen Dokumentations-HEAD getrennt prüfen.


### Sending – bestätigter Slotverbrauch und lokales Ereignis (Entwicklungs-PR #156)

[Draft-PR #156](https://github.com/ManuEtt/Dnd/pull/156) ergänzt den bisherigen **rein lesenden** Sending-Preview um eine **separate ausdrückliche Bestätigung**: Ein unveränderter Heldenzustand wird vor der Ressourcenbuchung überprüft, ein passender Slot genau einmal im SQLite-Spielstand gebucht und `spell.sending.attemptConfirmed` atomar journalisiert. Wiederholte identische Anfrage-IDs werden nach Neustart als bereits gesichert quittiert, abweichende IDs/Inhalte und alte Revisionen abgelehnt. Laufende Kämpfe und offene Würfe bleiben gesperrt. **Keine automatische Nachrichtenzustellung, KI-Antwort oder Behauptung eines Empfangs**. Domain-/SQLite-Regressionstests hinzugefügt, neue CI-Auswertung für dieses Paket noch erforderlich. App 0.8.37+87, SQLite 2 und Kampagnen-JSON 1 unverändert.

Die vorherige Unicode-Korrektur [PR #155](https://github.com/ManuEtt/Dnd/pull/155) ist separat vollständig grün, aber nicht Bestandteil dieses von main gestarteten Inkrements. Sie wird nicht überschrieben.


### Fantasy-EP-Dialog in der Abenteueransicht (Integrations-PR #151)

„EP-Belohnung bestätigen“ öffnet eine validierte, scrollbare EP-Vorschau. Erst die gesonderte ausdrückliche Zustimmung übergibt eine beständige `xp_<Belohnungskennung>` an den Controller. Doppelte Bestätigungen und Fehler erzeugen keine zweite Gutschrift; eine Erfolgsmeldung setzt einen gespeicherten `xp.reward.confirmed`-Beleg voraus. Vorherige Schurken-, SQLite- und SRD-Sending-Funktionen bleiben vorhanden. Neue kombinierte CI ist erforderlich.

### Sending-Zauber: Nachricht, Klasse und Ressourcen gemeinsam prüfen (24.10.2026)

**Code-Abnahme erfolgreich:** [PR-CI #40071729227](https://github.com/ManuEtt/Dnd/actions/runs/40071729227) auf ausführbarem Commit `efed3d732459478b072452ab8e92ef3c674e39fd`: Python/Backend, Dart-Format und Analyse, vollständige Flutter-Suite einschließlich acht neuer Sending-Cast-Tests, Android-Debug/native Tests, Alpha-APKs und versioniertes Alpha-Quell-/APK-Paket **success**. Kein echter Gerätetest und weiterhin keine tatsächliche Zauberausführung. [PR #154](https://github.com/ManuEtt/Dnd/pull/154) ist offen und wurde nicht nach main gemergt.

Der nicht gespeicherte Regel-Dry-run sperrt außerdem Zauberaktionen bei 0 TP, Handlungsunfähigkeit oder ungeübter angelegter Rüstung. Manipulierte Sending-Klassenmetadaten dürfen keine fremden Klassen freigeben.

Der neue reine Rule-Dienst `SrdSendingCastPreflightRules` prüft die
Sending-Nachricht und Empfängerbestätigung gemeinsam mit
Klassen-/Vorbereitungsstatus, bestätigter Aktion,
Dritte-Grad-Zauberplatz, V/S/M-Komponenten (Kupferdraht oder
autorisiertem Ersatz) und bekannten/unsicheren Ebenen-/Blockadefakten.
Er erzeugt ausschließlich eine Vorschau und **verbraucht noch keinen
Zauberplatz oder Spielzustand**. Sieben neue Domain-Testgruppen angelegt;
eigene CI noch ausstehend. Bestehende Reichweiten-Sperre für andere
`Unlimited`-Zauber und JSON-/SQLite-Datenformat bleiben erhalten.

### Sending-Nachrichten vor verdeckten Steuerzeichen schützen (24.10.2026)

**CI-Abnahme:** [GitHub Actions #40068321150](https://github.com/ManuEtt/Dnd/actions/runs/40068321150) auf Code-HEAD `fb96641db97598a5ee1b59416ad254f5e0e63e29` vollständig **success**, einschließlich Python, Backend, Dart/Flutter, nativer Android-Tests, Android-Debug, kleiner Alpha-APKs und versioniertem Alpha-Artefakt. Kein reales Android-Gerät getestet. Keine neue App-Versionsnummer oder DB-/JSON-Migration.

Sending weist jetzt unsichtbare Unicode-Worttrenner, bidirektionale
Steuerzeichen, eingebettete Kontrollbytes und technisch überlange Eingaben
(über 2048 UTF-16-Codeeinheiten) ab. Diese Längengrenze ist ein technischer
Schutz, **keine offizielle D&D-Regel**; die SRD-25-Wörter-Grenze bleibt
erhalten. Deutsche Sonderzeichen und normale Zeilenumbrüche bleiben gültig.
Die neuen Grenz- und Manipulationstests sind implementiert und werden
erst durch die neue GitHub-CI abgenommen. Keine Änderung an Spielständen.

### SRD-Sending-Vorprüfung integriert (24.10.2026)

Der reine Dart-Regeldienst aus [PR #144](https://github.com/ManuEtt/Dnd/pull/144) validiert bestätigte Empfänger und Wissensherkunft, 25-Wörter-Grenze und dokumentierte Ebenen-/Blockadebedingungen für `Sending`. Er führt **keinen Zauberspruch und keine Nachricht** aus; Slotverbrauch und Spielzustandsänderungen sind nicht implementiert. Eigenständige Tests wurden übernommen. Ursprüngliche Sending-CI war erfolgreich; **der kombinierte Integrationsstand braucht neue CI**. Version und bestehende Schurken-/EP-Funktionen bleiben erhalten.


### Integrationsstand 24.10.2026 – bestätigte EP-Belohnungen

Der XP-Kern aus [PR #149](https://github.com/ManuEtt/Dnd/pull/149) ist auf den neueren Schurken-/Kampfstand aus `main` portiert: manuelle Bestätigung, idempotente Anfragekennungen, persistentes XP-Ereignisjournal, atomare SQLite-Transaktion sowie Schutz bei veralteten Revisionen und beschädigten Rabenwacht-Belohnungsbelegen. Regressionstests für Duplikate, Race-Bedingungen und Neustarts wurden übernommen. **Gemeinsame neue CI ausstehend**, obwohl die getrennten Vorläuferstände grün waren. Die alternativen UI-PRs #150/#151 und die SRD-Sending-PR #144 sind noch nicht Bestandteil dieser Integration.

Deutschsprachige Android-Alpha für Soloabenteuer, Charakterverwaltung und regelgeprüfte D&D-Spielabläufe. Flutter/Dart-App mit SQLite, optionalem Fastify-/TypeScript-Erzähler und Fantasy-Oberfläche. **Das vollständige SRD 5.2.1 ist noch nicht implementiert.**

## Aktueller Stand und autonome Fortsetzung (24.10.2026)

**Version `0.8.37+87`**, Entwicklungsbranch `feature/sneak-attack-ally-integration-20261023`. Funktionaler Code-Commit: [`0a56aba`](https://github.com/ManuEtt/Dnd/commit/0a56aba7057dc12d80750759443f6d70ed510dc1); Basis `main`: `5958579e5321338bb7b4e46abb859fd3bfd1515f`. Der vollständige [Basis-CI-Lauf #40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485) ist erfolgreich. Er belegt die Basis, nicht automatisch diesen Entwicklungsbranch.

**Neu: Hinterhältiger Angriff mit bestätigtem Verbündeten im tatsächlichen Kampf.** Vor einem offenen Hauptwaffenangriff kann ein Schurke einen Verbündeten benennen und zwei Fakten unabhängig bestätigen: innerhalb von 5 Fuß **des Ziels** und nicht handlungsunfähig (`Incapacitated`). Die Bestätigung gilt nur für diese Kampagne, dieses Ziel und diesen Wurf. Sie lässt sich vor dem Würfeln entfernen. Erst ein regelgültiger Treffer würfelt den zusätzlichen Schaden; kritische Treffer verdoppeln die Schadenswürfel. Die bestehende Begrenzung pro eigenem Zug bleibt erhalten.

Bestätigung, Würfelergebnis und Schadensfolgen werden über die Regelengine und atomare SQLite-Transaktionen gespeichert. Neustart und JSON-Backup erhalten einen offenen bestätigten Angriff. Veraltete Dialoge werden abgewiesen, freie Eingabeentwürfe bleiben erhalten. Erzähltext und KI-Antworten bestätigen keine Verbündetenposition. Die Fakten sind manuelle Beobachtungen; eine allgemeine Positionsverwaltung wird nicht vorgetäuscht.

Zusätzlich korrigiert: gespeicherte Hauptwaffenproben prüfen den Angriffsbonus über dieselbe Regelberechnung wie die Ausführung, einschließlich Bogenschießen bei Mehrklassen. Die vollständige Dart-Formatprüfung ist wieder lokal und in GitHub CI aktiv; 70 bereits vorhandene Dateien wurden in einem getrennten Format-Commit normalisiert.

### Integration des inzwischen aktualisierten Main

`main` wurde während der CI um PR #145 auf `1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd` erweitert. Der XP-Fix wird übernommen: dieselbe Belohnungs-ID quittiert nur denselben gespeicherten Betrag; widersprüchliche oder beschädigte Belege werden ohne Zustandsänderung abgewiesen. Die gemeinsame Abnahme läuft erneut. Die nachfolgenden grünen 1.448-Tests-/APK-/CI-Nachweise beziehen sich auf den geprüften Vorintegrationsstand `bfc991f`; sie werden nicht als Test der neuen Kombination ausgegeben.

### Tatsächlicher Prüfstand

| Prüfung | Ergebnis dieses Zyklus |
| --- | --- |
| Normalisierte Funktionsbasis | 1.431 Flutter-Tests erfolgreich |
| Neues Paket gezielt | 11 Domain-/SQLite-Tests und 6 Widgettests erfolgreich |
| Python-Projekt-/Pakettests | 100 erfolgreich |
| Backend | Typecheck, Build und 31 Tests erfolgreich |
| Dart/Flutter | 344 Dateien unverändert formatiert, Analyse ohne Befunde |
| Vollständige neue Flutter-Suite | **1.448 Tests erfolgreich** |
| Android-Debug / native Tests | APK gebaut, Metadaten/CRC/Signatur geprüft; **12 native Tests erfolgreich** |
| GitHub-PR / Code-CI | [PR #147](https://github.com/ManuEtt/Dnd/pull/147); [CI #40056875863](https://github.com/ManuEtt/Dnd/actions/runs/40056875863) vollständig erfolgreich auf `182f44b` |
| Echtes Android-Gerät | nicht getestet |

APK-Herkunft: aus dem vollständigen Quell-ZIP gebaut, 461 ausführungsrelevante Quelldateien per SHA256 abgeglichen; Version 0.8.37/Build 87, minSdk24/targetSdk36, ARM64/ARMv7/x64, Debug-Testsignatur. Kein echter Geräte-/Update-Test. Die kleinere ARM64-Alpha ist gebaut und geprüft (**19,7MB**, gleicher Build 87, lokale Debug-Testsignatur).

**GitHub-Downloads:** [Vollprojekt-ZIP](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546510086) · [Alpha-APKs (ARM64/ARM/x64)](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546286030) · [Git-Patch](https://github.com/ManuEtt/Dnd/pull/147.diff). Der erfolgreiche Lauf prüft den veröffentlichten Code-Stand `182f44b` (Merge-Test `de67cd3`); der damalige Dokumentationsnachtrag änderte keinen ausführbaren Code; für die anschließende Main-Integration ist eine neue gemeinsame Abnahme erforderlich. Aktuelle Checks stehen am PR.

Aktuelle Übergabe: [docs/CODEX_CHECKPOINT.md](docs/CODEX_CHECKPOINT.md). Regelquelle, Akzeptanzkriterien und Grenzen: [Hinterhältiger Angriff](docs/SRD_SNEAK_ATTACK_ALLY_INTEGRATION_20261023.md).

## Vorhandene Funktionen und Grenzen

| Bereich | Implementierter Umfang |
| --- | --- |
| Charaktere und Aufstieg | Zwölf SRD-Klassen, Attribute, bestätigte Startwerte/Ausrüstung, XP-Schwellen, einzelne Aufstiege bis Gesamtstufe 20, bestehende Zweitklasse; zahlreiche Merkmals- und Talentwirkungen weiterhin offen |
| Kampf | W20/Vorteil/Nachteil, Angriff und Schaden, ausgewählte Zustände/Klassenaktionen, Bewegung/Aufstehen/Kriechen, Deckung, Einzelgegner mit bestätigten Mehrfachangriffen; keine vollständige Mehrakteur-Automatik |
| Magie | Zauberkatalog und Vorprüfungen, Plätze/Paktressourcen/Konzentration, ausgewählte echte Wirkungen und Schildreaktionen; Katalogeinträge sind keine vollständigen Zauberwirkungen |
| Kampagnen | Lokale Solo-Demo und Rabenwacht mit optionalen Fortsetzungen, Entscheidungen, NPC-Erinnerungen und Journal; keine universell fertige autonome Spielleitung |
| Speicherung | Kampagnen, Ereignisse und Revisionen atomar; JSON-Sicherung, transaktionale Spielerhandlungs-Outbox, Settings-Teilupdates und Datenreset; SQLite-Version 2, Kampagnen-JSON-Version 1 |
| Android und Fantasy-UI | Deutsche Oberfläche, Charakterbogen, vorhandene Fantasy-Assets/Porträts, Sprache/TTS und Abenteueraktionen; reale Geräteabnahme und produktive Signierung offen |
| Optionaler Erzähler | Getrennter Backenddienst, bestätigter Regelzustand bleibt lokal; keine automatische kostenpflichtige Wiederholung und keine externe Exactly-once-Garantie |

Regelanforderungen stehen in [Coverage-Audit](docs/SRD_5_2_1_COVERAGE_AUDIT.md) und den beiden JSON-Registern. Die derzeitigen **1.419 Prüfaufträge und neun Inventurlücken sind kein vollständiger SRD-Nenner**. Eine globale Fertigstellungsquote wird nicht behauptet.

## Lokal entwickeln und prüfen

Toolchain wie CI: Flutter 3.35.7 / Dart 3.9.2, Java 17, Node.js 22.14.0 und Android-SDK. Linux-SQLite-Tests benötigen `libsqlite3-dev`.

```bash
bash scripts/check.sh
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py --json
cd app
flutter build apk --debug
cd android
bash ./gradlew :app:testDebugUnitTest --no-daemon
```

Die Demo benötigt keinen externen KI-Anbieter. Für einen eigenen Erzähler siehe [Backend](backend/README.md) und [Verbindung](docs/BACKEND_CONNECTION.md). Dauerhafte Anbieter-Schlüssel gehören ausschließlich auf den Server.

## Nächster konkreter Entwicklungsschritt

Den tatsächlich angreifenden Waffenplatz beim Hinterhältigen Angriff durchgängig prüfen und den Bestätigungspfad für zulässige Nebenhandangriffe ergänzen. Abnahme: Finesse/Fernkampf der wirklichen Angriffswaffe, einmal pro Zug, alte Hauptwaffen-/JSON-Abläufe, kritische Treffer, Ablehnung und SQLite-Neustart. Allgemeine Gelegenheitsangriffe und automatisierte Verbündetenbewegung bleiben getrennte Arbeitspakete.

Weitere offene Arbeiten: vollständige Quelleninventur, Zauberwirkungen, Klassen-/Monstermechaniken, strukturierte Item-Overrides, Android-Upgrade mit echten Spielständen und produktive Signierung. Der frühere lokale Item-Entwurf ist separat gesichert und wurde nicht über neuere Main-Dateien kopiert.

## Dokumentation und Historie

- [Aktueller Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [Operativer Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Artefakte importieren](docs/ARTIFACT_IMPORT_20261024.md) · [Validierungsbericht](docs/VALIDATION_0_8_37_20261024.md)
- [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md)
- [README vor diesem Zyklus](docs/history/main_0.8.36_20261023/README.md) · [ältere Historie](docs/README_HISTORIE_BIS_20261020.md)

Nur ausgewählte Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte verwenden. [Namensnennung und Lizenzen](THIRD_PARTY_NOTICES.md) erhalten. Neue Arbeit erfolgt während einer aktiven Sitzung in einem eigenen Branch und PR; keine automatische Fortsetzung außerhalb einer laufenden Sitzung.


### Branch-Konsolidierung (24.10.2026)

Die abgeschlossenen Integrationen #149, #144 und #151 sowie die SHA-geprüfte Bereinigung der bisherigen Arbeitsbranches sind in [docs/BRANCH_MIGRATION_AUDIT_20261024.md](docs/BRANCH_MIGRATION_AUDIT_20261024.md) dokumentiert. Alternative UI-Tests aus #150 wurden auf den Hauptdialog übertragen; der alternative Quellstand wird vor der Referenzlöschung als Git-Tag archiviert. Eine abgeschlossene Bereinigung ist erst durch den erfolgreichen Cleanup-Workflow und erneute Branchprüfung belegt. Der Hauptbranch ist gegenwärtig eine Android-Alpha; reale Geräteabnahme bleibt offen.
