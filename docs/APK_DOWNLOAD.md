# Android-APK herunterladen

Ab 0.2.3 werden kleine Alpha-APKs pro Prozessorarchitektur gebaut. Die frühere
universelle Debug-APK hatte etwa 136 MiB; die neuen optimierten Dateien benötigen
jeweils ungefähr 15–19 MB. Der genaue erfolgreich geprüfte Stand steht in
[DEVELOPMENT_STATUS.md](../DEVELOPMENT_STATUS.md).

## Direkt bereitgestellte Datei

Ein lokaler Workspacepfad aus einer früheren Nachricht ist kein dauerhaft
veröffentlichter Download. Verwende den in der aktuellen Übergabe bestätigten
Dateilink. Wenn eine ZIP angeboten wird, diese zuerst entpacken; installieren
lässt sich nur eine `.apk`. Der Eigentümer kann bereitgestellte Drive-Dateien
mit seinem verbundenen Google-Konto öffnen und dort **Herunterladen** wählen.
Die Bereitstellung macht sie nicht öffentlich.

- **arm64-v8a:** übliche aktuelle Android-Telefone und Tablets mit 64-Bit-ARM.
- **armeabi-v7a:** ältere Geräte mit 32-Bit-ARM.
- **x86_64:** passende Android-Emulatoren beziehungsweise Intel-Geräte.

Die App benötigt mindestens Android 7.0 (API 24). Stimmen und Spracherkennung
hängen weiter von den auf dem Gerät vorhandenen Android-Diensten ab.

## Datei aus GitHub Actions

Mit dem Konto, das Zugriff auf `ManuEtt/Dnd` hat, in GitHub anmelden.
**Actions → Android-Alpha bauen → grüner Lauf → Artifacts** öffnen.
**lebendiger-spielleiter-alpha-kleine-apks** herunterladen, das ZIP entpacken
und die passende APK wählen. Diese Artefakte werden 30 Tage aufbewahrt;
abgelaufene Dateien benötigen einen neuen erfolgreichen Workflowlauf.

Liegt kein grüner Lauf vor, ist kein neuer Build nachgewiesen. Der Upload
einer Projekt-ZIP allein reicht nicht aus: `app/`, `backend/`, `scripts/`
und `.github/` müssen direkt in der Repositorywurzel liegen. Details:
[UPLOAD_TO_GITHUB.md](UPLOAD_TO_GITHUB.md).

## Installation und Updates

Die optimierten Alpha-APKs verwenden weiterhin eine Debug-Testsignatur.
Sie sind kein Produktions-/Store-Release. Die lokale Signatur wird vor
der Übergabe mit der bisherigen lokalen APK verglichen; derselbe GitHub-Runner
oder ein neuer Runner verwendet möglicherweise eine andere Debug-Signatur.

Bei einer passenden Signatur und höherer Buildnummer ist ein Update vorgesehen.
Der Benutzer meldet App-Betrieb auf einem Samsung Galaxy S26 Ultra; ein
Update auf 0.3.1 und die korrigierten Sprachfunktionen sind separat abzunehmen.
Bei einem Signaturkonflikt wichtige Spielstände vor einer Deinstallation
exportieren. Eine Deinstallation kann lokale Daten entfernen. Meldet Android
eine inkompatible App, zuerst Prozessorarchitektur und Mindestversion prüfen.

Android kann die Freigabe der verwendeten Installationsquelle verlangen.
Nur die tatsächlich bereitgestellte Datei installieren. Fehlertext, Gerät,
Android-Version und ausgewählte APK helfen bei der weiteren Prüfung.

Bei Sprachproblemen: [SPEECH_TROUBLESHOOTING.md](SPEECH_TROUBLESHOOTING.md).
