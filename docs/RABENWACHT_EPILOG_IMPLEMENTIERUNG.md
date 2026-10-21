# Rabenwacht – Epilog: Sieben Tage nach der vierzehnten Stimme

**Stand:** 21.10.2026. Separates Epilog-Inkrement auf
`feature/rabenwacht-voice-epilogue-20261021`, aufgebaut auf dem noch
offenen Akt-VIII-PR #84. Alle Änderungen müssen vor einer Integration nach
`main` die Projekt-CI bestehen. Ein echter Android-Gerätetest steht separat
aus.

## Warum es einen spielbaren Epilog gibt

Der Chronist ist nach dem Rat der Zeugen kein neues, ungeprüftes Monster.
Die ursprüngliche Kampagne und die Akte VI–VIII haben unterschiedliche
Erinnerungen und Beziehungen hervorgebracht. Der Epilog lässt die Spieler
deren langfristige Folgen erleben, ohne ein abgeschlossenes Finale wieder
aufzuheben, den Helden zurückzusetzen oder automatisch Erfahrung zu buchen.

### Eintritt und Sicherheit

- Nur aus `voice-end-oath`, `voice-end-archive` oder
  `voice-end-accord` und nur mit explizitem **„Epilog beginnen“**.
- Die Endszene muss mit dem gespeicherten `voice:ending` übereinstimmen.
  Dazu werden `voice:witnessChain=true` und der abgeschlossene
  Hauptauftrag `voice-main` benötigt.
- Der Modus bleibt `rabenwacht-voice-v1`, die vorhandene
  Campaign-JSON-Persistenz bleibt unverändert.
- Die Endmarkierung bleibt nach dem Wechsel erhalten. Ein Epilogabschluss
  erzeugt **keine** zusätzlichen XP, Gegenstände, SRD-Effekte oder Würfe.
  Offene optionale Aufgaben und frühere Fehlschläge bleiben unverändert.

## Spielbare Szenen

| Bühne | Spieleraktion | Gespeicherte Folge |
| --- | --- | --- |
| `voice-epilogue-square` | Eine Woche nach dem Finale; Elda, Tarek oder Liora aufsuchen; später Dorfzukunft bestimmen | `voice:epilogueStarted` und genau ein offener Epilogauftrag |
| `voice-epilogue-elda` | Elda erklärt ihren Umgang mit widersprüchlichen Erinnerungen und dem vierten Teller | `voice:epilogue:elda` |
| `voice-epilogue-tarek` | Tarek diskutiert unabhängige Zeugnisse und den Platz von Dokumenten | `voice:epilogue:tarek` |
| `voice-epilogue-liora` | Liora spricht abhängig von Schutz, Anschuldigung, Belegsuche und Verwahrung über Selbstbestimmung | `voice:epilogue:liora`; der alte Herkunftsstrang kann abgeschlossen werden |
| `voice-epilogue-future` | Erst nach mindestens zwei **verschiedenen** Stimmen: Entscheidung oder Rückweg zu weiteren Gesprächen | Keine automatische Wahl |
| `voice-epilogue-complete` | Abschließendes Vermächtnis, wiederholte Eingaben verändern es nicht mehr | `voice:legacy`, Epilogauftrag `completed`, aufgelöster Vermächtnis-Storythread |

Die drei Begegnungen sind unabhängig, wiederholbar und in beliebiger
Reihenfolge möglich. Ein zweiter Besuch derselben Person zählt nicht als
zweites unabhängiges Gespräch. Negierte Eingaben wie „Liora nicht besuchen“
dürfen keine neue Szene auslösen. Unbesuchte Figuren und nicht gefundene
frühere Spuren werden nicht als offengelegte Wahrheiten behandelt.

## Drei endgültige, freiwillige Dorfvermächtnisse

1. **Gedenkbuch anlegen** (`voice:legacy=memorial`): Die Familien dürfen
   unvollständige oder unsichere Erinnerungen freiwillig festhalten.
2. **Zeugnisse veröffentlichen** (`voice:legacy=testimonies`):
   Unterschiedliche Berichte bleiben einzeln zugeordnet. Der zuvor
   zerstörte Chronistenort wird nicht wiederhergestellt.
3. **Dorffest veranstalten** (`voice:legacy=festival`):
   Die Einwohner feiern Gemeinschaft ohne erzwungene einheitliche
   Vergangenheit.

Die Auswirkungen unterscheiden sich außerdem nach dem bisherigen Ende:
erneuerter Eid, zerstörtes Archiv oder neu verhandelter Eid. Auch alle
vier Ausgänge der ursprünglichen Glockennacht bleiben erkennbar, ohne
Seren entgegen einer früheren Erlösung oder Siegelentscheidung erneut als
physisch anwesend zu erfinden.

### Zeugnis und Chronistenschuld

- Eine öffentliche Ersatzzeugenaussage aus Akt VIII wird weiterhin
  **als umstritten gekennzeichnet**, niemals nachträglich als dritte
  unabhängige Originalspur ausgegeben.
- Eine frühere Zusage an den Chronisten bleibt **bestritten**, wird nicht
  stillschweigend eingelöst und löscht keine Person.
- Ein vorgetäuschter Handel und eine früher ausgesprochene Weigerung werden
  als Teil der Dorfgeschichte erwähnt, ohne Zweitentscheidung.

## Technische Abnahme

Die neuen Dateien:
`app/lib/story/fourteenth_voice_epilogue.dart` und
`app/test/rabenwacht_fourteenth_voice_epilogue_test.dart`.

Die Tests decken echten Durchlauf aus dem ersten Rabenwacht-Finale bis
zum Epilog, Wiederholbarkeit, negative Spielereingaben, beliebige
Zeugenreihenfolge, mindestens zwei verschiedene Gespräche,
drei Vermächtnisse, alle drei Enden aus Akt VIII, alle vier alten
Enden, Lioras frühere Beziehung, umstrittene Aussagen,
Questisolierung, idempotenten Abschluss, JSON-Roundtrip und konstante
Heldenwerte ab.

**Vor Integration:** `python3 scripts/check_domain_boundaries.py`,
`dart format --output=none --set-exit-if-changed lib test`,
`flutter analyze`, `flutter test`, Android-APK, native Prüfungen,
vollständige grüne GitHub-CI. Keine Freigabe allein auf Basis eines
grünen Teiltests oder eines erstellten Pull Requests.
