# Entwicklungsstatus

Stand: 13. Oktober 2026. Aktuelle Etappe: eigenständiger Android-Solo-Alpha-Prototyp zur ZIP-Übergabe für `ManuEtt/Dnd`.

Die vorhandene GitHub-Codebasis war während der Entwicklung nicht verfügbar. Dieses Paket wurde neu aufgebaut und noch nicht mit einer älteren Repositoryversion verglichen. Ein Push, ein Pull Request und eine Ausführung des Workflows auf GitHub sind deshalb nicht Bestandteil des nachgewiesenen Stands.

## IMPLEMENTIERT

- Flutter-/Android-Projekt mit Material 3 und deutscher Navigation: Start, Charaktere, Abenteuer, Journal und Einstellungen.
- Charaktereditor mit nullable, ausdrücklich unbestätigten Werten; JSON-Export/-Import, Kampagnenauswahl und lokale Löschfunktionen.
- Deterministischer deutscher Spielleiter mit Stichwortinterpretation freier Texte. Die mobile App verwendet ausschließlich diesen Dienst; keine generative Modellverbindung im App-Spielablauf.
- Demo „Das Licht von Mooswacht“ in Lunaris mit Liora, Erkundung, Schlüssel, Quest und einfacher Gegnerbegegnung.
- Historischer Arescan-Zustand „Das Herz der Ewigkeit“: bekannte Geschichte, fehlende Attribute, historische Werte 19/14 und ungeprüfter Modifikator +7; keine erfundenen Helden- oder Gegnerkampfwerte.
- Würfel W4/W6/W8/W10/W12/W20/W100, natürliche Ergebnisse getrennt von Gesamtergebnissen, Vorteil/Nachteil und kontrollierbare Zufallsquelle.
- Regelgrundlagen für Attributmodifikatoren, Übungsbonus, Initiative, Angriffe, kritischen Schaden, Trefferpunkte, Heilung und Todesrettung. Demo-Kampf mit automatischer Gegenrunde; kein vollständiges SRD-Kampfsystem.
- SQLite-Schema 1, gemeinsame Speicherung von Snapshot und Ereignissen, Revisionsjournal, Konfliktprüfung, Idempotenz und Wiederherstellung bestätigter Zustände.
- Grundlegender Kurzzeitkontext, faktengestützte Sitzungsübersicht und Langzeitfakten zu NPCs, Quests und Inventar; Checkpoint-Ereignisrekonstruktion.
- Deutsche Systemspracherkennung mit bearbeitbarem Transkript, TTS, Stimmwahl, optionale automatische Ausgabe und Unterbrechung. Tatsächliche Gerätefunktion noch nicht geprüft.
- Fastify-/TypeScript-Backend mit validierter, ausschließlich erzählender API, eigenen kurzlebigen Read-only-Tokens, In-Memory-Anfragelimits und kostenlosem Mock. Optionaler OpenAI-Responses-Provider ausschließlich serverseitig und mit ausdrücklichem Kosten-Opt-in. Kein Realtime-Token.

Der Workflow `.github/workflows/android-build.yml`, Projekt- und Übergabedokumentation liegen vor. CI verwendet Flutter 3.35.7, Dart 3.9.2, Java 17 und Node.js 22.14.0.

## GETESTET

Die offiziellen SRD-5.2.1-Quellen und die geforderte CC-BY-4.0-Namensnennung wurden abgerufen und geprüft. Das Backend bestand `npm ci`, TypeScript-Typecheck, Produktionskompilierung und alle **17 deterministischen Tests** sowohl unter Node.js 22.14.0 als auch unter Node.js 24.19.0. Ein HTTP-Smoke-Test des kompilierten Servers prüfte `/health`, `/v1/session` und `/v1/narrate` erfolgreich. `npm audit` meldete keine bekannten Schwachstellen zum Prüfzeitpunkt. Es wurden keine bezahlten API-Aufrufe ausgeführt. Flutter 3.35.7/Dart 3.9.2: `flutter analyze` ohne Befunde und **74 Tests bestanden**. Der Lauf umfasst 28 Würfel-/Regeltests, 14 Domänen-/Kampagnentests, 8 Datenbanktests, 6 Controller-Integrationstests, 7 Sprachlogiktests mit kontrollierten Plugin-Mocks und 11 Widgettests. Geprüft sind unter anderem vollständiger Demo-Quest/Kampfablauf, unbekannte historische Arescan-Werte, Modifikatoren, Ereignisrekonstruktion, erneutes Laden nach Datenbankneustart, Transaktionsrollback, Idempotenz, veraltete Schreiber, fehlerhafte Importe, korrekte Sprache-Abbruchlogik und mobile Layouts einschließlich 360×800 mit 300 Pixel Tastatur-Inset. Diese Sprachlogiktests ersetzen keinen Test des Gerätesprachdiensts.

