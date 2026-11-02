## 02.11.2026 – Chat C: manuelle Kampf-Zugfolge bei IME/200 % Schrift (PR #483)

[PR #483](https://github.com/ManuEtt/Dnd/pull/483) auf `feat/chat-c/manual-turn-queue-ime-20261102` basiert auf Main `885580202caeafc9787538b6dc1c833b3190a529`. `ManualTurnQueueDialog` verwendet `AlertDialog(scrollable:true)` mit kompakten Insets, eindeutige akteursspezifische Pfeil-Tooltips und `Semantics(liveRegion:true)` für Validierungsfehler. Fünf neue Widgettests bei 320/360 dp, 200 % Schrift und 220 dp Fake-IME prüfen negatives Bestätigen/Abbrechen, positive explizite Initiative/Gleichstandsbestätigung, nur unverbindliches Vorrücken eines gespeicherten Markers und deaktivierte Aktion bei fehlender Kreaturen-Initiative. Kampagnendaten müssen unverändert bleiben. **Finale CI noch ausstehend, Draft bis Grün.** Keine Domain-/JSON-/SQLite-/Versionsänderung, keine Migration, echtes Gerät/TalkBack/Release-Signatur offen.

# Codex-Checkpoint – Gesamtintegration zu Issue #425

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
