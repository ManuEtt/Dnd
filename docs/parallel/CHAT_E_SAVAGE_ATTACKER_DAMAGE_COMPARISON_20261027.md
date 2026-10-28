# Chat E – Wilder Angreifer: echte Waffen-Schadensberechnung vergleichen

**Stand:** 27.10.2026, isoliertes SRD-5.2.1-Entwicklungspaket.

Die Auswahloberfläche aus PR #315 und die Würfelnachweisprüfung aus PR #286 werden durch eine **lesende Schadensvergleichs-Regel** ergänzt, die für beide Waffenwürfelpakete `RulesEngine.weaponDamageSubtotal` aufruft, statt nur die Rohwürfel-Differenz zu addieren. Das verhindert Fehler mit *Kampf mit großen Waffen* (GWF): niedrige Würfel werden je Wurf getrennt auf mindestens 3 angehoben, auch bei kritischen zusätzlichen Waffenwürfeln. Der reguläre Attributs- und flache Waffenbonus wird nur einmal addiert; Sneak Attack, Rage und sonstige Quellen bleiben außerhalb der Waffen-Vorberechnung.

`SrdSavageAttackerDamageComparisonRules.compare` prüft dieselbe bestätigte Soldaten-Herkunft und den unverbrauchten eigenen Zug wie die bisherige Regelgrenze und verifiziert über `SrdSavageAttackerRules.choose` beide vollständigen Würfelnachweise, einen echten Waffentreffer und die explizite Spielerentscheidung. Sie lässt nur die in `HeroCharacter.weaponDamage` bestätigte **Hauptwaffe** zu; Nebenhandangriffe brauchen eine separate zweitwaffengerechte Abrechnung.

**Sicherheit / offener Schritt:** Diese Funktion erzeugt einen **Schadensvergleich**, keinen gebuchten Angriff. Sie verändert weder Kampagnenrevision, Gegner-TP noch `savageAttackerUsedThisTurn`. In einem nächsten Paket müssen der nach einem Treffer angebotene Dialog, persistierte Original-/Alternativwürfel, Angriffskontext und Revisionsprüfung in einer atomaren Controller-/SQLite-Aktion vereint werden. Ein gestohlener oder veralteter UI-Wert darf keinen Schaden auslösen. Keine Versions- oder Schemaänderung.

Regelgrundlage: [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), `Feats: Savage Attacker`, CC BY 4.0.
