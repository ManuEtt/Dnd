import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_duration_rules.dart';

SrdSpellDefinition _alter(
  SrdSpellDefinition original, {
  String? id,
  String? name,
  String? duration,
  bool? concentration,
}) => SrdSpellDefinition(
  id: id ?? original.id,
  name: name ?? original.name,
  level: original.level,
  school: original.school,
  classes: original.classes,
  castingTime: original.castingTime,
  range: original.range,
  components: original.components,
  duration: duration ?? original.duration,
  verbal: original.verbal,
  somatic: original.somatic,
  material: original.material,
  concentration: concentration ?? original.concentration,
  ritual: original.ritual,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all 339 catalogue durations retain classification or fail closed', () {
    final distinct = catalog.spells.map((spell) => spell.duration).toSet();
    expect(distinct, hasLength(24));
    expect(distinct, contains('Special'));

    var classified = 0;
    for (final spell in catalog.spells) {
      if (spell.duration == 'Special') {
        expect(
          () => SrdSpellDurationRules.inspect(spell),
          throwsUnsupportedError,
          reason: spell.name,
        );
        continue;
      }
      final result = SrdSpellDurationRules.inspect(spell);
      expect(result.requiresConcentration, spell.concentration);
      classified++;
    }
    expect(classified, 338);
  });

  test('noncatalogue durations do not manufacture an SRD deadline', () {
    for (final duration in [
      '2 rounds',
      '2 minutes',
      '2 hours',
      '5 hours',
      '999 days',
      'Concentration, up to 2 minutes',
      'Up to 10 days',
      'Special',
      '1 minute\u200b',
    ]) {
      expect(
        () => SrdSpellDurationRules.parse(
          duration,
          concentrationRequired: duration.startsWith('Concentration,'),
        ),
        throwsUnsupportedError,
        reason: duration,
      );
    }

    final tsunami = SrdSpellDurationRules.parse(
      'Concentration, up to 6 rounds',
      concentrationRequired: true,
    );
    expect(tsunami.kind, SrdSpellDurationKind.concentration);
    expect(tsunami.amount, 6);
    expect(tsunami.unit, SrdSpellDurationUnit.round);
    final upTo = SrdSpellDurationRules.parse(
      'Up to 1 minute',
      concentrationRequired: false,
    );
    expect(upTo.kind, SrdSpellDurationKind.upTo);
    expect(upTo.amount, 1);
  });

  test('pinned spell identity rejects a different valid duration', () {
    const names = [
      'Aid',
      'Arcane Lock',
      'Bless',
      'Counterspell',
      'Fly',
      'Geas',
      'Glyph of Warding',
      'Haste',
      'Hex',
      'Invisibility',
      'Mage Armor',
      'Magic Missile',
      'Shield',
      'Tsunami',
    ];
    for (final name in names) {
      final spell = catalog.find(name)!;
      final originalDuration = spell.duration;
      expect(SrdSpellDurationRules.inspect(spell), isNotNull);

      final alternate = spell.concentration
          ? originalDuration == 'Concentration, up to 1 minute'
                ? 'Concentration, up to 1 hour'
                : 'Concentration, up to 1 minute'
          : originalDuration == '1 minute'
          ? '8 hours'
          : '1 minute';
      // Even a well-formed catalogue duration is not interchangeable.
      expect(
        SrdSpellDurationRules.parse(
          alternate,
          concentrationRequired: spell.concentration,
        ),
        isNotNull,
      );
      expect(
        () => SrdSpellDurationRules.inspect(_alter(spell, duration: alternate)),
        throwsFormatException,
        reason: name,
      );
      expect(spell.duration, originalDuration);
    }
  });

  test('a forged name or ID cannot bypass pinned spell metadata', () {
    final shield = catalog.find('Shield')!;
    expect(SrdSpellDurationRules.inspect(shield).amount, 1);

    for (final forged in [
      _alter(shield, name: 'Unverified Shield'),
      _alter(shield, id: 'custom-shield'),
      _alter(shield, duration: '8 hours'),
      _alter(shield, concentration: true),
    ]) {
      expect(
        () => SrdSpellDurationRules.inspect(forged),
        throwsFormatException,
      );
    }

    expect(
      SrdSpellDurationRules.inspect(catalog.find('Magic Missile')!).kind,
      SrdSpellDurationKind.instantaneous,
    );
    expect(shield.duration, '1 round');
  });
}
