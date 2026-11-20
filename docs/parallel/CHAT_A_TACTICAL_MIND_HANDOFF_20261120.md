# Taktischer Verstand – Funktionsentwicklung und Übergabe

Stand: 20.11.2026. Nutzeranweisung: Funktionsentwicklung in diesem Chat;
Testausführung und koordinierte Integration übernimmt ein anderer Chat.

## Fachlicher Umfang

Requirement `CLASS-K-MPFER-2-BASE-TACTICAL-MIND-1`, SRD 5.2.1,
Kämpfer Stufe 2 / Tactical Mind, gedruckte Seite 48, CC BY 4.0.
[Amtliche Quelle](https://www.dndbeyond.com/srd), Wizards of the Coast LLC.
Das geprüfte amtliche PDF besitzt SHA256
`8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87`.
`THIRD_PARTY_NOTICES.md` bleibt erhalten.

Vor diesem Paket war nur die Klassenfreischaltung katalogisiert.
`SrdFighterTacticalMindRules` implementiert nun die tatsächliche Domänenwirkung:

- Bestätigte, fehlgeschlagene Attributsprobe und gültige Kämpferstufe ab 2.
- Ausdrückliche Spielerentscheidung nach dem bekannten Fehlschlag.
- Genau 1W10 zusätzlich zum bereits berechneten Probenergebnis, kein neuer
  W20 und keine erneute Addition von Attributsbonus oder Kämpferstufe.
- Eine Nutzung `spentSecondWind` nur bei neuem Gesamtergebnis **>= SG**;
  bei weiterem Fehlschlag keine Nutzung. Keine Heilung, Bonusaktion,
  Reaktion, Aktionswoge oder Bewegung durch Taktischen Positionswechsel.
- Originalwürfe, Vorteil/Nachteil, manuelle Gesamtergebnisse und bereits
  zutreffendes Verlässliches Talent bleiben getrennt nachvollziehbar.
- Zustimmungs-, Klassen-, Ressourcen-, Ergebnis- und Wiederholungsprüfung
  vor dem W10. Eine vorbereitete Entscheidung ist an den vollständigen
  Charakterzustand gebunden und verfällt bei dessen Änderung.

## Geänderte Schnittstellen

Neue Datei `app/lib/domain/srd_fighter_tactical_mind_rules.dart`, exportiert
über `app/lib/rules/rules_api.dart`. Bestehende Ressourcenberechnung aus
`ClassFeatureResources` und Mindestwurfberechnung aus `SkillCheckPassives`
werden wiederverwendet. Kein neues Modellfeld, keine Datenbankmigration,
kein Versionswechsel und keine Änderungen an bestehenden Spielständen.

`prepare` prüft den ursprünglichen `PendingRoll` und `DiceResult` und liefert
eine unverbindliche `SrdFighterTacticalMindDecision`. Unterstützte vorhandene
Attributsprobenarten: `preparedCheck`, `perception`, `escape`. Angriffe,
Rettungswürfe und Todesrettungen sind keine zulässigen Auslöser.

`resolve` prüft die Zustimmung und den aktuellen Zustand, würfelt 1W10 und
liefert `SrdFighterTacticalMindResult` mit dem neuen Charakterkandidaten,
beiden Würfeln, Gesamtergebnis, Erfolg und tatsächlichem Ressourcenverbrauch.
Das Eingabeobjekt wird nicht verändert. Auch ein mathematisch unerreichbarer
SG verhindert den ausdrücklich gewählten W10 nicht.

## Verbindlicher Integrationsvertrag

Die Domänenregel ist ausführbar, aber noch **nicht an Controller oder UI
angeschlossen**. Deshalb keine vollständige App-Funktion oder Freigabe behaupten.
Das koordinierende Paket muss den ursprünglichen Fehlschlag vor dessen
endgültigen Story-/Questfolgen anhalten und die Wahl „Taktischer Verstand“
oder „Fehlschlag übernehmen“ anbieten. Freitext allein autorisiert nichts.

Der Aufrufer liefert zu jedem Aufruf die verbindlich gespeicherten
`previouslyAttemptedCheckIds`. `result.attemptedCheckIds` enthält die neue
Versuchskennung auch bei einem weiterhin fehlgeschlagenen Ergebnis ohne
Ressourcenverbrauch. Das ist ein technischer Wiederholungsschutz für die
Auswertung desselben ursprünglichen Fehlschlags; die Quelle wird nicht mit
einer erfundenen wörtlichen „einmal pro Probe“-Klausel ergänzt.

Charakter, endgültiges Probenergebnis und Versuchsnachweis müssen gemeinsam
mit eindeutiger Ereignis-ID, Kampagnen-/Sitzungszuordnung und geprüfter
Repositoryrevision atomar bestätigt werden. `result.toJson()` enthält
`feature`, `checkId`, Original- und Bonuswurf, ursprüngliches effektives und
neues Ergebnis, SG, Erfolg und Ressourcenverbrauch. Es enthält absichtlich
keinen Charakter-Snapshot und keine vollständige historische Kennungsliste.
Der Aufrufer rekonstruiert den Versuchsnachweis aus den bestätigten Ereignissen
auch nach Neustart. Das Set allein ist kein SQLite-/Revisionsschutz.

## Prüfstatus und genaue Wiederaufnahme

Automatisierte Gegenbeispiele und Positivfälle sind in
`app/test/srd_fighter_tactical_mind_rules_test.dart` ergänzt: Erfolg und weiterer
Fehlschlag, exakter SG, Stufen/Aliase/Mehrklassen, getrennte Ressourcen,
manuelle Summen, Mindestwurf, Vorteil/Nachteil, natürliche 1/20,
fehlende Zustimmung, ungültige Proben/Würfel/Ressourcen, veralteter Charakter,
Wiederholung auch nach kostenlosem Fehlschlag, Immutabilität und JSON-Nachweis.

**Nicht ausgeführt:** Tests, Dart-Formatprüfung, Analyzer, Flutter-/Backend-
und Android-Builds sowie manuelle CI-Läufe. Der Nutzer hat diese Arbeiten
ausdrücklich an den anderen Chat delegiert. Es liegt kein neuer Test-,
APK-, Geräte- oder Integrationsnachweis dieses Pakets vor.

Ausgangsbasis der Entwicklung:
`fe220104f836e146275f1753d327290633b52326`.
Arbeitsbranch: `feat/chat-a/fighter-tactical-mind-20261117`.
Der Stand wird auf dem eigenen Branch gesichert, nicht auf Main integriert.
README und Checkpoints enthalten nur angehängte fachliche Nachträge;
parallele Nachträge müssen bei der Integration vollständig erhalten bleiben.

Nächster konkreter Schritt für die übernehmende Sitzung: aktuellen Main,
PR-Dateilisten und den finalen Branch-HEAD prüfen; zuerst die neue Testdatei
formatieren/analysieren und ausführen, danach den oben beschriebenen
Bestätigungs- und Transaktionspfad integrieren. Insbesondere Abbruch,
doppelte Bestätigung, kostenfreier Fehlschlag, Neustart und veraltete Revision
müssen vor einer Funktionsfreigabe durch echte Ablauf-/SQLite-Tests belegt sein.
