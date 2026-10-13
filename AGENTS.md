# Aetheria – Anweisungen für Codex

1. Vor Arbeitsbeginn README.md, DEVELOPMENT_STATUS.md, ROADMAP.md und ARCHITECTURE.md lesen; Git-Remote/Status und GitHub-Rechte prüfen.
2. Ausschließlich `ManuEtt/DND-Spielleiter-App` verwenden. Nie API-Secrets in Git committen.
3. Bereits funktionierende Module erhalten und inkrementell weiterentwickeln. Kein unnötiges Neuschreiben.
4. Narrativer Spielleiter darf keine regeltechnischen Fakten oder HP frei setzen. Regeln und Speicherung sind unabhängig von generativem Text.
5. Historische Arescan-Ergebnisse sind nicht verifizierte Erzähldaten. Keine fehlenden Werte erfinden.
6. Jede signifikante Änderung mit Unit- oder Integrationstests begleiten; lokale und CI-Tests getrennt protokollieren.
7. Nach einem Arbeitsabschnitt DEVELOPMENT_STATUS.md, CHANGELOG.md und ROADMAP.md aktualisieren.
8. Ist ein Push blockiert, exakten Fehler dokumentieren, andere unabhängige Aufgaben fortführen.
9. Bei Android-Arbeit zuerst `bash tool/setup_android.sh`, danach `flutter analyze`, `flutter test`, `flutter build apk --debug` ausführen.
10. Wenn das Android-Hostprojekt erstmalig generiert wurde, stabilisierte native Dateien anschließend versionieren und das Bootstrap-Script entsprechend vereinfachen.
