# Version 0.7.0+40 – Mönchsfokus und defensive Bonusaktionen

## Regelgrundlage

D&D SRD 5.2.1, Klasse Mönch, Monk's Focus: Patient Defense und Step of the Wind; Klasse Schurke, Cunning Action. Siehe [offizielle SRD-Übersicht](https://www.dndbeyond.com/srd).

## Ausführbare Aktionen

Innerhalb einer laufenden Begegnung (nach `Ich gehe zum Waldschrein`):

| Eingabe | Voraussetzung | Effekt |
| --- | --- | --- |
| `Geduldige Verteidigung` | Mönch 2, freie Bonusaktion | Rückzug, 0 Fokus |
| `Geduldige Verteidigung mit Fokuspunkt` | wie oben, mindestens 1 Fokuspunkt | Rückzug + Ausweichen bis zum nächsten Gegnerangriff, 1 Fokus |
| `Schritt des Windes` | Mönch 2, freie Bonusaktion, bewegungsfähig | Sprinten (Dash), 0 Fokus |
| `Schritt des Windes verstärkt` | wie oben, mindestens 1 Fokuspunkt | Sprinten + Rückzug; doppelter Sprungwert für den Zug als Status vermerkt, 1 Fokus |
| `Flinke Aktion: Rückzug` | Schurke 2, freie Bonusaktion | Rückzug, 0 Ressourcen |

Bei Aktionen, die Sprinten enthalten, wird die **aktuelle effektive Bewegungsrate** addiert. Monk's Focus wird mit der vorhandenen `spentClassResources.focusPoints`-Verwaltung verrechnet und bei einer Rast gemäß bestehender Engine regeneriert. Kein zusätzlicher Klassenstufen-Bonus aufgrund der Gesamtstufe bei Mehrklassencharakteren.

## Sicherer Kampfablauf

- `bonusActionUsed` sperrt weitere Bonusaktionen im selben Zug, auch für Second Wind, Kampfrausch und Flinke Aktion.
- `dodgeActive`, `disengagedThisTurn` und `jumpDoubledThisTurn` sind optionale Begegnungsfelder. Sie bleiben beim Speichern/Laden erhalten; in alten Spielständen sind sie standardmäßig `false`.
- Ein Gegnerangriff erhält Nachteil, wenn `dodgeActive` gilt; andere Vorteilsquellen werden vom bestehenden Würfelsystem berücksichtigt. Nach dem Gegnerzug werden die temporären Flags zurückgesetzt.
- Nicht bestätigte Bedingungen, Reichweiten und taktische Positionen werden **nicht erfunden**.

## Bewusste Grenzen

- Gelegenheitsangriffe und Sprungweiten sind in der vorhandenen vereinfachten Begegnung noch nicht vollständig als Karten-/Geometriesystem umgesetzt; die Freigabewirkung und das doppelte Springen sind als Zustand erfasst, aber nicht geometrisch simuliert.
- Mönchs-Focus-Option Flurry of Blows, Stufe-10-Sonderboni (temporäre TP, Mitnahme einer Kreatur) und Unterklassen-Fähigkeiten benötigen zusätzliche Kampfaktionen und/oder Datenmodelle. Diese werden **nicht** als fertig bewertet.
- Flutter-/Dart-Tests liegen bei; ein erfolgreicher Android-Build ist vor Auslieferung der APK erforderlich. Schema-Version 1 bleibt unverändert.
