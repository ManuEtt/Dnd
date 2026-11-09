import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  final engine = GameEngine();

  Campaign atChapel() {
    final start = engine.createRabenwacht(engine.createDemo().hero);
    return start.copyWith(
      storyBible: {...start.storyBible, 'stage': 'chapel'},
      facts: {
        ...start.facts,
        'visited:chapel': 'true',
        'visited:mill': 'true',
        'location': 'Kapelle',
      },
    );
  }

  Campaign act(Campaign campaign, String input) =>
      engine.act(campaign, input).campaign;

  test('negated revisit does not move', () {
    final before = atChapel();
    final after = act(before, 'Ich gehe nicht zurück zur Mühle.');

    expect(after.storyBible['stage'], 'chapel');
    expect(after.facts['location'], 'Kapelle');
    expect(after.facts['visited:mill'], 'true');
    expect(after.scene, before.scene);
    expect(after.hero.toJson(), before.hero.toJson());
  });

  test('positive revisit still moves', () {
    final after = act(atChapel(), 'Ich gehe zurück zur Mühle.');

    expect(after.storyBible['stage'], 'mill');
    expect(after.facts['location'], 'Alte Mühle');
    expect(after.facts['visited:mill'], 'true');
  });

  test('negated place mention does not revisit', () {
    final before = atChapel();
    final after = act(before, 'Ich möchte nicht zur Mühle.');

    expect(after.storyBible['stage'], 'chapel');
    expect(after.facts['location'], 'Kapelle');
    expect(after.hero.toJson(), before.hero.toJson());
  });
}
