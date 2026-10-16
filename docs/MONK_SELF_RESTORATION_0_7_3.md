# Würfelraunen 0.7.3+43 – Selbstwiederherstellung und Rettungswürfe

## Quellen und Lizenz

- D&D System Reference Document 5.2.1 (CC BY 4.0), Klasse **Monk**:
  https://www.dndbeyond.com/srd
- Lesbare Klassentexte des SRD 5.2.1:
  https://www.fantasygrounds.com/library/5e/dd-srd-5-2-1/classes
- Lizenz- und Urhebernachweis: `THIRD_PARTY_NOTICES.md`.

## Implementiert

1. **Selbstwiederherstellung ab Mönchsstufe 10:** Am *Ende des eigenen Zugs*, vor dem nächsten Gegnerzug, kann genau einer der Zustände `bezaubert`, `verängstigt` oder `vergiftet` beendet werden. Es wird weder eine Aktion noch ein Fokuspunkt verbraucht. Andere Zustände bleiben erhalten.
2. Hat der Charakter genau einen der betreffenden Zustände, wird dieser am Zugende automatisch beendet. Bei mehreren Zuständen darf das Programm keine Spielerentscheidung erfinden. In diesem Fall gibt es im Kampf auswählbare Schaltflächen („Am Zugende beenden: ...“) oder die Eingabe `Selbstwiederherstellung: vergiftet`. Die Auswahl ändert den Zustand **noch nicht**, sondern wird bis zum Zugende gespeichert. Ohne Auswahl bleibt bei mehreren Zuständen alles bestehen; das Ereignis weist darauf hin.
3. `Encounter.selfRestorationChoice` ist ein optionales JSON-Feld im bisherigen Speicherschema. Beim Beginn der nächsten Runde wird die Auswahl gelöscht. Ungültige Werte werden beim Import zurückgewiesen. Eine durch zwischenzeitliche andere Handlungen überholte Auswahl führt nicht zum Absturz.
4. **Disziplinierter Überlebender ab Mönchsstufe 14:** Der Charakter ist bei allen sechs Rettungswürfen geübt; die Berechnung verwendet die **Mönchsklassenstufe** zur Freischaltung und die **Gesamtstufe** für den Übungsbonus. Vorhandene Übung wird nicht doppelt gezählt. Nicht bestätigte Attributswerte bleiben unbekannt, und Erschöpfung wird weiterhin berücksichtigt. Die gespeicherte Liste der Rettungswurfübungen wird nicht verändert.
5. Bekannter Dart-Compilerfehler des GitHub-CI-Laufs `38868046916` in `monk_flurry_rules.dart` behoben: der ausgewählte Attributeintrag wird vor der Weitergabe an `abilityModifier` auf `null` geprüft. Regressionen mit ausschließlich bestätigter Stärke bzw. Geschicklichkeit ergänzt.

## Bewusste Grenzen

- Das Verhindern von Erschöpfung **aufgrund fehlender Nahrung oder Getränke** durch Selbstwiederherstellung benötigt zunächst ein systematisch bestätigtes Hunger-/Durst-Ereignismodell. Es wird keine pauschale Immunität gegen Erschöpfung erfunden.
- Die **optionale Wiederholung eines fehlgeschlagenen Rettungswurfs** für einen Fokuspunkt (Disziplinierter Überlebender) erfordert einen eigenen bestätigten Wurfablauf und ist **noch nicht implementiert**.
- Bei mehreren Zuständen muss die Auswahl vor einer den Zug automatisch abschließenden Aktion vorgenommen werden. Die derzeitige Kampflogik ist ein bewusst begrenztes Solo-Modell ohne vollständige Gelegenheitsangriffe, Positionen oder Reaktionsabläufe.
- Die Flutter-/Dart-Domain-Tests in `app/test/monk_self_restoration_test.dart` und der Regressionstest in `app/test/monk_flurry_rules_test.dart` sind **geschrieben, aber lokal nicht ausführbar**, weil kein Flutter/Dart SDK installiert ist. Der nächste GitHub-Actions-Lauf muss die Analyse und sämtliche Dart-Tests bestätigen, bevor eine APK freigegeben wird.
