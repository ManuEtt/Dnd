# Prüfbericht 0.7.9+49 – 18.10.2026 UTC

Vollständig geprüfter Codecommit: `99b8a7bbed9c07132bf49e5eb78be9cfeb391d71`, einschließlich Todesrettungsintegration b0fad28 und Zuggrenzen a2dd0da. Branch: `feature/autonomous-srd-engine-20261016`. Neue Patchbasis: `c889ab6619fe88bd48a420bc45f12d2751af94f7`. Finale Dokumentationsänderungen verändern keinen ausgeführten Code; exakter Abschluss-HEAD im Dateimanifest.

## Tatsächlicher Abschlusslauf

| Prüfung | Beobachtetes Ergebnis | Beleg außerhalb Repository |
| --- | --- | --- |
| Projektstruktur | erfolgreich | 0.7.9-check-final.log |
| Python | 56 bestanden, keine Fehler | 0.7.9-check-final.log |
| Backend Node22.14.0 | Typecheck/Build und 31 Tests bestanden, 0 Fehler/Skips | 0.7.9-check-final.log |
| Dartformat | 132 Dateien, 0 Änderungen | 0.7.9-check-final.log |
| Flutteranalyse | keine Befunde | 0.7.9-check-final.log |
| Fluttertests | 692 bestanden, 0 Fehler/Skips, inkl. realem Backendprotokolltest | 0.7.9-check-final.log, letzte Zeile 02:16 +692: All tests passed! |
| Gezielte Korrekturregression | 67/67 bestanden: 57 neue Fälle und 10 bestehende Erschöpfungsfälle | 0.7.9-corrections-targeted-final.log |
| Android-Debug | erfolgreich aus verifiziertem entpacktem Quell-ZIP, Gradle 35,4 s | 0.7.9-android-build-final.log |
| Native Android-/JVM-Tests | 12 bestanden, 0 Fehler/Skips; Gradle 36 s | 0.7.9-native-test-final.log und 0.7.9-native-final-result.json |
| APK | CRC, Version, Architekturen und Signatur erfolgreich | 0.7.9-apksigner-final.log; Artefakt APK_Pruefung.json |

Alle Lognamen relativ zu `/workspace/validation/`. Maschinenlesbare Zusammenfassung: `0.7.9-final-results.json`. Die neuen Fälle umfassen 19 Todesrettungs-Domänen-, 18 Ablauf-/UI-/SQLite- und 20 Zuggrenzenfälle. Enthalten: alter Import, manipulierter Bonus/Entscheidung, Mehrklassen, natürliche 1/20, verbindlicher niedrigerer Ersatzwurf, vorläufiger dritter Fehlschlag, einmal pro Zug, Revisionsschutz, Neustart und späte SQLite-Transaktionsabbrüche sowie echte UI. Auswahl bei 320 dp und Textskalierung 1,8 geprüft; tatsächliches Zugende in der Kampfoberfläche bei 400×900.

## Gefundene und behobene Fehler

Der erste vollständige Lauf endete mit 688 erfolgreichen Fällen und einer veralteten Erwartung in `exhausted_pending_roll_test.dart`: neue Version-1-Anfragen zeigen den korrekten Malus -4 bei Erschöpfung 2 bereits an. Erwartung angepasst und Regelversion geprüft; die endgültige Berechnung und der Legacy-0-Import sind weiterhin gesondert geprüft.

Zusätzlich reproduzierbare Lücke geschlossen: externer KO oder bestätigte Handlungsunfähigkeit ließen vorher einen alten Kampfrauschzustand bis zum Zugende bestehen. Spätere Heilung konnte ihn damit reaktivieren. Jetzt werden Rage/Dodge sofort beendet und das Ende journalisiert; drei Regressionen prüfen KO→Heilung→vollen Schaden, bestätigte Zustandsänderung und weiterhin gültige Resistenz ohne KO. Anschließend vollständige Suite und Android-Build/native Tests erneut durchgeführt.

## Buildherkunft und APK

