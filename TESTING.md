## Rabenwacht – Der Brief von Morgen (21.10.2026, CI offen)

- `app/test/rabenwacht_fourteenth_voice_morrow_test.dart`: echter Durchlauf aus ursprünglicher Kampagne über Finale und Epilog; Brief ausdrücklich öffnen, drei frei kombinierbare Ortsbelege, unabhängige Mindestschwelle, negierte Eingaben, drei unterschiedliche Enden, Save-Roundtrip, Spoiler- und Questschutz.
- **Noch zu bestätigen:** Dart-Format und Flutter-Testlauf, Android- und native CI, realer Gerätetest. Keine Heldendaten oder SRD-Effekte automatisch verändern.

## Rabenwacht – Epilog / Sieben Tage später (21.10.2026, CI offen)

- Neue Regression `app/test/rabenwacht_fourteenth_voice_epilogue_test.dart`: Eintritt nur nach abgeschlossenem Akt VIII, Epilog ausdrücklich beginnen, drei Personen in beliebiger Reihenfolge, mindestens zwei unterschiedliche Stimmen, Lioras freie Entscheidung, drei vermächtnisgebundene Abschlusswege, alle früheren Finale, negierte Eingaben, Questisolierung und Save-Roundtrips.
- **Noch ausstehend:** offizieller Dart-Formatter, Flutter-Analyse und Tests, Android-CI/Debug-APK und Geräteabnahme. Keine automatische Veränderung von TP, EP, Zauberressourcen, Inventar oder bestehenden NPC-Daten.
- Fachliches und technische Prüfpunkte: `docs/RABENWACHT_EPILOG_IMPLEMENTIERUNG.md`.

## Rabenwacht – Akt VIII / Der Eid der Raben (21.10.2026, CI offen)

- Neue Flutter-Regression `app/test/rabenwacht_fourteenth_voice_act8_test.dart`: echter Fortsetzungspfad bis zum Zeugenrat, bestätigte Originalspuren, alternative öffentliche Aussage, Abbruch/Negation, Rückkehr zur dritten Spur, vier historische Enden, drei neue Enden, Liora, Preis-Schuld, Questschutz und JSON-Roundtrip.
- Weiterhin unveränderte `schemaVersion=1`-Persistenz und unveränderte Heldenressourcen. Keine automatisierte regelmechanische Wirkung des Chronisten behaupten.
- **NOCH AUSZUFÜHREN:** Format-/Importprüfungen, `flutter analyze`, `flutter test`, Android-Debug-Build, native Checks und reales Gerät.
- Nachweise und fachliche Bedingungen: `docs/RABENWACHT_AKT_VIII_IMPLEMENTIERUNG.md`.

## Rabenwacht – Akt VII / Das Haus ohne Türen (21.10.2026, Tests geschrieben – nicht ausgeführt)

- `app/test/rabenwacht_fourteenth_voice_act7_test.dart`: Eintritt über die echte Akt-VI-Bibliothek, Porträtvergleich, Spoilergrenze, Ablehnung/Verhandlung/Täuschung, exakte Preisbestätigung, negierte Zustimmung, Rückzug, Eidblattbeweis, unterschiedliche Verwahrung, Speicher-Roundtrip und Nicht-Abschluss der Hauptquest.
- `app/lib/story/fourteenth_voice_act7.dart` importiert ausschließlich gemeinsames Modell und Story-Typ; keine direkte Würfel-/Zauberlogik.
- **OFFEN:** Dart-Formatprüfung, Flutter-Analyse, Flutter-Tests, Android-APK und Gerätetest; fehlender lokaler Flutter-/Dart-SDK-Zugriff ist kein Testerfolg. Abhängigkeit von offenem PR #77 beachten.
- Details: `docs/RABENWACHT_AKT_VII_IMPLEMENTIERUNG.md`.

## Rabenwacht: Die vierzehnte Stimme / Akt VI (21.10.2026)

- `app/test/rabenwacht_fourteenth_voice_act6_test.dart`: bestätigt freiwilligen Kapitelwechsel, Erhalt alter Abschlüsse und Charakterdaten, vier originale Enden, nicht wiederholbaren Questbeginn, Liora-Reaktion, spoilerfreie Hinweise, Nachforschungs-/Wahrnehmungsproben bei drei Zeugen, negative Würfe, alle Zweierkombinationen, Galerieszene, Speicher-Roundtrip und unveränderte alte Nebenquests.
- Regression: `flutter analyze`, `flutter test`, `flutter build apk --debug`; CI-Status vor Merge ablesen. Kein Android-Gerätetest behauptet. Die Fortsetzung verwendet exakt die vorhandene `StoryRulePort`-Schnittstelle und vergibt keinen nicht implementierten Zauber oder automatische Meilenstein-EP.

## Rabenwacht – Die stumme Strophe (21.10.2026)

