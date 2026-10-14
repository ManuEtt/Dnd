# Roadmap

Die Reihenfolge folgt dem Ziel eines dauerhaft fortsetzbaren Android-Abenteuers. Jede Aufgabe wird mit einem funktionierenden Ergebnis und passenden Tests abgeschlossen. Der tatsächliche Stand und die erfolgreich durchgeführten Prüfungen stehen in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

## Nächster Entwicklungsschritt

Das ZIP in einem neuen Branch von `ManuEtt/Dnd` integrieren, den GitHub-Workflow ausführen und seine Logs prüfen. Danach die Debug-APK auf einem Android-Gerät installieren und den dokumentierten Sprach-, Speicher- und Kampfablauf aus [TESTING.md](TESTING.md) durchführen. Erkenntnisse vor zusätzlichen Funktionen beheben.

Standardwerte und Punktekauf mit expliziten Hintergrundsteigerungen sind seit 0.3.0 implementiert und automatisiert geprüft; die Geräteabnahme folgt. Der nächste begrenzte Code-Schritt ist ein Vorschlag für Stufe-1-Trefferpunkte aus Klasse und bestätigtem Konstitutionsmodifikator anhand SRD 5.2.1. Vor Implementierung die offizielle Quelle lesen; bestehende/historische TP nie stillschweigend überschreiben.

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
