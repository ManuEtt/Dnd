# Branch-Migration am 28.10.2026

Würfelraunen **0.8.46+96**, Arbeitsbranch `integration/all-branches-20261028`.
Ausgangs-Main `dd0c2e94ccf0995c6070010b6af1df315205b36a`;
zwischenzeitlich integrierter Main `f9d68a97f35799e50881e9c6992efaed807e6301`.

## Umfang und Erhalt

Alle 26 ursprünglichen Nebenbranch-Köpfe sowie der während der Arbeit entstandene
Integrationsbranch `integration/conditional-imports-buttons-20261028` sind durch
reguläre Merge-Eltern erhalten. Bereits vorhandene Produktfunktionen wurden anhand
konkreter Dateien und Git-Blobs abgeglichen; alte Branchfassungen überschreiben
keine neueren Main-Funktionen. Alle 27 Ausgangsstände einschließlich Main sind
vorab in einem geprüften Git-Bundle gesichert. Kopf-SHAs und Zustände stehen im
[maschinenlesbaren Inventar](BRANCH_MIGRATION_20261028_INVENTORY.json).
Originaldokumente und Konfliktfassungen bleiben unter `docs/history/` samt
SHA-Manifesten erhalten; Git-Historie und Bundle bewahren sämtliche Quellstände.

## Übernommene Entwicklungspakete

| Gruppe | PRs / Inhalt | Grenzen |
| --- | --- | --- |
| Charakter | #297, #317, #319, #324, #330: Würfelherkunft, Klassenbeleg, Pflicht-Startwerte/-pakete für zwölf Klassen, Magieinitiierter-Auswahl, atomarer Editor-Schreibschutz | Auswahlbeleg beweist keine vollständige Zauberwirkung oder SRD-Erstellung |
| Klassenregeln | #313, #332, #336, #339, #340, #348: Entrinnen-Vorprüfung, bestätigte Bardenquelle, Unbezwingbare Stärke, Überlegene Inspiration, Unermüdlich, Stufe-20-Historie | Entrinnen bucht noch keine TP; manuelle nicht integrierte Stärke-Rettungswurfpfade bleiben offen |
| Kampfbelege | #338, #341: dauerhafte Wilder-Angreifer-Würfelvorschläge und revisionsgebundene Entscheidungsvorprüfung | noch keine durchgängige Angriffs-/Schadensbuchung für diese Vorschläge |
| Story | #322, #349: sitzungsgebundener Replay und bereits vorhandene Terminal-Wiederaufnahme | keine mechanischen Schreibrechte für KI oder Story |
| Erkundungs-/Materialhistorie | #287, #345–#347 und drei gestapelte Vorläufer | vorhandener Main-Produktcode erhalten; keine zweite Sprung-/Materialengine |
| Werkzeuge und Bedienung | #316, #320, #335, #301 sowie paralleler Integrationsbranch: bedingte Dart-Importprüfung, korrekte TalkBack-Buttonsemantik, geschützte Branches erhalten | alter konkurrierender Einmal-Löschworkflow nur noch manuell und lesend |

## Bei der Integration behobene Fehler

1. Ältere Barden-Initiative und aktueller Mönch-Stoffwechsel sind in allen drei
   Kampfstartpfaden gemeinsam erhalten; keine der beiden Ressourcenwirkungen geht verloren.
2. Der Barden-Bestätigungsdialog ist bei 320/360 dp, 200 % Schrift und Tastatur
   scrollbar. Vier neue Tests reproduzieren ohne Korrektur den RenderFlex-Überlauf.
3. Die bisherigen Klassenbeleg-UI-Tests wählen nun ausdrücklich KO und Startpaket,
   wie vom strengeren Zwölfklassen-Startvalidator gefordert; keine Regel wird abgeschwächt.
4. Ein gemeinsamer SQLite-Test bewahrt Attribut-, Klassen- und Talentbelege über
   Neustart und konkurrierende Bearbeitung. Abgelehntes Speichern verändert keine der
   sechs Tabellen; frisches Speichern vergibt kein Startgold und keine Ausrüstung erneut.
5. **Echter Altarchiv-CAS-Fehler:** Historische Gegenstände mit `catalogId` ohne `stats`
   werden beim Lesen korrekt ergänzt. Der neue Schreibschutz verglich zuvor rohes
   Datenbank-JSON mit normalisiertem Modell und lehnte unveränderte Altcharaktere ab.
   Beide Seiten werden jetzt innerhalb derselben Transaktion gleich normalisiert.
   Laden schreibt weiterhin nichts; echte konkurrierende Goldänderungen bleiben gesperrt.
