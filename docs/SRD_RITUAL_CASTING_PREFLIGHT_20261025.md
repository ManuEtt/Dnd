# Chat A – SRD 5.2.1 Ritualzauber: konservative Vorprüfung

**Quelle:** Wizards of the Coast, *System Reference Document 5.2.1*, Abschnitt *Spells → Casting a Spell → Casting without Slots → Rituals* und *Longer Casting Times*, CC BY 4.0: https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf; https://www.dndbeyond.com/srd. Nicht die abweichenden 2014er-Ritualregeln übernehmen.

**Requirement:** `RULE-SPELLS-RITUAL-CASTING` (`partial`, keine vollständige Ritualausführung).

## Tatsächlicher Umfang

`app/lib/domain/srd_ritual_casting_rules.dart` führt `SrdRitualCastingRules.preflight` ein. Der Rückgabewert `SrdRitualCastPlan` ist **nur ein lesendes Prüfresultat**:

- Ritual-Tag und bekannte Katalog-Zeit: `Action or Ritual`, `1 minute or Ritual`, `10 minutes or Ritual`, `1 hour or Ritual`; andernfalls sicher abbrechen.
- Klassenzugehörigkeit, Klassenstufe/Mehrklasse und ausdrücklich vorbereiteter Zauber. Für Mehrklassen ist die Zuordnung zur ausgewählten Klasse gesondert zu bestätigen; der flache alte `hero.spells`-Speicher enthält noch keine Klassenprovenienz.
- Zusatzzeit **immer zehn Minuten**. Ergebnis `totalCastingMinutes` für Minuten/Stunden 11, 20 bzw. 70; für `Action` **null**, da eine Aktion nicht blind als genau sechs Sekunden angenommen wird.
- Genügend ungestörte Zeit, während der längeren Zauberdauer mögliche Konzentration, gültige Zielbedingungen und erforderliche V-/S-/M-Komponenten müssen ausdrücklich bestätigt sein.
- Teure und verbrauchte Materialien werden über die bestehende SRD-Komponentenregel geprüft; keine heimliche Fokus-/Beutel-Substitution.
- Bewusstlosigkeit, null Trefferpunkte, Handlungsunfähigkeit und ungeübte angelegte Rüstung/Schilde blockieren die Freigabe.
- `spellSlotCost=0` als Regelvorgabe – **kein tatsächlicher Slotverbrauch und keine Aktion**. Keine spontane Wahl eines höheren Slotgrads; keine Effekt- oder Zeitfortschreibung.
- Charakteränderungen machen den `sourceSnapshot` der Planung über `validateUnchanged` ungültig. Bestätigte Änderungen an Welt/Ziel/Material erfordern später zusätzlich eine transaktionale Prüfung, die dieses Modul **nicht** anbietet.

## Tests und bewusst offene Grenzen

`app/test/srd_ritual_casting_rules_test.dart`: 29 Katalog-Rituale, vier Zeitmuster, fremde/nicht vorbereitete Zauber, falsche Klassen-/Mehrklassenstufen, fehlende Zeit/Ziel/Konzentrationsbestätigung, V/S/M mit Preis-/Verbrauch, Unfähigkeit/ungeübte Rüstung, Ressourcen- und JSON-Unverändertheit, ungültige Rituale und veraltete Charakterzustände.

**Nicht implementiert:** Ein Ritual beginnt/endet nicht, keine Magic-Action-Sequenz, keine Unterbrechungs-/Rundenlogik, keine tatsächliche Konzentrationsereignisse, keine Buchung verbrauchter Materialien, keine Wirkung oder persistierte Kampagnenzeit. Ein Prüfplan darf ausdrücklich **nicht** als ausgeführter Zauber gemeldet werden. Die SRD-Kataloge sind weiterhin nicht vollständig amtlich abgeglichen.

**Versions-/Speichervertrag:** Keine SQLite-/JSON-Migration, keine Änderungen an `HeroCharacter`, `GameEngine`, `GameController` oder fremden Chat-Dateien.

**Prüfpflicht:** Finale GitHub-Actions-CI mit struktureller Prüfung, Dart-Format/Analyse, Flutter-Tests und Android-Debug-/Alpha-Build; Geräteabnahme separat.
