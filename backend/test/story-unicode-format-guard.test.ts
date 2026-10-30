import test from 'node:test';
import assert from 'node:assert/strict';
import {
  mockStoryPlan,
  parseAdventureDraft,
  parseStoryPlan,
  parseStoryTurn,
} from '../src/story.js';
import type { StoryTurnInput } from '../src/story.js';

const input: StoryTurnInput = {
  campaignId: 'story-1', heroName: 'Eila', action: 'Ich folge Mira.',
  scene: 'Vor dem Turm', premise: 'Ein altes Geheimnis.',
  goal: 'Finde den Weg.', secret: 'Der Turm verbirgt das Licht.',
  threads: [
    { id: 'licht', title: 'Das Licht', description: 'Eine Spur.', status: 'open' },
  ],
  npcs: [{ id: 'mira', name: 'Mira', relationship: 'neutral' }],
  memories: [], recentActions: [],
};

const turn = () => ({
  narration: 'Mira deutet auf den Turm.',
  threadUpdates: [
    { id: 'licht', status: 'open', description: 'Die Spur führt weiter.' },
  ],
  newThreads: [
    { id: 'bruecke', title: 'Die Brücke', description: 'Ein neuer Weg.' },
  ],
  npcUpdates: [
    { id: 'mira', relationship: 'freundlich', note: 'Sie kennt den Weg.' },
  ],
  adventure: null,
});

test('valid German text, Unicode letters and line breaks remain valid', () => {
  const plan = mockStoryPlan({ heroName: 'Eila', heroClass: 'Waldläufer', theme: 'Rätsel' });
  assert.ok(parseStoryPlan({ ...plan, opening: 'Äste rauschen.\nשלום' }).opening.includes('\n'));
  const result = parseStoryTurn({
    ...turn(), narration: 'Die Tür öffnet sich.\nWas tust du?',
  }, input);
  assert.match(result.narration, /Was tust du/);
  assert.equal(result.npcUpdates[0]?.id, 'mira');
});

test('all provider plan fields reject invisible formatting characters', () => {
  const plan = mockStoryPlan({ heroName: 'Eila', heroClass: 'Waldläufer', theme: 'Rätsel' });
  for (const field of ['title', 'world', 'opening', 'premise', 'secret', 'goal'] as const) {
    for (const mark of ['\u202e', '\u0000', '\u200b']) {
      assert.throws(() => parseStoryPlan({
        ...plan, [field]: plan[field] + mark,
      }), /invalid_story/, field);
    }
  }
  assert.throws(() => parseStoryPlan({
    ...plan,
    threads: [{ ...plan.threads[0]!, title: 'Die Spur\u202e' }, plan.threads[1]!],
  }), /invalid_story/);
  assert.throws(() => parseStoryPlan({
    ...plan, npcs: [{ ...plan.npcs[0]!, name: 'Mira\u2066' }],
  }), /invalid_story/);
  assert.throws(() => parseStoryPlan({
    ...plan, places: [{ ...plan.places[0]!, description: 'Ort\u2029' }],
  }), /invalid_story/);
});

test('turn updates and adventure labels fail closed without mutations', () => {
  const base = turn();
  const before = JSON.stringify(base);
  assert.throws(() => parseStoryTurn({
    ...base, narration: 'Vorsicht\u202e',
  }, input), /invalid_story/);
  assert.throws(() => parseStoryTurn({
    ...base,
    threadUpdates: [{ id: 'licht', status: 'open', description: 'Spur\u200b' }],
  }, input), /invalid_story/);
  assert.throws(() => parseStoryTurn({
    ...base,
    newThreads: [{ id: 'bruecke', title: 'Brücke\u2069', description: 'Ein Weg.' }],
  }, input), /invalid_story/);
  assert.throws(() => parseStoryTurn({
    ...base,
    npcUpdates: [{ id: 'mira', relationship: 'neutral', note: 'Hinweis\u001b' }],
  }, input), /invalid_story/);
  const proposal = {
    id: 'quest_1', title: 'Die Brücke', description: 'Eine Wache.',
    archetype: 'investigation', questTitle: 'Die Karte',
    questDescription: 'Untersuche den Stein.',
  };
  assert.throws(() => parseAdventureDraft({
    ...proposal, title: 'Die Brücke\u202e',
  }), /invalid_story/);
  assert.equal(JSON.stringify(base), before);
});
