# Würfelraunen – Checkpoint 28.10.2026

**0.8.46+96**, Main `6576d2fc742f000bacdd1c105282bc9e3282ae7e`, SQLite3 / JSON1.
[Operative Fortsetzung](docs/CODEX_CHECKPOINT.md) ·
[Abnahmen und Branchinventar](docs/BRANCH_MIGRATION_20261028.md).

**Main-CI bestanden:** [Lauf 40708407065](https://github.com/ManuEtt/Dnd/actions/runs/40708407065) auf `6576d2fc742f000bacdd1c105282bc9e3282ae7e`.

**28 alte Quell-/Integrationsbranches archiviert und entfernt.** Alle Köpfe sind Vorfahren des geprüften Main; die exakten Archivtags stehen im Inventar. `feat/srd-warlock-magical-cunning-20261028` (Beobachtung `2026-10-28T14:59:26.197499+00:00`: `47cb207e99eeba0af3308de2b88c19f8357b0808`, PR #352) entstand danach und bleibt als aktive, separat zu prüfende Entwicklung erhalten.

**IMPLEMENTIERT:** Gemeinsame Integration der vorhandenen Charakter-, Klassen-,
Story-, Ausrüstungs-/Sprung- und Tooling-Pakete. Behoben sind der reproduzierte
Altarchiv-CAS-Fehler, der Barden-Dialogüberlauf und Integrationskonflikte zwischen
Barden- und Mönchsinitiative. Bestätigte Attribut-, Klassen-, Hintergrund- und Talentbelege
bleiben getrennt; Audit und Kataloge erteilen keine erfundenen Vorteile.

**GETESTET:** 2.185 Flutter-, 195 Python- und 72 Backend-Tests in der finalen
PR-CI; zusätzlich 20 gezielte UI-Prüfungen. Lokale Vollsuite, Formatierung von
500 Dart-Dateien, Analyzer, Backend-Build, Android-Debug-Build und zwölf native
Android-Tests bestanden. Genaue Commits und Main-Abnahme siehe Nachweistabelle.

**NICHT GETESTET:** Echtes Android-Gerät, TalkBack auf Gerät, Upgrade einer alten
installierten APK mit vorhandener Datenbank und produktive Signierung.

**BLOCKIERT:** Kein angeschlossenes Android-Testgerät. Die aktive parallele
Hexenmeister-Arbeit benötigt eine eigene fachliche und CI-Abnahme.

**NOCH NICHT IMPLEMENTIERT:** Vollständiger Charakter-Wizard mit allen Pflichtwahlen
und sämtliche SRD-Wirkungen. Magieinitiierter bestätigt bisher Zauberwahl und
Zauberattribut, nicht das vollständige Wirken. Wilder Angreifer besitzt dauerhafte
Würfelbelege und eine Entscheidungsvorprüfung, noch keinen durchgängigen
Angriffs-/Schadensabschluss. Entrinnen-Vorprüfung ist keine TP-Buchung.

**Nächster Schritt:** Drei Heilige-Symbol-Katalogvarianten für Kleriker/Paladin
explizit wählen und mit UI, Inventar und Klassenbeleg dauerhaft speichern;
Version-1-Altnachweise lesbar halten, keine erneute Gold-/Paketvergabe.
Akzeptanz und konkrete Tests stehen im operativen Checkpoint.
Original dieses Dokuments: [Historienmanifest](docs/history/migration_abschluss_20261028/MANIFEST.json).
