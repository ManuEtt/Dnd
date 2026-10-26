import test from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { mockNpcIdentityHint } from '../src/mock_npc_identity_hint.js';
import { mockStoryTurn } from '../src/story.js';
import type { StoryTurnWithNpcIdentities } from '../src/story_npc_identity_context.js';
import type { Config } from '../src/config.js';

const oldNote = 'Bestätigte NPC-Beziehungsnotiz zu Mira (freundlich): Alte Karte.';
const input = (): StoryTurnWithNpcIdentities => ({
  campaignId: 'chronicle_7', heroName: 'Aria',
  action: 'Ich frage Mira nach dem verlorenen Ring.',
  scene: 'Die Bibliothek von Eiren.',
  premise: 'Ein uralter Schwur.', goal: 'Das Archiv finden.',
  secret: 'Der Schwur ist gebrochen.', threads: [],
  npcs: [
    { id: 'mira-a', name: 'Mira', relationship: 'freundlich' },
    { id: 'tarek', name: 'Tarek', relationship: 'neutral' },
  ],
  memories: [oldNote], recentActions: [],
  campaignRevision: 17,
  npcContexts: [{
    campaignId: 'chronicle_7', campaignRevision: 17,
    npcId: 'mira-a', npcName: 'Mira', alive: true,
    relationship: 'freundlich',
    notes: [
      { id: 'note-new', npcId: 'mira-a', relationship: 'freundlich',
        note: 'Mira gab mir den silbernen Ring.',
        recordedAt: '2026-10-26T05:00:00.000Z' },
      { id: 'note-old', npcId: 'mira-a', relationship: 'neutral',
        note: 'Mira hütet das Geheimnis der Karte.',
        recordedAt: '2026-10-25T05:00:00.000Z' },
    ],
  }],
});

test('structured ID-bound note takes precedence over old marked diary', () => {
  const request = input();
  const previous = JSON.stringify(request);
  const hint = mockNpcIdentityHint(request);
  assert.equal(hint, 'Dein Tagebuch zu Mira vermerkt: „Mira gab mir den silbernen Ring.“ ');
  const turn = mockStoryTurn(request);
  assert.match(turn.narration, /silbernen Ring/);
  assert.doesNotMatch(turn.narration, /Alte Karte/);
  assert.deepEqual(turn.npcUpdates, []);
  assert.deepEqual(turn.threadUpdates, []);
  assert.deepEqual(turn.newThreads, []);
  assert.equal(turn.adventure, null);
  assert.equal(JSON.stringify(request), previous);
});

test('unrelated, missing and incomplete identity context preserves legacy', () => {
  const legacy = input();
  delete legacy.npcContexts;
  delete legacy.campaignRevision;
  assert.equal(mockNpcIdentityHint(legacy), '');
  assert.match(mockStoryTurn(legacy).narration, /Alte Karte/);
  const unrelated = { ...input(), action: 'Ich verlasse das Dorf.' };
  assert.equal(mockNpcIdentityHint(unrelated), '');
  assert.doesNotMatch(mockStoryTurn({
    ...unrelated, memories: [],
  }).narration, /Tagebuch/);
  const incomplete = input();
  delete incomplete.campaignRevision;
  assert.equal(mockNpcIdentityHint(incomplete), '');
});

test('similar names and duplicate visible names never imply an NPC identity', () => {
  const request = input();
  assert.equal(mockNpcIdentityHint({ ...request, action: 'Ich rufe Mirabella.' }), '');
  assert.equal(mockNpcIdentityHint({ ...request, action: 'Ich rufe miras.' }), '');
  const duplicates = input();
  duplicates.npcs.push({ id: 'mira-b', name: 'MIRA', relationship: 'feindlich' });
  assert.equal(mockNpcIdentityHint(duplicates), '');
  duplicates.memories = [];
  assert.doesNotMatch(mockStoryTurn(duplicates).narration, /Dein Tagebuch/);
});

test('diacritics in a non-German NPC name never break Unicode matching', () => {
  const request = input();
  request.npcs[0]!.name = 'Éloïse';
  request.npcContexts![0]!.npcName = 'Éloïse';
  request.action = 'Ich spreche Éloïse an.';
  assert.match(mockNpcIdentityHint(request), /silbernen Ring/u);
});

test('unknown IDs, stale revisions, and swapped notes cannot be narrated', () => {
  const mutations: Array<(value: StoryTurnWithNpcIdentities) => void> = [
    v => { v.campaignRevision = 18; },
    v => { v.npcContexts![0]!.campaignId = 'other_campaign'; },
    v => { v.npcContexts![0]!.npcId = 'tarek'; },
    v => { v.npcContexts![0]!.notes[0]!.npcId = 'tarek'; },
    v => { v.npcContexts![0]!.notes.reverse(); },
    v => { v.npcContexts![0]!.notes[0]!.note = 'Zeile 1\nZeile 2'; },
  ];
  for (const mutate of mutations) {
    const request = input();
    mutate(request);
    assert.equal(mockNpcIdentityHint(request), '');
  }
});

test('structured note is kept to a single codepoint-safe narration excerpt', () => {
  const request = input();
  request.npcContexts![0]!.notes[0]!.note = '🐉'.repeat(240);
  const hint = mockNpcIdentityHint(request);
  assert.equal(Array.from(hint.split('„')[1]!.split('“')[0]!).length, 160);
  assert.match(hint, /…“ $/u);
  assert.doesNotMatch(hint, /[\r\n]/u);
  assert.ok(!Array.from(hint).some(char => /[\uD800-\uDFFF]/u.test(char)));
});

const config: Config = {
  host: '127.0.0.1', port: 3000,
  accessToken: 'mock-npc-identity-access-0123456789',
  sessionSecret: 'mock-npc-identity-session-0123456789',
  sessionTtlSeconds: 300, requestsPerMinute: 30,
  requestsPerDay: 100, provider: 'mock',
};

test('Fastify mock narrates new NPC ID context without changing state', async t => {
  const app = buildApp(config);
  t.after(() => app.close());
  const authenticated = await app.inject({
    method: 'POST', url: '/v1/session',
    headers: { authorization: 'Bearer ' + config.accessToken },
    payload: {},
  });
  assert.equal(authenticated.statusCode, 200);
  const headers = {
    authorization: 'Bearer ' + authenticated.json<{ token: string }>().token,
  };
  const good = await app.inject({
    method: 'POST', url: '/v1/story/advance',
    headers, payload: input(),
  });
  assert.equal(good.statusCode, 200, good.body);
  assert.match(good.json().turn.narration, /silbernen Ring/);
  assert.doesNotMatch(good.json().turn.narration, /Alte Karte/);
  assert.deepEqual(good.json().stateChanges, []);
  assert.deepEqual(good.json().turn.npcUpdates, []);
  const bad = input();
  bad.npcContexts![0]!.campaignRevision = 16;
  const response = await app.inject({
    method: 'POST', url: '/v1/story/advance',
    headers, payload: bad,
  });
  assert.equal(response.statusCode, 400);
  assert.equal(response.json().error, 'invalid_request');
});
