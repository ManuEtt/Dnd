# Abschlussstand der Branch-Migration – 28.10.2026

**0.8.46+96**, Produkt-Main `6576d2fc742f000bacdd1c105282bc9e3282ae7e` aus regulärem PR #351.
Produktbaum `ec6bd6207681a59b55599a3f2ef8f7ae51487af4` identisch mit dem abschließend geprüften
PR-Kopf `c06b549` und CI-Checkout `9cf5ead`.

**Main-CI bestanden:** [Lauf 40708407065](https://github.com/ManuEtt/Dnd/actions/runs/40708407065) auf `6576d2fc742f000bacdd1c105282bc9e3282ae7e`.

**28 alte Quell-/Integrationsbranches archiviert und entfernt.** Alle Köpfe sind Vorfahren des geprüften Main; die exakten Archivtags stehen im Inventar. `feat/srd-warlock-magical-cunning-20261028` (Beobachtung `2026-10-28T14:59:26.197499+00:00`: `47cb207e99eeba0af3308de2b88c19f8357b0808`, PR #352) entstand danach und bleibt als aktive, separat zu prüfende Entwicklung erhalten.

Die finale PR-CI [40706203860](https://github.com/ManuEtt/Dnd/actions/runs/40706203860) ist vollständig erfolgreich:
2.185 Flutter / 195 Python / 72 Backend, 20 gezielte UI-Prüfungen sowie
Android-/Alpha-/Quellcheckpoint-Schritte. Lokal zusätzlich zwölf native Tests,
Format von 500 Dateien, Analyse, Backend- und Debug-Build erfolgreich.
Keine echte Geräteabnahme oder produktive Signierung; vollständiger Charakter-Wizard
und vollständige SRD-Engine bleiben offen. SQLite3 und JSON1 unverändert.

- [Main-Quellcheckpoint: Vollprojekt-ZIP, Binärpatch, Manifest und History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40708407065/artifacts/12826680612)
- [Main-Android-ARM64-Alpha (Debug-Testsignatur)](https://github.com/ManuEtt/Dnd/actions/runs/40708407065/artifacts/12826535931)

Das [Inventar](BRANCH_MIGRATION_20261028_INVENTORY.json) führt die einzelnen
Ausgangsköpfe, Ancestry und Archiv-/Löschbelege. Alle 27 Ursprungsrefs des
Ausgangsbundles wurden unabhängig wiederhergestellt und mit Manifest verglichen;
`git fsck --full --strict` ist erfolgreich. Dokumente vor dieser Konsolidierung
bleiben bytegetreu mit SHA256/Git-Blob-Manifest erhalten.

**Fortsetzung:** Heilige-Symbol-Katalogwahl für Kleriker/Paladin mit typisiertem
Inventar und Klassenbeleg; alte `startingClassChoice`-Version1 ohne neue Wahl
muss lesbar und historisch unbestätigt bleiben. Keine erneute Gold-/Paketvergabe.
[Konkrete Akzeptanzkriterien](CODEX_CHECKPOINT.md).

Die nachstehende Integrationschronik ist historisch und dokumentiert auch die
zwischenzeitlich laufenden/abgebrochenen Prüfungen. Aktuell gilt dieser Abschlussstand.

---

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

## Verifizierte Main-Artefakte und Bereinigung

Der tatsächlich heruntergeladene Main-Quellcheckpoint enthält **1.228 Dateien**;
alle SHA256-Werte und Dateimodi stimmen mit dem Manifest und dem Alpha-Quellpaket
überein. Der Binärpatch wurde tatsächlich gegen
`f9d68a97f35799e50881e9c6992efaed807e6301` angewendet und das Ergebnis vollständig verglichen.
Das History-Bundle wurde isoliert wiederhergestellt; `git fsck --full --strict`
und die Ancestry-Prüfung von **30 Ursprungs-/Integrations-/Main-Köpfen** sind erfolgreich.

| Datei | SHA256 |
| --- | --- |
| Main-Vollprojekt-ZIP | `912ca182f3bb24d77e599881288ca79ad5130bbe20682baa7b175a29f5b13196` |
| Main-Binärpatch | `5b83bb0d8f20d443bba56ae496f7530d966a80431b78d3a9bf46a95b37ca9099` |
| ARM64-Alpha-APK | `3f77e31663a154df9b5ff6e0549b7f4b050316101d44e93654c17457637c7c44` |

Die APK enthält ausschließlich `arm64-v8a`; die v2-Signatur mit Debug-Testschlüssel
ist geprüft. Dies ist keine produktive Signierung und kein realer Gerätetest.
[Cleanup-Lauf 40710914533](https://github.com/ManuEtt/Dnd/actions/runs/40710914533)
ist erfolgreich. Der Abschlussbeleg von `2026-10-28T14:59:26.197499+00:00` bestätigt
alle 28 alten Branches: Remote-Ref fehlt, Archivtag zeigt exakt auf den ursprünglichen
Kopf, Kopf ist Vorfahr des geprüften Main. Main und der neue aktive Hexenmeister-Branch
blieben erhalten. Dessen separat beobachteter Kopf ist `47cb207e99eeba0af3308de2b88c19f8357b0808`
([PR #352](https://github.com/ManuEtt/Dnd/pull/352)); vor weiterer Arbeit erneut live prüfen.

Dieser anschließende Dokumentationsabschluss hat die Projekt-/Importgrenzenprüfung,
195 Python-Tests und die unveränderte 1.419-/9-SRD-Inventur bestanden. Alle getrackten
Dateien unter `app/`, `backend/`, `scripts/` und `.github/` sind bytegleich mit
`6576d2fc742f000bacdd1c105282bc9e3282ae7e`. Es wurde keine neue APK für den Dokumentations-Commit erzeugt und keine
zusätzliche Produkt-CI daraus behauptet.
