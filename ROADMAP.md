## Aktueller Schwerpunkt – 0.5.4+24 (15.10.2026)

- **Implementiert, CI offen:** Übernahme einer zweiten Klassenstufe an unveränderte Regel-/Heldenbasis gebunden; fünf Dart-Regressionstests für veraltete Bestätigungen, doppelte Fertigkeiten, HP-Schaden und ungültige Klassenstufen.
- **Implementiert, CI offen:** Versioniertes vollständig importierbares Projekt-ZIP und ARM64-APK plus SHA-256/ReleaseNotes nach grünem Android-GitHub-Workflow; Fehler-Checkpoints bleiben klar getrennt. Siehe `docs/ALPHA_RELEASES.md`.
- **Jetzt erforderlich:** vollständigen Quellstand auf eigenem GitHub-Branch importieren (GitHub-Schreibzugriff derzeit 403), `flutter analyze`, `flutter test`, Kotlin-/Backend-Tests und APK-Build im CI validieren, Android-Installation und Persistenz auf echtem Gerät prüfen.
- **Danach:** Mehrklassen-Proficiency-/Ressourcenmodell weiter vervollständigen; vor neuen weitreichenden Spiellogikänderungen gültige SRD-Regeln und Spielstandkompatibilität testen.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## 0.3.7+13 – eigener KI-Spielleiter (implementiert, CI ausstehend)

Generative Kampagnenplanung, dauerhafte Story-Bibel, von Spielerentscheidungen abgeleitete Handlungsstränge und NPC-Beziehungsänderungen sind als optionale Backend-Funktion umgesetzt. Nächste Schritte: GitHub-CI und Android-Abnahme mit Mock; echter OpenAI-End-to-End-Test mit bewusstem Kostenlimit; weitere D&D-Kampfregeln für frei entwickelte Gegner, transparente Bestätigung erzählerischer Behauptungen, größere kontextsensitive Erinnerungen und mehrteilige Kampagnen-„Akte“ über mehrere Sessions. Ohne Verbindung bleibt die Demo verfügbar. Kein permanentes selbstlernendes Modell.

# Roadmap

Die Reihenfolge folgt dem Ziel eines dauerhaft fortsetzbaren Android-Abenteuers. Jede Aufgabe wird mit einem funktionierenden Ergebnis und passenden Tests abgeschlossen. Der tatsächliche Stand und die erfolgreich durchgeführten Prüfungen stehen in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

## Nächster Entwicklungsschritt

**0.3.6+12 als GitHub-Import vorbereitet:** Persistente, ausdrücklich bestätigte
Sitzungsrückblicke, dokumentierte NPC-Beziehungsverläufe und statusgeführte
Handlungsstränge sind im Tagebuch eingebaut. Für den nächsten Schritt stehen
zuerst die vollständige Flutter-/Android-CI und die Geräteabnahme dieser drei
Dialoge an. Danach folgen bessere Dialogvarianten auf Grundlage tatsächlich
bestätigter Beziehungen und Quests, konfliktfreie Bearbeitung über mehrere
Spieler hinweg und später echte semantische Erinnerungssuche.

GitHub `main`-Basis: `6e967080baba7de252fac378d51758a20f6556ae`;
letzter CI-Test dieses Basisstandes 290 bestanden/1 UI-Hit-Test fehlgeschlagen.
Die Testkorrektur ist enthalten, aber der neue Lauf steht aus.

**Version 0.3.3+9 vorbereitet:** Zwölf SRD-Klassen sind mit Level-1-Skills, Rettungswürfen und wählbarer Ausrüstung/Startgold in einen Bestätigungsdialog eingebaut. Manueller Ausnahmeweg bei neuen Startattributen ist nun sichtbar. Die bereits 0.3.2 bestätigte Trefferpunktfunktion bleibt nutzbar.

Nach Import: GitHub Actions (Flutter Analyze, alle Unit-/Widgettests, Backend, Android APKs) ausführen und den Klassenassistenten einschließlich Abbruch, Klassenauswahl, Ausrüstung und 27-Punkte-Dialog auf Samsung Galaxy S26 Ultra abnehmen. Noch offene Facharbeit: Hintergrund-Fertigkeits-/Werkzeugübung, Talente, Klassenmerkmale, Ausrüstungsanlegen/RK, langfristige Trennung von automatischen und manuellen Attribut-Quellen; sichere Stufenaufstiege. Keine unbewiesene Vollständigkeit der SRD-Engine behaupten.

