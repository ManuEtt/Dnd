import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_campaign_engine.dart';
import 'package:lebendiger_spielleiter/story/story_rule_boundary.dart';

Campaign _campaign() => Campaign(
  id: 'revision-guard',
  name: 'Das Nebelarchiv',
  world: 'Rabenwacht',
  sessionId: 'session-1',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Aria',
    hitPoints: 16,
    maxHitPoints: 16,
    armorClass: 12,
  ),
  scene: 'Vor dem alten Turm.',
  facts: const {'location': 'tower'},
  revision: 8,
);

StoryCampaignEngine _engine(int revisionDelta) => StoryCampaignEngine(
  nextId: (prefix) => '$prefix-test',
  clock: () => DateTime.utc(2026, 11, 12),
  commit:
      (
        before,
        next,
        narration, {
        required String type,
        required Map<String, dynamic> payload,
      }) => GameUpdate(
        campaign: next.copyWith(revision: before.revision + revisionDelta),
        events: const [],
      ),
);

void main() {
  test('narrative rewrite and single confirmed commit preserve revision order', () {
    final saved = _campaign();
    final before = jsonEncode(saved.toJson());
    for (final delta in [0, 1]) {
      final candidate = saved.copyWith(
        revision: saved.revision + delta,
        scene: 'Ein neuer Weg öffnet sich.',
        storyBible: const {'stage': 'crossroads'},
      );
      expect(
        () => StoryRuleBoundary.ensureRuleStateUnchanged(saved, candidate),
        returnsNormally,
        reason: 'delta $delta',
      );
      expect(candidate.hero.toJson(), saved.hero.toJson());
      expect(candidate.facts, saved.facts);
    }
    expect(jsonEncode(saved.toJson()), before);
  });

  test('rollback and skipped revisions cannot be disguised as story edits', () {
    final saved = _campaign();
    final before = jsonEncode(saved.toJson());
    for (final delta in [-8, -1, 2, 3, 99]) {
      final changed = saved.copyWith(
        scene: 'Die Erzählung geht weiter.',
        revision: saved.revision + delta,
      );
      expect(
        () => StoryRuleBoundary.ensureRuleStateUnchanged(saved, changed),
        throwsFormatException,
        reason: 'delta $delta',
      );
    }
    expect(jsonEncode(saved.toJson()), before);
  });

  test('single-step revision never permits a hidden rule-state mutation', () {
    final saved = _campaign();
    final changed = saved.copyWith(
      revision: saved.revision + 1,
      scene: 'Eine andere Geschichte.',
      hero: saved.hero.copyWith(hitPoints: 1),
    );
    expect(
      () => StoryRuleBoundary.ensureRuleStateUnchanged(saved, changed),
      throwsFormatException,
    );
  });

  test('real story commit callback rejects incorrect revisions', () {
    final saved = _campaign();
    final before = jsonEncode(saved.toJson());

    for (final delta in [-1, 2]) {
      expect(
        () => _engine(delta).saveSessionRecap(saved),
        throwsFormatException,
        reason: 'delta $delta',
      );
    }

    for (final delta in [0, 1]) {
      final accepted = _engine(delta).saveSessionRecap(saved).campaign;
      expect(accepted.revision, saved.revision + delta);
      expect(accepted.sessionRecaps, hasLength(1));
      expect(accepted.hero.toJson(), saved.hero.toJson());
      expect(accepted.facts, saved.facts);
    }
    expect(jsonEncode(saved.toJson()), before);
  });

  test('legacy JSON resumed revision remains protected without migration', () {
    final original = _campaign();
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());
    expect(restored.revision, 8);

    expect(
      () => StoryRuleBoundary.ensureRuleStateUnchanged(
        restored,
        restored.copyWith(revision: 10, scene: 'Eine neue Erzählung.'),
      ),
      throwsFormatException,
    );
    final committed = _engine(1).saveSessionRecap(restored).campaign;
    expect(committed.revision, 9);
    expect(committed.sessionRecaps, hasLength(1));
    expect(committed.hero.toJson(), restored.hero.toJson());
    expect(jsonEncode(restored.toJson()), before);
  });
}
