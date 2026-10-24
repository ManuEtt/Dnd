import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sending_cast_preflight_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sending_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';

HeroCharacter _caster({
  String className = 'Magier',
  int level = 5,
  List<String> spells = const ['Sending'],
}) => HeroCharacter(
  id: 'sending-caster',
  name: 'Nora',
  className: className,
  level: level,
  spells: spells,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;
  late SrdSpellDefinition sending;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
    sending = catalog.find('Sending')!;
  });

  SrdSendingCastPreview preview(
    HeroCharacter hero, {
    SrdSpellDefinition? spell,
    String? castingClass,
    int slotLevel = 3,
    String recipientId = 'npc-4',
    String message = 'Bitte melde dich.',
    SendingRecipientKnowledge recipientKnowledge =
        SendingRecipientKnowledge.personallyMet,
    bool creature = true,
    SendingBlockStatus blockStatus =
        SendingBlockStatus.notBlockedConfirmed,
    SendingPlaneRelation planeRelation =
        SendingPlaneRelation.samePlaneConfirmed,
    int? roll,
    bool action = true,
    bool turnLimit = true,
    bool verbal = true,
    bool somatic = true,
    bool material = true,
    bool focusAuthorized = false,
    SrdSpellMaterialSource source =
        SrdSpellMaterialSource.specificComponents,
  }) => SrdSendingCastPreflightRules.preview(
    hero,
    spell: spell ?? sending,
    castingClass: castingClass ?? hero.className,
    slotLevel: slotLevel,
    recipientId: recipientId,
    message: message,
    recipientKnowledge: recipientKnowledge,
    recipientIsCreatureConfirmed: creature,
    blockStatus: blockStatus,
    planeRelation: planeRelation,
    percentileRoll: roll,
    actionAvailableConfirmed: action,
    slotTurnLimitConfirmed: turnLimit,
    verbalComponentConfirmed: verbal,
    somaticComponentConfirmed: somatic,
    materialComponentConfirmed: material,
    materialSource: source,
    focusUseAuthorizedConfirmed: focusAuthorized,
  );

  test('all eligible classes preview a third-level slot', () {
    for (final name in ['Magier', 'Kleriker', 'Barde']) {
      final hero = _caster(className: name);
      final before = hero.toJson();
      final result = preview(hero);
      expect(result.castingClass, name);
      expect(result.recipient.wordCount, 3);
      expect(result.recipient.recipientId, 'npc-4');
      expect(result.assessment.outcome, SendingDeliveryOutcome.deliverable);
      expect(result.slotLevel, 3);
      expect(result.pactMagic, isFalse);
      expect(result.remainingSlotsIfCommitted, 1);
      expect(SpellcastingRules.availableSlots(hero)[3], 2);
      expect(hero.toJson(), before);
    }
  });

  test('no Sending without a prepared spell or qualifying casting class', () {
    expect(
      () => preview(_caster(spells: const ['Light'])),
      throwsFormatException,
    );
    expect(
      () => preview(_caster(className: 'Kämpfer')),
      throwsFormatException,
    );
    expect(
      () => preview(
        _caster(className: 'Magier'),
        castingClass: 'Kleriker',
      ),
      throwsFormatException,
    );
    expect(
      () => preview(_caster(level: 4)),
      throwsFormatException,
    );
  });

  test('action, once-per-turn slot and V/S/M proofs are all mandatory', () {
    final hero = _caster();
    expect(() => preview(hero, action: false), throwsFormatException);
    expect(() => preview(hero, turnLimit: false), throwsFormatException);
    expect(() => preview(hero, verbal: false), throwsFormatException);
    expect(() => preview(hero, somatic: false), throwsFormatException);
    expect(() => preview(hero, material: false), throwsFormatException);
    expect(
      () => preview(
        hero,
        source: SrdSpellMaterialSource.spellcastingFocus,
      ),
      throwsFormatException,
    );
    final focus = preview(
      hero,
      source: SrdSpellMaterialSource.spellcastingFocus,
      focusAuthorized: true,
    );
    expect(focus.remainingSlotsIfCommitted, 1);
    expect(hero.spentSpellSlots, isEmpty);
  });

  test('wrong slot level and fully spent pool must fail without mutation', () {
    final hero = _caster();
    expect(() => preview(hero, slotLevel: 2), throwsFormatException);
    expect(() => preview(hero, slotLevel: 9), throwsStateError);
    final spent = hero.copyWith(spentSpellSlots: const {'3': 2});
    expect(() => preview(spent), throwsStateError);
    expect(spent.spentSpellSlots, {'3': 2});
    expect(hero.spentSpellSlots, isEmpty);
  });

  test('25-word messages and verified recipient stay mandatory', () {
    final hero = _caster();
    final accepted = preview(
      hero,
      message: List.filled(25, 'Wort').join(' '),
    );
    expect(accepted.recipient.wordCount, 25);
    expect(
      () => preview(hero, message: List.filled(26, 'Wort').join(' ')),
      throwsFormatException,
    );
    expect(() => preview(hero, recipientId: ' '), throwsFormatException);
    expect(() => preview(hero, creature: false), throwsFormatException);
    expect(
      () => preview(
        hero,
        recipientKnowledge: SendingRecipientKnowledge.unverified,
      ),
      throwsFormatException,
    );
    expect(
      () => preview(hero, message: 'Zwei\u200BWörter'),
      throwsFormatException,
    );
  });

  test('confirmed planar roll, block and unknown facts remain distinct', () {
    final hero = _caster();
    final different = preview(
      hero,
      planeRelation: SendingPlaneRelation.differentPlaneConfirmed,
      roll: 5,
    );
    expect(
      different.assessment.outcome,
      SendingDeliveryOutcome.planarFailure,
    );
    final passed = preview(
      hero,
      planeRelation: SendingPlaneRelation.differentPlaneConfirmed,
      roll: 6,
    );
    expect(passed.assessment.outcome, SendingDeliveryOutcome.deliverable);
    final blocked = preview(
      hero,
      blockStatus: SendingBlockStatus.blockedConfirmed,
    );
    expect(blocked.assessment.outcome, SendingDeliveryOutcome.blocked);
    final unknown = preview(
      hero,
      planeRelation: SendingPlaneRelation.unverified,
    );
    expect(unknown.assessment.outcome, SendingDeliveryOutcome.unresolved);
    expect(
      () => preview(
        hero,
        planeRelation: SendingPlaneRelation.unverified,
        roll: 55,
      ),
      throwsFormatException,
    );
    expect(
      () => preview(
        hero,
        planeRelation: SendingPlaneRelation.differentPlaneConfirmed,
        roll: 101,
      ),
      throwsFormatException,
    );
    expect(hero.spentSpellSlots, isEmpty);
  });

  test('tampered catalogue metadata cannot waive Sending copper wire', () {
    final source = sending;
    final altered = SrdSpellDefinition(
      id: source.id,
      name: source.name,
      level: source.level,
      school: source.school,
      classes: source.classes,
      castingTime: source.castingTime,
      range: source.range,
      components: 'V, S',
      duration: source.duration,
      verbal: true,
      somatic: true,
      material: false,
      concentration: false,
      ritual: false,
    );
    expect(
      () => preview(_caster(), spell: altered),
      throwsUnsupportedError,
    );
    expect(
      () => preview(_caster(), spell: catalog.find('Magic Missile')),
      throwsUnsupportedError,
    );
  });
}
