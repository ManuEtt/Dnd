# CHAT C – Android und Fantasy-UI

## Chat C – Zyklus C-002: Zauber-Restdauer korrekt deklinieren (26.10.2026)

- **Ausgangs-`main`:** `12e2df634c1f60e972681cef4ca08b41e2d29410`
- **Branch:** `fix/chat-c/spell-effect-countdown-20261026`
- **Letzter technischer Commit:** `9e204e146dbbf35f2f226d1fbb5f487619b35c7d` (anschließende Dokumentationscommits auf demselben Branch)
- **Pull Request:** zugeordnet nach Erstellung; Branch aktuell noch nicht in `main`.
- **Problem:** `FantasyEffectWard._spellDuration` zeigte bei genau einem bestätigten eigenen Zugende fälschlich den Plural „noch 1 eigene Zugenden“; frühere Tests prüften nur vier verbleibende Zugenden.
- **Akzeptanz:** 1 Ende = „noch 1 eigenes Zugende“; mehrere Enden = korrekter Plural; fremde/nicht bestätigte Begegnungen = keine spekulative Restzeit; gespeicherte Zaubereffekte bleiben unverändert.
- **Änderungen:** `app/lib/ui/fantasy_effect_ward.dart`; `app/test/confirmed_spell_effect_widget_test.dart`; `README.md`; `docs/CODEX_CHECKPOINT.md`; dieser Checkpoint.
- **Tests hinzugefügt:** zwei bestätigte Widgetfälle für 320/360 dp mit 200 % Systemschrift, jeweils Singular, Plural und unverändertes Hero-JSON; ein Negativtest für eine fremde Begegnung.
- **GETESTET:** Neuer Code noch nicht per CI geprüft. Lokales Flutter-/Dart-SDK nicht vorhanden; kein Android-Gerätetest.
- **BLOCKIERT:** Keine lokale Flutter-Ausführung; vollständige Prüfung über CI nötig. Shared-Dokumentationspfade erfordern Integrationskoordination.
- **Migration:** keine. Unveränderte Regel-/RNG-/Kampfdaten, SQLite, JSON und Schnittstellen.
- **Koordination:** Bei Branch-Anlage kein offener PR zu den beiden technischen Dateipfaden. Main und offene PRs vor Merge erneut prüfen. Kein direktes `main`-Update und kein Merge.
- **Voriger Zyklus C-001:** PR [#245](https://github.com/ManuEtt/Dnd/pull/245) mit vollständig erfolgreicher CI [#40375552456](https://github.com/ManuEtt/Dnd/actions/runs/40375552456) auf `8fa2a2166e3681605e5610cb7c93dc0fae8a5fa0`, ready for review, **noch nicht gemergt**. Realgerätetest offen.
- **Nächster konkreter Schritt:** vollständige GitHub-CI des neuen Branch-HEADs abnehmen, Format/Analyse/Tests/Debug-APK korrigieren und PR erst nach grünem Lauf zur Integration freigeben.


**Stand:** 2026-10-25 (Europe/Berlin)  
**Zusätzlich nachgezogener Main-Stand:** `97a06118f17d71cc77be2cb15a2fc9a53db20ee0` (enthält Chat D PR #177, dessen zusätzliche CI-Gates; alte Dokumentation bewahrt)  
**Nachgezogener Main-Stand:** `fb788a980b8ee9eb60439c249f3e1f5092a9f188` (enthält PR #176; Merge ausschließlich auf dem Feature-Branch)  
**Basis-Main-SHA:** `5c1499a9342449050bb946542659b221ac2653da`  
**Branch:** `fix/chat-c/npc-chronicle-fallback-20261025`  
**Letzter überprüfter Code-/Testcommit:** `65fbfc21ab347f4e4dd1d57bbd08a58304bd7c40`  
**Pull Request:** [#178 – NPC-Chronik absturzsicher anzeigen](https://github.com/ManuEtt/Dnd/pull/178) (offen, keine Main-Integration)

## Ausgangsproblem und Akzeptanzkriterien

`CampaignMemoryPanel` wertete NPC-Beziehungsnotizen mittels `firstWhere` aus. Ist die referenzierte NPC-ID nicht in `campaign.npcs` enthalten, wirft die UI beim Rendern eine `StateError`-Ausnahme. Die Oberfläche soll auch unvollständige/historische In-Memory-Daten lesbar machen, ohne Spielzustände oder die Importvalidierung zu verändern.

Akzeptanz:
- Vorhandene NPCs behalten ihren gespeicherten Namen.
- Fehlt ein referenzierter NPC, erscheint die eindeutige neutrale Anzeige `NPC nicht mehr vorhanden` neben den unveränderten gespeicherten Beziehungsdaten.
- Ein vollständiger NPC-Ausfall lässt die Anzeige nicht abstürzen; die Bearbeitungsaktion bleibt bei leerer NPC-Liste deaktiviert.
- Keine Mutation von `Campaign`, keinem JSON, SQLite-Schema, Regel- oder Story-Zustand.

## IMPLEMENTIERT

- `app/lib/ui/campaign_memory_panel.dart`: sichere Auflösung von NPC-Anzeigenamen über eine lokale Map mit neutralem Fallback.
- `app/test/campaign_memory_panel_test.dart`: zwei zusätzliche Widgettests für gemischte gültige/verwaiste Referenzen sowie komplett fehlende NPC-Stammdaten.

## Abnahme nach Synchronisierung mit main

- **Feature-/Merge-Commit mit vollständig grüner CI:** `0500ce52ce88eda8a1e7d1259293ce5530327d22`.
- **GitHub Actions:** [#40218237100](https://github.com/ManuEtt/Dnd/actions/runs/40218237100), `completed/success`.
- **Bestanden:** Python-Paket-/Strukturtests; Backend-Typecheck, Build und Tests; Dart-Formatierung; Flutter-Analyse; gezielte Fantasy-Dialogtests; vollständige Flutter-Testsuite; Android-Debug-APK; native Android-Dateisicherungstests; kleine Alpha-APKs; CI-Quell-Checkpoint. Die beiden neuen Widgettests wurden mit der vollständigen Suite geprüft.
- **Artefakte:** [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12608841640), [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12609515426), [Quellarchiv](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12609101293). Keine reale Installation behauptet.
- **Versionsstand nach PR #176:** `0.8.40+90` (aus main übernommen); SQLite 2, JSON 1 unverändert.
- **Nicht getestet:** Realgerät, produktive Signierung, manuelles Tastatur-/Barrierefreiheitsszenario. Die separat benannten Domain-Boundary-/SRD-Coverage-Kommandos wurden durch diesen Workflow nicht als eigenständige Schritte nachgewiesen.
- Die älteren Angaben unterhalb dokumentieren den damaligen Vor-CI-Zustand.

## GETESTET

- Live-GitHub-Basis und offene PRs geprüft: bei Arbeitsbeginn `main` wie oben, nur [PR #176](https://github.com/ManuEtt/Dnd/pull/176) offen. Sein Dateiumfang wurde mit den betroffenen UI-/Testdateien abgeglichen: keine Codeüberschneidung.
- GitHub-Diff und veröffentlichte Code-/Teständerungen auf eigenem Branch erneut gelesen; kein vollständiger Testlauf daraus abgeleitet.

## NICHT GETESTET

- Flutter/Dart-Formatierung, `flutter analyze`, gezielter Widgettest und Gesamt-`flutter test`; Android-Debug-APK und echtes Android-Gerät.
- Python-Projekttests und Backend-Checks in dieser Sitzung ebenfalls nicht ausgeführt.
- Branch- und PR-CI müssen anhand des finalen Head-SHA ausgewertet werden; keine erfolgreiche Abnahme vorweggenommen.

## BLOCKIERT

- Hier keine Flutter-/Dart-/Android-SDKs und kein direkter GitHub-Checkout via Container-Netzwerk. Prüfung über GitHub Actions erforderlich.
- Paralleler PR #176 ändert `README.md` und `docs/CODEX_CHECKPOINT.md`; dortige Zusatzdokumentation darf bei der späteren Integration nur bewusst konsolidiert werden.

## NOCH NICHT IMPLEMENTIERT

- Keine Änderung an Importvalidierung oder Datenspeicherung (diese lehnt verwaiste NPC-Verweise weiterhin ausdrücklich ab).
- Kein KI-/Regel-/Kampagnenverhalten verändert. Keine neue Version; Basis `0.8.39+89`, SQLite-Schema 2/JSON 1.

## NÄCHSTER SCHRITT

**Unabhängiges UI-Paket:** `FantasyAdventureStatusHud` bei 320 dp und 200 % Textskalierung auf ausreichende Beschriftung sowie Screenreader-Erkennbarkeit prüfen. Akzeptanz: keine Flutter-Overflows; TP, RK, Tempo und EP sind weiterhin unterscheidbar; kein erfundener unbekannter Wert; mindestens ein negativer/positiver Widgettest; keine Regel-/Persistenzänderung.

## Synchronisierung 25.10.2026 – Hauptbranch nach Sicherheitsprüfungen

- **PR #178:** UI-Dateien und zwei Widgettests unverändert, bisheriger GitHub-Lauf [#40219700324](https://github.com/ManuEtt/Dnd/actions/runs/40219700324) auf `907d665a38db150684d290314120765d8d651eb4` erfolgreich (`completed/success`).
- **Neuer main:** `af70a48c84d83c133ced4200be04ca81a91abf1b`; integrierte Chat-D-Änderungen an Gradle-/APK-/Python-Prüfungen behalten. README und zentraler Checkpoint bewusst konsolidiert.
- **Weiterhin offen:** kombinierte CI des neuen Merge-Commits und Realgerät/TalkBack/Produktionssignierung. Keine Schema- oder Regeländerung.

## Nachzug nach erfolgreichem HUD-Merge PR #185

- `main` `5f9a01dd73f68ad4f9e226f859a8ca87803b8337` hat PR #185 integriert. Chat-C-PR #178 betrifft ausschließlich die unabhängige `campaign_memory_panel.dart`/Tests, keine Überschreibung von `fantasy_adventure_hud.dart`.
- Früherer vollständiger CI-Beleg [#40219700324](https://github.com/ManuEtt/Dnd/actions/runs/40219700324); erneute kombinierte CI nach diesem Merge ausstehend. Keine JSON-/SQLite-Migration, keine reale Geräteprüfung.
