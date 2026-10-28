# Chat A – SRD 5.2.1 Klassenautomatik: Barbar 18 (28.10.2026)

## Fachgrundlage

- Anforderung: CLASS-BARBAR-18-BASE-INDOMITABLE-MIGHT-0.
- Quelle: D&D SRD 5.2.1, Classes / Barbarian / Level 18: Indomitable Might, veröffentlicht unter CC BY 4.0; https://www.dndbeyond.com/srd.
- Wirkung: Liegt das nach Bonus/Malus ermittelte Gesamtergebnis einer Stärke-Attributsprobe oder eines Stärke-Rettungswurfs unter dem bestätigten Stärke-Attributswert, kann der höhere Attributswert gelten. Kein Mindestwert für den natürlichen W20; keine Anwendung bei Angriffen, Initiative, Todesrettungswürfen oder anderen Attributen.

## Implementiert

- app/lib/domain/srd_indomitable_might_rules.dart: reine, deterministische Prüfung von Klassenstufe (einschließlich Mehrklassen), Attribut, Wurfart und Gesamtwert; unbekannte Stärke wird nicht erfunden.
- app/lib/domain/game_engine.dart: bei bestätigter lokaler preparedCheck-Stärke-Probe und manuellem Stärke-Rettungswurf wird der effektive Wert für die SG-Entscheidung verwendet. Der ursprüngliche Wurf bleibt im Event (roll) erhalten. Wenn das Merkmal eine Änderung bewirkt, werden classFeature: indomitableMight und das effektive Ergebnis ergänzt. Bei manuellen Saves bleibt zusätzlich rawTotal erhalten.
- app/lib/domain/srd_class_feature_catalog.dart, app/lib/domain/srd_class_automation.dart, app/lib/rules/rules_api.dart: Teilabdeckung sichtbar und Regelbaustein exportiert.
- app/test/srd_indomitable_might_rules_test.dart: Fälle für Stufe 17/18, Mehrklassen, andere Wurfarten, unbekannte Werte, unveränderte JSON-Daten, manuelle Stärke-Rettung, andere Rettung und vorbereitete Athletik-Probe in Rabenwacht.

## Nachweisstand

- IMPLEMENTIERT: oben genannter Code auf dem Feature-Branch.
- TESTS ERGÄNZT, ABER NICHT LOKAL AUSGEFÜHRT: Flutter/Dart nicht in dieser Arbeitsumgebung installiert. Ein Testdateiname allein ist kein Erfolgsnachweis.
- NICHT GETESTET: vollständige CI inklusive Analyse/Formatierung, andere Kampagnen, Android-Build, Emulator und Gerät.
- NOCH NICHT IMPLEMENTIERT: Übernahme des Merkmals in sämtliche unabhängigen Rettungswurf- und Probenquellen (z. B. Konzentration, Fremdeffekte und andere bestätigte Regelereignisse); daher rule_implemented: partial.
- Nächster Schritt: CI-Ergebnis prüfen und konkrete Fehler beheben; anschließend alle Save-/Check-Entry-Points zum gemeinsamen Adjudikationspfad führen, ohne das bestehende schemaVersion-1-Format zu ändern. Danach die übrigen Klassen-Freischaltungen einzeln mit amtlicher Quelle, Mechanik und Tests abschließen. Die 282 Katalogeinträge sind keine 282 getesteten Features.

Keine fremden Branches verändert oder gelöscht; keine Main-Branch-Mutation. Kein KI-Text autorisiert eine mechanische Zustandsänderung.