## NICHT GETESTET

- Installieren und vollständiger End-to-End-Ablauf auf einem echten Android-Gerät.
- Deutsche Mikrofoneingabe und Sprachausgabe mit einem konkreten Android-Sprachanbieter.
- Unterbrechung, Berechtigungsablehnung und Ausfall von echten Gerätesprachdiensten; die zugehörige App-Logik ist mit Mocks getestet.
- GitHub-Actions-Lauf und Herunterladen eines APK-Artefakts.
- Reale, kostenpflichtige OpenAI-Aufrufe.

## BLOCKIERT

- Zugriff auf die vorhandene GitHub-Codebasis und direkte Übertragung der Änderungen: Das Repository konnte in dieser Sitzung nicht genutzt werden. Die ZIP-Übergabe ermöglicht die Übernahme durch den Eigentümer.
- Eine vollständige Prüfung auf einem Android-Gerät benötigt ein Gerät beziehungsweise einen geeigneten Emulator mit Sprachdiensten.
- Produktive KI-Anbindung benötigt sichere Serverkonfiguration und Anbieterzugang; der Demo-Modus bleibt unabhängig davon.

## NOCH NICHT IMPLEMENTIERT

- Vollständiges SRD-5.2.1-Regelsystem einschließlich regelkonformer automatischer Charaktererstellung, aller Klassen, Zauber, Ressourcen, Bonus- und Reaktionsaktionen sowie automatischem Stufenaufstieg.
- Regelkonforme Fortsetzung des historischen Arescan-Kampfs bei weiterhin unbekannten Gegnerwerten.
- Anbindung des mobilen Spielablaufs an die optionale Backend-Erzählung.
- Durchgängiger geprüfter mobiler OpenAI-Realtime-WebRTC-Sprachpfad und Ausstellung von OpenAI-Realtime-Credentials.
- Öffentlicher Mehrspielerdienst, PostgreSQL-Synchronisierung und Benutzerverwaltung.
- Vollständige mehrstufige Erinnerungsverdichtung und semantische Langzeitabrufe.
- Signierter Veröffentlichungsbuild und Store-Veröffentlichung.
- Abgenommene Windows- und iOS-Versionen.

## Letzter Build und nächste Aufgabe

**13. Oktober 2026: `flutter build apk --debug` erfolgreich** mit Flutter 3.35.7, Dart 3.9.2 und einem vollständigen Temurin-JDK 17.0.20.1. Verwendet wurden Gradle 8.12, Android Gradle Plugin 8.9.1, Kotlin 2.1.0, Plattform-SDKs 34/35/36, Build Tools 35.0.0, NDK 27.0.12077973 und CMake 3.22.1. Die APK hat Paket-ID `de.aetheria.lebendiger_spielleiter`, Version 0.1.0+1, Mindest-Android-API 24 (Android 7.0) und Ziel-API 36. `apksigner verify --verbose` bestätigt die Debug-Signatur; APK-Metadaten und die verpackten Demo-/Arescan-Dateien wurden geprüft. Ausgabe: `app/build/app/outputs/flutter-apk/app-debug.apk`.

Anfangs fehlten ein vollständiger Java-Compiler, die Sprachplugin-SDKs und CMake. Diese Entwicklungswerkzeuge wurden installiert. Proxy-/CA-Vertrauen wurde ausschließlich in der lokalen Cloud-Werkzeugumgebung konfiguriert, ohne TLS-Prüfung zu deaktivieren. Lokale Werkzeugpfade und Cloud-Konfiguration gehören nicht zum ZIP. Die CI installiert die benötigten SDK-Komponenten ausdrücklich. Der erfolgreiche lokale Build ist **kein** ausgeführter GitHub-Actions-, Emulator- oder Gerätetest.

Nächster konkreter Schritt: Die geprüften ZIP-Projektinhalte in einem neuen Branch mit dem vorhandenen Repository vergleichen und übernehmen. GitHub Actions ausführen, dann die APK auf einem Android-Gerät installieren und den Sprach-/Wiederherstellungstest aus TESTING.md abschließen. Das ZIP enthält keine Git-Historie oder Buildcaches; eine separat bereitgestellte APK dient direkt zum Testen.
