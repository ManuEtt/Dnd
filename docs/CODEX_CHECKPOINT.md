# Aktiver Checkpoint – 01.11.2026, UTC, Chat A

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
[Fachbericht und Grenzen](parallel/CHAT_A_CONCENTRATION_CLASS_PREFLIGHT_20261101.md).

Nächster Schritt nach Abnahme: allgemeine Klassen-Wiederholungen vor Würfel und
Ressourcenverbrauch auf dieselbe konsistente Klassenherkunft prüfen. Vorher
aktuelle PRs abgleichen; offene #453/#461/#463/#448 nicht erneut implementieren.
Die nachfolgenden früheren Entwicklungsstände sind historische Momentaufnahmen.

---

**Letzte vollständige Main-Abnahme:**
[41184883579](https://github.com/ManuEtt/Dnd/actions/runs/41184883579),
`5a88834c98f5aca40395088c20c7e1dc5b587868`, erfolgreich: 2.710 Flutter,
262 Python, 76 Backend, Debug/native/drei optimierte ABI-APKs und Quellpakete.
Diese Baseline beweist nicht die finale CI des neuen Branches.

**BLOCKIERT:** kein Code-/SDK-/GitHub-Blocker; Integration mit parallelen
README-/Checkpoint-Änderungen durch Chat D. Kein angeschlossenes Testgerät.
**Sicherung:** vorhandene `scripts/create_checkpoint.py` und History-Bundle
mit exakter Patchbasis `5a88834c98f5aca40395088c20c7e1dc5b587868` verwenden.
Lokaler Paketpfad `/workspace/artifacts/concentration-class-preflight-20261101/`.
Beim Wiederaufnehmen tatsächlichen Main, PR-Head und CI erneut prüfen.

Die Migration zu Issue #425 ist abgeschlossen: 54 abgeschlossene Branches
archiviert/entfernt, Issue geschlossen. Nicht erneut als offene Migration starten.
Aktuell laufen neue unabhängige Entwicklungs-PRs. Historischer Übergabestand folgt.

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
