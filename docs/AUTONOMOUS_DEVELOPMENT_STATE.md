# Fortsetzungsstand der autonomen Entwicklung – 15.10.2026

- **Produkt:** Würfelraunen – Der lebendige Spielleiter (historisch Aetheria).
- **Version dieses vollständigen Quellstands:** `0.5.3+23` (lokales vollständiges Quellarchiv; **noch nicht in GitHub CI geprüft**).
- **Herkunft:** Vollständiges, zuvor gesichertes `Wuerfelraunen_v0.5.3_23_Fixierte_Schnellaktionen_GitHub_Import.zip` aus der Projektbibliothek; darin enthalten: Flutter, Android, Kotlin, TypeScript-Backend, SQLite, WebP-Grafiken, Tests, Dokumentation und Skripte.
- **Vergleich GitHub `main` bei der Erstellung:** `bb5383b7a52b5052a5c2e8ce4714fe16b0e600da` (`0.5.2+22`). Die neuere `0.5.3+23` mit unten fixierten Schnellaktionen befindet sich **nur im vollständigen Quellarchiv**; sie wurde nicht in `main` gemergt.
- **Letzte erfolgreich geprüfte Version im GitHub-CI:** `0.5.1+21`, Commit `13b2f5fe2ca481db9e3dd17439fb8ba63b6e217d`, Actions-Lauf `38706060048` mit 330 Flutter- und 29 Backend-Tests sowie Debug-/ARM-APKs.
- **Bekannter GitHub-Buildfehler auf `main`:** Actions-Lauf `38709406240`, ungültige `description` wegen ungequotetem YAML-Doppelpunkt in `app/pubspec.yaml` bei `flutter pub get`.
- **In diesem Quellarchiv korrigiert:** `app/pubspec.yaml` enthält den zitierten Text (aus Version 0.5.3); neuer Python-Regressionstest `scripts/tests/test_pubspec_metadata.py` schützt die Beschreibung vor dem gleichen Fehler.
- **Letzte funktionale Ergänzung:** Fixierte Schnellaktionen im Abenteuer-Footer aus 0.5.3 und vorhandene Widgettests; noch nicht in Android CI bestätigt.
- **CI-Ergänzung dieses Pakets:** Quellen-Checkpoint (ZIP/Prüfsumme/Fehlerbericht) auch beim Scheitern der Android-Pipeline sowie vorbereiteter, standardmäßig **deaktivierter** Codex-Entwicklungsworkflow für Montag/Donnerstag 18:00 Uhr Europe/Berlin. Codex führt keine kostenpflichtigen Aktionen ohne bewusstes Opt-in aus.
- **Checkpoint dieser Übergabe:** Vollständiges ZIP `Wuerfelraunen_v0.5.3_23_Vollstaendiges_Projekt_mit_Codex.zip` und gleichnamige `.sha256`-Datei. Dies ist eine Quellcodeübergabe, keine APK-Freigabe.
- **APK dieses Quellstands:** **keine verifizierte APK**; eine installierbare `0.5.3+23` erfordert zunächst grünen GitHub-CI-Lauf.
- **GitHub-Berechtigungen:** verbundenes GitHub-Schreibwerkzeug meldete HTTP 403 für die Branch-Erstellung. Der Hauptbranch wurde nicht verändert.
- **Kostenfreigabe:** `OPENAI_API_KEY` und `ENABLE_PAID_CODEX=true` müssen erst nach ausdrücklicher Einwilligung im GitHub-Repository konfiguriert werden; bis dahin keine autonomen API-Aufrufe.
- **Offene Aufgaben:** Vorläufige Quellversion `0.5.3+23` auf eigenem Branch einspielen, GitHub-CI vollständig grün bekommen, Android-Gerätetests durchführen; danach D&D-Multiclass-Regeln und KI-Kampagnengedächtnis erweitern.
- **Nächster konkreter Schritt:** Archiv entpacken, sauber nach `auto-development` committen, GitHub Actions ausführen, fehlerhafte Tests reparieren und erst bei Erfolg eine ARM64-APK bereitstellen.

**Regeln:** Bekannte Builds/Tests niemals als erfolgreich ausgeben, wenn sie nicht gelaufen sind. Keine Spielstände oder historische Kampagnen überschreiben. Dem KI-Erzähler keine Autorität über mechanische Spielwerte geben. Niemals private Schlüssel oder `.env` hochladen.
