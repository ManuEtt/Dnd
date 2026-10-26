# Heilige Flamme – gültige klassenbezogene Zauberwerte

**Requirements:** `SPELL-ENTRY-SACRED-FLAME` und `RULE-SPELLS-SPELL-SAVE-DC`, beide weiterhin **partial**.

**Quelle:** amtliches [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), *Multiclassing / Proficiency Bonus / Spellcasting* S.25 und *Cleric / Spellcasting Ability* S.37. Wizards of the Coast LLC, CC BY4.0; bestehende [Namensnennung](../THIRD_PARTY_NOTICES.md) erhalten. PDF SHA256 `8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87` geprüft. Zauberklasse bestimmt Attribut; Übung kommt aus Gesamtstufe.

## Nachgewiesener Fehler

Bestehende Importe dürfen historische freie Klassennamen behalten. Die bloße Mitgliedschaft irgendeiner Klerikerklasse genügte Heilige Flamme aber auch für `Cleric/Kleriker` als kanonisch doppelte Klasse und `Unbekannt/Kleriker`. Der tatsächliche GameEngine-Pfad erhöhte die Revision, verbrauchte die Aktion und änderte Gegner-TP30→28. Sieben zusätzliche Domain-Klassenfälle belegten das Problem zuerst am unveränderten alten Code.

## Korrektur und Akzeptanz

- Geprüften Klassenwerte-Rechner aus PR #184 im tatsächlichen `SacredFlameRules.cast` verwenden, mit fest zugeordnetem Kleriker und bestehender ausdrücklicher Bestätigung unmodellierter SG-Boni.
- Klassenstruktur, kanonische Aliase, eigene Klasse, Stufen und WIS validieren, bevor Ressourcen oder Würfel benutzt werden. Ungültige Aktionen ohne Teiländerungen ablehnen.
- Für gültige importierte Bestandsprofile WIS + Übung der Gesamtstufe unverändert: Wizard5/Cleric1, INT20/WIS12 liefert SG12. Dies ist kein neuer Klassenaufstieg und keine nachträgliche Freigabe von Multiclass-Voraussetzungen.
- Keine globale Importverschärfung, kein automatisches Umschreiben historischer Klassennamen und keine rückwirkende Änderung alter Ereignisse. SQLite2/JSON1 unverändert.
- Dialog zeigt Basiswerte erst nach vorhandener SG-Bestätigung; keine künstlich vorbelegte Zustimmung. Ungültige Profile werden vor Bestätigung erkennbar. Gemeinsames Scrollen von Titel und Inhalt hält die Prüfung bei großer Schrift/Tastatur bedienbar.

## Tests und Grenzen

`sacred_flame_rules_test.dart`: sieben zuvor fehlschlagende Klassenfälle, gültige Multiclasskontrolle und bestehende Wirkungsregeln. `sacred_flame_class_validation_storage_test.dart`: reale Importe/Controller/SQLite, Ablehnung vor RNG, gültige WIS-Wirkung, Journal/Replay/Neustart, Stale Revision und Event-Insert-Rollback. `sacred_flame_class_stats_dialog_test.dart`: bestätigungsgebundene Vorschau, ungültige Klassen, gültige Rückgabe und 360dp/1,8×Schrift/Tastatur.

Automatische Monsterwerte, ungeprüfte Magieboni, zusätzliche Ziele und reale Geräteabnahme bleiben offen. Das Paket ersetzt keine vollständige SRD-Implementierung. Vollständige Abnahme nur nach tatsächlicher Gesamtsuite und finaler eigener CI dokumentieren.
