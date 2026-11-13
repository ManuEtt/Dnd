import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_sending_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Sending recipient identity must match input', () async {
    final catalog = await SrdSpellCatalogLoader.load();
    final sending = catalog.find('Sending')!;

    for (final id in [' npc-42', 'npc-42 ', '\tnpc-42', 'npc-42\n']) {
      expect(
        () => SrdSendingRules.prepare(
          spell: sending,
          recipientId: id,
          message: 'Hallo',
          knowledge: SendingRecipientKnowledge.personallyMet,
          recipientIsCreatureConfirmed: true,
        ),
        throwsFormatException,
        reason: 'No silent recipient identity normalization: ${id.codeUnits}',
      );
    }

    final valid = SrdSendingRules.prepare(
      spell: sending,
      recipientId: 'npc-42',
      message: 'Hallo',
      knowledge: SendingRecipientKnowledge.personallyMet,
      recipientIsCreatureConfirmed: true,
    );
    expect(valid.recipientId, 'npc-42');
  });
}
