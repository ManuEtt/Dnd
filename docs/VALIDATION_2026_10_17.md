# Prüfbericht Würfelraunen 0.7.7+47 – 17.10.2026 UTC

Implementierungscode: `718d30fe1ca53ca01002fc03e9057229345e63be`. Basis: `b66354f3112165d76aa340a2f2ab5705f8019e1a`. Nach den Prüfungen ausschließlich Übergabedokumentation aktualisiert. Alle 198 enthaltenen app/backend/scripts/CI-Dateien stimmen byteweise mit dem tatsächlich entpackten APK-Quell-ZIP überein. Der finale Commit steht im Dateimanifest.

| Prüfung | Beobachtetes Ergebnis |
| --- | --- |
| `python3 scripts/verify_project.py` | Projekt vollständig, erfolgreich |
| `python3 -m unittest discover -s scripts/tests -v` | 56 bestanden, 0 Fehler |
| Backend `npm ci`, `npm run typecheck`, `npm run build`, `npm test` mit Node22.14.0 | erfolgreich, 31 Tests bestanden, 0 Fehler/Skips |
| `dart format --output=none --set-exit-if-changed lib test` | 127 Dateien, 0 Änderungen |
| `flutter analyze --no-pub` | keine Befunde |
| `RUN_BACKEND_SMOKE=1 flutter test --no-pub --reporter expanded` | 635 bestanden, 0 Fehler/Skips, 3:20 min; echter lokaler Node/Dart/SQLite-Protokolltest eingeschlossen |
| `flutter build apk --debug` aus entpacktem Vollprojekt-ZIP | erfolgreich, Gradle140.0s, app-debug.apk tatsächlich vorhanden |
| `:app:testDebugUnitTest --no-daemon` auf demselben entpackten Heilzauberstand | BUILD SUCCESSFUL, 33s; XML: 12 Tests, 0 Fehler/Skips |
| `aapt dump badging` | Paket de.aetheria.lebendiger_spielleiter; Version0.7.7, Code47; minAPI24, targetAPI36; ARM64/ARMv7/x86_64 |
| APK-ZIP-CRC und `apksigner verify --verbose --print-certs` | erfolgreich; lokaler Android-Debug-Testschlüssel |
| Vollprojekt-ZIP/Binärpatch | helper prüft CRC, Pfade, Vollständigkeit, Dateihashes/-modi und echte git-apply-Wiederherstellung gegen saubere Basis |
| GitHub-Basis-CI38933445408 | erfolgreich für b66354f; neuer Stand wegen Git-/Connector-HTTP403 nicht remote geprüft |

Neue fachliche Fälle: 26 Heilzauber-Domänen-, 13 Heilzauber-Dialog- und 9 Heilzauber-Integrationstests; davor 42 zusätzliche Effekt-/Zustands-/UI-/SQLite-Tests. Gesamtsuite enthält ferner historische Charaktere, Speicher-/Import-/Export-, Klassen-/Kampf-/UI-/Sprach-/Backendregressionen. Grenztests schließen veraltete Dialoge, fehlende Ressourcen, falsche Klassen, auto-fehlgeschlagene Rettungen, Pakt-/normalen Platzguard, Zugwechsel, Revisionskonflikte und späte Datenbankabbrüche ein.

## Werkzeugstand und Belege

Flutter3.35.7, Dart3.9.2, Node22.14.0, Temurin17.0.20.1; Androidplattformen34/35/36, Tools35, NDK27.0.12077973. Linux-SQLite zur Laufzeit mit libsqlite3.so-Link auf vorhandene Systembibliothek; frische Umgebungen installieren libsqlite3-dev. Keine SDKs/Caches im Quellarchiv. Lokale Rohbelege: /workspace/validation/final-flutter-test.log, final-analyze.log, final-python.log, final-android-build.log, final-android-unit.log, final-apk-metadata.json, final-apk-signature.txt. Backend-Abschlusslauf direkt mit beobachtetem Exit0; zusätzliche gespeicherte Phase2-Backendbelege unter phase2-*.log.

Tatsächlich gebautes Quell-ZIP: `Wuerfelraunen_0.7.7+47_20261017T125535049438Z_heilzauber-vor-build_Vollprojekt.zip`. Endgültige Übergabedokumente und Importanleitung werden danach im finalen Archiv ergänzt. Separate Debug-APK: Wuerfelraunen_0.7.7+47_Debug.apk,142474157Bytes; SHA256 bdf389221c6228be9c1a6d87ab106ca3ee9fa748295a791d3e5059bd95f003b1. Signaturzertifikat SHA256 bde776ce0122bcc6acbd6a2f343604c882b06a1c6d33aa84b3943c015b905e50.

## Offene Abnahmen

Keine bekannten Fehler in den ausgeführten Prüfungen. Gradle/Flutter-Abhängigkeiten melden Deprecation-Hinweise, die den erfolgreichen Build nicht blockieren. Keine Emulator-/Geräte-, reale Sprach-/Dateiauswahl- oder OpenAI-HTTPS-Abnahme; Updatesignatur zu früheren Installationen nicht abgeglichen. Die APK ist eine lokal testsignierte Debugfassung, keine Store-Freigabe. Vollständige SRD-Regeln und verbleibende Mechaniken ausdrücklich offen, siehe RULE_COVERAGE und CHECKPOINT. Keine neuen kostenpflichtigen KI-Aufrufe.
