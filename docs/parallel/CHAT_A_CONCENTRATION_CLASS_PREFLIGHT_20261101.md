# Konzentrationsrettung: Klassenprüfung vor dem Wurf

Stand: 01.11.2026, UTC. Basis-Main
`5a88834c98f5aca40395088c20c7e1dc5b587868`, Code-/Testcommit
`37604994828745ac44e48d8e2f628024f2f355e2`, Branch
`fix/chat-a/concentration-class-preflight-20261101`, App **0.8.50+100**,
[PR #468](https://github.com/ManuEtt/Dnd/pull/468).

## Problem und Akzeptanz

Die laufende Schadensverarbeitung berechnete eine Konzentrationsrettung für
unbekannte oder widersprüchliche Klassenprofile. Ein Beispiel auf dem alten
Main: unbekannte Hauptklasse mit Mönch 14, Gesamtstufe 15 und Konstitution 14
bekam den automatischen Mönchs-Übungsbonus +5. Ein natürlicher Wurf 3 ergab
so 10 und erhielt die Konzentration. Die vorhandene separate
Konzentrationsvorbereitung lehnte dasselbe Profil bereits ab.

Erforderlich sind dieselben Regeln für Vorbereitung und tatsächliche
Konzentrationsrettung: bekannte SRD-Klassen, Gesamt-/Teilklassenstufen 1–20,
keine doppelte kanonische Klasse, keine benannte Zweitklasse ohne Klassenstufe,
keine unbekannten oder doppelten Rettungswurfübungen. Ungültige Daten müssen
vor dem Konzentrationswürfel abgewiesen werden. Bestehende Profile bleiben
lesbar; null Schaden, Immunität und Konzentrationsende ohne Wurf bleiben
unabhängig von dieser Klassenbestätigung verarbeitbar.

## Regelquelle

D&D SRD 5.2.1, Wizards of the Coast LLC, CC BY 4.0:
[offizielle Quelle](https://www.dndbeyond.com/srd),
[amtliche PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf).
Die amtliche PDF wurde am 01.11.2026 neu geladen; SHA256
`8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87`
ist mit dem vorhandenen Cache identisch. Gedruckte/PDF-Seite **179**, *Rules Glossary / Concentration / Damage*:
Konstitutionsrettung bei Schaden; Seite **52**, *Monk / Level 14: Disciplined
Survivor*: Übung in allen Rettungswürfen ab dieser Klassenstufe.
`THIRD_PARTY_NOTICES.md` bleibt unverändert. Requirement-ID:
`RULE-SPELLS-CONCENTRATION-SAVING-THROWS`, konservativ **partial**.

Die vorhandene SG-Berechnung `min(30, max(10, Schaden ~/ 2))` war bereits im
laufenden Spielpfad korrekt und wird nicht als neue Funktion ausgegeben.

## Umsetzung und Integration

Die bisherige Klassen-/Stufen-/Übungsprüfung wurde aus
`SrdConcentrationSaveModifierRules.prepare` unverändert in die öffentliche
reine Methode `validateClassAndProficiencies` extrahiert. Vorbereitung und
Laufzeit verwenden denselben Validator:

- `CharacterEffectRules._applyDamage` ruft ihn ausschließlich vor einem
  tatsächlich erforderlichen Konzentrationswurf auf, vor `DiceEngine.check`.
- `SpellcastingRules.saveAfterDamage` validiert auch einen separat übergebenen
  natürlichen W20 vor der Entscheidung über erhaltene/verlorene Konzentration.
- `CharacterRuleEngine.savingThrow` bleibt die einzige bestehende Berechnung
  von Attribut, Übung, Klassenmerkmal und Erschöpfung. Keine parallele Formel.

Es werden keine vorbereitenden Spielerbestätigungen automatisch auf `true`
gesetzt. Der Validator bestätigt nur die vorhandene Struktur; er erfindet
keine situativen Zusatzboni, Talente oder Würfelumstände.

Der reale deutsche Ablauf bleibt `CharacterEffectDialog` → Controller →
`GameEngine.applyDamage` → `CharacterEffectRules` → atomare SQLite-Speicherung.
Die bestehende Fehleranzeige zeigt die deutsche Klassen-/Übungsdiagnose.
Nach ausdrücklich gespeicherter Klassenkorrektur kann derselbe Schadensablauf
normal bestätigt werden. Keine neuen UI-/Controller-/Modell-/Datenbank-APIs,
keine Schemaänderung: SQLite **3**, äußeres JSON **1**. Keine Neuberechnung
historischer Charaktere beim Öffnen und keine Änderung früherer Ereignisse.

## Tests und tatsächliche Nachweise

**68 neue Tests** in drei Dateien:

- `concentration_class_preflight_test.dart`: **58 Fälle** für typisierten und
  untypisierten Schaden sowie separat übergebene W20. Elf ungültige Profile,
  alle zwölf SRD-Klassen und ihre vorhandenen deutschen/englischen Aliase,
  gültiger Mehrklassen-Mönch, einmalige Übung/Erschöpfung, temporäre TP und
  unveränderte Eingaben. Legacy-Pfade ohne Rettung bleiben ausführbar.
- `concentration_class_preflight_flow_test.dart`: **8 Fälle** mit echter Engine,
  Controller, SQLite-Import/Neustart, Vergleich aller sechs Tabellen samt
  gespeicherten JSON-Strings, Export/Import, Replay, veralteter Bestätigung,
  zweitem Controller und spätem Ereignis-Triggerfehler.
- `concentration_class_preflight_ui_test.dart`: **2 Widgetfälle** bei 360 dp mit
  echter App und Schadensdialog: lesbares Altprofil, Abbruch, deutscher Fehler,
  unveränderte Tabellen, explizite Korrektur über `saveHero`, tatsächliche
  Bestätigung und gespeicherter Konzentrationswurf bis zum SQLite-Neustart.

Die 58 neuen Domänentests wurden auf einem isolierten unveränderten Main-Checkout
wirklich ausgeführt: **25 bestanden / 33 fehlgeschlagen**. Mit dem Fix bestehen
**58/58**. Zusammen mit den neuen Flow-/UI-Fällen und bestehenden Effekt-, Zauber-
und Konzentrationstests bestehen **110 gezielte Tests**. Analyzer ohne Befund.
Kein Test deaktiviert oder zur Maskierung eines Fehlers abgeschwächt.

Die vollständige lokale `bash scripts/check.sh`-Prüfung bestand:
**2.778 Flutter-, 262 Python- und 76 Backend-Tests**, 579 Dart-Dateien ohne
Formatänderung, Analyzer ohne Befund, Backend-Typecheck/Build und echter lokaler
Node-/Dart-Protokollsmoke. Der Runtime-/Testcode ist Commit `37604994`; die
anschließende fachliche Quelldateiänderung präzisiert nur den alten Kommentar
von Konzentrationsseite 187 auf die richtige Seite 179.

`flutter build apk --debug --target-platform android-arm64` und
`bash gradlew :app:testDebugUnitTest --no-daemon` bestanden ebenfalls:
**13 JUnit-Tests, null Fehler/Skip**. Zwei lokale Build-Vorläufe scheiterten am
vollständig belegten Datenträger (Gradle konnte Verzeichnisse nicht anlegen).
Ein erster Bereinigungsversuch konnte selbst kein Logverzeichnis erstellen;
nach Freigabe alter erzeugter Dart-/Build-Caches lief der Build erfolgreich.
Vorhandene Quellen, Spielstände, Quellen-ZIPs, Bundles sowie frühere APK-/XML-
Nachweise blieben erhalten. Fehlgeschlagene und erfolgreiche Logs sind getrennt
unter `/workspace/validation/20261101-concentration-*.log` aufbewahrt.

Die bereits erzeugte lokale ARM64-Debug-APK ist 0.8.50+100, minSDK24/targetSDK36,
ARM64 und per v2-Debug-Testsignatur verifiziert. Sie ist kein realer Gerätetest.
Vorbereitung: vollständiger früher ZIP-/Patch-Checkpoint und History-Bundle
unter `/workspace/artifacts/concentration-class-preflight-20261101/frueh/`.

Finale PR-CI auf dem aktuellen #468-Head bleibt separat nachzuweisen; relevante
[Checks](https://github.com/ManuEtt/Dnd/pull/468/checks). Laufende oder nicht
beobachtete Prüfungen sind kein Erfolgsnachweis.

## Grenzen

Die Null-RNG-Zusage gilt vor dem Konzentrationswurf bei bereits bestätigtem
externem Schaden. Bei einem Gegnerangriff können Angriffs-/Schadenswürfel vorher
bereits legitim nötig gewesen sein. Ein später DB-Fehler rollt persistierte
TP/Revision/Ereignisse zurück, nicht die bereits verbrauchte Zufallsquelle.
Auch ein zweiter veralteter Controller kann den Revisionskonflikt erst nach
einem legitimen Wurf beim atomaren Speichern erkennen; dies wird getrennt getestet.

Keine vollständige Konzentrationsautomation: optionale Klassen-Wiederholungen,
weitere situative Zusatzquellen und die vollständige Wirkung aller Zauber bleiben
eigene Pakete. Allgemeine Rettungswürfe außerhalb dieses Konzentrationspfads
wurden nicht pauschal verändert. Echte Android-/TalkBack-/Upgradeprüfung und
produktive Signierung fehlen weiterhin.

## Konflikte, Übergabe und nächster Schritt

Vor Änderung alle 18 offenen PRs mit ihren vollständigen Dateilisten und finalen
Checks geprüft; die anschließend neu angelegten #464–#467 vor Veröffentlichung
zusätzlich auf Dateipfadüberschneidungen geprüft. #453 (Klassenaliase für Slots), #461 (Vorbereitungsquelle), #463
(klassenbezogener Vorbereitungsdatensatz) und #448 (Zaubertransaktion) bearbeiten
andere Fachdateien. Gemeinsame README-/Checkpoint-Ergänzungen sind bei Integration
durch Chat D additiv zu konsolidieren. Keine fremden Branches verändert.

Nach Abnahme dieses Pakets: allgemeine Klassen-Wiederholungswürfe in
`SavingThrowClassActions` auf dieselbe geprüfte Klassenherkunft untersuchen.
DoD: unbekannte/doppelte Klassen gewähren weder automatischen Bonus noch
Wiederholung/Fokus-/Unbeugsam-Nutzung; vor RNG/Ressourcenverbrauch abweisen,
gültige Aliase unverändert, UI-/SQLite-/Retry-Gegenfälle und finale CI.
Zuerst Main und aktuelle Parallel-PRs erneut prüfen. Keine automatische
Fortsetzung außerhalb einer aktiven Sitzung.