6. PR #301 hätte einen zweiten automatischen Löschworkflow reaktiviert. Die Originaldatei
   ist bytegetreu archiviert; aktiv bleibt ausschließlich der bestehende Main-CI-gesicherte
   Cleanup samt Schutz geschützter Branches und offener PR-Verwendungen.

## Tatsächlicher Prüfstand dieses Checkpoints

**GETESTET (Teilpakete):** 120 unterschiedliche Charaktertests, 99 Regel-/UI-Tests,
32 Story-Tests, 24 Wilder-Angreifer-/Button-Tests; 195 Python- und 72 Backend-Tests;
zusätzlich zwei echte SQLite-Altarchiv-Regressionen im behobenen CAS-Pfad.
Die Teilpakete ersetzen keine gemeinsame Abnahme.

**Gesamtprüfung:** Der frühe Lauf auf `300f7be` wurde nach erfolgreichem Python-/Backend-
Teil und während Flutter ausdrücklich beendet (143), um den zusätzlich reproduzierten
Altarchivfehler vor der endgültigen Abnahme zu beheben. Dieser Lauf ist kein voller Erfolg.
Der korrigierte gemeinsame Stand wird anschließend vollständig mit `scripts/check.sh`
und Android-Debug/native Tests geprüft. Aktuelle Logs liegen außerhalb des Git-Repos unter
`/workspace/validation/20261028-migration-*`; finale CI-Links und Ergebnisse kommen in
PR-Beschreibung und Artefaktbericht. Kein Gerätetest wird aus einer APK abgeleitet.

**NICHT GETESTET:** echtes Android-Gerät, TalkBack auf Gerät, Upgrade historischer
installierter App-Daten und produktive Signierung. **BLOCKIERT:** kein angeschlossenes Gerät.
**NOCH NICHT IMPLEMENTIERT:** vollständiger Charakter-Wizard und vollständige SRD-Regelengine;
Detailgrenzen bleiben in den Teilpaketberichten und SRD-Registern sichtbar.

SQLite-Schema **3** und Kampagnen-JSON **1** bleiben unverändert. Keine weitere Migration,
keine automatische Neuberechnung bestätigter Helden, keine kostenpflichtigen KI-Aufrufe.
SRD-5.2.1-Attribution in `THIRD_PARTY_NOTICES.md` bleibt erhalten.

## Abschluss und Wiederaufnahme

Vor Löschung: finale PR-CI, regulärer Merge, danach tatsächliche Main-CI prüfen.
Nur exakt gesicherte, unveränderte und enthaltene Branchköpfe löschen. Neue oder
weitergeschriebene Branches erneut prüfen; keine Force-Pushes. Das frühzeitige Vollprojekt-ZIP
und der tatsächlich anwendbare Binärpatch liegen unter
`/workspace/artifacts/branch-migration-20261028/`; der abschließende Artefaktbericht
enthält verifizierte Downloadlinks und Wiederherstellungsschritte.

Nächster konkreter fachlicher Schritt nach Migrationsabschluss: im bestehenden
Klassenassistenten die drei katalogisierten Heiligen-Symbol-Varianten für Kleriker/Paladin
explizit und strukturiert wählen, speichern und ohne doppelte Ausrüstung testen.
Keine Hintergrundfortsetzung außerhalb einer aktiven Sitzung.

## Ergänzte gemeinsame lokale Abnahme / CI-Artefakte

Auf `4f03b788` wurden `bash scripts/check.sh`, Android-Debug-Build und native Tests
vollständig erfolgreich ausgeführt: **2185 Flutter / 195 Python / 72 Backend / 12 native**;
500 Dart-Dateien ohne Formatänderung, Analyzer sauber. Der frühe abgebrochene
Versuch bleibt separat als unvollständig protokolliert.

Der finale Workflow verwendet die bereits geprüfte `create_checkpoint.py` statt eines
bloßen ZIP-Exports: ZIP-Hash-/Modusprüfung, Binärpatch, echte Anwendung gegen expliziten
Basiscommit und Dateimanifest. Vollständig gefetchte Git-Historie ermöglicht zusätzlich
`Wuerfelraunen_History.bundle` samt SHA256; dadurch sind vorangehende Branchstände aus
dem CI-Artefakt anhand der dokumentierten SHAs wiederherstellbar. Bei PR-/Main-Merges
ist der erste Elterncommit die Patchbasis; im Root-Commit-Fall der Commit selbst.
Diese Verpackungsänderung ändert keine App-/Backend-/SQLite-Daten und erfordert eine
neue finale CI am PR-HEAD. Die finale Downloadabnahme bleibt bis dahin offen.
