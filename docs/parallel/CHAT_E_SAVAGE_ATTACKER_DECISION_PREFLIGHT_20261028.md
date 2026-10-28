# Chat E – Wilder Angreifer: revisionsgebundene Auswahlvorprüfung

**28.10.2026 – abhängiges Paket auf dem offenen PR #338.**

Neue zustandsfreie Domain-Grenze `SrdSavageAttackerDecisionPreflight.preview` verbindet einen **ausdrücklichen UI-Auswahlwunsch** (nur Angriff-ID, Gegner-ID, erwartete Revision und Boolean für zweiten Wurf) mit den **vollständigen, gespeicherten** Würfeln aus dem bereits separaten `Campaign.pendingSavageAttackerHit`.

Die Grenzen prüfen Roll-/Gegneridentität, erwartete Kampagnenrevision, ursprüngliche Angebotsrevision, Kampf-/Rundenzustand, konkurrierende offene Proben und Reaktionen, Talentberechtigung und die exakten Einzelwürfel. Die beiden Kandidaten werden durch den bestehenden `SrdSavageAttackerDamageComparisonRules.compare` unter denselben Klassen-/Kampfstilregeln wie echter Waffenschaden verglichen. Höhere Werte werden **nicht automatisch** ausgewählt. Die Funktion liest weder einen UI-Schadenswert noch behauptet sie, ein Treffer sei mit kryptografischer Sicherheit aus einem gespeicherten JSON entstanden.

**Nicht implementiert:** Automatische Erzeugung aus einem wirklichen, noch nicht verbuchten Waffentreffer, Android-Anzeige/Verknüpfung, finaler GameEngine-/GameController-Commit von Gegner-TP, Sneak-Attack, Rage, Questfolge und Talentnutzung. Diese atomare Aktion muss der vertrauenswürdige Kampfcontroller nach einer neuen Repository-Lese-/Revisionskontrolle bereitstellen. Bis dahin **nur eine Vorschau**, keine HP-Änderung und kein Talentverbrauch.

Neue Dart-Tests prüfen beide Spielerentscheidungen, kritische Treffer, Alt-/Neu-Speichern, falsche IDs, alte Revision, mehrfache Nutzung, fehlerhafte Würfel und konkurrierende offene Entscheidungen. Keine Änderung an Modell-, Story-, Datenbank- oder Controllercode. Abhängigkeit auf PR #338 getrennt belassen, nicht ungeprüft nach main mergen.

SRD-Regelgrundlage: [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), `Feats: Savage Attacker` (CC BY 4.0).
