# Chat A – Todesrettung: bestätigte Klassen vor Regelwirkung

Stand 30.10.2026 UTC, Basis-Main `55fe44475a113943c6310ec16a8ffb481185f4e9`,
Arbeitsbranch `feat/chat-a/death-save-class-validation-20261030`.
Laufzeit-/Testcommit `ee1e5a19e03b5db60fad838d0da36d1f360b84bc`. Dieses Paket ist ein eigener PR-Arbeitsstand;
Integration und Dokumentationskonsolidierung obliegen Chat D.
Appbasis `0.8.48+98`, SQLite **3**, äußeres JSON **1**, keine Migration oder
Versionsänderung. Der frühere Mönch-Abschluss ist bereits auf Main integriert;
ältere Aussagen „kein lokales SDK“, „SQLite2“ und „Integrationskandidat nicht main“
weiter unten sind historische Schreibstände.

## Ausgangsproblem und Akzeptanz

`Unbestätigt 6 / Mönch 14` und `Mönch 14 / Unbestätigt 6` erhielten mit natürlicher
4 unzulässig +6, einen Erfolg und Zugriff auf den Fokus-Wiederholungswurf. Die
bisherige Klassenprüfung bestätigte nur die numerische Verteilung. Unbekannte
Kämpferkombinationen konnten entsprechend Unbeugsamkeit freigeben.

- Hauptklasse und tatsächlich gewählte Zweitklasse müssen aus dem bestehenden
  SRD-Klassenresolver bestätigt sein; kanonische Aliase bleiben erlaubt.
- Unbekannte Klassen ergeben vor Bonus, neuer Todesrettung oder Ressourcenwahl
  eine verständliche FormatException; bestehende Stufen-/Doppelklassenprüfungen bleiben.
- Auch eine unversionierte historische offene Todesprobe wird **vor** einem
  zufälligen, natürlichen oder nur als Gesamtergebnis übergebenen neuen Wurf geprüft.
- Historische Profile, rohe Spielstände und unversionierte Proben bleiben lesbar,
  ohne stillschweigende Klassenergänzung oder Neuinterpretation ihrer Geschichte.
- Ablehnung erzeugt keinen Wurf, Ressourcenverbrauch, Event, Revisionswechsel oder
  SQLite-Teilstand. Gültige Klassen behalten Übung, Klassenstufe und gewählte Wiederholung.

## IMPLEMENTIERT

`DeathSavingThrowRules._validateClassLevels` prüft zusätzlich die beiden
Klassenidentitäten. `GameEngine.resolveRoll` ruft für Todesproben die bestehende
lesende Klassenprüfung vor `dice.check` auf, auch für alte Regelversion0. Neue
versionierte PendingRoll-/PendingDeathSave-Importe werden über ihre vorhandene
Revalidierung abgewiesen. Kein Modell-, Controller-, Repository- oder UI-Umbau;
die deutsche Fehlermeldung läuft durch den vorhandenen Fehlerkanal.

Gemeinsame `game_engine.dart`: genau fünf Zeilen Vorprüfung in einem koordinierten
Integrationsanteil dieses Pakets. Vor der Änderung wurden alle **27** zu diesem
Zeitpunkt offenen PRs samt Dateipfaden geprüft: kein anderer PR bearbeitete die
beiden Laufzeitdateien oder neuen Tests. PR175 ist bereits geschlossen/gemergt.
#387/#400/#405/#408 bleiben eigenständige fremde Zauberpakete; keine Übernahme,
kein Schließen/Mergen/Löschen ihrer Branches. README-/Checkpoint-Ergänzungen werden
nur im eigenen Branch geführt, bisherige Einträge bleiben erhalten.

## GETESTET

- **84** gezielte Domain-/bestehende Ablauf-/UI-Fälle bestanden, darunter **45**
  neue Klassenprüfungsfälle: alle zwölf Einzelklassen, elf Mönch-Mehrklassenfälle,
  Aliase, unbekannte/verschleierte Namen, Doppelklasse, unverändertes Hero-JSON.
- **Neun** neue Integrations-/SQLite-Fälle bestanden: vier ungültige Kombinationen,
  manipulierter versionierter Wurf/Entscheidung, alte offene Probe, gültige Mönch-
  und Kämpfer-Mehrklassenfälle, Neustart, Retry/stale Revision. Bei Ablehnung
  bleiben alle sechs rohen SQLite-Tabellen exakt unverändert und RNG unberührt.
- Die bestehenden Todesrettungs-Widgettests bei 320/360 dp bleiben grün.
- Der erste neue Flow-Testlauf hatte sieben Fixturefehler (Listeninitialisierung
  und JSON-Schlüsselreihenfolge), zwei Fälle bestanden. Fixtures korrigiert;
  rohe Datenbankvergleiche erhalten, anschließende neun Fälle grün. Kein Test deaktiviert.

