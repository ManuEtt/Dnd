## Chat A – Klassenprofil-Preflight für Sorcerous Restoration (05.11.2026, Europe/Berlin)

- **Ausgangs-main:** `f11701efd46d0fee058f5f8e80b57f38ed4f7af4`; letzter bestätigter Main-Android-Workflow vor Start: [42053653539](https://github.com/ManuEtt/Dnd/actions/runs/42053653539) erfolgreich auf diesem SHA.
- **Branch:** `feat/chat-a/sorcerous-restoration-class-profile-20261105`; **Fach-/Testformat-HEAD:** `509a86e971e1a492d892b7e25fd9bd7847b3badd` (Diagnoseworkflow danach entfernt); **Draft-PR:** [#564](https://github.com/ManuEtt/Dnd/pull/564). Finaler Dokumentations-HEAD und CI gesondert zu kontrollieren.
- **Ausgangsproblem:** Die öffentliche Zauberer-Klassenstufenberechnung akzeptierte doppelte Alias-Klassen (`Zauberer 6 / Sorcerer 6`) sowie inkonsistente Zweitklassen und konnte dadurch SRD-5.2.1-Regeneration zu früh oder mit zu hoher Punktzahl gewähren.
- **IMPLEMENTIERT:** Konsistenzprüfung der ganzen Klassenkombination (gültige SRD-Aliase, unterschiedliche Klassen, Hauptklasse mindestens Stufe 1, konsistente Zweitklasse, Gesamtlevel 1–20). Lesen liefert für invaliden Snapshot 0, die bewusste Zustandsänderung wirft `FormatException` vor Ressourcenverbrauch. Gültige Level-5-/20-Grenzen und Mehrklassen bleiben unverändert.
- **Dateien:** `app/lib/domain/srd_sorcerous_restoration_rules.dart`, neuer `app/test/srd_sorcerous_restoration_class_preflight_test.dart` plus additive `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_A_CHECKPOINT.md`, `CHANGELOG.md`, `DEVELOPMENT_STATUS.md`.
- **Regressionen:** 10 ungültige Profile, 1 manipulierte Restaurationsressource, 4 positive DE-/EN-Solo-/Mehrklassenkonfigurationen, Negativfall ohne Feature/Stufe 4, Level 20 sowie Immutable-/JSON-Prüfung. Tests nicht deaktiviert.
- **GETESTET:** Live-main/11 offene PR-Dateilisten, Branchkollisionen, Quell-/Testvertrag und CC-BY-4.0-Regelstelle geprüft. Code und Tests auf GitHub-Branch gesichert. Keine lokale Flutter-Laufzeit verfügbar.
- **CI-Diagnose 05.11.2026:** Der Dart-Formatter fand in [Actions 42059486375](https://github.com/ManuEtt/Dnd/actions/runs/42059486375) drei Zeilenumbrüche in der neuen Testdatei. [Isolierte Formatter-Diagnose 42060023947](https://github.com/ManuEtt/Dnd/actions/runs/42060023947) lieferte die exakte Dart-3.9-Diff; die drei Stellen wurden im Fach-/Testformat-Commit `509a86e971e1a492d892b7e25fd9bd7847b3badd` übernommen. Diagnoseworkflow aus Branch entfernt; erneute vollständige CI [42060234695](https://github.com/ManuEtt/Dnd/actions/runs/42060234695) war beim Check zunächst **ausstehend**. Frühere Python-/Backend-Jobs bestanden, aber nicht auf dem finalen Branch-HEAD.
- **NICHT GETESTET:** Dart-Format, Flutter-Test-/Analyze-/APK, Python-/Backend-Vollsuite, finale Actions-Prüfung auf späterem PR-HEAD, Android-Realgerät.
- **BLOCKIERT:** lokales Flutter-/Dart-SDK sowie lokale GitHub-Klonverbindung; GitHub Actions ist für die eigentliche Testabnahme zuständig. Unabgenommene CI bedeutet keine Mergefreigabe.
- **NOCH NICHT IMPLEMENTIERT:** keine allgemeine Klassenprofilmigration, keine automatische SRD-Vollabdeckung, keine neue UI.
- **Migrationen/Abgrenzung:** keine Änderung an SQLite 3, äußerem JSON 1, `models.dart`, `rest_rules.dart`, `game_engine.dart`, Controller, Story, UI und Backend. Keine Änderung der App-Version und kein automatischer Merge. Requirement-ID `CLASS-ZAUBERER-5-BASE-SORCEROUS-RESTORATION-0` bleibt `partial`. SRD v5.2.1, Sorcerer / Level 5 Sorcerous Restoration, WotC, CC BY 4.0: <https://www.dndbeyond.com/srd>. Coverage-Status bleibt bestehen.
- **Koordination:** Open-PRs #543/#545/#546/#548/#549/#551/#554/#556/#557/#560/#561 fachlich dateikonfliktfrei; die gemeinsamen Dokumente müssen Chat D beim Merge additiv zusammenführen.
- **Nächster einzelner Schritt:** Auf frischem main und nach erneuter PR-Dateiprüfung `SrdEvasionRules` gegen doppelte/ungültige SRD-Klassenprofile absichern; Akzeptanz: ungültiger Unlock = false, regelwidrige Evasion-Preview abgewiesen, gültige Mönch-/Schurke-Aliase/Mehrklassen und Schadenshalbierung unverändert, deterministische Positiv- und Negativtests.

---

## Chat-A-Konsolidierung – 04.11.2026

Die Beiträge zu Waldläufer-Unermüdlich (#538) und Hexenmeister-Magische-List (#539) werden im gemeinsamen Integrationsbranch `fix/chat-d/branch-migration-actions-20261104` vereint; die originale Commit-Historie und beide individuellen Belege werden beibehalten. Kombinierte CI vor Main-Merge gesondert nachweisen.

---

<!-- PR #538 vor Integration, unverändert archivierter Zusatz -->
## 04.11.2026 – CHAT A: Waldläufer „Unermüdlich“ gegen ungültige Klassenprofile absichern (PR #538)

- **Ausgangs-main:** `c8f25132a82bcf55368a79100e0c2ea5595140b6`; **Arbeitsbranch:** `feat/chat-a/ranger-tireless-class-preflight-20261104`; **Fach-/Test-HEAD:** `58fa652fef01cb25d7fdae553364b31947cbd06a`.
- **Ausgangsproblem:** Direkt an `SrdRangerTirelessRules` übergebene Klassen-Snapshots wurden ohne Prüfung von Haupt-/Nebenklasse, Alias-Dopplung oder inkonsistenten Stufen ausgewertet; dadurch konnten die SRD-5.2.1-Waldläufermerkmale *Tireless* / Unermüdlich ab Stufe 10 zu Unrecht verfügbar erscheinen.
- **Implementiert:** `app/lib/domain/srd_ranger_tireless_rules.dart` prüft die Klassenprofile vor temporären TP, Magieaktion/W8 und automatischer Erschöpfungsreduktion. Bei ungültigen Profilen nur neutrale lesende Ergebnisse; ausdrücklich bestätigte Magieaktion wird vor Zufall und Ressourcenverbrauch abgelehnt. Gültige Aliase und gemischte Kämpfer-/Waldläuferklassen bleiben gültig.
- **Neue Regressionen:** `app/test/srd_ranger_tireless_class_preflight_test.dart`, sieben negative Profile (u. a. unbekannte Klasse, Doppel-Ranger, verwaiste Zweitklasse, unzulässige Stufen), positive gültige Einzel-/Mehrklasse, unverändertes Ausgangs-JSON und keine RNG-Verwendung bei Ablehnung.
- **Daten-/Schnittstellenschutz:** Keine Änderung an `models.dart`, `game_engine.dart`, `services/`, `data/`, Story/UI/Backend, SQLite3/JSON1; keine Migration. Register `CLASS-WALDL-UFER-10-BASE-TIRELESS-0` bleibt `partial`.
- **Tests/CI:** Quell- und Git-Diff geprüft; GitHub Actions, `flutter analyze`, `flutter test` und APK auf dem finalen dokumentierten PR-HEAD getrennt zu kontrollieren; vor Abschluss keine grüne CI behauptet.
- **Regelquelle:** <https://www.dndbeyond.com/srd>, SRD v5.2.1, Classes / Ranger 10 / Tireless; CC BY 4.0.
- **PR:** <https://github.com/ManuEtt/Dnd/pull/538> (Draft), Integration durch CHAT D nach bestandener finaler CI und konfliktfreiem Main-Abgleich.
- **Nächster konkreter Schritt:** Klassen-/Quellenvalidierung einer anderen spezialisierten SRD-Regelfunktion nur nach erneuter Prüfung offener PRs und ihrer Dateilisten.


---

---

<!-- PR #539 vor Integration, unverändert archivierter Zusatz -->
# Chat A – Magische List nur nach Klassenprofilprüfung (04.11.2026, PR #539)

**Basis-main:** `c8f25132a82bcf55368a79100e0c2ea5595140b6`. **Branch:** `feat/chat-a/warlock-magical-cunning-class-preflight-20261104`. **Fach-/Testcommit:** `86c83b5c93610285866e1717e65ac0a1d8e582b5`. **Draft-PR:** https://github.com/ManuEtt/Dnd/pull/539.

**Ausgangsproblem:** Die spezielle SRD-5.2.1-Regel `SrdWarlockMagicalCunningRules` vertraute auf einen unvalidierten Hexenmeister-Levelwert. Direkt konstruierte, inkonsistente Profile konnten Magische List oder Stufe-20-Eldritch-Master und damit Paktmagieplatz-Erholung freischalten.

**Implementiert:** Profilprüfung erkennt unbekannte Klassen, doppelte deutsche/englische Aliasvarianten, inkonsistente Zweitklassenstufen sowie Gesamtlevel außerhalb 1–20 oder eine Hauptklasse unter Level 1. Lesefunktionen fail-closed (0 Nutzungen/Plätze), expliziter Ritualabschluss mit ungültigem Profil wirft `FormatException` vor jeder Ressourcenänderung. Normale Hexenmeister- und Fighter-/Warlock-Mehrklasse einschließlich Eldritch Master bleiben wirksam. Keine Regelentscheidung aus Storytext.

**Betroffene Dateien:** `app/lib/domain/srd_warlock_magical_cunning_rules.dart`, neue `app/test/srd_warlock_magical_cunning_class_preflight_test.dart` und additiv README/zentraler/persönlicher Checkpoint.

**GETESTET:** Ausgangs-main, PR-Dateilisten, SRD-Rechtsgrundlage, bestehende Fachtests und aktuelle Domänenschnittstelle geprüft; neue 12 deterministische Fälle implementiert. **Noch NICHT getestet:** Flutter-Testlauf, Analyzer, Dart-Format, Android-APK und finale CI auf aktuellem PR-Kopf. Sie werden nur nach nachgewiesenem GitHub-Actions-Ergebnis als bestanden verbucht; lokale SDKs fehlen. Der unabhängig laufende Waldläufer-PR #538 ist kein Testnachweis für #539.

**Migrationen/Kompatibilität:** Keine; SQLite 3, JSON 1, Spielstandsstruktur und App-Version unverändert. `SpellcastingRules.pactClassLevel` bleibt ohne Änderung. Gewöhnliche Paktmagie benötigt gegebenenfalls einen gesonderten Schritt; keine Behauptung globaler Charakterprofilvalidierung.

**Koordination:** Offene PRs #535 (UI), #536 (Story), #537 (CI) und #538 (Waldläufer) ohne Fachdatei-Konflikt; die gemeinsamen Dokumente sind bei der Integration durch Chat D additiv zu konsolidieren. Kein Main-Merge durch Chat A.

**SRD-Nachweis:** Wizards of the Coast LLC, SRD 5.2.1, *Warlock Level 2 Magical Cunning / Level 20 Eldritch Master*, CC BY 4.0, https://www.dndbeyond.com/srd. `CLASS-HEXENMEISTER-2-BASE-MAGICAL-CUNNING-0` verbleibt **partial**, da die reale 1-Minuten-Ritualdauer und Unterbrechungen nicht automatisch kontrolliert werden.

**Nächster unabhängiger Schritt:** Nach finaler CI und aktueller PR-Prüfung Paktmagie-Klassenlevel in `SpellcastingRules` auf doppelte/ungültige SRD-Klassenzuordnungen prüfen; bei echter Lücke kleine, kompatible Domänenkorrektur mit deterministischen Cast-/Rast-/JSON-Regressionen auf eigenem Branch.

---

---

# Chat A – bestätigte Metamagie-Optionen versioniert prüfen (02.11.2026)

**Ausgangs-main:** `885580202caeafc9787538b6dc1c833b3190a529` ·
**Branch:** `feat/chat-a/metamagic-choice-proof-20261102` ·
**PR:** nach Veröffentlichung im GitHub-PR, CI auf finaler HEAD-SHA gesondert.

**Offizieller Fachbeleg:** D&D SRD 5.2.1,
Sorcerer Level 2 / Metamagic Options, CC BY 4.0.
Zwei Optionswahlen bei eigener Zaubererstufe 2,
plus zwei auf 10 und 17, maximal ein Ersatz bei
jedem *Zauberer*-Klassenaufstieg, nicht
bei anderen Multiclass-Level-ups.

**IMPLEMENTIERT:** eigenständiges Domainmodul
`app/lib/domain/srd_metamagic_choice_record.dart`:
`SrdMetamagicChoiceRules.confirm` benötigt
ausdrückliche Wahl, gültige eigene Klassen
und nachgewiesenes Metamagic-Feature,
exakt 2/4/6 verschiedene amtliche Namen.
`advanceSorcererLevel` sperrt ersetzte
Mehrfachoptionen, erfundene Zusatzoptionen,
stale Herkunft/Level, falsche Klasse.
`SrdMetamagicChoiceRecord` ist unveränderlich
und hat streng versionierte JSON-V1-
Serialisierung und `matchesHero`, das
Sorcererlevel und unveränderte Rohklassennamen
prüft, aber Ressourcen und andere Klassenlevel
bewusst nicht vermischt.

**Tests:** `app/test/srd_metamagic_choice_record_test.dart`,
zwölf Gruppen: Stufengrenzen, Optionenkatalog,
ungültige/abgewiesene Auswahl, Multiclass-
Klassenstufe/Aliase, immutable JSON,
manipulierte Schemafelder, 10/17-Zusatzplätze,
ein Wechsel/Stufenanstieg, fremde Level-ups,
Legacy-Helden-JSON sowie echte SQLite-
Neustarts/Retry/stale Revision.

**NICHT IMPLEMENTIERT / BLOCKIERT:** Das
versionierte Record-JSON bleibt bewusst
ein **externes Artefakt**, es wird **nicht**
in `HeroCharacter` oder SQLite automatisch
gespeichert. Ein manuell gebildetes JSON ist
kein autorisiertes Auswahlereignis.
Vollständige Persistenz benötigt Koordination
mit offenem PR #463; Distant Spell #478
wird nicht verändert. Live-Casting,
Metamagiekosten und UI bleiben unverändert.
Keine Migration: SQLite3 / JSON1.

**GETESTET:** Tests und Fachcode angelegt,
CI erst auf finalem PR-Kopf als grün
dokumentieren. Reale Android-Hardware,
Altupgrade, TalkBack, Release-Signierung
ausdrücklich noch nicht geprüft.

**NÄCHSTER SCHRITT:** nach Integration
der Metamagie-/Zauberbeleg-Bausteine
ein bestätigtes Metamagie-Auswahlereignis
persistent zum Heldenmodell hinzufügen
und die Freigabe in der atomaren
Cast-Transaktion mit Neustart-/Rollback-
und Revisionsfällen verwenden.

---

## 31.10.2026 – SRD-Zauber- und Aktionsökonomie gemeinsam vorbereitet

- **Ausgangs-main:** `47ab002872b7d46daeae03bb558258cf2ea73e4a`.
- **Branch:** `feat/chat-a/spell-turn-atomic-staging-20261031`; **PR:** neuer Draft-PR in Anlage.
- **IMPLEMENTIERT:** Reines Domain-Staging `app/lib/domain/srd_spell_turn_transaction_rules.dart` mit `SrdSpellTurnTransactionRules.prepare`, `stageConfirmed` und privatem, an Hero-/Zauber-/Encounter-Snapshots gebundenem `SrdSpellTurnPlan`. Bestehende Ziel-/Komponenten-/Slotprüfung und getrennte Aktionsökonomie bilden einen gemeinsamen Helden-/Encounter-Rückgabewert. Kein Effekt ohne separate Bestätigung und keine unbestätigte Spielzustandsänderung.
- **TESTS ERSTELLT:** `app/test/srd_spell_turn_transaction_rules_test.dart`, neun deterministische Gruppen, darunter Magic-/Bonus-Action getrennt, Turn-Slot- und Cantrip-Regeln, stale Retry/Revision, Fehlerpfade und unveränderte Original-JSONs.
- **DOKUMENTIERT:** `docs/SRD_SPELL_TURN_TRANSACTION_STAGING.md`, README, zentraler Checkpoint. SRD 5.2.1 *Playing the Game / Actions, Bonus Actions, Spells / Casting Time*, CC BY 4.0. Regelabdeckung nur `partial`.
- **GETESTET:** Vorabprüfungen auf GitHub (Main/Issues/PRs/Code) und Test-/Sourceerstellung; **NICHT GETESTET:** neuer Flutter-/Android-CI-Gesamtlauf und echtes Gerät.
- **KEINE MIGRATION:** Vorhandene Modelle, Controller, GameEngine, JSON-/SQLite-/Eventformat, Versionsnummer, UI, Backend und Story unverändert.
- **BLOCKIERT:** Vollständige Persistenz-/Revisionsintegration benötigt nächsten kleinen koordinierten Integrationsschritt. Die bestehende boolsche Legacy-Preflight-API bleibt unverändert; die neue Route wird nur bei expliziter Nutzung aktiv.
- **VORGÄNGER:** Der gemergte PR #432 hatte vollständige [CI #41123342877](https://github.com/ManuEtt/Dnd/actions/runs/41123342877) grün. Main-CI auf `47ab0028` war beim Start noch aktiv; Issue #425 weiterhin offen.
- **NÄCHSTER SCHRITT:** Nach Fach-Review die atomare SQLite-/Event-Buchung für beide zurückgegebenen Objekte unter Kampagnenrevision testen.

---

## Integrationsnachtrag 30.10.2026 – Chat-A-Branches

Alle 13 initialen Chat-A-Branchheads auf Main `6465a4b2` regulär konsolidiert.
Fachliche Kombinationskorrektur: vollständiger bestätigter Konzentrationsmodifier
zwischen Vorbereitung und Auflösung konsistent; namentliche Zweitklasse auf
Stufe 0 abgewiesen. Drei neue Regressionen zunächst rot, danach 19 zugehörige
Konzentrationstests grün; final alle 171 betroffenen Fach-/Flowtests grün,
559 Dart-Dateien formatkonform und `flutter analyze` ohne Befund.
Einzelne neue Regelhelfer bleiben ausdrücklich ohne vollständige Spielintegration.
Details und Abnahmegrenzen: [Migrationsbericht](CHAT_A_MIGRATION_20261030.md).
Gesamtintegration/Fullsuite/CI durch den koordinierenden Integrationsbranch offen.

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
# Chat A – Kurzrast-Ressourcen vor Trefferwürfeln prüfen

## Geprüfter Integrationsstand vor erneuter Abnahme

Main ist während dieses Pakets auf `69bfe78ec4eeb30042b26971978038a2ee9dac34`
(PR413, barrierefreie Todesrettungsoberfläche) weitergelaufen. Dieser Stand wird
regulär in den eigenen Branch übernommen; beide README-/Checkpoint-Berichte
bleiben erhalten. Der frühere Vollversuch auf Basis55fe4447 wurde vor Abschluss
bewusst beendet und gilt nicht als bestandene Vollsuite, auch wenn Flutter beim
SIGTERM Exit0 liefert. Die kombinierte Vollsuite und finale CI werden neu geprüft.
Der eigene Rast-Laufzeit-/Testcode19fe5e16 ist unverändert. Main wird durch diesen
Branch-Merge nicht verändert; PR416 und andere fremde Pakete bleiben getrennt.


Stand30.10.2026 UTC, Basis-Main `55fe44475a113943c6310ec16a8ffb481185f4e9`.
Branch `feat/chat-a/short-rest-resource-preflight-20261030`,
Quellcode-/Testcommit `19fe5e16394fae096c082a86e7aa8886461fc883`. [PR #428](https://github.com/ManuEtt/Dnd/pull/428) ·
[aktuelle CI-Ergebnisse](https://github.com/ManuEtt/Dnd/pull/428/checks). Kein Main-Merge behauptet; Chat D konsolidiert.
Appbasis **0.8.48+98**, SQLite **3**, äußeres JSON **1**, keine Migration.

## Ausgangsproblem / Akzeptanz

Ein Kämpfer2 mit SecondWind3, ActionSurge2 oder unverdienter Rage1 scheiterte
bisher erst **nach einem** Heilungswurf. Paktverbrauch1 ohne Hexenmeister wurde
sogar akzeptiert: HP3→6, Pakt1→0, ein Würfel. Die Ressourcengrenzen müssen vor
RNG/Heilung/Regeneration gelten; ein Erholungsreset darf einen ungültigen
Ausgangswert nicht verdecken. Gültige Erholung darf nicht doppelt erfolgen.

## IMPLEMENTIERT

`RestRules.shortRest` prüft direkt nach der vorhandenen Rastzulässigkeit:
`ClassFeatureResources.validate`, `ClassResourceRules.validate` und
`SpellcastingRules.availablePactSlots` auf dem **Originalhelden**, bevor ein
Trefferwürfel geworfen wird. Bestehende Regenerationskette und optionale
Zauberkraftregeneration bleiben unverändert. Keine GameEngine-, Modell-,
Controller-, Persistenz- oder UI-Datei verändert; deutsche Fehlermeldungen
nutzen den vorhandenen Fehlerkanal. Historische gültige Spielstände bleiben
unverändert lesbar, keine ungefragte Reparatur oder Neuberechnung.

Akzeptanzfälle: negative/überhöhte/unverdiente Zähler abweisen, ursprüngliche HP,
HD und Ressourcen bewahren, kein Würfel bei ungültigem Pool; gültige Mönch-,
Kämpfer-, Pakt- und weitere Klassenregeneration genau einmal; Abbruch/Import,
Retry, stale Revision, SQLite-Neustart und atomarer Rollback absichern.

## GETESTET

**65** gezielte Domain-/Bestandsfälle bestanden, darunter **33 neue** Unitfälle:
negative/überhöhte/unverdiente Zähler, 1/2HD, Klassen-/Alias-/Mehrklassenfälle,
unveränderte Eingabe, genau einmalige Regeneration und explizites Sorcerous-Restoration-Opt-in.
**Sieben neue** Flow-/SQLitefälle bestanden: echte Engine-/Controllerablehnung
vor RNG, unveränderte sechs Tabellen bei ungültigen Daten, gültige Erholung,
Request-ID-Replay vor/nach Neustart, stale Zweitcontroller, JSON-Export/Import,
Eventprovenienz und später SQLite-Fehler. Bei letzterem sind zwei gültige Würfe
bereits erfolgt; die Datenbank rollt zurück, Zufallszahlen werden nicht als
rückrollbar behauptet. Kein Test deaktiviert.

Ein erster Flow-Testlauf hatte fünf erfolgreiche Fälle und zwei neue
Fixturefehler (Roh-JSON-Exportvertrag, Wizard/Magier-Slotannahme). Fixtures auf
bestehende Verträge korrigiert; danach sieben grüne Fälle, unveränderte rohe
Tabellenvergleiche. Ursprünglicher Fehllog bleibt im externen Prüfnachweis erhalten.

Vollsuite, Analyse, Debug/native und aktuelle GitHub-CI werden separat anhand
[des aktuellen PR-Kopfs](https://github.com/ManuEtt/Dnd/pull/428/checks) und des vollständigen Testberichts im PR
geführt. Frühere Basis-CI oder PR416 gelten nicht als Abnahme dieses neuen Pakets.
Alle tatsächlich abgeschlossenen Läufe/Artefakte werden dort mit Commit/ID belegt.

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
Signierung bleiben offen. Kein Code-/GitHub-Zugriffsblocker. Dieser Fix gilt
**nur für kurze Rast mit Trefferwürfelverbrauch**. Engine-Sonderpfade ohne HD,
lange Rast, allgemeine Rastdauer/Unterbrechungen, freie Null-HD-Auswahl und
normale Zauberplatzvalidierung bleiben getrennt. Keine vollständige Rast- oder
SRD-Automatik behauptet. Requirement `RULE-SPELLS-PACT-MAGIC` bleibt **partial**.

## Quellen / Koordination

Amtliches [SRD5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
CC BY4.0, gedruckte S.187 Short Rest, S.48 Second Wind/Action Surge,
S.71 Pact Magic. Lizenzhinweise unverändert. Vor der Implementierung alle
**32** damaligen offenen PR-Dateilisten geprüft: keine Überschneidung von
`rest_rules.dart` und neuen Tests. Gemeinsame README-/Checkpoint-Ergänzungen
bleiben im eigenen Branch; Chat D konsolidiert sie bei Integration.

Voriger eigener [PR416](https://github.com/ManuEtt/Dnd/pull/416), Kopf870d4e98,
ist offen und mit [CI41074122650](https://github.com/ManuEtt/Dnd/actions/runs/41074122650)
geprüft. Sein GameEngine-Anteil wird hier nicht parallel verändert. Er ist
nicht auf Main übernommen; erfolgreiche Einzeltests ersetzen keine Kombination.
Historische ältere SDK-/SQLite2-/Integrationskandidaten-Aussagen darunter sind
Momentaufnahmen, kein aktueller Blocker.

## Sicherung / Wiederaufnahme

ZIP, Binärpatch, Manifest und Git-Bundle außerhalb des Projekts unter
`/workspace/artifacts/chat-a-short-rest-preflight-20261030/`, Frühstand `frueh/`,
Endstand `abschluss/`, tatsächliche Logs `pruefnachweise/`; Importanleitung
`ARTEFAKTE_UND_IMPORT.md`. Endgültige Patchbasis ausdrücklich Main69bfe78e (vollständig:
`69bfe78ec4eeb30042b26971978038a2ee9dac34`), getrennt vom ursprünglichen Branchstart55fe4447; keine privaten
Spielstände/Schlüssel aufnehmen. Bestehende Arbeitsstände nicht mit ZIP überschreiben.
Vor neuen Änderungen Main/PRs/CI und Masterprompt erneut prüfen.

**Genau nächster Schritt:** bestätigte SRD-Klassenaliase bei normalen
Zauberplätzen kanonisieren. Reproduzierte separate Lücke:
`MulticlassRules.combinedSpellcasterLevel` vergleicht rohe Namen; Wizard erhält
keine Slots, Magier schon. Akzeptanz: gleiche Slotzahlen für alle erlaubten
Caster-Aliase und Mehrklassen, Pact Magic getrennt, unbekannte Klassen nicht
erraten, bisherige JSONs unverändert und Domain-/Persistenz-/CI-Nachweis.
Nicht im Rastpaket verändert; vor Umsetzung Überschneidungen erneut prüfen.
Keine automatische Entwicklung nach Sitzungsende.

---

## Historischer Verlauf (damaliger Schreibstand)

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
## Lokale kombinierte Vollabnahme

Auf integriertem Quellstand86a91a2c vollständig bestanden: **2495 Flutter-,
221 Python- und72 Backend-Tests**,538 Dartdateien unverändert formatiert,
Analyzer sauber, Backend-Typecheck/Build/Protokollsmoke erfolgreich.
ARM64-Debug und zwölf native App-Tests ebenfalls bestanden. Dieser nachfolgende
Dokumentationsabschluss korrigiert nur die Importbasis und erfasst die Abnahme;
Laufzeit-/Testdateien sind unverändert. Die finale CI gilt für den aktuellen
PR-Kopf und wird mit tatsächlicher Lauf-ID/Artefakten im PR geführt.

---

## 02.11.2026 – 0-TP-Guard für Aufstehen/Kriechen (PR #487)

- **Ausgangs-Main-SHA:** `885580202caeafc9787538b6dc1c833b3190a529`. **Eigener Branch:** `fix/chat-a/zero-hp-prone-movement-20261102`. **Pull Request:** https://github.com/ManuEtt/Dnd/pull/487 (Draft bis CI-/Integrationsabnahme).
- **Regellücke:** Ein importierter Legacy-Held mit `hitPoints == 0`, aber ohne `bewusstlos`, bestand bisher die alleinige Konditionsprüfung von `ConditionRules.canMove`. Aufstehen und Kriechen konnten deshalb Bewegungsbudget/Revisions-Event verbrauchen. Regelquelle: Wizards of the Coast LLC, *SRD 5.2.1*, **Damage and Healing → Falling Unconscious**, S. 17, CC BY 4.0, https://www.dndbeyond.com/srd.
- **Implementiert:** positive bestätigte TP, nicht toter Held als Vorbedingung in `app/lib/domain/crawling_movement_rules.dart` und `app/lib/domain/prone_movement_rules.dart`.
- **Tests ergänzt:** `app/test/prone_crawling_rules_test.dart` und `app/test/prone_standing_rules_test.dart`: je eine reproduzierbare 0-TP-Ablehnung aus Legacy-JSON ohne Unconscious, ohne Änderung des ursprünglichen Snapshots; je ein positiver Heilungs-/Bewegungsfall. Vorhandene Controller-/SQLite-Revision-, Rollback- und Neustarttests bleiben unverändert.
- **GETESTET:** Repo-/PR-Konfliktprüfung (27 offene PRs; keine der vier Fachdateien belegt), amtliche SRD-Quelle. Die Quelländerungen und Testdateien wurden auf dem eigenen Branch veröffentlicht. **Flutter-Tests sind noch nicht als bestanden belegt.**
- **NICHT GETESTET:** lokaler Flutter-/Dart-Formatter, Analyzer, Fullsuite, Android-APK, Python und Backend wegen fehlenden SDKs/Netz-Zugriffs. CI-Abnahme auf dem letzten Commit muss separat erfolgen.
- **BLOCKIERT:** kein lokales Flutter-SDK. **Keine Migration:** äußeres JSON, SQLite-Schema, bestehende Spielstände und Ereignisse bleiben unverändert; keine eigenmächtige rückwirkende Zustandskorrektur.
- **NÄCHSTER SCHRITT:** Für PR #487 finale Android-CI einschließlich aller Flutter-Regressionen prüfen und Format-/Analyze-/Testfehler im selben Branch beheben; anschließend Integration durch Chat D koordinieren. Keine vollständige SRD-Implementierung beansprucht.


---

## 02.11.2026 – Chat-D-Vorbereitung zur gemeinsamen A/B/C-Integration

Die vollständigen, einzeln CI-grünen Fachänderungen von #485 (Metamagie)
und #487 (Bewegung bei 0 TP) werden ohne Änderungen ihrer technischen
Blobs im gemeinsamen Integrations-Draft vorbereitet. Beide Chat-A-
Dokumentationseinfügungen sind hier erhalten, weder ersetzt noch
gekürzt. Gesamt-Integrations-CI auf finalem Head noch ausstehend.
Die parallelen Chat-A-PRs und insbesondere andere offene Regelmodule
werden nicht überschrieben oder ohne separate Prüfung gemergt.

---

## 02.11.2026 – Chat-D-Koordination: Originalnachträge PR #478

Der vollständige rein additive Chat-Fachnachtrag aus PR #478 ist nachfolgend erhalten. Die technische Quelländerung wird nur im gemeinsamen Draft aufgenommen; eine vollständige neue Integrations-CI ist vor einem Merge erforderlich.
# Chat A – Metamagie Distant Spell für Touch (02.11.2026)

**Basis-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`
· **Branch:** `feat/chat-a/distant-touch-metamagic-20261102`
· **PR/Commit:** siehe GitHub-PR-Head, Einzel-PR-CI danach.

**Problem / Quelle:** SRD 5.2.1, *Sorcerer → Metamagic →
Distant Spell* (CC BY 4.0). Für **1 Sorcery Point**
darf eine ausdrücklich gewählte Metamagie die
`Touch`-Reichweite auf **30 feet** erhöhen. Eine bloße
Rasternahbereich-Checkbox darf keine größere
Berührungsreichweite vortäuschen.

**Implementiert:** Neues eigenständiges Fachmodul
`app/lib/domain/srd_distant_touch_metamagic_rules.dart`:
bestätigte Sorcerer-/Zaubererstufe 2 und
Metamagie-Freischaltung, getrennte eigene
Zauber-Klassenzuordnung mit individuellem
Zaubergrad, offizielle Katalog- und Touch-Einträge,
ausdrücklich bestätigte Auswahl/Ziel/
Metamagie-Kombination, vorhandener
Zaubereipunkt, bestätigte freie 5-Fuß-Karte
und 0–30-Fuß-Grenze. Unveränderliche
Snapshot-Vorschau ohne Zustandsänderung;
Punktkosten nur als **neue Heldenkopie** zur
späteren gemeinsamen Transaktion vormerkbar.

**Tests angelegt:** zehn neue Gruppen in
`app/test/srd_distant_touch_metamagic_rules_test.dart`,
einschließlich positiver Grenzen, fehlender
Wahl/Klasse/Ressource, Mehrklassen-Quelle,
Zaubergrad, blockierter Karte,
Snapshot-Manipulation, Alt-JSON,
SQLite-Neustart, Retry und stale Revision.
Dart-/Flutter-/Android-/Backend-CI erst
auf finaler PR-SHA als bestanden melden.

**Grenzen:** Keine endgültige Speicherung
der Metamagiewahl in `models.dart`; ein
Bestätigungsbool ist kein dauerhafter
Quellnachweis. Die Fachvorschau darf
**nicht** eigenständig Zauberplätze, TP,
Zauberwirkung oder Sorcery Points
persistieren; der vollständige Cast und
ein atomarer Commit fehlen. Keine
Änderung an Fachdateien der PRs #461,
#463, #472; SQLite3 / JSON1 / Version
unverändert. Gerät, Upgrade, TalkBack
und Release-Signierung nicht geprüft.

**Nächster Schritt:** nach Integration
der Vorbereitungs-/Grid-Bausteine
eine persistierte Metamagiewahl und den
atomaren Cast mit Slot-/Punkt-/Effekt-
Abrechnung inklusive Restart/Retry
und Revisionskonflikt implementieren.

---

---

# Chat A – Raster-Berührungsreichweite fail-closed (02.11.2026)

**Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868` ·
**Branch:** `fix/chat-a/grid-touch-range-20261102` ·
**PR:** nach Veröffentlichung im GitHub-PR-Log.

**Regelbeleg:** Offizielle SRD 5.2.1, *Casting Spells / Range / Touch*,
CC BY 4.0. Berührungszauber verlangen ein Ziel in tatsächlicher
Reichweite. Das existierende 5-Fuß-Raster akzeptierte bisher eine
beliebig entfernte `Touch`-Zelle, sofern nur ein Boolwert
`withinTouchReachConfirmed` gesetzt wurde.

**Implementiert:** Konservativer Zielwächter in
`app/lib/domain/srd_spell_grid_target_rules.dart`:
eigene sowie angrenzende Rasterzellen (0/5 Fuß)
mit bestätigter Berührung zulässig; ab zwei
Rasterfeldern (10+ Fuß) wird auch bei manueller
Berührungsbestätigung vor der Preflight-Buchung
abgelehnt. Blockierte/ungeprüfte Karte bleibt
abgelehnt; `Self` und Distanzzauber unverändert.
Die offizielle Formulierung `within reach` erlaubt
Sonderreichweiten, diese erhalten bewusst **keine**
Freischaltung ohne separaten belegten Spezialmechanismus.

**Tests:** neue Datei
`app/test/srd_spell_grid_touch_range_test.dart`:
eigene/acht Nachbarzellen, entfernte Ziele,
fehlende Berührung/Kartenaufnahme/Hindernisse,
Fern-/Selbstzauber, echte Kleriker-Zaubervorprüfung
mit unveränderten Slots und TP, Legacy-JSON,
SQLite-Neustart/Retry und stale Revision.
Format-/Analyzer-/Flutter-/Python-/Backend-/APK-Ergebnisse
erst nach finaler GitHub-CI als grün markieren.

**Unverändert:** Datenmodelle, Controller,
Engine, Story, UI, DB-/JSON-Schema und Version;
keine fremden PRs, Branches oder Tests geändert.
Parallele offene Chat-A-PRs #448, #453, #461,
#463, #467 und #468 bleiben eigenständig.
Gemeinsame README-/Checkpoint-Zeilen bei
Integration durch Chat D additiv zusammenführen.

**Nicht getestet:** echtes Android-Gerät,
Altinstallations-Upgrade, TalkBack,
Produktivsignierung. **Nächster Schritt:**
belegte Spezialreichweiten für Touch in einem
getrennten Domainbeleg mit negativen
Manipulations-, SQLite- und Revisionsfällen
einführen, ohne den einfachen Bool zu vertrauen.

---

---

# Chat A – SRD-5.2.1-Zaubervorbereitungstausch nach Rast/Stufenaufstieg (01.11.2026)

**Main-Ausgangs-SHA:** `5a88834c98f5aca40395088c20c7e1dc5b587868` ·
**Branch:** `feat/chat-a/prepared-spell-exchange-triggers-20261101` ·
**PR:** nach Veröffentlichung hier und in PR-Beschreibung.

**Quelle:** Offizielle SRD 5.2.1, *Spells → Preparing Spells →
Spell Preparation by Class*, S. 104, CC BY 4.0.

**Problem:** Barde/Zauberer/Hexenmeister dürfen genau einen
Zauber erst beim **eigenen Klassenaufstieg** tauschen;
Paladin/Waldläufer einen bei abgeschlossener langer Rast;
Kleriker/Druide/Magier bei langer Rast beliebig viele der
bisherigen vorbereiteten Zauber. Ungeprüfte Trigger könnten
zusätzliche oder höhergradige Zauber freigeben.

**IMPLEMENTIERT:** Unabhängiges, rein lesendes
`SrdSpellPreparationExchangeRules.preview` mit bestätigtem
eigenem Klassennamen, vor/nach-Charakterzustand,
Klassenzuordnung/Stufenvergleich, offiziellem Zauberkatalog,
Grad-1+-Grenze, gleich großen Vorbereitungslisten und
strenger Anzahl von Austauschvorgängen. Cantrips, unbekannte
Klassen/Zauber, unerworbene Grade, freie Übersetzungen,
unbestätigte Rast und falsche Klassen-Level-ups sind
gesperrt. Magier benötigen getrennte Zauberbuchbestätigung.
Unveränderlicher Vorschauplan mit Snapshot-Revalidierung,
keine Ressourcen-/Rast-/Level-up-/SQLite-Mutation.

**Geänderte Dateien:** neuer Fachcode unter
`app/lib/domain/srd_spell_preparation_exchange_rules.dart`,
elf neue deterministische Testgruppen unter
`app/test/srd_spell_preparation_exchange_rules_test.dart`,
Quellennotiz `docs/SRD_SPELL_PREPARATION_EXCHANGE_20261101.md`,
README sowie additive Checkpoints.

**GETESTET:** Quellen-/Repository-/PR-Inventur und
Testimplementierung durchgeführt. Flutter-/Dart-/Android-CI
bis zu tatsächlichem Laufabschluss **noch nicht** als
erfolgreich melden; nach PR-Erstellung auf finaler SHA auswerten.

**NICHT GETESTET / BLOCKIERT:** echtes Android-Gerät, Altupgrade,
TalkBack und Store-Signierung. Fachintegration der getrennten
PRs #461 (Preflight) und #463 (persistierter Klassenbeleg)
bleibt ausdrücklich aus; diese PRs sind in ihren eigenen
Dateien geschützt. SQLite 3, äußeres JSON 1 unverändert.
Keine aus Narration erfundenen Auslöseereignisse.

**NÄCHSTER SCHRITT:** Nach koordiniertem Merge der
Preflight- und Nachweisbausteine die Klassenauswahl und
den Tauschplan in den bestätigten Rast-/Level-up-Commit
integrieren und Revisionskonflikt/Replay/Neustart prüfen.

---

---

# Chat A – kanonische Klassenaliase für Mehrklassen-Zauberplätze (31.10.2026)

- **Basis-Main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`
- **Eigener Branch:** `feat/chat-a/multiclass-slot-aliases-20261031`
- **Produktivcode-Commit:** `edd8be956ca9228c8d14dbbbfcdbb37c27118bc4`
- **Testkorrektur-Commit:** `c35a625b4b336f58c52ccab2c0ae8b8cb29eb48a`
- **Pull Request:** wird nach Abschluss der Branchdokumentation erstellt; Main wird nicht verändert.

## Ausgangsproblem / Akzeptanz

`MulticlassRules.combinedSpellcasterLevel` verglich rohe Namen, während
`findSrdClass` vorhandene deutsche, englische und feminine SRD-Klassenaliase
kennt. Beispielsweise erhielt `Magier 5` drei Zauberplatzgrade, `Wizard 5`
aber keine normalen Zauberplätze. Nachweis aus Main-Quellcode und SRD 5.2.1
*Multiclassing*, gedruckte S. 25 (CC BY 4.0,
https://www.dndbeyond.com/srd). Ziel: dieselbe Berechnung für bestätigte
Aliase; Halbzauberer einzeln aufrunden; Paktmagie nicht hinzurechnen;
unbekannte Namen nicht erraten; rohe gespeicherte Klassennamen erhalten.

## IMPLEMENTIERT

- `app/lib/domain/multiclass_rules.dart`: nur für die lesende
  Zauberstufenberechnung die bereits bestehende
  `findSrdClass(name)?.name`-Auflösung verwenden. Nicht-positive
  Klassenstufen ergeben keine Beiträge; bestätigte Vollzauberer zählen
  voll, Paladin/Waldläufer halb aufgerundet, Hexenmeister-Paktmagie
  getrennt. Keine Änderung an der Klassenidentität im Spielstand.
- `app/test/multiclass_spell_slot_alias_test.dart`: sieben neue
  deterministische Testfälle für Vollzauberer, Halbzauberer,
  Mehrklassenkombinationen, Paktmagie, Ablehnung unbekannter Klassen,
  Alt-JSON sowie SQLite-Neustart/Retry/Revisionskonflikt.
- Keine Änderung an `models.dart`, `game_engine.dart`,
  `rules_api.dart`, Controller, Datenbankschema, Backend, UI,
  SRD-Lizenzdateien oder Versionsnummer. SQLite **3** und JSON **1**
  bleiben erhalten; kein Migrationslauf, keine rückwirkende
  Spielstandänderung.

## GETESTET

Quellcode, vorhandener Klassenresolver, angrenzende Zauber- und
Mehrklassenregressionen und der GitHub-Stand wurden eingesehen;
der Fehlerpfad wurde auf Basis des tatsächlichen Codes identifiziert.
**Noch kein ausgeführter neuer Dart-/Flutter- oder SQLite-Test.**
Die tatsächlichen GitHub-Actions-Ergebnisse für den finalen PR-HEAD sind
separat nachzuweisen; bestehende grüne Main-CI gilt nur für Main.

## NICHT GETESTET / BLOCKIERT

Lokale Ausführung von `flutter`, `dart` und APK-Build in dieser
Umgebung nicht möglich, da Flutter-/Dart-SDK fehlt. GitHub-CI folgt.
Ein echter Android-Geräte- und Altversionsupgrade-Test ist offen.

## Koordination / nächster Schritt

Vor Arbeitsbeginn waren nur PRs #446 (Story), #447 (UI), #448
(Chat A: andere neue Domain-/Testdateien), #449 (Android-Backup)
offen. Keine dieser PRs verändert die zwei Fachdateien dieses Pakets.
README und zentraler Checkpoint sind als gemeinschaftliche Dokumente
bei der Integration von Chat D additiv zu vereinigen.

**Nächster unabhängiger Chat-A-Schritt:** Erst nach CI-/PR-Abnahme
die SRD-Abweichungen zwischen Klassen-Freischaltungen und
tatsächlich regelgeprüften vorbereiteten Zaubern anhand von
`RULE-CHARACTER-CREATION-MULTICLASS-SPELLCASTING` untersuchen.
Akzeptanz: pro Klasse und Stufe keine unbelegten vorbereiteten
Zauber freigeben; dokumentierte positive/negative deterministische
Tests und Alt-JSON-Verträglichkeit.

---

---

# Chat A – Mehrklassen-Zaubervorbereitung der gewählten Klasse bestätigen (01.11.2026)

**Basis-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868` ·
**Branch:** `feat/chat-a/multiclass-prepared-source-20261101` ·
**Laufzeit-Commit:** `b72cdd4230c90eead9870dad8cd3b54cad5cea05` ·
**Tests:** `dda176dfe80df5e5c50045994520ee33a3ea59f5` ·
**PR:** wird nach Sicherung der Branchdokumentation eröffnet.

## Ausgangsproblem / Akzeptanz
Bei zwei eigenen qualifizierten Zauberklassen kann die bisherige globale
`hero.spells`-Liste nicht nachweisen, welcher Klasse ein auf beiden
Listen vorhandener Zauber zugeordnet wurde. SRD 5.2.1 *Multiclassing,
Spells Prepared* (S. 25, CC BY 4.0) verlangt getrennte Vorbereitung.
Ohne explizite Klassenbestätigung ist diese mehrdeutige Freigabe zu
verweigern; einzelne nachweislich qualifizierte Klassen bleiben
unverändert bedienbar; Zaubertricks ebenso geschützt.

## IMPLEMENTIERT
`app/lib/domain/srd_spell_preflight_rules.dart` ergänzt das optionale
`preparedForCastingClassConfirmed` (Standard `false`). Nur wenn
**beide** eigenen SRD-Klassen den gewählten Zauber auf ihrer Klassenliste
haben und mit ihren **individuellen Stufen** vorbereiten könnten,
verlangt die Vorprüfung den ausdrücklichen Nachweis für
`castingClass`. Auch mit Bestätigung gelten weiterhin Klassengrad-,
Liste-, Vorbereitungs-, Ressourcen-, Komponenten-, Ziel- und
Snapshot-Schranken.

Acht deterministische positive/negative Fallgruppen unter
`app/test/srd_multiclass_prepared_source_test.dart`, einschließlich
JSON-Neustart, echter SQLite-Rekonstruktion, unveränderter
Ressourcen und verweigertem alten Snapshot. Fachnotiz:
`docs/SRD_MULTICLASS_PREPARED_SOURCE_20261101.md`.

**Kompatibilität:** keine neuen JSON-/DB-/Event-Felder, SQLite 3,
JSON 1, App-Version unverändert; keine Migration, kein UI-/Controller-/
Story-Eingriff. Eine bloße Bestätigung ist noch kein persistierter
per-Klasse-Vorbereitungsnachweis. Die globale SRD-Coverage bleibt offen.

## GETESTET / NICHT GETESTET
Quellcode, verbindliche Projektdokumente und aktuelle PR-Dateien
#446–#458 geprüft. Acht neue Testgruppen geschrieben.
Flutter-/Dart-SDK steht lokal nicht bereit; die neuen Dart-/SQLite-Tests,
vollständige CI, Debug-/Alpha-APKs und natives Gradle sind **noch
nicht als ausgeführt oder erfolgreich bestätigt**. Die
Ergebnisse werden auf dem finalen PR-HEAD anhand von Actions geprüft;
ältere Main- oder fremde PR-Ergebnisse zählen nicht.

## BLOCKIERT / NÄCHSTER SCHRITT
Kein Schreibzugriffskonflikt an den Fachdateien. Parallel ändern andere
PRs README und `docs/CODEX_CHECKPOINT.md`; Chat D muss
Dokumentationsbeiträge bei der Integration erhalten. Ein reales
Android-Gerät/Upgrade/TalkBack fehlt weiterhin.

**Genau nächster unabhängiger Chat-A-Schritt:** Versionierte
klassebezogene vorbereitete Zauberauswahl als ausdrücklich
bestätigter und rückwärtskompatibler Nachweis aufbauen. Kriterien:
historische globale Liste unverändert importierbar, unbekannte
alte Zuordnung nicht raten, per-Klasse-Kapazität und Stufengrenzen
quellengeprüft; positive/negative Domain-, SQLite-/Retry- und
Abbruchtests. Gemeinsame Modelle erst nach Konfliktabgleich ändern.

---

---

## Chat A – Zauberwirkzeit: unsichtbare Trigger-Steuerzeichen abweisen (02.11.2026)

**Ausgangs-main:** `84437e4e92d735e179bb2585427b46a10451951d`. **Eigener Branch:** `feat/chat-a/casting-time-trigger-control-20261102`. **Implementierungs-Commit:** `2f8804aca425e55053a81facd2982e3e936b8bd8`. **Pull Request:** [#500](https://github.com/ManuEtt/Dnd/pull/500) (Draft, keine Integration). **App-Version:** `0.8.49+99` unverändert.

**Problem:** Die ausgelösten Wirkzeit-Angaben für Reaktionen/Bonusaktionen akzeptierten nach dem festen Prefix auch die bislang ungefilterten Unicode-Steuerzeichen U+206A–U+206F (veraltete Bidi-Steuerzeichen) und U+FFF9–U+FFFB (Interlinear-Anmerkungen). So konnte der öffentliche `SrdSpellDefinition`-Konstruktor optisch irreführende Trigger klassifizieren lassen. Die vorhandene Ein-Zug-Regelfreigabe blockierte solche Trigger bereits; die Metadatenvalidierung selbst war unvollständig.

**IMPLEMENTIERT:** `app/lib/domain/srd_spell_casting_time_rules.dart` erweitert die vorhandene strenge Zeichenprüfung um genau diese neun Formatcodes. Neue Datei `app/test/srd_spell_casting_time_control_guard_test.dart`: acht gültige Trigger aus dem tatsächlichen Katalog, reguläres `Magic Missile`, neun negative Steuerzeichen-Varianten pro Trigger einschließlich beider öffentlichen Prüfpfade. Keine Umdeutung eines Auslösers; keinerlei automatische Zauberwirkung.

**GETESTET:** Die neue Testdatei und der Regex wurden überprüfbar in GitHub gesichert; **keine tatsächlich erfolgreich ausgeführten Dart-/Flutter-Tests** in dieser Sitzung. Die lokal verfügbare Umgebung besitzt kein Dart/Flutter-SDK.

**NICHT GETESTET:** `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, vollständiger GitHub-Workflow auf finalem PR-HEAD, reales Android-Gerät. Python-/Backend-Tests ebenfalls lokal nicht ausführbar ohne Repository-Checkout (kein GitHub-DNS in der Containerumgebung). Aktuelle CI muss anhand von #500 geprüft werden; andere grüne Läufe zählen nicht als Abnahme.

**BLOCKIERT:** Lokaler GitHub-Clone/Dart-SDK. Keine bestätigte CI- oder Gerätetestsperre; PR bleibt bis zum nachgewiesenen vollständigen Testlauf Draft.

**NOCH NICHT IMPLEMENTIERT:** Einzelfallbasierte Prüfung, ob ein Triggertext zum amtlichen Zauber gehört, und die tatsächlich ausgelöste Reaktions-/Bonusaktionsbuchung. Die Metadatenklassifikation ist keine Autorisierung und erteilt keine Kosten-/Aktionsfreigabe.

**Dateien/Kompatibilität:** Fachmodul, neuer Test, README, zentraler Checkpoint, Chat-A-Checkpoint und Fachnachweis. SQLite 3, bestehendes Kampagnen-JSON 1, Heldendaten und App-Version unverändert; **keine Migration**, kein bestehender Spielstand verändert. Quellregel SRD 5.2.1 „Spells / Casting Time / Reaction and Bonus Action Triggers“, Wizards of the Coast LLC, CC BY 4.0, https://www.dndbeyond.com/srd. Bestehende Lizenzhinweise unverändert.

**NÄCHSTER SCHRITT (genau ein eigenständiges Paket):** Die **Dauer-Metadatenprüfung** in `srd_spell_duration_rules.dart` separat gegen unsichtbare Formatzeichen innerhalb bestätigter Zeitangaben prüfen; nur bei reproduzierbarem Befund minimale Abwehr und positive/negative Katalog-Regressionen, ansonsten keinen Code ändern. Zunächst #500 CI abnehmen und vor einem neuen Branch die offenen PRs neu vergleichen.

---

---

## 03.11.2026 – Chat A: PR #515 CI-Testfehler korrigieren

**03.11.2026 – PR #515, gezielte CI-Korrektur:** Die vollständigen Android-Workflows [#41532714674](https://github.com/ManuEtt/Dnd/actions/runs/41532714674) und [#41532722057](https://github.com/ManuEtt/Dnd/actions/runs/41532722057) auf Commit `7ae3aaf5a73e` waren **rot: 2.854 Flutter-Tests bestanden, drei neue fehlgeschlagen**. Ausschließlich die drei Testannahmen waren falsch: Ein ungültiger, manipuliert konstruierter Held kann kein gültiges `rules.blocked`-Event erzeugen; `GameEngine._commit` ruft `Campaign.fromJson` auf und weist den nicht serialisierbaren Zustand mit `FormatException` zurück. **IMPLEMENTIERT** auf Code-Commit `49745fc6232f7f8d3ddd711bbffd4aa1eaea52c0`: Testfälle erwarten `FormatException`, prüfen unverändertes ursprüngliches Helden-JSON, kein gespeichertes Event, und keine RNG-Nutzung. Die zwei gültigen Kurzrastfälle bleiben unverändert. Produktionscode und Persistenzschema wurden bei dieser Korrektur nicht geändert. **GETESTET:** Der ursprüngliche 2854/3-CI-Befund ist belegt; zwei Zusatz-Workflows (Mönch/Eldritch) zum Vorgängercommit grün. **NICHT GETESTET:** vollständige Flutter-/Android-CI auf dem korrigierten finalen PR-HEAD, Android-Gerät, Altversionsupgrade. **BLOCKIERT:** PR bis vollständiger grüner finaler CI als Draft belassen. **NOCH NICHT IMPLEMENTIERT:** vollständiger World-Time-Nachweis für Dauer/Unterbrechung der Rast. **Nächster Schritt:** End-HEAD von PR #515 anhand der vollständigen GitHub-CI prüfen und erst dann zur Integration an Chat D übergeben; kein ungeprüfter Merge.

---

## Chat A – Kurzrast ohne Trefferwürfel: Ressourcen vor Recovery prüfen (02.11.2026)

**Main beim Branchstart:** `a2f22eaceb344aaced12d0ad548b813aa44d544f`. **Branch:** `fix/chat-a/short-rest-zero-dice-preflight-20261102`. **Implementierungs-Commit:** `fe80087dde1ac9b336b3cc1378c67ad73d977d3d`. **PR:** [#515](https://github.com/ManuEtt/Dnd/pull/515) (Draft). **App:** 0.8.49+99, unverändert.

**Ausgangsproblem:** Die bereits geprüfte Kurzrast mit echten Trefferwürfelwürfen validierte die ursprünglichen ausgegebenen Klassen-, Pakt- und Hit-Dice-Ressourcen. Zwei `GameEngine`-Sonderpfade für *null* ausgegebene Trefferwürfel führten dagegen `SpellcastingRules.afterShortRest` direkt aus. Bei beispielsweise einem Kämpfer ohne Hexenmeisterstufe und fingierten `spentPactSlots=1` wurde der Wert auf null zurückgesetzt, bevor ein Paktpoolcheck ihn abweisen konnte. Auch auf volle TP bzw. aufgebrauchte Trefferwürfel darf eine Rast keine manipulierten Quellressourcen still reparieren.

**IMPLEMENTIERT:** `RestRules.validateShortRestResources(hero)` prüft einen unveränderten originalen Helden auf Rastfähigkeit, `ClassFeatureResources.validate`, `ClassResourceRules.validate`, `SpellcastingRules.availablePactSlots` und `availableHitDice`. Der bestehende `RestRules.shortRest`-Würfelpfad nutzt denselben Gate. `GameEngine.act` ruft ihn am Beginn jeder erkannten kurzen Rast vor den bisherigen Sonderpfaden auf. Keine Klassen-, Kosten- oder Erholungsformeln verändert; ein ungültiger Wert wird mit vorhandenem `rules.blocked`-Ergebnis abgewiesen, ohne TP/Ressourcen oder Wurf zu ändern.

**Regressionen:** `app/test/short_rest_zero_hit_dice_resource_preflight_test.dart` umfasst fünf deterministische Tests: Kämpfer mit ungültigem Paktverbrauch bei vollen TP; denselben bei aufgebrauchten Trefferwürfeln; fingierte Klassenressource; gültige Second-Wind-Regeneration bei vollen TP; gültige Paktregeneration des verwundeten Hexenmeisters mit aufgebrauchten Trefferwürfeln. Alle Fälle prüfen keine RNG-Nutzung; bei Ablehnung unverändertes Held-JSON, bei Erfolg Ressourcen-/Hit-Dice-Daten und die JSON-Wiederaufnahme.

**GETESTET:** GitHub-Branch und PR sind erfolgreich angelegt, technische Code- und Testdateien vorhanden. **Noch kein tatsächlich erfolgreicher aktueller Dart-/Flutter-/Python-/Backend-Testlauf behauptet.** Die finale CI steht bis zum tatsächlichen Workflowabschluss aus; ältere grüne Testläufe anderer Commits sind keine Abnahme.

**NICHT GETESTET:** `python3 scripts/verify_project.py`, `python3 scripts/check_domain_boundaries.py`, `python3 scripts/srd_coverage.py --json`, `python3 -m unittest discover -s scripts/tests -v`, `cd backend && npm ci && npm run typecheck && npm run build && npm test`, `cd app && flutter pub get && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build apk --debug` auf finalem Commit. Realgerät, TalkBack, Versionsupgrade und Produktivsignierung nicht geprüft.

**BLOCKIERT:** Die GitHub-CI/Format-/Analyse- und App-Tests müssen noch auf diesem finalen Stand bestätigt werden. Kein Merge und keine automatische Branchlöschung; UI und Datenmodelle anderer Chats bleiben unverändert.

**NOCH NICHT IMPLEMENTIERT:** Genaue Dauer und Unterbrechung einer Rast durch eine versionierte Weltzeit, Gerätetest, umfassende SRD-Abdeckung. Die Null-HD-Regeneration war bereits vorhanden; dieses Paket verhindert nur eine Validierungsumgehung.

**Dateien:** `app/lib/domain/rest_rules.dart`, `app/lib/domain/game_engine.dart`, `app/test/short_rest_zero_hit_dice_resource_preflight_test.dart`, `docs/SRD_SHORT_REST_ZERO_DICE_PREFLIGHT_20261102.md` sowie additive README-/Checkpoint-Einträge. SQLite 3, Kampagnen-JSON 1, bestehende Spielstände und `app/pubspec.yaml` bleiben unverändert; keine Migration. Quelle: amtliches D&D SRD 5.2.1, „Rules Glossary / Short Rest“ und „Warlock / Pact Magic“, Wizards of the Coast LLC, CC BY 4.0, https://www.dndbeyond.com/srd.

**NÄCHSTER SCHRITT (genau ein unabhängiges Paket):** Den Kurzrast-Null-HD-Übergang über den vorhandenen Controller samt SQLite-Neustart und idempotentem Retry für einen *gültigen* Hexenmeister separat prüfen. Abnahme: ein gespeicherter bestätigter Rast-Event, keine zweite Paktregeneration bei Request-ID-Wiederholung, veraltete Revision wird abgewiesen, keinerlei Reparatur ungültiger Herkunftsdaten; vor Beginn offenen PR-Dateiabgleich wiederholen.

---


---

# Chat A – Unsichtbare Materialstapel-IDs abweisen (03.11.2026)

**Basis-main:** `a786ad61c508da1a9ec1a24f85100a4a994182c8`.
**Eigener Branch:** `fix/chat-a/spell-material-id-invisible-20261103`.
**Code-/Test-HEAD vor Dokumentation:** `79a6a0509d393b0681f662e67427f8a951575f90`.
**Pull Request:** [#520](https://github.com/ManuEtt/Dnd/pull/520) (Draft).
**App-Version:** `0.8.49+99` unverändert.

### Ausgangslage und Regelgrenze

Die ID-Prüfung für Inventarstapel verhinderte bereits gängige bidi- und
Zero-Width-Formatzeichen, ließ aber U+206A–U+206F (veraltete
Richtungsformatierung) und U+FFF9–U+FFFB (Interlinear-Anmerkungen) durch.
Das betraf sowohl auditierte SRD-Komponentenbindungen als auch die
bestätigte, atomare Inventar-/Slotbuchung. SRD 5.2.1,
*Spells / Components* (CC BY 4.0), liefert den fachlichen Kontext;
die Unicode-Sperre ist eine technische Prüfmaßnahme, keine neue SRD-Wirkung.

### IMPLEMENTIERT

- `app/lib/domain/srd_spell_inventory_id_rules.dart`: die bestehende
  zentrale Negativliste um exakt neun Formatcodepunkte ergänzt.
- `app/test/srd_spell_inventory_id_legacy_format_test.dart`: positive
  internationale ID-Fälle; negative Fälle für alle neun Codepunkte am
  Ende und in der Mitte; negatives auditiertes Secret-Chest-Material;
  negative Revivify-Ressourcenbuchung ohne Mutation des ursprünglichen
  Helden-/Inventar-JSONs; positive gültige Revivify-Buchung.
- Nicht geändert: `models.dart`, `game_engine.dart`, Controller, Story,
  Backend, Materialpreise, Inventar-Schema oder andere Chat-Zuständigkeiten.

### GETESTET

- Main-SHA, offene PRs, vollständige Fachpfad-Überschneidungen,
  bestehende Tests und letzte Main-Actions geprüft.
- Eigener Branch ab beobachtetem `main` erstellt; die beiden Fachdateien
  tatsächlich per GitHub geschrieben; Draft-PR #520 eröffnet.
- Lokale Python-Regulärausdruck-Gegenprüfung bestätigte die bisher
  fehlende Sperre für U+206A–U+206F und U+FFF9–U+FFFB. Dies ist kein
  Dart-/Flutter-Test und kein Beleg für lauffähige App oder APK.

### NICHT GETESTET / BLOCKIERT

- `flutter test test/srd_spell_inventory_id_legacy_format_test.dart`,
  vollständiges `flutter test`, Formatierung, `flutter analyze`, APK-Build,
  Python-Skripte, Backend-Tests und reale Geräte-/Upgrade-Abnahme.
- In dieser Laufzeit sind Dart-/Flutter-SDK sowie ein GitHub-Checkout
  wegen fehlender DNS-Auflösung nicht verfügbar; finale GitHub-CI
  muss an der endgültigen PR-HEAD-SHA getrennt abgenommen werden.

### KOMPATIBILITÄT / RISIKEN

Keine SQLite-/JSON-Migration, keine Änderung gespeicherter Spielstände,
kein erzwungenes Umbenennen. Vorhandene historische IDs mit genau diesen
Formatzeichen werden bei der nächsten regelgeprüften Materialbuchung
abgewiesen, ohne Bestand oder Ressourcen stillschweigend zu verändern.
Neue Regelwirkungen, KI-Entscheidungen und Materialwerte werden nicht
automatisch bestätigt. Änderungen in fremden PRs werden nicht überschrieben.

### NÄCHSTER SCHRITT (ein Paket)

Nach vollständiger CI-Abnahme des finalen PR-HEAD unabhängig prüfen,
ob eine weiterhin offene klassenbezogene Zaubervorbereitungsgrenze auf
aktuellem `main` reproduzierbar ist. Akzeptanz: eigener isolierter
Fachpfad, positive/negative SRD-Regressionsfälle und keine Änderung
von `models.dart` während #463 offen ist.

---


---

# Chat A – Verlässliche SRD-Komponententexte vor Preis-/Verbrauchserkennung (03.11.2026)

**Basis-main:** `bd423f4586e355ef888fe8ede1a0cd13fdc48dd4`.
**Arbeitsbranch:** `fix/chat-a/spell-component-format-20261103`.
**Fachcode-/Test-HEAD:** `48cc73d1b466080fd4703413e20a5ed909591942`.
**PR:** [#523](https://github.com/ManuEtt/Dnd/pull/523) (Draft).
**App-Version:** `0.8.49+99` unverändert.

## Ausgangsproblem / Nachweis

Vorher ließ `SrdSpellDefinition.validateComponentMetadata` unsichtbare
Zeichen innerhalb von `M (...)` zu, solange das V/S/M-Grundformat stimmte.
Ein scheinbar identischer `Revivify`-Text mit U+206A mitten in
`consumes` besteht die syntaktische Komponentenprüfung, aber die
separate Consumption-Worterkennung trifft nicht mehr zu.
Selbst ein direkt konstruiertes `SrdSpellDefinition` konnte die
Verbrauchsvoraussetzung dadurch falsch klassifizieren.

## IMPLEMENTIERT

- `app/lib/domain/srd_spell_catalog.dart`: unsichtbare C0/C1-Steuerzeichen,
  Soft-Hyphen, Bidi/Zero-Width, veraltete Formate und Interlinear-Zeichen
  bereits bei der Komponenten-Metadatenprüfung fail-closed abweisen.
- `app/test/srd_spell_component_invisible_format_test.dart`: vier
  Testgruppen für bekannte Katalogmetadaten, legitime internationale
  Materialbeschreibungen, alle neun U+206A–U+206F/U+FFF9–U+FFFB innerhalb
  von Verbrauchs- und Preisworten, JSON-Eingabe und unveränderte
  Helden-/Slotdaten bei fehlgeschlagenem Preflight sowie positiven
  `Revivify`-Verbrauchsvorbehalt.
- `README.md`, `docs/CODEX_CHECKPOINT.md` und dieser Checkpoint
  werden additiv fortgeschrieben; alte Einträge bleiben erhalten.

## GETESTET

- Verfügbaren Main-/PR-/Branch-/Actions-Stand per GitHub geprüft.
- Reproduzierender JavaScript-Test bestätigte, dass ein unsichtbares
  Zeichen das Wort `consumes` zerlegt und der bisherige Regex den
  Materialverbrauch in der manipulierten Textvariante nicht erkennt.
- Quell- und Teständerungen im eigenen GitHub-Branch gesichert.
  Vollständige Flutter-/CI-Abnahme ist davon getrennt.

## NICHT GETESTET / BLOCKIERT

- Noch nicht als grün belegt: `flutter analyze`,
  `dart format --output=none --set-exit-if-changed lib test`,
  `flutter test test/srd_spell_component_invisible_format_test.dart`,
  vollständige Flutter-/Python-/Backend-Suite, Android-Debug-APK,
  tatsächlicher Android-Geräte-/Upgrade-Test.
- CI darf nur auf finaler Commit-SHA als `completed/success` gelten.
- Lokale Flutter-Laufzeit/Checkout nicht verfügbar; GitHub Actions
  liefert den maßgeblichen überprüfbaren Nachweis.

## KOMPATIBILITÄT / KONFLIKTE

- Keine Änderung an gespeicherten Spielständen, SQLite/JSON-Schema,
  App-Version, bestehenden Zauberressourcen oder der Erzähl-API.
- Neue Fail-closed-Prüfung kann manipulierte importierte Zauberkatalogwerte
  ablehnen, führt aber weder heimliche Datenmigration noch Slot-Abzug aus.
- Offen: #463 (Klassen-Vorbereitungsbeleg), #520 (Materialstapel-IDs),
  Integrations-PRs von Chat D. Keines dieser Pakete überschreibt
  `srd_spell_catalog.dart` oder den neuen Testpfad.
- **Lizenz:** SRD 5.2.1, *Spells / Components*, CC BY 4.0;
  keine allgemeine SRD-Vollabdeckung oder neue magische Wirkung behauptet.

## NÄCHSTER SCHRITT (genau ein unabhängiges Paket)

Nach erfolgreich abgenommener kombinierter CI den
klassenbezogenen Vorbereitungspfad gegen aktuelle Main-Integration
von #463 prüfen; nur bei reproduzierbarer Lücke ein separates
Positiv-/Negativpaket ohne parallele Änderung an `models.dart` wählen.

---


---

# Chat A – Persistenter klassenbezogener Vorbereitungsnachweis (01.11.2026)

**Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868` · **Branch:**
`feat/chat-a/class-prepared-spell-record-20261101` · **PR:** folgt auf Branch-Sicherung.

**Problem:** Die historische globale Zauberliste hat keine Klassenherkunft.
Ein boolescher aktueller Nachweis aus dem offenen PR #461 wird nicht dauerhaft
als eigene Auswahl im bestehenden JSON gespeichert. SRD 5.2.1
*Multiclassing – Spells Prepared*, S.25, CC BY 4.0.

**IMPLEMENTIERT:** `SrdPreparedSpellRecord` v1 speichert unveränderliche
per-Klasse-Auswahl und deren Klassen-/Zauberlisten-Snapshot; `confirm`
prüft ausdrückliche Bestätigung, eigene kanonische SRD-Klassen,
Katalogklassen/individuelle Klassenstufen, Dubletten und vorhandene Zauber.
`isPreparedForClass` ist read-only und revalidiert den SRD-Katalog.
`HeroCharacter` speichert `preparedSpellRecord` optional im bisherigen
Schema; alte JSONs bleiben identisch, `copyWith` verwirft Nachweise bei
Klassen-/Stufen-/Zauberlistenänderung; Ressourcenänderungen behalten sie.
Keine UI-/Controller-/Engineänderung, keine SQLite-Migration, keine
automatische Ableitung aus KI/Legacytext.

**Dateien:** `app/lib/domain/models.dart`,
`app/lib/domain/srd_prepared_spell_record.dart`,
`app/lib/domain/srd_class_prepared_spell_rules.dart`,
`app/test/srd_class_prepared_spell_record_test.dart`,
`docs/SRD_CLASS_PREPARED_SPELL_RECORD_20261101.md`,
README, zentraler sowie persönlicher Checkpoint.

**GETESTET:** neun neue deterministische Testgruppen geschrieben
einschließlich negativem Import, JSON-Roundtrip, tatsächlichem
SQLite-Neustart, idempotenter Revision und stale write. Ausführung
und GitHub-Actions-Status auf finalem Commit nach Veröffentlichung
verifizieren; keine vorweggenommene grüne CI.

**NICHT GETESTET:** reales Android-Gerät, Upgrade/Store-Signierung.
**BLOCKIERT:** vollständige Integration in den realen
Zauberpreflight hängt von der koordinierten Review des
offenen [PR #461](https://github.com/ManuEtt/Dnd/pull/461) ab;
dessen Fachdatei bleibt unberührt. Gemeinsame
Dokumentation bei späterem Merge durch Chat D erhalten.
SQLite 3, äußeres JSON 1, App-Version unverändert.

**NÄCHSTER SCHRITT:** nach Integration von PR #461
vorhandene gespeicherte Klasse statt bloßes Bestätigungsflag
als optionalen starken Nachweis in dessen Vorprüfung
verwenden, einschließlich falscher Klasse/Alterung/Retry/
SQLite und eigener Stufenlimits. Vollständige
Vorbereitungsanzahl bleibt separat.

---


---

## 01.11.2026 – Chat A: Klassenprüfung vor Konzentrationswürfen

Entwicklungsstand **0.8.50+100**, Branch
`fix/chat-a/concentration-class-preflight-20261101`, Code/Test
`37604994828745ac44e48d8e2f628024f2f355e2`, Basis-Main `5a88834c`.
Die vorhandene Klassen-/Stufen-/Rettungswurf-Übungsprüfung wird jetzt auch vor
dem tatsächlichen Konzentrationswurf und vor einer separaten W20-Auflösung
verwendet. Unbekannte oder widersprüchliche Klassen gewähren keinen Mönchsbonus.
Der deutsche Schadensdialog zeigt den Fehler ohne Teiländerung; nach expliziter
Klassenkorrektur bleibt der normale Ablauf ausführbar. Alte Profile bleiben
lesbar, keine SQLite-/JSON-Migration. SG 10–30 war bereits zuvor umgesetzt.

**GETESTET:** 68 neue Tests (58 Domain, 8 Engine/SQLite, 2 echte UI-Flows) und
42 bestehende Regressionen: **110 gezielte Tests bestanden**, Analyzer sauber.
Die neuen Domänentests auf unverändertem Main: 25 bestanden / 33 fehlgeschlagen;
mit Fix alle 58 bestanden. **Vollständig lokal bestanden:** 2.778 Flutter-,
262 Python- und 76 Backend-Tests, 579 Dart-Dateien ohne Formatänderung,
Analyse/Backend-Typecheck/Build/Protokollsmoke. Zusätzlich ARM64-Debug-APK und
**13 native JUnit-Tests** ohne Fehler oder Skip. Zwei Android-Vorläufe scheiterten
am vollen Datenträger; nach Bereinigung ausschließlich erzeugter Caches bestand
die Wiederholung. Quellen, Spielstände und frühere Artefakte blieben erhalten.
[PR #468](https://github.com/ManuEtt/Dnd/pull/468) ist gesichert; vollständige finale
GitHub-CI auf seinem aktuellen Head separat abwarten. Kein Main-Merge behauptet.
**NICHT GETESTET:** echtes Androidgerät/TalkBack, installiertes Upgrade,
produktive Signierung. **NOCH NICHT IMPLEMENTIERT:** vollständige Konzentrations-
automation und Klassenprüfung aller allgemeinen Wiederholungswürfe.
[Fachbericht und Grenzen](CHAT_A_CONCENTRATION_CLASS_PREFLIGHT_20261101.md).

Nächster Schritt nach Abnahme: allgemeine Klassen-Wiederholungen vor Würfel und
Ressourcenverbrauch auf dieselbe konsistente Klassenherkunft prüfen. Vorher
aktuelle PRs abgleichen; offene #453/#461/#463/#448 nicht erneut implementieren.
Die nachfolgenden früheren Entwicklungsstände sind historische Momentaufnahmen.

---

**Quelle/Requirement:** SRD 5.2.1 S.179 und52, CC BY4.0,
`RULE-SPELLS-CONCENTRATION-SAVING-THROWS` bleibt partial. Gemeinsamer Validator
unverändert aus vorbereitender Evidenz extrahiert, keine erfundenen Bestätigungen.
**Dateien:** drei spezialisierte Domainmodule, drei neue Testdateien,
`app/pubspec.yaml`, konservativer Requirement-Nachweis und Dokumentation.
Keine Änderungen an models/GameEngine/Controller/SQLite/Story/UI-Quellen.
**Patchbasis:** vollständiger Main-SHA5a88834c98f5aca40395088c20c7e1dc5b587868.
**BLOCKIERT:** nur finale GitHub-CI und spätere koordinierte Integration;
kein SDK-Zugriffsblocker. Echte Geräteabnahme bleibt offen.

---


---

## 02.11.2026 – Main2e9 integriert, kombinierte lokale Prüfungen bestanden

Main `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1` aus #471 ist regulär
in denselben Entwicklungsbranch integriert; ursprüngliche Basis war `5a88834c`.
Der abschließende Mergecommit ist über [PR #473](https://github.com/ManuEtt/Dnd/pull/473)
ermittelbar. Keine Quellkonflikte; einziger Markdown-Konflikt im Chat-A-Checkpoint
additiv gelöst, alle Main-Beiträge erhalten. Die eigenen 51 Guardzeilen und ihr
Dateihash bleiben unverändert. SQLite3/JSON1 unverändert, keine Migration.

**GETESTET auf dem kombinierten Stand:** **182 gezielte Flutter-Regressionen**
mit den eigenen UI-/SQLite-Fällen und den neuen Main-Paketen; **275 Pythonfälle**,
Projekt-/Importgrenzen-/SRD-Prüfung, **582 Dartdateien ohne Formatänderung** und
saubere Analyse. Neuer **ARM64-Debug-Build und 14 native JUnit-Tests** ohne
Fehler, Error oder Skip bestanden. Die vollständige lokale frühere Suite
**2.782 Flutter /262 Python /76 Backend** gehört ausdrücklich zum Vorgänger8dd
auf Basis5a; sie ist kein behaupteter neuer kombinierter Vollpass.

**OFFEN:** vollständige CI des aktuellen abschließenden Merge-Heads, optimierte
Alpha und reale Geräte-/TalkBack-/Upgrade-/Produktivsignierungsabnahme.
[PR-Checks](https://github.com/ManuEtt/Dnd/pull/473/checks) abwarten; PR bleibt
bis zur tatsächlichen CI-/Artefaktabnahme Draft. Kein Code-/SDK-Blocker bekannt.
Der aktuelle Quellencheckpoint/Patch wird gegen **Main2e9** erstellt; frühere
8dd-/5a-Archive bleiben unverändert erhalten. Main nicht direkt verändert.
Allgemeiner initialer manueller Rettungswurf bleibt das nächste getrennte Paket;
beide Klassen-Requirements weiterhin partial, Gesamt-SRD/Charakterassistent offen.

**Nachfolgend historische Prüf- und Checkpointstände vor Main2e9:**

## 02.11.2026 – lokale Vollabnahme des Chat-A-Pakets bestanden

**0.8.51+101**, Basis-Main `5a88834c98f5aca40395088c20c7e1dc5b587868`,
Branch `fix/chat-a/saving-throw-class-preflight-20261102`. Laufzeit-/Testcommit
`de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038`, früher Dokumentationscheckpoint
`d5cf52f1c27ecdb0f01f0ce461788cde12449310`. Nur Dokumentation folgt danach;
Laufzeit-/Testcode unverändert. [PR #473](https://github.com/ManuEtt/Dnd/pull/473)
ist Draft; die **[Checks des finalen aktuellen PR-Heads](https://github.com/ManuEtt/Dnd/pull/473/checks)**
sind separat abzunehmen. Kein Main-Merge und keine erfolgreiche neue CI behauptet.

**GETESTET:** `bash scripts/check.sh` vollständig mit Exit 0 bestanden:
**2.782 Flutter / 262 Python / 76 Backend**, 579 Dartdateien ohne Formatänderung,
Analyse sauber, Backend-Typecheck/Build und tatsächlicher lokaler Protokollsmoke.
Abschlussmarker `08:15 +2782: All tests passed!`; 72 neue Fälle und 159 gezielte
Regressionen sind darin keine zusätzliche globale SRD-Abnahme. Lokaler ARM64-
Debug-Build und **13 native JUnit-Tests** ohne Fehler, Error oder Skip bestanden.
Der frühzeitige Quellencheckpoint auf d5cf52f1 ist unabhängig geprüft: **1.369
Dateien**, CRC/Hashes/Größen/Modi, echte Patchanwendung auf Basis5a und isolierte
Git-Bundle-Wiederherstellung/fsck bestanden. Endcheckpoint und finale CI folgen.

**Koordination:** Vor PR erneut **27 fremde PRs** geprüft: ursprüngliche 23 Heads
unverändert, neue #469–#472 ohne Überschneidung der Fachdateien; deren CI lief beim
Audit noch. #468 teilt das Requirement-Register, bearbeitet andere IDs. Bei späterer
Konsolidierung die neue Version101 gegenüber100 und alle geprüften Belege erhalten.

**OFFEN:** aktuelle finale PR-CI, optimierte Alpha und reale Geräte-/TalkBack-/
Upgrade-/Produktivsignierungsabnahme. Allgemeiner initialer manueller Rettungswurf
bleibt das nächste gesonderte Paket; vorher frische PR-/Quellenprüfung. SQLite3/
JSON1 ohne Migration; beide Klassen-Requirements bleiben partial. Weitere Details
im Fachbericht `docs/parallel/CHAT_A_SAVING_THROW_CLASS_PREFLIGHT_20261102.md`.

**Historischer Frühcheckpoint vor der vollständigen lokalen Abnahme:**

## 02.11.2026 – Chat A: Klassenprüfung vor Rettungswurf-Wiederholungen, 0.8.51+101

**Vorläufiger Quellen-Checkpoint, keine vollständige Abnahme.** Basis-Main
`5a88834c98f5aca40395088c20c7e1dc5b587868`, Branch
`fix/chat-a/saving-throw-class-preflight-20261102`. Code-/Testcommit
`de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038` ist gesichert. Pull Request und finale CI
folgen nach den erforderlichen Prüfungen. Main bleibt
unverändert; Issue #425 und alte Branchmigration sind abgeschlossen.

**IMPLEMENTIERT:** Genau 51 zusätzliche Zeilen im bestehenden
`app/lib/domain/saving_throw_class_actions.dart`: bekannte SRD-Klassen und
kanonische Aliase, Gesamt-/eigene Klassenstufen, zulässiger Zweitklassensplit und
eindeutige Rettungswurfübungen vor Klassenbonus, Ressourcenverbrauch und neuem
W20 prüfen. Die lesende Verfügbarkeitsabfrage liefert für solche ungültigen
Profile `false`. Berechnungen, Ressourcenregeln und übriger vorhandener Code
bleiben unverändert. In der bestehenden Engine-Kette erzeugt ein abgewiesener
Textversuch absichtlich `rules.blocked` und eine Revision; Helden-/Ressourcenwerte
und RNG ändern sich nicht. Historische Profile werden beim Öffnen nicht repariert.

**GETESTET:** 62 neue Domain-, acht Engine-/SQLite- und zwei tatsächliche App-UI-
Tests bestanden, zusammen **72 neue Fälle**. **159 gezielte neue und bestehende
Regressionen** bestanden (157 Domain-/Flowfälle plus zwei UI-Fälle). Lokaler
ARM64-Debug-APK-Build bestanden. Positivfälle
für alle zwölf Klassen, gültige Aliase, tatsächliche Kämpfer-Klassenstufe,
Übung/Erschöpfung einmal sowie negative Klassen-/Stufen-/Übungsdaten. Speicherfälle
prüfen Ablehnung, einmalige Ressourcenbuchung, Replay, stale Zweitcontroller,
Neustart, Export/Import und späten SQLite-Rollback. Ein vorher legitimer W20 wird
bei spätem SQL-Fehler nicht als rückrollbar behauptet.

**NICHT ABGESCHLOSSEN / NICHT GETESTET:** Vollständiges `scripts/check.sh` und
native Android-Tests laufen zum Frühcheckpoint noch; kein Vollpass behauptet.
Optimierte Alpha und aktuelle GitHub-CI stehen aus. Geräte-/TalkBack-/Upgrade-
und produktive Signierungsabnahme fehlen. Kein Legacy-Profil-Korrektur-UI-Flow
wird behauptet.

**BLOCKIERT:** Kein bekannter fachlicher oder GitHub-Zugriffsblocker; reparierte
UI-Fixtures haben 2/2 bestanden, vollständige Abnahme läuft. Nur begrenzter
lokaler Speicherplatz: frühes Quellen-ZIP, Patch und Bundle außerhalb des
Projekts priorisieren. Keine Quellen, Spielstände, WIP oder alten Artefakte löschen.

**NOCH NICHT IMPLEMENTIERT:** Allgemeiner initialer manueller Rettungswurf ist
in diesem Paket unverändert. Weitere Rettungswurfquellen, situative Modifikatoren,
kompletter Charakterassistent und Gesamt-SRD bleiben offen. SQLite **3** / äußeres
JSON **1**, keine Migration. `CLASS-K-MPFER-9-BASE-INDOMITABLE-0` und
`CLASS-M-NCH-14-BASE-DISCIPLINED-SURVIVOR-0` nur **partial**; keine globale Abschlussquote.

Vor Beginn 23 offene PRs anhand ihrer Dateilisten geprüft. PR #468 bleibt getrennt
und auf seinem eigenen Head CI-grün; seine Konzentrationsdateien werden nicht
verändert. Andere Chat-A-/B-/C-/D-Pakete nicht erneut implementieren oder mergen.
Gemeinsame README-/Checkpoint-Zusätze konsolidiert Chat D später additiv.

**Genau nächstes unabhängiges Paket:** Allgemeinen initialen manuellen Rettungswurf vor automatisch abgeleiteten Klassenboni und W20 validieren; schreibfreie Charakterbogen-Vorschauen unverändert lassen. Zuerst frische Main-/PR-Dateilisten prüfen. Akzeptanz: unbekannte/inkonsistente Klassen vor Bonus/RNG ablehnen, gültige Aliase und Mehrklassen behalten dieselben Boni, Domain-, SQLite-/Retry- und tatsächliche UI-Regressionen bestehen.

Fachnachweis: `docs/parallel/CHAT_A_SAVING_THROW_CLASS_PREFLIGHT_20261102.md`.
Die darunter bewahrten Berichte gelten jeweils für ihren damaligen Stand.

---


---

# CHAT A · Status 2026-11-03 · PR #530

**Basis-main-SHA:** `7be2135f5046c4139a7340cc2bfa876a7d311c93`  
**Branch:** `fix/chat-a/concentration-damage-source-id-unicode-20261103`  
**Fach-/Testcommit:** `f9bdb9b687c2144bb45c3f8227900048fd2a0249`  
**PR:** https://github.com/ManuEtt/Dnd/pull/530 (Draft)

### IMPLEMENTIERT
- `app/lib/domain/srd_concentration_damage_rules.dart`: U+206A–U+206F und U+FFF9–U+FFFB als unsichtbare, irreführende Schadensquellen-ID-Zeichen abweisen; Vorprüfung aller Quellen vor irgendeiner Zustandsänderung erhalten.
- `app/test/srd_concentration_damage_rules_test.dart`: zwei Gruppen mit negativen Fällen für alle 9 Zeichen (allein, nach Wurffehlschlag, ohne Wurf bei 0 TP) und positiven internationalen Quellen mit zwei getrennten erfolgreichen Würfen.
- Additive Statusdokumentation in `README.md`, `docs/CODEX_CHECKPOINT.md` und dieser Chat-A-Datei.

### GETESTET
- Prüflogik und Codepfade über Quellcode-Review analysiert; GitHub-PR-Diff und CI gesondert kontrollieren.
- **Keine** lokal ausgeführten Dart-/Flutter-Tests. Es gibt keine behauptete grüne lokale Testausführung.

### NICHT GETESTET / BLOCKIERT
- Werkzeugcontainer enthält kein `flutter` oder `dart`; `flutter test test/srd_concentration_damage_rules_test.dart`, `flutter analyze`, APK-Build und volle Projektprüfungen dort nicht ausführbar.
- GitHub Actions auf dem finalen PR-HEAD separat nachweisen; laufende Workflows nicht als erfolgreich deklarieren.
- Reale Hardware, TalkBack, Upgrade und signierte APK nicht getestet.

### KOMPATIBILITÄT / MIGRATIONEN
- Keine Modelle, Controller, Speicherformate, API oder bestehenden Events geändert; SQLite/JSON unverändert; keine Migration.
- Kein direkter Commit auf `main`. PR #527 und seine Vorgänger nicht verändert; deren gemeinsame Dokuänderungen sind bei Integration durch CHAT D additiv zu konsolidieren.

### NÄCHSTER SCHRITT
- Nach CI/Integrationsabgleich einen unabhängigen, bislang unbelegten Quellen-ID-Validierungsfall im Regelbereich mit positiven und negativen Tests bearbeiten.

---
