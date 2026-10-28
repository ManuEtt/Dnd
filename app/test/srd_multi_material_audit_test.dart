import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

List<SrdMaterialItemConfirmation> _confirm(
  List<SrdAuditedMaterialItem> items,
) => [
  for (final item in items)
    SrdMaterialItemConfirmation(
      id: item.id,
      identityAndCostConfirmed: true,
      requiredQuantityConfirmed: true,
      consumptionReservedConfirmed: item.isConsumed,
    ),
];

SrdSpellMaterialRequirements _validate(
  SrdSpellDefinition spell,
  List<SrdMaterialItemConfirmation> confirmations,
) => SrdSpellComponentRules.validateMaterial(
  spell,
  materialComponentConfirmed: true,
  costlyComponentAvailableConfirmed: true,
  consumedComponentReservedConfirmed: true,
  confirmedMaterialItems: confirmations,
);

SrdSpellDefinition _alterComponents(
  SrdSpellDefinition spell,
  String components,
) => SrdSpellDefinition(
  id: spell.id,
  name: spell.name,
  level: spell.level,
  school: spell.school,
  classes: spell.classes,
  castingTime: spell.castingTime,
  range: spell.range,
  components: components,
  duration: spell.duration,
  verbal: spell.verbal,
  somatic: spell.somatic,
  material: spell.material,
  concentration: spell.concentration,
  ritual: spell.ritual,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('four exact multi-priced catalogue recipes have two stable items', () {
    final cases = <String, List<bool>>{
      'Astral Projection': [true, true],
      'Clone': [true, false],
      'Legend Lore': [true, false],
      'Secret Chest': [false, false],
    };
    for (final entry in cases.entries) {
      final spell = catalog.find(entry.key)!;
      final items = SrdSpellComponentRules.auditedItems(spell);
      expect(items, hasLength(2), reason: spell.name);
      expect(items.map((item) => item.isConsumed).toList(), entry.value);
      expect(items.map((item) => item.id).toSet(), hasLength(2));
      expect(_validate(spell, _confirm(items)).hasSpecifiedCost, isTrue);
    }
    expect(
      SrdSpellComponentRules.auditedItems(catalog.find('Revivify')!),
      isEmpty,
    );
  });

  test('missing, duplicated or invented component identities fail closed', () {
    final spell = catalog.find('Clone')!;
    final approvals = _confirm(SrdSpellComponentRules.auditedItems(spell));
    expect(() => _validate(spell, []), throwsFormatException);
    expect(() => _validate(spell, [approvals.first]), throwsFormatException);
    expect(
      () => _validate(spell, [approvals.first, approvals.first]),
      throwsFormatException,
    );
    expect(
      () => _validate(spell, [
        approvals.first,
        const SrdMaterialItemConfirmation(
          id: 'unknown-material',
          identityAndCostConfirmed: true,
          requiredQuantityConfirmed: true,
        ),
      ]),
      throwsFormatException,
    );
  });

  test('every price, required count and consumed status needs proof', () {
    final spell = catalog.find('Astral Projection')!;
    final approvals = _confirm(SrdSpellComponentRules.auditedItems(spell));
    for (final invalid in [
      const SrdMaterialItemConfirmation(
        id: 'astral-jacinth',
        identityAndCostConfirmed: false,
        requiredQuantityConfirmed: true,
        consumptionReservedConfirmed: true,
      ),
      const SrdMaterialItemConfirmation(
        id: 'astral-jacinth',
        identityAndCostConfirmed: true,
        requiredQuantityConfirmed: false,
        consumptionReservedConfirmed: true,
      ),
      const SrdMaterialItemConfirmation(
        id: 'astral-jacinth',
        identityAndCostConfirmed: true,
        requiredQuantityConfirmed: true,
      ),
    ]) {
      expect(
        () => _validate(spell, [invalid, approvals.last]),
        throwsFormatException,
      );
    }
  });

  test('non-consumed vessel must not be recorded as consumed', () {
    final spell = catalog.find('Clone')!;
    final approvals = _confirm(SrdSpellComponentRules.auditedItems(spell));
    expect(
      () => _validate(spell, [
        approvals.first,
        const SrdMaterialItemConfirmation(
          id: 'clone-vessel',
          identityAndCostConfirmed: true,
          requiredQuantityConfirmed: true,
          consumptionReservedConfirmed: true,
        ),
      ]),
      throwsFormatException,
    );
    expect(_validate(spell, approvals).isConsumed, isTrue);
  });

  test('transcription changes require review instead of guessed prices', () {
    final spell = catalog.find('Secret Chest')!;
    final changed = _alterComponents(
      spell,
      spell.components.replaceFirst('5,000+ GP', '6,000+ GP'),
    );
    expect(
      () => SrdSpellComponentRules.auditedItems(changed),
      throwsFormatException,
    );
    expect(
      () => _validate(
        changed,
        _confirm(SrdSpellComponentRules.auditedItems(spell)),
      ),
      throwsFormatException,
    );
  });

  test('unknown recipe cannot accept unrelated detailed confirmations', () {
    final spell = catalog.find('Revivify')!;
    final approval = const SrdMaterialItemConfirmation(
      id: 'clone-diamond',
      identityAndCostConfirmed: true,
      requiredQuantityConfirmed: true,
      consumptionReservedConfirmed: true,
    );
    expect(() => _validate(spell, [approval]), throwsFormatException);
    expect(_validate(spell, const []).hasSpecifiedCost, isTrue);
  });

  test('Secret Chest preflight requires both items without spending slots', () {
    final spell = catalog.find('Secret Chest')!;
    final hero = HeroCharacter(
      id: 'multi-material-wizard',
      name: 'Material-Test',
      className: 'Magier',
      level: 9,
      spells: const ['Secret Chest'],
      abilities: const {
        'strength': 10,
        'dexterity': 12,
        'constitution': 14,
        'intelligence': 18,
        'wisdom': 12,
        'charisma': 10,
      },
      hitPoints: 38,
      maxHitPoints: 38,
    );
    SrdSpellCastPlan preflight(List<SrdMaterialItemConfirmation> approvals) =>
        SrdSpellPreflightRules.preflight(
          hero,
          spell: spell,
          castingClass: 'Magier',
          slotLevel: 4,
          actionAvailableConfirmed: true,
          targetRulesConfirmed: true,
          verbalComponentConfirmed: true,
          somaticComponentConfirmed: true,
          materialComponentConfirmed: true,
          costlyComponentAvailableConfirmed: true,
          slotTurnLimitConfirmed: true,
          confirmedMaterialItems: approvals,
        );

    expect(() => preflight(const []), throwsFormatException);
    final approvals = _confirm(SrdSpellComponentRules.auditedItems(spell));
    final plan = preflight(approvals);
    expect(plan.hasConsumedMaterial, isFalse);
    expect(plan.spell.name, 'Secret Chest');
    expect(hero.spentSpellSlots, isEmpty);
  });
}
