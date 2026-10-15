# SRD 5.2.1 – Waffen- und Rüstungsausrüstung (0.6.0+30)

**Quelle:** https://www.dndbeyond.com/srd (SRD 5.2.1, Equipment und Rules Glossary), Lizenz CC BY 4.0; zusätzliche Auslegung siehe https://www.dndbeyond.com/sources/dnd/br-2024/equipment.

## Bedienung

1. Inventar im Charaktereditor öffnen. Aus dem SRD-Katalog eine Waffe, Rüstung oder einen Schild übernehmen. Alte freie Inventareinträge werden nicht automatisch zu SRD-Gegenständen umgedeutet.
2. „Waffen und Rüstung anlegen / RK berechnen“ öffnen. Bereits besessene SRD-Ausrüstung wählen; vorhandene Übung mit Rüstung/Schild/Waffe bewusst bestätigen. Finesse, beidhändige Führung und Werfen optional einstellen.
3. **Vorschau** prüfen und „Werte übernehmen“ drücken. Erst dann ändern sich die ausgewählten Ausrüstungsreferenzen und die dafür geprüften RK- bzw. Waffengrundwerte im bearbeiteten Charakter. Anschließend den Charakter explizit speichern.
4. Gegenstände können entfernt werden; ausgerüstete Referenzen werden dann gelöscht. Bereits bestätigte RK-/Waffenwerte werden nicht stillschweigend neu gesetzt; eine Warnung verlangt erneute Prüfung.

## Implementierte Regeln

- **RK:** Leichte Rüstung = Basis + voller GE-Modifikator; mittelschwere = Basis + GE (maximal +2, negativer Modifikator nicht auf 0 angehoben); schwere = fester Wert. Schild gewährt +2 RK **nur** bei bestätigter Schildübung. Ohne Rüstung: Grundformel 10 + GE als explizit markierte Vorschau. Nur eine Rüstung und ein Schild; keine additive zweite RK-Formel.
- **Anforderungen:** Schwere Rüstung kann ohne erforderliche ST einen **Bewegungsabzug von 10 Fuß** und Rüstungen einen Heimlichkeitsnachteil erzeugen. Fehlende Rüstungsübung meldet Nachteil auf ST-/GE-W20-Tests sowie blockierte Zauberei. Diese Zustände werden derzeit nur in der Vorschau gewarnt und **nicht** automatisch bei allen Engine-Proben bzw. der Bewegungsrate durchgesetzt.
- **Waffen:** Gewählte Nahkampfwaffen ST, reguläre Fernkampfwaffen GE; Finesse erlaubt GE, Wurfwaffen übernehmen das Nahkampfattribut, Zweihandführung verwendet ggf. den größeren Versatile-Würfel. Angriffsbonus = Attributsmodifikator + Übungsbonus **nur bei bestätigter Waffenübung**. Schaden führt Attributsmodifikator weiterhin über die vorhandene RuleEngine genau einmal hinzu. Schwere Waffen melden Nachteil bei ST/GE unter 13; Reichweite, Munition, Laderegel und Meisterschaften werden gekennzeichnet.
- **Persistenz:** Optionale Inventar-Instanz-IDs `equippedArmorId`, `equippedShieldId`, `equippedWeaponId` sowie explizite Übungsbestätigungen. Alte `schemaVersion: 1`-Saves ohne diese Felder bleiben gültig; ungültige Verweise sind Importfehler. Kein SQLite-Tabellenumbau, keine automatische Währungstransaktion.

## Bekannte Grenzen

- Klassen-, Spezies- und Talent-basierte Rüstungs-/Waffenübungen werden nicht automatisch aus dem gesamten Feature-Set abgeleitet; die Person bestätigt sie momentan ausdrücklich.
- Alternative RK-Formeln (Unarmored Defense, Zauber, magische Boni), Magie-Gegenstände, Einstimmung, Ladungen und Zauberkonzentration brauchen getrennte Regelpakete. Ein Schild darf nicht mit zweihändig geführten Waffen kombiniert werden.
- Munitionsverbrauch, Handmanagement, Reichweitennachteil, Belastung und Heimlichkeitsnachteil sind noch nicht vollständig in sämtliche Kampfaktionen integriert. Das Vorschaufeld `speedPenaltyFeet` ist in Fuß, während das bestehende Editor-Feld „Bewegung“ eigene Einheiten verwendet; kein unprüfbarer Umrechnungs-/Geschwindigkeitswert wird automatisch gespeichert.
- Vervollständigung der Regeln und vollständige Flutter-Tests, Widgettests sowie Android-Build sind vor Freigabe erforderlich. Lokale Python-Projekttests sind kein Ersatz für eine Flutter-CI-Abnahme.
