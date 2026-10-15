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
