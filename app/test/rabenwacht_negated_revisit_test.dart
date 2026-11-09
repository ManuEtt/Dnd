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

  test(
    'verneinte Rückreise zu einem bekannten Ort bewegt den Helden nicht',
    () {
      final before = atChapel();
      final after =
          engine.act(before, 'Ich gehe nicht zurück zur Mühle.').campaign;

      expect(after.storyBible['stage'], 'chapel');
      expect(after.facts['location'], 'Kapelle');
      expect(after.facts['visited:mill'], 'true');
      expect(after.scene, before.scene);
      expect(after.hero.toJson(), before.hero.toJson());
    },
  );

  test('positiv bestätigte Rückreise bleibt möglich', () {
    final after =
        engine.act(atChapel(), 'Ich gehe zurück zur Mühle.').campaign;

    expect(after.storyBible['stage'], 'mill');
    expect(after.facts['location'], 'Alte Mühle');
    expect(after.facts['visited:mill'], 'true');
  });

  test('verneinte Ortsnennung ohne Reisebefehl löst keine Rückreise aus',
      () {
        final before = atChapel();
        final after =
            engine.act(before, 'Ich möchte nicht zur Mühle.').campaign;

        expect(after.storyBible['stage'], 'chapel');
        expect(after.facts['location'], 'Kapelle');
        expect(after.hero.toJson(), before.hero.toJson());
      });
}
