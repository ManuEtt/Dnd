import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_sending_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;
  late SrdSpellDefinition sending;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
    sending = catalog.find('Sending')!;
  });

  SendingMessagePlan prepare({
    String recipientId = 'known-npc-42',
    String message = 'Bitte antworte, wenn du sicher bist.',
    SendingRecipientKnowledge knowledge =
        SendingRecipientKnowledge.personallyMet,
    bool isCreature = true,
  }) => SrdSendingRules.prepare(
    spell: sending,
    recipientId: recipientId,
    message: message,
    knowledge: knowledge,
    recipientIsCreatureConfirmed: isCreature,
  );

  test('Sending is uniquely identified by published level and spell metadata',
      () {
    expect(sending.name, 'Sending');
    expect(sending.level, 3);
    expect(sending.range, 'Unlimited');
    expect(sending.castingTime, 'Action');
    expect(sending.concentration, isFalse);

    for (final name in ['Dream', 'Magic Missile', 'Mirage Arcane']) {
      expect(
        () => SrdSendingRules.prepare(
          spell: catalog.find(name)!,
          recipientId: 'npc-01',
          message: 'Hallo',
          knowledge: SendingRecipientKnowledge.personallyMet,
          recipientIsCreatureConfirmed: true,
        ),
        throwsUnsupportedError,
        reason: name,
      );
    }
  });

  test('a confirmed creature met personally qualifies with 25 words', () {
    final words = List.filled(25, 'Wort').join(' ');
    final plan = prepare(recipientId: '  npc-01  ', message: '  $words  ');
    expect(plan.recipientId, 'npc-01');
    expect(plan.wordCount, 25);
    expect(plan.message, words);
    expect(plan.recipientKnowledge, SendingRecipientKnowledge.personallyMet);
  });

  test('an eyewitness description also qualifies, no personal visit required',
      () {
    final plan = prepare(
      knowledge: SendingRecipientKnowledge.describedByEyewitness,
      message: 'Hallo,\nwir sprechen morgen!\tBis dann.',
    );
    expect(plan.wordCount, 6);
  });

  test('unknown recipient evidence and noncreatures fail closed', () {
    expect(
      () => prepare(knowledge: SendingRecipientKnowledge.unverified),
      throwsFormatException,
    );
    expect(() => prepare(isCreature: false), throwsFormatException);
    for (final id in ['', '    ', 'x' * 161]) {
      expect(() => prepare(recipientId: id), throwsFormatException);
    }
  });

  test('message is required and cannot contain over 25 words', () {
    for (final msg in ['', '    ', '\n \t']) {
      expect(() => prepare(message: msg), throwsFormatException);
    }
    final tooMany = List.filled(26, 'Wort').join(' ');
    expect(() => prepare(message: tooMany), throwsFormatException);
  });

  test('confirmed same plane is deliverable without a percentile roll', () {
    final plan = prepare();
    final outcome = SrdSendingRules.assessDelivery(
      plan,
      blockStatus: SendingBlockStatus.notBlockedConfirmed,
      planeRelation: SendingPlaneRelation.samePlaneConfirmed,
    );
    expect(outcome.outcome, SendingDeliveryOutcome.deliverable);
    expect(outcome.percentileRoll, isNull);
    expect(
      () => SrdSendingRules.assessDelivery(
        plan,
        blockStatus: SendingBlockStatus.notBlockedConfirmed,
        planeRelation: SendingPlaneRelation.samePlaneConfirmed,
        percentileRoll: 60,
      ),
      throwsFormatException,
    );
  });

  test('different planes use exactly five-percent failure boundary', () {
    final plan = prepare();
    for (final value in [1, 5]) {
      final result = SrdSendingRules.assessDelivery(
        plan,
        blockStatus: SendingBlockStatus.notBlockedConfirmed,
        planeRelation: SendingPlaneRelation.differentPlaneConfirmed,
        percentileRoll: value,
      );
      expect(result.outcome, SendingDeliveryOutcome.planarFailure);
      expect(result.percentileRoll, value);
    }
    for (final value in [6, 50, 100]) {
      expect(
        SrdSendingRules.assessDelivery(
          plan,
          blockStatus: SendingBlockStatus.notBlockedConfirmed,
          planeRelation: SendingPlaneRelation.differentPlaneConfirmed,
          percentileRoll: value,
        ).outcome,
        SendingDeliveryOutcome.deliverable,
      );
    }
    for (final value in [null, 0, -1, 101]) {
      expect(
        () => SrdSendingRules.assessDelivery(
          plan,
          blockStatus: SendingBlockStatus.notBlockedConfirmed,
          planeRelation: SendingPlaneRelation.differentPlaneConfirmed,
          percentileRoll: value,
        ),
        throwsFormatException,
      );
    }
  });

  test('known eight-hour block prevents delivery and any random roll', () {
    final plan = prepare();
    for (final plane in SendingPlaneRelation.values) {
      final result = SrdSendingRules.assessDelivery(
        plan,
        blockStatus: SendingBlockStatus.blockedConfirmed,
        planeRelation: plane,
      );
      expect(result.outcome, SendingDeliveryOutcome.blocked);
      expect(result.percentileRoll, isNull);
      expect(
        () => SrdSendingRules.assessDelivery(
          plan,
          blockStatus: SendingBlockStatus.blockedConfirmed,
          planeRelation: plane,
          percentileRoll: 1,
        ),
        throwsFormatException,
      );
    }
  });

  test('unverified block or plane stays unresolved without a die', () {
    final plan = prepare();
    for (final facts in [
      (
        SendingBlockStatus.unverified,
        SendingPlaneRelation.samePlaneConfirmed,
      ),
      (
        SendingBlockStatus.notBlockedConfirmed,
        SendingPlaneRelation.unverified,
      ),
      (SendingBlockStatus.unverified, SendingPlaneRelation.unverified),
    ]) {
      final result = SrdSendingRules.assessDelivery(
        plan,
        blockStatus: facts.$1,
        planeRelation: facts.$2,
      );
      expect(result.outcome, SendingDeliveryOutcome.unresolved);
      expect(result.percentileRoll, isNull);
      expect(
        () => SrdSendingRules.assessDelivery(
          plan,
          blockStatus: facts.$1,
          planeRelation: facts.$2,
          percentileRoll: 99,
        ),
        throwsFormatException,
      );
    }
  });

  test('planning and assessment never modify a character or game state', () {
    final first = prepare();
    final second = prepare();
    expect(first.recipientId, second.recipientId);
    expect(first.message, second.message);
    expect(first.wordCount, second.wordCount);
    final result = SrdSendingRules.assessDelivery(
      first,
      blockStatus: SendingBlockStatus.notBlockedConfirmed,
      planeRelation: SendingPlaneRelation.differentPlaneConfirmed,
      percentileRoll: 100,
    );
    expect(result.outcome, SendingDeliveryOutcome.deliverable);
    // No GameEngine, CampaignRepository, narrator or dice RNG is needed.
  });
}
