import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_automation.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';

HeroCharacter character(
  String className,
  int level, {
  String subclass = '',
  String secondary = '',
  int secondaryLevel = 0,
  String secondarySubclass = '',
}) => HeroCharacter(
  id: 'srd-class-automation-test',
  name: 'Probe',
  className: className,
  level: level,
  subclass: subclass,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  secondarySubclass: secondarySubclass,
  abilities: const {
    'strength': 14,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 14,
    'wisdom': 14,
    'charisma': 14,
  },
  maxHitPoints: 10,
  hitPoints: 10,
);

void main() {
  test('alle 282 SRD-Freischaltungen besitzen einen Status', () {
    var total = 0;
    final ids = <String>{};
    for (final klass in srdCharacterClasses) {
      final features = SrdClassFeatureCatalog.allForClass(klass.name);
      expect(features, isNotEmpty, reason: klass.name);
      total += features.length;
      for (final feature in features) {
        expect(ids.add(feature.id), isTrue, reason: feature.id);
        final state = SrdClassAutomation.inspect(feature);
        expect(state.feature.id, feature.id);
        if (state.hasSupportedMechanics) {
          expect(state.evidence, isNotEmpty, reason: feature.id);
        }
        if (feature.automation == FeatureAutomation.choiceRequired) {
          expect(state.status, SrdFeatureRuntimeStatus.playerChoice);
          expect(state.hasSupportedMechanics, isFalse);
        }
      }
    }
    expect(total, 282);
  });

  test('exekutierbare Merkmale und unvollständige Wirkungen unterscheiden', () {
    final fighter = SrdClassAutomation.unlocked(
      character('Kämpfer', 20, subclass: 'Champion'),
    );
    expect(
      fighter
          .singleWhere((e) => e.feature.name == 'Three Extra Attacks')
          .status,
      SrdFeatureRuntimeStatus.computed,
    );
    expect(
      fighter.singleWhere((e) => e.feature.name == 'Second Wind').status,
      SrdFeatureRuntimeStatus.confirmedAction,
    );
    expect(
      fighter.singleWhere((e) => e.feature.name == 'Studied Attacks').status,
      SrdFeatureRuntimeStatus.notImplemented,
    );
    expect(
      fighter.singleWhere((e) => e.feature.name == 'Improved Critical').status,
      SrdFeatureRuntimeStatus.computed,
    );
    final warlock = SrdClassAutomation.unlocked(character('Hexenmeister', 1));
    expect(
      warlock
          .singleWhere((e) => e.feature.name == 'Eldritch Invocations')
          .status,
      SrdFeatureRuntimeStatus.playerChoice,
    );
    expect(
      warlock.singleWhere((e) => e.feature.name == 'Pact Magic').status,
      SrdFeatureRuntimeStatus.partial,
    );
  });

  test('Unterklassen ohne explizite Wahl lösen keine Regelwirkung aus', () {
    final unchosen = SrdClassAutomation.unlocked(character('Kleriker', 20));
    final life = SrdClassAutomation.unlocked(
      character('Kleriker', 20, subclass: 'Life Domain'),
    );
    expect(unchosen.any((e) => e.feature.isSubclass), isFalse);
    expect(life.any((e) => e.feature.name == 'Disciple of Life'), isTrue);
  });

  test('Mehrklassenwerte berücksichtigen eigene Klassenstufen', () {
    final mixed = character(
      'Kämpfer',
      10,
      subclass: 'Champion',
      secondary: 'Schurke',
      secondaryLevel: 5,
      secondarySubclass: 'Thief',
    );
    final available = SrdClassAutomation.unlocked(mixed);
    expect(
      available.any((e) => e.feature.name == 'Two Extra Attacks'),
      isFalse,
    );
    expect(available.any((e) => e.feature.name == 'Sneak Attack'), isTrue);
    final values = SrdClassAutomation.derivedValues(mixed);
    expect(
      values
          .singleWhere((e) => e.name == 'Angriffe je Angriffsaktion (gesamt)')
          .value,
      '2',
    );
    expect(
      values.singleWhere((e) => e.name == 'Hinterhältiger Angriff').value,
      '3W6',
    );
    expect(
      values.singleWhere((e) => e.name == 'Zweite Luft gesamt').value,
      '3',
    );
  });

  test('jede SRD-Klasse erhält nur ihre gesicherten numerischen Werte', () {
    for (final klass in srdCharacterClasses) {
      final values = SrdClassAutomation.derivedValues(
        character(klass.name, 20),
      );
      expect(values, isNotEmpty, reason: klass.name);
      expect(values.every((value) => value.className == klass.name), isTrue);
      expect(values.every((value) => value.value.isNotEmpty), isTrue);
    }
    final levelOne = SrdClassAutomation.derivedValues(character('Zauberer', 1));
    expect(levelOne.any((e) => e.name == 'Zaubereipunkte gesamt'), isFalse);
    final wizard = SrdClassAutomation.derivedValues(character('Magier', 20));
    expect(
      wizard
          .singleWhere((e) => e.name == 'Gemeinsame verfügbare Zauberplätze')
          .value,
      isNotEmpty,
    );
  });

  test('unbekannte Mechaniken werden nicht automatisch unterstützt', () {
    final novel = SrdClassFeature(
      id: 'fixture_future_feature',
      className: 'Magier',
      classLevel: 20,
      name: 'Future Unknown Ability',
      automation: FeatureAutomation.automatic,
    );
    final state = SrdClassAutomation.inspect(novel);
    expect(state.status, SrdFeatureRuntimeStatus.notImplemented);
    expect(state.hasSupportedMechanics, isFalse);
    expect(state.evidence, isEmpty);
  });
}