- `app/test/rabenwacht_hymn_story_test.dart` prüft: keine Spuren vor der Entdeckung, Questvergabe erst in der Kapelle, fehlende Beweise, Rückreise und Idempotenz, Oswins Erinnerung und Relationship-State, dauerhafte Verbrennung, negative/ambivalente Kommandos, 4-fach gesperrten Namenchor, viertes Finale mit einmaliger EP-Vergabe, klassische Enden und ungelöste Nebenquest.
- Weiterhin `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, `flutter build apk --debug` und praktischer Android-Spieltest erforderlich.

## Rabenwacht – alternative Fertigkeitswege (21.10.2026, CI offen)

- `app/test/rabenwacht_alternative_checks_test.dart`: ursprüngliche und neue Wege bei Turmruine/Treppe/Tür, Schwierigkeitsgrade 12–14, echte Heldenproben, Belegfreischaltung, unbestätigte Hinweise, Erfolgs-/Misserfolgszweige, JSON-Roundtrip und frei behauptete Zauberwirkung.
- Vor Merge: `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, `flutter build apk --debug` und separater Test auf einem Android-Gerät.

## Rabenwacht – NPC-Gedächtnis und Geheimweg (21.10.2026)

- `app/test/rabenwacht_npc_memory_test.dart` enthält sieben Testfälle: Geheimweg nur nach gezieltem Tarek-Gespräch, nicht freigeschalteter Geheimweg, Geheimweg mit einmaliger EP-Vergabe und gespeicherten Ortsbesuchen, unveränderter Krähenalarm, Alriks Belegprüfung und Geständnis, Maras Versöhnung und ein zusammenhängender Weg über Tarek → Friedhof → Alrik → Mara.
- Vor Merge erneut `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, `flutter build apk --debug`; reale Geräteprüfung separat. Noch keine erfolgreiche CI-Abnahme für diesen Branch behaupten.

## Rabenwacht – Gedenkstein-Friedhofsquest (21.10.2026)

- `app/test/rabenwacht_memorial_test.dart`: Hinweisfreigabe erst nach Entdeckung, Nachweis zum Bewahren, Nichtblockieren des Hauptpfads, Rückreisen, einmalige Quest, Speicherrundlauf, explizites Verschweigen, drei Epiloge und negierte Aussagen.
- CI-Abnahme: `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, Android-APK; realer Android-Test separat. **Noch nicht erfolgreich bestätigt.**

## Rabenwacht – verzweigte Ermittlungen (21.10.2026, CI offen)

