# Codex-Checkpoint – Gesamtintegration zu Issue #425

> **Paralleler CHAT-C-Entwicklungsbranch (31.10.2026):**
> [Draft-PR #447](https://github.com/ManuEtt/Dnd/pull/447) schützt die
> Flutter-Kampfchronik vor der Anzeige unbestätigter Treffer-/Schadensdetails
> bei einer offenen Schildreaktion. Neue Widgettests für 320/360 dp,
> 200 % und Semantics hinzugefügt, aber bis zur erfolgreichen GitHub-CI nicht
> als bestanden melden. Code-HEAD `5f951e9b06b08956e9d86fa084b53699964f06c7`;
> eigenes Detailprotokoll in `docs/parallel/CHAT_C_CHECKPOINT.md`.
> PR #445 bearbeitet ebenfalls zentrale Dokumentation: vor Merge
> konfliktfrei konsolidieren, bestehende Integrationseinträge erhalten.


Stand: 30.10.2026, UTC. Produkt **Würfelraunen – Der lebendige Spielleiter**,
Alpha **0.8.49+99**. Dieser neue Live-Status ersetzt widersprüchliche historische
Momentaufnahmen; die vollständige additive Vereinigung ist bytegenau unter
`docs/history/migration_20261030/` archiviert, samt Manifest.

- **Auftrag:** alle vorhandenen Entwicklungsbranches fachlich geprüft migrieren,
  Integrationsfehler beheben, anschließend gesichert bereinigen und #425 lösen.
  Die ausdrückliche Nutzerweisung erweitert den bisherigen Chat-A-Bereich.
- **Basis-main:** `6465a4b2fc8d42ae7aab596ac26e85d61d2b8f49`.
- **Branch:** `integrate/all-branches-issue425-20261030`.
- **Kombinierter Fachstand:** `b0a4211c` (vollständig über Git auflösen).
  Aktuelle PR-/Main-SHAs und finale CI im Integrations-PR prüfen, keine
  erfolgreiche Main-Integration aus diesem Vorab-Checkpoint ableiten.
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

Kombinierte `bash scripts/check.sh`, Android-Debug-/native und GitHub-Prüfungen
werden im laufenden Integrationszyklus ausgeführt. Erst beobachtete Endergebnisse
hier bzw. im PR als erfolgreich fortschreiben.

## NICHT GETESTET

Reales Android-Gerät, TalkBack, tatsächliches Altversionsupgrade, produktive
Release-Signierung und echter externer KI-/Sprachbetrieb. Eine gebaute APK
ersetzt diese Abnahmen nicht.

## BLOCKIERT

Vor Main-Übernahme vollständige kombinierte CI abwarten; danach frische Main-CI
und erst dann Archiv-/Head-/Ancestry-/PR-Schutz für Branchlöschung prüfen.
Kein Zugriffs-/SDK-Blocker, aber kein angeschlossenes Android-Testgerät.

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
öffentliche Downloads erst aus tatsächlich fertiggestellten Prüfläufen verlinken.

1. Main, alle offenen PRs, Branches und jüngste CI erneut live prüfen.
2. Gesamtintegrations-PR und Report lesen; bereits übernommene Features nicht
   neu entwickeln oder alte Patches erneut auf Main anwenden.
3. Prüfungen: `bash scripts/check.sh`, Debug-Build, native Gradle-Tests und finale
   PR-/Main-CI; aktuelle Fehler zuerst beheben.
4. Ausschließlich nach allen Gates originale unveränderte integrierte Branches
   archiviert löschen, entfernte Remote-Refs und passende Tags frisch nachweisen.
5. Keine Hintergrundausführung oder automatische Wiederaufnahme behaupten.

**Genau ein nächstes Entwicklungspaket nach Integrationsabschluss:** normale
Mehrklassen-Zauberplätze für bestätigte SRD-Klassenaliasnamen kanonisieren.
Akzeptanz: `Wizard`/`Magier` und andere erlaubte Caster-Aliase ergeben identische
Slots; Pact Magic bleibt separat; unbekannte Namen werden nicht geraten;
Domain-/Speicher-/Retry-Regression und finale CI. Zuvor neue Parallel-PRs abgleichen.
