# Integrationskandidat: 24 parallele Entwicklungspakete (29.10.2026)

**Status: ungetesteter Integrationskandidat, kein Produkt-Main-Merge.** Ursprung: `main` `a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`. Diese Datei ist eine wortgetreue Momentaufnahme der PR-Beschreibungen mit Referenzen; die Aussagen in einzelnen PRs über grüne Einzel-CI sind KEIN Nachweis für gemeinsame CI. Originale Branch-HEADs müssen als Eltern des späteren Integrationscommits im Git-Verlauf erhalten bleiben. Entwurfs-PRs werden nicht als fertig bezeichnet.

Die technischen Quell- und Testdateien aus jedem der 24 PRs wurden ohne dateipfadübergreifende Überschneidungen in einem Git-Baum zusammengetragen (47 Dateien). Die in den Einzelbranches konkurrierenden Änderungen an `README.md`, `docs/CODEX_CHECKPOINT.md` und den vier Chat-Checkpoints wurden nicht überschrieben, sondern über diesen integrierten Quellen-/Statusindex konsolidiert. Die unveränderten Originalstände bleiben über die Git-Elternhistorie und jeden verlinkten PR nachvollziehbar. Keine Datenmigration vorgesehen; reale CI auf dem Kandidaten steht aus.

**Noch nicht zur Freigabe bereit (zum Snapshot als Draft):** [#359](https://github.com/ManuEtt/Dnd/pull/359), [#365](https://github.com/ManuEtt/Dnd/pull/365), [#372](https://github.com/ManuEtt/Dnd/pull/372), [#374](https://github.com/ManuEtt/Dnd/pull/374), [#376](https://github.com/ManuEtt/Dnd/pull/376), [#379](https://github.com/ManuEtt/Dnd/pull/379), [#380](https://github.com/ManuEtt/Dnd/pull/380), [#382](https://github.com/ManuEtt/Dnd/pull/382), [#384](https://github.com/ManuEtt/Dnd/pull/384).

## Herkunft und ursprüngliche Entwicklungsberichte

### PR #356: fix(Chat B): NPC-Identität beim 2.400-Zeichen-Rückblick bewahren

- Quelle: [#356](https://github.com/ManuEtt/Dnd/pull/356)
- Original-Branch: `feat/chat-b/recap-npc-id-boundary-20261028`
- Original-HEAD: `3b584590a8aa433441476387b3871d1ac9d08d53`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> `MemoryEngine.buildSessionSummary` begrenzte den bestätigten Sitzungsrückblick auf 2.400 UTF-16-Codeeinheiten. Der globale Abschneidepunkt konnte mitten in einem Eintrag eines gleichnamigen NPCs liegen und seine eindeutige `(NPC-ID: ...)`-Kennung unvollständig entfernen. Eine unvollständige Identität darf nicht als bestätigte Erinnerung an den Erzähler gesendet werden.
> 
> ## Lösung (Chat B)
> - NPC-Liste bei Platzmangel nur mit vollständigen, unterscheidbaren Einträgen ausgeben. Wenn kein kompletter Eintrag passt, wird die NPC-Zeile ganz ausgelassen.
> - Vorherige Zeilen, frühere menschlich lesbare Formate bei ausreichend Platz und Unicode-sicheres Abschneiden sonstiger Rückblicktexte bleiben erhalten.
> - Kein Eingriff in Regelengine, zustandsverändernde KI-Vorschläge, Backend, SQLite, Spielstand-JSON oder Domainmodelle.
> 
> ## Akzeptanz / Regression
> - Bei knappem Restbudget wird der erste vollständige NPC inklusive ID übernommen; ein folgender NPC erscheint nicht abgeschnitten.
> - Bei zu wenig Platz wird kein unvollständiger NPC-Hinweis ausgegeben.
> - Bestehende Tests für eindeutige Namen, beschädigte doppelte IDs und Altspielstände bleiben vorhanden.
> - Expliziter `GameEngine.saveSessionRecap`- und JSON-Roundtrip sowie Heldenunveränderlichkeit im positiven Grenztest.
> 
> ## Verifikation
> - GitHub-Quellstand und offene PR-Dateipfade geprüft; lokale SDK-Verfügbarkeit kontrolliert.
> - **Nicht lokal ausführbar:** Flutter/Dart/Android und vollständiges Python-/Backend-Repo; GitHub-DNS in dieser Laufzeit nicht erreichbar. Keine durchgeführten Testläufe behauptet.
> - CI wird auf finalem PR-HEAD geprüft und bei Befund im selben Branch repariert.
> - Basis-Main: `ab8bef62039a2c4df04ee0cbecf0baebfefc8d78`; Fachcommit: `2e395b0dcfdbcb287b3fafb1dfb56b601fee822f`.
> - Parallel-PRs #353 (Regelwerk) und #355 (Android-UI) ändern keine dieser beiden Dart-Dateien.
> 
> ## Kompatibilität
> Keine Migration, unverändertes SQLite3 / Kampagnen-JSON1, unveränderte App-Version. Vor Integration Dokumentationsüberschneidungen mit anderen PRs konsolidieren.
> 
> ## Finale CI-Abnahme – 28.10.2026
> **Bestanden auf exakt `3b584590a8aa433441476387b3871d1ac9d08d53`:** [GitHub Actions PR-Lauf #40716423391](https://github.com/ManuEtt/Dnd/actions/runs/40716423391), Ergebnis `success`.
> Bestanden: Projekt-/Python-Strukturtests, Domänengrenzen, SRD-Audit, Backend-`typecheck`/`build`/`test`, Dart-Format, Flutter-Analyse, gezielte Widgettests, vollständige Flutter-Tests, Android-Debug-APK, native Dateisicherung, ARM-Alpha-APKs sowie Artefakt-/Quellcode-Checkpoint.
> Der anfängliche Formatierungsfehler wurde durch den offiziellen Dart-Formatter-Diff korrigiert und die temporäre Diagnose-Action wieder entfernt. **Nicht getestet:** Realgerät, Produktivsignatur und kostenpflichtige KI-Provider.
> **Aktueller Konfliktcheck:** `main` unverändert auf `ab8bef62039a2c4df04ee0cbecf0baebfefc8d78`; keine Überschneidung der Fachdateien mit #353, #355, #357, #358 oder #359. Gemeinsame README-/Checkpoint-Ergänzungen mit #357–#359 vor der Integration durch Chat D additiv konsolidieren.
> 

---

### PR #357: feat(Chat A): validate Cube spell origin before area preview (SRD 5.2.1)

- Quelle: [#357](https://github.com/ManuEtt/Dnd/pull/357)
- Original-Branch: `feat/chat-a/cube-spell-origin-20261028`
- Original-HEAD: `90a3b40d9b2be9f66e0e3e93938e802ff4a9d0ac`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Anlass / Requirement
> `RULE-SPELLS-SPELL-AREAS-OF-EFFECT` bleibt **partial**. Für die bisher nur geometrische `SrdCubeAreaRules.preview`-Vorschau fehlte im Unterschied zu den anderen SRD-Bereichsformen ein gegen den Zauberkatalog validierter Einstieg.
> 
> **Quelle:** SRD 5.2.1, *Rules Glossary / Cube*, *Spells / Thunderwave* (S. 169), Wizards of the Coast LLC, CC BY 4.0: https://www.dndbeyond.com/srd
> 
> ## Implementiert
> - Neuer read-only `SrdCubeAreaRules.previewConfirmedSpell` verlangt eine separat bestätigte Würfelform/Dimension und ruft **vor** dem unveränderten geometrischen `preview` die bestehende `SrdSpellGridTargetRules.validateOrigin` auf.
> - Bei Reichweite `Self` wird ein fremder Würfelursprung zurückgewiesen; unbekannte/voll blockierte Karten bleiben gesperrt.
> - Bestehende API, Kampagnen-JSON, SQLite, Regelressourcen und Story-Zustand unverändert; keine Migration.
> 
> ## Regressionen / Akzeptanz
> `app/test/srd_cube_area_rules_test.dart` ergänzt:
> - 15-ft-Cube von `Thunderwave` mit bestätigtem Wirkerursprung (positive geometrische Kandidaten)
> - Ablehnung unbestätigter Form/Ausrichtung, ungültiger Kantenlänge, fremdem Self-Ursprung, unbekannter Hinderniskarte, blockiertem und Off-grid-Ursprung
> - Unveränderbarkeit der Vorschau
> 
> **Keine vollständige Thunderwave-/3D-Wirkung**: keine Schadenswürfe, Rettungswürfe, Zielautomatiken oder Ressourcenbuchung.
> 
> ## Testnachweis (zu aktualisieren nach CI)
> - Quellcode und geänderte PR-Dateien live kontrolliert.
> - Flutter/Dart lokal nicht installiert, Tests/Analyzer/Build lokal **nicht ausführbar**.
> - GitHub-Actions-Status für finalen PR-HEAD noch **ausstehend**, nicht als Erfolg ausgegeben.
> - Python-/Backend-Gesamtsuite und realer Android-Gerätetest für diesen Branch **nicht ausgeführt**.
> 
> ## Parallelitätsprüfung
> Startbasis main `ab8bef62039a2c4df04ee0cbecf0baebfefc8d78`. Der offene PR #353 (Chat A, Sorcerous Restoration) und PR #355 (Chat C, Inventar-Scrollen) bearbeiten **keine** der hier veränderten Dateien. Zentrales Requirements-JSON bewusst nicht verändert, da #353 es berührt. [Chat-A-Checkpoint](https://github.com/ManuEtt/Dnd/blob/feat/chat-a/cube-spell-origin-20261028/docs/parallel/CHAT_A_CHECKPOINT.md).
> 
> ## Koordination – aktualisierte PR-Lage am 28.10.2026
> Nach Erstellung von #357 wurden zusätzlich #356 (Chat B) und #358 (Chat D) eröffnet. **Keine Laufzeit- oder Testdateien überschneiden sich.** #356 und #358 ändern jedoch ebenfalls `README.md` und `docs/CODEX_CHECKPOINT.md`: Diese beiden historischen Fortschrittstexte müssen vor der Integration durch Chat D ohne Verlust vorhandener Einträge zusammengeführt werden. #357 nimmt keine fremde Branchänderung vor. Die `app/lib/domain/srd_cube_area_rules.dart` und `app/test/srd_cube_area_rules_test.dart` bleiben konfliktfreie eigene Chat-A-Module.
> 
> ## CI-Regression und Korrektur
> Erster vollständiger Prüfversuch [#40715887654](https://github.com/ManuEtt/Dnd/actions/runs/40715887654): **2.197 Flutter-Tests bestanden, 2 fehlgeschlagen**. Beide neuen Cube-Tests luden Assets über `SrdSpellCatalogLoader.load()` vor Initialisierung der Test-Bindings (`ServicesBinding.instance`). Der Fehler ist auf den neuen Testaufbau begrenzt; die vorherigen Format-/Analyse-, Python- und Backend-Gates waren grün. **Korrektur** auf Commit `90a3b40d9b2be9f66e0e3e93938e802ff4a9d0ac`: `TestWidgetsFlutterBinding.ensureInitialized()` am Beginn von `main()`, analog zu den vorhandenen Zauberkatalogtests. Neuer CI-Lauf [#40717093590](https://github.com/ManuEtt/Dnd/actions/runs/40717093590) gestartet; der letzte beobachtete Status war `queued`. Eine vollständige grüne Folge-CI wird nicht vorweggenommen.
> 

---

### PR #359: test(Chat C): Tastaturfokus der fixierten Schnellaktionen bei Android-IME absichern

- Quelle: [#359](https://github.com/ManuEtt/Dnd/pull/359)
- Original-Branch: `feat/chat-c/shortcut-keyboard-focus-20261028`
- Original-HEAD: `c0e885862612f4af743b7cd78a112a4910a5061d`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangslage
> Die vorhandenen Tests der unteren Abenteuer-Schnellaktionen bestätigen Touch-Interaktion und Sichtbarkeit bei 320–400 dp. Sie prüfen aber nicht den **Tastaturfokus und Enter-Auslösung** bei gleichzeitig simulierter Bildschirmtastatur und 2x Systemschrift.
> 
> ## Scope und Akzeptanz
> - Zwei zusätzliche Widgettests in `app/test/fantasy_pinned_actions_test.dart`, bei 320×800 dp, 270 dp IME-Inset und TextScaler 2.0.
> - Tab-Fokus in Reihenfolge Sprache → Untersuchen → Angriff → W20, nachfolgend Enter löst genau die entsprechende Aktion aus.
> - Bei `attackEnabled: false` meldet die Attack-Semantik deaktiviert, der Fokus überspringt Angriff und dessen Callback bleibt unberührt.
> - Keine Änderung an produktivem UI-Code, Regelengine, Story, SQLite, JSON, Version oder Backend.
> 
> ## Koordination
> Basis-main `ab8bef62039a2c4df04ee0cbecf0baebfefc8d78`, Code-Commit `8f892d7df902ec8805ec6d535ecdd49e22670a58`. PR #355 bearbeitet `app/lib/ui/fantasy_art.dart` und einen anderen Test; es gibt **keine Code-/Testdateiüberschneidung**. PRs #353, #356, #357 und #358 ebenfalls ohne Codekonflikt. Die begleitenden gemeinsamen `README.md` und `docs/CODEX_CHECKPOINT.md` müssen bei der Integration durch Chat D zusammengeführt werden.
> 
> ## Tests und Qualität
> Die neue CI muss zunächst die Flutter-Tests tatsächlich ausführen und ggf. einen nachweisbaren Fokusfehler aufdecken; bisher sind **keine neuen Testläufe bestanden**. Prüfschritte: Dart-Format, Flutter-Analyse, gezielter Widgettest, vollständige Tests, Android-Debug-/Alpha-APK und native Android-Tests. Die native Geräte-/TalkBack-Abnahme bleibt separat.
> 
> Checkpoint: `docs/parallel/CHAT_C_CHECKPOINT.md`.
> 
> ## Nachgezogener Hauptbranch / Konfliktprüfung
> 
> PR #355 (scrollbarer Inventardialog) wurde inzwischen erfolgreich in `main` integriert, Commit `854ca85c0234c508f34f00cdbfbef2e10554ca13`. Der eigene Branch wurde im regulären, nicht-forcierten Zweieltern-Merge `c0e885862612f4af743b7cd78a112a4910a5061d` synchronisiert: bestehende UI-/Inventaränderungen sowie beide zugehörigen README-/Checkpoint-Abschnitte bleiben erhalten. Der neue Test bleibt auf `app/test/fantasy_pinned_actions_test.dart` begrenzt; der temporäre Formatter-Workflow wurde vollständig entfernt.
> 
> Die erste CI erreichte wegen Dart-Formatierung keine Fluttertests. Ein isolierter Flutter/Dart-Formatterlauf [#40719636423](https://github.com/ManuEtt/Dnd/actions/runs/40719636423) zeigte den exakten Diff, der übernommen wurde. Finale CI auf dem neuen Merge-HEAD: [#40720229897](https://github.com/ManuEtt/Dnd/actions/runs/40720229897) (bei Abschluss verifizieren).

---

### PR #361: feat(Chat A): SRD 5.2.1 Cylinder footprint with explicit height and origin face

- Quelle: [#361](https://github.com/ManuEtt/Dnd/pull/361)
- Original-Branch: `feat/chat-a/cylinder-area-preview-20261028`
- Original-HEAD: `57288e6245aac84885137ca026abb583aec4d04c`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> Für die SRD-5.2.1-Wirkungsform **Cylinder** gibt es bislang keine dedizierte Domain-Vorschau. Ein Zauber mit Zylinderwirkung darf weder als Kugel mit falscher Höhe noch als verifizierter Treffer gewertet werden. Das offene Cube-Paket #357 und andere Chat-PRs werden nicht verändert.
> 
> ## Definition of Done / Akzeptanz
> - [x] Separate, lesende `SrdCylinderAreaRules` ohne UI, Speicher- oder Storyzustandsänderung.
> - [x] Radius und Höhe als unabhängig bestätigte Maße, Top-/Bottom-Ursprungsfläche explizit; vertikale Offsets relativ zum Ursprung statt erfundener Höhe.
> - [x] Konservative horizontale Rand-/Mittelpunkt-Kandidaten; Blocker bedeuten weitere Deckungsprüfung, nicht automatische Immunität.
> - [x] `previewConfirmedSpell` erfordert bestätigte Effektform und kontrolliert die Zauberreichweite zum Ursprung über vorhandene Domainregeln.
> - [x] Negative Tests für unbekannte Karte, blockierten/ungültigen Ursprung, nicht bestätigte Geometrie, nicht unterstützte Maße, versperrten Pfad und überhöhte Distanz.
> - [x] Testbinding vor Laden von SRD-Assets initialisiert (Regression #357).
> - [ ] Vollständige CI auf finalem Branch erfolgreich.
> 
> ## Dateien
> - `app/lib/domain/srd_cylinder_area_rules.dart` – eigenständige, konservative Vorschau; nutzt bestehende Kreisüberschneidung und center-ray-Prüfung
> - `app/test/srd_cylinder_area_rules_test.dart` – Deterministik, Ursprungsfläche, Randfelder, Blocker, Flame Strike-Reichweite
> - Eigener Chat-A-Checkpoint, zentraler Checkpoint und README sind ergänzt.
> 
> ## Umfang und Grenzen
> **Keine** automatische betroffene Kreatur, 3D-Sicht/Deckung, absolute Z-Koordinate, Höhe einer Figur, Schadenswürfe, Slot-/Ressourcenbuchung oder Kampagnenmutation. Unterstützte Maße sind appseitig begrenzt (Radius 5–120, Höhe 5–300 Fuß in 5-Fuß-Schritten). Keine Migration; keine JSON-/SQLite-Schemaänderung. Arbeits-ID `RULE-SPELLS-SPELL-AREAS-OF-EFFECT` bleibt **partial**.
> 
> **SRD-Provenienz:** Wizards of the Coast LLC, SRD 5.2.1, *Rules Glossary / Cylinder*, CC BY 4.0, https://www.dndbeyond.com/srd ; *Flame Strike* aus dem bestehenden Zauberkatalog.
> 
> ## Koordination
> Ursprüngliche Base `main` = `ab8bef62039a2c4df04ee0cbecf0baebfefc8d78`. Neue `main`-Commits bis `854ca85c0234c508f34f00cdbfbef2e10554ca13` wurden mit einem **nicht-erzwungenen Merge-Commit** `0a8990f4d284f2db2d06fd600df7be17e44a54b9` einbezogen. Dokumentation wurde unter Erhalt der Chat-C-Ergänzungen manuell vereinigt. Open-PR-Sichtung #353/#355/#356/#357/#358: neue Domain- und Testdateien sind unabhängig. **README und docs/CODEX_CHECKPOINT.md überschneiden sich dokumentarisch** mit Chat B/C/D/#357; Chat D konsolidiert vor Merge. Kein automatischer Merge.
> 
> ## Prüfstand
> Lokal fehlt Dart/Flutter; CI ist die ausführbare Dart-/Android-Abnahme. Referenz: älterer Chat-A-Cube-PR #357, CI #40717093590 erfolgreich, jedoch **nicht** Testbeleg dieses neuen Zylinder-Branches. Die ursprünglichen CI-Versuche scheiterten ausschließlich am Dart-Format der neuen Testdatei. Mit einem danach wieder entfernten temporären Diagnose-Workflow wurde die exakte Dart-3.9.2-Ausgabe ermittelt und übernommen. Regel-/Testquellcode zuletzt `12ef202f144b7183360328624afd513a289d11b7`; finaler HEAD nach Entfernen des Diagnose-Workflows: `57288e6245aac84885137ca026abb583aec4d04c`. **Finale Android-CI [#40720953868](https://github.com/ManuEtt/Dnd/actions/runs/40720953868): Projekt-, Domänengrenzen-, SRD-Registry-, Python-/Backend-Prüfungen, Dart-Formatierung, Flutter-Analyse, gezielte UI-Tests und vollständiges Flutter-Testset erfolgreich. Android-Debug-APK ist noch im Build; native Tests und Alpha-APKs bisher nicht abschließend bestätigt.**
> 

---

### PR #362: fix(Chat B): Lange NPC-Namen im Erzähler-Gedächtnis eindeutig halten

- Quelle: [#362](https://github.com/ManuEtt/Dnd/pull/362)
- Original-Branch: `feat/chat-b/npc-narrator-long-name-id-20261028`
- Original-HEAD: `d10f8cea07b416f7bfbcebb259615e8a45f7e32b`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> `NpcNarratorMemory.merge` kürzt bestätigte NPC-Notizen auf 400 UTF-16-Codeeinheiten. Ein sehr langer, aber in einer bestehenden Kampagne eindeutig gespeicherter NPC-Anzeigename kann dabei mitten im Namen abgeschnitten werden; ein zweiter NPC mit demselben Namenspräfix wäre im an den Erzähler gesendeten Gedächtnis nicht mehr eindeutig zu unterscheiden.
> 
> ## Lösung
> - Bei normal langen Anzeigenamen unverändertes bisheriges Erzählerformat.
> - Wenn der vollständige Name samt Beziehungsmetadaten nicht ins 400er-Budget passt, wird eine **nur aus eindeutig gespeicherter und syntaktisch gültiger NPC-ID** gebildete Kennung verwendet.
> - Kann auch der Ersatzkopf nicht vollständig geschrieben werden, wird der NPC-spezifische Eintrag verworfen (fail closed), statt ein uneindeutiges Namensfragment als bestätigt zu senden.
> - Ungültige Einträge verbrauchen nicht vorzeitig die `npcNoteLimit`-Quote: verbleibende gültige Notizen werden berücksichtigt.
> - Unverändert: Freitext darf keinen gleichnamigen NPC erraten; keine KI-/Regelautorität; bestehendes Limit 400 pro Eintrag / 12 standardmäßig gesamt.
> 
> ## Regression
> Vier neue Tests: zwei eindeutige lange Namen mit fast gleichem Präfix über Kampagnen-JSON-Roundtrip; ungültige ID und erfolgreiche Quoten-Nachfüllung; identische lange Namen bleiben mehrdeutig; kurze Namen und `npcNoteLimit: 0` bleiben kompatibel. Heldendaten und gespeicherte Kampagne unverändert.
> 
> ## Abgrenzung
> Nur `app/lib/story/npc_narrator_memory.dart` und `app/test/npc_narrator_memory_long_name_test.dart` als Fachdateien. Insbesondere **keine Änderung** an `story_memory_engine.dart` im offenen Chat-B-PR #356. Andere offene PRs: #357–#361 getrennte Fachdateien. Dokumentationskonflikte in README/zentralem Checkpoint bei Integration durch Chat D additiv konsolidieren.
> 
> **Basis:** `854ca85c0234c508f34f00cdbfbef2e10554ca13`. **Implementierung:** `a6415893a9fc84c6df1bb0872fc2eebd2ee72204`.
> Keine Migration (SQLite3/Kampagnen-JSON1 unverändert). Lokales Flutter-/Dart-SDK fehlt; keine lokalen Test- oder APK-Erfolge behauptet. CI-Gates auf finalem HEAD abzunehmen.
> 
> ## Endabnahme 28.10.2026 – finaler HEAD
> - **Commit:** `d10f8cea07b416f7bfbcebb259615e8a45f7e32b` (alle Fachdateien und Dokumentationen); Basismain `854ca85c0234c508f34f00cdbfbef2e10554ca13`.
> - **PR-CI:** [Actions #40720810625](https://github.com/ManuEtt/Dnd/actions/runs/40720810625) – **completed/success**.
> - **Push-CI:** [Actions #40720798115](https://github.com/ManuEtt/Dnd/actions/runs/40720798115) – **completed/success**.
> - Beide vollständigen Läufe am exakt selben SHA: Projektstruktur, Python-Projekt-/Grenztests, SRD-Audit, Backend Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse, gezielte Flutter-Widgettests, gesamte Flutter-Testsuite inklusive vier neuer NPC-Fälle, Android-Debug-Build, native Tests, ARM-Alpha-APKs und Artefakt-/Quell-Checkpoint erfolgreich.
> - Der anfängliche Format-/Textersetzungsfehler wurde im eigenen Branch korrigiert; der temporäre Diagnoseworkflow vollständig entfernt. Finale Diff-Liste: genau fünf erwartete Dateien.
> - **NICHT GETESTET:** echtes Android-Gerät, produktive KI-Provider, Produktivsignatur. **Keine Migration:** SQLite3/JSON1 und bestätigte Helden-/SRD-Zustände unverändert.
> - **Konfliktprüfung:** `main` bei Reviewfreigabe weiter `854ca85c`, GitHub meldet `mergeable=true`. Keine Fachcode-Pfadüberschneidung mit offenen PRs #356–#361 und #363. Gemeinsame `README.md`/`docs/CODEX_CHECKPOINT.md`-Nachträge der anderen Chats beim Merge durch Chat D additiv konsolidieren; keine fremden Änderungen überschreiben.
> 

---

### PR #364: fix(Chat B): Gleichnamige NPCs im Kontinuitätsprotokoll eindeutig ausweisen

- Quelle: [#364](https://github.com/ManuEtt/Dnd/pull/364)
- Original-Branch: `feat/chat-b/npc-continuity-disambiguation-20261028`
- Original-HEAD: `3cd4d53546c6941eec09c9626baac02e3a0fadea`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> `NpcContinuityReader.read(campaign, npcId: ...)` liest bestätigt und per ID, aber `NpcContinuitySnapshot.confirmedContext` veröffentlichte nur `NPC: <Name>`. Bei zwei gleichnamigen Figuren sind dadurch gespeicherte Einzelprotokolle im Erzähltext ohne sichere Identität unterscheidbar.
> 
> ## Umsetzung
> - Normalisierte Namen (Umlaute, ß, Groß-/Kleinschreibung und Leerzeichen) aller gespeicherten NPCs vergleichen.
> - Bei eindeutigem Anzeigenamen **exaktes historisches Textformat** beibehalten.
> - Nur bei mehreren gleichen Anzeigenamen `NPC: <Name> (NPC-ID: <gespeicherte ID>)` ausgeben; niemals eine ID aus frei erfundenem Dialog erraten.
> - Ungültige IDs im identitätskritischen Fall werden abgewiesen, anstatt eine mehrdeutige oder unsichere Kennung in den Text einzufügen.
> - Gleicher Notizfilter, Zeitordnungsregel, Limit und unveränderlicher Snapshot wie bisher.
> 
> ## Akzeptanz und Regression
> Vier neue Flutter-Tests für zwei gespeicherte gleiche Miras mit unterschiedlichen Notizen über Kampagnen-JSON-Roundtrip und unverändertem Heldenzustand, normalisierte deutsche Namensgleichheit, ungeeignete/doppelte IDs und historischen Kontext ohne optionale Beziehungshistorie. Keine Änderung am SQLite- oder Kampagnen-JSON-Schema, an Regeln, Questbelohnungen oder KI-Providerverträgen.
> 
> **Branch:** `feat/chat-b/npc-continuity-disambiguation-20261028`; **Basis:** `f5cb518a0c0a6aafc1b1483c833fb7907ca5e882`; **Erster Codecommit:** `5f4e957790d67646b94f913ed3ade54253f1c5d2`.
> 
> **Kollisionsprüfung:** Kein Fachdateikonflikt mit offenen Chat-B-PRs #356/#362 und übrigen PRs #357/#358/#359/#361/#363. Gemeinsame README-/Checkpoint-Abschnitte nur additiv durch Chat D zusammenführen.
> 
> **CI:** Nach Dokumentationscommit auf finalem Head auswerten. Lokales Flutter/Dart fehlt; keine lokalen Test-/APK-Erfolge behauptet. **Kein automatischer Merge.**
> 
> ## Endabnahme – Commit `3cd4d53546c6941eec09c9626baac02e3a0fadea`
> - [Push-CI #40741043013](https://github.com/ManuEtt/Dnd/actions/runs/40741043013): **completed/success** auf exakt diesem Commit, einschließlich Python-/Projekt-/Modulgrenzen, SRD-Prüfung, Backend Typecheck/Build/Tests, Dart-Format, Flutter-Analyse, gezielten UI-Tests, **vollständiger Flutter-Testsuite mit vier neuen Kontinuitätsfällen**, Android-Debug-APK, nativen Tests, kleineren Alpha-APKs und Artefakt-/Quellcodebereitstellung.
> - [PR-CI #40741055290](https://github.com/ManuEtt/Dnd/actions/runs/40741055290): zum Zeitpunkt dieser Dokumentation läuft der unabhängige Zweitlauf noch; seine Android-Abnahme ist nicht als bestanden behauptet. Der vollständige grüne Push-CI-Lauf genügt für die fachliche Reviewfreigabe.
> - Der erste Formatfehler wurde anhand des offiziellen Dart-3.9.2-Formatters korrigiert; der temporäre Diagnoseworkflow ist vollständig entfernt. Final genau fünf Dateien.
> - **Nicht getestet:** echtes Android-Gerät, produktiver KI-Provider, Produktivsignatur.
> - **Keine Daten-/SRD-Migration:** SQLite3/Kampagnen-JSON1 unverändert; keine automatische Änderung bestätigter Regelzustände.
> - **Konfliktcheck:** `main` weiterhin `f5cb518a0c0a6aafc1b1483c833fb7907ca5e882`, `mergeable=true`; offene PRs #356–#363 und #365/#366 ändern keine identischen Fachdateien. Gemeinsame README/CODEX-Nachträge durch Chat D additiv konsolidieren.
> 

---

### PR #365: fix(Chat C): weitere erledigte Quests im Abenteuer-HUD kennzeichnen

- Quelle: [#365](https://github.com/ManuEtt/Dnd/pull/365)
- Original-Branch: `feat/chat-c/quest-board-overflow-hint-20261028`
- Original-HEAD: `e08ab0cc3f206c6e3fceeeee3c2870b5b942a184`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> Im `FantasyAdventureQuestBoard` zeigt der Zähler alle abgeschlossenen/gescheiterten Aufträge, die kompakte Liste aber nur `resolved.take(3)`. Ab dem vierten erledigten Auftrag ist nicht erkennbar, dass weitere Einträge bewusst nur über das Tagebuch zugänglich sind.
> 
> ## Lösung
> - Direkter, lesbarer Hinweis nach den ersten drei Questzeilen: „Ein weiterer Auftrag im Tagebuch“ bzw. „N weitere Aufträge im Tagebuch“.
> - Nur anzeigen, wenn die tatsächliche Liste mehr als drei erledigte/gescheiterte Quests enthält; kein erfundener Inhalt.
> - Vorhandene Tagebuch-Aktion bleibt unverändert; Questdaten werden nicht geschrieben oder sortiert.
> - Neue Flutter-Widgettests in `app/test/fantasy_quest_board_hidden_test.dart` für 3, 4 und 5 erledigte Aufträge, 320 dp bei 200 % Schrift, Tagebuch-Callback und unveränderte ID-/Statusreihenfolge.
> 
> ## Konventionen & Koordination
> Basis-main `f5cb518a0c0a6aafc1b1483c833fb7907ca5e882`. Geänderte UI-Produktionsdatei: `app/lib/ui/fantasy_adventure_hud.dart`. Offene PRs #356, #357, #358, #359, #361, #362, #363 besitzen keine Überschneidung mit den beiden Flutter-Code-/Testdateien. **Gemeinsame Dateien** `README.md`, `docs/CODEX_CHECKPOINT.md` müssen vor dem Merge mit den parallelen Chats additiv konsolidiert werden.
> 
> ## Qualitätsgates
> **Noch ausstehend**: Dart-Format, Flutter Analyze, gesamtes `flutter test`, Backend-/Python-Tests, nativer Android-Test, Debug- und Alpha-APK via GitHub Actions. Erst nach belegtem Erfolg reviewbereit. Keine SQLite-/JSON-/Domain-/Story-/SRD-Regeländerungen; keine Migration, keine App-Versionserhöhung.
> 
> Fortschritt: `docs/parallel/CHAT_C_CHECKPOINT.md`.
> 

---

### PR #366: feat(Chat A): SRD 5.2.1 Emanation origin, motion and conservative grid preview

- Quelle: [#366](https://github.com/ManuEtt/Dnd/pull/366)
- Original-Branch: `feat/chat-a/emanation-area-preview-20261028`
- Original-HEAD: `56e00c7433b28c30384b0661b0fb13e0e704787e`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ziel / Regelumfang (Chat A)
> SRD 5.2.1 *Rules Glossary / Emanation*: Eine Emanation geht von einer Kreatur oder einem Gegenstand aus, folgt der Quelle (außer bei sofortigen bzw. stationären Effekten) und schließt die Quelle standardmäßig nicht ein. Die Regeln brauchen dafür eine von Kugel-/Zylinder-Vorschauen getrennte, **lesende** Vorprüfung, bevor spätere Wirkungen entscheiden. Die SRD-Zauberreichweite ist nicht die Ausdehnung der Emanation.
> 
> **Quellen/Lizenz:** Wizards of the Coast LLC, SRD 5.2.1, *Rules Glossary / Emanation* und *Spirit Guardians*, CC BY 4.0, https://www.dndbeyond.com/srd.
> 
> ## Implementiert
> - Neue Domain-Datei `app/lib/domain/srd_emanation_area_rules.dart` mit `SrdEmanationAreaRules.preview` und `previewConfirmedSpell`.
> - Explizite `SrdEmanationSourceKind.creature/object`, `SrdEmanationMotion.followsSource/instantaneous/stationary`, `includeSourceByChoice` (false als SRD-Default), Hinweis auf notwendigen Repreview nach Bewegung.
> - Einzelfeld-Quellpunkt und vollständige Blocker-Karte müssen bestätigt sein; unbekannte Geometrie wird abgelehnt.
> - Übernimmt ausschließlich die konservative Kreisüberschneidung und den Mittelpunktstrahl aus `SrdSphereAreaRules`, **nicht** Hit-/Deckungs-/Zielentscheidungen. Das Ursprungsfeld bleibt als Kandidat für *andere* dort befindliche Ziele sichtbar, auch wenn die Quelle selbst ausgeschlossen ist.
> - `previewConfirmedSpell` fordert separat bestätigte Emanationsform/Ausdehnung und validiert die SRD-Zauberreichweite zum Ursprung.
> 
> ## Akzeptanz / Tests
> - [x] `app/test/srd_emanation_area_rules_test.dart`: sechs reproduzierbare positive/negative Tests zu Geometrie/Randzellen, Quellenopt-in, Bewegungsdaten, Hindernisprüfbedarf, ungültigen Karten/Ursprüngen/Dimensionen sowie `Spirit Guardians`-Selbstursprung.
> - [x] Keine App-/Backend-/UI-/Story-, JSON-, SQLite- oder Ressourcenänderung; keine Migration.
> - [ ] CI auf finalem Commit vollständig erfolgreich. Lokales Dart-/Flutter-SDK nicht verfügbar; GitHub Actions übernimmt die Ausführung.
> - [ ] Kein echter Android-Gerätetest (separates Abnahmethema).
> 
> **Noch nicht modelliert:** große/multizelluläre Quellen, exakte 3D-Höhen, Total Cover, Kreaturpositionen, Bewegungsevents, Zaubereffekt/Schaden/Rettungswürfe/ausgenommene Ziele. Requirement `RULE-SPELLS-SPELL-AREAS-OF-EFFECT` bleibt `partial`.
> 
> ## GitHub-/Integrationskoordination
> Main-Basis `f5cb518a0c0a6aafc1b1483c833fb7907ca5e882`. Code- und Testdateien überschneiden sich nicht mit den offenen Arbeiten der Chats B/C/D oder #357/#361. `README.md` und `docs/CODEX_CHECKPOINT.md` sind gemeinsame Dokumentationsdateien; Chat D soll die Einträge vor Merge zusammenführen, nicht überschreiben. `docs/parallel/CHAT_A_CHECKPOINT.md` aktualisiert. **Kein automatischer Merge.**
> 
> ## CI-Nachtrag (28.10.2026)
> Der erste Branch-CI-Lauf [#40740757358](https://github.com/ManuEtt/Dnd/actions/runs/40740757358) hat Python-/Backend- und Strukturprüfungen bestanden, aber **an einer Dart-Formatabweichung der neuen Testdatei gestoppt**; Flutter-/Android-Tests waren dort nicht erreicht. Der temporäre Formatter-Diagnose-Lauf [#40741010556](https://github.com/ManuEtt/Dnd/actions/runs/40741010556) wurde erfolgreich zur Ermittlung des exakten Dart-3.9-Formatdiffs verwendet; die Korrektur ist Commit `e96a9563c0c4d02684331023a13a4eff5858a7fc`. Der Diagnose-Workflow wurde im folgenden Commit wieder gelöscht. Finaler Arbeitsstand `56e00c7433b28c30384b0661b0fb13e0e704787e`; **neuer CI-Lauf [#40741267835](https://github.com/ManuEtt/Dnd/actions/runs/40741267835)** gestartet, vollständige Erfolgsbehauptung erst nach Abschluss.
> 
> 
> ## Nachweis auf finalem HEAD
> Bis zur letzten aktiven Abfrage ist [CI #40741267835](https://github.com/ManuEtt/Dnd/actions/runs/40741267835) auf Code-/Dokumentations-HEAD `56e00c7433b28c30384b0661b0fb13e0e704787e` in Ausführung: **Projektstruktur, SRD-Anforderungsregister, Domain-/Storygrenzen, Python, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse, gezielte Dialogtests, die vollständige Flutter-Testsuite, Android-Debug-APK und native Backup-Tests bestanden**. Noch offen: **kleine Alpha-APKs**, finale Artefaktbereitstellung und der vollständige Workflow-Abschluss. Keine Gerätetests. PR bleibt Entwurf bis zur nachgewiesenen grünen Endabnahme; keine automatische Integration.
> 
> 
> ## Abschließende Abnahme
> **Erfolgreich:** [GitHub Actions #40741267835](https://github.com/ManuEtt/Dnd/actions/runs/40741267835) auf HEAD `56e00c7433b28c30384b0661b0fb13e0e704787e`, `completed/success`. Damit sind auch die kleinen Alpha-APKs, Debug-APK, nativen Tests, vollständigen Flutter-Tests, Dart-Formatierung, Flutter-Analyse, Python-/Backend-Tests und Buildartefaktbereitstellung bestanden. Keine Geräteinstallation oder vollständige SRD-Regelautomatik daraus ableiten. **PR bereit für das koordinierte Review; kein automatischer Merge.**
> 

---

### PR #367: feat(Chat A): SRD 5.2.1 Wall of Fire ring footprint preflight

- Quelle: [#367](https://github.com/ManuEtt/Dnd/pull/367)
- Original-Branch: `feat/chat-a/wall-of-fire-ring-preview-20261028`
- Original-HEAD: `444b282a56613b20b68e03006b7010200e364c82`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> Der 339 Einträge umfassende SRD-5.2.1-Zauberkatalog kennt `Wall of Fire` (4. Grad, Reichweite 120 Fuß), kennzeichnet die mechanische Wirkung jedoch als **nicht implementiert**. Eine sicher abgeschirmte Vorschau für die ausdrücklich wählbare Ringform (max. 20 Fuß Außendurchmesser, max. 20 Fuß Höhe, 1 Fuß Wanddicke) fehlt.
> 
> ## Akzeptanz / umgesetzt
> - [x] Neue isolierte, zustandslose Regel-Domainklasse `SrdWallOfFireRingRules` mit konservativer 2D-Ringflächen-Kandidatenliste.
> - [x] Äußerer Durchmesser und Höhe nur 5-Fuß-Schritte bis 20 Fuß; Wandstärke 1 Fuß. Die **Außendurchmesser-Konvention** wird vom Aufrufer ausdrücklich bestätigt, nicht geraten.
> - [x] Ringmittelpunkt der 5-Fuß-Zelle ist explizit; leeres Ringinneres und potentielle Rand-/Ecküberschneidungen sind unterscheidbar.
> - [x] Opaque Hindernisfelder werden als gesonderter Prüfbedarf markiert, nicht blind verworfen oder als gültige Treffer deklariert. Blockierte Center-Rays erfordern Deckungsprüfung.
> - [x] `previewConfirmedSpell` überprüft Wall-of-Fire-Metadaten, bestätigte Ringform, Außendurchmesser-Annahme und feste Oberfläche sowie vorhandene Zauberursprungsreichweite (120 Fuß).
> - [x] Fünf deterministische Tests für Ringgeometrie, Karte, Blocker, fehlende Fakten/ungültige Maße und SRD-Spell-Reichweite inklusive Grenzwert und Gegenbeispiele.
> - [ ] Vollständige CI/Android-Abnahme auf finalem PR-Head (noch nicht erfolgt).
> 
> ## Scope / Spielstand-Kompatibilität
> **Keine** Schadensanwendung (5W8), Zielauswahl, Rettungswürfe, Wahl der heißen Wandseite, Konzentration, absoluter Höhenraum, bewegte Kreaturen oder Zustandsänderungen. Kein UI-, Controller-, Story-, Backend-, SQLite-/JSON-/Migrations- oder Versionswechsel. SRD-Arbeits-ID `SPELL-ENTRY-WALL-OF-FIRE` bleibt im maschinenlesbaren Register **unverified** (reine Vorprüfung ist keine komplette Regelwirkung), keine vollständige Zauberautomatik.
> 
> ## Änderungen
> `app/lib/domain/srd_wall_of_fire_ring_rules.dart`, `app/test/srd_wall_of_fire_ring_rules_test.dart` sowie additive Projekt-/Chat-A-Checkpoints und README.
> 
> ## Provenienz
> Wizards of the Coast LLC, *System Reference Document 5.2.1*, **Spell Descriptions – Wall of Fire**, CC BY 4.0, https://www.dndbeyond.com/srd. Implementationshinweis: Der Spell-Catalog liefert aktuell **keine** geprüfte Wirkungsgeometrie, diese muss pro Vorschau explizit bestätigt werden.
> 
> ## Parallele Entwicklung
> Ausgangs-`main`: `f5cb518a0c0a6aafc1b1483c833fb7907ca5e882`. Offene PRs #357 (Cube), #361 (Cylinder), #366 (Emanation), #356/#362/#364 (Story B), #359/#365 (UI C), #358/#363 (Integration D) ändern diese neuen Domain-/Testdateien **nicht**. README und `docs/CODEX_CHECKPOINT.md`/Chat-A-Checkpoint überschneiden sich dokumentarisch; Chat D soll vor Merges additiv konsolidieren. Kein automatischer Merge.
> 
> ## Integrations- und CI-Nachtrag
> Die erste CI deckte ausschließlich Dart-Formatabweichungen in den zwei neuen Dateien auf. Der exakte Formatter-Diff wurde über einen kurzlebigen Diagnose-Workflow ermittelt und eingecheckt; dessen Workflow-Datei ist wieder entfernt. Anschließend wurde der neue Main-Stand `37a6142ea791a607c78065b50aa66fda90acda5c` über einen **regulären Zwei-Eltern-Merge** mit additiv konsolidierten README-/Checkpoint-Inhalten übernommen. Keine fremden Änderungen überschrieben. Finaler PR-HEAD `444b282a56613b20b68e03006b7010200e364c82`, GitHub mergeable=true.
> 
> [CI des finalen PR-HEADs #40754399935](https://github.com/ManuEtt/Dnd/actions/runs/40754399935): Struktur, Python, SRD-Register, Backend, Dart-Format, Flutter-Analyse und gezielte Widgettests erfolgreich. **Vollständiges Flutter-Testset läuft; Android/native/Alpha noch nicht abgeschlossen.**

---

### PR #371: fix(Chat B): Doppelte gespeicherte NPC-IDs im Story-Payload abweisen

- Quelle: [#371](https://github.com/ManuEtt/Dnd/pull/371)
- Original-Branch: `feat/chat-b/npc-payload-duplicate-id-20261029`
- Original-HEAD: `5eaff64c1cf31ddf4e62e29c473ba8ce174892ed`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> Importierte Kampagnen können zwei verschiedene NPC-Zeilen mit derselben gespeicherten ID enthalten. Trotz eindeutiger Anzeigenamen darf der KI-Story-Kontext diese ID nicht als eindeutig bestätigt übertragen.
> 
> ## Lösung
> `NpcIdentityStoryPayload.prepare` zählt alle gespeicherten NPC-IDs und überspringt mehrfach vorkommende IDs. Andere eindeutig gespeicherte NPCs bleiben verfügbar. Keine Änderung an Regelzustand, Heldenwerten, Datenformat oder Provider-API.
> 
> ## Tests
> Drei neue Flutter-Regressionen: beide Namen mit derselben ID werden ausgelassen; eine andere eindeutige ID bleibt verfügbar; eindeutige IDs überstehen den JSON-Roundtrip. **CI: vollständig erfolgreich** auf dem finalen HEAD `5eaff64c1cf31ddf4e62e29c473ba8ce174892ed` – [PR-Workflow #40815627270](https://github.com/ManuEtt/Dnd/actions/runs/40815627270) und [Push-Workflow #40815613877](https://github.com/ManuEtt/Dnd/actions/runs/40815613877), jeweils completed/success. Alle Jobs einschließlich Python-Prüfungen, Backend-Typprüfung/-Build/-Tests, Dart-Formatierung, Flutter-Analyse/-Tests und Android-Debug-/Alpha-APKs erfolgreich. Kein Test auf physischem Android-Gerät oder produktivem AI-Provider.
> 
> ## Koordination
> Fachdatei `app/lib/story/npc_identity_story_payload.dart` und neue Testdatei, kein Eingriff in Fachdateien der offenen Chat-B-PRs #356, #362, #364. README und zentralen Checkpoint bei Integration durch Chat D additiv zusammenführen.
> 
> Branch `feat/chat-b/npc-payload-duplicate-id-20261029`; Basis `1dc8d076786dbfb6a6792b6653bd1457bd7992d9`; finaler HEAD `5eaff64c1cf31ddf4e62e29c473ba8ce174892ed`. Reviewbereit, nicht gemergt.

---

### PR #372: feat(Chat A): SRD 5.2.1 Wall of Fire hot-side and turn-trigger preflight

- Quelle: [#372](https://github.com/ManuEtt/Dnd/pull/372)
- Original-Branch: `feat/chat-a/wall-fire-heat-side-preflight-20261029`
- Original-HEAD: `cd3e46f8d060f1045bf30fa03ee0b70a60e230e1`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem / SRD
> *Wall of Fire* requires a side chosen at casting time. Its 10-foot end-of-turn band only applies on that selected side (or within the wall); first wall entry on a turn is a separate trigger. This rule is not yet represented by an isolated, validated mechanic. Existing ring preview PR #367 remains untouched.
> 
> ## Implemented
> - New pure read-only `SrdWallOfFireHeatSideRules.previewConfirmedTrigger`: validates the Wall-of-Fire spell identity, a confirmed active wall, explicit hot-side selection, target region and measured distance.
> - Strict topology checks: straight walls accept left/right; rings accept inside/outside. Incorrect/missing confirmations fail closed.
> - End-of-turn hot-side review candidate through **exactly 10 feet** (inclusive), not on the opposite side; targets inside the wall are separate candidates.
> - First wall entry is only accepted with a confirmed first-entry-on-turn event **at the wall**. Does not infer timing from story or silently deduct damage.
> - Six deterministic unit tests: distance boundary, opposite side, ring variants, entry/end triggers, invalid/unknown values, wrong topology/spell identity.
> - No RNG, saves, damage, creature HP, revisions, storage, UI, height/3D cover, automatic duplicated-event processing or new persistence. Returns candidates for further adjudication, **not confirmed hits**.
> - No migrations or changes to SQLite3 / JSON1.
> 
> ## Changed files
> `app/lib/domain/srd_wall_of_fire_heat_side_rules.dart`; `app/test/srd_wall_of_fire_heat_side_rules_test.dart`; additive README / docs/CODEX_CHECKPOINT.md / docs/parallel/CHAT_A_CHECKPOINT.md on own branch.
> 
> ## Acceptance / verification
> - [x] Code and six positive/negative tests committed on independent Chat A branch.
> - [ ] Dart-format, Flutter analysis/tests, Python/backend, Android/native/Alpha CI on final head. Local Flutter/Dart SDK unavailable.
> - [ ] Code review and integration; do **not** merge automatically.
> 
> ## Scope / provenance
> Working SRD ID `SPELL-ENTRY-WALL-OF-FIRE` remains **unverified** in the registry; this is a partial preflight, not full SRD coverage. Official: Wizards of the Coast LLC, SRD 5.2.1, *Wall of Fire*, CC BY 4.0, https://www.dndbeyond.com/srd . Wall activation, targeting, elevation, cover and trigger idempotency still need authoritative integration.
> 
> ## Parallel coordination
> Based on main `1dc8d076786dbfb6a6792b6653bd1457bd7992d9`. Open PRs #357, #361, #366, #367 (Chat A), plus Chat B/C/D and #371: no overlap of the **new code/test paths**. README and central checkpoint necessarily overlap documentary changes in other PRs; integrate additively after re-checking main.
> 
> ## CI-/Formatter-Korrektur
> Die anfängliche Android-CI scheiterte ausschließlich bei der Dart-Formatierung der neuen Testdatei (`test/srd_wall_of_fire_heat_side_rules_test.dart`); spätere Gates waren deshalb noch nicht ausgeführt. Der kurze [Formatter-Diagnoselauf #40816059928](https://github.com/ManuEtt/Dnd/actions/runs/40816059928) war erfolgreich und hat den offiziellen exakten Diff geliefert. Dieser ist mit Commit `51cbb8621f900ef077192164a1939f699c6a1564` übernommen. Der temporäre Diagnose-Workflow wurde im folgenden Commit **entfernt**. Finaler PR-Head: `cd3e46f8d060f1045bf30fa03ee0b70a60e230e1`. Die [finale Android-Alpha-CI #40816206840](https://github.com/ManuEtt/Dnd/actions/runs/40816206840) ist separat in Ausführung; bis zu ihrem Abschluss keine vollständige Abnahme behaupten.
> 

---

### PR #373: fix(Chat B): KI-Story-Schritte gegen aktuellen Event-Checkpoint absichern

- Quelle: [#373](https://github.com/ManuEtt/Dnd/pull/373)
- Original-Branch: `feat/chat-b/ai-step-checkpoint-binding-20261029`
- Original-HEAD: `68e717c9dc8534946251dc9d427c81e7667c07a5`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> `StoryCampaignEngine.applyAiStoryStep` prüfte `narrative.turn`, aber nicht die Herkunft des zu überschreibenden Events. Ein veraltetes, manipuliertes oder sitzungsfremdes Event konnte den letzten Journaleintrag ersetzen und die KI-Erzählung an einem unbestätigten Zustand fortführen.
> 
> ## Änderung
> Vor dem Übernehmen des KI-Schritts werden Ereignis-ID, Kampagnen-/Sitzungs-ID, Gleichheit mit dem letzten Journalereignis und dessen `stateAfter`-Checkpoint zum tatsächlichen Kampagnenzustand kanonisch verglichen. Bestehende zulässige Story-Änderungen bleiben unverändert. Keine regelrelevanten Änderungen oder Migrationen.
> 
> ## Regressionstests
> Neue Datei `app/test/ai_story_event_checkpoint_test.dart`: gültiger Story-Schritt + JSON-Roundtrip; sieben manipulierte Kombinationen von Event-ID, Kampagne, Sitzung, Checkpoint und Journal; veraltetes Event aus vorherigem Turn. Unverändertheit des ursprünglichen Spielstands wird geprüft.
> 
> ## Koordination
> Ändert keine Fachdateien der offenen Chat-B-PRs #356, #362, #364, #371. README und Checkpoints bei Integration additiv konsolidieren.
> 
> Basis `1dc8d076786dbfb6a6792b6653bd1457bd7992d9`, Commit `b57797b30723525aeec76e49178caa0294cdf1be`. Erfolgreiche vollständige Abnahme auf finalem HEAD; reviewbereit.
> 
> ## Finale CI-Abnahme (Commit `68e717c9dc8534946251dc9d427c81e7667c07a5`)
> 
> - **[Pull-Request-Workflow #40820806717](https://github.com/ManuEtt/Dnd/actions/runs/40820806717): completed / success**
> - **[Push-Workflow #40820802015](https://github.com/ManuEtt/Dnd/actions/runs/40820802015): completed / success**
> - Beide vollständigen Jobs erfolgreich: Python-Projekt-/Grenztests, SRD-Audit, Backend npm ci/Typecheck/Build/Tests, offizieller Dart-Formatter, Flutter analyze, gezielte und vollständige Flutter-Tests (einschließlich aller neuen Regressionstests), Android-Debug-APK, native Sicherungstests, alle Alpha-APKs und Release-/Quellcodeartefakte.
> - Der anfängliche reine Dart-Formatierungsfehler wurde auf dem eigenen Branch mit der offiziellen SDK-Ausgabe korrigiert. Der temporäre Diagnose-Workflow ist wieder entfernt; final nur fünf gewünschte Dateien im Diff.
> - PR ist konfliktfrei (`mergeable=true`) und reviewbereit, **nicht gemergt**.
> - Nicht getestet: physisches Android-Gerät, produktiver KI-Anbieter und produktive APK-Signierung.

---

### PR #374: fix(Chat C): Charakter-Dock bei großer Android-Schrift zweireihig und lesbar

- Quelle: [#374](https://github.com/ManuEtt/Dnd/pull/374)
- Original-Branch: `feat/chat-c/character-nav-large-text-20261029`
- Original-HEAD: `22720b9232841163d782d9acc42bf7e2c7c411e4`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> Die fünf fest angehefteten Aktionen des Charakterbogens bleiben bei 200 % Systemschrift selbst auf 320-dp-Android-Geräten in einer engen Zeile. Vier Beschriftungen liegen in `FittedBox(scaleDown)` und verlieren dadurch einen Teil der vom Benutzer angeforderten Textskalierung.
> 
> ## Implementierung
> - `FantasyCharacterQuickNavigation` verwendet bei TextScaler ≥ 1.8 und Breite unter 500 dp ein zweireihiges Dock: Charakter/Inventar/W20 oben, Zauber/Mehr unten.
> - Große Beschriftungen bekommen maximal zwei Zeilen ohne `FittedBox`-Verkleinerung; bei normaler Schrift bleibt die ursprüngliche einreihige Anordnung erhalten.
> - W20-Medaillon, alle Buttons, Callbacks und Semantik bleiben unverändert. Keine Domain-, Regel-, Story- oder Savegame-Änderung.
> 
> ## Regressionen
> Neue Flutter-Widgettests in `app/test/fantasy_character_quick_navigation_large_text_test.dart`: 320 und 360 dp bei 200 % Schrift (Geometrie/Lesbarkeit/fünf echte Aktionen), 320 dp bei Standardtext (altes Layout und W20-Callback), 320 dp + 200 % + simuliertes Android-IME-Inset (alle Aktionen erreichbar). Vorbestehende `fantasy_character_reference_design_test.dart` und `fantasy_sheet_reference_unification_test.dart` bleiben unberührt.
> 
> ## Koordination
> **Chat C**, Ausgangs-main `1dc8d076786dbfb6a6792b6653bd1457bd7992d9`, Branch `feat/chat-c/character-nav-large-text-20261029`. PR #359 testet ein anderes Dock; PR #365 ändert das Abenteuer-Quest-HUD. Mit Chat A, B und D keine gemeinsame Produktions-/Testdatei. Gemeinsame README-/Checkpoint-Abschnitte bei der Integration konsolidieren.
> 
> ## CI- und Geräte-Gates
> Bis zum Abschluss der auf dem finalen SHA gestarteten GitHub-Actions-CI **keine erfolgreichen Flutter- oder Android-Tests behaupten**. Für Freigabe: Dart format, Flutter analyze, neue Widgettests + vollständige Suite, Python/Backendtests, Android-Debug-/Alpha-Build und native Tests. Physisches Android-Gerät mit TalkBack/200 % Schrift bleibt ein separat offen ausgewiesenes Abnahmekriterium.
> 
> Checkpoint: `docs/parallel/CHAT_C_CHECKPOINT.md`.

---

### PR #375: feat(Chat A): SRD 5.2.1 Magic Missile auf mehrere bestätigte Ziele verteilen

- Quelle: [#375](https://github.com/ManuEtt/Dnd/pull/375)
- Original-Branch: `feat/chat-a/magic-missile-multitarget-plan-20261029`
- Original-HEAD: `1e0ac19fd3e4f830808534fc35fd44c7abb637fe`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem und Quelle
> `SPELL-MISSILE-MULTITARGET` ist im Requirements-Register als `missing` dokumentiert. Die bisherige ausführbare Magisches-Geschoss-Aktion beschränkt den Treffer auf einen Gegner. SRD 5.2.1 S. 146 (*Magic Missile*), Wizards of the Coast LLC, CC BY 4.0, erlaubt stattdessen die Verteilung der gleichzeitig auftreffenden Geschosse auf eine oder mehrere sichtbare Kreaturen in Reichweite. Quelle: https://www.dndbeyond.com/srd
> 
> ## Unabhängiges Paket / DoD
> - Reine Domänen-Vorprüfung von 3 + (Zauberplatzgrad - 1) Geschossen für Grad 1 bis 9.
> - Jede Geschossposition besitzt genau eine ausdrücklich bestätigte Kreaturen-ID; dieselbe Kreatur darf mehrfach gewählt werden.
> - Duplikate, nicht vorhandene Identitäten, fehlende Sicht, Reichweite, Kreaturen- oder Deckungsbestätigung und verfälschte Zaubermetadaten werden vor einer Aktion abgewiesen.
> - Immutable Plan bewahrt die Reihenfolge der Geschosse und zählt die Verteilung pro Ziel.
> - Positiv-, Negativ-, Grenz- und Immutability-Regressionstests.
> 
> ## Grenzen
> Nur Vorprüfung; **noch keine Integration in Kampfdialog, GameEngine, GameController, SQLite oder Ausführung**. Keine zusätzlichen Trefferwürfe/Schäden, keine Shield- oder Widerstandsentscheidung und keine Ressourcenbuchung. Kein bestehender Spielstand wird verändert; SQLite 3 / äußeres JSON 1 unverändert; Requirement bleibt bis zur End-to-End-Ausführung **partial**.
> 
> ## Parallele Entwicklung
> Eigene Fachdateien `srd_magic_missile_multi_target_rules.dart` und `srd_magic_missile_multi_target_rules_test.dart`; keine Überschneidung mit bestehenden Chat-A-PRs #357/#361/#366/#367/#372 oder Chat B/C/D. Gemeinsame README/CODEX-Checkpoint-Nachträge bitte durch Chat D additiv zusammenführen. Kein automatischer Merge.
> 
> ## Tests
> Lokal weiterhin kein Dart/Flutter-SDK; siehe finale nachgewiesene CI-Abnahme unten.
> 
> ## Finale CI-Abnahme (29.10.2026)
> - **Vollständig grün:** [Android-Alpha GitHub Actions #40829590211](https://github.com/ManuEtt/Dnd/actions/runs/40829590211) auf finalem PR-Branch-HEAD `1e0ac19fd3e4f830808534fc35fd44c7abb637fe`.
> - **Bestanden:** 200 Python-Tests, 72 Backend-Tests, 2.273 Flutter-Tests (inkl. acht neuer Magic-Missile-Mehrziel-Tests), gezielte 20 Widgettests, `dart format` 509 Dateien/0 Änderungen, Flutter-Analyse, Debug-APK, native Android-Tests, drei kleinere Alpha-APK-Builds, versioniertes Alpha-/Quellcode-Paket.
> - [Debug-APK-Artefakt](https://github.com/ManuEtt/Dnd/actions/runs/40829590211/artifacts/12879105948) · [Kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40829590211/artifacts/12879031162) · [Quellcode-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40829590211/artifacts/12879115901) · [Vollständiges Alpha-Paket](https://github.com/ManuEtt/Dnd/actions/runs/40829590211/artifacts/12878373715).
> - **Nicht getestet:** echtes Android-Gerät, historische Updateinstallation und Release-Produktivsignierung. Bereits fehlgeschlagene Vorläufe scheiterten nur an inzwischen korrigierter Dart-Formatierung.
> - **Kein Merge:** fachlicher Review/Integration der gemeinsamen README-/Checkpoint-Dokumentation bleibt Chat D vorbehalten. Keine Datenmigration und keine Änderung am bestehenden Einziel-Kampfbefehl.
> 

---

### PR #376: fix(Chat C): Kampagnen-Gedächtnisdialoge bei 200 % Schrift und Android-IME scrollbar halten

- Quelle: [#376](https://github.com/ManuEtt/Dnd/pull/376)
- Original-Branch: `fix/chat-c/scrollable-memory-edit-dialogs-20261029`
- Original-HEAD: `1c9c58bc95a45919667de7f22f1524bfe5d138e2`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> Die Dialoge zur Bearbeitung von Handlungssträngen und NPC-Beziehungen besitzen einzelne `SingleChildScrollView`-Formularinhalte, aber bislang keine scrollbar konfigurierte Dialoghülle. Bei 320 dp Android-Breite, 200 % Systemschrift und eingeblendeter Tastatur können die Dialogaktionen schwer erreichbar werden.
> 
> ## Änderung
> - Beide `AlertDialog` in `app/lib/ui/campaign_memory_panel.dart` erhalten `scrollable: true`.
> - Felder, Status, NPC-Auswahl und alle Controller-Callbacks bleiben unverändert.
> - Neue Widgetregression `app/test/campaign_memory_dialog_large_text_test.dart`: beide Dialoge bei 320×800 dp, 2x Schrift, 270 dp IME-Inset; Aktionen `Speichern`/`Bestätigen` und `Abbrechen` hit-testbar; Abbrechen ohne Spielstands-/JSON-Mutation.
> - Fortschritt ergänzt in `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_C_CHECKPOINT.md`.
> 
> ## Koordination / Grenzen
> **Chat-Kennung C**; Ausgangs-main `1dc8d076786dbfb6a6792b6653bd1457bd7992d9`. UI-/Testdateien sind von den parallelen Chat-C-PRs #359, #365 und #374 sowie Chat A/B/D unabhängig. Gemeinsame README- und Checkpoint-Abschnitte bei Integration zusammenführen.
> 
> Keine Spielregel-, Story-, Controller-, Backend-, SQLite- oder JSON-Änderung. Keine Migration, kein Merge in main.
> 
> ## Abnahme
> CI muss für finalen PR-SHA Dart-Formatierung, Flutter-Analyse, vollständige Widgettests, Backend/Python, Debug-/Alpha-APK und native Android-Gates erfolgreich abschließen. Solange das nicht bestätigt ist, PR als Draft belassen. Realgerät/TalkBack/IME separat.
> 
> ## main-Synchronisierung vom 29.10.2026
> 
> Neuer produktiver Main-Stand `a25b357372afe6a2ac3cce9c10bc56a7d9cc775c` (Chat D PR #358) wurde als regulärer, nicht-forcierter Merge in den Feature-Branch übernommen, Commit `8165b8ea19ab30c21a6341c4913f23af44309e48`. Sowohl die Alpha-Release-Sperre als auch deren README/Checkpoint bleiben erhalten. **Keine UI-/Testdateiüberschneidung** mit Chat A, B, D oder #359/#365/#374.
> 
> Die erste CI scheiterte an drei reinen Formatierungsabweichungen in der neuen Testdatei; ein temporärer, isolierter offizieller [Flutter-Dart-Format-Lauf #40832186273](https://github.com/ManuEtt/Dnd/actions/runs/40832186273) stellte den exakten Diff bereit. Korrekturen angewendet und temporären Workflow wieder entfernt. Finale vollständige Android-Alpha-CI auf `1c9c58bc95a45919667de7f22f1524bfe5d138e2`: [#40832274768](https://github.com/ManuEtt/Dnd/actions/runs/40832274768) (Ergebnis bis Abschluss offen).

---

### PR #377: fix(Chat B): NPC-Auswahl an Sitzung und gespeichertes Profil binden

- Quelle: [#377](https://github.com/ManuEtt/Dnd/pull/377)
- Original-Branch: `feat/chat-b/npc-selection-session-description-20261029`
- Original-HEAD: `b5ec0d49d4cca19e61139fe009930a4fd2ed38a0`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> Explizit gewählte NPC-IDs sind bisher an Kampagnen-ID und Revision sowie Name, Beziehung und Leben gebunden. Die Sitzungs-ID und der weitere NPC-Profiltext wurden nicht geprüft. Ein importierter/extern geänderter Spielstand kann bei gleicher Revision trotz geänderter Sitzung bzw. ausgetauschter NPC-Beschreibung alte Auswahlen zulassen.
> 
> ## Umsetzung
> `NpcStorySelection.choose` hält **Sitzungs-ID** und **NPC-Beschreibung** nur im flüchtigen Auswahlobjekt fest. `requireCurrent` validiert beide unmittelbar vor der ID-gebundenen Story-Kontextvorbereitung. Eindeutige NPC-ID bleibt die einzige Identität. Änderung an einem anderen NPC-Profildatensatz lässt die Auswahl bestehen.
> 
> ## Akzeptanz und Tests
> Vier Flutter-Regressionen in `app/test/npc_story_selection_session_profile_test.dart`:
> 1. Unveränderter Spielstand nach JSON-Roundtrip: gewählte NPC-ID und nur die zugehörige bestätigte Notiz verfügbar.
> 2. Neuer Session-Key bei gleicher Kampagnen-ID, Revision und NPC-Identität: Auswahl abgewiesen, keine Mutation.
> 3. Neuer NPC-Profiltext bei gleicher ID/Name/Beziehung/Leben/Revision: Auswahl abgewiesen, keine Mutation.
> 4. Profiländerung eines anderen NPCs bei unverändert gewählter Identität: Auswahl weiterhin gültig.
> 
> Keine Datenbankmigration, kein JSON-Schemawechsel, keine Änderung an SRD-Regeln, Quest- oder Heldenwerten.
> 
> ## Parallelkoordination
> Vom aktuellen main `a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`. Nur `app/lib/story/npc_story_selection.dart` und neuer Fachtest; keine Fachdatei der offenen Chat-B-PRs #356/#362/#364/#371/#373 berührt. README und zentrale Checkpoints werden bei Integration von Chat D additiv konsolidiert.
> 
> ## CI
> **Vollständige CI auf dem finalen Commit bestanden; reviewbereit.** Ausgangscommit: `4f570fc9bb4c345a9850860b77ffa03a6c7a3930`, finaler HEAD: `b5ec0d49d4cca19e61139fe009930a4fd2ed38a0`. Physisches Android-Gerät/Produktiv-KI-Anbieter nicht getestet.
> 
> ## Finale Abnahme – 29.10.2026
> 
> - **[PR-CI #40832372024](https://github.com/ManuEtt/Dnd/actions/runs/40832372024): vollständig erfolgreich** (`completed/success`, exakt `b5ec0d49d4cca19e61139fe009930a4fd2ed38a0`).
> - **[Push-CI #40832364581](https://github.com/ManuEtt/Dnd/actions/runs/40832364581): vollständig erfolgreich** (`completed/success`, exakt `b5ec0d49d4cca19e61139fe009930a4fd2ed38a0`).
> - Sämtliche Schritte beider Jobs grün: Projekt-/Python-Tests, SRD-Audit, Backend-Typecheck/-Build/-Tests, Dart-Formatierung, Flutter-Analyse, gezielte und vollständige Flutter-Tests inklusive vier neuer NPC-Auswahlregressionen, Android-Debug-APK, native Android-Tests, ARM-/ARM64-/x64-Alpha-APKs und Release-/Quellcodeartefakte.
> - Initialer reiner Dart-Formatierungsfehler auf `4f570fc` korrigiert anhand offiziellen Dart 3.9.2-Diffs; temporärer Diagnoseworkflow wieder gelöscht. Finaler PR-Diff enthält exakt fünf Dateien, keine CI-Workflow-Reste.
> - **Keine Migration; keine Änderungen an SRD-Regeln, Hero/Quest-Zustand oder persistentem Schema.**
> - Neues Konfliktaudit: Auch die zwischenzeitlich veröffentlichten PRs #378, #379 und #380 überschneiden sich ausschließlich in gemeinsam zu konsolidierenden README-/Checkpoint-Dateien. `app/lib/story/npc_story_selection.dart` wird in keinem parallelen offenen PR verändert.
> - Nicht auf physischer Android-Hardware oder mit produktivem KI-Anbieter geprüft. Kein Merge durchgeführt.

---

### PR #378: fix(Chat D): Historische Checkpoint-Prüfsummen ohne Symlink-Rennen erstellen

- Quelle: [#378](https://github.com/ManuEtt/Dnd/pull/378)
- Original-Branch: `fix/chat-d/checkpoint-history-nofollow-hash-20261029`
- Original-HEAD: `78b35cca3cf2b871120357d352e825e452b95fa0`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem / Implementierung
> Historische Checkpoint-Dateien wurden mit `lstat` auf Sicherheit geprüft, später jedoch pfadbasiert gehasht. Ein inzwischen eingeschleuster Symlink konnte externe Inhalte preisgeben. `previous_checkpoint_files()` merkt sich nun Dateimetadaten. `sha256_previous_checkpoint()` liest historische Dateien unter POSIX aus einem per `O_DIRECTORY|O_NOFOLLOW` gepinnten Verzeichnisdeskriptor, relativ dazu über `O_NOFOLLOW`. Der SHA-256 wird blockweise ermittelt; `lstat` und `fstat` müssen vor/nach dem Lesen Größe, Geräte-/Inoden-ID, ctime und mtime des ursprünglichen Inventars bestätigen. Ein vor dem Hashing geänderter oder durch einen Link ersetzter Eintrag wird zurückgewiesen, ohne stabile Aliasdateien zu ersetzen.
> 
> ## Tests auf FINALER SHA erfolgreich
> **HEAD `78b35cca3cf2b871120357d352e825e452b95fa0`.** [PR-GitHub-Actions #40832312476](https://github.com/ManuEtt/Dnd/actions/runs/40832312476) **vollständig erfolgreich, 36/36 Schritte**: Projektprüfung, Modulgrenzen, SRD-Register, Python-Gesamtsuite einschließlich zwei neuer Austausch-Regressionen, Backend-Typen/Build/Tests, Dart-Format/Flutter-Analyse/-Tests, native Android-Tests, Debug-/Alpha-APKs und vollständiges Release/Quellcheckpoint. Auch auf Basis `main` `a25b3573` bestand separat [Main-CI #40831922453](https://github.com/ManuEtt/Dnd/actions/runs/40831922453).
> 
> ## Geltungsbereich
> Kein SQLite-/JSON-/Appversions-/Regel-/Story-Update und keine Migration. Keine Änderung historischer ZIPs oder Checksum-Formate. Der Nicht-POSIX-Fallback ist **nicht** gleichwertig racefrei und ein nicht autorisierter Schreiber mit beliebigem Zugriff auf die Prozessressourcen ist außerhalb dieses Modells. Kein Realgerätetest.
> 
> ## Koordination
> Von `main` `a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`; kein anderer offener PR ändert die zwei technischen Python-Dateien. Gemeinsame README/Checkpoint-Einträge wurden additiv geschrieben. Der unabhängige Chat-D-PR #380 behandelt das Alpha-Release-Abbruch-Cleanup und wird nach diesem Merge erneut synchronisiert. Kein Force-Push/Branchlöschen.

---

### PR #379: fix(Chat C): vollständige Helden- und Kampagnennamen bei großer Android-Schrift

- Quelle: [#379](https://github.com/ManuEtt/Dnd/pull/379)
- Original-Branch: `fix/chat-c/active-hero-identity-large-text-20261029`
- Original-HEAD: `47a91076d76a7e25a0ce28666175a43c597a43be`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> Die aktive Heldenkarte schneidet auch bei 200 % Android-Schrift und schmalen Bildschirmen einen langen Heldennamen nach zwei Zeilen und den Kampagnenamen nach einer Zeile ab. Neben dem 79-dp-Porträt ist zu wenig Breite für eine gut lesbare Identität.
> 
> ## Implementierung
> - `FantasyActiveHeroCard` wechselt ab 180 % Textskalierung bei weniger als 500 dp Karten-Innenbreite in ein vertikales Layout: Porträt zuerst, vollständiger Heldentext darunter.
> - Name, Spezies/Klasse/Stufe und Kampagnenname verwenden in diesem Modus `maxLines: null` und `TextOverflow.visible`. Keine künstliche Verkleinerung.
> - Standardlayout mit Porträt links und bisherigem einzeilig/gekürztem Kampagnentitel bleibt unverändert.
> 
> ## Regressionen
> Neue `app/test/fantasy_active_hero_identity_large_text_test.dart`: 320/360 dp bei 200 % Schrift, vollständige Namen, vertikale Geometrie, unveränderte Statuswerte und echte `onContinue`-/`onHeroes`-Callbacks, `HeroCharacter.toJson()` unverändert; 360 dp Standardtext beweist die ursprüngliche kompakte Anordnung. Vorhandene Dashboard-Tests bleiben erhalten.
> 
> ## Grenzen / Koordination
> **Chat-Kennung C**, Basis-main `a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`. Andere Produkt-/Testdateien als bei Chat C PR #359, #365, #374 und #376 sowie allen offenen Chat-A/B/D-Paketen; gemeinsame README-/Checkpoint-Änderungen bei Integration bewahren. Keine Regel-/Story-/Datenbank-/Controller-/JSON-Mutation und keine Migration.
> 
> ## CI
> Bis vollständige GitHub Actions für den finalen SHA erfolgreich sind, bleibt der PR **Draft**. Erforderlich sind Dart format, Flutter analyze, neue Widgettests sowie vollständige Suite, Backend/Python, Android-Debug/Alpha und native Tests. Echtes Gerät mit 200 % Systemschrift und TalkBack separat prüfen.
> 
> Dokumentiert in `docs/parallel/CHAT_C_CHECKPOINT.md`.

---

### PR #380: fix(Chat D): Unterbrochene Alpha-Releases vor Freigabe der Versionssperre bereinigen

- Quelle: [#380](https://github.com/ManuEtt/Dnd/pull/380)
- Original-Branch: `fix/chat-d/alpha-release-interrupt-cleanup-20261029`
- Original-HEAD: `8adcce4b233949f46e266703cc5c6bf7be47842a`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> Das exklusiv gesperrte Alpha-Packaging aus PR #358 räumte mit `except Exception` nur gewöhnliche Fehler auf. Bei `KeyboardInterrupt` oder `SystemExit` sprang der Ablauf direkt in `finally` und löste die Versionssperre, obwohl unvollständige Release-Dateien verbleiben konnten. Beim nächsten Aufruf derselben Version wurde dann die Kollision gemeldet.
> 
> ## Implementierung
> - Der vorhandene, strikt auf die selbst erzeugten Version-Dateien beschränkte Cleanup wird auch für `BaseException` ausgeführt. Der Abbruch wird danach unverändert weitergeworfen.
> - Das vorhandene `finally` löst anschließend die exklusive Versionssperre.
> - Kein Veränderung der API, regulärer Fehlerbehandlung, Signierung, Release-Dateiformate, SQLite, Kampagnen-JSON oder App-Version.
> - **Nicht** als SIGKILL-/Stromausfallbereinigung ausgeben: Harte Prozessabbrüche lassen die Sperre absichtlich stehen (Fail-Closed).
> 
> ## Neue Tests
> 1. `KeyboardInterrupt` während der APK-Kopie nach Erzeugung einer partiellen Ziel-APK: Alle eigenen Dateien entfernt, Sperre entfernt, erneuter vollständiger Aufruf erfolgreich.
> 2. `SystemExit(15)` während SHA256-Berechnung: Exit-Code unverändert, alle eigenen Dateien und Sperre entfernt, Retry erfolgreich.
> 3. Sämtliche bisherigen positiven und negativen Release-Regressionen bleiben aktiv.
> 
> ## Abnahme und Koordination
> - Ausgangs-`main`: `a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`.
> - Finaler Code/Test-Head: `8adcce4b233949f46e266703cc5c6bf7be47842a`.
> - **CI noch offen**. Abzunehmen: Python-Komplettsuite, Projekt-/SRD-/Modulgrenzen, Backend-Tests, Flutter/Dart-Analyse/-Tests, Android-Build, native Tests, Alpha-/Checkpoint-Artefakte.
> - PR #378 behandelt `scripts/create_checkpoint.py` und seine Tests, nicht die beiden technischen Dateien dieses PRs. Andere offene Chats arbeiten nicht an den Fachdateien. Die Dokumentationsdateien werden vor jeder Integration additiv konsolidiert.
> - Draft bis vollständiger CI auf finalem Head und aktueller Main-/PR-Prüfung. Kein Force-Push und kein automatisches Merge unfertiger Arbeit.

---

### PR #381: fix(Chat D): Quell-ZIP-Ausgabe und Prüfsumme vor Symlink-Umleitungen schützen

- Quelle: [#381](https://github.com/ManuEtt/Dnd/pull/381)
- Original-Branch: `fix/chat-d/source-archive-output-symlink-20261029`
- Original-HEAD: `63dc3b78e527cfa079c2e2c799f09f3b48d6b6fc`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> `scripts/package_project.py` verwendete für den **Ausgabepfad** `Path.resolve()`. Ein bereits existierender Symlink wie `export.zip -> /anderer/pfad/private.datei` wurde dadurch als Zielpfad verwendet; das spätere `os.replace` konnte die externe Datei statt des benannten ZIPs überschreiben. Ein analoger Link für `.zip.sha256` wurde vor Veröffentlichung nicht ausgeschlossen. Bei einem Austausch zwischen Vorprüfung und Sicherung folgte `shutil.copy2` dem Symlink.
> 
> ## Implementierung (Chat D)
> - Den gewählten Ausgabe-Namen absolutisieren, ohne seinen letzten Symlink aufzulösen; existierende/dangling Symlinks für ZIP und Prüfsumme vor dem Aufbau ablehnen.
> - Das Auflösungsziel weiterhin gegen den Projektbaum prüfen; nichtreguläre vorhandene Ziele ablehnen.
> - Vorhandenes ZIP unter POSIX per `O_NOFOLLOW|O_NONBLOCK` + `fstat` sichern, so dass ein nachträglich ausgetauschter Symlink nicht gelesen wird. Der Non-POSIX-Fallback bleibt best effort.
> - Bisherige Staging-, Prüfsummen-, ZIP-Validierungs- und Rollback-Mechanik bleibt erhalten. Keine SDK-, Story-, Spielstands- oder Versionsänderungen.
> 
> ## Regressionen und Akzeptanz
> 1. Existing output Symlink: Fremdzieldatei unverändert, keine ZIP-/SHA-Veröffentlichung.
> 2. Dangling output Symlink: Ziel wird nicht erzeugt.
> 3. Checksum-Symlink: bestehende ZIP-Datei und fremde Prüfsummenzieldatei bleiben bytegleich.
> 4. Austausch nach Vorprüfung: POSIX-No-Follow-Sicherung lehnt Link ab und liest die fremde Datei nicht.
> 5. Bestehende positive Tests für ZIP/Hash und fehlgeschlagene Veröffentlichungen bleiben aktiv.
> 
> **Basis main:** `a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`  
> **Technischer Commit:** `5fc1b4a2d1e950c89432575d812d26fd90939144`  
> **Koordination:** Keine technische Datei der 19 offenen PRs überschneidet sich. `README.md` und `docs/CODEX_CHECKPOINT.md` werden additiv bearbeitet und müssen vor Integration mit anderen PRs abgeglichen werden. SQLite-, äußeres JSON- und App-Schema unverändert; keine Migration.
> 
> **Tests:** Neue Testfälle sind implementiert, noch **nicht lokal ausgeführt**: lokaler Git-Checkout scheitert an DNS, Flutter/Dart sind nicht installiert. GitHub Actions auf finalem HEAD gesondert prüfen. Kein grüner Build vor tatsächlicher Abnahme; PR bleibt Draft bis vollständigem CI-Nachweis und Integrationsprüfung.

---

### PR #382: fix(Chat C): ausstehende Spielerhandlung vor Wiederholung vollständig prüfbar

- Quelle: [#382](https://github.com/ManuEtt/Dnd/pull/382)
- Original-Branch: `feat/chat-c/pending-action-full-text-20261029`
- Original-HEAD: `214ad2570cae9e796daf9ea447b2ba646143e3ae`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Problem
> Nach einer unterbrochenen Handlung wurde der bestätigungspflichtige, lokal gespeicherte Auftrags-Text in `PendingActionStatus` nach zwei Zeilen mit Ellipse gekürzt. Vor dem kostenrelevanten manuellen Retry konnte der Nutzer den vollständigen Auftrag nicht prüfen.
> 
> ## Implementierung
> - Das bisher kompakte Zwei-Zeilen-Layout bleibt Standard; ein expliziter Button blendet den vollständigen unveränderten Text ein und wieder aus.
> - Bei Wechsel von Kampagne, Request-ID, Text oder NPC-Bindung wird die aufklappbare Ansicht zurückgesetzt.
> - Der Schalter funktioniert auch, wenn Regelinteraktionen gesperrt sind; Retry/Verwerfen bleiben weiterhin gesperrt.
> - Keine Änderung an `PendingPlayerAction`, Outbox, Controller, Speicherformat, Regel- oder KI-Mechanik.
> 
> ## Tests
> - Neuer Test für vollständigen Text, Ein-/Ausklappen und nachweislich unverändertes `toJson()` vor/nach manuellem Retry.
> - Neuer Test für Wechsel des Auftrags und Zustand ohne ausstehenden Auftrag.
> - 320/360 dp und 200 % Systemschrift, Screenreader-Schalter und gesperrte Retry-Aktion.
> - Bestehende `pending_action_status_test.dart` bleiben aktiv.
> 
> ## Koordination
> **Chat C**, Basis `main` a25b357372afe6a2ac3cce9c10bc56a7d9cc775c; primär nur `app/lib/ui/pending_action_status.dart` und `app/test/pending_action_status_test.dart`. Keine Überschneidung mit offenen C-PRs #359, #365, #374, #376, #379 oder A/B/D-Fachdateien. Gemeinsam bearbeitete README/Checkpoint-Einträge bei Integration additiv konsolidieren.
> 
> ## Abnahme
> Bis zur vollständigen CI auf finalem PR-SHA bleibt der PR **Draft**. Flutter-/Dart-/Android-SDK sind hier lokal nicht verfügbar; Flutter-Analyse, gezielte/vollständige Tests, Android-Build, Python/Backend und natives Android-Gate via Actions prüfen. Realgerät/TalkBack gesondert.
> 
> Keine Datenbank-/JSON-Migration. Kein Merge vorgesehen.

---

### PR #383: fix(Chat B): NPC-Erinnerungssnapshots an die Sitzung binden

- Quelle: [#383](https://github.com/ManuEtt/Dnd/pull/383)
- Original-Branch: `feat/chat-b/npc-identity-session-guard-20261029`
- Original-HEAD: `4d9d7f91e95d981df69e71310ad81d5ce4d2852f`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> `NpcIdentityMemory.requireCurrent` bestätigte einen zuvor gelesenen NPC-Snapshot auch für eine andere Sitzung derselben Kampagne, wenn Revision, NPC-Daten und Notizen identisch waren. Ein Snapshot darf nicht unbemerkt über den Sitzungswechsel hinweg weiterverwendet werden.
> 
> ## Umsetzung
> - `NpcIdentityContext` enthält die `sessionId` als lokale, unveränderliche Momentaufnahme.
> - `NpcIdentityMemory.read` übernimmt sie aus der bestätigten Kampagne; `requireCurrent` vergleicht sie vor dem erneuten Lesen, zusammen mit der bisherigen Kampagnen-ID und Revision.
> - **Der Story-API-/Wire-Vertrag ist unverändert:** `toContextMap` enthält absichtlich keine neue Sitzungs-ID und keine neue Payload-Struktur.
> - Keine Speicherung, Änderung am Schema, D&D-Regelwerk, Quest- oder Heldenwerten.
> 
> ## Positive und negative Regressionen
> Neue Datei `app/test/npc_identity_memory_session_guard_test.dart` mit vier Tests:
> 1. JSON-Roundtrip in derselben Sitzung erhält die bestätigte Auswahl samt NPC-ID, Notizen und unverändertem Wire-Format.
> 2. Andere Sitzung bei identischer Kampagnen-ID, Revision und identischem NPC-Inhalt muss den alten Snapshot zurückweisen; frischer Snapshot funktioniert.
> 3. Auch leere Legacy-NPC-Notizen dürfen keinen Sitzungswechsel ignorieren.
> 4. Änderung eines anderen NPCs verändert die Gültigkeit dieser ausgewählten Identität nicht.
> Jeder Test verifiziert, dass der Spiel-/Heldenzustand unberührt bleibt.
> 
> ## Parallelarbeit
> Basis `main=a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`, Fachcommit `ec0759fe257caba8779caf4803e45831f2713728`. Fachdatei unabhängig von allen offenen Chat-B-PRs (#356, #362, #364, #371, #373, #377). Gemeinsam bearbeitete README-/Checkpoint-Einträge bei Integration durch Chat D additiv konsolidieren.
> 
> ## Tests
> **Vollständig CI-abgenommen auf dem finalen Commit**; reviewbereit. Physisches Android-Gerät, Live-KI-Provider und produktive Signatur nicht getestet.
> ## Finale Abnahme auf dem SHA `4d9d7f91e95d981df69e71310ad81d5ce4d2852f`
> 
> - **[Pull-Request-CI #40862239692](https://github.com/ManuEtt/Dnd/actions/runs/40862239692): completed / success**.
> - **[Push-CI #40862230202](https://github.com/ManuEtt/Dnd/actions/runs/40862230202): completed / success**.
> - Beide Jobs mit jeweils 36 erfolgreichen Schritten: Projektstruktur, Python-Unittests, Story-/Regelgrenzen und SRD-Audit, Backend Typecheck/Build/Test, Dart-Formatierung, Flutter-Analyse, gezielte Widgettests, vollständige Flutter-Tests inklusive der vier neuen Session-Guard-Regressionen, Android-Debug-APK, native Tests, sämtliche Alpha-APKs, Quellcode-/Release-Artefakte.
> - Der anfängliche **reine Dart-Formatierungsfehler** wurde mittels offiziellem Dart 3.9.2 korrigiert; der kurzzeitig erstellte Diagnoseworkflow wurde wieder gelöscht. Der finale Diff umfasst nur fünf vorgesehene Dateien.
> - Aktueller `main=a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`; `mergeable=true`, keine Fachdatei-Überschneidung mit anderen offenen Chat-B-PRs oder den neu hinzugekommenen PRs #384, #385. README- und zentrale Checkpoint-Einträge bei Integration durch Chat D additiv konsolidieren.
> - Nicht getestet: physisches Android-Gerät, echter bezahlter KI-Provider, produktive APK-Signierung.
> - **Keine automatische Zusammenführung** in `main`; Review durch Integrationsteam vorgesehen.
> 

---

### PR #384: fix(Chat D): Dart-Modulgrenzen bei Kommentaren und Strings korrekt prüfen

- Quelle: [#384](https://github.com/ManuEtt/Dnd/pull/384)
- Original-Branch: `fix/chat-d/dart-boundary-comment-safe-20261029`
- Original-HEAD: `a2e73c65eedba0c8888871c850bb061a54861ff3`
- Zum Snapshot: Entwurf (nicht freigegeben)
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> `scripts/check_domain_boundaries.py` suchte Dart-`import`/`export`/`part`-Direktiven mit einem zeilenverankerten Regulären Ausdruck. Direkt vorangestellte Blockkommentare (`/* license */ import '../domain/...'`) umgingen die bisherige Suche. Umgekehrt wurde scheinbarer Importcode in mehrzeiligen Blockkommentaren oder Dart-Mehrzeilenstrings als echte Direktive behandelt. Das erzeugt sowohl unentdeckte unzulässige Abhängigkeiten als auch irreführende Fehlalarme.
> 
> ## Implementiert (Chat D)
> - Kommentarzeichen werden vor der Direktivenprüfung positionsgleich durch Leerzeichen maskiert; Zeilenumbrüche und bestehende URI-Werte bleiben erhalten.
> - Verschachtelte Dart-Blockkommentare und Zeilenkommentare werden berücksichtigt.
> - Normale und rohe Dart-Strings (auch dreifach quotiert) werden lexikalisch verfolgt; scheinbare Direktiven darin werden verworfen, Kommentarzeichen innerhalb der Strings behalten ihre ursprüngliche Bedeutung.
> - Bestehende Regeln für relative/package-, bedingte und part-of-URIs sowie Whitelist unverändert.
> - Keine App-/Backend-/Story-/Regel-/Persistenzänderung; keine SQLite-/JSON-Migration.
> 
> ## Neue Regressionen
> 1. Verbotener Story→Domain-Import unmittelbar nach Blockkommentar wird erkannt.
> 2. Verschachtelter Blockkommentar vor verbotenem `part of` wird erkannt.
> 3. Scheinbare Imports in Block- und verschachtelten Kommentaren bleiben ohne Fehlalarm.
> 4. Scheinbare Imports in gewöhnlichen und rohen mehrzeiligen Strings bleiben ohne Fehlalarm.
> 5. `//` innerhalb eines URI-Strings wird nicht als Kommentar behandelt.
> 6. Kommentarpräfix vor bedingtem Domain→Story-Import wird geprüft.
> 7. Reguläre lokale Imports und Parts nach Kommentaren bleiben erlaubt.
> 
> **Basis-main:** `a25b357372afe6a2ac3cce9c10bc56a7d9cc775c`.
> **Code-Commit:** `d57f6c0637e0ac34ab24d246655fa290b416cc91`.
> **Escape-Fix:** `450699851401a6074de6e69b121572c28df1f6ed`.
> **Konflikte:** Andere offene PRs bearbeiten diese zwei technischen Dateien nicht. Gemeinsame README-/Checkpoint-Dokumentation additiv und vor Integration abgleichen.
> 
> **CI-Status:** Der erste Code-Commit war fehlerhaft (Escaping) und sein CI-Lauf schlug fehl; der korrigierte Branch-HEAD befindet sich in erneuter CI. Kein Erfolg vor tatsächlichem Nachweis. PR bleibt Draft bis vollständige Python-/Backend-/Flutter-/Android-CI auf finaler SHA erfolgreich ist. Nicht-POSIX-Plattform-/Realgeräteprüfung offen.

---

### PR #385: feat(Chat A): Magic Missile Mehrziel-Schadensauflösung mit Shield und Resistenz

- Quelle: [#385](https://github.com/ManuEtt/Dnd/pull/385)
- Original-Branch: `feat/chat-a/magic-missile-volley-damage-20261029`
- Original-HEAD: `d8b7c4c035203da883510b7de90fa98cf9f8315f`
- Zum Snapshot: offen, nicht als kombiniertes Paket abgenommen
- Basis: `main`

**Originale PR-Beschreibung (historische Einzelaussagen, nicht Integrationsabnahme):**

> ## Ausgangsproblem
> PR #375 enthält die reine SRD-5.2.1-Geschossverteilung, ist aber noch nicht integriert. Für die spätere Mehrziel-Kampfaktion fehlen unabhängig davon eine **pro Kreatur** korrekte Schadensauflösung, Einzelgeschoss-Rundung und ein expliziter Shield-Status. Die bestehende Einziel-Engine darf hierfür nicht konfliktträchtig umgebaut werden.
> 
> ## Regelquelle
> Wizards of the Coast LLC, *System Reference Document 5.2.1*, CC BY 4.0: *Magic Missile* S. 146, *Shield* S. 161–162, *Resistance and Vulnerability* S. 17: https://www.dndbeyond.com/srd
> 
> ## Dieses Paket
> - Neue reine Domäne `srd_magic_missile_volley_damage_rules.dart` prüft 3–11 Geschosse (Slotgrad 1–9), eindeutige bestätigte Zielkennungen und explizite Shield- und Force-Verteidigungszustände.
> - Shield für eine Kreatur blockiert nur deren zugeteilte Geschosse und erfordert **keinen Schadenswürfel**. Für alle anderen Geschosse ist ein gültiger W4 zwingend.
> - Bestehender `EnemyForceDefenseRules.apply` rechnet pro Einzelgeschoss, nicht irrtümlich erst nach der Gesamtverteilung. Getrennte rohe/angewandte Zielschäden und Gesamtschäden; keine Statusänderung.
> - Defensive Ablehnung unbestätigter Entscheidungen, unbekannter/mehrdeutiger IDs, fehlender oder zusätzlicher Würfe und unpassender Geschosszahl.
> - Elf positive und negative deterministische Regressionstests inkl. Eingabe-/Ergebnis-Unveränderbarkeit.
> 
> ## Grenzen und Integration
> Keine neue ausführbare Kampfaktion, kein Rollback/Transaktionscommit, keine Ressourcenbuchung, keine erdachte Reaktion und keine Übernahme ungeprüfter KI-Werte. Zaubervorbereitung, Sicht, Reichweite, Aktionsökonomie, Reaktion und tatsächliche Zuordnung müssen zuvor separat bestätigt sein. `SPELL-MISSILE-MULTITARGET` bleibt **partial**. Fachdateien kollidieren nicht mit dem offenen PR #375 oder den SRD-Zauberbereichs-PRs #357/#361/#366/#367/#372. Gemeinsame `README.md`/`docs/CODEX_CHECKPOINT.md` sind bei der späteren Zusammenführung von Chat D additiv zu konsolidieren.
> 
> **Keine Migration:** SQLite 3 / äußeres Kampagnen-JSON 1 unverändert.
> 
> ## Testabnahme
> Lokal fehlen Dart/Flutter und Gerät; vollständige GitHub-Actions-Abnahme siehe unten. Keine automatische Integration nach `main`.
> 
> ## Finale CI-Abnahme auf dem unveränderten PR-HEAD (29.10.2026)
> 
> **Erfolgreich:** [Actions #40862398849](https://github.com/ManuEtt/Dnd/actions/runs/40862398849), `completed/success` auf genau `d8b7c4c035203da883510b7de90fa98cf9f8315f`.
> 
> - **206 Python-Tests**, **72 Backend-Tests**, **2.276 Flutter-Tests** (einschließlich elf neuer Regeltests), 20 gezielte Flutter-Widgettests.
> - **Dart-Formatierung:** 509 Dateien, keine Änderungen. Flutter-Analyse erfolgreich; Backend-Typecheck/Build erfolgreich.
> - **Android:** Debug-APK, native Tests und drei kleine Alpha-APKs erfolgreich; versioniertes Alpha-/Quellpaket bereitgestellt.
> - [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40862398849/artifacts/12892856882) · [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40862398849/artifacts/12893011428) · [Source-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40862398849/artifacts/12893031389) · [versioniertes Alpha-Paket](https://github.com/ManuEtt/Dnd/actions/runs/40862398849/artifacts/12893046199).
> - Die frühere CI scheiterte allein an der inzwischen exakt korrigierten Dart-Formatierung. Der temporäre CI-Diagnoseschritt wurde vollständig entfernt; final geändert bleiben genau zwei unabhängige Dart-Fachdateien sowie README, zentraler und Chat-A-Checkpoint.
> - **Nicht getestet:** reales Android-Gerät, historisches Installationsupgrade, TalkBack, Produktivsignatur. **Kein Merge**; gemeinsame Dokumentation durch Chat D additiv integrieren. Multi-Target-Ausführung bleibt **partial** bis zur kombinierten Integration mit #375.
> 

---