Abgenommen in der Nutzer-Rückmeldung zur 0.3.2: 27-Punkte-Verteilung, Spracheingabe, Sprachausgabe und Start-TP-Vorschlag funktionieren auf dem Samsung Galaxy S26 Ultra. Ein detaillierter Gerätestand ist für 0.3.3 noch offen.

GitHub-Zugang: Lesezugriff bestätigt; letzter bekannter Schreibversuch wurde durch GitHub 403 abgelehnt. Änderungen als direkt importierbares vollständiges Quell-ZIP bereitstellen.

## Phase 1 und 2: Solo-Alpha absichern

- Attributshilfe 0.3.0 auf einem Gerät abnehmen und Charaktererstellung um geprüfte Klassen-Startwerte erweitern.
- Charakterbearbeitung und Importvalidierung anhand der tatsächlich unterstützten Regeloptionen erweitern.
- Dateibasierte JSON-Sicherungen aus App 0.2.2 auf Android mit lokalem und optionalem Cloud-Dokumentanbieter abnehmen; Export, Abbruch, ungültige Importe und Wiederherstellung prüfen.
- Automatischen und manuellen Würfelmodus einschließlich natürlichem Wert und Gesamtwert prüfen.
- Kampfgrenzen sichtbar machen und weitere Zustände, Aktionen, Ressourcen und Todesrettungswürfe schrittweise ergänzen.
- Regeloptionen und Charakterfortschritt aus rechtmäßig nutzbarem SRD-Inhalt implementieren; jede Regeländerung mit Referenz und Test versehen.
- Arescan mit Benutzereingaben vervollständigen, ohne historische Angaben rückwirkend zu ändern.

## Phase 3: Sprache und KI

- Deutsche Android-Erkennung und TTS auf einem Gerät mit dokumentiertem Anbieter und Sprachpaket prüfen.
- Fehler bei verweigerter Mikrofonfreigabe, fehlendem Sprachdienst und Verbindungsabbruch prüfen.
- Den optionalen Backend-Erzähler mit echten Android-HTTPS-Verbindungen abnehmen; die Textintegration und lokalen Protokolltests liegen seit 0.2.0 vor.
- Sichere Sitzungserneuerung und Benutzerkonten ergänzen, ohne dauerhafte Anbieter-Schlüssel im Client.
- Offizielle OpenAI-Dokumentation unmittelbar vor der Realtime-Integration erneut prüfen.
- Realtime über WebRTC mit sicherer kurzlebiger Token-Ausstellung implementieren; Transkription/Text/TTS als Fallback behalten.
- Ausgaben für Sprache begrenzen und Zustandsvorschläge strikt validieren.

## Phase 4: Kampagnengedächtnis

- Kurzzeit-, Sitzungs- und Langzeitgedächtnis als eigenständige Abrufebenen vervollständigen.
- Den seit 0.2.1 vorhandenen lexikalischen Abruf um überprüfbare Sitzungszusammenfassungen und offene Handlungsstränge erweitern.
- Regeln für Zusammenfassungen und dauerhafte Fakten durch Konsistenztests absichern.
- Abbruchtests auf einem Gerät ergänzen und Schema-Migrationen mit alten Exporten prüfen.

## Phase 5: Mehrspieler

- Serverkonten, Kampagnenmitgliedschaften und Rollen entwickeln.
- PostgreSQL und versionierte Migrationen ergänzen.
- Ereignissynchronisierung mit Konfliktbehandlung und Idempotenz umsetzen.
- Fremde Charaktere und Kampagnen gegen unberechtigte Änderungen schützen.
- Gemeinsame Initiative, Sprecherprofil-Auswahl und Push-to-Talk-Sitzungen ergänzen.

## Phase 6: Weitere Plattformen und Darstellung

- Windows und iOS erst nach funktionierender Android-Alpha auf eigenen Buildumgebungen prüfen.
- Erweiterte Charakteroptionen, Kampagneneditor und dynamische Abenteuer ergänzen.
- Optionale Musik und Umgebungsgeräusche mit klaren Nutzungsrechten integrieren.
- NPC-Stimmen nur mit tatsächlich unterstütztem Anbieter und Kostenkontrolle anbieten.
- Store-Signierung, Datenschutztexte, Hosting und Veröffentlichung gesondert vorbereiten.
