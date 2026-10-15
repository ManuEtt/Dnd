# SRD 5.2.1 – Zustände und Erschöpfung (Würfelraunen 0.6.2+32)

**Offizielle Quellen:** https://www.dndbeyond.com/srd und
https://www.dndbeyond.com/sources/dnd/br-2024/rules-glossary
(SRD 5.2.1, CC BY 4.0). Der Regelstand **2024** ist relevant, nicht
die abweichende SRD-5.1-/2014-Tabelle.

## Erschöpfung

- Gespeicherte Stufen 0–6 (`HeroCharacter.exhaustionLevel`), optionales Feld
  `exhaustionLevel` in alten Schema-1-Spielständen, fehlend bedeutet 0.
- Jede Stufe: **−2 pro Stufe auf W20-Tests** (beinhaltet Angriff, Initiative,
  Attributsprobe und Rettungswurf). Bei manuellen Todesrettungswürfen bleiben
  Sonderfälle für natürliche 1 und 20 unverändert; der W20-Test berücksichtigt
  ansonsten den Erschöpfungsabzug.
- Bewegung: **5 Fuß = 1,5 Meter je Stufe** weniger. Grundbewegung (`speed`)
  ist bereits in Metern gespeichert und wird nie überschrieben. Für die
  ganzzahlig geführten Kampfrunden werden verfügbare Meter abgerundet,
  damit niemand schneller laufen kann als der reduzierte SRD-Grenzwert.
- Bei Stufe 6 gilt `isDead`, auch wenn historische Zustandslisten keinen
  Eintrag `tot` enthalten. Erhöhen über Stufe 6 hinaus ist nicht möglich.
- Bei abgeschlossener langer Rast sinkt die Erschöpfung um **genau eine**
  Stufe. Der bisherige Rast-Workflow hat **noch keine verlässliche Spieluhr**
  für Dauer/Unterbrechung; nur ausdrücklich bestätigte lange Rasten wirken.
- Kein automatisches Erlangen von Erschöpfung aus Erzähltext. Der Charaktereditor
  bietet ein Eingabefeld (0–6); die reine `ExhaustionRules.gain()`-Methode ist
  für spätere ausdrücklich bestätigte Regelereignisse verfügbar.

## Zustände

`ConditionRules.descriptions` hält deutschsprachige Kurzüberblicke der
**14 weiteren SRD-Zustände** vor; Erschöpfung ist das 15. Element des Glossars.
Die bestehenden frei editierbaren `conditions` bleiben kompatibel. Das Modul
ermittelt konservative, *nicht situationsabhängige* Verbote für Aktionen,
Bewegung und bestimmte Angriffsnachteile. Im Demo-Kampf werden diese
Handlungs-/Bewegungsverbote geprüft.

**Grenzen:** Zauberkonzentration, Rettungswürfe für alle Gegenstände und
Zauber, Quellen/Endzeiten, Sichtlinien, relative Entfernungen, Vor-/Nachteile
auf Würfel und regelbasierte Zustandsanwendung durch Monster/Zauber müssen
in eigenen getesteten Arbeitspaketen implementiert werden. Insbesondere
dürfen situationale Effekte von `verängstigt`, `bezaubert`, `unsichtbar`
und `liegend` nicht ohne Verursacher/Entfernung automatisch festgelegt werden.
Charaktere behalten bisherige frei formulierte Einträge, die nicht stillschweigend
als kodifizierte Zustände interpretiert werden.

## Regressionsschutz

`app/test/exhaustion_conditions_test.dart` prüft Schema-1-Kompatibilität,
Validierung, Erschöpfung, Modifikatoren, Bewegung, Tod, Rast und
konservative Zustandsauswertung. Android-Widgettests und reale Geräteabnahme
stehen aus. `flutter analyze` und `flutter test` sind vor jeder APK-Freigabe
erforderlich. Der automatische Codex-Workflow darf nicht reaktiviert werden.
