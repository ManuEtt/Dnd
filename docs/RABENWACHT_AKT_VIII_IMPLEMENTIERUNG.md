# Rabenwacht – Die vierzehnte Stimme: Akt VIII, Der Eid der Raben

**Entwicklungsstand: 21.10.2026.** Implementierung auf
`feature/rabenwacht-voice-act8-council-20261021`. Der ursprüngliche
Kampagnenmodus und die Fortsetzung `rabenwacht-voice-v1` bleiben erhalten.
Die vollständige CI- und Geräteabnahme ist von der nachfolgend dokumentierten
Code- und Testerstellung getrennt.

## Anschluss und Einstieg

Aus der bestehenden Bibliothek in Akt VII gelangt der Spieler nach dem
tatsächlichen Auffinden des vierzehnten Eidblatts und der bewussten Wahl
seiner Verwahrung nach `voice-threshold`. Erst mit einer ausdrücklichen
Einberufung des Rats geht es nach `voice-council`. Die zuvor belegten
Spuren und die Originalentscheidung `end-seal`, `end-break`, `end-mercy`
oder `end-chorus` werden weiterverwendet.

Seren wird dabei **nicht** pauschal wieder als körperlich anwesender NPC
eingesetzt. Ihr Verhältnis zum Dorf richtet sich nach dem alten Ende:
die Siegelgrenze, das zerbrochene Siegel, Serens Erlösung oder der bewahrte
Namenchor werden als unterschiedliche Folgen erklärt.

## Beweiskette und Zeugenrat

Drei voneinander unabhängige Hinweise aus Akt VI:
`voice:memorySketch`, `voice:splitInkLetter` und
`voice:namelessGrave`. Nur ihr bereits gespeicherter bestätigter Fundstatus
wird gezählt. Das Eidblatt selbst ist die verbindende Urkunde und **keine**
vierte unabhängige Zeugenaussage.

- Mit allen drei gesicherten Belegen rekonstruiert der Rat die vollständige
  gegenseitige Beweiskette direkt.
- Bei nur zwei Belegen kann der Held eine **ausdrücklich bestätigte
  öffentliche Ersatzzeugenaussage** abgeben. Sie trägt die persistenten
  Marker `voice:publicTestimony` und `voice:testimonyRisk` und wird
  nachfolgend als umstritten gekennzeichnet, niemals als drittes gefundenes
  Dokument ausgegeben. Dies ist eine fiktionale Risikoentscheidung,
  **keine bestandene Überreden-Probe**.
- Der Held kann die Aussage abbrechen, den Rat vertagen, am Dorfplatz die
  fehlende dritte Spur untersuchen und auf dem vorhandenen Akt-VI/VII-Weg
  zurückkehren. Ein zuvor gesichertes Blatt muss nicht erneut erfunden werden.

## Das Kerngeheimnis

Erst nach Rekonstruktion der Beweiskette erkennt der Rat, dass der
vierzehnte Name zum Chronisten gehört. Nicht die Vergangenheit selbst wurde
verändert, sondern die gemeinschaftliche Beweiskette der Erinnerungen
beschädigt. Liora ist unabhängig von dieser Manipulation eine eigenständige
Person.

## Drei alternative Abschlüsse

| Auswahl | Bedingung | Konsequenz |
| --- | --- | --- |
| **Eid erneuern** `voice-end-oath` | 3 Hinweise oder 2 plus ausdrücklich bestätigtes Zeugnis | Gemeinsam erneuerter Schwur schützt Rabenwacht; freiwillige Zeugenschaft bleibt mit dem Ort verbunden |
| **Archiv zerstören** `voice-end-archive` | **Alle 3 echten Hinweise**, nicht nur Ersatzzeugnis | Belege werden vor der Auflösung des falschen Erinnerungsarchivs gesichert |
| **Neuen Eid verhandeln** `voice-end-accord` | 3 Hinweise oder 2 plus ausdrücklich bestätigtes Zeugnis | Statt einer erzwungenen einzigen Dorfchronik werden freiwillige Erinnerungen gemeinsam bezeugt |

Die endgültige Entscheidung erfordert ein positives, explizites Kommando;
negierte Kommandos dürfen kein Ende starten. Der Abschluss setzt
`voice:ending` und löst die Hauptquest `voice-main`; ein nochmals
eingesandter Schlussbefehl erzeugt **keine zweite Lösung und keine EP**.
Alte abgeschlossene/gescheiterte Quests sowie nicht gelöste optionale
Nebenaufträge bleiben in ihrem bisherigen Status.

Die bereits gespeicherte Chronistenentscheidung bleibt nachvollziehbar.
Ein vorher ausdrücklich zugesagter gefährlicher Preis wird als
`voice:chronistDebt=contested` öffentlich angefochten: **kein NPC wird
aus dem Speicher gelöscht**. Ein vorgetäuschter Handel behält den Verdacht
des Chronisten. Die Auflösung ist eine narrative, bezeugte Ritualfolge,
kein automatisch durch einen Freitextangriff gewonnener SRD-Kampf.
Es werden weder TP, RK, Zauberplätze, Ausrüstung noch Charakter-EP
verändert. Keine neue Monsterstatistik ist impliziert.

## Persistenz und Regression

Alle Zusatzfakten werden im existierenden schema-1-Campaign-JSON
gespeichert. Keine SQLite-Migration oder neuer Savegame-Modus.

`app/test/rabenwacht_fourteenth_voice_act8_test.dart` prüft
den Start aus echter Akt-VI-/VII-Spielhandlung, die Zwei-/Drei-Belege-Sperre,
verneinte oder abgebrochene öffentliche Aussagen, die Rückkehr zum dritten
Hinweis, alle drei Enden, die Besonderheiten der vier alten Enden,
die bestrittene Schuld, Liora-/Täuschungs-Erinnerung, Questschutz, konstante
Heldenwerte und JSON-Roundtrips.

**Abnahmekriterien vor Merge:** Projekt-/Importgrenzprüfungen,
Dart-Format, `flutter analyze`, alle Flutter-Tests, Android-Debug-APK,
native Checks und CI-Artefakte. Eine tatsächliche Spielzeit-,
Balance- und Android-Geräteabnahme bleibt separat offen.
