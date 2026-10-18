# Quellgebundene Zustände: Entwurf für das nächste Inkrement

**Status: ENTWURF, NICHT IMPLEMENTIERT.** Dieses Dokument beschreibt die
Fortsetzung nach den Zugabschluss-/Todesrettungskorrekturen. Es ist kein Nachweis
einer bereits vorhandenen allgemeinen Zustands- oder Dauerengine. Ausgangsbasis
der Untersuchung: `12e148f`, App 0.7.7+47, 17.10.2026. Aktuellen Code und
`CHECKPOINT.md` vor der Umsetzung erneut prüfen.

## Umfang und Regelgrundlage

Ein ausdrücklich bestätigter äußerer Effekt soll dem eigenen Helden einen
benannten Zustand geben. Seine Quelle und sein Ende bleiben von anderen Quellen
desselben Zustands getrennt. Ein bestätigter eigener Kampfzugabschluss kann
ausdrücklich daran gebundene Effekte beenden. Freie Erzählung erzeugt keinen
Effekt; Echtzeit, fremde Züge, allgemeine Zauberdauern und Kreaturenpositionen
werden nicht daraus abgeleitet.

Quelle: offizielles [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0;
Attribution bleibt in `THIRD_PARTY_NOTICES.md`. Die gedruckten Dokumentseiten
wurden im vorhandenen PDF/Text unter `/workspace/scratch/SRD_CC_v5.2.1.*`
überprüft; diese lokalen Hilfsdateien sind kein Bestandteil des Projektpakets.

- S.179, **Condition**: Derselbe Zustand stapelt nicht; Erschöpfung ist die
  Ausnahme. Die verursachende Regel bestimmt das Ende.
- S.179, **Concentration**: Handlungsunfähigkeit oder Tod beendet Konzentration;
  Ende der Konzentration beendet die zugehörige Wirkung. Ein allgemeiner
  Quellenname reicht noch nicht für eine solche Verknüpfung.
- S.184, **Incapacitated**: Keine Aktion, Bonusaktion oder Reaktion; kein
  Sprechen und keine Konzentration. Ein reiner Zugabschluss ist keine Aktion.
- S.52, **Self-Restoration**: Mönch 10 kann am Ende des eigenen Zugs einen der
  Zustände Bezaubert, Verängstigt oder Vergiftet beenden; es wird keine Aktion
  verlangt.
- S.29, **Rage**: Ende bei Handlungsunfähigkeit bzw. am festgelegten eigenen
  Zugende; nachträgliches Entfernen der Handlungsunfähigkeit startet Rage nicht
  erneut.
- S.10, **Dodge**: Vorteil endet unter anderem bei Handlungsunfähigkeit oder
  Bewegungsrate 0.
- S.191, **Unconscious**: Enthält Handlungsunfähig und Liegend; nach Ende der
  Bewusstlosigkeit bleibt Liegend bestehen. Diese zusätzliche Folge braucht
  einen eigenen ausdrücklichen Implementierungs-/Testentscheid.

## Datenmodell: Besitz eines Zustands niemals verlieren

`HeroCharacter` erhält `manualConditions` und `conditionEffects`. Der bisherige
Konstruktorparameter `conditions:` und der gleichnamige `copyWith`-Parameter
behalten zunächst ihre Bedeutung als **manuelle/alte Zustandsliste**. Intern
wird diese Liste unveränderlich als `manualConditions` gespeichert. Der öffentliche
Getter `conditions` liefert die unveränderliche, deduplizierte Vereinigung aus
`manualConditions` und den Zuständen aller aktiven `conditionEffects`.

`copyWith()` muss ohne Zustandsargument die ursprüngliche **manuelle** Liste
und die getrennten Effekte weitergeben, niemals den effektiven Getter.
`isDead` und Regelabfragen verwenden weiterhin die effektive Sicht. Die
bestehenden Pseudozustände `tot` und `stabil` bleiben manuelle/technische Daten;
der neue generische Effektweg nimmt ausschließlich die 14 benannten Zustände aus
`ConditionRules.descriptions` an. Erschöpfung bleibt beim bestehenden Levelmodell.

**Kritische Falle:** `copyWith(conditions: [...hero.conditions])` würde alle
quellgebundenen Zustände zu manuellen Dauerzuständen machen. Ein Effekt ließe sich
danach nicht mehr korrekt durch Quellenentfernung beenden. Alle Mutatoren müssen
deshalb im selben Inkrement angepasst werden, bevor die Union aktiviert wird.

Ein `ConditionEffect` braucht mindestens:

| Feld | Bedeutung und Validierung |
| --- | --- |
| `id` | Nichtleere eindeutige Effektinstanz-ID; unabhängig vom Quellnamen |
| `condition` | Exakter unterstützter kanonischer Zustand, keine Synonymnormalisierung alter Texte |
| `source` | Bestätigte beschreibende Quelle, getrimmt, 1–200 Zeichen; keine ausgedachte Kreaturenidentität |
| `expiresInEncounterId` | Nur zusammen mit einem Zugendpunkt; eindeutige aktuelle Begegnung beim Anlegen |
| `expiresAtOwnTurnEndRound` | Optionaler positiver ganzzahliger Endpunkt; nur eigener bestätigter Zugabschluss der gebundenen Begegnung löst ihn aus |

Für das erste Inkrement genügen die Dauern „Bis zur ausdrücklichen Entfernung“,
„Bis Ende deines aktuellen Zugs“ und „Bis Ende deines nächsten Zugs“. Endpunkte
werden beim Bestätigen aus der aktuellen Begegnung abgeleitet, nicht als freie
Benutzereingabe oder KI-Feld übernommen. Ohne aktive Begegnung werden nur
manuell zu beendende Effekte angeboten. Längere Zeitspannen bleiben offen.

Beendet ein Kampf sich vor dem vorgesehenen Zugende, darf dies weder eine
fiktive Runde erzeugen noch einen zeitlich fortbestehenden Zustand automatisch
löschen. Effekt erhalten, automatische Dauer als pausiert anzeigen und gezielte
Entfernung anbieten. Kein Abgleich mit Rundennummern einer späteren Begegnung.
Alte Begegnungsreferenzen dürfen daher bei Wiederherstellung existieren; die
Engine muss sie inaktiv behandeln. Freie Spielzeit benötigt ein späteres Modell.

## Mutation und Persistenz

Neue reine Domänenoperationen: Effekt hinzufügen, genau eine Effekt-ID beenden,
einen benannten Zustand ausdrücklich über alle Quellen beenden und am eigenen
Zugende passende Effekte ablaufen lassen. Keine Operation löscht aufgrund eines
gleichen Quellnamens mehrere Instanzen. Unbekannte ID, doppelte ID,
unzulässiger Zustand oder inkonsistente Dauer werden vor einer Mutation
abgewiesen. Effekt-ID-Duplikate und Ereignis-ID-Idempotenz sind getrennte Dinge.

`toJson()['conditions']` enthält ausschließlich `manualConditions`; ein
optionales neues Feld `conditionEffects` enthält die strukturierte Liste.
`fromJson` versteht Altdateien ohne dieses Feld als leere Effektliste. Beide
Listen bleiben ausdrücklich getrennt, auch wenn derselbe Zustand in beiden
steht. Keine SQL-Strukturänderung ist nötig, solange nur das bestehende
Snapshot-JSON erweitert wird. Die rückwärtskompatible additive Erweiterung und
die strenge Importvalidierung dokumentieren; bei einer späteren strukturellen
Änderung Schema-/Importversion tatsächlich erhöhen und migrieren.

Die öffentlichen Aktionen folgen dem bestehenden Effektweg:
`GameEngine` validiert und berechnet, `GameController` prüft Kampagnen-ID und
erwartete Revision, das Repository schreibt Snapshot und Ereignis atomar.
Dialogabbruch und veraltete Revision ändern nichts. Offene Würfel-/Todesrettungs-
entscheidungen blockieren äußere Effekte wie die bisherigen Effektaktionen;
keine veralteten Würfelboni nachträglich verwenden.

Ereignisse enthalten Effekt-ID, Quelle, Ziel-ID, Zustand, bestätigten Endpunkt,
entfernte/abgelaufene IDs sowie Konzentrations-/Ragefolgen. Die Berechnung
interpretiert keinen freien Quelltext als offizielle Zauber- oder Monstermechanik.

## Vollständige Änderungsstellen

Die folgende Liste bezieht sich auf die tatsächlich untersuchten Dateien;
vor Implementierung erneut `rg -n '\.conditions|conditions:' app/lib` ausführen.
Neu hinzugekommene Mutatoren gehören in dieselbe Prüfung.

| Datei | Erforderliche Änderung |
| --- | --- |
| `app/lib/domain/models.dart` | Backinglisten, Getter, Konstruktor/copyWith, JSON, strenge Effektvalidierung; bestehende Kampagnen-/PendingRoll-Validierungen lesen effektive Zustände |
| `app/lib/domain/rules_engine.dart` | `damage` kopiert `manualConditions` und ergänzt HP-bedingte technische Zustände; `heal` entfernt daraus bisherige HP-bedingte Bewusstlosigkeit/Stabilität, lässt unabhängige Quellbewusstlosigkeit bestehen |
| `app/lib/domain/death_saving_throw_rules.dart` | Neue Todesrettungsauflösung kopiert `manualConditions`, nicht effektive Union; natürliche 20 übernimmt dieselbe quellenbewahrende Heilung |
| `app/lib/domain/condition_rules.dart` | `ExhaustionRules.gain` ergänzt `tot` in der manuellen Liste; alle lesenden Regelabfragen bleiben effektiv |
| `app/lib/domain/monk_self_restoration.dart` | Auswahl anhand effektiver Zustände; bestätigtes Beenden eines Zustands entfernt diesen aus manueller Liste und sämtlichen Effektinstanzen dieses Zustands |
| `app/lib/domain/paladin_lay_on_hands.dart` | Vergiftet-Prüfung effektiv; bestätigte Entfernung beendet Vergiftet über alle Quellen und manuelle Einträge |
| `app/lib/domain/game_engine.dart` | Hinzufügen/Entfernen und zentraler Zugendrand; Ereignisse/Erzählung; bestehende stabile-/tote-Prüfungen lesen effektiv |
| `app/lib/services/game_controller.dart` | Neue Aktionen mit erwartetem Revisionsstand über vorhandene Transaktion; normale JSON-Revalidierung muss Effekte erhalten |
| `app/lib/ui/character_editor.dart` | Initialisierung, Speichern und `_draftForSpellcasting` bearbeiten nur JSON-Manualliste; kompletten ursprünglichen Effektblock erhalten; Feld als „Manuelle Zustände“ beschriften und Effekte separat darstellen |
| `app/lib/ui/app.dart` | Vorhandene Vergiftet-/Klassenabfragen lesen effektiv; `_showInventory` darf für Zustandsanzeige nicht mehr bloß `hero.toJson()['conditions']` verwenden |
| `app/lib/ui/fantasy_character_sheet.dart` | Effektive Zustandswirkungen anzeigen, dazu getrennt Quelle und Dauer bzw. pausierte Automatik; überlappende Quellen sichtbar halten |
| `app/lib/domain/healing_spell_rules.dart`, `app/lib/ui/healing_spell_dialog.dart` | Bestehende Sicht-/Komponentenprüfungen lesen effektive Zustände; keine manuellen Listen verwenden |
| `app/lib/domain/character_effect_rules.dart` | Bestehende Abwehr-/Konzentrationsprüfungen bleiben effektiv; Quellzustände bei Schaden/Konzentrationsverlust nicht pauschal löschen |

Eine gewöhnliche TP-Heilung beendet keinen ausdrücklich unabhängig verursachten
Bewusstlos-Effekt. Das bisherige Verhalten manueller/alter Bewusstlos-Einträge
bleibt erhalten, bis deren Herkunft gesondert migriert werden kann. „Zustand
beenden“ durch eine bestätigte passende Regel ist dagegen eine andere Operation
und entfernt alle Instanzen dieses Zustands. „Diese Quelle beenden“ entfernt nur
ihren eigenen Effekt.

## Zugrand und sofortige Folgen

Die parallele Entwicklung bearbeitet bereits den reinen Zugabschluss und die
Klassen-Todesrettung. Vor Umsetzung dieses Entwurfs deren tatsächlichen finalen
Code lesen; die folgenden Punkte sind Anforderungen, kein Fertignachweis:

1. „Zug beenden“ und Mönch-Endauswahl vor dem pauschalen Aktionsguard bearbeiten.
   Handlungsunfähigkeit erlaubt dadurch weder Ausweichen noch Ressourcenaktionen.
   Stabile 0-TP-Figuren brauchen ebenfalls einen erreichbaren reinen Endpfad.
2. Nur `_enemyTurn(advanceRound: true)` bzw. der daraus extrahierte zentrale
   eigene Endrand darf eigene Dauer verkürzen. `advanceRound: false` beim
   feindlichen Erstzug tut dies nicht. Abgewiesene Texte, Bewegungen,
   Bonusaktionen und einzelne Extra-Attack-Würfe erzeugen kein Zugende.
3. Ablauf, Mönch-Selbstwiederherstellung und Rage-Ende vor dem Gegnerangriff
   auswerten. Verfügbare Mönch-Auswahl am Rand erneut validieren; ein bereits
   abgelaufener Zustand darf keinen alten Dialogentscheid zum Fehler machen.
4. Neue Handlungsunfähigkeit beendet Konzentration und Rage sofort. Rageflag
   wirklich löschen, damit Zustandsentfernung Rage nicht wiederbelebt.
   Dodge bei Handlungsunfähigkeit/Bewegungsrate 0 verlieren lassen.
5. Eigene Todesrettung pro Zug und ausstehende Klassenwiederholung zuerst
   abschließen. Keine zweite Probe, keine Dauerverkürzung durch bloße
   Ergebnisvorschau und kein Gegnerangriff vor endgültiger Annahme/Wiederholung.
6. Durch Ablauf wiedergewonnene Handlungsfähigkeit startet keine alte
   Konzentration, Rage oder Dodge-Wirkung neu. Bewegung erst am tatsächlichen
   nächsten Zugbeginn neu berechnen; kein pauschales Auffüllen mitten im Zug.

## Verbindliche Testfälle für die Umsetzung

- Zwei Quellen für Vergiftet: Zustand wirkt einmal; erste Quelle entfernen
  lässt die zweite bestehen; letzte Quelle entfernen beendet nur deren Zustand.
- Zusätzlicher manueller Vergiftet-Eintrag bleibt nach Quellenablauf bestehen.
  Umgekehrt bleibt ein Quelleffekt nach Löschen des manuellen Eintrags bestehen.
- Schaden, Heilung, temporäre TP, natürliche Todesrettung 20, andere
  Todesrettungen, Erschöpfungstod, Rast und `copyWith()` befördern keine
  Quellzustände in die manuelle Liste und verlieren keine Effektmetadaten.
- Handauflegen/Selbstwiederherstellung beenden sämtliche Quellen des ausdrücklich
  gewählten Zustands; andere Zustände und Ressourcen bleiben korrekt erhalten.
- Unabhängige Quellbewusstlosigkeit bleibt nach TP-Heilung bestehen; normale
  HP-bedingte Altbewusstlosigkeit endet weiterhin. Liegend-Folge separat prüfen,
  falls im Inkrement implementiert.
- Aktuelles/nächstes Zugende: genaue Grenze, mehrere Angriffe, Bonusaktion,
  Action Surge, Gegnererstzug, reines Beenden bei Betäubt und stabilem 0 TP,
  Dauerwirkung auf den unmittelbar folgenden Gegnerangriff.
- Hinzufügen von Handlungsunfähigkeit beendet Konzentration/Rage/Dodge sofort;
  anschließendes Entfernen stellt diese Wirkungen nicht wieder her.
- Kampfende ohne weiteren eigenen Zug und spätere neue Begegnung entfernen
  keinen alten Effekt aufgrund einer zufällig gleichen Rundennummer.
- Alt-JSON ohne Effekte, JSON-/SQLite-Neustart, Export/Import, Editor ohne
  Zustandsänderung und Editor mit Änderung manueller Zustände erhalten Besitz
  und Endpunkt byte-/wertgetreu.
- Unbekannter Zustand, leere/zu lange Quelle, doppelte IDs, ungültige Typen,
  halber Endpunkt und negative Dauer: Import/Aktion vollständig abweisen.
- Dialogabbruch, Revisionskonflikt, doppelte Ereignis-ID und SQLite-Triggerfehler
  nach Schreibbeginn: keinerlei Teiländerung; Wiederholung nach Neustart sicher.
- Deutsche Dialog-/Blattansicht bei schmaler Breite: Quelle, Dauer, überlappende
  Instanzen und gezielter Entfernenknopf sind verständlich und erreichbar.

Abschluss erst nach beobachtet erfolgreichen Domain-, Widget-, echten SQLite-
und Regressionstests, Formatprüfung und Analyse dokumentieren; Android-Build und
Geräteabnahme weiterhin getrennt ausweisen. Danach `RULE_COVERAGE`, Changelog,
Entwicklungsstatus und Checkpoint aktualisieren und vollständiges ZIP/Patch
erstellen. Bis dahin bleibt `EFFECT-SOURCE-DURATION` nicht implementiert.
