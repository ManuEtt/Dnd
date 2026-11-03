## CHAT A · 03.11.2026 · Konzentrationsschadensquellen-IDs

- **PR:** [#530](https://github.com/ManuEtt/Dnd/pull/530) (Draft), **Branch:** `fix/chat-a/concentration-damage-source-id-unicode-20261103`, **Basis-main:** `7be2135f5046c4139a7340cc2bfa876a7d311c93`.
- **Fach-/Testcommit vor Dokumentation:** `f9bdb9b687c2144bb45c3f8227900048fd2a0249`.
- **Problem:** In `SrdConcentrationDamageRules.resolve` konnten U+206A–U+206F und U+FFF9–U+FFFB in auditierbaren Schadensquellen-IDs unbemerkt unterschiedliche Schlüssel für optisch gleiche Quellen bilden.
- **Umsetzung:** Neun weitere unsichtbare Legacy-Formatzeichen in der bestehenden Fail-Closed-Validierung gesperrt; zwei deterministische Testgruppen prüfen verworfene Einzelschlüssel, fingierte Zweitquelle nach gescheitertem Rettungswurf, die automatische Beendigung ohne Wurf sowie weiterhin zulässige internationale IDs. Keine Änderungen an Modellen, Spielständen oder Aktionsökonomie.
- **Tests:** `app/test/srd_concentration_damage_rules_test.dart` erweitert; Flutter/Dart nicht im ausführenden Container installiert, GitHub-Actions-Lauf auf finalem PR-HEAD gesondert prüfen. Keine lokale Testausführung oder grüne CI behauptet.
- **Quelle:** D&D SRD 5.2.1, Concentration / Taking Damage, CC BY 4.0: https://www.dndbeyond.com/srd.
- **Nächster unabhängiger Schritt:** Einen weiteren spezialisierten Quellen-/ID-Validator ausschließlich nach erneuter PR-Dateiprüfung auf bestätigte externe Dateneingaben testen.

## Chat D – UTF-8-Bytegrenze beim JSON-Import (02.11.2026)

- **Basis-main:** `84437e4e92d735e179bb2585427b46a10451951d`.
- **Branch:** `fix/chat-d/utf8-import-size-limit-20261102`.
- **Code-/Test-HEAD vor Dokumentation:** `f3359b826f65027979b6e9af09640ff304a1188f`.
- **Pull Request:** [#502](https://github.com/ManuEtt/Dnd/pull/502).
- **Problem:** Importgrenze von 10 MiB prüfte UTF-16-Codeeinheiten statt
  tatsächlicher UTF-8-Bytes; große Unicode-JSONs konnten durchrutschen.
- **Änderung:** Begrenzung auf maximal 10 MiB UTF-8 vor JSON-Parsing;
  schneller `String.length`-Vorfilter erhalten, identische Fehlermeldung.
- **Regressionen:** `app/test/storage_repository_test.dart` schützt
  oversized Unicode + erhaltene alte Kampagne/Revision sowie erlaubte
  Unicode-Importe einschließlich Emoji.
- **Betroffen:** `app/lib/data/sqlite_campaign_repository.dart`,
  `app/test/storage_repository_test.dart` und diese drei Dokumentationen.
- **GETESTET:** GitHub-Dateiupdates/PR-Erstellung bestätigt;
  keine lokale Flutter-Ausführung, keine CI für den finalen Stand behauptet.
- **NICHT GETESTET:** gezielte Flutter-SQLite-Tests, vollständige
  Flutter-/Backend-/Python-/Android-CI und Realgerät.
- **Kompatibilität:** SQLite 3, JSON 1, alte Spielstände, Exportformat und
  Versionsnummer unverändert; keine Migration.
- **Koordination:** weitere offene A/B/C/D-PRs ändern andere Fachdateien;
  README-/Checkpoint-Änderungen beim Merge additiv konsolidieren.
- **Nächster Schritt:** vollständige PR-CI auf finalem HEAD auswerten und
  ausschließlich nach erfolgreichem Lauf den Integrationsreview beginnen.

---

# Chat A – SRD Metamagie: versionierte Wahl und Ersatzregeln (02.11.2026)

**Basis-main:** `885580202caeafc9787538b6dc1c833b3190a529`.
**Branch:** `feat/chat-a/metamagic-choice-proof-20261102`.
**Offizielle Quelle:** SRD 5.2.1, Sorcerer /
Metamagic Options, CC BY 4.0.

**IMPLEMENTIERT:** standalone
`SrdMetamagicChoiceRecord` JSON1 mit
streng bestätigten Rohklassenetiketten,
eigenem Sorcererklassenlevel, amtlicher
Optionsliste und exakter SRD-Anzahl
2/4/6 bei 2/10/17. Klassenlevelaufstieg
erlaubt genau zwei neue Optionen an
10/17 sowie optional höchstens eine
Ersetzung. Andere Klassenaufstiege
grantieren keine neue Metamagieoption.
Falsche Klassen-/Level-, Options- und
Schema-Behauptungen werden abgewiesen.

**TESTS:** zwölf neue deterministische
Domain-/JSON-/SQLite-/Revisionsgruppen
in `app/test/srd_metamagic_choice_record_test.dart`,
inclusive Alt-JSON, Level-Boundaries,
duplizierte/fingierte Namen, Multiclass,
stale Identität, Restart, Retry, Konflikt.
CI- und Android-Ergebnis nur mit finalem
Workflowbeleg ausweisen.

**GRENZEN:** Keine Kopplung an das
bestehende `HeroCharacter`-Modell,
kein automatisch persistierter
Metamagiebeleg, kein bestätigtes
Ereignis und keine echte Casting-
oder Sorcery-Point-Buchung.
Das eigenständige JSON ist kein
manipulationssicherer Besitzbeleg.
PR #463 und #478 bleiben unberührt;
Schema SQLite3/JSON1 unverändert.
Gemeinsame Checkpoints und README
bei Integration durch Chat D additiv
zusammenführen.
[SRD-Fachbeleg](SRD_METAMAGIC_CHOICE_RECORD_20261102.md).

**NÄCHSTER SCHRITT:** bestätigte
Metamagiewahl nach koordiniertem
Merge in das persistente Heldenmodell
integrieren und mit Distant Spell
nur im revisionsgeschützten gemeinsamen
Casting-Commit verwenden.

---

# Codex-Checkpoint – Gesamtintegration zu Issue #425

## Chat C – 02.11.2026: Mehrgegner-Initiative mit großer Schrift und IME

- **Ausgangs-main:** `885580202caeafc9787538b6dc1c833b3190a529`.
- **Branch:** `feat/chat-c/tracked-initiative-ime-20261102`.
- **Pull Request:** [#488](https://github.com/ManuEtt/Dnd/pull/488) (Draft).
- **Code-/Testcommit:** `4fc35cbb35f43142b98e700e52656b22f40fcd0c`.
- **Implementiert:** `TrackedCreatureInitiativeDialog` mit einem
  AlertDialog-Scrollbereich, kompakten Insets, größeren Dropdowns,
  visuellen Kurztexten bei 200 % ohne Verlust der TalkBack-Langtexte
  und zugänglicher Validierungsfehlermeldung.
- **Tests hinzugefügt:** fünf Widgetfälle in
  `app/test/tracked_creature_initiative_ime_test.dart`
  (320/360 dp, 200 %, 220 dp IME; Abbruch, Erfolg, Fehler und
  unveränderte Kampagnen-JSON-Snapshots).
- **Teststand:** Flutter/Dart lokal nicht installiert; CI am finalen
  Commit zum Zeitpunkt der Eintragung noch nicht belegt. Echte
  Android-/TalkBack-/IME-/Upgrade-Tests sind noch offen.
- **Kompatibilität:** Keine Änderungen an Regeln, GameController,
  Kampfzustand, SQLite, JSON, Version oder gespeicherten Spielständen.
- **Parallelität:** PR-Pfadüberschneidungen ausgeschlossen, gemeinsame
  README-/Checkpoint-Ergänzungen durch Chat D beim Merge konsolidieren.
- **Nächster Schritt:** Echten Touch-/TalkBack-Test der
  Mehrgegner-Initiative auf einem schmalen Android-Gerät mit Tastatur
  und 200 % Schrift durchführen.

---

Stand: 31.10.2026, UTC. Produkt **Würfelraunen – Der lebendige Spielleiter**,
Alpha **0.8.49+99**. Dieser neue Live-Status ersetzt widersprüchliche historische
Momentaufnahmen; die vollständige additive Vereinigung ist bytegenau unter
`docs/history/migration_20261030/` archiviert, samt Manifest.

- **Auftrag:** alle vorhandenen Entwicklungsbranches fachlich geprüft migrieren,
  Integrationsfehler beheben, anschließend gesichert bereinigen und #425 lösen.
  Die ausdrückliche Nutzerweisung erweitert den bisherigen Chat-A-Bereich.
- **Basis-main:** `6465a4b2fc8d42ae7aab596ac26e85d61d2b8f49`.
- **Abschlussbranch:** `docs/migration-issue425-acceptance-20261031`.
- **Produkt-Main:** `47ab002872b7d46daeae03bb558258cf2ea73e4a`,
  regulärer Historiennachtrag #444 nach Gesamtmerge #440 (`72ba9d2e`).
  Alle offenen Ursprungs-PRs dadurch automatisch als übernommen geschlossen.
- **Kombinierter Fachstand:** `b0a4211c` (vollständig über Git auflösen).
  Gesamt-PR #440 ist mit finalem HEAD `ea4561f4` regulär integriert;
  beide vollständigen Main-CIs auf `72ba9d2e` und `47ab0028` sind erfolgreich.
- **Inventar:** anfangs 46 Remote-Referenzen mit Main / 41 offene PRs; zusätzlich
  während der Prüfung #437 mit eigener gesicherter Referenz aufgenommen.
  Alle 47 dokumentierten Heads sind Vorfahren des kombinierten Fachstands.
  Quelle: `docs/parallel/MIGRATION_BRANCHES_20261030.json`.

## IMPLEMENTIERT

Alle Regel-, Story-, UI- und Infrastrukturpakete regulär mit Historie vereinigt.
Nur Dokumentationskonflikte, plus ein reiner Kommentarunterschied der beiden
Casting-Time-Versionen. Technische Quellen erhalten; zwei zusätzliche geprüfte
Konzentrationskorrekturen und ein NPC-Identitätsfix mit roten Gegenproben ergänzt.
Details und ursprüngliche PR-Zuordnung: `docs/parallel/ALL_BRANCHES_MIGRATION_20261030.md`
und die vier Fachberichte `CHAT_{A,B,C,D}_*MIGRATION*20261030.md`.

Shared-Modelle und JSON-/SQLite-Schemas bleiben kompatibel: SQLite **3**, äußeres
JSON **1**. Keine Migration und keine stille Neuberechnung älterer Charaktere.
Story-/KI-Ausgaben dürfen weiterhin keine bestätigten Regelzustände verändern.
SRD-Lizenzhinweise bleiben erhalten, keine externen KI-Kosten ausgelöst.

## GETESTET

Vier getrennte Gruppen: 171 neue/angepasste Regeltests plus 125 bestehende
Regelregressionen; 89 Story-/Persistenztests, 55 UI-Tests, 11 Outbox-/SQLite-Tests;
258 Pythonfälle und je nach Teilgruppe 73/75 Backendfälle. Analyse/Format und
Modulgrenzen bestanden. Dies sind Teilpaketnachweise, keine Gesamtabnahme.

**Vollständige Main-CI [41180122526](https://github.com/ManuEtt/Dnd/actions/runs/41180122526)**
auf `72ba9d2e06e7121f955832b4ad22223f64f7c343`: **completed/success**.
Tatsächliche Logs: **2.710 Flutter / 258 Python / 76 Backend**, 20 zusätzliche
gezielte UI-Fälle, Format 576 Dateien ohne Änderungen, Analyse ohne Befund,
Backend-Typecheck/Build und lokaler Protokollsmoke, Debug-APK, native Gradle-Tests,
drei optimierte ABI-APKs sowie Source-/Alpha-Pakete bestanden.
Der lokale vollständige Flutter-Lauf endete durch Sitzungsunterbrechung bei
1.154 erfolgreichen Fällen; kein Vollpass und keine Hintergrundfortsetzung.
**Vollständige Main-CI [41183481979](https://github.com/ManuEtt/Dnd/actions/runs/41183481979)**
auf `47ab002872b7d46daeae03bb558258cf2ea73e4a`: **completed/success**.
Tatsächliche Logs: **2.710 Flutter / 262 Python / 76 Backend**, 20 zusätzliche
UI-Fälle, Format 576 unverändert, Analyse/Backend-Build/Protokollsmoke sowie
Debug-/native-/drei ABI-/Source-/Alpha-Schritte erfolgreich.
Auch lokal 262 Pythonfälle mit vollständiger Git-Ancestry, Projekt-/Importgrenzen-
und SRD-Prüfer bestanden. Kein Test deaktiviert.

[Cleanup 41184619156](https://github.com/ManuEtt/Dnd/actions/runs/41184619156):
**completed/success**. Frischer unabhängiger Check vom 31.10.2026, 08:27 UTC:
**53/53 Altbranch-Heads sind Main-Vorfahren, remote abwesend und exakt archiviert**.
Maschinenlesbarer Nachweis: `docs/parallel/MIGRATION_ACCEPTANCE_20261031.json`.
53 = 46 erfasste Entwicklungsheads einschließlich #437, Gesamtbranch #440 und
sechs später angelegte Integrationsbranches einschließlich #444.
PRs #446–#448 wurden erst anschließend als neue Arbeit begonnen und bleiben
aktiv geschützt. Keine globale Behauptung, dass nur Main oder keine PRs existieren.

## NICHT GETESTET

Reales Android-Gerät, TalkBack, tatsächliches Altversionsupgrade, produktive
Release-Signierung und echter externer KI-/Sprachbetrieb. Eine gebaute APK
ersetzt diese Abnahmen nicht.

## BLOCKIERT

Die fachliche Migration und Bereinigung aller 53 erfassten Altbranches ist
abgenommen. Kein Code-/SDK-/GitHub-Zugriffsblocker; kein Android-Testgerät.
Abschluss-PR #445 enthält ausschließlich dokumentierte Endergebnisse und den
Branch-/Archivnachweis. Seine statischen Prüfungen und reine Baumgleichheit
von `app/`, `backend/`, `scripts/` und `.github/` gegenüber Produkt-Main `47ab0028`
sind gesondert zu prüfen. Eigene Abschlussbranch erst nach erfolgreicher
Abnahme und unverändertem Head archivieren/löschen; Issue #425 anschließend
mit den tatsächlichen Belegen schließen. Neue aktive PRs #446–#448 schützen.

## NOCH NICHT IMPLEMENTIERT

Sechs neue SRD-APIs sind weiterhin Standalone-Domänenbausteine ohne komplette
UI-/Controller-/Persistenzanbindung: Mehrziel-Geschoss, TP-Vorschau,
Zauber-Aktionsökonomie, Materialwerte und zwei Konzentrationshelfer.
Vollständiger Charakterassistent und vollständiges SRD-Regelwerk bleiben offen.
1.419 Prüfaufträge und neun Inventurlücken erlauben keine globale Abschlussquote.

## Sicherung und Wiederaufnahme

Ausgangs-Main-ZIP und Bundle sämtlicher ursprünglichen Remote-Heads liegen unter
`/workspace/artifacts/migration-issue425-20261030/ausgang/`. Jede während der
Bestandsaufnahme erfasste Spitze ist remote über
`archive/pre-migration-20261030/<Branch>-<SHA12>` erhalten. Endartefakte und
Öffentliche geprüfte Produktartefakte aus Main-CI `41183481979`:
[Source-ZIP/Patch/Manifest/History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/41183481979/artifacts/13036032830) und
[ARM64-Alpha/Quellen](https://github.com/ManuEtt/Dnd/actions/runs/41183481979/artifacts/13036442277).
CI-Patchbasis: `72ba9d2e06e7121f955832b4ad22223f64f7c343`. Bereits integriertes
Main nicht erneut patchen. Der folgende Dokumentationsabschluss ist kein
neuer fachlicher Appstand; finale Artefakte über den jeweiligen echten CI-Lauf prüfen.

1. Main, alle offenen PRs, Branches und jüngste CI erneut live prüfen.
2. Gesamtintegrations-PR und Report lesen; bereits übernommene Features nicht
   neu entwickeln oder alte Patches erneut auf Main anwenden.
3. Prüfungen: `bash scripts/check.sh`, Debug-Build, native Gradle-Tests und finale
   PR-/Main-CI; aktuelle Fehler zuerst beheben.
4. Die 53 alten Branches sind bereits nachgewiesen bereinigt. Keine entfernten
   Entwicklungsbranches als neue Arbeit rekonstruieren; aktive neue PRs gesondert prüfen.
5. Keine Hintergrundausführung oder automatische Wiederaufnahme behaupten.

**Genau ein nächstes Entwicklungspaket nach Integrationsabschluss:** normale
Mehrklassen-Zauberplätze für bestätigte SRD-Klassenaliasnamen kanonisieren.
Akzeptanz: `Wizard`/`Magier` und andere erlaubte Caster-Aliase ergeben identische
Slots; Pact Magic bleibt separat; unbekannte Namen werden nicht geraten;
Domain-/Speicher-/Retry-Regression und finale CI. Zuvor neue Parallel-PRs abgleichen.

## Chat B – verzögerte KI-Antwort nach SQLite-Neustart (31.10.2026)

Ein neuer Flutter-Regressionstest schützt vor einer Story-Provider-Antwort, die erst nach einer parallelen, bereits bestätigten SQLite-Änderung ankommt. Der positive Gegenfall bestätigt genau einen narrativen Spielzug; der Konfliktfall bewahrt Journal, NPC-Notizen, Story-Fäden, Heldenzustand und rekonstruierte Kampagne. Branch `feat/chat-b/delayed-story-response-restart-20261031` von `47ab002872b7`; CI-Ausführung dieses Pakets steht bei Erstellung noch aus. Kein Schemawechsel, keine neuen API-Kosten.

> **Paralleler CHAT-C-Entwicklungsbranch (31.10.2026):**
> [Draft-PR #447](https://github.com/ManuEtt/Dnd/pull/447) schützt die
> Flutter-Kampfchronik vor der Anzeige unbestätigter Treffer-/Schadensdetails
> bei einer offenen Schildreaktion. Neue Widgettests für 320/360 dp,
> 200 % und Semantics hinzugefügt, aber bis zur erfolgreichen GitHub-CI nicht
> als bestanden melden. Code-HEAD `5f951e9b06b08956e9d86fa084b53699964f06c7`;
> eigenes Detailprotokoll in `docs/parallel/CHAT_C_CHECKPOINT.md`.
> PR #445 bearbeitet ebenfalls zentrale Dokumentation: vor Merge
> konfliktfrei konsolidieren, bestehende Integrationseinträge erhalten.

## 31.10.2026 – Chat A: Zauber-Preflight + Kampfaktion kombiniert (Staging)

- **Aktueller Ausgangs-main:** `47ab002872b7d46daeae03bb558258cf2ea73e4a`; **eigener Branch:** `feat/chat-a/spell-turn-atomic-staging-20261031`.
- **Vorheriger beobachteter Zustand:** PR #432 war nach vollständiger GitHub-CI #41123342877 erfolgreich integriert; vor Arbeitsbeginn keine offenen Pull Requests. GitHub-`main`-CI für #425 auf `47ab0028` war bei letzter Sichtung noch `in_progress`; Issue #425 blieb offen. Unbestätigte Abschlussangaben nicht aus diesem Checkpoint ableiten.
- **IMPLEMENTIERT:** `app/lib/domain/srd_spell_turn_transaction_rules.dart`, ausschließlich explizite `prepare`/`stageConfirmed`-Schnittstelle. Kombiniert die vorhandenen, zuvor unabhängigen Zauber- und Action/Bonus-Action-Nachweise. Nach der erneuten Snapshotvalidierung entsteht ein gemeinsamer **nicht persistierter** Held-/Encounter-Vorschlag mit genau einem verbrauchten Slot und dem zutreffenden Aktionsflag, unveränderte Ursprungsobjekte. Keine Story-/KI-Vertrauensannahmen.
- **TESTS ERSTELLT:** `app/test/srd_spell_turn_transaction_rules_test.dart`, neun deterministische Gruppen: Magic/Bonus, Turn-Slot-Limit, Cantrip, Action Surge, Ablehnung ohne bestätigte Wirkung, stale Hero-/Encounter/JSON/Retry, unbekannter oder geänderter Nicht-Kampfstatus, keine Trigger-/Langzeitzauber, unveränderte Ausgangskonzentration.
- **GETESTET:** Aktuellen Repository-/PR-/Issue-/CI-Zustand und relevante Regelmodule geprüft. **NICHT GETESTET:** Dartformat, Flutteranalyse, gesamte Testsuite, Android-APK und Realgerät des neuen finalen Commits bei Erstellung; CI folgt im eigenen Draft-PR.
- **KEINE MIGRATION:** `models.dart`, `game_engine.dart`, Controller, SQLite/JSON/Events, Backend, UI/Story und Version unverändert. Quelle: SRD 5.2.1, Playing the Game und Spells / Casting Time, CC BY 4.0, Status `partial`. Details: `docs/SRD_SPELL_TURN_TRANSACTION_STAGING.md`.
- **NICHT IMPLEMENTIERT:** Persistenter atomarer Commit unter gesperrter Kampagnenrevision und integrierter Legacy-/Controller-Aufruf. Dies muss mit Chat D und positiven/negativen SQLite-/Neustarttests erfolgen.
- **NÄCHSTER SCHRITT:** Nach erfolgreicher GitHub-CI und Review das gestagte Ergebnis in die bestehende Event-/SQLite-Transaktion überführen; Issue #425 separat durch den Integrationsverantwortlichen abschließen.

## 31.10.2026 – CHAT D: native Unicode-Zeilentrenner für Backup-Dateinamen sperren

- **Basis-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`; **Branch:** `fix/chat-d/backup-unicode-separators-20261031`; **PR:** [#449](https://github.com/ManuEtt/Dnd/pull/449) (Draft).
- **Implementierungs-Commits:** `147b86ad80ed32b1bdcddd940dbc492312db7909`, `3a32be9c74d79a141602f4461db4714d38902a0c`.
- **IMPLEMENTIERT:** Der native `JsonBackupIo.isSafeName`-Code erkennt Unicode-Zeilentrenner/Absatztrenner (Zl/Zp) zusätzlich zu vorherigen ISO-/FORMAT-/Surrogat-Sperren. Regressionen testen U+2028, U+2029, U+0085 und sichtbare, weiterhin gültige Unicode-Dateinamen.
- **GETESTET:** Implementierungs-/Testdateien auf Branch gesichert. Noch keine erfolgreich abgeschlossene CI auf dem finalen Dokumentations-Commit bestätigt.
- **NICHT GETESTET:** finale Python-, Backend-, Flutter-, native Gradle-/JUnit-, APK-Gesamtsuite sowie realer Android-SAF-Dateidialog.
- **BLOCKIERT:** kein lokaler GitHub-Checkout über DNS und kein lokales Flutter-SDK. Remote-CI ist der Abnahmeweg.
- **Migrationen:** keine Änderungen an Datenbank, JSON, Spielständen, Import-/Export-Schema, Version, Berechtigungen oder Rule-/Story-Grenzen.
- **Nächster Schritt:** endgültigen Actions-Lauf auf PR #449 prüfen, bei Erfolg nach konfliktfreiem main-Abgleich Review; ohne final-grüne CI keine Integration.

---

## 31.10.2026 – Chat D: ZIP-Pfadschutz, PR #451

- Ausgangs-main: `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- Branch: `fix/chat-d/archive-unicode-controls-20261031`; technischer Commit:
  `59757423be3bbd47be9a39a1a187a1cb3baee71e`.
- PR: https://github.com/ManuEtt/Dnd/pull/451 (Draft, noch kein Merge).
- IMPLEMENTIERT: Windows-portable Source-ZIP-Komponenten verweigern neben den
  bisherigen ungültigen Zeichen nun Unicode-Kategorien Cc/Cf/Cs/Zl/Zp.
  Vier neue Python-Testmethoden prüfen Negativ-/Positivfälle sowie
  unveränderte Prüfsummen/ZIPs bei abgelehnter Veröffentlichung.
- GETESTET: noch kein vollständiger Projekt- oder CI-Lauf auf finalem PR-HEAD
  belegt; Testcode ist nicht gleich bestandenem Test.
- NICHT GETESTET: Python-Gesamtsuite, Flutter/Android, Backend, APK, reales Gerät
  (vorliegende CI-Läufe anderer Commits sind kein Freigabenachweis).
- BLOCKIERT: lokale GitHub-Klonung durch DNS nicht möglich; Flutter/Dart fehlen.
  Andere A/B/C/D-PRs #446–#449 bleiben unverändert. Gemeinsame Dokumentation
  bei Integration verlustfrei zusammenführen.
- Keine Spielstand-, Datenbankschema-, JSON-, Regel- oder UI-Migration.
- Nächster Schritt: PR #451 auf finalem HEAD vollständig in GitHub Actions
  prüfen und gegen die anderen offenen PRs auf Dateikonflikte nachkontrollieren.


---

## 01.11.2026 – Chat D: sichere APK-ZIP-Mitgliedsnamen (PR #460)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Branch:** `fix/chat-d/apk-unicode-entry-names-20261101`.
- **Technische Commits:** `1b5928ded1bd14fbe204b0bd82b725dc40b08a93`,
  `14431b670ae4a6cd0c8b87d6d98d2d6be7d8ce88`.
- **Implementiert:** `scripts/prepare_alpha_release.py` verwirft Unicode-
  Steuer-, Format-, Surrogat- und Unicode-Zeilen-/Absatztrennzeichen in
  APK-ZIP-Einträgen vor CRC-Validierung und Release-Publikation.
- **Regressionstests geschrieben:** fünf positive/negative Methoden in
  `scripts/tests/test_prepare_alpha_release.py`, einschließlich unversehrter
  vorheriger Releases und sichtbarer Unicode-Dateinamen.
- **GETESTET:** CI auf finalem PR-HEAD zum Zeitpunkt der Dokumentation
  noch nicht bestätigt. In dieser Sitzung lokaler GitHub-Checkout wegen
  DNS-Fehler nicht möglich; Flutter/Dart nicht vorhanden.
- **NICHT GETESTET:** Python-Gesamtsuite, Backend/Flutter, native Android-
  Prüfungen, APK-Erstellung und Realgerät auf **diesem** Commit.
- **BLOCKIERT:** definitive GitHub-Actions-Abnahme und spätere additive
  Dokumentationsintegration mit aktiven A/B/C/D-PRs.
- **Migration:** keine. SQLite-/Spielstand-/Exportformate, SRD-Regeln,
  Backend und Android-Berechtigungen bleiben unverändert.
- **Nächster konkreter Schritt:** finale CI für PR #460 verifizieren,
  bei Defekt im selben Branch korrigieren; kein ungeprüfter Merge.


---

## 01.11.2026 – Chat D: Unicode-sichere Gradle-Wrapper-JAR (PR #462)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Arbeitsbranch:** `fix/chat-d/gradle-wrapper-unicode-entries-20261101`.
- **Code-Commit:** `2616c50fff45e64f9d577b3d3bf93d0dab5ad9ca`.
- **Test-Commit:** `5188d18ec791803ff79b21e91c00da230c344cc6`.
- **PR:** https://github.com/ManuEtt/Dnd/pull/462 (Draft).
- **IMPLEMENTIERT:** `scripts/verify_project.py` validiert zusätzliche Unicode-
  Kategorien `Cc/Cf/Cs/Zl/Zp` in JAR-ZIP-Mitgliedsnamen vor CRC und
  Gradle-Startklassenprüfung. Keine bestehende Schutzprüfung entfernt.
- **REGRESSIONEN:** Vier Python-Testmethoden in
  `scripts/tests/test_verify_project.py` einschließlich negativer
  Metadatenfälle und gültiger internationaler Ressourcennamen.
- **GETESTET:** PR-CI auf endgültigem Dokumentationscommit noch ausstehend.
  Geschriebene Tests sind kein Beleg für ausgeführte Tests.
- **NICHT GETESTET:** endgültige Python-/Backend-/Flutter-/Android-CI,
  APK-Build und echtes Android-Gerät auf diesem HEAD.
- **BLOCKIERT:** CI-Nachweis und koordinierte spätere Integration;
  in dieser Laufzeit kein lokal nutzbarer GitHub-DNS-Zugriff, kein Flutter/Dart.
- **Keine Migration:** unveränderte SQLite-/JSON-/Spielstand- und
  Gradle-Buildversion; kein geändertes Android-Berechtigungsmodell.
- **Parallelität:** Alle zum Branchstart offenen PRs #446–#461
  fachdateibezogen abgeglichen, keine Überschneidung mit diesen beiden
  Python-Dateien. README-/Checkpoint-Inhalte vor Merge additiv konsolidieren.
- **Genau nächster Schritt:** CI auf finalem PR #462 überprüfen,
  bei Defekt im eigenen Branch korrigieren und nicht ungeprüft mergen.

---

## 01.11.2026 – Chat D: koordinierte Integration der Unicode-ZIP-Schutzpakete

- **Basis-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Branch:** `chore/chat-d/integrate-unicode-zip-guards-20261101`.
- **Quell-PRs/Final-HEADs:**
  - #451 Source-ZIP `33463cc1c8719bbfb5aa0139497ca3a0a45c1cd0`;
    GitHub Actions #41244456398 `completed/success`.
  - #460 Alpha-APK `d9fe14ac21d6f1ad2944ab77c7b35a8ec2d0bfeb`;
    GitHub Actions #41282041207 `completed/success`.
  - #462 Gradle-Wrapper-JAR `afe9853e14eb49b7e997a2c6400608361f99c210`;
    GitHub Actions #41312267140 `completed/success`.
- **IMPLEMENTIERT:** Alle sechs Python-Code-/Test-Blobs aus den
  Quellen unverändert in einem Git-Tree zusammengeführt. Die drei
  Quell-README-, zentralen und Chat-D-Checkpoint-Anhänge vollständig
  additiv an aktuellen Main-Inhalt angefügt; historische Statusmeldungen
  unter ihren ursprünglichen Abschnittsüberschriften belassen.
- **GETESTET:** Alle drei Einzelpakete auf jeweiligen finalen HEADs
  vollständig mit Python, Backend, Flutter, nativen Android-Tests und
  Alpha-Build geprüft.
- **NICHT GETESTET:** die kombinierte Integration auf dem finalen
  Integrations-HEAD; CI muss neu durchlaufen. Echte Geräte-/SAF-Abnahme
  ebenfalls nicht durchgeführt.
- **BLOCKIERT:** definitive CI-Freigabe der Kombination und Koordination
  mit #454 (andere disjunkte Fachdateien, identische README/Checkpoints).
- **Migration:** keine. Keine Änderung an SQLite-Schema, Save-/JSON-Format,
  Android-Berechtigungen oder Versionsnummer.
- **Nächster Schritt:** Kombinations-CI prüfen und vor jedem Merge
  Main, offene PRs und verlustfreie Dokumentationsintegration neu prüfen.
  Nicht ungeprüft mergen oder fremde Branches löschen.

---

## 02.11.2026 – Chat D: geprüfte A–D- und ZIP-Integrationen zusammenführen

- **Main-Basis:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Arbeitsbranch:** `chore/chat-d/integrate-verified-ad-and-zip-guards-20261102`.
- **Quellen:** PR #454 mit vier fachlichen Quellpaketen
  #446/#447/#448/#449, finaler Head
  `6e55749aebdc5dbf8324ef6865d07973f5d5d52e` und CI
  https://github.com/ManuEtt/Dnd/actions/runs/41244568578
  `completed/success`; PR #466 mit #451/#460/#462, finaler Head
  `1698fb37fac0696a5bde572959dd6f7ff3c3dd14` und CI
  https://github.com/ManuEtt/Dnd/actions/runs/41323233143
  `completed/success`.
- **IMPLEMENTIERT:** Alle aus beiden Integrationen übernommenen 18
  nicht gemeinsamen Fach-, Test- und eigenen Checkpoint-Dateien behalten
  die Quell-Blob-SHAs. Die drei gemeinsamen Dokumentationen README,
  CODEX_CHECKPOINT und CHAT_D_CHECKPOINT enthalten alle vollständigen
  additiven Originaländerungen beider Quellen.
- **GETESTET:** beide selbstständigen Integrationspakete am exakten
  finalen Head mit vollständiger GitHub-CI erfolgreich.
- **NICHT GETESTET:** übergreifende Kombination auf endgültigem
  neuen Head, reales Android-/SAF-/TalkBack-Gerät.
- **BLOCKIERT:** Neu durchlaufende gemeinsame CI und abschließende
  Konkurrenz-/Main-/Dokumentationsprüfung vor einem späteren Merge.
- **Migrationen:** Keine neuen SQLite-/JSON-/Saveformat- oder
  App-Version-/Berechtigungsänderungen.
- **Koordination:** Alle aktuell offenen PRs, einschließlich
  A #467/#468, B #464, C #465, auf Pfade geprüft: keine fachliche
  Überschneidung; README und zentraler Checkpoint bleiben aktive
  Dokumentations-Hotspots. Frühere historische Teststatus bleiben
  erhalten, aktueller Nachweis steht in diesem Abschnitt.
- **Nächster konkreter Schritt:** vollständige GitHub-CI des neuen
  Integrations-HEAD abschließen, Konflikte nochmals prüfen; kein
  ungeprüfter Merge und keine ungeprüfte Altbranch-Bereinigung.

---

## 02.11.2026 – Chat D: Unix-ZIP-Dateitypen im Gradle-Wrapper-JAR

- **Ausgangs-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`.
- **Branch:** `fix/chat-d/wrapper-jar-member-types-20261102`.
- **Code-Commit:** `778873d148e5170482b721a3f93b11ce93bcb41c`.
- **Test-Commit:** `b150cbb701912a616c3db497c128981768dd5e51`.
- **IMPLEMENTIERT:** `scripts/verify_project.py` prüft für Unix-ZIP-
  Mitglieder `S_IFMT` vor Dekomprimierung. Nur nicht spezifizierte
  Typen, reguläre Dateien und Verzeichnisse sind zulässig; Typ und
  abschließendes `/` müssen zueinander passen. Bestehender
  Symlink-/Unicode-/Pfad-/CRC-/Größenschutz unverändert.
- **REGRESSIONEN:** Vier Tests in
  `scripts/tests/test_verify_project.py`, davon drei negative
  Metadatenfälle mit explizitem Verbot einer vorzeitigen CRC-
  Dekomprimierung und ein positiver Unix-Datei-/Verzeichnisfall.
- **GETESTET:** Die zuvor integrierte main-CI
  https://github.com/ManuEtt/Dnd/actions/runs/41395163971
  war auf dem Ausgangs-main vollständig erfolgreich.
- **NICHT GETESTET:** neuer Branch/PR auf finalem HEAD bis zur
  neuen GitHub-CI, reales Android-/SAF-/TalkBack-Gerät.
- **BLOCKIERT:** volle PR-CI und finale Prüfung neuer PRs
  auf Dateikonflikte; kein ungeprüfter Merge.
- **Parallele Arbeit:** Alle 19 zum Paketbeginn offenen PRs
  geprüft; keiner ändert die beiden Python-Zieldateien.
  README/zentralen Checkpoint beim späteren Merge mit A/B/C
  verlustfrei konsolidieren.
- **Migrationen:** Keine, unveränderte Gradle-JAR-Binärdatei,
  unveränderte SQLite-/JSON-/Saveformate, Android-Berechtigungen,
  App-Version und regeltechnische Module.
- **Nächster konkreter Schritt:** Vollständige PR-CI auf
  finalem HEAD prüfen, dann konfliktfrei Review freigeben.


---

## 02.11.2026 – Chat D: APK-ZIP-Pfadkollisionen vermeiden

- **Ausgangs-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`.
- **Bestätigte Main-CI:** #41395163971 und #41396647217,
  beide `completed/success` auf obigem SHA.
- **Branch:** `fix/chat-d/apk-unicode-path-collisions-20261102`.
- **PR:** https://github.com/ManuEtt/Dnd/pull/476 (Draft bis vollständiger CI).
- **Code-Commit:** `dc2055bfb4cad572b822672dd4f6dadd6bc3b3b3`.
- **Test-Commit:** `9de29379de5114cf6c1519e41123d60001853ab8`.
- **IMPLEMENTIERT:** APK-ZIP-Metadaten verweigern
  kollidierende Pfade bei Casefold und kanonischer NFC-Unicode-Normalisierung
  einschließlich indirekt betroffener Unterverzeichnisse,
  vor CRC/Entpacken und Release-Veröffentlichung.
- **Tests:** fünf neue Python-Regressionen für Casefold/NFC/
  Verzeichniskollisionen, zulässige internationale Namen und
  Bestandsschutz vorheriger Release-Artefakte.
- **GETESTET:** erfolgreiche Baseline-Main-CI auf Ausgangs-Commit.
  Neue PR-Python-/Flutter-/Android-Gesamt-CI noch offen.
- **NICHT GETESTET:** finale CI auf diesem Branch sowie reale Android-Geräteabnahme.
- **Parallelität:** alle bei Arbeitsbeginn 19 offenen PRs auf die
  beiden Python-Zieldateien geprüft; keine technische Überschneidung.
  README und CODEX_CHECKPOINT bleiben gemeinsame Dokumentations-Hotspots.
- **Migration:** keine (SQLite, JSON, Save-Schema, Version,
  Berechtigungen, Story- oder Regelwerk unverändert).
- **BLOCKIERT:** Abschluss der CI auf finalem Branch-HEAD.
- **Nächster Schritt:** eigenen vollständigen GitHub-Actions-Lauf
  abnehmen; bei Fehlern den eigenen PR korrigieren und ohne
  erfolgreiche Gesamtabnahme nicht mergen.

---

## 02.11.2026 – Chat D: gemeinsame APK-/Gradle-JAR-Archivprüfung

- **Basis-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`;
  Main-CI #41395163971 und #41396647217 erfolgreich.
- **Neuer Integrationsbranch:** `chore/chat-d/integrate-apk-wrapper-guards-20261102`.
- **Quell-PR #475:** `3c8bc937358c4a95e4fd75094c0e038b5638c379`;
  `scripts/verify_project.py`, `scripts/tests/test_verify_project.py`
  schützen den Gradle-Wrapper vor inkonsistenten Unix-ZIP-Dateitypen.
- **Quell-PR #476:** `cf12727bcaf493f5fb03775b67dbd423bd56618c`;
  `scripts/prepare_alpha_release.py`,
  `scripts/tests/test_prepare_alpha_release.py` schützen APKs vor
  Unicode-NFC-/Casefold-Pfadpräfixkollisionen.
- **IMPLEMENTIERT:** Die vier technischen Dateien werden mit
  unveränderten Quell-Blob-SHAs übernommen. README, zentraler und
  Chat-D-Checkpoint erhalten **beide vollständigen Anhänge**.
- **GETESTET:** beide Quell-PRs haben bereits die Python-Paket-/
  Strukturtests, Backend-Tests, Flutter-Analyse und gezielte Dialogtests
  in GitHub Actions bestanden.
- **NICHT GETESTET:** vollständige Einzel-CI der beiden finalen Heads
  und neue kombinierte GitHub-CI auf finalem Integrations-HEAD;
  reale Android-/SAF-/TalkBack-Geräteabnahme.
- **BLOCKIERT:** erfolgreiche Einzel- und kombinierte Gesamttests,
  dann erneute Main-/PR-Konfliktkontrolle vor jedem Merge.
- **Parallelität:** Fachdateien aus #475 und #476 sind disjunkt;
  andere offene PRs arbeiten an anderen Fachmodulen. README/CODEX
  müssen bei späteren Integrationen weiterer Chats erhalten bleiben.
- **Migration:** keine neuen SQLite-/JSON-/Spielstand- oder
  Android-App-Versions-/Berechtigungsänderungen.
- **Nächster Schritt:** Final-HEAD-CI auf beiden Quell-PRs und der
  Integration kontrollieren, bei Fehlern gesondert korrigieren.
  Keine automatische Main-Integration und kein Branchlöschen.

---

## 02.11.2026 – Chat A: ungültige Bewegung bei 0 TP blockieren (PR #487)

- **Ausgangs-main:** `885580202caeafc9787538b6dc1c833b3190a529`; **Branch:** `fix/chat-a/zero-hp-prone-movement-20261102`; **PR:** https://github.com/ManuEtt/Dnd/pull/487.
- **Problem:** Der historisch nicht immer gespeicherte Zustand `bewusstlos` konnte dazu führen, dass Helden mit 0 TP dennoch aufstehen oder kriechen, obwohl SRD 5.2.1 *Dropping to 0 Hit Points* (S. 17, CC BY 4.0) Bewusstlosigkeit vorgibt.
- **Implementiert:** Fail-closed-Prüfung auf bekannte positive TP und nicht toten Helden in `app/lib/domain/prone_movement_rules.dart` und `app/lib/domain/crawling_movement_rules.dart`; ohne Zustands-, Modell-, Schema- oder Controlleränderung.
- **Tests ergänzt:** Je ein negativer Legacy-0-TP-/JSON-/Unverändertheitsfall und positiver Heilungs-/Bewegungsfall in `app/test/prone_standing_rules_test.dart` bzw. `app/test/prone_crawling_rules_test.dart`.
- **Getestet:** GitHub-Lesezugriff, Main-/PR-Dateilisten, offizielle SRD-Quelle; nicht als Flutter-Ausführung auszugeben.
- **Nicht getestet:** lokale Dart-/Flutter-Suite, Python-/Backend-Volltests, APK und finales GitHub-Actions-Ergebnis (SDK und Repository-Netz-Zugriff lokal nicht verfügbar). Keine Migration, Auto-Merge oder Branchlöschung.
- **Nächster Schritt:** CI auf finalem Branch-HEAD abnehmen und bei Fehlern denselben Branch korrigieren; danach fachlich geprüften PR durch Chat D integrieren.


## Chat B – NPC-Beziehungsauswahl für bestätigte Wiederaufnahme (02.11.2026)

- **Ausgangs-main:** `885580202caeafc9787538b6dc1c833b3190a529`;
  **Branch:** `feat/chat-b/confirmed-npc-resume-selection-20261102`;
  **Draft-PR:** [#489](https://github.com/ManuEtt/Dnd/pull/489).
- **Problem:** Bisherige Reader decken einzelne NPCs ab, aber keinen
  sicher sortierten, begrenzten Kampagnen-Wiederaufnahmekontext über
  bestätigte Beziehungen mehrerer NPCs.
- **IMPLEMENTIERT:** `ConfirmedNpcResumeSelector.read` in neuer
  `app/lib/story/confirmed_npc_resume_selection.dart`; sortiert
  lokal bestätigte Notizen nach UTC-Zeit, gespeichertem Eintragsindex
  und ID. Ignoriert unbestätigte Narration, ungültige/doppelte IDs,
  verwaiste Notizen. Max. drei NPCs, drei Notizen/NPC und 2.400
  UTF-16-Codeunits; Unicode-sichere Vorschau mit sichtbaren NPC-IDs,
  unveränderliche Ergebnislisten, Revisions-/Sitzungs- und
  volltextbasierte Same-Revision-Revalidierung.
- **TESTS ERSTELLT:** `app/test/confirmed_npc_resume_selection_test.dart`:
  sieben Gruppen für Sortierung, getrennte Identitäten, unsichere
  Legacy-IDs, Unicode-/Emoji-Grenzen, stale Revision/gleichrevidierte
  Änderungen, alten JSON und echten SQLite-Neustart samt
  unveränderter Hero-/Revisionskontinuität.
- **Fachdateien:** ausschließlich die zwei neuen Story-/Testdateien;
  additiv auch `README.md`, `docs/CODEX_CHECKPOINT.md` und
  `docs/parallel/CHAT_B_CHECKPOINT.md`.
- **GETESTET:** Main-SHA, offener PR-Bestand und Fachdateilisten,
  aktuelle Architektur und vorhandene Reader/Tests geprüft;
  offizieller Dart-3.9.2-Formatter angewandt und temporären
  Formatterworkflow wieder entfernt.
- **NICHT GETESTET:** finale vollständige GitHub-CI von #489, reales
  Android-Gerät/TalkBack/produktiver KI-Provider.
  **BLOCKIERT:** keine GitHub-Codeblockade; lokale Flutter-/Dart-Tools
  fehlen, Actions als Abnahmepfad. **Migration:** keine; SQLite 3,
  äußeres JSON 1, Version unverändert.
- **Koordination:** #452/#456/#459/#464/#470/#477/#486 betreffen
  andere Storydateien; README/Checkpoints nur durch Chat D additiv
  mit weiteren PRs konsolidieren. Kein Auto-Merge.
- **NÄCHSTER SCHRITT:** vollständige CI des finalen PR-HEAD prüfen,
  bei Fehlern nur eigenen Branch korrigieren; nach Grün
  koordinierte Review-/Integration durch Chat D.


---

## 02.11.2026 – Chat D: Gradle-JAR-Namenskollisionen vor Dekomprimierung abweisen

- **Basis-main:** `885580202caeafc9787538b6dc1c833b3190a529`, zuvor
  geprüfte Integration #480 von #475 und #476.
- **Main-CI:** #41401319969 beim Beginn dieses Pakets noch in Arbeit;
  nicht als grün ausgeben, solange `completed/success` fehlt.
- **Branch:** `fix/chat-d/wrapper-jar-unicode-collisions-20261102`.
- **Code-Commit:** `4b3a75daf3c6f2191f9776e98ffdbc2a880b0280`.
- **Test-Commit:** `e86ce230f57d42ffa4c857dfb9842a5a5a5004b7`.
- **IMPLEMENTIERT:** `verify_project.py` führt für jeden Wrapper-JAR-Eintrag
  komponentenweise ein NFC-/Casefold-Register mit allen übergeordneten
  Verzeichnispräfixen. Abweichende Schreibweisen mit gleichem
  kanonischen Ziel sind unzulässig, vor CRC-Test/Startklassenlesung.
- **REGRESSIONEN:** Fünf neue `test_verify_project.py`-Tests:
  ASCII- und `ß`-Casefold, NFC-Dateien,
  implizite Casefold-/NFC-Verzeichnisse sowie gültige Unicode-Pfade.
  Alle Negativfälle sperren CRC mit einem Mock.
- **GETESTET:** beide Quell-PRs #475/#476 und ihre Kombination #480 waren
  vollständig CI-grün auf den exakt geprüften Heads.
  Die neue Implementierung hat vor dem finalen Branch-CI noch keinen
  nachgewiesenen Python-/Flutter-/Android-Vollpass.
- **NICHT GETESTET:** abschließende CI auf finalem Branch-HEAD,
  echte Android-/SAF-/TalkBack-Geräteabnahme.
- **Parallelität:** 22 offene Fach-PRs A/B/C bei Paketbeginn geprüft;
  keiner bearbeitete die zwei technischen Python-Zieldateien.
  README/CODEX bleiben gemeinsame Dokumentations-Hotspots.
- **Migration:** keine SQLite-, JSON-, Spielstands-, Appversions- oder
  Berechtigungsänderung; das JAR selbst bleibt unverändert.
- **BLOCKIERT:** erfolgreiche volle CI, erneuter Main-/PR-Abgleich.
- **Nächster Schritt:** finalen CI-HEAD vollständig prüfen, Fehler
  auf demselben Branch korrigieren und keinen ungeprüften Merge durchführen.


---

## 02.11.2026 – Chat D: ZIP-Dateien dürfen keine Verzeichnispräfixe sein

- **Ausgangs-main:** `982cc1f548a309f8eb54cdb2ea37697267813389` (Integration #482 erfolgreich gemergt).
- **Basis-Main-CI:** #41408485671 bei Implementierung noch in Arbeit,
  deshalb noch nicht als erfolgreich bewertet; die vollständige PR-CI
  von #482 war zuvor erfolgreich.
- **Branch:** `fix/chat-d/zip-file-directory-conflicts-20261102`.
- **IMPLEMENTIERT:** `scripts/prepare_alpha_release.py` und
  `scripts/verify_project.py` registrieren kanonische Datei- und
  Verzeichnispräfixe für APK-/Gradle-JAR-ZIP-Einträge. Bei Schnittmenge
  (Datei wird zugleich als Ordner vorausgesetzt) wird das Archiv
  **vor `testzip()` und Entpacken** verweigert.
- **REGRESSIONEN:** vier APK- und drei Wrapper-JAR-Tests in
  `scripts/tests/test_prepare_alpha_release.py` und
  `scripts/tests/test_verify_project.py`: beide Eintragsreihenfolgen,
  Datei gegen implizites Elternverzeichnis, Datei gegen expliziten
  Verzeichniseintrag, erlaubte explizite Verzeichnisse/Unterdateien,
  unveränderte früher veröffentlichte Releases bei Ablehnung.
- **GETESTET:** vollständige ursprüngliche CI von #482 am finalen
  Head `b42b71f5f8835ab200c0892c0b6c9653e91aba9f` grün.
  Neue Tests und kombinierter Branch zu diesem Zeitpunkt noch nicht
  durch GitHub Actions vollständig abgenommen.
- **NICHT GETESTET:** finale Python-/Flutter-/Android-CI auf dem neuen
  Branch-HEAD; echte Android-/SAF-/TalkBack-Geräteabnahme.
- **Parallelität:** 28 andere offene PRs bei Beginn geprüft;
  keine technischen Änderungen an den vier Python-Zieldateien.
  README/CODEX/Chat-D-Checkpoint nur additiv ändern und später mergen.
- **Migration:** keine; Gradle-JAR-Binärdatei, Android-App-Code,
  App-Version, SQLite-/JSON-/Spielstände, Berechtigungen unverändert.
- **BLOCKIERT:** vollständige GitHub-PR-CI und finale Revalidierung von
  Main/PRs vor Review/Merge.
- **Nächster Schritt:** eigenen PR anlegen, CI auf finalem Commit prüfen,
  bei Fehlern auf eigenem Branch korrigieren; keinen fremden Branch löschen.

---

## 02.11.2026 – Chat D: Vorbereitete Integration von vier CI-grünen A/B/C-PRs

- **Main-Basis:** `c33448780dfe8b453f7f1db9d28c1396822901a7` nach #490,
  neue Main-CI #41424171660 bei Vorbereitungsbeginn noch laufend.
- **Arbeitsbranch:** `chore/chat-d/integrate-verified-abc-features-20261102`.
- **Quell-PR #485:** finaler Head `62e25c89eaa820f32f9b28cbf639245704850ae4`, vollständige CI #41402170368 grün.
- **Quell-PR #487:** finaler Head `964b0b07aab5b43bf5d90616dea483cbdc428d1a`, vollständige CI #41405378184 grün.
- **Quell-PR #488:** finaler Head `e89cc6250fd4e26467d411e68f8a05850ffb5df0`, vollständige CI #41405839209 grün.
- **Quell-PR #489:** finaler Head `b98ebb7d3310a5b5a3391e9b37266565ec29422b`, vollständige CI #41404718886 grün.
- **IMPLEMENTIERT:** zehn unabhängige technische App-Code-/Testdateien aus den Quellbranches
  werden 1:1 übernommen; alle additiven Quelländerungen in README,
  CODEX, CHAT_A, CHAT_B und CHAT_C sowie das neue Metamagie-Fachdokument erhalten.
- **GETESTET:** sämtliche vier Quell-HEADs jeweils vollständige GitHub-CI `completed/success` (36 Schritte).
- **NICHT GETESTET:** endgültige kombinierte CI, reale Android-/SAF-/TalkBack-Abnahme.
- **BLOCKIERT:** Main-Postmerge-CI auf `c3344878` und vollständige neue
  Integrations-CI auf finalem HEAD; vor Merge erneut alle offenen PR-Dateien kontrollieren.
- **Parallele Arbeit:** #481 und #483 überschneiden sich in
  `manual_turn_queue_dialog.dart`; beide bleiben außerhalb dieser Integration.
  Andere offene Fach-PRs und Branches nicht überschreiben oder löschen.
- **Migration:** keine durch die Zusammenführung selbst; alle Quell-PR-Semantiken
  und Warnungen zu noch nicht persistierten Metamagie-Auswahlbelegen bleiben bestehen.

---

## 02.11.2026 – Chat D: Vier weitere CI-grüne Fachpakete als Draft kombiniert

- **Basis-main:** `01259cbc93810a159c9a0d79d6055572f0bde3f1` nach #493; Main-Postmerge-CI noch ausstehend.
- **Integration:** `chore/chat-d/integrate-validated-story-rules-ui-20261102` mit den finalen Quellpaketen #478, #479, #486, #491.
- **CI der Quell-PRs:** #478: #41398490052 / #41398483892, #479: #41398989518, #486: #41402073724, #491: #41426189797 / #41426180554; alle auf jeweiligen finalen Source-Heads erfolgreich.
- **Technische Dateien:** 8 Fachcode-/Testdateien originalgetreu übernehmen; SRD-Distant-Touch-Fachdokument aus #478 unverändert.
- **Dokumentation:** Sämtliche reinen Einfügungen der vier Quell-Diffs in README, CODEX und den Chat-A/B/C-Checkpoints unter Quell-PR-Nennung nachtragen; vorherige Main-Dokumentation unverändert erhalten.
- **GETESTET:** Einzel-CIs. **NICHT GETESTET:** kombinierte CI am künftigen Integrations-HEAD sowie reale Android-Geräte-/SAF-/TalkBack-Abnahme.
- **BLOCKIERT:** vollständige neue GitHub-CI, Main-CI und letzter PR-/Main-Konfliktabgleich. Der Metamagie-Beleg aus #485 bleibt aktuell ohne Helden-/SQLite-Persistenz; daraus keine automatische Cast-Autorisierung ableiten.
- **Parallelität:** 23 andere offene PRs auf die 8 Fachpfade geprüft: keine Überschneidung. #481/#483 behalten ihren separaten manuellen Zugfolgedialog-Konflikt; keine fremden Branches löschen.

---

### Übernommener Originalnachtrag aus PR #478

# Chat A – Distant Spell Touch: 30 Fuß mit einem Zaubereipunkt (02.11.2026, eigener PR)

Basis-main `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`;
Branch `feat/chat-a/distant-touch-metamagic-20261102`.
SRD 5.2.1, Sorcerer / Metamagic / Distant Spell, CC BY 4.0.

**IMPLEMENTIERT:** Neues isoliertes
`SrdDistantTouchMetamagicRules.preview`
mit wirklichem 30-Fuß-Grenzwert
für Touch-Zauber und Pflichtprüfung
der bestätigten Sorcerer-Klassenstufe 2+,
Metamagie-Freischaltung, einer verfügbaren
Klassenressource `sorceryPoints`,
eines tatsächlich vorbereiteten
SRD-Zaubers der korrekten eigenen Klasse
und der vollständig bestätigten
blockerfreien Rastergeometrie.
Ausdrückliche Spieler-/Options-/Zielwahl
getrennt. Snapshotgebundene Vorschau,
Punktkosten nur als Kopie vorgemerkt.

**TESTS:** zehn neue positive/negative
Regressionsgruppen für 0/30/35 Fuß,
Metamagie-/Klassen-/Spell-Quellen,
Mehrklassenlevel, Slot- und Punkte-
Trennung, Status und Hindernisse,
alternde Vorschauen, JSON,
SQLite-Restart, Retry und stale Revision.
CI/Analyse/Debug-/ABI-Builds nur nach
tatsächlichem finalem Workflow-Abschluss
als grün melden.

**BLOCKIERT/GEPLANT:** Keine
dauerhaft versionierte Metamagiewahl
im Helden. Der aktuelle Boolwert ist
kein manipulationssicherer Nachweis,
keine Live-Casting-Engine-Integration
und keine atomare Zauberplatz-/Effekt-/
Punktausgabe. Deshalb **kein** impliziter
automatischer Fern-Touch-Cast. Unberührt:
PR #461/#463/#472, gemeinsam genutzte
Domainmodelle, Controller, SQLite3,
JSON1 und App-Version.

**NÄCHSTER SCHRITT:** nach
koordiniertem Merge Metamagiewahl als
versionierten Quellbeleg speichern,
mit dem Grid- und Spell-Preflight
verbinden und vollständige
Casting-Kosten in einem revisions-
geschützten Persistenzschritt testen.
[Technischer Fachbeleg](SRD_DISTANT_TOUCH_METAMAGIC_20261102.md).

---


---

### Übernommener Originalnachtrag aus PR #479

## 02.11.2026 – Chat C: Zauberwirkungsdialog bei 200 % Text und IME (PR #479)

[PR #479](https://github.com/ManuEtt/Dnd/pull/479) auf `feat/chat-c/confirmed-spell-effect-ime-20261102` von `main` `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`: Der `ConfirmedSpellEffectDialog` verwendet `AlertDialog(scrollable:true)`, kompakte Insets und Screenreader-Live-Region für Validierungsfehler; lange Laufzeitoptionen besitzen Ellipsis. Vier neue Flutter-Widgettests bei 320/360 dp, 200 % Schrift und 220 dp simuliertem Tastatur-Inset prüfen Fehler/Abbruch, gültige Quellbestätigung und das gezielte Beenden nur einer von zwei Quellen, jeweils ohne Mutation des Helden. **Finaler CI-Nachweis für #479 steht aus (Draft).** Keine Regel-, Controller-, Domain-, Speicher-, Datenformat-, Versions- oder Migrationsänderung. Echte TalkBack-/Android-Gerätetests weiterhin offen.


---

### Übernommener Originalnachtrag aus PR #486


## Chat B – kurze, bestätigte NPC-Historie sicher begrenzen (02.11.2026)

- **Ausgangs-main:** `885580202caeafc9787538b6dc1c833b3190a529`;
  **Branch:** `feat/chat-b/bounded-confirmed-npc-excerpt-v2-20261102`;
  **Draft-PR:** [#486](https://github.com/ManuEtt/Dnd/pull/486).
  Ein älterer, nicht gemergter eigener Draft #484 auf altem Main wurde
  zugunsten dieser neuen Basis geschlossen; seine Branchdaten bleiben.
- **Problem:** bestehende bestätigte NPC-Historie hat keine kontrollierte
  Kürzung für kleine Rückblicke, besonders bei sehr langen Legacy-Feldern.
- **Implementiert:** neues `app/lib/story/confirmed_npc_continuity_excerpt.dart`
  mit maximal 1.800 UTF-16-Einheiten, höchstens drei bestätigt
  gespeicherten Beziehungsnotizen, sicherer sichtbarer NPC-ID,
  Unicode-/Bidi-Bereinigung und rune-sicherer Kürzung. Read-only:
  keine Bestätigung aus freier KI-Prosa, keine Zustandsänderung.
- **Testdatei:** `app/test/confirmed_npc_continuity_excerpt_test.dart`:
  sechs positive/negative Gruppen (Faktenisolation, lange Emoji-Texte,
  Zeilen-/Bidi-Injektion, ungültige IDs/Grenzen, Alt-JSON ohne Notizen,
  echter SQLite-Neustart und unveränderter Held/Revision).
- **Andere Dateien:** additive README, zentraler und Chat-B-Checkpoint;
  `npc_continuity_reader.dart` aus PR #477 **nicht** geändert.
- **Getestet:** aktuellen main, offene PR-Fachdateien und zugehörige
  Architektur/Tests geprüft; offiziellen Dart-3.9.2-Formatter ausgeführt,
  temporäre Workflowdatei vor PR entfernt.
  **Nicht getestet:** finale volle PR-CI, Android-Echthardware/TalkBack,
  echte KI-Provider-Anbindung. **Blockiert:** lokales Dart-/Flutter-SDK;
  Actions als vollständige CI verfügbar.
  **Migration:** keine; SQLite 3, äußeres JSON 1 und Version unverändert.
  **Koordination:** README/Checkpoints mit Chat D additiv konsolidieren.
- **Nächster Schritt:** vollständige CI auf finalem PR-HEAD abnehmen,
  Fehler nur auf diesem Branch korrigieren, danach Integration/Review
  ohne automatischen Merge.


---

### Übernommener Originalnachtrag aus PR #491


---

## 02.11.2026 – Chat B: U+200C/U+200D im unbestätigten KI-Storyparser sperren

- **Ausgangs-main:** `c33448780dfe8b453f7f1db9d28c1396822901a7`.
- **Branch:** `feat/chat-b/ai-provider-zero-width-guard-20261102`; **PR:** [#491](https://github.com/ManuEtt/Dnd/pull/491) (Draft).
- **Commitnachweise:** Parser `bfcedd60ea018d0c5964afaf571cf9554736b365`, Regressionen `4295681ff0fb9b0660140640c23c50d0412c02dd`.
- **IMPLEMENTIERT:** `app/lib/story/ai_story.dart` lehnt in neuen `AiStoryPlan`-/`AiStoryStep`-Textfeldern unsichtbare Joiner U+200C/U+200D zusammen mit den bisher gesperrten U+200B/U+200E/U+200F ab. Reguläre Erzählabsätze bleiben erlaubt. `app/test/ai_story_zero_width_validation_test.dart` prüft positive und negative Feldvarianten und unveränderten Kampagnenzustand.
- **GETESTET:** GitHub-Quellvergleich, Main-SHA, sämtliche offenen PR-Dateipfade und eigenständige Fachpfade geprüft; Branch/Commits/PR angelegt.
- **NICHT GETESTET:** Neue Flutter-Tests, gesamte CI auf finalem PR-HEAD, echte Android-Geräte/produktiver KI-Dienst. Kein lokales Flutter/Dart, kein lokaler Checkout.
- **MIGRATION:** keine. Kein SQLite-/JSON-/Regel-/Held-/Questwechsel. Keine Änderung an alten Spielständen.
- **NÄCHSTER SCHRITT:** finale GitHub-CI abnehmen, Fehler gegebenenfalls im eigenen Branch korrigieren. README/CODEX/CHAT_B bei Integration mit anderen laufenden PRs verlustfrei additiv zusammenführen.

---

## 02.11.2026 – Chat C: Materialinventar bei großer Schrift/IME (PR #474)

[PR #474](https://github.com/ManuEtt/Dnd/pull/474) auf Branch `feat/chat-c/material-inventory-ime-main-20261102` basiert auf aktualisiertem Main `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`. `SrdMaterialInventoryDialog` ist als Ganzes scrollbar (`AlertDialog(scrollable: true)`) mit kompakten Insets; Rezept- und Validierungsfehler sind Screenreader-Live-Regionen. Fünf Widgetfälle auf 320/360 dp, 200 % Schrift und 220 dp Fake-IME prüfen fehlendes Rezept, negative Bestätigung, read-only Auswahl zweier bestätigter Materialstapel ohne Inventar-/Zauberveränderung und die Astral-Projection-Zieleingabe. **Neuer PR-HEAD muss noch vollständig in GitHub Actions geprüft werden; Draft bis CI grün.** Kein Domain-, SQLite-, JSON-, Version- oder Regelwechsel; keine Migration. Main-Merge während Arbeitsbeginn erkannt und Code neu auf frischer Main-Basis erstellt; geteilte Doku additiv integrieren.

---

## 02.11.2026 – Chat C: Kreaturen-Erfassungsdialog bei 200 % Schrift/IME (PR #469)

[PR #469](https://github.com/ManuEtt/Dnd/pull/469) auf Branch `feat/chat-c/area-creature-ime-20261102` gegen `main` `5a88834c98f5aca40395088c20c7e1dc5b587868` ersetzt den verschachtelten vertikalen Inhalt von `AreaCreatureRegistrationDialog` durch ein gesamthaft scrollbares `AlertDialog(scrollable: true)`. Fehler erhalten `Semantics(liveRegion:true)`. Vier neue Widgettests für 320/360 dp, 200 % Schrift, 220 dp IME prüfen fehlende Bestätigung, neutrale Abbruchaktion, gültige Registrierung sowie Null-TP und nachfolgende Korrektur. **Noch keine grüne finale PR-CI behaupten; Draft bis vollständiger CI-Abnahme.** Keine SRD-/Domain-, Speicher-, Datenformat- oder Versionsänderungen; echte Android-Gerätetests/TalkBack offen. Vorpaket [PR #465](https://github.com/ManuEtt/Dnd/pull/465) ist auf `3cd78d0881e3b0093eefb96342f7fb9b165292db` vollständig grün und bereit zur Review, nicht gemergt.

**Nachweis Chat-D-Integration (02.11.2026):** Die zuvor als ausstehend beschriebenen vollständigen Einzel-CIs sind auf den finalen Heads abgeschlossen und erfolgreich: [#474 / 41396373761](https://github.com/ManuEtt/Dnd/actions/runs/41396373761) und [#469 / 41393278139](https://github.com/ManuEtt/Dnd/actions/runs/41393278139). Kombination mit #495 erfordert eine eigene CI.

---

## 01.11.2026 – Chat C: Zustandsquellen-Dialog mit IME/Großschrift (PR #465)

Im Flutter-Dialog `app/lib/ui/condition_effect_dialog.dart` wird der verschachtelte Scrollbereich durch `AlertDialog(scrollable: true)` mit schmalen Insets ersetzt. Lange Dropdown-Beschriftungen werden mit Ellipsis begrenzt und Validierungsfehler als Screenreader-Live-Region angekündigt. Vier Widgettests in `app/test/condition_effect_dialog_ime_test.dart` prüfen 320/360 dp, 200 % Schrift, 220 dp simulierte Tastatur, Abbruch, explizite Bestätigung und Auswahl nur einer existierenden Zustandsquelle ohne Heldenmutation. Ausgangs-main `5a88834c98f5aca40395088c20c7e1dc5b587868`, Branch `feat/chat-c/condition-effect-dialog-ime-20261101`, [PR #465](https://github.com/ManuEtt/Dnd/pull/465) (Draft). **Neue CI bis finalem HEAD nicht als bestanden behaupten.** Keine Regel-/Controller-/Speicher-/Schema-/Versionsänderung. Additive Paralleldokumentation beim Merge konsolidieren.

---

## 01.11.2026 – Chat C: Mehrklassen-Dialog bei 200 % Schrift/IME (PR #458)

Der bisher verschachtelt scrollende `MulticlassSelectionDialog` wird mit `AlertDialog(scrollable: true)` und kompakteren Insets dargestellt. Erfahrung und Meilenstein sind auf kleinen Displays horizontal scrollbar. Vier neue Widgettests bei 320/360 dp, 200 % Schrift und simuliertem 220-dp-Tastatur-Inset prüfen EP-Sperrung, Abbruch, bestätigten Meilenstein und Fertigkeitsvoraussetzung einer Barden-Zweitklasse. Ausgangs-main `5a88834c98f5aca40395088c20c7e1dc5b587868`, Branch `feat/chat-c/multiclass-dialog-large-text-ime-20261101`, [PR #458](https://github.com/ManuEtt/Dnd/pull/458) (Draft bis zur finalen CI). **Neue Flutter-/Android-/Backend-CI noch nicht als bestanden behaupten.** Keine Domänen-, JSON-, SQLite-, Ressourcen-, Lizenz- oder Versionsänderung. Parallele README-/Checkpoint-Änderungen beim Merge additiv konsolidieren.

---

## 31.10.2026 – Chat C: Magieinitiierter-Dialog (PR #457, Draft)

Im Flutter-Dialog `app/lib/ui/srd_magic_initiate_dialog.dart` wird der verschachtelte Scrollbereich durch `AlertDialog(scrollable: true)` mit schmalem Außenabstand ersetzt. Vier neue Widgetfälle in `app/test/srd_magic_initiate_ime_test.dart` decken 320/360 dp, 200 % Schrift, simuliertes 220-dp-IME-Inset, Abbruch, nichtbestätigbare doppelte Zaubertricks und vier ausdrücklich bestätigte Pflichtwerte ab. Ausgangs-main `5a88834c98f5aca40395088c20c7e1dc5b587868`; Branch `feat/chat-c/magic-initiate-ime-scroll-20261031`, [PR #457](https://github.com/ManuEtt/Dnd/pull/457). **Neue Flutter-/Android-CI noch ausstehend; nicht als abgenommen ausgeben.** Keine Regel-, Datenmodell-, Controller-, Speicher-/Schema-, Versions- oder Lizenzänderung; keine Migration. Parallele Dokumentationsänderungen beim Merge additiv konsolidieren.

---

## 31.10.2026 – Chat C: Hintergrundpaket bei großer Schrift und Tastatur (PR #455, Draft)

Dialog `app/lib/ui/srd_background_package_dialog.dart` nutzt `AlertDialog(scrollable: true)`, kompakte Außenränder und expandierte Auswahlfelder für Spielset und Heiliges Symbol. Neue Widgettests `app/test/srd_background_package_ime_test.dart` prüfen Soldat und Akolyth bei 320/360 dp/200 % Schrift mit simuliertem 220-dp-Tastatur-Inset, einschließlich gesperrter Bestätigung, Abbruch und gültiger expliziter Auswahl. Base-main `5a88834c98f5aca40395088c20c7e1dc5b587868`, [PR #455](https://github.com/ManuEtt/Dnd/pull/455) auf `feat/chat-c/background-package-large-text-ime-20261031`. **Bis zum finalen PR-CI-Lauf nicht als getestet oder APK-fertig darstellen.** Keine Regel-, Controller-, JSON-, SQLite- oder Versionsänderung; keine Migration. README/zentralen Checkpoint bei parallelen PRs additiv konsolidieren.

**Integrations-CI-Nachweis (02.11.2026):** Vollständige Quellprüfungen waren jeweils auf dem finalen Head erfolgreich: [#465](https://github.com/ManuEtt/Dnd/actions/runs/41323668152), [#458](https://github.com/ManuEtt/Dnd/actions/runs/41282153192), [#457](https://github.com/ManuEtt/Dnd/actions/runs/41248140576) und [#455](https://github.com/ManuEtt/Dnd/actions/runs/41246044715). Historische Angaben „CI ausstehend“ beziehen sich auf den damaligen Veröffentlichungszeitpunkt. Kombinierte neue CI bleibt verpflichtend.

---

# Chat A – 5-Fuß-Raster Berührungszauber begrenzen (02.11.2026, eigener PR)

Ausgangs-main `5a88834c98f5aca40395088c20c7e1dc5b587868`.
Branch `fix/chat-a/grid-touch-range-20261102`.
SRD 5.2.1, *Spells / Range / Touch*, CC BY 4.0.

**Implementiert:** `SrdSpellGridTargetRules.factsFor`
verweigert bei bekannten Rasterentfernungen von
über 5 Fuß die `Touch`-Freigabe, selbst bei
`withinTouchReachConfirmed=true`. Eigenes
Feld und acht angrenzende Zellen erfordern
weiterhin ausdrücklich bestätigte Berührung,
überprüfte Karte und fehlende Hindernisse.
Keine Auswirkungen auf Reichweite `Self`
und Fernzauber. Für offiziell nicht auf
5 Fuß festgelegte Spezialreichweiten
muss später ein eigener belegter
Mechanismus eingebaut werden; kein
willkürliches Auto-Gewähren.

**Neue Tests:** positive/negative
5-Fuß-Grenzen, Klerikerzauber-Preflight
ohne Ressourcenverlust, Legacy-JSON,
SQLite-Neustart, idempotenter Retry und
stale Revision. Vollständige CI und
APK-Ergebnisse auf endgültiger Branch-SHA
nach Veröffentlichung im PR nachweisen;
keine ungeprüfte grüne CI behaupten.
Keine Migration (SQLite3, äußeresJSON1).
Andere offene PRs/Branches unberührt.

**Nächster Schritt:** Spezialreichweiten
für Berührungszauber mit nachgewiesener
Spielregelquelle (statt nur Bool) begrenzen
und als separaten, testbaren Eingabevertrag
mit Persistenz-/Revisionsfällen modellieren.
[Fachnachweis](SRD_GRID_TOUCH_REACH_20261102.md).

---

---

# Chat A – Auslöser und Anzahl des Zaubervorbereitungstauschs (01.11.2026, separater PR)

**Basis-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
**Branch:** `feat/chat-a/prepared-spell-exchange-triggers-20261101`.
**Quelle:** SRD 5.2.1, S.104, *Spell Preparation by Class*, CC BY 4.0.

**IMPLEMENTIERT:** Eine neue isolierte lesende Regelprüfung
`SrdSpellPreparationExchangeRules.preview` erlaubt
bei bestätigter langer Rast je einen Austausch für
Paladin/Waldläufer oder beliebig viele für
Kleriker/Druide/Magier; beim Klassenstufenaufstieg genau
einen für Barde/Zauberer/Hexenmeister. Eigene Klassenlevels
werden getrennt von der Gesamtstufe geprüft. Keine
unbestätigten Cantrips, Fremdklassen, Dubletten, Zaubergrade
oder Zauberbuch-Einträge. Der reine Plan bindet
Vorher-/Nachher-Charakter über JSON-Snapshots und schreibt
keine Helden-/Rast-/Spielstandänderung.

**Tests angelegt:** elf positive/negative Gruppen,
einschließlich acht Klassen, Englisch/Deutsch-Aliase,
erlaubter/gesperrter Anzahl, Mehrklassen-Stufenanstieg,
Absage/Unveränderlichkeit, SQLite-Restart und stale
Revision. CI-Status auf dem finalen PR-SHA nachmessen
und gesondert dokumentieren, nicht vorab als grün behaupten.

**Kompatibilität:** keine Modelle, Controller,
Story, UI, Repository, Migration oder Engine geändert;
SQLite3/JSON1/App-Version unverändert. PR #461 und
#463 besitzen weiterhin ihre eigenständigen Preflight-
und Persistenzimplementierungen. Keine unkontrollierte
Dokumentationsüberschreibung bei Integration durch Chat D.

**NÄCHSTER SCHRITT:** nach koordiniertem Integrationsreview
die freigegebene Klasse und Wechselgrenzen atomar an
bestätigte Rast-/Klassen-Aufstiegsaktionen anbinden,
mit SQLite- und Rollback-Fällen.
[Fachbeleg](SRD_SPELL_PREPARATION_EXCHANGE_20261101.md).

---

---

# Branch-Ergänzung 31.10.2026 – Chat A: bestätigte Klassenaliase

**Noch nicht in main integriert.** Basis-main
`5a88834c98f5aca40395088c20c7e1dc5b587868`,
Branch `feat/chat-a/multiclass-slot-aliases-20261031`.

Die reine Leseberechnung der normalen Zauberplätze in
`app/lib/domain/multiclass_rules.dart` löst jetzt bestätigte Klassen
mit dem bestehenden `findSrdClass`-Resolver auf. Deutsch/Englisch/
feminine Aliase ergeben dieselbe Zauberstufe; Paladin und Waldläufer
zählen gemäß SRD 5.2.1 jeweils halb aufgerundet, Hexenmeister-Paktmagie
bleibt getrennt und unbekannte Klassen erhalten keine erfundenen Slots.
Die gespeicherten Klassenlabels ändern sich nicht.

`app/test/multiclass_spell_slot_alias_test.dart` ergänzt sieben
positive/negative Prüfgruppen einschließlich Alt-JSON, SQLite-Neustart,
idempotentem Save-Retry und stale Revision. Keine Migration (SQLite 3,
JSON 1), keine neue API, kein KI-/Story-/UI-Eingriff. Bei Start offene
PRs #446–#449, davon #448 anderer Chat-A-Regelbaustein; keine
Überschneidung der neuen Fachdateien. README und Checkpoints müssen
bei parallelen PRs additiv integriert werden.

**Teststatus zum Dokumentationscommit:** Quell-/Vertragsprüfung
durchgeführt, neue Flutter-/Dart-/SQLite-Tests mangels lokalem SDK
nicht ausgeführt; neue CI ist abzuwarten und nur auf dem finalen
PR-HEAD zu beurteilen. Die zuvor erfolgreiche Main-CI
[41184883579](https://github.com/ManuEtt/Dnd/actions/runs/41184883579)
belegt nicht die neuen Änderungen. Reales Android-Gerät, Upgrade,
TalkBack und produktive Signierung sind weiter offen.

**Nächster unabhängiger Chat-A-Schritt:** vorbereitete Zauber pro
Mehrklassen-Stufe vor Wirken anhand ausdrücklich bestätigter
Regelmetadaten abgleichen; positive/negative Domain-, JSON- und
SQLite-Retrytests, keine angenommene Zaubervorbereitung oder
implizite Storyregeln. Detaillierter Fachstand:
[Chat-A-Checkpoint](parallel/CHAT_A_CHECKPOINT.md).

---

---

# Chat-A-Branchnachtrag – mehrdeutige Mehrklassen-Zaubervorbereitung (01.11.2026)

**Noch nicht in main** · Basis `5a88834c98f5aca40395088c20c7e1dc5b587868`,
Branch `feat/chat-a/multiclass-prepared-source-20261101`.
SRD 5.2.1, S. 25, *Multiclassing / Spells Prepared*, CC BY 4.0.

`SrdSpellPreflightRules.preflight` verlangt jetzt eine ausdrückliche
`preparedForCastingClassConfirmed`-Bestätigung, wenn beide eigenen
Zauberklassen denselben Zauber jeweils nach ihrer individuellen
Klassenstufe vorbereiten könnten. Die alte globale
`HeroCharacter.spells`-Liste wird dabei **nicht** stillschweigend
als klassenbezogener Nachweis interpretiert; nur eine eindeutige
vorhandene Klasse bleibt ohne zusätzliche Bestätigung zulässig.
Die bestehende getrennte Ressourcen-/Ziel-/Materialprüfung und
Snapshot-Revalidierung bleiben erhalten.

Neue Fachdateien bzw. Änderungen:
`app/lib/domain/srd_spell_preflight_rules.dart`,
`app/test/srd_multiclass_prepared_source_test.dart`,
`docs/SRD_MULTICLASS_PREPARED_SOURCE_20261101.md` sowie
die beiden Chat-/Zentral-Checkpoints und README.
Keine Migration (SQLite 3, JSON 1), keine Klassen-/Zauber-
Rekonstruktion aus KI-Antworten oder unbestätigten Altspielständen.
Acht neue deterministische Testfälle einschließlich JSON/SQLite;
**CI auf finalem PR-HEAD ist zunächst ausstehend**.
Frühere erfolgreiche Prüfungen anderer Commits sind kein Nachweis.

Koordination: Die offenen PRs #446–#458 wurden geprüft;
keiner verändert diese Fach-/Testdateien. Chat D soll gemeinsame
Dokumentation additiv konsolidieren. Keine Änderung an main,
fremden Branches oder bestehender Spielstandmigration.

**Genau nächster Schritt:** Einen ausdrücklich bestätigten,
rückwärtskompatiblen per-Klasse-Vorbereitungsnachweis entwerfen
und mit Alt-JSON-, Revisions-, Speicherkonflikt- und
Stufengrenzentests absichern; globale Liste nicht umdeuten.
Fachdetails im [Chat-A-Checkpoint](parallel/CHAT_A_CHECKPOINT.md).

---

---

## 31.10.2026 – Chat C: barrierearme Schildreaktion (PR #450, Draft)

UI-only: `app/lib/ui/hero_shield_reaction_dialog.dart` nutzt jetzt `AlertDialog(scrollable: true)`, kleinere Insets und expandierte Auswahlfelder. Neue Regressionstests in `app/test/hero_shield_reaction_dialog_large_text_ime_test.dart` für 320/360 dp, 200 % Schrift, simulierte Tastatur, Abbruch, V/S-Freigabe und gesperrten Bestätigungspfad ohne vorbereiteten Zauber. Basierend auf main `5a88834c98f5aca40395088c20c7e1dc5b587868`; Branch `feat/chat-c/hero-shield-dialog-large-text-ime-20261031`, PR [#450](https://github.com/ManuEtt/Dnd/pull/450). **Kein Flutter/Dart lokal vorhanden; Tests noch nicht ausgeführt, GitHub-CI auf finalem PR-HEAD offen.** Unveränderte Regeln, Speicherformate und Version; kein Merge, keine Migration. Gemeinsame Dokumentation beim Merge mit parallel offenen PRs additiv konsolidieren.

**Integrationsstatus Chat D (02.11.2026):** Erfolgreiche Einzel-PR-CIs auf finalen Quellheads: [#472](https://github.com/ManuEtt/Dnd/actions/runs/41393551106), [#467](https://github.com/ManuEtt/Dnd/actions/runs/41323611885), [#453](https://github.com/ManuEtt/Dnd/actions/runs/41244807154), [#461](https://github.com/ManuEtt/Dnd/actions/runs/41282290565) und [#450](https://github.com/ManuEtt/Dnd/actions/runs/41244483591). Neue kombinierte Integrations-CI ist noch auszuwerten; historische „CI ausstehend“-Texte sind keine aktuellen Messergebnisse.

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

# Chat B – NPC-Wiederaufnahme: verdeckte Historienänderung erkannt (02.11.2026)

**Status:** Implementierung im [Draft-PR #501](https://github.com/ManuEtt/Dnd/pull/501), Branch `feat/chat-b/npc-hidden-history-staleness-20261102`, ursprüngliches Main `55d33945872e251ec53b6860addcb05152a80c3a`, konfliktfrei aktualisiert auf Main `84437e4e92d735e179bb2585427b46a10451951d`, Code-/Testcommit `1f05dceea033c32094dad9b748898c203299b60c`.

**IMPLEMENTIERT:** Private vollständige NPC-Historien-Quellbindung in `NpcIdentityMemory` verhindert dieselbe-Revisions-Wiederverwendung eines Lesekontexts nach Änderungen an per `maxNotes` verdeckten Notizen. Unabhängige NPC-Verläufe und bestehendes öffentliches Story-Kontextformat bleiben erhalten.

**GETESTET:** GitHub-PR/Datei-Konfliktprüfung; neues Testdesign in `app/test/npc_identity_memory_test.dart` (zwei deterministische Fälle). **NICHT GETESTET:** Dart/Flutter, vollständige CI, Android/APK und Realgerät auf dem finalen Branch-HEAD; keine SDKs für lokale Abnahme. **BLOCKIERT:** lokales Dart/Flutter/DNS; Gesamt-CI-Mergegate offen. **NOCH NICHT IMPLEMENTIERT:** weitere Identitätsvalidierung und Live-Provider-Abnahme. **Datenmigration:** keine, SQLite 3/JSON 1 unverändert; keine autoritative Regel-/Spielstandsänderung.

**Nächster unabhängiger Schritt:** Kollisionen älterer bestätigter Notiz-IDs in der schreibgeschützten NPC-Abfrage behandeln, mit Altspielstand-/JSON-/SQLite-Regressionsnachweis und kompletter CI.

---

---


## 02.11.2026 – Chat C: manueller Zusatzkreaturen-Angriff bei großer Schrift/IME (PR #492)

- **Ausgangs-main:** `c33448780dfe8b453f7f1db9d28c1396822901a7`.
- **Branch:** `feat/chat-c/manual-extra-attack-ime-20261102`; **PR:** [#492](https://github.com/ManuEtt/Dnd/pull/492) (Draft).
- **Code-/Test-HEAD vor Dokumentation:** `88dfb25b21065f51baad4031a7340d919696126c`; finalen HEAD dem PR entnehmen.
- **Ausgangsproblem:** Im umfangreichen Dialog für einen ausdrücklich bestätigten Zusatzkreaturen-Angriff erschwerten der innere Scrollbereich, lange Checkboxtexte und nicht expandierte Dropdowns die Bedienung auf 320/360 dp bei 200 % Schrift mit 220 dp IME.
- **Implementiert:** `AlertDialog(scrollable: true)` und kompakte Insets statt innerem `SingleChildScrollView`; kompakte visuelle Checkboxbeschriftungen ab 180 % mit vollständigem `Text.semanticsLabel`; drei expandierte Dropdowns, ellipsierte lange Kreaturennamen, lebende Fehler-Semantik. Keine Regel-/Controller-/Persistenzänderung.
- **Geänderte Fachdateien:** `app/lib/ui/manual_extra_creature_attack_dialog.dart`, neue `app/test/manual_extra_creature_attack_ime_test.dart`. Daneben additive README-/Checkpoint-Nachträge auf eigenem Branch.
- **Neue Regressionen:** Abbruch auf 320/360 dp mit 200 %/IME ohne Mutation, unvollständige Angriffsbestätigung ohne Mutation und positiver bestätigter Angriffs-DTO-Weg mit sieben Pflichtbestätigungen. Bestehende `manual_extra_creature_attack_dialog_test.dart` bleibt unverändert.
- **GETESTET:** Live-GitHub-main, 29 vor Start offene PRs inklusive geänderter Fachdateien und Quell-/Testfixtures geprüft; Branch/Commits und Draft-PR erstellt. Keine erfolgreichen ausführbaren Flutter-Tests behauptet.
- **NICHT GETESTET:** Dart-Format, Flutter-Analyse/Tests, Debug-APK, native Android-Tests, Python-/Backend-Gates auf finalem PR-HEAD, reales Android/TalkBack/IME und Altgeräteupgrade bis CI-/Geräteabnahme.
- **BLOCKIERT:** Lokales Flutter/Dart-SDK nicht vorhanden; CI auf finalem Commit nach Dokumentation neu bewerten. README-/zentrale Checkpoint-Integration wegen paralleler PRs durch Chat D.
- **Spielstandkompatibilität:** Keine Migration; unveränderte Domainregeln, JSON-/SQLite-Schemata, Ereignisse und App-Version.
- **Nächster unabhängiger Schritt:** `app/lib/ui/srd_class_level_up_dialog.dart` separat auf 320 dp/200 % und schmale Auswahlfelder prüfen; nur bei nachweisbarer UI-Regression testen und korrigieren, nicht parallel zu künftig kollidierenden PRs.

---

---

## Chat C – 02.11.2026: Sending-Dialog mit IME und großer Schrift

- **Branch:** `feat/chat-c/sending-dialog-ime-20261102`, Basis-Main `55d33945872e251ec53b6860addcb05152a80c3a`.
- **Implementiert:** Ein scrollbarer `AlertDialog` statt separatem Inhalts-Scrollbereich; kompakte visuelle Bestätigungen ab 180 % Schrift mit vollständigem TalkBack-Label und kurze Abschlussaktion.
- **Widgettests ergänzt:** `app/test/sending_attempt_ime_test.dart`; 320/360 dp, 200 % Schrift, 220 dp IME, Abbruch/Bestätigung, Re-Consent nach Textänderung und unverändertes Helden-JSON. Beim ersten vollständigen CI-Lauf #41452067597 bestanden 2.789 Fluttertests; der positive neue Touchfall scheiterte am nur abwärts scrollenden Testhelfer, der anschließend in beide Scrollrichtungen korrigiert wurde. Finale Wiederholungs-CI noch offen.
- **Grenzen:** Nur Flutter-UI und Widgettests, keine Regeln/Controller/SQLite/JSON/Version. CI am finalen SHA sowie reale Android-/TalkBack-Tests bis zur tatsächlichen Abnahme nicht als bestanden ausweisen.
- **Parallelität:** Offene Chat-C-/Integrations-PRs bearbeiten andere UI-Module; gemeinsame README-/Checkpoint-Ergänzungen bei Integration verlustfrei durch Chat D konsolidieren.

---

---

### Chat D: Checkpoint-Archivnamen ohne versteckte Unicode-Steuerzeichen (02.11.2026)

Ausgangs-main `516bc14e06cb02e7035a6adfb8e2d21e54253184`, Branch `fix/chat-d/checkpoint-unicode-ledger-20261102`. `scripts/create_checkpoint.py:safe_name` verbietet jetzt Unicode-Kategorien `Cc/Cf/Cs/Zl/Zp`, damit archivierte Checkpointnamen keine visuell täuschenden Einträge in `SHA256SUMS.txt` bilden; sichtbare Umlaute, Emoji und kombinierende Unicodezeichen bleiben erlaubt. Zwei positive/negative Regressionstests in `scripts/tests/test_create_checkpoint.py` schützen den bisherigen SHA-256-Verlauf und die unveränderten `LATEST`-Aliases bei ungültigen Namen. Vollständige Remote-CI ist auf dem finalen PR-HEAD noch zu bestätigen, keine Spielstands-/Schema-/API-Migration. Gemeinsame Dokumentation nicht überschreiben.

---

## Chat B – Orts-Wiederaufnahme (02.11.2026)

PR #505: bestätigte gespeicherte Ortsauswahl mit ID, Unicode-Schutz, Revision, sechs Tests; CI offen. Siehe docs/parallel/CHAT_B_CHECKPOINT.md.

---

## 02.11.2026 – Chat C: Wilder-Angreifer-Auswahl bei großer Schrift und IME

- **Main-Basis:** `516bc14e06cb02e7035a6adfb8e2d21e54253184`. **Branch:** `feat/chat-c/savage-attacker-ime-20261102`. **PR:** [#506](https://github.com/ManuEtt/Dnd/pull/506).
- **UI:** Ein vollständig scrollbarer `AlertDialog` statt eigener Inhalts-Scrollfläche; beide bereits geprüften Waffenwürfe zeigen expliziten `Semantics.selected`-Status. Keine direkte Schadens- oder Talentbuchung.
- **Tests:** Vier zusätzliche Widgetfälle bei 320/360 dp, 200 % Schrift und 220 dp Android-IME. Abbruch/ungültige Quelle gesperrt, Wahl eines auch niedrigeren Wurfs, kritischer Treffer und unverändertes Kampagnen-JSON.
- **Geprüft:** Zielgerichtete GitHub-Actions-Prüfung [#41478500514](https://github.com/ManuEtt/Dnd/actions/runs/41478500514) erfolgreich mit insgesamt 10 Widgettests. Offizielle Formatkorrekturen übernommen; temporärer Workflow entfernt.
- **Noch offen:** Vollständige CI auf finalem PR-Head und reales Android/TalkBack/IME/Upgrade. Nur `app/lib/ui/savage_attacker_selection_dialog.dart` und `app/test/savage_attacker_selection_dialog_test.dart` sowie additive Dokumentation geändert; keine Modell-/Speichermigration. Chat D konsolidiert zentrale Docs beim Merge.

---

---

## 02.11.2026 – Chat C: Sanfter Fall – erneute Zustimmung bei editiertem Schaden

- **Main-Basis:** `516bc14e06cb02e7035a6adfb8e2d21e54253184`, **Branch:** `feat/chat-c/slow-fall-ime-consent-20261102`; **PR:** [#509](https://github.com/ManuEtt/Dnd/pull/509) (Draft).
- `MonkSlowFallDialog` nutzt `AlertDialog.scrollable` und schmale Insets für Android-200-%-Schrift/IME.
- Editieren des Schadens widerruft die beiden vorherigen Checkbox-Zustimmungen. Der Dialog gibt weiterhin nur `ConfirmedSlowFallChoice` zurück, ohne selbst HP/Reaktion zu ändern.
- Vier Widgettests ergänzt (320/360 dp, 200 %, 220 dp IME, Abbruch, Reaktionssperre, Neuprüfung, keine Heldenmutation).
- Zielgerichtete und vollständige GitHub-CI noch zu belegen; physisches Android/TalkBack/Upgrade nicht getestet. Keine Domain-, Datenbank-, Export- oder Versionsmigration. Gemeinsame Docs bei Chat-D-Integration additiv konsolidieren.

---

---

## 02.11.2026 – Chat C: Manuelle Zugfolge bei 200 % Schrift/IME (PR #481)

[PR #481](https://github.com/ManuEtt/Dnd/pull/481) auf Branch `feat/chat-c/manual-turn-queue-ime-rebased-20261102` von Main `885580202caeafc9787538b6dc1c833b3190a529`: `ManualTurnQueueDialog` verwendet `AlertDialog(scrollable:true)` und schmale Insets; Validierungsfehler erhalten `Semantics(liveRegion:true)`. Fünf neue Widgetfälle bei 320/360 dp, 200 % Schrift und simuliertem 220-dp-IME prüfen nicht bestätigte Initiative, neutralen Abbruch, gültige rein deklarative Zugfolgen, erneute explizite Gleichstandsbestätigung nach Sortierung und read-only Fortschrittswahl; Campagne/Initiative wird nicht mutiert. **Finale CI für #481 noch offen und Draft.** Keine Domain-, SRD-, SQLite-/JSON-, Schema-/Versions- oder Migrationsänderungen. Main wurde nach parallel laufender Integration auf `885580202caeafc9787538b6dc1c833b3190a529` als sauberer PR-Ausgangspunkt aktualisiert.

---

## 02.11.2026 – Chat C: manuelle Kampf-Zugfolge bei IME/200 % Schrift (PR #483)

[PR #483](https://github.com/ManuEtt/Dnd/pull/483) auf `feat/chat-c/manual-turn-queue-ime-20261102` basiert auf Main `885580202caeafc9787538b6dc1c833b3190a529`. `ManualTurnQueueDialog` verwendet `AlertDialog(scrollable:true)` mit kompakten Insets, eindeutige akteursspezifische Pfeil-Tooltips und `Semantics(liveRegion:true)` für Validierungsfehler. Fünf neue Widgettests bei 320/360 dp, 200 % Schrift und 220 dp Fake-IME prüfen negatives Bestätigen/Abbrechen, positive explizite Initiative/Gleichstandsbestätigung, nur unverbindliches Vorrücken eines gespeicherten Markers und deaktivierte Aktion bei fehlender Kreaturen-Initiative. Kampagnendaten müssen unverändert bleiben. **Finale CI noch ausstehend, Draft bis Grün.** Keine Domain-/JSON-/SQLite-/Versionsänderung, keine Migration, echtes Gerät/TalkBack/Release-Signatur offen.

---

---

## Chat B – KI-Erzähltext gegen ältere Unsichtbarzeichen absichern (02.11.2026)

**Branch:** `fix/chat-b/story-provider-invisible-unicode-20261102`.
**Pull Request:** [#513](https://github.com/ManuEtt/Dnd/pull/513) (Draft).
**Ausgangs-main:** `a2f22eaceb344aaced12d0ad548b813aa44d544f`.
**Problem:** Die vorhandene Provider-Validierung blockierte viele C0/C1-
und Bidi-Zeichen, akzeptierte aber U+00AD, U+034F, U+180E und U+206A–U+206F.
**Implementiert:** Gleichartige zusätzliche Ablehnung in
`app/lib/story/ai_story.dart` und `backend/src/story.ts`.
**Tests neu:** `app/test/ai_story_invisible_unicode_test.dart`,
`backend/test/story-legacy-format-guard.test.ts`; positive legitime
Unicode-/Emoji-/Zeilenumbruchfälle und negative Plan-/Turn-/Angebotsfelder.
**GETESTET:** Repository, PR-Dateipfade und vorhandene Quellcodeprüfung;
zuvor wurde PR #505 auf exaktem Head erfolgreich vollständig CI-geprüft,
dies ist aber kein Nachweis für das neue Paket.
**NICHT GETESTET:** Endgültige GitHub-CI/Dart/Flutter/Android-Tests und Gerät
bis zur gesonderten Prüfung. Keine Migration von SQLite/JSON oder App-Version.
**Nächster Schritt:** neuen Draft-PR vollständig CI-prüfen und bei
Fehlschlägen denselben Branch reparieren; kein automatischer Merge.

---

### Chat D: APK-Quellpfad bei Alpha-Paketierung gegen Symlinks sperren (02.11.2026)

Ausgangs-main `a2f22eaceb344aaced12d0ad548b813aa44d544f`; Branch `fix/chat-d/alpha-apk-source-symlink-20261102`. `scripts/prepare_alpha_release.py` verwirft symbolisch verlinkte Quelldateien und über verlinkte Eltern erreichbare APKs vor der ZIP-Validierung; erneute Kontrolle nach Quellarchiverzeugung und vor dem Kopieren verhindert die Freigabe eines zwischenzeitlich verlinkten Quellpfads. Neue `scripts/tests/test_prepare_alpha_release.py`-Regressionen für direkte/indirekte Symlinks, Austausch nach Staging und zulässige unverlinkte APK. Keine Änderungen an Android-/SQLite-/JSON-/Spielstandsformaten oder Versionsangaben. Vollständige GitHub-CI auf finalem Branch-HEAD ausstehend; reine lokale statische Prüfungen nicht als CI-Erfolg zählen.

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
