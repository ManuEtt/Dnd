# Auftrag für genau einen begrenzten autonomen Codex-Zyklus

Dieses Dokument ergänzt den **aktuellen [Codex-Fortsetzungsprompt](CODEX_CONTINUATION_PROMPT.md)** und den **[lebenden Entwicklungscheckpoint](CODEX_CHECKPOINT.md)**. Es ist ein Leitfaden für manuell gestartete Codex-Sitzungen. Die automatische Codex-Entwicklung aus GitHub Actions wurde entfernt. Es erlaubt keine automatischen API-Käufe und keine unkontrollierten Änderungen an `main`.

Du arbeitest an **Würfelraunen – Der lebendige Spielleiter** im Repository `ManuEtt/Dnd` und erhältst einen Checkout des aktuellen Ausgangscommits. Dies ist **eine begrenzte, endliche Ausführung**, keine Endlosschleife.

1. Lies vor jeder Änderung `AGENTS.md`, `docs/CODEX_CHECKPOINT.md`, `README.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `DEVELOPMENT_STATUS.md`, `TESTING.md` und `CHANGELOG.md`. `docs/AUTONOMOUS_DEVELOPMENT_STATE.md` ist eine historische Übergabe, kein aktueller HEAD-Nachweis.
2. Prüfe `git status`, Version, vorhandene Implementierung und aktuelle bekannte CI-Probleme. Wähle **eine** überprüfbare Aufgabe. Buildfehler haben Vorrang.
3. Erhalte Datenformat, Spielstände, Tests, Regelgrenzen, bestehende Funktionen und vorhandene Assets. KI-Ausgaben dürfen bestätigte Spielwerte nicht verändern. Kein neues kostenpflichtiges Backend aktivieren.
4. Implementiere die kleinstmögliche korrekte Änderung und Regressionstests. Keine Tests deaktivieren, keine Notlösung durch erfundene Werte und kein Zugriff auf private Benutzerdaten. Nutze nur SRD-konformes Material.
5. Führe erreichbare lokale Prüfungen aus. Der reguläre `android-build.yml`-Workflow kann nach Git-Push oder manuell die vollständige unabhängige CI-Abnahme ausführen. Behaupte keine bestandenen Tests ohne Laufnachweis.
6. Aktualisiere **immer** `docs/CODEX_CHECKPOINT.md` mit tatsächlichem HEAD, Basis-Commit, PR, CI-Lauf/SHA, Teststatus, Blockern und genau einer nächsten Aufgabe; schreibe außerdem die kompakte Statussektion in `README.md` fort. Passe bei sachlichem Fortschritt `CHANGELOG.md` und gegebenenfalls `DEVELOPMENT_STATUS.md` an. Versionsnummern nicht für reine Dokumentation erhöhen.
7. Beende die Ausführung nach einem abgeschlossenen Arbeitspaket. Plane **kein** zweites großes Feature. Reserve für Abschluss und Dokumentation.
8. Verwende für Git-Pushes und Pull Requests nur die tatsächlich verfügbaren Rechte und einen ausdrücklich gewünschten Entwicklungsbranch. Keine Änderungen an `main` ohne Prüfung. Committe keine Geheimnisse, privaten Sicherungen oder Signaturschlüssel.

### Bei knappen Ressourcen oder Fehlern

Sichere einen konsistenten Dateistand und eine konkrete Fehlerbeschreibung in `docs/CODEX_CHECKPOINT.md` sowie eine kurze Statusnotiz in `README.md`. Stoppe neue Entwicklungen. Der reguläre GitHub-Actions-Workflow kann nach einem Push bei fehlgeschlagenen Tests zumindest einen Quell-Checkpoint erzeugen. Eine APK darf nur nach tatsächlich bestandener unabhängiger Prüfung als Alpha-Artefakt erscheinen. Kein Merge ohne menschliche Prüfung.