Gebaut wurde `/workspace/artifacts/Wuerfelraunen_0.7.9+49_20261018T062523649913Z_todesrettung-korrektur-vor-build_Vollprojekt.zip`, vorher durch die Checkpointsoftware vollständig mit Manifest und tatsächlich angewendetem Patch geprüft. Frische Extraktion nach `/workspace/checkpoints/todesrettung-final-zip`, Archiv-Dateimodi wiederhergestellt. 203 Quell-/Test-/Builddateien in app/, backend/, scripts/ und .github/ byteweise mit dem aktuellen Arbeitsstand verglichen; danach nur Dokumentation.

Finale APK: `/workspace/artifacts/Wuerfelraunen_0.7.9+49_Debug.apk`, 142493733 Bytes, Versionname0.7.9/Code49, minAPI24/target36, ARM64/ARMv7/x86_64. SHA256: `0b38dab8d03e001b46a2e925359d729842100b6b6e8053ab862de06a78f34c7b`. `aapt dump badging` und `apksigner verify --verbose --print-certs` erfolgreich. Zertifikat-SHA256 `bde776ce0122bcc6acbd6a2f343604c882b06a1c6d33aa84b3943c015b905e50`; lokale Debug-Testsignatur, keine Store-Release-Signatur. Erster APK-Kandidat vor letzter Korrektur bleibt mit `vor-korrektur` im Namen erhalten und ist nicht die finale Übergabe.

## GitHub

Main wurde erneut abgeglichen und enthält bereits den bisherigen 0.7.7-Stand. [Main-CI39055088686](https://github.com/ManuEtt/Dnd/actions/runs/39055088686) für c889ab6 laut Actions-REST-API erfolgreich. Die verbundene Commit-Abfrage liefert nur PR-Läufe; daher separate REST-Abfrage. Beleg: `0.7.9-github-main-runs.json`. Neuer Push auf eigenen Branch nach grüner lokaler Prüfung: **HTTP403, Permission to ManuEtt/Dnd.git denied to ManuEtt**, Beleg `0.7.9-github-push.log`. Kein neuer Remote-CI-Lauf/PR behauptet, main unverändert. Übernahme mit IMPORT_0_7_9_49.md.

## Reproduzierbare Befehle

Mit Flutter3.35.7/Dart3.9.2, Node22.14.0, Java17 und Linux-SQLite aus Repositorywurzel `bash scripts/check.sh`: Projektprüfung, 56 Pythonfälle, npm ci/typecheck/test/build, flutter pub get, Formatcheck, Analyse, RUN_BACKEND_SMOKE=1 flutter test. Keine kostenpflichtige KI genutzt.

Android aus app/: `flutter build apk --debug`; danach aus app/android/: `./gradlew :app:testDebugUnitTest --no-daemon`. In dieser Umgebung zusätzlich pro Kommando:

```bash
JAVA_HOME=/workspace/toolchains/jdk17
ANDROID_HOME=/workspace/toolchains/android-sdk
ANDROID_SDK_ROOT=/workspace/toolchains/android-sdk
GRADLE_USER_HOME=/workspace/toolchains/gradle-cache
JAVA_TOOL_OPTIONS='-Dhttp.proxyHost=proxy -Dhttp.proxyPort=8080 -Dhttps.proxyHost=proxy -Dhttps.proxyPort=8080 -Dhttp.nonProxyHosts=localhost|127.*|[::1] -Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts'
```

PATH um Flutter/JDK/Node erweitern; SDK36, Buildtools35.0.0, NDK27.0.12077973. Exakte lokale Einrichtung: `/workspace/validation/TOOLCHAIN.md`; keine Geheimnisse im Projekt.

Nicht abgenommen: Emulator, reales Gerät, Sprache/SAF auf Hardware, Updateinstallation, reale kostenpflichtige Anbieter und neue Release-APKs je ABI. Allgemeine Zustandsdauer ist Entwurf; volle SRD-Implementation offen. Finale ZIP-/Patchprüfung und tatsächliche Dateinamen werden im Manifest und Artefaktindex festgehalten.
