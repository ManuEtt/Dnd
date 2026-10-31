# SRD 5.2.1 – kanonische Zauberwirkzeiten und Ritualkennzeichen

**Stand:** 30.10.2026 · **Quelle:** Wizards of the Coast LLC, [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), Kapitel *Spells / Casting Time, Reaction and Bonus Action Triggers, Longer Casting Times, Casting without Slots / Rituals*, CC BY 4.0.

## Problem und Schutzgrenze

Das bestehende `SrdSpellDefinition.fromJson` prüft einfache Übereinstimmung zwischen der Zeichenfolge `casting_time` und dem `ritual`-Flag. Die öffentliche `const SrdSpellDefinition`-Konstruktion kann diese Prüfung umgehen. Die generische `SrdSpellPreflightRules.preflight` verwendete bisher nur `supportsSingleTurnPreparation`, das bei `Action` oder `Action or Ritual` sowie `Bonus Action` den allgemeinen Aktionspfad freigab, **ohne** ein widersprüchliches Ritualkennzeichen zu erkennen.

`app/lib/domain/srd_spell_casting_time_rules.dart` stellt nun `SrdSpellCastingTimeRules.inspect` und `requireSingleTurn` bereit. Letzteres ist in die bestehende `SrdSpellPreflightRules.preflight` integriert. Es klassifiziert den vollständig beobachteten Arbeitskatalog mit 339 Einträgen, ohne erfundene oder unscharf interpretierte Zeitangaben:

| Klassifikation | Katalogeinträge | Behandlung der bestehenden generischen Vorprüfung |
| --- | ---: | --- |
| Normale Aktion, ggf. Ritualoption | 256 | weiterhin zulässig, falls alle übrigen Regelbestätigungen bestehen |
| Unbedingte Bonusaktion | 19 | weiterhin zulässig, falls die tatsächliche Bonusaktion extern bestätigt ist |
| Ausgelöste Bonusaktion | 4 | gesperrt; eigener bestätigter Auslöser erforderlich |
| Ausgelöste Reaktion | 4 | gesperrt; eigene Reaktions-/Auslöserregel erforderlich |
| Längere Wirkzeit von 1 Minute bis 24 Stunden | 55 | gesperrt; mehrzügiger Regel-/Konzentrationspfad erforderlich |
| Sonderwirkzeit `Plant Growth` | 1 | gesperrt; spezifische Auswahl/Wirkungsprüfung erforderlich |

Die Zahlen beschreiben **den heutigen transkribierten Projektkatalog**, keine nachgewiesene vollständige offizielle SRD-Abdeckung.

Die geprüften, länger dauernden Grundzeiten sind derzeit exakt `1 minute`, `10 minutes`, `1 hour`, `8 hours`, `12 hours` und `24 hours`, mit einer Ritualoption bei den drei passenden Katalogvarianten. Das ist nur **Lesen von Metadaten**: Es wird keine Spielzeit, Konzentration oder Ressource gebucht. Bei einer Ritualoption darf die normale Wirkzeit weiterhin als reguläre Aktion in der generischen Vorprüfung geprüft werden; die *wirkliche* Ritualvariante bleibt im separaten `SrdRitualCastingRules`-Pfad.

## Fail-closed-Verhalten

- `ritual` muss exakt zur suffixierten Wirkzeit ` or Ritual` passen, auch bei direkt konstruierten Zaubern; keine nachträgliche Rekonstruktion aus Namen.
- Nichtkanonische Schreibung, Leerzeichen an Rändern, Steuerzeichen, Zero-width, BiDi und unbekannte Zeitformate werden abgelehnt.
- Ausgelöste Reaktionen und ausgelöste Bonusaktionen werden **nur** als unbekannte Auslösertexte klassifiziert, nicht automatisch ausgeführt. Eine Fälschung eines solchen Eintrags kann **keine** generische Aktion genehmigen.
- `preflight` prüft vor jeder Ressourcenbuchung, die bereits existierende Snapshot-/Slottransaktion bleibt unverändert.

**Einschränkungen:** Durch diese Metadatenprüfung wird noch **nicht** bewiesen, dass die übergebene Zauberdefinition exakt mit der offiziellen Quelle übereinstimmt. Das Klassifizieren triggerbasierter Zeitangaben ist keine Triggerverifikation. Keine Änderung an Katalog-JSON, bestehenden Spielständen, SQLite-/Event-Schema, Controller, UI, Story oder App-Version. Vollständige Wirkungs-, Reaktions- und länger dauernde Zauberautomatik fehlt weiterhin.

## Regressionen

`app/test/srd_spell_casting_time_integrity_test.dart` prüft acht Gruppen: alle 339 Arbeitskatalogeinträge mit Klassenzahlen und 29 Ritualkennzeichen; reguläre Aktions-/Ritualauswahl; bestätigte Langzeiten; ausgelöste Reaktionen und Bonusaktionen; öffentliche Konstruktor-Fälschungen vor `preflight`; unsichtbare/unbekannte Zeitangaben; Trigger-Masquerading; weiterhin funktionierende legitime Vorprüfung und getrennte Ressourcenbestätigung.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_casting_time_integrity_test.dart
flutter test
flutter build apk --debug
```

Der Anforderungsstand für umfassende SRD-Zauberregeln bleibt **partial**. Vollständige CI nur als bestanden markieren, wenn der genaue finale GitHub-Commit erfolgreich getestet wurde. Ein Android-Realgerätetest und ein unabhängiger Review sind separat erforderlich.
