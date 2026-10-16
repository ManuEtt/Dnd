import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';

HeroCharacter hero(String className, int level,
    {String subclass = '', String second = '', int secondaryLevel = 0}) =>
    HeroCharacter(id: 'catalog', name: 'Testfigur', className: className,
      level: level, subclass: subclass, secondaryClassName: second,
      secondaryClassLevel: secondaryLevel);

void main() {
  test('Every SRD class has feature unlocks, independent of total level', () {
    expect(SrdClassFeatureCatalog.counts.length, 12);
    for (final name in SrdClassFeatureCatalog.counts.keys) {
      expect(SrdClassFeatureCatalog.allForClass(name), isNotEmpty);
      final features = SrdClassFeatureCatalog.unlocked(hero(name, 20));
      expect(features, isNotEmpty);
      expect(features.every((f) => f.classLevel >= 1 && f.classLevel <= 20),
          isTrue);
      final ids = SrdClassFeatureCatalog.allForClass(name).map((f) => f.id);
      expect(ids.toSet().length, ids.length, reason: name);
      expect(SrdClassFeatureCatalog.atClassLevel(name, 0), isEmpty);
      expect(SrdClassFeatureCatalog.atClassLevel(name, 21), isEmpty);
    }
    expect(SrdClassFeatureCatalog.allForClass('fantasy-class'), isEmpty);
  });

  test('SRD subclass features are never granted to unknown subclasses', () {
    final fighter = hero('Kämpfer', 20);
    expect(SrdClassFeatureCatalog.unlocked(fighter).any((f) => f.isSubclass),
      isFalse);
    final champion = hero('Kämpfer', 20, subclass: 'Champion');
    expect(SrdClassFeatureCatalog.unlocked(champion)
      .any((f) => f.name == 'Improved Critical'), isTrue);
    final incorrect = hero('Kämpfer', 20, subclass: 'Battle Master');
    expect(SrdClassFeatureCatalog.unlocked(incorrect).any((f) => f.isSubclass),
      isFalse);
  });

  test('Subclass does not silently transfer to secondary class', () {
    final mixed = hero('Kämpfer', 11, second: 'Schurke', secondaryLevel: 5,
        subclass: 'Champion');
    final list = SrdClassFeatureCatalog.unlocked(mixed);
    expect(list.any((f) => f.name == 'Two Extra Attacks'), isFalse);
    expect(list.any((f) => f.name == 'Sneak Attack'), isTrue);
    expect(list.any((f) => f.isSubclass && f.className == 'Schurke'), isFalse);
    expect(list.any((f) => f.name == 'Improved Critical'), isTrue);
  });

  test('All unlocks carry a scope and automation is never assumed for all', () {
    final wizard = SrdClassFeatureCatalog.unlocked(hero('Magier', 20,
        subclass: 'Evoker'));
    expect(wizard.any((f) => f.name == 'Spell Mastery' &&
      f.automation == FeatureAutomation.manual), isTrue);
    expect(wizard.any((f) => f.name == 'Evocation Savant' && f.isSubclass),
      isTrue);
  });
}