- `app/test/rabenwacht_branching_story_test.dart`: Maras drei Entscheidungswege, NPC-Vertrauen und -Konflikt, nachholbare bekannte Orte, Schutz vor EP-Doppelbuchung, keine Kämpfe durch negierte Angriffe, bewusster Abschluss nach Seren-Überreden, warnende Krähen und persistente Epilog-Fakten.
- Vor PR-Merge in `app/`: `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, `flutter build apk --debug`. Neu implementiert, aber noch nicht durch Flutter-CI geprüft.

## Zaubersystem 0.6.4+34

- `app/test/spellcasting_rules_test.dart`: vollständige Zauberklassen-/Pakt-Pools, Verbrauch und alte Speicherdaten, Zaubertrick, bestätigte Konzentration, lange/kurze Rast, Konzentration nach Schaden, manipulierte Speicherstände.
- `app/test/spellcasting_dialog_test.dart`: sichtbare Zauberplatzvorräte, ausdrückliche Buchung/Abbruchverhalten im Dialog.
- Lokal: `python3 scripts/verify_project.py` und `python3 -m unittest discover -s scripts/tests -v`. Vollständiges Flutter/Android CI nach Import.

## Einheitliche Regelengine – 0.6.3+33

- `character_rule_engine_test.dart`: Erschöpfung einmal; Rettungswurfübung; Initiative/Vorteil/Nachteil; Vergiftung, liegend, blind; schwere Waffen; Stärkeanforderungen schwerer Rüstung; ungeübte Ausrüstung; PendingRoll-Speicherkompatibilität; Kampfereignis-Integration.
- `character_rule_engine_widget_test.dart`: Der Charakterbogen zeigt abgeleitete Bewegung und Erschöpfung konsistent im Zustandsbereich.
- `scripts/verify_project.py` und 38 Python-Tests bestanden. Dart/Flutter/Android-SDK steht hier nicht bereit; neue Flutter-Tests und APK noch nicht ausgeführt.

## 0.6.2+32 – Erschöpfung und Zustände

- Neue Domain-Datei `app/lib/domain/condition_rules.dart`, Tests `app/test/exhaustion_conditions_test.dart`.
- Prüffälle: Rückwärtskompatibilität, ungültige Stufen, 2024- statt 2014-Mali,
  Bewegung im Meter-Modell, Zustand Tod, Rast um eine Stufe, Todesrettungen,
  Handlungs-/Bewegungsverbote und situationsabhängige Ausnahmen.
- Vor Freigabe `flutter analyze`, `flutter test` und `flutter build apk --debug`.
- Python-/Strukturtests sind keine Aussage zur Dart-Kompilierbarkeit.

## Korrekturprüfung 0.6.1+31

Auf Basis der Logausgaben aus GitHub Actions #38746011222 und #38734808085:

1. `flutter analyze` darf kein `unnecessary_brace_in_string_interps` in `lib/domain/srd_equipment_catalog.dart` mehr melden.
2. `flutter test test/rest_rules_test.dart` muss die Rast-Tests einschließlich `HeroCharacter.fromJson` ausführen, ohne `FormatException: Spezies ist ungültig.` beim Fixture-Aufbau.
3. Anschließend das vollständige `flutter test`, Backend-Tests und den Android-APK-Build ausführen.

**Status:** Diese Flutter-/APK-Befehle konnten lokal mangels Flutter SDK nicht ausgeführt werden. Ein grüner CI-Build ist erst nach separater Übernahme auf GitHub belegbar.

## SRD-Ausrüstung 0.6.0+30

- `app/test/equipment_rules_test.dart`: Waffen- und Rüstungsvorschau, Stärke-/Geschicklichkeits-Grenzen, Übung, Finesse, Schild-/Zweihand-Ausschlüsse, Sicherheitsvalidierung, Altspeicher und veraltete Vorschläge.
- `app/test/ui_equipment_loadout_test.dart`: Dialog-Auswahl, explicit confirm, unverändertes Ursprungsobjekt.
- Befehle: `cd app && flutter pub get && flutter analyze && flutter test` und `flutter build apk --debug`; vollständige Projekt-CI vor Veröffentlichung erforderlich. Lokal ohne Flutter/Dart nicht ausführbar.

## Zusätzliche Tests für SRD-Ausrüstung 0.5.9+29

- `app/test/srd_equipment_catalog_test.dart`: Genau 38 SRD-Waffen + 13 Rüstung/Schild, eindeutige IDs, englisch/deutsche Suche, Waffenmeisterschaft, Reichweite/Munition, Rüstungs-RK und negative GE, magische Gegenstände ohne automatische Regelwirkung, optionale `catalogId` mit Legacy-Import.
- `app/test/ui_equipment_catalog_test.dart`: Suche, explizite Wahl und Abbruch ohne Inventaränderung.
- `app/test/ui_character_editor_test.dart`: Zusätzlicher Editor-Integrationstest mit Katalogauswahl und Round-Trip-Persistenz.
- `scripts/tests/test_srd_equipment_source.py`: Basistabellen-/Lizenz-Schutz ohne Flutter SDK.
- **Prüfstatus:** 38 Python-Tests und Strukturprüfung lokal bestanden. Vollständiges `flutter analyze` und `flutter test` stehen in der Android-CI aus; keine APK für 0.5.9 als freigegeben ausgeben.

## 0.5.8+28 – SRD-Rastregeln (CI noch ausstehend)

- `flutter test test/rest_rules_test.dart`: Einzel-/Mehrklassenpool, Konstitutionsbonus, Mindestheilung, HP-Obergrenze, Ressourcenerschöpfung, alte JSONs, ungültige Importe, GameEngine-Journal, lange Rast und Sperren.
- `flutter test test/fantasy_character_sheet_test.dart`: neue Anzeige verfügbarer Trefferwürfel im Verteidigungsbereich.
- `flutter test test/domain_game_test.dart`: bestehende Demo-Heilung mit expliziter langer Rast.
- Vollständiges `flutter analyze` und `flutter test` vor Android-Build zwingend ausführen. Flutter/Dart-SDK in der lokalen Packaging-Umgebung nicht vorhanden; **keine grünen Dart-Testläufe erfunden**.
- Auf Android testen: kurze Rast mit 2W10, Neustart/Speicherung/Export/Import, erneute kurze Rast nach ausgeschöpftem Pool, lange Rast, Kampf-/Todesblockade, Mehrklassen 2W10 + 1W6.

## Regression 0.5.6+26 – drei vorherige CI-Fehler

CI-Ausgangslage: https://github.com/ManuEtt/Dnd/actions/runs/38728029583 (349 Tests bestanden, 3 fehlgeschlagen).

- `flutter test test/fantasy_pinned_actions_test.dart`: bei 360dp simulierten IME-Inset erkennen, Überschrift entfernen und alle vier Schnellaktionen hit-testbar halten. Bei 320dp und 180% Schrift keinerlei RenderFlex-Overflow; W20 antippbar.
- `flutter test test/ui_character_editor_test.dart`: Inventar-Button bis ins sichtbare Testfenster scrollen; Itemname, Anzahl und Save korrekt speichern. Kein Unterdrücken von Hit-Test-Warnungen.
- Danach `flutter analyze`, `flutter test` vollständig sowie Android-Debug- und ARM64-Build via `.github/workflows/android-build.yml`.

Der lokale Quellcode wurde **noch nicht mit Flutter ausgeführt**; Tests sind zur Abnahme vorbereitet.

## 0.5.5+25 – Schnellaktionen dauerhaft am unteren Bildschirmrand

- `app/test/ui_app_test.dart`: echte Abenteueransicht nutzt `Scaffold.bottomNavigationBar`; Leiste bleibt unter dem Editor und oberhalb der Hauptnavigation, wird beim Scrollen nicht verschoben und kann Aktionen auslösen.
- `app/test/fantasy_pinned_actions_test.dart`: vier Aktionen bei 320/360/400 dp, mit geöffneter Tastatur und neu bei 320 dp/1,8-facher Schriftgröße erreichbar.
- `flutter analyze`/`flutter test`/`flutter build apk --debug` stehen bis zur GitHub-CI offen; im lokalen Container ist kein Flutter-SDK vorhanden. 35 Python-Tests prüfen weiterhin Projekt- und Packaging-Sicherheit. Gerätetest mit Android-Navigationsleiste und Bildschirmtastatur empfohlen.

## 0.5.4+24 – Zusätzliche Abnahme der Multiclass- und ARM64-Freigabe

- Python: `python3 scripts/verify_project.py .` und `python3 -m unittest discover -s scripts/tests -v`, inklusive der sieben `test_prepare_alpha_release.py`-Fälle.
- Dart: `flutter test test/multiclass_rules_test.dart` zusätzlich zum vollständigen `flutter test`; insbesondere Heldentausch, nachträglich geänderte Klassenvoraussetzungen/HP/Fertigkeiten und zwischenzeitlicher TP-Schaden.
- Backend: `npm ci && npm run typecheck && npm run build && npm test` mit online verfügbaren Paketen, nicht anhand eines unvollständigen Offline-Caches.
- Android: `flutter build apk --debug`, Kotlin-JVM-Tests und anschließend ARM64-AOT-APK erstellen; die neue Release-Paketierung liest `app/build/alpha/app-arm64-v8a-alpha.apk`. Nur nach erfolgreichen Prüfungen als Alpha freigeben.
- GitHub-Artefakt prüfen: ZIP-Pflichtdateien (`README.md`, `app/`, `backend/`, `.github/`, `scripts/`) im Archiv-Root; `Wuerfelraunen_vVERSION_BUILD_arm64.apk` enthält `lib/arm64-v8a/libapp.so`, `libflutter.so` und Manifest; `SHA256.txt` verifiziert ZIP, APK, Notizen.
- Vor einem Gerätetest vorhandene Spielstände sichern; Debug-Signatur kann sich zwischen unabhängig gebauten Release-Dateien unterscheiden.

## Pflichtprüfung 0.5.3+23 – Feste Abenteuer-Schnellaktionen

Neuer Hauptzweck: Die Schnellaktionen **Sprache / Untersuchen / Angriff / W20** müssen direkt oberhalb der unteren Navigation fixiert bleiben, während die Szene und Nachrichten scrollbar sind. Nach Aktivierung eines Kampfes bleiben die Aktionen ebenfalls verfügbar. Bei geöffneter Android-Tastatur bleiben die vier kompakten Aktionsfelder sichtbar, während doppelte Eingabebuttons eingespart werden. Die alte horizontale Schnellaktionsleiste in der Szenenliste existiert nicht mehr.

Wichtige automatisierte Prüfschritte nach GitHub-Import:

- `cd app && flutter pub get` (war zuvor durch `description: Würfelraunen: ...` ungültig; Beschreibung nun gequotet)
- `cd app && flutter analyze`
- `cd app && flutter test test/fantasy_pinned_actions_test.dart test/ui_app_test.dart`
- `cd app && flutter test`
- `cd app && flutter build apk --debug`

Beim manuellen Test auf dem Smartphone: Abenteuer öffnen, nach unten scrollen, Schnellaktionen positionstreu und bedienbar prüfen, Bildschirmtastatur öffnen, W20 und Mikrofonschaltfläche überprüfen. Besonders 320/360/400 dp und erhöhte Textskalierung prüfen. Keine Änderung der Regeln oder Speicherformate. Flutter-/APK-Lauf steht für diese Version noch aus.

## Aktuelle CI-Fix-Abnahme 0.5.1+21

Vorversion 0.5.0+20: 328 Flutter-Tests erfolgreich; zwei fehlgeschlagen (`fantasy_character_sheet_test.dart` offscreen/lazy Tab und `ui_app_test.dart` offscreen Demo). Teständerungen verwenden explizite echte Scroll-Gesten, `ensureVisible` und `.hitTestable()`, statt Tests oder Warnungen zu deaktivieren.

Testprotokoll: https://github.com/ManuEtt/Dnd/actions/runs/38704528398/job/116320523742

Die neue Version muss in GitHub Actions erneut sämtliche Schritte einschließlich Android-Build bestehen. Für einen schnellen ersten Check: `cd app && flutter test test/fantasy_character_sheet_test.dart test/ui_app_test.dart` und `flutter analyze`.

## Illustrierte Oberfläche 0.5.0+20 – Pflichtchecks nach GitHub-Import

- `python3 scripts/verify_project.py .`
- `python3 -m unittest discover -s scripts/tests -v`
- `cd app && flutter pub get && flutter analyze && flutter test`
- `cd app && flutter build apk --debug`
- Android: auf 320/360/400 dp, vergrößerter Schrift und im Hoch-/Querformat testen, insbesondere die Aktionsleiste und den Inventardialog.
- End-to-End: Demo starten, Aktion eingeben/diktieren, Würfeln, Charakterbogen öffnen, Inventar anzeigen, Kampagne speichern/exportieren und App erneut starten.
- Die Art-Dateien sind lokal und brauchen keine Netzverbindung. Der CI-Status von v0.4.3 darf nicht als Erfolgsnachweis für v0.5.0 ausgegeben werden.

## Neue Regression 0.4.3+19

`app/test/fantasy_character_sheet_test.dart` testet die tatsächlichen Attributkarten auf 320/360/400 dp, die Einzigartigkeit der Grid-Keys und 1.4x-Systemschrift. Der vorherige CI-Lauf erreichte 319 bestandene / 4 fehlgeschlagene Flutter-Tests; diese Änderungen müssen in GitHub Actions neu nachgewiesen werden. Prüfe `flutter analyze`, `flutter test` und `flutter build apk --debug`.

## Regression für 0.4.2+18 – Flutter-Analyse

In 0.4.1 schlug GitHub Actions mit `undefined_named_parameter: mainAxisExtent` in `fantasy_character_sheet.dart:237` fehl. Die Syntax ist jetzt `GridView(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(..., mainAxisExtent: tileHeight))`. Bitte insbesondere `flutter analyze`, `flutter test` und den Android-Build im CI prüfen. Widgettests enthalten Fälle für 320, 360 und 400 logische Pixel sowie 1,4-fache Schrift; ein Test überprüft explizit den Grid-Delegate. Kein Fehler wird absichtlich unterdrückt.

## Zusätzliche Prüfung für 0.4.0+16

- Neues `app/test/fantasy_design_system_test.dart`: Theme-Farben und gerahmte Komponenten bei 320, 360 und 1000 logischen Pixeln.
- Vorhandene UI-/Dialogtests bleiben Teil der CI, insbesondere Scroll-/Tap-Tests unter 360 Pixeln, deren antippbare Elemente durch Gestaltung nicht überdeckt werden dürfen.
- Manuelle Geräteabnahme: untere Navigation, Landscape/Tablet-Seitenleiste, Abenteuer-Eingabe mit Tastatur, Scrollen, Inventar, Heldeneditor, Speichern, Import/Export.
- Lokal konnten Struktur und Python getestet werden; **Flutter-/Android-SDK fehlen**. Neue Widgets und mögliche Layout-/Compileprobleme erfordern die GitHub-CI.

## 0.3.9+15 – UI-Akzeptanz

1. `flutter analyze` und `flutter test`: insbesondere `fantasy_character_sheet_test.dart` und `ui_app_test.dart` auf einem 320-/360-dp-Fenster.
2. **Helden** → **Bogen ansehen**: gespeicherte Werte, farbige sechs Attribute, Übungsbonus und Rettungswürfe müssen stimmen; „Charakter bearbeiten“ öffnet den bisherigen Editor.
3. **Abenteuer** → **Charakterbogen ansehen**: die aktiven Kampagnenwerte anzeigen, ohne Spielerhandlung/Würfelwurf zu verändern.
4. Einen unvollständigen importierten Helden öffnen: unbekannte Werte bleiben „–“/„Nicht erfasst“, und in allen Ansichten gibt es keine überlaufende Typografie.
5. **Zustände/Verteidigung** wechseln; dabei dürfen keine Regeln oder Spielstände verändert werden.
6. Verifikation auf einem echten Android-Gerät, auch mit großer Systemschrift und aktiver Bildschirmvorlesefunktion, vor Freigabe.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## KI-Geschichtenmodul 0.3.7+13

Neue Tests: `app/test/ai_story_test.dart`, `app/test/ai_story_integration_test.dart`, `backend/test/story.test.ts`. Zusammen mit `app/test/campaign_memory_panel_test.dart` und `app/test/ui_app_test.dart` nach Import in GitHub Actions ausführen. Die Integrationstests nutzen nur einen simulierten Story-Provider und echte lokale SQLite-Revisionsspeicherung. Behauptet wird kein bestandener Flutter-Test, solange der Lauf nicht erfolgreich abgeschlossen wurde.

Zusätzlich auf Android prüfen: KI-Start mit Mock und OpenAI (ausdrückliche Kostenfreigabe), mehrere verschiedene Themen, Neustart nach drei Entscheidungen, NPC- und Queststatus, unterbrochene Sitzung, volles lokales Kontingent, fehlerhafte Providerantwort, PDF-freier JSON-Export/Import, alte 0.3.6-Spielstände und Abgrenzung der Mooswacht-Demo. Der narrative KI-Spielzug darf niemals Gegenstände, HP oder Würfel verändern. Die Backend-Endpunkte `/v1/story/start` und `/v1/story/advance` teilen sich Limits mit `/v1/narrate`.

# Tests und Abnahme

Tests verwenden kontrollierbare Zufallsquellen und Anbieter-Mocks. Es sind keine kostenpflichtigen Modellaufrufe erforderlich. Ein Test gilt erst nach einem tatsächlich beobachteten erfolgreichen Lauf als bestanden; implementierter Testcode allein ist kein Testergebnis.

## Automatisierte Prüfungen

Unter Linux benötigen SQLite-Tests die Entwicklungsbibliothek `libsqlite3-dev` (Debian/Ubuntu: `sudo apt-get install libsqlite3-dev`). Der CI-Workflow installiert sie vor den Flutter-Tests.

Vor dem Installieren der Buildwerkzeuge die Übertragung prüfen:

```bash
python3 scripts/verify_project.py
python3 -m unittest discover -s scripts/tests -v
```

Diese Tests benötigen nur Python 3. Sie prüfen insbesondere Wurzelstruktur,
Dateiausschlüsse, fehlende Lock-/Workflowdateien, Gradle-JAR-CRC und beschädigte
Uploads. Der CI-Workflow führt sie ebenfalls vor Flutter/Node aus.

Im Projektverzeichnis:

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

```bash
cd backend
npm ci
npm run typecheck
npm run build
npm test
```

Mit Android SDK und Java 17:

```bash
cd app
flutter build apk --debug
```

Die native Dateisicherungslogik wird nach einem Android-Build zusätzlich auf der JVM geprüft:

```bash
cd app/android
./gradlew :app:testDebugUnitTest --no-daemon
```

Diese JVM-Tests prüfen Dateinamen und begrenztes Lesen. Dart-Kanal- und Widgettests simulieren die Systemdateiauswahl; sie ersetzen keinen Gerätetest. Der GitHub-Workflow führt auch diese Prüfungen aus und stellt die APK nur nach erfolgreichem Build und erfolgreichen Tests bereit. Er benötigt für Demo-Tests keine API-Schlüssel.

Der zusätzliche echte Node-/Dart-Protokolltest benötigt zuvor `npm run build`
im Backend und wird mit `RUN_BACKEND_SMOKE=1 flutter test` aktiviert.
`scripts/check.sh` und GitHub Actions aktivieren ihn nach dem Backend-Build.
Er verwendet ausschließlich synthetische Zugangsdaten und den lokalen Mock;
unverschlüsseltes Loopback-HTTP ist nur für diesen Entwicklungstest freigeschaltet.

Die Testabdeckung soll natürliche Würfelwerte und Gesamtwerte, Attributmodifikatoren, Angriffe, Schaden und Heilung, unvollständige Charakterdaten, Speicherung und Neustart, Transaktionsrollback, doppelte Ereignisse, Importvalidierung, Demo-Erzählung, zentrale Widgets und Backend-Authentifizierung beziehungsweise Validierung prüfen. Die tatsächlich vorhandenen Tests und ausgeführten Ergebnisse stehen in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

## Rückblick und konsistente NPCs (0.3.5)

Nach GitHub-Import zusätzlich `cd app && flutter test test/memory_recall_test.dart test/ui_app_test.dart`
und `flutter analyze` ausführen. Automatische Tests sollen thematische
Filterung, leere/unbekannte Erinnerungen, bestätigte NPC-/Quest-/Inventarstatus,
reproduzierbares Ereignisjournal, erhaltene ausstehende Würfel und ungesendete
Texte prüfen. Auf dem Gerät Rückblick bei aktiver Tastatur und Push-to-Talk,
sowie das erneute Ansprechen Miras nach Schlüssel, Wächter und Questabschluss
prüfen. Ein bestandener CI-Test ersetzt diesen Gerätetest nicht.

## Persistentes Kampagnengedächtnis (0.3.6)

Nach GitHub-Import zusätzlich:

```bash
cd app
flutter analyze
flutter test test/campaign_memory_v036_test.dart test/campaign_memory_storage_test.dart test/campaign_memory_panel_test.dart test/ui_app_test.dart
```

Im Tagebuch einen Sitzungsrückblick speichern, einen offenen Handlungsstrang
anlegen und als gelöst markieren, Miras Beziehung mit Begründung ändern.
Das Gerät neu starten, Kampagne laden und dieselben Daten einschließlich der
alten Beziehungsnotiz sowie JSON-Export prüfen. Den Aktionsrückblick mit
Fragen zu NPCs und Handlungssträngen vergleichen. Eine Verwaltungsnotiz darf
keine TP, Würfel, Questbelohnung oder ausstehende Probe verändern.
Alten 0.3.5-Export ohne die drei neuen JSON-Felder importieren und den
360-px-Button „Vervollständigen“ überprüfen. Die eingereichten Dart-Tests
sind ohne erfolgreichen CI-Lauf nur Quellcode, keine bestandenen Tests.

## Android-Gerätetest

Diese Schritte sind eine noch separat durchzuführende Abnahme. Gerät, Android-Version, APK-Commit und Sprachdienst im Testbericht festhalten.

1. APK installieren und App starten. Im Demo-Modus ohne Backend und ohne API-Schlüssel beginnen.
2. Charakter anlegen. **Attribute ermitteln** öffnen und Standardwerte beziehungsweise Punkte-Kauf testen. Hintergrund und Steigerung ausdrücklich wählen; Vorschau und Modifikatoren prüfen. Abbrechen muss eingegebene/historische Werte bewahren, bekannte Werte benötigen Ersetzbestätigung. Hilfe übernehmen, übrige Daten bestätigen, speichern und anzeigen; Werte bearbeiten. Die App schließen und neu öffnen, anschließend denselben Charakter prüfen.
3. Neue Demo-Kampagne starten. Texteingabe senden, Antwort lesen und mehrere freie Handlungen durchführen. Den Umfang der Demo-Interpretation dabei berücksichtigen.
4. Automatisch und manuell würfeln. Natürliches Ergebnis und Gesamtergebnis prüfen; sicherstellen, dass Boni genau einmal angewendet werden.
5. Einen einfachen Kampf bis zum Ende durchführen. Treffer, Fehlschlag, kritischen Treffer, Trefferpunkte und gespeichertes Ergebnis prüfen.
6. Die App nach einer bestätigten Aktion beenden und neu starten. Szene, Verlauf und Charakterzustand müssen erhalten bleiben. Einen kontrollierten Abbruch während einer Aktion zusätzlich prüfen.
7. Ein **persönlich gesichertes**, historisches JSON einer unvollständigen Kampagne nur über „Kampagne aus JSON importieren“ laden. Geschichte und bestätigte/unbestätigte Attribute unverändert übernehmen. Die App stellt keinen historischen Arescan-Spielstand standardmäßig bereit.
8. Charakter und Kampagne über **Als Datei speichern** als `.json` sichern; im Android-Systemdialog Zielordner und Dateinamen auswählen. Nach dem Speichern die Datei außerhalb der App prüfen. Beim Import über **Datei wählen** zunächst laden und dann ausdrücklich **Importieren** drücken. Jeweils die Systemauswahl abbrechen: vorhandene Daten müssen unverändert bleiben. Ungültige, fremde, übergroße und nicht UTF-8-codierte Dateien abweisen. Vorhandene Kampagnen nicht überschreiben; für den Wiederherstellungstest ein gesichertes Testexemplar zuerst lokal löschen. Zwischenablage und Texteingabe als Fallback prüfen. Einen Schreibfehler, fehlenden Dokumentanbieter und Aktivitätsende separat testen. Auch den gewählten Dokumentanbieter und Offline-Verfügbarkeit im Bericht nennen.
9. Deutsche Sprachpakete installieren beziehungsweise prüfen. Mikrofonfreigabe zunächst ablehnen und danach erlauben; beide Abläufe müssen verständliche Rückmeldung liefern.
10. Push-to-Talk verwenden. Erkanntes Deutsch anzeigen, Text manuell korrigieren und erst danach senden. TTS abspielen und unterbrechen; automatische Wiedergabe und verfügbare Stimmen prüfen.
11. Den Sprachdienst ohne Netzwerk testen. Das Ergebnis dokumentieren; vollständige Offline-Spracherkennung wird nicht zugesichert. Textspiel muss weiterhin verfügbar sein.
12. Datenexport und Löschfunktion prüfen. Bestätigte Löschung darf die entfernten Daten nach einem Neustart nicht zurückbringen.

## Getrennte Nachweise

| Nachweis | Bedeutung |
| --- | --- |
| Analyse und Unit-/Widget-/Backendtests | Prüfen Code und automatisierte Abläufe in der Entwicklungsumgebung |
| Android-APK-Build | Belegt erfolgreiche Kompilierung des Android-Projekts |
| Emulatorprüfung | Prüft Laufzeit auf der angegebenen Emulatorumgebung |
| Realer Gerätetest | Prüft tatsächliche Installation, Sprache, Berechtigungen und Wiederherstellung auf dem Gerät |
| GitHub-Actions-Lauf | Belegt das Verhalten der eingecheckten CI-Konfiguration auf GitHub |

Bisheriger Funktionsnachweis App 0.2.2/Backend 0.2.0: **178 Flutter-Tests** einschließlich echtem lokalem Node-/Dart-Protokolltest, **12 native JVM-Tests** sowie **22 Backend-Tests** des unveränderten Backends bestanden; Flutter-Analyse ohne Befunde und Android-Debug-APK erfolgreich gebaut. Die echten OpenAI- und Android-HTTPS-/Sprachpfade sind weiterhin separat abzunehmen. Details und Werkzeuge stehen in DEVELOPMENT_STATUS.md. Es wurden keine kostenpflichtigen API-Aufrufe ausgeführt.

## Kleine Alpha-APKs

```bash
cd app
flutter build apk --release --target-platform android-arm64
```

Ausgabe `build/app/outputs/flutter-apk/app-release.apk` sofort sichern, bevor
für android-arm oder android-x64 erneut gebaut wird. Die CI kopiert jede
Architektur separat nach build/alpha. Metadaten müssen App 0.3.1, Buildcode 7,
API 24 und die ausgewählte ABI zeigen; Signatur mit einer bisherigen lokalen
APK vergleichen. Ein eigener APK-Build und Metadatenprüfung ersetzen weiterhin
keine Installation. Je Architektur außerdem Start, Sprache, SQLite-Neustart und
Update von der alten Debug-App auf einem passenden Gerät abnehmen.

Stand 0.2.3: 22 Python-Paket-/Strukturtests bestanden; drei kleine Alpha-APKs
lokal erfolgreich gebaut, Metadaten, ABI und gleiche lokale Testsignatur
verifiziert. Der vollständige scripts/check.sh-Lauf ist erfolgreich: 22 Python-Tests,
22 Backend-Tests, 178 Flutter-Tests einschließlich realem lokalem Protokolltest
und saubere Flutter-Analyse. Remote-CI und Gerätetests bleiben offen.

## Attributshilfe 0.3.0

Neue Domain-Tests prüfen Standardsatz, alle 720 Zuweisungen, Punktekosten,
Höchstbudget und zulässige Hintergrundsteigerungen. Die Widgettests prüfen
unter anderem 360-Pixel-Breite, explizite Auswahl, Punktgrenzen, Vorschau,
Bestätigung und Abbruch. SQLite-Integration prüft Neustart, Export/Import,
regelkonforme Modifikatoren, keine wiederholten Boni und historischen Arescan.
Ein realer SQLite-Triggerfehler nach begonnenem Schreiben muss Transaktion
und angezeigten Zustand unverändert lassen. Aktuelle Gesamtergebnisse stehen
in DEVELOPMENT_STATUS.md; diese Tests ersetzen keine Geräteprüfung.

## Sprachkorrekturen 0.3.1

Controller-Mocks prüfen TTS-Ergebnisse 0/false, fehlende Stimmendaten,
Netzwerk-Metadaten, deutsche regionale Locales, Paket-Neusuche, Anbieterfehler,
offene Futures, Stop und verspätete Ergebnisse. Die Android-Sprachliste darf
unvollständig sein; ein fehlender deutscher Eintrag führt zu einem begrenzten
expliziten de-DE-Versuch. Keine Mikrofonaufnahme wird automatisch wiederholt.
Widgettests prüfen Neusuche ohne Mikrofon, entfernte gespeicherte Auswahl und
lange Anbieter-IDs bei 360 px mit bis zu doppelter Schriftgröße.

Die Startprüfung verwendet echte temporäre SQLite-Daten und eine offene
native Stimmabfrage: Die lokale Startseite muss bereits bedienbar sein. Nach
der Antwort des simulierten Dienstes erscheint dessen Status in Einstellungen.
Gezielte Befehle:

```bash
cd app
flutter test test/voice_controller_test.dart test/ui_voice_settings_test.dart test/bootstrap_voice_test.dart
```

Der Benutzerbericht bestätigt App-Betrieb auf Samsung Galaxy S26 Ultra, aber
keine vollständige Sprachabnahme. Am Gerät getrennt deutsche Eingabe und
Vorlesen, Anbietername, Pakete, Netzwerk, Unterbrechung, erneute Stimmensuche
und Update von der vorherigen APK prüfen. Anleitung:
[docs/SPEECH_TROUBLESHOOTING.md](docs/SPEECH_TROUBLESHOOTING.md).

Der alte GitHub-Lauf 38560369343 besteht alle Tests und scheitert anschließend
am fehlenden sdkmanager. Die neue Tools-Installation muss auf GitHub gesondert
bestehen; lokale Builds ersetzen diesen Nachweis nicht.
