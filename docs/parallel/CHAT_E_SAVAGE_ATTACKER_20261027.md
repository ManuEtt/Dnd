# Chat E – Wilder Angreifer: geprüfte Würfelwahl (27.10.2026)

## Implementiert
D&D SRD 5.2.1, `Savage Attacker` (*Origin Feat*): Bei einem **bestätigten Waffentreffer** dürfen einmal pro Zug die Waffen-Schadenswürfel zweimal geworfen und **einer der beiden Würfe bewusst gewählt** werden. Anders als die ältere D&D-Version gilt die 2024-SRD-Regel auch für Fernkampfwaffen. Eine automatische Maximalauswahl findet nicht statt. Kritische Treffer prüfen je zwei getrennte vollständige Waffenwürfel-Pakete. Flache Waffenmodifikatoren werden nicht verdoppelt; Sneak Attack, Rage, Fighting Style, Magie und andere separate Schadensquellen werden nicht angetastet.

Die neue reine, typisierte Regelgrenze `SrdSavageAttackerRules.choose` nimmt ausschließlich zwei vollständige Würfelnachweise für denselben kanonischen Waffenschadensausdruck an, prüft Würfelgrenzen, alle Teilsummen, Kritischen Treffer, expliziten Waffentreffer, bestätigten Waffenkontext und ein noch nicht in diesem Zug genutztes Talent. Sie akzeptiert kein bloßes Freitext-Talent: nur ein bestätigtes Soldat-Hintergrundpaket bei übereinstimmendem Hintergrund. Manuelle Gesamtsummen sowie veränderte/ungültige Würfel werden verworfen.

## Bewusste Teilabdeckung
**Noch nicht automatisch spielbar:** Die eigentliche GameEngine-/GameController- und UI-Anbindung, das sichere `alreadyUsedThisTurn` aus revisionsfestem Kampfrundenstatus, Ressourcencommit sowie eventuelle bestätigte Waffen-Kontextprüfung. Derzeit wird weder eine zweite Schadensprobe in einem echten Kampf ausgelöst, noch ein Gegner-TP-Wert geändert. Die beiden booleans `confirmedWeaponHit` / `confirmedWeaponAttack` sind **Verträge für vertrauenswürdigen Regelcode**, keine aus Spielertext zu übernehmenden Zusagen. Den Helfer nicht unvalidiert mit KI-Daten benutzen. Die SRD-Abdeckung bleibt `partial`.

## Tests
Neue Domain-Regressionen: dokumentierte Herkunftsquelle und Alt-JSON, freie Talente-Fakes, beide bewusst erlaubten Auswahlrichtungen, Treffer-/Waffen-/Nutzungsgrenzen, Kritische, manipulierter Würfelnachweis, nicht-kanonische Würfelnotation und unveränderte Spielstände. Keine SQLite-/JSON-/Android-Versionsänderung.

**Nächster Schritt:** eigenständige, bestätigungsgebundene UI, revisionsgeschütztes `usedThisTurn` im Encounter, atomare Schadensabwicklung und Android-Geräteabnahme.

Quelle: [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), `Feats / Savage Attacker`, © Wizards of the Coast LLC, CC BY 4.0.
