# Chat A – Sicherheitsgrenze bei SRD-Zaubertrigger-Metadaten

Quelle: Wizards of the Coast LLC, *System Reference Document 5.2.1*, Abschnitt `Spells / Casting Time / Reaction and Bonus Action Triggers`, CC BY 4.0. https://www.dndbeyond.com/srd

## Fehler und Akzeptanz

Die Reaktions- und Bonusaktions-Wirkzeiten des Arbeitskatalogs enthalten die ausdrückliche Auslöserbeschreibung. Das lokale `inspect` klassifizierte über den Präfix hinaus bislang ungefilterte versteckte Zeichen U+206A–U+206F und U+FFF9–U+FFFB als Teil des Triggers. Ein per öffentlichem Konstruktor manipuliertes `SrdSpellDefinition` durfte keine irreführenden Formatzeichen in einen als plausibel bewerteten Auslöser schmuggeln. Weder ein Preflight noch eine Ressourcenbuchung dürfen aus dieser Klassifikation automatisch abgeleitet werden.

## Änderung

`app/lib/domain/srd_spell_casting_time_rules.dart`: zwei weitere Unicode-Bereiche in bestehendem Steuerzeichen-RegEx abweisen. Die schon unterstützten Wirkzeiten bleiben unverändert und unbekannte Auslöser erhalten dadurch keine automatischen Rechte.

`app/test/srd_spell_casting_time_control_guard_test.dart`: acht bekannte Auslöser (vier Reaction, vier ausgelöste Bonus Action) bleiben klassifizierbar und werden vom allgemeinen Single-Turn-Preflight nicht autorisiert. Neun verborgene Codes in jedem bestätigten Auslöser müssen in `inspect` und `requireSingleTurn` als `FormatException` scheitern. Eine unveränderte normale Action bleibt gültig. Keine zufallsabhängigen Ergebnisse.

## Grenzen / Veröffentlichung

Ein textuell korrekt erscheinender, aber einem anderen Zauber zugeordneter Trigger wird in diesem Inkrement nicht anhand einer amtlichen individuellen Zauber-Signatur autorisiert. Keine Cast-Transaktion, keine Persistenz oder Migration, keine Versionsänderung. CI auf PR #500 und Android-Gerätetest separat prüfen. Historische grüne CI anderer Commits wird nicht als aktueller Nachweis verwendet.
