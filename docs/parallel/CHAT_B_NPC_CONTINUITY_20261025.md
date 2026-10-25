# Chat B – NPC-Kontinuität (25.10.2026)

## Ausgangslage und Koordination
- Repository: `ManuEtt/Dnd`
- Ausgangs-`main`: `fb788a980b8ee9eb60439c249f3e1f5092a9f188` (PR #176 bereits integriert).
- Branch: `feat/chat-b/npc-continuity-20261025`
- Offene fremde PRs bei Auswahl: #177 (CI), #178 (NPC-UI), #180 (Zauberdauer). Eigener vorheriger PR #179 (Recall-Absicht) noch offen.
- PR #179: GitHub Actions #40217711273 `completed/success` auf `7778df9081e7c053599a9e7a05cd1235943f7056`; **nicht** in `main` integriert.
- Kein gemeinsamer Story-Quellpfad mit PR #179, kein UI-Code aus PR #178 geändert. Gemeinsame Dokumentationspfade sind zur Integration durch Chat D zu konsolidieren.

## Problem
Persistierte NPC-Beziehungsnotizen werden zwar gespeichert und innerhalb des allgemeinen Lexikalabrufs bewertet, aber es fehlt ein eigenständiger, auf eine bestätigte NPC-ID begrenzter, zeitlich stabiler, schreibgeschützter Kontext für eine spätere narrationssichere Kampagnenfortsetzung über mehrere Sitzungen. Ein neues Kapitel darf nicht unbestätigte Prosa als Beziehungstatsache übernehmen.

## Akzeptanzkriterien
1. Bekannte NPC-ID liefert aktuelle bestätigte Identität, Lebensstatus, Beziehung und jüngste persistierte Notizen aus demselben Kampagnenobjekt.
2. Auswahl ordnet nach `recordedAt` absteigend, bei identischen Zeitstempeln stabil nach späterer Protokollposition. Limit 1–20.
3. Fremde NPC-Notizen, freie Szene, Dialoge und unbestätigte KI-Texte gelangen nicht in diese Projektion.
4. Unbekannte/mehrdeutige NPC-IDs und ungültige Grenzen werden abgelehnt.
5. Alte JSON-Spielstände ohne optionales Notizfeld bleiben ladbar. Aktuelle bestätigte Änderungen erscheinen nach JSON-Roundtrip unverändert.
6. Kein Regel-/Quest-/Inventarzustand wird verändert, keine neue Persistenzmigration.

## Implementiert
- `app/lib/story/npc_continuity_reader.dart`: `NpcContinuityReader.read` und unveränderliche `NpcContinuitySnapshot` einschließlich deutscher `confirmedContext`-Projektion. Zeilenumbrüche gespeicherter Texte für Kontextausgabe neutralisiert, keine Provider- oder Regel-Aufrufe.
- `app/lib/story/story_api.dart`: Die neue Typ/API ist ausschließlich im bestehenden öffentlichen Story-Modul exportiert.
- `app/test/npc_continuity_reader_test.dart`: sechs Tests für zeitlich geordneten Sitzungsübergang, Gleichstand, unbestätigte Prosa, Fehlerfälle, Legacy-JSON/echte Bestätigung und Ein-Zeilen-Kontext.
- Keine Änderungen an `story_memory_engine.dart` (PR #179), `game_engine.dart`, `models.dart`, `game_controller.dart`, UI oder Datenbank.

## Teststand
- **Erstellt:** Testdatei mit sechs Fällen; Schreibzugriff zu GitHub bestätigt.
- **Nicht lokal ausgeführt:** `flutter` und `dart` fehlen in der verfügbaren Containerumgebung. Kein vollständiger Repository-Checkout für Python-/Backend-Tests.
- **Neue GitHub-CI:** Status erst nach dem PR und abschließenden GitHub-Lauf als erfolgreich oder fehlerhaft ausweisen. Andere grüne Commits sind kein Nachweis.
- **Nicht geprüft:** Installation auf Android-Gerät, echte Erzähler-Provider-Anbindung, alte Gerätesicherungen, Release-Signierung.

## Migration, Risiken, offene Punkte
- SQLite 2, Kampagnen-JSON 1 und Android-Version unverändert. Nur vorhandene bestätigte Modellfelder werden gelesen.
- Der Kontext ist eine sichere lokale **Quellenauswahl**, keine semantische KI-Faktenprüfung und noch nicht in automatisches Prompt-Building integriert.
- Schnittstellen und Model-Revisionen bleiben unberührt.
- Ausstehende PR/CI-Integration und gemeinsame README-/Checkpoint-Konsolidierung durch Chat D beachten.

## Genau ein nächster Schritt
In einem weiteren eigenständigen Story-PR die neue NPC-Kontinuitätsprojektion als optionalen, strikt begrenzten Narrationskontext an die bestehende Storyvorbereitung anbinden. Akzeptanz: nur nach expliziter NPC-ID, keine Überschreitung von Antwort-/Kontextgrenzen, bestätigter lokaler Regelzustand unverändert, mindestens ein Provider-Mock- und ein Negativtest. Zuerst Überschneidungen mit dann offenen PRs prüfen.


## GitHub-Nachtrag zum Entwicklungszyklus
- Pull Request: [#181](https://github.com/ManuEtt/Dnd/pull/181) gegen `main`, weiterhin **nicht gemergt**.
- Implementierung `ef0e7978e03d82b0f73d6b1a8944c7d356a646e9`, Story-API `b4f9337b8d284b945fe67068712814e68b266c08`, Testdatei `9d2b7e12275c9f7ed054dcbfec942bad297ac22e`.
- Ursprüngliche GitHub-CI #40219009241 und #40219188924 meldete ausschließlich am Schritt „Dart-Formatierung prüfen“ einen Fehler in der neuen Testdatei. Die vorübergehende dedizierte Diagnose-CI #40219405615 zeigte den genauen Formatter-Diff und lief erfolgreich, ist **keine Gesamtabnahme**.
- Exakter Formatfix `f4eced4040618a5f7e76dc95a49daa25b7dab6f4`. Die temporäre Diagnose-Workflowdatei wurde anschließend mit `24470a5cc612aed9313a06400fffee9afbb67c9b` vollständig entfernt.
- Inzwischen wurde Chat-D-PR #177 nach `main` integriert (neuer Live-Main-HEAD `97a06118f17d71cc77be2cb15a2fc9a53db20ee0`). Neuer PR #182 von Chat D ändert ausschließlich Python-Grenzprüfungen sowie gemeinsame Dokumentation. **Keine Quellcode-/Testpfad-Überschneidung**; README und zentraler Checkpoint müssen bei Integration konsolidiert werden.
- Finale vollständige CI am letzten eigenen Dokumentationscommit steht aus und wird nur bei sichtbarem Erfolg als bestanden ausgewiesen. Tests/Android-Ergebnisse der Main-CI dürfen nicht diesem PR zugeschrieben werden.
