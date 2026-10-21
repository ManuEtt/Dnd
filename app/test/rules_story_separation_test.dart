import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart' as legacy;
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_campaign_engine.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart' as story;
import 'package:lebendiger_spielleiter/story/story_rule_boundary.dart';

Campaign _campaign() => Campaign(
  id: 'campaign-1',
  name: 'Rabenwacht',
  world: 'Valdorn',
  sessionId: 'session-1',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Aria',
    hitPoints: 20,
    maxHitPoints: 20,
    armorClass: 14,
  ),
  scene: 'Du stehst vor dem Glockenturm.',
  facts: const {'location': 'Rabenwacht'},
  quests: const [
    Quest(
      id: 'quest-1',
      title: 'Glocke',
      description: 'Erkunde den Glockenturm.',
    ),
  ],
);

void main() {
  test('Story mutations can update prose but not any rule owned field', () {
    final original = _campaign();
    StoryRuleBoundary.ensureRuleStateUnchanged(
      original,
      original.copyWith(
        scene: 'Ein neuer Morgen beginnt.',
        storyBible: const {'stage': 'morning'},
        revision: 1,
      ),
    );
    for (final modified in [
      original.copyWith(hero: original.hero.copyWith(hitPoints: 5)),
      original.copyWith(facts: const {'location': 'unverified'}),
      original.copyWith(quests: const []),
      original.copyWith(
        encounter: const Encounter(
          id: 'battle',
          enemyName: 'Ork',
          enemyHitPoints: 10,
          enemyMaxHitPoints: 10,
        ),
      ),
    ]) {
      expect(
        () => StoryRuleBoundary.ensureRuleStateUnchanged(original, modified),
        throwsFormatException,
      );
    }
  });

  test('Story engine independently journals a recap with no rule changes', () {
    var sequence = 0;
    final component = StoryCampaignEngine(
      nextId: (prefix) => '$prefix-${++sequence}',
      clock: () => DateTime.utc(2026, 10, 21),
      commit:
          (
            before,
            next,
            narration, {
            required String type,
            required Map<String, dynamic> payload,
          }) {
            expect(type, 'memory.sessionRecapSaved');
            return GameUpdate(
              campaign: next.copyWith(revision: before.revision + 1),
              events: const [],
            );
          },
    );
    final initial = _campaign();
    final result = component.saveSessionRecap(initial);
    expect(result.campaign.sessionRecaps, hasLength(1));
    expect(result.campaign.hero.hitPoints, 20);
    expect(result.campaign.revision, 1);
    expect(result.campaign.quests.single.id, 'quest-1');
  });

  test('Story commit interface rejects even subtle forbidden HP mutation', () {
    final malicious = StoryCampaignEngine(
      nextId: (prefix) => '$prefix-1',
      clock: () => DateTime.utc(2026, 10, 21),
      commit:
          (
            before,
            next,
            narration, {
            required String type,
            required Map<String, dynamic> payload,
          }) => GameUpdate(
            campaign: next.copyWith(hero: next.hero.copyWith(hitPoints: 1)),
            events: const [],
          ),
    );
    expect(
      () => malicious.saveSessionRecap(_campaign()),
      throwsFormatException,
    );
  });

  test(
    'MemoryEngine remains backward compatible through GameEngine export',
    () {
      final campaign = _campaign();
      expect(
        legacy.MemoryEngine.buildSessionSummary(campaign),
        story.MemoryEngine.buildSessionSummary(campaign),
      );
      expect(
        story.MemoryEngine.isRecallRequest('Erinnere dich an Rabenwacht'),
        isTrue,
      );
      final old = campaign.toJson();
      expect(Campaign.fromJson(old).toJson(), old);
    },
  );
}
