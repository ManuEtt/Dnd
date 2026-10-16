# Würfelraunen 0.6.8+38 – SRD 5.2.1 Klassenmerkmal-Register

## Ziel, Quelle und Lizenz

Dieser Schritt setzt den **vollständigen Stufenregister-Unterbau** der zwölf SRD-Grundklassen und ihrer jeweils einen SRD-Unterklasse in einem gemeinsamen Katalog um. Die Einträge bilden die Freischaltungspunkte der Klassentabellen ab. **Die volle automatische Ausführung sämtlicher Merkmale ist ausdrücklich nicht abgeschlossen.**

Quelle: D&D System Reference Document 5.2.1, Kapitel „Classes“, CC BY 4.0: https://www.dndbeyond.com/srd – Pflicht-Namensnennung in `THIRD_PARTY_NOTICES.md`.

## Neu hinzugefügt

- `app/lib/domain/srd_class_feature_catalog.dart`: klassenspezifische Merkmaldaten mit Stufe, Klassenname, Unterklassenzuordnung, stabilem Merkmalschlüssel und Automatisierungsstatus; trennt Grundklasse und SRD-Unterklasse; keine Erfindung für fremde Unterklassen
- `app/lib/domain/class_resource_rules.dart`: deterministische maximale Ressourcen und verfügbare Restnutzungen von Kampfrausch, bardischer Inspiration, Kleriker-/Paladin-Kanal, Tiergestalt, Mönchsfokus, Handauflegen, Erzfeind/Favored Enemy und Zaubereipunkten; Regeneration differenziert nach kurzer/langer Rast
- Ressourcen werden optional unter `spentClassResources` im vorhandenen Speicherformat (`schemaVersion: 1`) geführt; ältere Spielstände laden ohne Änderung
- `app/lib/domain/class_combat_features.dart`: Champions kritischer Trefferbereich (19–20 ab Kämpfer 3, 18–20 ab Kämpfer 15); regelkonforme, rein funktionale Vorprüfung auf Hinterhältigen Angriff anhand bestätigter Umstände; zugehörige Würfelberechnung für normalen/kritischen Treffer
- Barbar: passiver Bewegungsbonus ab Klassenstufe 5, Initiativevorteil ab Stufe 7, Vorteil auf GE-Rettungswürfe ab Stufe 2 (außer bei Handlungsunfähigkeit)
- Mönch: ungerüsteter Bewegungsbonus gemäß Klassenstufe (und ohne Schild) im zentralen Regelrechner
- Champion: Initiativevorteil ab Stufe 3
- Charakterbogen: getrennt sichtbares Merkmalsregister, Status „Berechnet“ gegenüber „Regelprüfung erforderlich“ und separate Ressourcenstände
- Sicherheit: kein KI-Text ändert automatisch Ressourcen; Import ungültiger Ressourcenzähler wird verweigert; es werden keine unbekannten Unterklassenmerkmale vorgetäuscht

## Wichtige Grenzen / noch nicht automatisch implementiert

- Ein Merkmal ist erst dann **vollständig automatisiert**, wenn alle zeit-, ziel-, zustands-, zauber- und ausrüstungsabhängigen Effekte samt Aktionen und Reaktionen verarbeitet werden. Der Katalog ist kein solcher Nachweis.
- Die vollständigen Zauberlisten, vorbereiteten Zauber, Metamagievarianten, Paktanrufungen, Tierformen, Begleiter, Divine-Intervention-Wirkungen sowie weitere SRD-Klassenausnahmen sind noch offen.
- Das existierende Charaktermodell kennt nur ein Unterklassenfeld. Bei zwei Klassen wird deshalb **nicht geraten**, ob die Unterklasse zur Zweitklasse gehört; fehlende Angaben werden nicht automatisch erzeugt.
- Hinterhältiger Angriff ist als **geprüfte Berechnungsfunktion** vorhanden; Integration in die aktuelle Kampfrunden-/Zielpositionsverwaltung sowie die Einmal-pro-Zug-Markierung ist noch erforderlich.
- Rage ist noch **kein vollständiger aktiver Kampfzustand**. Passive Merkmalsberechnungen und Ressourcenverwaltung dürfen nicht mit aktivierter Rage-Resistenz verwechselt werden.
- Aufgelistete „choiceRequired“-Merkmale sind Meilensteine für eine explizite Auswahl, keine stillschweigend vergebenen Talente.
- Automatische UI-Aktionen zum Ausgeben aller neuen Ressourcen sind noch nicht vorhanden; die Regeln unterstützen nur explizit validierte Aufrufe aus zukünftigen Aktionen.
- `flutter analyze`, `flutter test` und der APK-Build müssen in Flutter CI geprüft werden. In dieser Arbeitsumgebung ist kein Flutter-SDK installiert.

## Prüfungen

- Neu: `srd_class_feature_catalog_test.dart`, `class_resource_rules_test.dart`, `class_combat_features_test.dart`, `class_feature_passives_test.dart`.
- Bestehende `scripts/tests`: 38 Python-Tests; gesondert erneut ausgeführt.
- Nach Import in GitHub:

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

### Nächste fachlich notwendige Umsetzung

1. Ereignisbasierter Klassenmerkmal-Ausführer mit Kampfzug- und Reaktionsfenstern.
2. Gesonderte Ziel-, Form-, Konzentrations- und Wirkungsberechnung für komplexe Klassenmerkmale.
3. Explizite Unterklassenauswahl pro Klasse und eine echte Klassenstufen-Steigerungsengine.
4. Umfangreicher Akzeptanztestkatalog gegen SRD 5.2.1.
