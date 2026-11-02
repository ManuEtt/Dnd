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
