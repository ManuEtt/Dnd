import test from 'node:test';
import assert from 'node:assert/strict';
import {
  mockStoryPlan,
  parseAdventureDraft,
  parseStoryPlan,
  parseStoryTurn,
} from '../src/story.js';
import type { StoryTurnInput } from '../src/story.js';

const hiddenMarks = [
  '\u00ad', '\u034f', '\u180e', '\u206a', '\u206b',
  '\u206c', '\u206d', '\u206e', '\u206f',
];

const input: StoryTurnInput = {
  campaignId: 'c1', heroName: 'Eila', action: 'Ich frage Mira.',
  scene: 'Am Turm', premise: 'Ein Geheimnis.', goal: 'Finde den Weg.',
  secret: 'Der Turm bewahrt ein Licht.',
  threads: [
    { id: 'spur', title: 'Die Spur', description: 'Suche.', status: 'open' },
  ],
  npcs: [{ id: 'mira', name: 'Mira', relationship: 'neutral' }],
  memories: [], recentActions: [],
};

const turn = () => ({
  narration: 'Eine neue Spur.',
  threadUpdates: [
    { id: 'spur', status: 'open', description: 'Finde den Weg.' },
  ],
  newThreads: [
    { id: 'bruecke', title: 'Die Brücke', description: 'Ein Pfad.' },
  ],
  npcUpdates: [
    { id: 'mira', relationship: 'freundlich', note: 'Sie half.' },
  ],
  adventure: null,
});

test('legacy invisible format marks fail in every top-level plan field', () => {
  const plan = mockStoryPlan({
    heroName: 'Eila', heroClass: 'Waldläufer', theme: 'Rätsel',
  });
  for (const mark of hiddenMarks) {
    for (const field of [
      'title', 'world', 'opening', 'premise', 'secret', 'goal',
    ] as const) {
      assert.throws(
        () => parseStoryPlan({ ...plan, [field]: 'Vor' + mark + 'Nach' }),
        /invalid_story/,
        field,
      );
    }
    assert.throws(() => parseStoryPlan({
      ...plan,
      threads: [{ ...plan.threads[0]!, description: 'Vor' + mark + 'Nach' }, plan.threads[1]!],
    }), /invalid_story/);
    assert.throws(() => parseStoryPlan({
      ...plan,
      npcs: [{ ...plan.npcs[0]!, name: 'Vor' + mark + 'Nach' }],
    }), /invalid_story/);
    assert.throws(() => parseStoryPlan({
      ...plan,
      places: [{ ...plan.places[0]!, description: 'Vor' + mark + 'Nach' }],
    }), /invalid_story/);
  }
});

test('legacy invisible marks fail across story turn and adventure prose', () => {
  const original = turn();
  const baseline = JSON.stringify(original);
  for (const mark of hiddenMarks) {
    assert.throws(() => parseStoryTurn({
      ...turn(), narration: 'Vor' + mark + 'Nach',
    }, input), /invalid_story/);
    assert.throws(() => parseStoryTurn({
      ...turn(),
      threadUpdates: [{
        id: 'spur', status: 'open', description: 'Vor' + mark + 'Nach',
      }],
    }, input), /invalid_story/);
    assert.throws(() => parseStoryTurn({
      ...turn(),
      newThreads: [{
        id: 'bruecke', title: 'Vor' + mark + 'Nach', description: 'Ein Pfad.',
      }],
    }, input), /invalid_story/);
    assert.throws(() => parseStoryTurn({
      ...turn(),
      npcUpdates: [{
        id: 'mira', relationship: 'neutral', note: 'Vor' + mark + 'Nach',
      }],
    }, input), /invalid_story/);
    assert.throws(() => parseAdventureDraft({
      id: 'quest_1', title: 'Vor' + mark + 'Nach',
      description: 'Eine Wache.', archetype: 'investigation',
      questTitle: 'Die Karte', questDescription: 'Finde die Karte.',
    }), /invalid_story/);
  }
  assert.equal(JSON.stringify(original), baseline);
});

test('German accents, ordinary line breaks and emoji remain valid', () => {
  const plan = mockStoryPlan({
    heroName: 'Eila', heroClass: 'Waldläufer', theme: 'Rätsel',
  });
  const opening = 'Äste rascheln.\nEin Drache 🐉 fliegt über den Turm ❤️';
  assert.equal(parseStoryPlan({ ...plan, opening }).opening, opening);
  const narration = 'Die Tür öffnet sich.\nWas tust du? 🐉';
  assert.equal(parseStoryTurn({ ...turn(), narration }, input).narration, narration);
});
