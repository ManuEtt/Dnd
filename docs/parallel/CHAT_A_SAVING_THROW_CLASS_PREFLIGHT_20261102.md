# Chat A – lokale Vollabnahme: Klassen vor Rettungswurf-Wiederholungen

Stand: **02.11.2026, UTC**, **0.8.51+101**. Die unten bewahrte frühe Momentaufnahme
wurde durch die nachfolgenden tatsächlichen lokalen Endergebnisse ergänzt.

## Gesicherter Code, PR und noch getrennte CI-Abnahme

Basis-Main `5a88834c98f5aca40395088c20c7e1dc5b587868`; eigener Branch
`fix/chat-a/saving-throw-class-preflight-20261102`. Code-/Testcommit
`de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038`; früher Docscommit
`d5cf52f1c27ecdb0f01f0ce461788cde12449310`. Der abschließende Dokumentationsnachtrag
ändert keine Laufzeit- oder Testdatei. Der SHA-256 der einzigen Laufzeitdatei bleibt
`a637a0edd30f364564690ec5c36a42912499b3ed9ae3ca56db11c84ef98e5aa8`.

[PR #473](https://github.com/ManuEtt/Dnd/pull/473) ist Draft. Seine **[Checks des
aktuellen finalen Heads](https://github.com/ManuEtt/Dnd/pull/473/checks)** sind
separat abzunehmen; noch keine erfolgreiche finale CI oder Main-Integration
behauptet. Kein direkter Main-Commit und keine fremde Branchlöschung.

## Tatsächliche lokale Endergebnisse

`bash scripts/check.sh` vollständig mit **Exit 0** beendet. Im tatsächlichen
Log steht `08:15 +2782: All tests passed!`:

- **2.782 Fluttertests** bestanden, darunter die 72 neuen Fälle aus diesem Paket.
- **262 Python- und 76 Backendtests** bestanden.
- **579 Dartdateien** ohne Formatänderung, Flutter-Analyse ohne Befund.
- Backend-Typecheck, Build und tatsächlicher lokaler Node-/Dart-Protokollsmoke
  bestanden; keine kostenpflichtige KI nötig.
- Zuvor **159 gezielte Domain-/Bestands-/Flow-/UI-Regressionen** bestanden:
  62 neue Domainfälle, acht neue Speicherflows und zwei echte App-UI-Flows.
- Lokaler **ARM64-Debug-Build** bestanden; **13 native JUnit-Tests**, null
  Fehler, null Errors, null Skips. APK auf Code-/Testcommitde8cef1b, Version
  0.8.51+101, tatsächlich vorhandene Datei
  `/workspace/artifacts/saving-throw-class-preflight-20261102/local/Wuerfelraunen_0.8.51_101_ARM64_Debug.apk`,
  76.268.275 Bytes, SHA-256
  `38727b89128d7e6342d6aecc6353828f77d8a52c7d52201f52fb114c69bc68c8`.

Diese Nachweise sind keine reale Android-Geräte-, TalkBack-, Upgrade- oder
Produktivsignierungsabnahme. Optimierte Alpha und finale GitHub-CI bleiben offen.
Ein altes grünes Fremd-PR-Ergebnis wird nicht als Abnahme dieses Pakets verwendet.

## Frühe Sicherung und erneuter PR-Abgleich

Der Quellencheckpoint auf d5cf52f1 liegt tatsächlich unter
`/workspace/artifacts/saving-throw-class-preflight-20261102/frueh/`. Unabhängig
geprüft: **1.369 Quelldateien** mit exaktem Dateisatz, ZIP-CRC, SHA-256, Größe und
Modus; Patch tatsächlich auf Basis5a angewendet und sämtliche Dateien/Löschungen
verglichen; Git-Bundle separat wiederhergestellt und `git fsck` bestanden.
Alle drei Tips Basis5a, Codede8 und Frühdocsd5cf sind wiederherstellbar. Früh-ZIP:
`a5b3902a3d67c3349122dbfd2e0515c01b6d5b8269626f3565522a55a777a073`.
Die zwei historischen Patchdateien bleiben nach bestehender Paketkonvention im
Git-Bundle erhalten. Ein finaler Quellencheckpoint auf dem nachfolgenden
Dokumentationsstand wird gesondert erzeugt und geprüft; dieser frühere ZIP-Hash
ist kein vorweggenommener End-ZIP-Hash. Quellen-ZIPs enthalten keine APK.

Unmittelbar vor PR wurden **27 fremde PRs** auf aktuellem Main5a geprüft:
ursprüngliche 23 Heads unverändert, neue #469/#470/#471/#472 ohne Überschneidung
mit den Fachdateien dieses Pakets. Deren CI war zum Auditzeitpunkt noch laufend.
#468 teilt das Requirement-Register, verändert andere IDs; seine drei
Konzentrationsdateien bleiben hier unverändert. Bei Integration die unterschiedliche
Versionsnummer101 gegenüber100 sowie gemeinsame Dokumentation/Requirement-Belege
additiv durch Chat D konsolidieren. Einzelne grüne PRs beweisen keine gemeinsam
geprüfte Integration aller Pakete.

## Begrenzung und genau nächster Schritt

Beide Klassen-Requirements bleiben **partial**. SQLite3 / äußeres JSON1 ohne
Migration, historische Profile unverändert lesbar. `rules.blocked` mit neuer
Revision ist im vorhandenen Textaktionspfad beabsichtigt; Held, Ressourcen und
RNG bleiben beim ungültigen Klassenreroll unverändert. Ein legitimer W20 vor einem
späten SQLite-Fehler wird nicht rückgängig gemacht. Allgemeine Erstwürfe sind
hier unverändert; kein vollständiges Klassen-, Charaktererstellungs- oder SRD-
Regelwerk behauptet. Die bereits abgeschlossene Migration/Issue425 nicht wiederholen.

**Nächstes gesondertes Paket:** allgemeine initiale manuelle Rettungswürfe vor
automatisch abgeleiteten Klassenboni und W20 validieren. Schreibfreie
Charakterbogen-Vorschauen bewahren; zuerst frische Main-/PR-Dateilisten prüfen.
Akzeptanz: bekannte valide Aliase und Multiclassprofile unverändert korrekt,
ungültige Klassen-/Stufen-/Übungsdaten vor Bonus/RNG abweisen; Domain-, tatsächliche
UI-, SQLite-/Retry-/Neustart-Regressionen. Keine automatische Fortsetzung nach
Sitzungsende.

---

## Historischer Frühcheckpoint vor der lokalen Vollabnahme

# Chat A – bestätigte Klassen vor Rettungswurf-Wiederholungen

Stand: **02.11.2026, UTC**. App **0.8.51+101**. Vorläufiger Quellen-Checkpoint;
fachliche Änderung und gezielte Tests vorhanden, vollständige Abnahme offen.

## Git- und Integrationsstand

- Basis-Main: `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- Eigener Branch: `fix/chat-a/saving-throw-class-preflight-20261102`.
- Gesicherter Code-/Testcommit: `de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038`.
  Pull Request und finale CI sind noch offen. Dies ist ein Frühcheckpoint vor
  vollständiger lokaler und CI-Abnahme, kein Main-Merge.
- Laufzeitdatei-SHA-256 des unabhängig geprüften Zwischenstands:
  `a637a0edd30f364564690ec5c36a42912499b3ed9ae3ca56db11c84ef98e5aa8`. Dies ist ein **Dateihash**, keine Git-Commit-SHA.
- 23 offene PRs samt Fachdateien geprüft. Eigener früherer PR #468 zur
  Konzentrationsvorprüfung bleibt unverändert; dessen erfolgreiche CI ist kein
  Erfolgsnachweis dieses neuen Pakets. Main wird nicht direkt verändert;
  Review und spätere Integration koordiniert Chat D.
- Alte Branchmigration und Issue #425 bereits abgeschlossen. Keine fremden
  Branches schließen oder löschen. Bei neuen PRs/fortgeschrittenem Main vor
  Veröffentlichung Überschneidungen erneut prüfen.

## Ausgangsproblem und Akzeptanz

Die bestehende allgemeine Klassenwiederholung konnte eine unbestätigte
Hauptklasse zusammen mit Mönch 14 oder Kämpfer 9 als gültiges Profil behandeln.
Dabei wurden Bonus, ein Fokus-/Unbeugsamkeitsverbrauch und ein neuer W20 gewährt.
Auch gleiche kanonische Klassen unter zwei Sprachaliasnamen sowie doppelte oder
unbekannte Rettungswurfübungen waren an dieser Grenze nicht abgesichert.

Das begrenzte Paket verlangt:

1. Hauptklasse und tatsächlich ausgewählte Zweitklasse werden durch den
   bestehenden `findSrdClass`-Resolver bestätigt; zulässige Aliase bleiben erhalten.
2. Gesamtstufe 1–20 und eigene Klassenstufen bleiben konsistent: eigene Hauptstufe
   mindestens eins, ausgewählte Zweitklasse bekannt, verschieden und positiv;
   ohne Zweitklasse keine Zweitklassenstufen.
3. Gespeicherte Rettungswurfübungen enthalten nur die sechs vorhandenen
   Attributkennungen und keine Duplikate.
4. `available` bleibt eine lesende Abfrage und liefert bei ungültigen Profilen
   `false`; sie darf nicht erst nach einem separaten Erstwurf einen neuen
   Validierungsfehler auslösen. Bestehende HP-/Tod-/Ressourcenprüfungen bleiben.
5. `rerollFailed` weist ungültige Profile vor Klassenbonus, Ressourcenbuchung und
   `dice.check` ab. Gültige Berechnungen und die ausdrückliche Spielerentscheidung
   bleiben unverändert; der neue Wurf ersetzt weiterhin den alten.
6. Historische Profile und Ereignisse bleiben lesbar, ohne stillschweigende
   Klassen-/Übungskorrektur beim Öffnen.

## IMPLEMENTIERT

Einzige geänderte Laufzeitdatei:
`app/lib/domain/saving_throw_class_actions.dart`. Genau 51 zusätzliche Zeilen:
privater Profilvalidator sowie Aufrufe aus Verfügbarkeitsabfrage und expliziter
Wiederholung. Der unabhängige Review bestätigt: Nach Entfernung dieser Zusätze
ist der alte Code unverändert. Vorhandene Formeln aus
`CharacterRuleEngine.savingThrow` und bestehende Ressourcenmethoden aus
`ClassResourceRules` werden weiterverwendet. Keine zweite Berechnungslogik und
keine erfundenen Spielerbestätigungen.

Keine Laufzeitänderung an Modellen, `GameEngine`, Controller, Datenzugriff,
Flutter-UI, Story, Backend oder den drei Konzentrationsdateien aus #468. Die
vorhandene deutsche App-/Controller-/Engine-/SQLite-Kette nutzt die gehärtete
Regel automatisch. Eine abgewiesene Texteingabe wird wie bisher als
`rules.blocked` samt neuer Revision gespeichert. Das ist ein beabsichtigter
Journalbeleg; unverändert bleiben Heldenwerte und Ressourcen, und es wird kein
Reroll-W20 erzeugt. Die Behauptung „kein Event oder Revisionswechsel bei jeder
Ablehnung“ wäre an diesem bestehenden Textaktionspfad falsch.

SQLite **3**, äußeres JSON **1**, keine Migration. Kein automatisches Neuberechnen
historischer Charaktere, keine KI-/Story-Befugnis über mechanische Zustände.

## SRD-Quelle und Anforderungsumfang

Amtliches [D&D SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
Wizards of the Coast LLC, **CC BY 4.0**. Frisch geladene PDF-SHA-256:
`8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87`.
Gedruckte/PDF-Seiten **48** (Fighter 9 / Indomitable, Bonus der eigenen
Kämpferstufe) und **52** (Monk 14 / Disciplined Survivor, ein Fokuspunkt).
Lizenzhinweise in `THIRD_PARTY_NOTICES.md` erhalten.

- `CLASS-K-MPFER-9-BASE-INDOMITABLE-0`: **partial**.
- `CLASS-M-NCH-14-BASE-DISCIPLINED-SURVIVOR-0`: **partial**.

Diese beiden bereits existierenden IDs belegen nur die eingegrenzte vorhandene
Klassenwiederholung und neue Vorprüfung. Ein Katalogeintrag, Tests für die
Verfügbarkeit oder dieses Paket allein belegen keine vollständige Klassenregel.
Die 1.419 Arbeitsanforderungen und neun offenen Inventurlücken bleiben keine
zulässige globale Fertigstellungsquote.

## GETESTET

Der gesicherte Laufzeit-/Teststand auf Code-/Testcommit
`de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038` hat **62 neue Domänentests**,
**acht neue Engine-/SQLite-Flows** und **zwei tatsächliche App-UI-Flows** bestanden:
**72 neue Fälle**. **159 gezielte neue und bestehende Regressionen insgesamt**
(157 Domain-/Flowfälle plus zwei UI-Fälle) bestanden. Diese Zahlen sind keine
vollständige Flutter-/Backend-Suite. Der lokale ARM64-Debug-APK-Build ist ebenfalls
bestanden; native Tests und vollständiges `scripts/check.sh` laufen noch.

- `app/test/saving_throw_class_preflight_test.dart`: ungültige Haupt-/Zweitklassen,
  doppelte kanonische Klassen, unerlaubte Stufensplits, doppelte/unbekannte
  Übungen und verschleierter Name; beide Features jeweils vor RNG und Spend
  blockiert. Positivfälle für alle zwölf Klassen mit legalem Feature-Klassensplit,
  Sprachaliase, eigene Kämpferstufe, Übung/Erschöpfung einmal, schlechterer
  Ersatzwurf, verfügbare HP/Ressourcen und automatisches Zustandsmisslingen.
- `app/test/saving_throw_class_preflight_flow_test.dart`: vier lesbare ungültige
  Altprofile, `rules.blocked` mit genau unverändertem Held/RNG, Replay vor/nach
  SQLite-Neustart und Export/Import; zwei gültige Aliasprofile mit genau einem
  Reroll-/Ressourcenverbrauch. Staler Zweitcontroller vor RNG abgewiesen;
  tatsächlicher später SQLite-Triggerfehler rollt Snapshot/Spend/Journal zurück.
  Ein davor legitimer W20 bleibt gezogen; die Zufallsquelle ist nicht rückrollbar.
- Unabhängiger Nur-Lese-Review und sieben zuvor reproduzierte ungültige Profile
  erneut gegen den Fix geprüft: jeweils Formatfehler vor RNG, keine neuen
  Rechenformeln. Review ist ein zusätzlicher Nachweis, kein Ersatz für Vollsuite.

- `app/test/saving_throw_class_preflight_ui_test.dart`: **2/2 tatsächliche App-
  Flows auf 360 dp bestanden**. Frühere Fixtureläufe hatten einen Pass/einen Fail
  beziehungsweise null Pass/zwei Fail. Korrigiert wurden die Erwartung der
  absichtlichen `rules.blocked`-Revision (+1), echte Scroll-Gesten und die
  Aktionslisten-Suche bei leerer Outbox. Danach 2/2 im tatsächlichen Lauf
  `20261102-saving-throw-ui-verified.log` bestanden. Keine Laufzeitdatei geändert,
  kein Test deaktiviert oder abgeschwächt. Ein individueller Ablauf „Altprofil
  bearbeiten, speichern, Erstwurf und Wiederholung“ wird weiterhin nicht behauptet.
- Lokaler ARM64-Debug-APK-Build tatsächlich in etwa 55 Sekunden bestanden. Dies
  ist noch kein Gerätetest oder Nachweis produktiver Signierung.

## NICHT ABGESCHLOSSEN / NICHT GETESTET

Vollständiges `scripts/check.sh` und native Gradle-Tests laufen zum Zeitpunkt
dieses Frühcheckpoints noch. Deren Abschluss sowie die vollständige endgültige
Format-/Analyse-/Backend-/Flutter-Kette werden erst nach tatsächlichem Endergebnis
als bestanden geführt. Optimierte ARM64-Alpha und aktuelle GitHub-CI sind noch
nicht geprüft. Ein früherer grüner CI-Lauf anderer PRs ist keine Abnahme.

Kein realer Android-/TalkBack-/Upgrade-Test oder produktiver Signiervorgang.
Flutter-Widgettests und APK-Build ersetzen diese Geräteabnahmen nicht.

## BLOCKIERT

Kein bekannter Code-/SDK-/GitHub-Zugriffsblocker. Die reparierten UI-Fixtures
haben 2/2 bestanden. Nächste unmittelbare Arbeiten: frühen vollständigen Quellen-
Checkpoint sichern, Endergebnisse der laufenden vollständigen lokalen Prüfkette
und nativen Tests prüfen, danach PR und finale PR-CI abnehmen. Wegen begrenztem lokalen Speicher zuerst
frühen Quellen-Checkpoint sichern. Nur eigene reproduzierbare generierte Caches
nach Prüfung bereinigen; Quellen, WIP, Spielstände und ältere Artefakte erhalten.

## NOCH NICHT IMPLEMENTIERT

Der **allgemeine initiale manuelle Rettungswurf** wird durch dieses Paket nicht
neu validiert. Auch andere Rettungswurfquellen, zusätzliche situative Boni,
vollständige Klassen-/Charaktererstellung und Gesamt-SRD bleiben offene Aufgaben.
Ein beschädigter Ressourcen-Map kann weiterhin die bisherige Ressourcenvalidierung
auslösen; das neue `false`-Verhalten der Verfügbarkeitsabfrage betrifft ungültige
Klassen-/Stufen-/Übungsnachweise und ist keine neue universelle Fehlerunterdrückung.

## Sicherung, Prüfungen und genaue Wiederaufnahme

Frühcheckpoint und Endpaket außerhalb des Repositories als vollständiges Quellen-
ZIP, binärfähiger Git-Patch, Manifest und Git-Bundle sichern. Noch keine neuen
Artefaktpfade oder Downloadlinks behauptet; tatsächliche Erzeugung/Prüfsummen,
Patchbasis, finaler Commit und PR werden nach den Prüfläufen ergänzt. Ein Quellen-
ZIP enthält keine APK. Bereits integriertes Main nicht erneut blind patchen.

Vor Prüfungen nach einer Git-/Bundle-Wiederherstellung explizit:

```sh
python3 scripts/generate_fantasy_buttons.py
source /workspace/validation/wr-env.sh
bash scripts/check.sh
```

Der `source`-Pfad ist eine lokale Umgebungsdatei und kein Bestandteil des
Quellprojekts; andernorts die Toolchain aus `TESTING.md` bereitstellen. Der
Generator gehört nicht zu `scripts/check.sh`. Android separat gemäß vorhandener
CI: `flutter build apk --debug` sowie `:app:testDebugUnitTest`; bei ausreichend
Platz optimierte ARM64-Alpha und tatsächlich heruntergeladene CI-Artefakte mit
Metadaten, Signatur und Prüfsummen prüfen.

**Genau nächstes unabhängiges Entwicklungspaket nach Abnahme:** Allgemeinen initialen manuellen Rettungswurf vor automatisch abgeleiteten Klassenboni und W20 validieren; schreibfreie Charakterbogen-Vorschauen unverändert lassen. Zuerst frische Main-/PR-Dateilisten prüfen. Akzeptanz: unbekannte/inkonsistente Klassen vor Bonus/RNG ablehnen, gültige Aliase und Mehrklassen behalten dieselben Boni, Domain-, SQLite-/Retry- und tatsächliche UI-Regressionen bestehen.

Keine automatische Fortsetzung nach Sitzungsende; offene PRs vor dem nächsten
Paket erneut prüfen. Chat D konsolidiert gemeinsame Dokumentation bei Integration.
