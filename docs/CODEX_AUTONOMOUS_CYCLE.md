# Auftrag für genau einen begrenzten autonomen Codex-Zyklus

Dieses Dokument wird ausschließlich durch den **explizit freigeschalteten** GitHub-Actions-Workflow geladen. Es erlaubt keine automatischen API-Käufe und keine Änderungen an `main`.

Du arbeitest an **Würfelraunen – Der lebendige Spielleiter** im Repository `ManuEtt/Dnd` und erhältst einen Checkout des aktuellen Ausgangscommits. Dies ist **eine begrenzte, endliche Ausführung**, keine Endlosschleife.

1. Lies vor jeder Änderung `AGENTS.md`, `README.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `DEVELOPMENT_STATUS.md`, `TESTING.md`, `CHANGELOG.md` und, falls vorhanden, `docs/AUTONOMOUS_DEVELOPMENT_STATE.md`.
2. Prüfe `git status`, Version, vorhandene Implementierung und aktuelle bekannte CI-Probleme. Wähle **eine** überprüfbare Aufgabe. Buildfehler haben Vorrang.
3. Erhalte Datenformat, Spielstände, Tests, Regelgrenzen, bestehende Funktionen und vorhandene Assets. KI-Ausgaben dürfen bestätigte Spielwerte nicht verändern. Kein neues kostenpflichtiges Backend aktivieren.
4. Implementiere die kleinstmögliche korrekte Änderung und Regressionstests. Keine Tests deaktivieren, keine Notlösung durch erfundene Werte und kein Zugriff auf private Benutzerdaten. Nutze nur SRD-konformes Material.
5. Führe erreichbare lokale Prüfungen aus. Der separate Workflow führt zusätzlich die vollständige unabhängige Abnahme aus. Behaupte keine bestandenen Tests ohne Laufnachweis.
6. Aktualisiere `docs/AUTONOMOUS_DEVELOPMENT_STATE.md` mit tatsächlichem Stand, Basis-Commit, Teststatus, Fehlern und der nächsten konkreten Aufgabe. Passe bei sachlichem Fortschritt `CHANGELOG.md` und gegebenenfalls `DEVELOPMENT_STATUS.md` an. Versionsnummern nur bei geprüften neuen installierbaren Fassungen erhöhen.
7. Beende die Ausführung nach einem abgeschlossenen Arbeitspaket. Plane **kein** zweites großes Feature. Reserve für Abschluss und Dokumentation.
8. **Keine Git-Pushes, keine PR-Erstellung und keine Branch-Manipulation aus Codex heraus.** Der getrennte Veröffentlichungsjob besitzt die GitHub-Schreibrechte; Codex selbst nicht. Committe keine Geheimnisse, privaten Sicherungen oder Signaturschlüssel.

### Bei knappen Ressourcen oder Fehlern

Sichere einen konsistenten Dateistand und eine konkrete Fehlerbeschreibung in `docs/AUTONOMOUS_DEVELOPMENT_STATE.md`. Stoppe neue Entwicklungen. Die GitHub-Actions-Pipeline speichert auch bei fehlgeschlagenen Tests den Patch und soweit möglich ein vollständiges Quell-ZIP. Eine APK darf nur nach tatsächlich bestandener unabhängiger Prüfung als Alpha-Artefakt erscheinen. Kein Merge ohne menschliche Prüfung.
