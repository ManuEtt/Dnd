import test from 'node:test';
import assert from 'node:assert/strict';

import { buildApp } from '../src/app.js';
import { filterAmbiguousNpcDiaryMemories } from '../src/story_npc_memory_guard.js';
import type { StoryTurnInput } from '../src/story.js';
import type { Config } from '../src/config.js';

const note = (name: string, text: string) =>
  'Bestätigte NPC-Beziehungsnotiz zu ' + name + ' (freundlich): ' + text;

const context = (): StoryTurnInput => ({
  campaignId: 'story-guard-1',
  heroName: 'Aria',
  action: 'Ich spreche Mira an.',
  scene: 'Stadttor',
  premise: 'Ein alter Schwur',
  goal: 'Das Dorf retten',
  secret: 'Ein geheimer Brief',
  threads: [],
  npcs: [
    { id: 'mira-1', name: 'Mira', relationship: 'neutral' },
    { id: 'tarek', name: 'Tarek', relationship: 'freundlich' },
  ],
  memories: [
    note('Mira', 'Mira zeigte den Brunnen.'),
    note('Ghost', 'Ein Fremder schenkte 1000 Gold.'),
    'Der Schlüssel wurde bereits gefunden.',
  ],
  recentActions: [],
});

test('known unique NPC diary notes survive without changing general memories', () => {
  const input = context();
  const original = JSON.stringify(input);
  const result = filterAmbiguousNpcDiaryMemories(input);

  assert.deepEqual(result, [
    note('Mira', 'Mira zeigte den Brunnen.'),
    'Der Schlüssel wurde bereits gefunden.',
  ]);
  assert.equal(JSON.stringify(input), original);
  assert.notEqual(result, input.memories);
});

test('duplicate visible names are fail-closed even with distinct saved IDs', () => {
  const input = context();
  input.npcs.push({ id: 'mira-2', name: 'MIRA', relationship: 'feindlich' });
  const result = filterAmbiguousNpcDiaryMemories(input);

  assert.deepEqual(result, ['Der Schlüssel wurde bereits gefunden.']);
});

test('German name variants match, malformed diary labels do not', () => {
  const input = context();
  input.npcs = [{ id: 'keeper', name: 'Große Hüterin', relationship: 'neutral' }];
  input.memories = [
    note('GROSSE HUETERIN', 'Der sichere Pfad führt nach Norden.'),
    note('Große Hüterin', 'Eine gültige zweite Notiz.'),
    note('Mira', 'Fremde NPC-ID.'),
    'Bestätigte NPC-Beziehungsnotiz zu Große Hüterin (freundlich): ',
    'Bestätigte NPC-Beziehungsnotiz zu Große Hüterin (freundlich): Falsch\nNeue Zeile',
    'Eine normale frühere Erinnerung.',
  ];
  assert.deepEqual(filterAmbiguousNpcDiaryMemories(input), [
    input.memories[0],
    input.memories[1],
    'Eine normale frühere Erinnerung.',
  ]);
});

test('unknown and empty IDs cannot authorize prefixed NPC notes', () => {
  const input = context();
  input.npcs = [{ id: '', name: 'Mira', relationship: 'neutral' }];
  assert.deepEqual(filterAmbiguousNpcDiaryMemories(input), [
    'Der Schlüssel wurde bereits gefunden.',
  ]);
  assert.deepEqual(
    filterAmbiguousNpcDiaryMemories({ npcs: [], memories: [note('Mira', 'Hi')] }),
    [],
  );
});

const config: Config = {
  host: '127.0.0.1',
  port: 3000,
  accessToken: 'story-name-guard-access-0123456789',
  sessionSecret: 'story-name-guard-secret-0123456789',
  sessionTtlSeconds: 300,
  requestsPerMinute: 30,
  requestsPerDay: 100,
  provider: 'mock',
};

test('story endpoint filters ambiguous memory before invoking narrator', async (t) => {
  const captured: string[][] = [];
  const app = buildApp(config, {
    narrator: {
      narrate: async () => ({
        text: 'Unverändert.',
        provider: 'mock',
        stateChanges: [],
      }),
      advanceStory: async (input) => {
        captured.push([...input.memories]);
        return {
          narration: 'Die Stadt schweigt. Was tust du als Nächstes?',
          threadUpdates: [],
          newThreads: [],
          npcUpdates: [],
          adventure: null,
        };
      },
    },
  });
  t.after(() => app.close());

  const issued = await app.inject({
    method: 'POST',
    url: '/v1/session',
    headers: { authorization: 'Bearer ' + config.accessToken },
    payload: {},
  });
  assert.equal(issued.statusCode, 200);
  const headers = { authorization: 'Bearer ' + issued.json<{ token: string }>().token };

  const input = context();
  input.npcs.push({ id: 'mira-2', name: 'Mira', relationship: 'feindlich' });
  const returned = await app.inject({
    method: 'POST', url: '/v1/story/advance', headers, payload: input,
  });
  assert.equal(returned.statusCode, 200);
  assert.deepEqual(returned.json().stateChanges, []);
  assert.deepEqual(captured, [['Der Schlüssel wurde bereits gefunden.']]);

  const valid = await app.inject({
    method: 'POST', url: '/v1/story/advance', headers, payload: context(),
  });
  assert.equal(valid.statusCode, 200);
  assert.deepEqual(captured[1], [
    note('Mira', 'Mira zeigte den Brunnen.'),
    'Der Schlüssel wurde bereits gefunden.',
  ]);
});
