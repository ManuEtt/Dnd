import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/story/story_rule_boundary.dart';

void main() {
  final campaign = GameEngine().createDemo();

  test('story-only scene edits preserve the rule boundary', () {
    final changed = campaign.copyWith(
      scene: 'Die Spielleitung beschreibt einen neuen Schauplatz.',
      storyBible: {...campaign.storyBible, 'mood': 'mysterious'},
    );

    expect(
      () => StoryRuleBoundary.ensureRuleStateUnchanged(campaign, changed),
      returnsNormally,
    );
    expect(campaign.scene, isNot(changed.scene));
  });

  test('narration cannot silently alter confirmed world facts', () {
    final changed = campaign.copyWith(
      scene: 'Eine neue Szene.',
      facts: {...campaign.facts, 'secretReward': 'granted'},
    );

    expect(
      () => StoryRuleBoundary.ensureRuleStateUnchanged(campaign, changed),
      throwsA(isA<FormatException>()),
    );
  });

  test('narration cannot silently alter campaign identity', () {
    final changed = campaign.copyWith(
      scene: 'Eine neue Szene.',
      name: 'Eine fremde Kampagne',
    );

    expect(
      () => StoryRuleBoundary.ensureRuleStateUnchanged(campaign, changed),
      throwsA(isA<FormatException>()),
    );
  });

  test('identical saved campaign passes without mutation', () {
    final restored = campaign.copyWith();
    expect(
      () => StoryRuleBoundary.ensureRuleStateUnchanged(campaign, restored),
      returnsNormally,
    );
  });
}
