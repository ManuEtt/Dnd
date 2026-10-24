# Hinterhältiger Angriff: tatsächliche Angriffswaffe

Version 0.8.38+88, Basis-main `dcb42c5efff40a757994d4f5b5f8e98b2ff128e9`.
Arbeits-ID `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt **partial**.
Quelle: [offizielles SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
Rogue / Sneak Attack, S. 61–62, CC BY 4.0. Namensnennung siehe THIRD_PARTY_NOTICES.md.

## Fehler und Änderung

Die Waffeneignung verlangt, dass der konkrete Angriff eine Finesse- oder
Fernkampfwaffe verwendet. `eligibleSneakAttackDice` verwendete bisher immer
`hero.equippedWeaponId`, auch wenn GameEngine eine andere bestätigte Nebenhandwaffe
aus `pendingRoll.weaponId` auflöste. So konnte eine Handaxt einen Dolchangriff
unberechtigt sperren oder ein Hauptdolch einer Nebenhandaxt Zusatzschaden gewähren.

Der reine Helper akzeptiert jetzt optional `attackingWeaponId`. Ohne Angabe bleibt
die bestehende Hauptwaffenberechnung erhalten. Eine explizite leere, fehlende,
mehrdeutige oder verbrauchte Inventarreferenz ergibt keine Eignung; kein Rückfall
auf die Hauptwaffe. GameEngine übergibt für die vorhandene Nebenhandauflösung die
bereits durch `TwoWeaponFightingRules.confirmedOffhand` geprüfte Inventar-ID.

## Abnahmekriterien

- Beide gemischten Waffenrichtungen im tatsächlichen Kampfablauf prüfen.
- Eignung verändert ausschließlich den zulässigen Sneak-Zusatzschaden; kritische
  Treffer verdoppeln nur zulässige Würfel, ein Fehlschlag verbraucht keine Nutzung.
- Vorteil/Nachteil und bereits verbrauchter Hinterhältiger Angriff bleiben wirksam;
  Haupt- und Nebenhand teilen dieselbe bestehende Nutzung pro eigenem Zug.
- Offene Probe mit Waffen-ID und bestätigtem Vorteil über die normale
  JSON-/SQLite-Grenze laden und mit Controller auflösen; Journal und Schaden prüfen.
- Alte Aufrufe ohne Waffenargument sowie Hauptwaffen-Verbündetenbestätigung bleiben
  unverändert. Vollständige Format-/Analyse-/Flutter-/Backend-/Python-Prüfung sowie
  Android-Build/native Tests vor Freigabe beobachten.

## Oberfläche, Speicherung und Grenzen

Die vorhandene Abenteueraktion „Nebenhandangriff mit …“, die Würfelauflösung und
das Schadensjournal nutzen die korrigierte Regel direkt. Kein zusätzliches Menü
oder katalogbasierter Platzhalter. Bestehende Nebenhandvoraussetzungen einschließlich
Kampfstil und Bonusaktion werden nicht erweitert. Die Korrektur erfindet keinen
Vorteil; ein gespeicherter Vorteilsfakt muss bereits bestätigt sein.

SQLite 2, Kampagnen-JSON 1, PendingRoll und Ereignisformat bleiben unverändert.
Keine KI-/Story-Abhängigkeit oder neue Datenmigration. Allgemeine Positionsverwaltung,
Verbündetenbestätigung für Nebenhand und Gelegenheitsangriffe bleiben offen.
Prüfergebnisse und konkreter Git-/CI-Stand: [CODEX_CHECKPOINT.md](CODEX_CHECKPOINT.md).
