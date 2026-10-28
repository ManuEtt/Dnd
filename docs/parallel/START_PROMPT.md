# Kurzer Startprompt für parallele Entwicklungs-Chats

Verwende diesen Prompt in **vier unabhängigen Chats**. Ersetze `A` jeweils durch `B`, `C` oder `D`. Der folgende Chat-Buchstabe ist verbindlich und ersetzt den Platzhalter im Masterprompt.

## Kopiervorlage

> Entwickle das Projekt **Würfelraunen – Der lebendige Spielleiter** selbstständig weiter.
>
> Repository: https://github.com/ManuEtt/Dnd
>
> **CHAT-KENNUNG: A**
>
> Lies vollständig `docs/parallel/MASTER_PROMPT.md` und befolge die dort festgelegten Regeln. Meine Chat-Kennung bestimmt verbindlich deinen Aufgabenbereich.
>
> Prüfe den aktuellen Main-Stand, alle offenen PRs, ihre geänderten Dateien, CI-Ergebnisse, die Projektdokumentation und den Quellcode. Wähle danach das wichtigste noch offene, konfliktfreie und überschaubare Entwicklungspaket aus deinem Bereich.
>
> Implementiere und teste es. Arbeite ausschließlich auf einem eigenen Branch, erstelle einen PR gegen `main` und dokumentiere Änderungen, Tests, Blocker und den nächsten Schritt in `docs/parallel/CHAT_<KENNUNG>_CHECKPOINT.md`. Überschreibe keine fremden Änderungen, merge nichts ungeprüft und lösche keine fremden Branches.
>
> Arbeite innerhalb dieser aktiven Sitzung eigenständig und beginne direkt mit der Repository-Prüfung. Behaupte keine Hintergrundarbeit und keine unbestätigten Testerfolge.

## Aufgabenbereiche

- **A – Regelwerk:** SRD 5.2.1, Regeln, Kampf, Klassen, Zauber und deterministische Tests
- **B – KI-Spielleitung:** Abenteuer, Kampagnen, NPCs, Quests, Erinnerungen und Storyzustände
- **C – Android und Flutter:** Fantasy-UI, Charaktererstellung, Bedienbarkeit und Widgettests
- **D – Stabilität und Integration:** Builds, CI, Persistenz, Migrationen, Regressionstests und PR-Koordination

**Startreihenfolge:** Zuerst diesen Dokumentations-PR nach Prüfung in `main` übernehmen. Anschließend in vier Chats mit je einer eigenen Kennung starten. Alle Chats berücksichtigen parallel existierende PRs und arbeiten unabhängig voneinander.
