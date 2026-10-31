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
