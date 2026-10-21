import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

HeroCharacter _caster({
  String characterClass = 'Magier',
  String spellName = 'Chromatic Orb',
}) => HeroCharacter(
  id: 'material-caster',
  name: 'Materialtest',
  className: characterClass,
  level: 5,
  spells: [spellName],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 14,
    'charisma': 12,
  },
  maxHitPoints: 28,
  hitPoints: 28,
);

SrdSpellCastPlan _preflight(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  int slotLevel = 1,
  SrdSpellMaterialSource source = SrdSpellMaterialSource.specificComponents,
  bool materialConfirmed = true,
  bool focusAuthorized = false,
  bool costlyConfirmed = false,
  bool reservedConfirmed = false,
}) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: hero.className,
  slotLevel: slotLevel,
  actionAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  materialComponentConfirmed: materialConfirmed,
  materialSource: source,
  focusUseAuthorizedConfirmed: focusAuthorized,
  costlyComponentAvailableConfirmed: costlyConfirmed,
  consumedComponentReservedConfirmed: reservedConfirmed,
  slotTurnLimitConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all 339 catalogue entries can be inspected without effects', () {
    for (final spell in catalog.spells) {
      final req = SrdSpellComponentRules.requirements(spell);
      expect(req.hasMaterial, spell.material, reason: spell.name);
      if (!spell.material) {
        expect(req.hasSpecifiedCost, isFalse);
        expect(req.isConsumed, isFalse);
      }
    }
  });

  test('SRD source distinguishes free, priced and consumed materials', () {
    final free = SrdSpellComponentRules.requirements(catalog.find('Fireball')!);
    expect(free.maySubstitute, isTrue);
    expect(free.hasSpecifiedCost, isFalse);
    expect(free.isConsumed, isFalse);

    final priced = SrdSpellComponentRules.requirements(
      catalog.find('Identify')!,
    );
    expect(priced.hasSpecifiedCost, isTrue);
    expect(priced.isConsumed, isFalse);
    expect(priced.maySubstitute, isFalse);

    final consumed = SrdSpellComponentRules.requirements(
      catalog.find('Revivify')!,
    );
    expect(consumed.hasSpecifiedCost, isTrue);
    expect(consumed.isConsumed, isTrue);
    expect(consumed.maySubstitute, isFalse);

    final noMaterial = SrdSpellComponentRules.requirements(
      catalog.find('Magic Missile')!,
    );
    expect(noMaterial.hasMaterial, isFalse);
  });

  test('focus or component pouch cannot replace a priced diamond', () {
    final hero = _caster();
    final spell = catalog.find('Chromatic Orb')!;
    for (final source in [
      SrdSpellMaterialSource.componentPouch,
      SrdSpellMaterialSource.spellcastingFocus,
    ]) {
      expect(
        () => _preflight(
          hero,
          spell,
          source: source,
          focusAuthorized: true,
          costlyConfirmed: true,
        ),
        throwsFormatException,
      );
    }
    expect(() => _preflight(hero, spell), throwsFormatException);
    final valid = _preflight(hero, spell, costlyConfirmed: true);
    expect(valid.hasConsumedMaterial, isFalse);
    expect(hero.spentSpellSlots, isEmpty);
  });

  test(
    'focus must be specifically authorized; component pouch can substitute',
    () {
      final hero = _caster(spellName: 'Fireball');
      final fireball = catalog.find('Fireball')!;
      expect(
        () => _preflight(
          hero,
          fireball,
          slotLevel: 3,
          source: SrdSpellMaterialSource.spellcastingFocus,
        ),
        throwsFormatException,
      );
      expect(
        () => _preflight(
          hero,
          fireball,
          slotLevel: 3,
          source: SrdSpellMaterialSource.spellcastingFocus,
          focusAuthorized: true,
          materialConfirmed: false,
        ),
        throwsFormatException,
      );
      expect(
        _preflight(
          hero,
          fireball,
          slotLevel: 3,
          source: SrdSpellMaterialSource.spellcastingFocus,
          focusAuthorized: true,
        ).hasConsumedMaterial,
        isFalse,
      );
      expect(
        _preflight(
          hero,
          fireball,
          slotLevel: 3,
          source: SrdSpellMaterialSource.componentPouch,
        ).hasConsumedMaterial,
        isFalse,
      );
    },
  );

  test(
    'consumed material requires reservation and separate consumption at commit',
    () {
      final hero = _caster(characterClass: 'Kleriker', spellName: 'Revivify');
      final spell = catalog.find('Revivify')!;
      expect(
        () => _preflight(hero, spell, slotLevel: 3, costlyConfirmed: true),
        throwsFormatException,
      );
      final approved = _preflight(
        hero,
        spell,
        slotLevel: 3,
        costlyConfirmed: true,
        reservedConfirmed: true,
      );
      expect(approved.hasConsumedMaterial, isTrue);
      expect(
        () => SrdSpellPreflightRules.recordConfirmedResourceUse(
          hero,
          approved,
          effectResolvedSeparatelyConfirmed: true,
        ),
        throwsStateError,
      );
      expect(hero.spentSpellSlots, isEmpty);
      final recorded = SrdSpellPreflightRules.recordConfirmedResourceUse(
        hero,
        approved,
        effectResolvedSeparatelyConfirmed: true,
        materialConsumptionResolvedSeparatelyConfirmed: true,
      );
      expect(recorded.hero.spentSpellSlots, {'3': 1});
      expect(
        () => SrdSpellPreflightRules.recordConfirmedResourceUse(
          recorded.hero,
          approved,
          effectResolvedSeparatelyConfirmed: true,
          materialConsumptionResolvedSeparatelyConfirmed: true,
        ),
        throwsFormatException,
      );
    },
  );
}
