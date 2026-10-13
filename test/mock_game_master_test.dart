import 'package:aetheria/domain/models.dart';
import 'package:aetheria/services/mock_game_master.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hero = CharacterSheet(id: 'arescan', name: 'Arescan', species: 'Mensch', characterClass: 'Waldläufer');
  const campaign = Campaign(
    id: 'heart-eternity', title: 'Das Herz der Ewigkeit', heroId: 'arescan',
    scene: 'Der Ritter ist gefallen.', location: 'Silberhain',
  );
  test('historical campaign supports follow-up questions', () {
    final answer = const MockGameMaster().respond(campaign, 'Ich untersuche das Amulett', hero);
    expect(answer, contains('Amulett'));
    expect(answer, contains('Arescan'));
  });
  test('dice response does not invent stats', () {
    final answer = const MockGameMaster().respond(campaign, 'Ich schieße', hero);
    expect(answer, contains('Unbestätigte'));
  });
  test('serialization preserves unknown scores', () {
    final decoded = CharacterSheet.fromJson(hero.toJson());
    expect(decoded.dexterity, isNull);
    expect(decoded.name, 'Arescan');
  });
}
