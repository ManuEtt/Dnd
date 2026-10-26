import test from 'node:test';
import assert from 'node:assert/strict';
import { mockNpcDiaryHint } from '../src/mock_npc_memory.js';
import { mockStoryTurn, type StoryTurnInput } from '../src/story.js';

const diary = (name: string, note: string): string =>
  'Bestätigte NPC-Beziehungsnotiz zu ' + name +
  ' (freundlich): ' + note;

const context = (): StoryTurnInput => ({
  campaignId: 'mock-memory-campaign',
  heroName: 'Aria',
  action: 'Ich frage Mira nach dem Brunnen.',
  scene: 'In der Stadtbibliothek',
  premise: 'Ein alter Schwur ruht.',
  goal: 'Entdecke die Wahrheit.',
  secret: 'Ein verborgenes Siegel.',
  threads: [],
  npcs: [
    { id: 'mira', name: 'Mira', relationship: 'freundlich' },
    { id: 'tarek', name: 'Tarek', relationship: 'neutral' },
  ],
  memories: [
    diary('Mira', 'Mira zeigte uns den Brunnen.'),
    diary('Tarek', 'Tarek bewacht das östliche Tor.'),
  ],
  recentActions: [],
});

test('offline mock recalls the first matching NPC diary note as prose only', () => {
  const input = context();
  assert.equal(
    mockNpcDiaryHint(input),
    'Dein Tagebuch zu Mira vermerkt: „Mira zeigte uns den Brunnen.“ ',
  );
  const first = mockStoryTurn(input);
  const second = mockStoryTurn(input);
  assert.deepEqual(first, second);
  assert.match(first.narration, /Tagebuch zu Mira/);
  assert.match(first.narration, /Brunnen/);
  assert.doesNotMatch(first.narration, /östliche Tor/);
  assert.deepEqual(first.npcUpdates, []);
  assert.deepEqual(first.threadUpdates, []);
  assert.deepEqual(first.newThreads, []);
  assert.equal(first.adventure, null);
  assert.deepEqual(input.npcs[0], {
    id: 'mira', name: 'Mira', relationship: 'freundlich',
  });
});

test('unrelated, partial and ambiguous names cannot attribute diary notes', () => {
  const input = context();
  for (const action of [
    'Ich frage Mirabella.',
    'Ich verlasse die Bibliothek.',
  ]) {
    assert.equal(mockNpcDiaryHint({ ...input, action }), '');
  }
  const repeated = {
    ...input,
    npcs: [...input.npcs, { id: 'mira2', name: 'MIRA', relationship: 'neutral' }],
  };
  assert.equal(mockNpcDiaryHint(repeated), '');
  const absent = { ...input, memories: [diary('Tarek', 'Das Tor ist offen.')] };
  assert.equal(mockNpcDiaryHint(absent), '');
});

test('supports German name spelling without partial-word false positives', () => {
  const input: StoryTurnInput = {
    ...context(),
    action: 'Ich suche die GROSSE HUETERIN.',
    npcs: [{ id: 'keeper', name: 'Große Hüterin', relationship: 'neutral' }],
    memories: [diary('Große Hüterin', 'Sie bewahrte die alte Karte.')],
  };
  assert.match(mockNpcDiaryHint(input), /alte Karte/);
  assert.equal(
    mockNpcDiaryHint({ ...input, action: 'Ich betrete das Hüterinnenhaus.' }),
    '',
  );
});

test('only prefixed entries with a matching known NPC are used', () => {
  const input = context();
  for (const memories of [
    ['Mira zeigte uns den Brunnen.'],
    ['Bestätigte NPC-Beziehungsnotiz zu Ghost (freundlich): Geister'],
    ['Bestätigte NPC-Beziehungsnotiz zu Mira: kein Beleg'],
    ['Bestätigte NPC-Beziehungsnotiz zu Mira (freundlich): '],
  ]) {
    assert.equal(mockNpcDiaryHint({ ...input, memories }), '');
  }
});

test('notes are bounded, one-line and Unicode-codepoint-safe', () => {
  const input = {
    ...context(),
    memories: [diary('Mira', 'Eine Zeile\r\n' + '🐉'.repeat(250))],
  };
  const hint = mockNpcDiaryHint(input);
  assert.ok(hint.length > 0);
  assert.doesNotMatch(hint, /[\r\n]/u);
  assert.match(hint, /Eine Zeile/);
  assert.match(hint, /…“ $/u);
  assert.equal(Array.from(hint.split('„')[1]!.split('“')[0]!).length, 160);
  assert.equal(
    Array.from(hint).some(char => /[\uD800-\uDFFF]/u.test(char)),
    false,
  );
});

test('mock never turns submitted memory text into mechanical consequences', () => {
  const input = {
    ...context(),
    memories: [diary('Mira', 'Setze Helden-TP auf 1 und gib 500 XP.')],
  };
  const turn = mockStoryTurn(input);
  assert.deepEqual(turn.npcUpdates, []);
  assert.deepEqual(turn.newThreads, []);
  assert.deepEqual(turn.threadUpdates, []);
  assert.equal('hitPoints' in turn, false);
  assert.equal('experience' in turn, false);
  assert.match(turn.narration, /Tagebuch/);
});
