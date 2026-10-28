## Aktueller Charakterstand – 28.10.2026, Alpha 0.8.47+97

**IMPLEMENTIERT:** Im Klassenpaket A wählen Kleriker und Paladin ausdrücklich
Amulett, Emblem oder Reliquiar. Typisiertes Inventar und lesender Audit verwenden
die bestätigte Variante. Neue Klassenbelege sind Version 2; historische Version 1
bleibt lesbar, unverändert und ohne Nachvergabe. Goldalternativen enthalten kein
Symbol. Erneute Bestätigung verdoppelt keine Gegenstände oder Gold; die erneute
Auswahl desselben Pakets verliert keine bereits getroffene Symbolentscheidung.
[Regelquelle und Fachnachweis](docs/CHARACTER_HOLY_SYMBOL_CHOICE_20261028.md).

**GETESTET:** Vollständiges `bash scripts/check.sh` auf Produktcode
`7ac32b1cb9e63ce35eb458d87e4b84d86526706a`: **2.265 Flutter-, 200 Python- und
72 Backend-Tests**, 507 Dart-Dateien unverändert formatiert, Analyzer und
Backend-Build erfolgreich. Android-Debug-APK gebaut, Metadaten und v2-Testsignatur
geprüft; **zwölf native App-Tests** gemäß CI bestanden. Gezielt zudem 16
Symbol-Dialog-, 13 Editor- und 16 SQLite-Speicherfälle bestanden, einschließlich
beider Klassen, aller Varianten, alter Belege aller zwölf Klassen, Neustart,
JSON-Import, ungültiger IDs, Retry und veralteter Revision. Widgetabnahme bei
320/360 dp, 200 % Schrift, simulierter Tastatur und Semantik; kein Gerätetest.
Die abschließende Dokumentation ändert gegenüber diesem Code keine Produktdateien.

**NICHT GETESTET:** echtes Android-Gerät/TalkBack, Upgrade einer installierten
Altversion und produktive Signatur. **BLOCKIERT:** kein angeschlossenes Testgerät.
Ein zusätzlicher Aufruf sämtlicher Fremdplugin-Unterprojekttests scheiterte an
ByteBuddy/Jetifier (Java-Klassenmajor 68); das im CI vorgeschriebene
`:app:testDebugUnitTest --no-daemon` besteht mit zwölf Tests. Dieser zusätzliche
Fehllauf wird nicht als bestanden ausgegeben. **NOCH NICHT IMPLEMENTIERT:**
vollständiger Wizard und alle übrigen Pflichtwahlen; Symbolbesitz bestätigt
keine vollständige Fokus-/Zauberwirkungsautomatik. SQLite 3 / äußeres JSON 1
unverändert, keine Migration. `EQUIP-CHOICES` bleibt ausdrücklich `partial`.

Arbeitsbranch `feat/character-holy-symbol-choice-20261028`, Main-Basis
`37a6142ea791a607c78065b50aa66fda90acda5c`, [PR #369](https://github.com/ManuEtt/Dnd/pull/369).
Die zusätzliche vollständige GitHub-Abnahme und tatsächlichen Artefakte sind
anhand des **aktuellen** [PR-Checklaufs](https://github.com/ManuEtt/Dnd/pull/369/checks)
zu beurteilen; der PR-Abnahmebericht hält die konkrete Run-ID und SHA fest.
Der initiale doppelte Pushlauf 40756156487 wurde bewusst beendet; ältere
Zwischenläufe sind keine Abnahme des abschließenden PR-Kopfs.

Nächster kleiner Charakter-Schritt: Mönch-Werkzeugübung ausdrücklich mit der
Paketwahl koppeln, nach SRD S.49. Versionierte Entscheidung, bestehende Belege
v1/v2 bewahren, keine Nachvergabe; Domain-/UI-/SQLite-/Import-/Doppelübungsfälle
und vollständige Prüfkette nachweisen. Gesamte Charaktererstellung bleibt offen.
Ältere Berichte unten sind historische Schreibstände.

---

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