Vollständige lokale Prüfkette `bash scripts/check.sh` auf dem eingefrorenen
Quellcode bestanden: **2.504 Flutter-, 221 Python-, 72 Backend-Tests**,
537 Dart-Dateien unverändert formatiert, Analyzer ohne Befund, Backend-Typprüfung,
Build und Protokollsmoke erfolgreich. Der lokale **ARM64-Debug-Build und zwölf native App-Tests** sind ebenfalls
erfolgreich; APK-ABI, Version98 und v2-Testsignatur geprüft. Der normale Debug-
Build und drei optimierte ABIs werden durch die GitHub-CI getrennt geprüft.
[PR #416](https://github.com/ManuEtt/Dnd/pull/416) · [maßgebliche CI-Ergebnisse des aktuellen Kopfs](https://github.com/ManuEtt/Dnd/pull/416/checks).
Die lokalen Ergebnisse sind kein Ersatz für diesen aktuellen CI-Nachweis;
Status, tatsächliche Lauf-IDs und Artefakte werden im PR geführt.
Frühere Main-CI40922492508 ist Basisnachweis, keine Abnahme des neuen Pakets.

## NICHT GETESTET / BLOCKIERT / NOCH NICHT IMPLEMENTIERT

Echtes Android-Gerät/TalkBack, installiertes Altversionsupgrade und produktive
Signierung fehlen. Kein Regel-/GitHub-Zugriffsblocker. Vollständiges SRD sowie alle
externen Rettungswurfmodifikatoren bleiben offen. Unbekannte manuelle Klassen
werden weiterhin gespeichert, erteilen aber keine bestätigte neue SRD-Todesrettung.
`RULE-CORE-RULES-DEATH-SAVING-THROWS` bleibt **partial**; keine Gesamtvollständigkeit.

## Regelquelle

Amtliches [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
CC BY 4.0, gedruckte S.17–18 (Death Saving Throws), **48** (Fighter9/Indomitable),
**52** (Monk14/Disciplined Survivor). Level-/Übungsboni nur aus bestätigter eigener
Klasse; keine Klasse aus KI-Text erfinden. Lizenzhinweise unverändert.

## Dateien / Wiederaufnahme

Laufzeit: `app/lib/domain/death_saving_throw_rules.dart`,
`app/lib/domain/game_engine.dart`. Neue Tests:
`app/test/death_save_class_validation_test.dart` und
`app/test/death_save_class_validation_flow_test.dart`. SRD-Register um Beleg
ergänzt, keine neue Anforderungszählung. Fachnachweis und Tests vor Änderungen lesen.
Vor Integration Main/PRs/CI erneut prüfen; Kombination anderer PRs separat abnehmen.

Genau nächster unabhängiger Schritt: **Kurze Rast ohne Trefferwürfelverbrauch**
prüfen und umsetzen. Amtliches SRD: Würfelverbrauch ist optional. Akzeptanz:
Ressourcen-/Paktregeneration auch bei leerem HD-Pool, keine Heilungs-/Würfelannahme,
explizite Bestätigung, kein RNG bei null Würfeln, Alt-JSON/SQLite/Retry und deutsche
Ablaufanzeige. Zuerst offene PRs und gemeinsame Engine-/Resultverträge abstimmen.
Keine automatische Arbeit nach Sitzungsende.

---

## Historische Einträge (jeweiliger damaliger Stand)

# Chat A – Checkpoint (26.10.2026): Eldritch-Blast-Klassenprüfung

## 29.10.2026 – Chat A, Fortsetzung PR #387: sichere HP-Zuordnung für Mehrzielgeschosse

- **Basis:** main `fde0ef6ed8b419d6a31c701a03aa05d61994c352`. PR #387 lag vor der Fortsetzung vollständig grün vor (Actions #40914915185/#40914925223); PRs #388/#389/#390 bearbeiten andere Produktionsdateien. Bestehender Chat-A-Branch bleibt derselbe, kein Merge nach main.
- **Neue Fachdateien:** `app/lib/domain/srd_magic_missile_encounter_hp_rules.dart`, `app/test/srd_magic_missile_encounter_hp_rules_test.dart`.
- **Implementiert:** unveränderliche Zuordnung bestätigter, gleichzeitig wirkender Magic-Missile-Geschosse zu Encounter-Hauptgegner und gespeicherten `trackedAreaCreatures`. Explizite unveränderte Ziel-IDs, passender Dart-Reihenfolge/Slot, identischer Encounter, exakte erwartete Revision und bestätigte lebende Kreaturen werden vorausgesetzt. Die TP nach Schaden werden bis Null gekappt, aber niemals gespeichert. Wenn der Primärgegner stirbt, jedoch Zusatzkreaturen leben, kennzeichnet `requiresMultiActorVictoryResolution` eine noch fehlende Mehrgegner-Kampfabwicklung. Fremd-IDs, Duplikate, bereits besiegte Kreaturen, offene Rolls/Reaktionen und veraltete Revisionen werden abgewiesen.
- **Tests:** neun neue deterministische Fachtests für Primär-/Zusatzkreaturen, nur Zusatzkreaturen, Shield/Immunität, Überkill, Konflikt/gespeicherte Identität, Ungültigkeit, JSON-Roundtrip, Preview-Immutability. Abschließende Flutter-/Android-CI auf neuem HEAD nach Dokumentationscommit prüfen; frühere grüne Tests betreffen nur den vorherigen PR-HEAD.
- **Provenienz:** SRD 5.2.1 `Magic Missile` S. 146, CC BY 4.0, https://www.dndbeyond.com/srd. `SPELL-MISSILE-MULTITARGET` bleibt `partial`.
- **Nicht implementiert / Sicherheitsgrenze:** keine echte Kampfbefehl- oder Controller-Integration, keine HP-Buchung, keine Monsterreaktion oder Questbelohnung, kein atomarer Event-/SQLite-Commit, kein automatischer Kampfabschluss nach Sieg über nur einen Gegner. Die vorhandene Einziel-Kampfaktion bleibt unverändert.
- **Migration:** keine; SQLite 3, Kampagnen-JSON 1 bleiben identisch.
- **Nächster Schritt:** nach Merge von PR #387 eine konfliktfreie Integration von Domain-Cast und HP-Vorprüfung in eine atomare, idempotent quittierte Mehrziel-Kampfaktion mit vollständig bestätigter Mehrgegner-Zug-/Sieglogik und Repository-CAS.

## 29.10.2026 – Chat A, PR #387: Mehrziel-Magisches-Geschoss als Domänen-Cast

- **Ausgangs-main:** `fde0ef6ed8b419d6a31c701a03aa05d61994c352` (24-PR-Integration, grüne Main-Actions #40867945743/#40869408110). Beim Start keine offenen PRs.
- **Branch:** `feat/chat-a/magic-missile-cast-resolution-20261029`; **PR:** https://github.com/ManuEtt/Dnd/pull/387 (Draft bis zur fachlichen und CI-Abnahme).
- **Implementiert:** `app/lib/domain/srd_magic_missile_multi_target_cast_rules.dart` bindet die validierte unveränderliche Zielverteilung an einen einzigen regulären oder Pakt-Zauberplatzverbrauch, an V/S-/Klassenvoraussetzungen, explizit abgeschlossene Schildreaktionen und getrennte Energieschaden-Abwehr pro Ziel. Die Geschosse werden erst nach vollständiger Validierung gewürfelt; vom Schild abgewehrte Geschosse würfeln nicht. Keine Veränderung des Eingangsspielstands.
- **Tests:** `app/test/srd_magic_missile_multi_target_cast_rules_test.dart`, zehn deterministische Fälle: Einziel, Split, Immunität/Resistenz/Verwundbarkeit, Schild, fehlende Bestätigungen, unbekannte/doppelte Ziele, vorbereitete Klassen, freie Zauberplätze, Multiklassen-Paktplatz, Grad-9-Grenze und Unveränderlichkeit. GitHub-CI wird auf dem finalen Branch-HEAD geprüft und im PR mit tatsächlichen Ergebnissen dokumentiert; ein früherer Lauf auf anderem HEAD gilt nicht als Schlussabnahme.
- **Quelle:** SRD 5.2.1 `Magic Missile`, S. 146, `Shield`, S. 161, Wizards of the Coast LLC, CC BY 4.0, https://www.dndbeyond.com/srd. Requirement `SPELL-MISSILE-MULTITARGET` bleibt `partial`.
- **Nicht implementiert:** Kampfbefehl in GameEngine, Controller, UI, bestätigte gegnerische Reaktion im Zugkontext, HP-/Ereignis-Update, atomare Revisions-/Exactly-once-Persistenz. Diese reine Domänenberechnung darf niemals unmittelbar als abgeschlossene Spieleraktion verbucht werden.
- **Migration:** Keine, SQLite 3 / Kampagnen-JSON 1 unverändert. Keine fremden Branches verändert.
- **Nächster Schritt:** Eigenständig bestätigte Mehrziel-Aktion in `GameEngine` und Controller integrieren, mit atomarem Zug-/Ressourcenverbrauch, realer Zielzuordnung zu Encounter/zusätzlichen Kreaturen, Revisionskonflikt- und Rollbacktests. Gemeinsame Dateien erst nach konfliktfreier Abstimmung mit Chat D ändern.
## 30.10.2026 – V/S/M-Metadaten vor regeltechnischer Freigabe prüfen (PR #400)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9` (Alpha 0.8.48+98).
- **Branch:** `feat/chat-a/spell-component-metadata-guard-20261030`; Code-/Test-Commit `cc4acba4ec2ad5d7db331a753aa6086925541921`; [PR #400](https://github.com/ManuEtt/Dnd/pull/400), Entwurf.
- **Ausgangsproblem:** Direkt über den öffentlichen Konstruktor erzeugte `SrdSpellDefinition` konnte widersprüchliche V/S/M-Flags enthalten. Die Materialprüfung hat dem Flag vertraut und erforderliche Bestätigungen umgehbar gemacht.
- **IMPLEMENTIERT:** Gemeinsame, bisher beim JSON-Import verwendete V/S/M-Validierung als `SrdSpellDefinition.validateComponentMetadata`; Prüfung an der Material-/Preflight-Grenze vor Ressourcenbuchung.
- **Dateien:** `app/lib/domain/srd_spell_catalog.dart`, `app/lib/domain/srd_spell_component_rules.dart`, `app/test/srd_spell_component_flag_guard_test.dart`, dieser Chat-Checkpoint, `README.md`, `docs/CODEX_CHECKPOINT.md`.
- **Tests:** Fünf neue deterministische Testfälle für 339 Katalogeinträge, inkonsistente Material-/V-/S-Flags, ungültige Syntax, gültiges kostspieliges Material und unveränderten Held/Zauberplätze. Tests erstellt, **noch nicht als bestanden nachgewiesen**. Flutter-/Dart-SDK fehlt lokal; finale GitHub Actions und Geräteprüfung getrennt abnehmen.
- **CI/Blocker:** Draft bis vollständige Android-CI inklusive Dart-Format, Analyse, Flutter-Tests, Python-/Backend-Prüfungen und APK auf finalem PR-Head erfolgreich ist. Bereits existierende CI anderer Commits ersetzt die Abnahme nicht.
- **Kompatibilität/Migration:** Kein SQLite-/JSON-Schema, keine Version, keine bestehende Ressource, keine Migration. Nur ungültige, direkt konstruierte Regelmetadaten werden bei neuen Freigaben abgelehnt. SRD 5.2.1, *Spells / Components*, Wizards of the Coast LLC, CC BY 4.0; Coverage-Status bleibt unverändert.
- **Koordination:** #387–#399 geprüft. Fachdateien ohne Überschneidung; README-/zentralen Checkpoint mit anderen Chat-PRs beim Merge additiv konsolidieren. Kein Merge anderer Arbeiten.
- **NOCH NICHT IMPLEMENTIERT:** Vollständige offizielle SRD-Zauberinventur, individuelle Wirkungen und transaktionaler Materialverbrauch.
- **NÄCHSTER SCHRITT:** Eigenständige Prüfung der Komponentenverfügbarkeit im bestätigten Materialinventar; positive/negative und Wiederholungs-/Neustarttests, keine unbestätigte automatische Abbuchung.
## 30.10.2026 – Reichweiten-Metadaten unverfälscht prüfen (PR #405)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `feat/chat-a/spell-range-canonical-metadata-20261030`, Code-/Teststand `92184c85c2b67458a83b78bc2aebf6ea28367013`, [PR #405](https://github.com/ManuEtt/Dnd/pull/405) (Draft).
- **Problem:** `SrdSpellTargetRules` normalisierte ungeprüfte direkte SRD-Metadaten mit `trim()` und erlaubte nicht-kanonische Schreibweisen per case-insensitive Regex.
- **IMPLEMENTIERT:** `validateOrigin` lehnt Randzeichen ab, numerische Reichweiten müssen kanonisch klein geschrieben sein; bisherige bestätigte Reichweiten bleiben identisch.
- **Geänderte Fachdateien:** `app/lib/domain/srd_spell_target_rules.dart`, `app/test/srd_spell_range_metadata_guard_test.dart`.
- **Neue Tests:** fünf deterministische Fälle (339 Katalogeinträge; Self/Touch/Sight-Randzeichen; numerische Rand-/Steuerzeichen und Großschreibung; Singular/Plural/Distanzgrenzen; Zauber-Preflight ohne Ressourcenmutationen). Alte Reichweitentests bleiben aktiviert.
- **GETESTET:** Quellen und offene PR-Dateipfade geprüft; neue Flutter-Tests bei Erstellung noch **nicht ausgeführt**. **NICHT GETESTET:** vollständige CI auf finalem Head, lokale Flutter-/Dart-/APK-Ausführung, Realgerät. Lokales SDK fehlt; GitHub Actions muss die Abnahme übernehmen.
- **Kompatibilität:** Weder SQLite noch JSON-Schema, GameController, Story, UI oder Version geändert; keine Migration. Nur künftig geprüfte, verfälschte Metadaten werden abgelehnt.
- **Quellen:** SRD 5.2.1 `Spells – Range/Targets`, Wizards of the Coast LLC (CC BY 4.0). `RULE-SPELLS-SPELL-RANGE` und `RULE-SPELLS-SPELL-TARGETS` bleiben `partial`.
- **Koordination:** #387, #400 sowie alle anderen offenen PRs bis #404 fachlich überschneidungsfrei; gemeinsam betroffene Dokumentation beim Review additiv mit Chat D integrieren.
- **PR #400:** Separate V/S/M-Komponentenprüfung, finale Android-CI #41007599214 auf `fb6076922cb6c62c74e657ac1b848e2b291c1f7b` **erfolgreich**; weiterhin ungemergter Draft.
- **BLOCKIERT:** Vollständige Endstand-CI/Review steht aus. Kein automatischer Merge.
- **NOCH NICHT IMPLEMENTIERT:** Spezialreichweiten `Unlimited`/`Special` und vollständige Ziel-/Deckungsgeometrie.
- **NÄCHSTER SCHRITT:** Nach CI und Integration getrennt prüfen, ob bestätigte nichtverbrauchte kostspielige Zaubermaterialien bei wiederholter Anwendung auf denselben, revisionsgesicherten Inventarstapel gebunden bleiben.
## 30.10.2026 – SRD-Materialinventar-IDs und nicht verbrauchte Komponenten (neuer PR)

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`. **Branch:** `feat/chat-a/spell-material-id-integrity-20261030`.
- **IMPLEMENTIERT:** `SrdSpellInventoryIdRules.isSafe` schützt bestätigte Inventarstapel-IDs vor C0/C1-/ASCII-Steuerzeichen, Soft Hyphen, Null-/Zeilenzeichen, Unicode-Bidi-Overrides/Isolaten und ausgewählten unsichtbaren Trennern. Normale internationalisierte IDs und innere Leerzeichen bleiben zulässig.
- **Verwendung:** `SrdSpellAuditedInventoryRules.consumedQuantities` validiert vor der Zuordnung alle Inventarstapel und Bindungs-IDs, auch für die ausdrücklich *nicht verbrauchten* teuren Komponenten von `Secret Chest`, `Clone` und `Legend Lore`. `SrdSpellInventoryRules.commitConfirmedCast` validiert außerdem bestätigte Verbrauchs-IDs und alle Stapel beim atomaren Ressourcenübergang.
- **Tests:** `app/test/srd_spell_inventory_id_guard_test.dart` prüft internationale IDs, unsichtbare Unicode-/Steuerzeichen, mehrfaches `Secret Chest` mit frisch geprüfter Planrevision bei unverändertem Inventar, JSON-Roundtrip, Stale-Plan-Verbot, Verlust eines gebundenen Stapels, unbeteiligte manipulative Stapel und gültige Einzelkomponenten.
- **Sicherheitsgrenze:** Diese Regeln erfinden weder Inventargegenstandswerte noch Materialidentitäten. Unabhängige Bestätigung von Identität/Wert/Menge bleibt Pflicht; es entstehen keine automatischen Spielwirkungen, keine generische erneute Zauberaktion ohne bestätigten frischen Preflight und kein Journalbeleg für behaltene Komponenten.
- **KEINE MIGRATION:** Bestehende historische Spielstände lassen sich laden, aber ein künftig bestätigter Cast mit manipulativem Stapel-Identifier wird abgelehnt; SQLite-/JSON-Schema, Controller, UI, Eventprotokoll und Version unverändert.
- **GETESTET:** Basis-main, verfügbare PRs und relevante Domain-Tests gesichtet; neue Tests geschrieben. **NICHT GETESTET:** Flutter-/Dart-Tests und vollständige GitHub-CI auf finalem Head, echte Android-Geräteprüfung.
- **BLOCKIERT:** Das Flutter-SDK fehlt im lokalen Werkzeug; CI muss das Format-/Analyse-/Test-/Build-Gate auf dem tatsächlichen GitHub-Head übernehmen. Nicht ohne erfolgreiche Abnahme mergen.
- **SRD-Provenienz:** SRD 5.2.1, `Spells / Casting Spells / Components`, Wizards of the Coast LLC, CC BY 4.0; `RULE-SPELLS-MATERIAL-COMPONENTS` bleibt `partial`.
- **Koordination:** Fachdateien mit den offenen PRs #387/#400/#405 und den aktuellen Chat-B/C/D-PRs überschneidungsfrei. README und `docs/CODEX_CHECKPOINT.md` mit anderen parallelen Checkpoints vor späterem Merge additiv konsolidieren.
- **Voriger PR #405:** vollständige GitHub-CI [#41011249059](https://github.com/ManuEtt/Dnd/actions/runs/41011249059) für Head `18bde90536921f324e2826cbc60ab731be40684c` **erfolgreich**, weiterhin nicht gemergter Draft. Voriger PR #400 ebenso grün auf [#41007599214](https://github.com/ManuEtt/Dnd/actions/runs/41007599214).
- **NÄCHSTER SCHRITT:** Unabhängige tatsächliche Wert-/Identitätsvalidierung kostspieliger Komponenten und Transaktions-Journaleintrag für behaltene Materialbelege über koordinierten Integrationsvertrag, ohne Freitext-Preisannahmen.
## 30.10.2026 – Separater Stückwert-Nachweis für auditierte Zaubermaterialien (Chat A, PR #415)

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`. **Branch:** `feat/chat-a/spell-material-value-evidence-20261030`. **Pull Request:** [#415](https://github.com/ManuEtt/Dnd/pull/415). Formatierter Code-/Teststand: `1f3e6d746688e87a266e6d076e0f494d0bbe4a30`. Neues Folgepaket **getrennt** von #387/#400/#405/#408.
- **IMPLEMENTIERT:** Neues Domain-Modul `app/lib/domain/srd_spell_material_value_rules.dart` mit `SrdSpellMaterialValueEvidence`, `validatedConsumption` und `commitConfirmedCast`. Der strenge, ausdrücklich zu wählende Pfad prüft die konkrete Anforderungs-ID und Inventarstapel-ID, externe Identitäts-/Stückwertbestätigung, SRD-Mindestwert **pro Einheit** (Kupferstücke), optional widerspruchsfreien Inventarmetadatenpreis sowie die im Bestand vorhandene Menge. Acht Komponenten in vier exakt auditierten Zaubern: Astral Projection, Clone, Legend Lore und Secret Chest.
- **GETESTET / TESTS NEU:** `app/test/srd_spell_material_value_rules_test.dart` mit sieben deterministischen Testgruppen: Grenzpreise jeder Position der vier Rezepte, fehlende/gefälschte/beidseitig unbestätigte Bindungen, optionaler Metadatenpreis, Astral-Zielanzahl, nicht unterstützte Rezepte, atomarer Slot-/Material-Commit samt JSON-Roundtrip, Ablehnungs-/Stale-Snapshot-Invarianz. **Status:** Tests implementiert, noch nicht ausgeführt; GitHub-CI auf finalem Commit steht aus.
- **DOKUMENTIERT:** `docs/SRD_SPELL_MATERIAL_VALUE_EVIDENCE.md` mit vollständiger Preis-/Verbrauchstabelle und begrenzter Vertrauensannahme. Keine Namens-/Freitext-Preisinterpretation.
- **WICHTIGE GRENZE:** Der neue Pfad nimmt die **unabhängig ermittelten** Werte als Eingabe entgegen; er kann deren externe Herkunft nicht beweisen. Die bisherige boolesche Legacy-API bleibt unverändert. Controller/UI/Persistenz sind noch nicht an die neue strenge API gebunden. Keine echte Zauberwirkung wird aus diesen Informationen errechnet.
- **KEINE MIGRATION:** SQLite, JSON, Journal, Story, UI, Backend und Version unverändert. Keine Datenbank- oder Controller-Datei geändert. Offizielle SRD-5.2.1-Quelle: WotC `Spells / Components`, CC BY 4.0. `RULE-SPELLS-MATERIAL-COMPONENTS` bleibt **partial**.
- **BLOCKIERT:** Lokales Flutter-/Dart-SDK fehlt; volle GitHub-Actions-Format-/Analyse-/Test-/APK-Abnahme noch ausstehend. Reale Android-Geräteprüfung nicht durchgeführt. Vor Merge Code-Review und additive Dokumentationskonsolidierung durch Chat D.
- **Vorgängerabnahmen:** #408 vollständige [CI #41017785511](https://github.com/ManuEtt/Dnd/actions/runs/41017785511) auf `afccc063040a67d03ff0fdb4a417f21831e17c09` erfolgreich; #405 [CI #41011249059](https://github.com/ManuEtt/Dnd/actions/runs/41011249059), #400 [CI #41007599214](https://github.com/ManuEtt/Dnd/actions/runs/41007599214) ebenfalls erfolgreich. Alle ungemergte Draft-PRs.
- **NÄCHSTER SCHRITT:** Koordinierter Controller-/Repository-Integrationspfad, der prüfbare externe Einzelwert-Nachweise revisionssicher in einen journalisierten Zaubermaterial-Commit überführt, ohne boolesche Legacy-Bestätigungen zu überschreiben.
## 30.10.2026 – Zauberwirkzeit-/Ritualintegrität bei regulärem Preflight – PR #423

- **PR:** [#423](https://github.com/ManuEtt/Dnd/pull/423) (Draft). Formatter-Workflow [#41119780572](https://github.com/ManuEtt/Dnd/actions/runs/41119780572) erfolgreich, Hilfsworkflow vor finaler CI entfernt.
- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`, eigener Branch `feat/chat-a/spell-casting-time-integrity-20261030`.
## 30.10.2026 – Zauberwirkzeit-/Ritualintegrität bei regulärem Preflight – PR #423

- **PR:** [#429](https://github.com/ManuEtt/Dnd/pull/429) (Draft) (Draft). Formatter-Workflow [#41119780572](https://github.com/ManuEtt/Dnd/actions/runs/41119780572) erfolgreich, Hilfsworkflow vor finaler CI entfernt.
- **Basis-main:** `69bfe78ec4eeb30042b26971978038a2ee9dac34`, eigener Branch `feat/chat-a/spell-casting-time-integrity-synced-20261030`.
- **IMPLEMENTIERT:** `app/lib/domain/srd_spell_casting_time_rules.dart` klassifiziert alle 339 bekannten SRD-Arbeitskatalog-Wirkzeiten. `app/lib/domain/srd_spell_preflight_rules.dart` ruft `requireSingleTurn(spell)` auf, um mit dem öffentlichen Konstruktor injizierte falsche Ritualflags, nichtkanonische Zeitangaben und Steuerzeichen nicht zu übernehmen. Aktions- und Bonusaktionszauber bleiben gültig; Reaktion, getriggerte Bonusaktion, Langzeit-/Sonderzeiten bleiben gesperrt.
- **TESTS ERSTELLT:** `app/test/srd_spell_casting_time_integrity_test.dart`: acht deterministische Gruppen mit Katalogkategorien 256/19/4/4/55/1, 29 Ritualflaggen, negative Metadatendaten, keine Slotveränderung durch Preflight, und getriggerte Zauber weiterhin getrennt.
- **DOKUMENTIERT:** `docs/SRD_SPELL_CASTING_TIME_INTEGRITY.md`, README und globaler Checkpoint. Quelle: WotC SRD 5.2.1 Spells / Casting Time, CC BY 4.0. Status nur `partial`, keine eigene Wirkungsausführung.
- **GETESTET:** PR-/main-Sichtung und Quell-/Kataloganalyse. **NICHT GETESTET:** neue Flutter-/Dart-/Android-CI; echtes Android-Gerät. Lokales Flutter-/Dart-SDK fehlt.
- **KEINE MIGRATION:** Kein JSON-/SQLite-/Event-/API-Schema, Controller/UI/Story/Backend/Versionswechsel; nur spezialisiertes Domainmodul und Preflight. Mit anderen Chat-A-/B-/C-/D-Fachdateien keine bekannte Überschneidung. README/zentralen Checkpoint beim Review durch Chat D additiv zusammenführen.
- **VORHERIG:** PR #420 [CI #41091851917](https://github.com/ManuEtt/Dnd/actions/runs/41091851917) vollständig grün auf `a755e2e81e72f497fb1711601c24df76bc58263f`; #418/#415/#408/#405/#400 ebenfalls grün, weiterhin Draft.
- **NÄCHSTER SCHRITT:** separates, autorisiertes Aktionsökonomie-Gate für Action vs. Bonus Action statt freier allgemeiner `actionAvailableConfirmed`-Bestätigung.
## 30.10.2026 – Konzentration nach Schaden mit SG-Obergrenze 30 (Chat A)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `feat/chat-a/concentration-damage-dc-cap-20261030`.
- **IMPLEMENTIERT:** `app/lib/domain/srd_concentration_damage_rules.dart`: isolierte, unveränderliche Konzentrationsentscheidung für separat bestätigte Schadensquellen. SG `min(30, max(10, Schaden~/2))` mit korrekt abgerundetem halbem Schaden, maximal 30 nach SRD 5.2.1 (anders als SRD 5.1). Rettungswurf je Quelle; erster Misserfolg beendet Konzentration, 0 TP/Tod/Handlungsunfähigkeit ohne Wurf.
- **BESTÄTIGUNGSPFLICHT:** bereits regelgeprüfter Heldenstatus nach Schaden, eindeutig lesbare Schadensquellen-IDs, Schaden, W20, vollständiger KO-Save-Modifikator und schon aufgelöster Vor-/Nachteil. Kein RNG und kein KI-Text als Beleg.
- **Tests:** `app/test/srd_concentration_damage_rules_test.dart` (8 Gruppen: SG 10/30, Grenzen/Rundung, Erfolg/Misserfolg, natürliche 1/20, mehrere Quellen, ungültige spätere Quelle, Bidi-ID, Zustände, Snapshot, JSON-Roundtrip).
- **Doku:** `docs/SRD_5_2_1_CONCENTRATION_DAMAGE_CHECKS.md`, README und zentraler Checkpoint ergänzt.
- **GETESTET:** offener PR-/main-Stand und bestehende Regelpfade geprüft, SRD-5.2.1-Provenienz über offizielles SRD bestätigt. Tests geschrieben, bislang nicht ausgeführt. **NICHT GETESTET:** Format-/Flutter-/Android-CI auf finalem Head, reales Gerät. **BLOCKIERT:** lokales SDK fehlt; CI auf GitHub notwendig.
- **KEINE MIGRATION:** bestehende Heldenspeicherung, JSON-/SQLite-Schema, Events, UI/Backend, GameEngine/Controller, Version unverändert. Kein automatischer Commit oder echte Schadenswirkung im Modul.
- **KOORDINATION:** #416 betrifft Todesrettungs-/GameEngine-Regeln, dieses Paket nur neue separate Konzentrationsdateien; andere offene Chat-A-/B-/C-/D-PRs haben keine Fachpfadüberschneidung. README und zentralen Checkpoint beim späteren Review additiv mit Chat D konsolidieren.
- **Vorgänger:** #415 finale [CI #41071482495](https://github.com/ManuEtt/Dnd/actions/runs/41071482495) erfolgreich, ebenfalls #408/#405/#400 erfolgreich. Alle getrennte Drafts.
- **NÄCHSTER SCHRITT:** atomarer persistierter Konzentrationsstatus per bestätigtem Schadensereignis und erwarteter Revision; nicht ohne Koordination mit Chat D an Shared-Dateien arbeiten.
## 30.10.2026 – Konzentrations-Rettungswurfmodifikator (Chat A)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `feat/chat-a/concentration-save-modifier-evidence-20261030`.
- **IMPLEMENTIERT:** Isolierte `app/lib/domain/srd_concentration_save_modifier_rules.dart`, `SrdConcentrationSaveModifierRules.prepare` und unveränderliche `SrdConcentrationSaveModifierEvidence`: ausschließlich bestätigte Konstitution, profiziente Rettungen, Mönch-14-Übung, Erschöpfungsabzug, ausdrücklich geprüfte situative Modifikatoren und Vorteil/Nachteil. Alle vorhandenen Formeln werden aus `CharacterRuleEngine.savingThrow` wiederverwendet, keine zweite Profizienztabelle.
- **SICHERHEIT:** Unbekannte Klassen, unmögliche Multiclass-Level, fehlende Konstitution, doppelte/ungültige Profizienzen, verlorene Konzentration, 0 TP/Tod/Handlungsunfähigkeit, unbestätigte Modifikatoren und veraltete Snapshot-Belege werden abgewiesen. Keine Würfel-, HP-, Zauberplatz- oder Konzentrationsmutation.
- **TESTS NEU:** `app/test/srd_concentration_save_modifier_rules_test.dart`, acht deterministische Gruppen zu Klasse, Mönch 13/14 und Multiclass, Erschöpfung, bestätigtem Bonus, Vorteil/Nachteil, ungültigem Charakterzustand, JSON-Roundtrip und Stale-Snapshot.
- **DOKUMENTIERT:** `docs/SRD_CONCENTRATION_SAVE_MODIFIER_EVIDENCE.md`, README und zentraler Checkpoint. Quelle: Wizards of the Coast SRD 5.2.1, Saving Throws, Concentration, Monk 14, Exhaustion (CC BY 4.0). Keine vollständig implementierte Konzentrationsengine behauptet.
- **GETESTET:** Repository-/CI-/PR-Sichtung; Code und Tests geschrieben. **NICHT GETESTET:** finale Dart-Format-/Flutter-/Android-CI, echtes Android-Gerät. **BLOCKIERT:** lokale Flutter-/Dart-SDKs nicht verfügbar, Review und exakte CI-Abnahme fehlen.
- **KEINE MIGRATION:** Modelle, Controller, GameEngine, SQLite-/JSON-Schema, Eventformat, Version, UI und Story unverändert.
- **KOORDINATION:** Fachpfade getrennt von Chat-A-PRs #387/#400/#405/#408/#415/#416/#418 und Chat B/C/D. README/zentrale Checkpoints additiv durch Chat D zusammenführen.
- **VORHERIG:** #418 vollständige [CI #41077695088](https://github.com/ManuEtt/Dnd/actions/runs/41077695088) erfolgreich, ebenso #415/#408/#405/#400. Alle PRs bleiben Drafts.
- **NÄCHSTER SCHRITT:** Integration des Modifikatorbelegs in den bestätigten Konzentrations-SG-Entscheid von #418 und später atomare Controller-/SQLite-Buchung.
## 30.10.2026 – Aktion und Bonusaktion bei Zauberpreflight unterscheiden

- **Basis-main:** `69bfe78ec4eeb30042b26971978038a2ee9dac34`; **Branch:** `feat/chat-a/spell-action-economy-evidence-20261030`.
- **IMPLEMENTIERT:** `app/lib/domain/srd_spell_action_economy_rules.dart` mit `SrdSpellActionEconomyRules.inspect` und `SrdSpellTurnActionEvidence.validateUnchanged`: eigener normaler Magieaktions- oder Bonusaktionsbeleg aus bestätigtem Kampf-Snapshot. Diese Zugressourcen sind nicht austauschbar; Slot-Turn-Limit gilt für Grad-1+-Zauber, Zaubertricks brauchen keinen Slot; Action Surge, Rage, fremder Zug und Handlungsunfähigkeit werden geprüft.
- **SICHERHEIT:** Keine unscharfen Reaktions-/Bonus-Trigger/Langzeitfreigaben; nicht bestätigter Begegnungsstatus wird nicht als `out of combat` geraten. Der Snapshot verhindert Wiederverwendung nach Helden-/Kampf-/Zauberänderung. Es wird **keine Aktion reserviert**, kein Commit ausgeführt und kein KI-Text als Bestätigung akzeptiert.
- **TESTS ERSTELLT:** Acht deterministische Gruppen in `app/test/srd_spell_action_economy_rules_test.dart` (Action vs. Bonus, Spells-Slot-per-turn, Action Surge, Rage/HP/active turn, fehlende Begegnungsbestätigung, Ritual/Trigger, Zeitfälschungen, stale Snapshot/JSON).
- **DOKUMENTATION:** `docs/SRD_SPELL_ACTION_ECONOMY_EVIDENCE.md`, README, zentraler Checkpoint. Offizielle WotC SRD 5.2.1, CC BY 4.0. SRD-Requirement bleibt `partial`.
- **GETESTET:** offener PR-/main-/Codezustand geprüft und Implementierung geschrieben. **NICHT GETESTET:** neue CI, Android-Realgerät. Flutter/Dart-SDK lokal nicht verfügbar.
- **KEINE MIGRATION:** Models/Engine/Controller, JSON/SQLite/Events, UI/Story/Backend, Version unverändert. Keine Überschneidung mit anderen Chat-A-/B-/C-/D-Fachdateien. Additive README/Checkpoint-Konsolidierung bleibt für Review offen.
- **BISHER:** #420 vollständige CI grün [#41091851917](https://github.com/ManuEtt/Dnd/actions/runs/41091851917); #429 Android-Alpha-Gate [#41121119046](https://github.com/ManuEtt/Dnd/actions/runs/41121119046) bei letzter Prüfung noch nicht final, alte #423 ausschließlich ohne Merge geschlossen.
- **NÄCHSTER SCHRITT:** Einen typisierten, revisionsgeprüften Aktionsbeleg mit der echten Zauberpreflight- und GameEngine-Kampf-Transaktion verbinden, sobald dies nach Merge von #429 mit Chat D kollisionsfrei möglich ist.

---


## Integrationskandidat 29.10.2026 – Chat A

Zusammengeführte Fachpakete: [#357](https://github.com/ManuEtt/Dnd/pull/357), [#361](https://github.com/ManuEtt/Dnd/pull/361), [#366](https://github.com/ManuEtt/Dnd/pull/366), [#367](https://github.com/ManuEtt/Dnd/pull/367), [#372](https://github.com/ManuEtt/Dnd/pull/372), [#375](https://github.com/ManuEtt/Dnd/pull/375), [#385](https://github.com/ManuEtt/Dnd/pull/385). Die ursprünglichen Branch-HEADs, PR-Beschreibungen, Tests, bekannte Grenzen und Statusmeldungen sind im [Integrationsjournal](INTEGRATION_20261029.md) mit Git-Historie dokumentiert. **Dieser Stand ist weder auf main integriert noch gemeinsam CI-abgenommen; Drafts sind nicht freigegeben.** Bisherige Checkpoint-Einträge bleiben erhalten.


- Ausgangs-Main: `42d14ad36cc947691f7e5a1e8647a43f5421b86e`; Branch: `fix/chat-a/eldritch-primary-class-validation-20261026`.
- IMPLEMENTIERT: `SrdEldritchBlastRules.resolve` weist unbekannte Hauptklassen vor RNG zurück, auch mit gültiger Warlock-Zweitklasse. Deterministischer Negativ-/Positivtest ergänzt.
- GETESTET: erfolgreiche vorherige Main-CI #40329543284/#40329543416; neue Branch-CI noch nicht ausgewertet.
- NICHT GETESTET: Branch-Flutter/Dart/Android, realer Gerätetest, historisches Geräte-Upgrade.
- BLOCKIERT: kein lokales Dart/Flutter-SDK. GitHub Actions übernimmt die ausführbare Abnahme.
- NOCH NICHT IMPLEMENTIERT: vollständiges SRD, weitere Mechanik; `SPELL-ENTRY-ELDRITCH-BLAST` bleibt partial.
- Kompatibilität: SQLite2, JSON1, keine Migration oder Eingriffe anderer Chats.
- Detailbericht: [Eldritch-Primärklassen-Prüfung](CHAT_A_ELDRITCH_PRIMARY_VALIDATION_20261026.md).
- Nächster Schritt: klassenrichtige Zauber-SG-Berechnung für Säurespritzer prüfen.

---

# Chat A – Regelwerk: Feuerpfeil-Klassenvalidierung

Stand: 2026-10-26 09:15 Europe/Berlin. Dies ist ein gesonderter Arbeitsstand von Chat A, kein Merge nach main.

## Ausgangslage / Git
- Ausgangs-main: `20098805d8c70cbd361a13862379894c47ef4eb6`.
- Eigener Branch: `feat/chat-a/fire-bolt-confirmed-modifiers-20261026`.
- Erstes Implementierungscommit: `992f5d537f158f0d1883fbd7210bf874205357cf`.
- Pull Request: [#221](https://github.com/ManuEtt/Dnd/pull/221) (Entwurf, kein Merge).
- PR #175: bereits geschlossen/gemerged; offene fremde PRs bei Ausgangsanalyse #216, #218, #219 ohne Überschneidung der geänderten Laufzeit-/Testdateien. Dokumentationsüberschneidung mit #216/#218 beim Integrationsreview durch Chat D konsolidieren.

## IMPLEMENTIERT (noch nicht vollständig CI-abgenommen)
- `FireBoltRules.cast` nutzt den bestehenden, klassenbezogenen `SrdSpellSavingThrowRules.statsForClass`, nicht mehr eine unvalidierte zweite Attribut-/Übungsrechnung.
- Feuerpfeil verlangt ausdrücklich die zunächst abgewählte Bestätigung, dass keine unmodellierten Gegenstände oder Merkmale den Zauberangriffsbonus verändern. Durchgängiger Transport: Dialog → App → Controller → GameEngine → Domain; Ablehnung vor Würfelwurf oder Spielstandänderung.
- Basisangriffsvorschau erst nach der Bestätigung; Eigenschaft/Klasse und Gesamtstufen-Übungsbonus bleiben erkennbar. Erschöpfung wird im Würfelbonus genau einmal angewendet.
- SRD-5.2.1-Provenienz: *Spellcasting* (Spell Attack Modifier), *Multiclassing* (Proficiency Bonus) und *Attack Rolls*; Wizards of the Coast LLC, CC BY 4.0. `THIRD_PARTY_NOTICES.md` unverändert. Requirement bleibt `partial`.

## Geänderte Dateien
- `app/lib/domain/fire_bolt_rules.dart`
- `app/lib/domain/game_engine.dart` (eng begrenzte Feuerpfeil-Schnittstelle)
- `app/lib/services/game_controller.dart` (eng begrenzte Weiterleitung)
- `app/lib/ui/fire_bolt_dialog.dart`
- `app/lib/ui/app.dart` (eng begrenzte Weiterleitung)
- `app/test/fire_bolt_rules_test.dart`
- `app/test/fire_bolt_dialog_test.dart`
- `docs/FIRE_BOLT_CLASS_VALIDATION_20261026.md`, `README.md`, `docs/CODEX_CHECKPOINT.md`, diese Datei.

## GETESTET / CI
- Erstes Android-CI auf `992f5d5`, [Run #40289603452](https://github.com/ManuEtt/Dnd/actions/runs/40289603452): **fehlgeschlagen** bei `dart format --output=none --set-exit-if-changed lib test` (genau zwei Testdateien), spätere Gates **nicht ausgeführt**. Formatierungsbehebung anschließend eingecheckt.
- Erster separater Chat-A-Regression-Workflow [#40289603227](https://github.com/ManuEtt/Dnd/actions/runs/40289603227): `completed/success`; ersetzt keine vollständige Android-CI.
- **Vollständige Android-CI [#40290687523](https://github.com/ManuEtt/Dnd/actions/runs/40290687523) auf geprüftem Code-/Test-HEAD `588b746e60fa27d9f4c40064a70c13aa9f125dd0`: completed/success.** 1.706 Flutter-Tests, 141 Python- und 57 Backend-Tests; 389 Dartdateien ohne Formatänderung, Flutter-Analyse ohne Befund, Backend-Typecheck/Build und Android-Debug/native/3 Alpha-ABI-Builds erfolgreich. Ein weiterer paralleler CI-Lauf ist keine Voraussetzung für diese nachgewiesene Einzelabnahme.
- GitHub-Artefakte nachgewiesen: [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40290687523/artifacts/12635429229), [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40290687523/artifacts/12635723341), [Alpha-/Buildartefakt](https://github.com/ManuEtt/Dnd/actions/runs/40290687523/artifacts/12635748319), [Quell-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40290687523/artifacts/12635414535). Artefaktarchive nicht mit lokal gerätegetesteten APKs gleichsetzen.
- Endgültiger Laufzeit-/Testquellcommit: `588b746e60fa27d9f4c40064a70c13aa9f125dd0`. Ein nachgelagerter reiner Dokumentationscommit enthält keine Änderung an `app/`, `backend/` oder `scripts/`.

## NICHT GETESTET
Lokale Flutter-/Dart-/APK-Befehle mangels installiertem SDK nicht ausführbar; stattdessen vollständige GitHub-CI auf Code-HEAD `588b746e60fa27d9f4c40064a70c13aa9f125dd0` erfolgreich. Reales Android-Gerät, TalkBack, historisches Geräte-Upgrade und Produktionssignierung fehlen. CI-APKs wurden gebaut und als GitHub-Artefakte bereitgestellt, aber nicht auf einem Gerät installiert.

## BLOCKIERT
Lokale Ausführung von `flutter test`, `flutter analyze` und `flutter build apk --debug` mangels Flutter-SDK. GitHub Actions hat die vollständige Integrationsprüfung bestanden. Keine unabhängigen Remote-Branches verändert oder gelöscht; README und zentraler Checkpoint sind bei parallelen PRs beim Integrationsreview zu konsolidieren.

## Speicher / Kompatibilität
Keine Migration, kein Schema-/JSON-Update (SQLite 2, Kampagnen-JSON 1). Historische Profile bleiben lesbar; ungültige Werte werden ausschließlich bei neuen Aktionen zurückgewiesen. Keine KI- oder Storyzustandsänderung.

## NOCH NICHT IMPLEMENTIERT
Zusätzliche bestätigte magische Angriffsmodifikatoren als echte modellierte Werte; vollständige Feuerpfeil-Objekt-/Umgebungswirkung; vollständige SRD-Inventur. Diese Prüfung beansprucht keine vollständige Regelabdeckung.

## NÄCHSTER SCHRITT
Nach erfolgreichem Review dieses Pakets: **Feuerpfeil-Ziel- und Gegenstandsregeln unabhängig prüfen**. Akzeptanz: brennbare unbeaufsichtigte Objekte nur mit explizit bestätigtem Objekttyp und Reichweite; keine Änderung eines unbestätigten Objekts, kein RNG vor Validierung; deterministische positive/negative Tests sowie Alt-JSON- und Ablehnungsinvarianz.

## GitHub und Sicherungen

Eigener [PR #416](https://github.com/ManuEtt/Dnd/pull/416); [aktuelle Checks](https://github.com/ManuEtt/Dnd/pull/416/checks).
Source-Commit `ee1e5a19e03b5db60fad838d0da36d1f360b84bc`; abschließende
Dokumentationscommits ändern die Laufzeit-/Testdateien nicht. CI-Läufe auf
überholten Köpfen gelten nicht als Freigabe. Chat D übernimmt die Integration;
keine fremden Branches werden geschlossen oder gelöscht.

Vollprojekt-ZIP und binärfähiger Patch außerhalb des Projekts unter
`/workspace/artifacts/chat-a-death-save-class-validation-20261030/`; Frühstand
`frueh/`, Endstand `abschluss/`, tatsächliche Prüfnachweise `pruefnachweise/`.
Patchbasis ausdrücklich Main `55fe44475a113943c6310ec16a8ffb481185f4e9`.
Nicht auf bereits integriertem Main erneut anwenden. Download- und Importdetails
im zugehörigen PR und lokalen `ARTEFAKTE_UND_IMPORT.md`; keine privaten Spielstände
oder Schlüssel in die Quellpakete aufnehmen.
