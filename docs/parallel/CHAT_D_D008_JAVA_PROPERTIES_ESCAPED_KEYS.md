## Aktualisierung nach D-007 (26.10.2026)

Neuer Main-Stand `0212e99b6222f9fcae0714a2ee09123c3c78347c` nach vollständig erfolgreicher Integration von PR #215. Der alte D-008-Head `06c0acd8e0739db80847f0f1fcb9abfb5d7ee484` wurde mit dem aktuellen Main in einem **nicht-erzwungenen** Merge-Commit synchronisiert. Die acht gezielten Parser-Regressionstests haben im früheren Lauf bestanden; vollständige CI-Abnahme auf dem neuen Commit folgt. Die ursprünglichen D-008-Anforderungen und Testergebnisse unten bleiben erhalten.

---

# Chat D – D-008: Escapte Java-Properties-Schlüssel sicher erkennen

**Datum:** 26.10.2026  
**Projekt:** Würfelraunen – Der lebendige Spielleiter  
**Bereich:** CI-/Gradle-Integrität, keine App-Regel-/Story-/Datenänderung  
**Ausgangs-main:** `e903ae38c6ae99abfa99a432e7f7777f0eee853f`  
**Branch:** `fix/chat-d/gradle-java-property-escaped-keys-20261026`

## Problem und Sicherheitsgrenze

Java-`Properties` unterstützt mit Backslashes escapte Schlüsselnamen (`distribution\\u0055rl`), Unicode-escapte Buchstaben und per ungerader Anzahl abschließender Backslashes über mehrere physische Zeilen fortgesetzte Einträge. `unique_gradle_property` aus D-005 zählte bisher nur unescapte, einzeilige Schlüsselnamen. Ein zusätzlich kodierter `distributionUrl`- oder `distributionSha256Sum`-Eintrag konnte dadurch bei der Projektvalidierung unerkannt bleiben, während Gradle einen anderen Effektivwert lädt.

## Implementiert

- `scripts/verify_project.py`: `_gradle_logical_lines` baut fortgesetzte Java-Properties-Zeilen vor der Schlüsselerkennung zusammen, ohne unescapte Werte zu verändern.
- `_decode_java_property_key` interpretiert `\\uXXXX`, einfache Backslash-Escapes, `\\t`, `\\r`, `\\n` und `\\f` für den Keyvergleich.
- `unique_gradle_property` findet damit sämtliche effektiv gleichen sicherheitsrelevanten Schlüssel und weist doppelte oder uneindeutige Angaben wie vorher fail-closed zurück. Die bestehende HTTPS-/Version-/SHA256-Formatprüfung bleibt unangetastet.
- Acht neue Regressionen in `scripts/tests/test_verify_project.py`: kodierter URL-Key, kodierter SHA256-Key, einfacher Escape, Zeilenfortsetzung, abweichender escapeter Doppelpunkt-Key, einzelne gültige kodierte Deklaration, Kommentare sowie gerade Backslash-Anzahlen ohne Fortsetzung.

## Tests

**GETESTET:** Alle acht neuen Regressionstests haben im GitHub-Actions-Lauf [#40283160431](https://github.com/ManuEtt/Dnd/actions/runs/40283160431) auf Code-/Test-Commit `430940553d4f9aa2e1226f96b293a2fca845fc0c` einzeln `ok` gemeldet. Die vollständige Python-Suite scheiterte **an drei bestehenden Quell-ZIP-/Checkpoint-Regressionsfehlern**, nicht an diesen acht Tests. Die unmittelbare Python-Testqualität der neuen Parserfälle ist deshalb belegt, die Gesamt-Abnahme nicht.

**BLOCKIERT:** D-007 repariert die Quell-ZIP-/Checkpoint-Baseline in [PR #215](https://github.com/ManuEtt/Dnd/pull/215); dieser PR benötigt selbst reguläre grüne Flutter-/Android-CI. D-008 soll erst nach diesem Main-Fix neu mit Main synchronisiert und vollständig geprüft werden.

**NICHT GETESTET:** vollständige CI und Release/APK auf finalem D-008-Commit sowie reale Geräteinstallation.

**NOCH NICHT IMPLEMENTIERT:** vollständige Java-Properties-Neuimplementierung jenseits der beiden konkret sicherheitsrelevanten Gradle-Distributionsparameter; kein Eingriff in die echte `gradle-wrapper.properties`-Datei.

## Persistenz und nächster Schritt

Keine Änderung an SQLite, JSON, SRD-Spielmechanik, NPC-Stories, Android-App-Quellen oder Spielstandmigration. Nach grüner Integration von D-007 `main` synchronisieren, finale Python-/Backend-/Flutter-/Android-CI auf neuer Commit-SHA abnehmen und eigenständigen D-008-PR erstellen.

**Genau ein nächster Schritt:** D-007-Integrations- und GitHub-CI nachweisen, anschließend D-008 synchronisieren und vollständige Abnahme starten.
