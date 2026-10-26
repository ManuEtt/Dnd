# Würfelraunen – Der lebendige Spielleiter

## Chat D – Quell-ZIP vor Symlink-Austausch nach dem Scan schützen (D-009, 26.10.2026)

Der Quellarchiv-Export nutzt auf POSIX nun vor jedem Dateilesen gesicherte Verzeichnis-Deskriptoren und `O_NOFOLLOW`, damit ein nach der Auflistung eingeschleuster Link nicht unbemerkt projektfremde Daten archiviert. Drei neue Regressionstests prüfen solche Datei-/Verzeichniswechsel sowie den Erhalt bereits veröffentlichter ZIP-/SHA256-Dateien; ein veralteter Testmock wurde aktualisiert. Non-POSIX-Plattformen erhalten eine zusätzliche Best-Effort-Prüfung, jedoch keine Garantie gegen alle Race Conditions. **Die finale CI auf dem aktuellen PR-Commit ist noch abzunehmen.** Keine Änderungen am Spielstandformat, App-Code oder Regelwerk. [Chat-D-Checkpoint](docs/parallel/CHAT_D_CHECKPOINT.md).

## Chat B – NPC-Zeitstempel strikt prüfen (Arbeitsbranch, 26.10.2026)

Im isolierten [PR #220](https://github.com/ManuEtt/Dnd/pull/220) auf Branch `fix/chat-b/npc-timestamp-validation-20261026` wird ein Fehler bei Datumsangaben bestätigter NPC-Beziehungsnotizen behoben: JavaScript normalisiert bisher einen ungültigen 30. Februar stillschweigend auf März. Die Prüfung verlangt jetzt zusätzlich die unveränderte UTC-Kalendersekunde und weist überlaufende Tage oder 24:00 zurück. Gültige Schalttage, Sekundenpräzision und Mikrosekunden bleiben zugelassen. Backend-Unit- und HTTP-Gegenfälle wurden ergänzt. **CI- und Gesamt-Tests dieses Branches sind erst nach dem konkreten Pull-Request-Lauf belegt; hier wird kein Grün behauptet.** Keine Änderung an Spielregeln, JSON-/SQLite-Schema oder bestehenden Spielständen. Andere offene PRs #216/#218/#219 nicht angefasst; gemeinsame Dokumentabschnitte von Chat D konsolidieren lassen. Fachlicher Stand: [Chat-B-Checkpoint](docs/parallel/CHAT_B_CHECKPOINT.md).


Deutschsprachige Android-Alpha für regelgeprüfte Soloabenteuer und lokale Kampagnen. Das vollständige SRD 5.2.1 bleibt in Arbeit.

## Aktueller Stand und autonome Fortsetzung (26.10.2026)

**Version 0.8.41+91 – Klassenprüfung für Heilige Flamme.** Branch `fix/sacred-flame-caster-validation-20261026` integriert Main `0212e99b6222f9fcae0714a2ee09123c3c78347c` und die geprüfte Klassenwerte-Berechnung aus [PR #184](https://github.com/ManuEtt/Dnd/pull/184) in den tatsächlichen Zauberablauf.

Heilige Flamme lehnt doppelte Klassenaliase, unbekannte Partnerklassen und widersprüchliche Klassenstufen jetzt vor Würfeln, Schaden und Aktionsverbrauch ab. Für gültige Mehrklassencharaktere bleiben Kleriker-Weisheit und der Übungsbonus der Gesamtstufe maßgeblich. Nach der vorhandenen ausdrücklichen SG-Bestätigung zeigt der Dialog die verwendeten Werte; ungültige Profile können nicht bestätigt werden. Titel und Inhalt bleiben gemeinsam scrollbar, auch bei großer Schrift und eingeblendeter Tastatur.

**Spielstände bleiben erhalten:** keine globale Importverschärfung, kein Umschreiben historischer Werte oder Ereignisse, SQLite 2 und Kampagnen-JSON 1 unverändert. Alte Profile lassen sich weiterhin laden und bearbeiten; nur neue Zauberhandlungen benötigen gültige Klassenwerte.

**Vollständig lokal geprüft:** 1.703 Flutter-, 141 Python-, 57 Backend- und zwölf native Android-Tests bestanden. Dart-Formatierung (389 Dateien), Flutter-Analyse, Backend-Typecheck/-Build und Backend-Protokolltest erfolgreich. Debug-APK und ARM64-Alpha tatsächlich aus dem geprüften Vollprojekt-ZIP gebaut; Version, Android-API24/36, ZIP-CRC, Architekturen, Signatur und Quellidentität geprüft. Beide APKs nutzen die lokale Debug-Testsignatur. Geräte-/Upgradeabnahme und produktive Signierung bleiben offen.

**GitHub:** [PR #217](https://github.com/ManuEtt/Dnd/pull/217), geprüfter Code-/APK-Quellcommit `7c9441e650a3b809db50f1a2d708d39bddfb39b7`. Vollständige [Android-CI #40284690640](https://github.com/ManuEtt/Dnd/actions/runs/40284690640) auf diesem Code-/Build-HEAD erfolgreich, einschließlich Debug-, nativer und drei Alpha-ABI-Builds. Spätere reine Dokumentationsnachträge sind über die [finalen PR-Checks](https://github.com/ManuEtt/Dnd/pull/217/checks) separat nachvollziehbar. [Checkpoint](docs/CODEX_CHECKPOINT.md) · [fachlicher Nachweis](docs/SACRED_FLAME_CLASS_VALIDATION_20261026.md).

**Geerbte Buildfehler korrigiert:** PR #215 wurde inzwischen auch in Main integriert; die entsprechenden Quell-/Testdateien sind bytegleich mit unserer Abnahme. Die ZIP-Dateimodi und Schreibfehler-Regressionen aus PR #215 sind mit den Originalkorrekturen `340fe91`/`8fd2141` übernommen; der zusätzliche NPC-Analyzer-/Formatfehler ist in `5edf968` behoben. Die alte Baseline-Gesamtsuite wurde nach dem Main-Fortschritt bewusst abgebrochen und durch die vollständig erfolgreiche kombinierte Abnahme ersetzt.

Andere aktuelle Arbeitsstände stehen unter [docs/parallel](docs/parallel/). Frühere README-/Checkpoint-Fassungen von Main und PR #184 sind [bytegenau archiviert](docs/history/sacred_flame_before_20261026/manifest.json). Grüne Einzel-CIs sind kein Nachweis einer neuen Kombination.

## Vorhandene Funktionen und Grenzen

| Bereich | Implementierter Umfang |
| --- | --- |
| Charaktere und Aufstieg | Zwölf SRD-Klassen, Attribute, bestätigte Startwerte/Ausrüstung, XP-Schwellen und bestätigte idempotente EP-Belohnungen, einzelne Aufstiege bis Gesamtstufe 20, bestehende Zweitklasse; zahlreiche Merkmals- und Talentwirkungen weiterhin offen |
| Kampf | W20/Vorteil/Nachteil, Angriff und Schaden, ausgewählte Zustände/Klassenaktionen, Bewegung/Aufstehen/Kriechen, Deckung, Einzelgegner mit bestätigten Mehrfachangriffen; keine vollständige Mehrakteur-Automatik |
| Magie | Zauberkatalog und Vorprüfungen, Plätze/Paktressourcen/Konzentration, ausgewählte echte Wirkungen und Schildreaktionen; Sending mit bestätigtem Dialog, Slotverbrauch und SQLite-Beleg, ohne Nachrichtenzustellung; Katalogeinträge sind keine vollständigen Zauberwirkungen |
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

Die vorhandene klassenrichtige Feuerpfeil-Berechnung an dieselbe ausdrückliche Bestätigung unbekannter Zauberangriffsmodifikatoren anbinden. Fehlende Bestätigung muss vor RNG und Zustandseffekt abbrechen; vorhandene Magier-/Zauberer-Auswahl, Gesamtstufen-Übung und Erschöpfung genau einmal erhalten. Vorschau, Ablehnung, Stale Revision und SQLite-Rollback prüfen. Keine neue Klassenwahl oder bereits vorhandene reine Regelhelper duplizieren.

Weiterhin offen: zahlreiche Zauber-/Klassen-/Monstermechaniken, amtliche Vollinventur, vollständiger Gelegenheitsangriff, Item-Overrides und reale Android-Abnahme. Kataloge oder Vorprüfungen ergeben keine globale SRD-Fertigstellungsquote.

## Dokumentation, Sicherung und Import

- [Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [operativer Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Changelog](CHANGELOG.md) · [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Roadmap](ROADMAP.md)

Downloadlinks zum überprüften Vollprojekt-ZIP und Patch stehen in [PR #217](https://github.com/ManuEtt/Dnd/pull/217). Vollprojekt-ZIP, Git-Patch, APKs, Prüfberichte, Dateimanifest und SHA256 lokal unter `/workspace/artifacts/0.8.41+91/`; aktuelle Dateinamen im dortigen Artefaktindex. Finale Patchbasis `0212e99b6222f9fcae0714a2ee09123c3c78347c` (die frühe Sicherung nennt ihre abweichende Basis im Manifest). ZIP in eine Arbeitskopie entpacken oder Patch auf dieser Basis mit `git apply --check` und `git apply` übernehmen, eigenen Branch pushen und PR öffnen. Keine alten Stände ungeprüft über Main kopieren. APKs werden separat bereitgestellt.

Nur rechtmäßig nutzbare Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte nutzen. [Namensnennung](THIRD_PARTY_NOTICES.md) erhalten. Keine automatische Weiterarbeit außerhalb einer aktiven Sitzung.

---

## Chat B – explizite NPC-ID im Story-Protokoll (26.10.2026)

Auf Basis des vollständig geprüften Main `42d14ad36cc947691f7e5a1e8647a43f5421b86e` implementiert der unabhängige Branch `feat/chat-b/explicit-npc-wire-20261026` die sichere, **optionale** Übertragung der vom Spieler ausdrücklich ausgewählten NPC-ID. Ein Backend bewirbt hierfür neu `npc-selection-v1`; alte Server werden keine `selectedNpcId`-Felder erhalten. Der Server verlangt eine eindeutige ID, denselben Kampagnenkontext mit Revision und genau eine passende, gespeicherte NPC-Chronik. Bei identischen Anzeigenamen darf der Offline-Mock dann nur die ausdrücklich gewählte Figur erzählen. Ohne Auswahl bleibt die bisherige Mehrdeutigkeits-Sperre bestehen. Altclients, Legacy-Texterinnerungen sowie SQLite 2/Kampagnen-JSON 1 bleiben unverändert.

**Begrenzung:** Die Android-Bedienoberfläche und der `GameController` liefern die Auswahl noch nicht automatisch; der reine Protokoll- und Story-Baustein kann nach expliziter Auswahl verwendet werden. Client-Fakten sind serverseitig nicht unabhängig authentifiziert und autorisieren niemals Regel- oder Questwerte. Positive/negative Backend-/Fluttertests wurden geschrieben; der vollständige CI-/APK-Status dieses neuen Branches ist ausschließlich anhand des endgültigen PR-HEAD zu prüfen. [Fachlicher Checkpoint](docs/parallel/CHAT_B_NPC_SELECTION_WIRE_20261026.md).

**Chat-B-PR zur NPC-ID-Auswahl:** [#237](https://github.com/ManuEtt/Dnd/pull/237). Bereits bestanden: Backendprüfungen, Dart-Formatierung, Flutter-Analyse und vollständige Flutter-Tests auf dem Code-/Formatstand `65bb3d29ac2aeead857073e2062c6c7fc0fa985a`; Android-Artefakte und finale CI des Dokumentationscommits separat prüfen. Die Spieloberfläche zur NPC-Auswahl bleibt ein künftiges, mit Chat C abzustimmendes Arbeitspaket.
