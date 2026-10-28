import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_bard_font_of_inspiration.dart';

HeroCharacter bard({
  int level = 5,
  String second = '',
  int secondLevel = 0,
  int spentInspiration = 2,
  Map<String, int> spentSlots = const {},
  int spentPactSlots = 0,
}) => HeroCharacter(
  id: 'font-test',
  name: 'Sänger',
  className: 'Barde',
  level: level,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  hitPoints: 10,
  maxHitPoints: 10,
  abilities: const {'charisma': 16, 'constitution': 12},
  spentClassResources: {'bardicInspiration': spentInspiration},
  spentSpellSlots: spentSlots,
  spentPactSlots: spentPactSlots,
);

void main() {
  test('Font of Inspiration verrechnet beide Ressourcen atomar', () {
    final initial = bard();
    final proposal = SrdBardFontOfInspirationRules.propose(
      hero: initial,
      slotLevel: 1,
    );
    final updated = proposal.applyTo(initial);
    expect(initial.spentClassResources['bardicInspiration'], 2);
    expect(initial.spentSpellSlots, isEmpty);
    expect(updated.spentClassResources['bardicInspiration'], 1);
    expect(updated.spentSpellSlots['1'], 1);
    final restored = HeroCharacter.fromJson(updated.toJson());
    expect(restored.spentClassResources, updated.spentClassResources);
    expect(restored.spentSpellSlots, updated.spentSpellSlots);
    expect(restored.abilities['charisma'], 16);
    expect(() => proposal.applyTo(updated), throwsFormatException);
  });

  test('bei letzter verbrauchter Nutzung wird Null-Zähler entfernt', () {
    final initial = bard(spentInspiration: 1);
    final result = SrdBardFontOfInspirationRules.propose(
      hero: initial,
      slotLevel: 2,
    ).applyTo(initial);
    expect(
      result.spentClassResources.containsKey('bardicInspiration'),
      isFalse,
    );
    expect(result.spentSpellSlots['2'], 1);
  });

  test('kein Verlust, wenn eine Ressource nicht vorhanden ist', () {
    for (final initial in [
      bard(spentInspiration: 0),
      bard(spentSlots: {'1': 4}),
      bard(level: 4),
      bard().copyWith(hitPoints: 0),
    ]) {
      expect(
        () =>
            SrdBardFontOfInspirationRules.propose(hero: initial, slotLevel: 1),
        throwsA(anyOf(isA<StateError>(), isA<FormatException>())),
      );
      expect(initial.spentSpellSlots['1'] ?? 0, lessThanOrEqualTo(4));
    }
    expect(
      () => SrdBardFontOfInspirationRules.propose(hero: bard(), slotLevel: 0),
      throwsRangeError,
    );
  });

  test('Paktplatz optional nur bei korrektem, bestätigtem Grad', () {
    final initial = bard(
      level: 6,
      second: 'Hexenmeister',
      secondLevel: 1,
      spentInspiration: 1,
    );
    final result = SrdBardFontOfInspirationRules.propose(
      hero: initial,
      slotLevel: 1,
      usePactSlot: true,
    ).applyTo(initial);
    expect(result.spentPactSlots, 1);
    expect(result.spentSpellSlots, isEmpty);
    expect(result.spentClassResources['bardicInspiration'], isNull);
    expect(
      () => SrdBardFontOfInspirationRules.propose(
        hero: initial,
        slotLevel: 2,
        usePactSlot: true,
      ),
      throwsStateError,
    );
  });

  test('veraltete Entscheidung darf keinen weiteren Platz abbuchen', () {
    final initial = bard();
    final proposal = SrdBardFontOfInspirationRules.propose(
      hero: initial,
      slotLevel: 1,
    );
    final changed = initial.copyWith(
      spentClassResources: {'bardicInspiration': 3},
    );
    expect(() => proposal.applyTo(changed), throwsFormatException);
    expect(changed.spentSpellSlots, isEmpty);
  });
}
