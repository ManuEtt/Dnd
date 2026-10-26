import test from 'node:test';
import assert from 'node:assert/strict';

import { buildApp } from '../src/app.js';
import { mockNpcIdentityHint } from '../src/mock_npc_identity_hint.js';
import { mockStoryTurn } from '../src/story.js';
import { validateNpcIdentityContext, type StoryTurnWithNpcIdentities } from '../src/story_npc_identity_context.js';
import type { Config } from '../src/config.js';

const request = (): StoryTurnWithNpcIdentities => ({
  campaignId: 'choice-demo',
  heroName: 'Aria',
  action: 'Ich betrachte das Zeichen.',
  scene: 'Die Bibliothek',
  premise: 'Ein alter Schwur',
  goal: 'Die Stadt retten',
  secret: 'Das Siegel schützt die Bibliothek.',
  threads: [],
  npcs: [
    { id: 'mira-one', name: 'Mira', relationship: 'freundlich' },
    { id: 'mira-two', name: 'Mira', relationship: 'misstrauisch' },
  ],
  memories: ['Bestätigte NPC-Beziehungsnotiz zu Mira (freundlich): Falsches Gerücht.'],
  recentActions: [],
  campaignRevision: 8,
  selectedNpcId: 'mira-two',
  npcContexts: [{
    campaignId: 'choice-demo',
    campaignRevision: 8,
    npcId: 'mira-two',
    npcName: 'Mira',
    alive: true,
    relationship: 'misstrauisch',
    notes: [{
      id: 'diary-two',
      npcId: 'mira-two',
      relationship: 'misstrauisch',
      note: 'Die zweite Mira bewacht das Stadttor.',
      recordedAt: '2026-10-26T12:00:00.000Z',
    }],
  }],
});

test('selected ID disambiguates same-name NPCs even without name in action', () => {
  const data = request();
  const before = JSON.stringify(data);
  assert.doesNotThrow(() => validateNpcIdentityContext(data));
  const hint = mockNpcIdentityHint(data);
  assert.match(hint, /Stadttor/);
  assert.doesNotMatch(hint, /Gerücht/);
  const turn = mockStoryTurn(data);
  assert.match(turn.narration, /Stadttor/);
  assert.deepEqual(turn.npcUpdates, []);
  assert.deepEqual(turn.threadUpdates, []);
  assert.deepEqual(turn.newThreads, []);
  assert.equal(turn.adventure, null);
  assert.equal(JSON.stringify(data), before);
});

test('without explicit ID, same-name NPC still cannot be inferred', () => {
  const data = request();
  delete data.selectedNpcId;
  data.action = 'Ich spreche Mira an.';
  assert.equal(mockNpcIdentityHint(data), '');
  assert.doesNotMatch(mockStoryTurn(data).narration, /Stadttor/);
  assert.deepEqual(mockStoryTurn(data).npcUpdates, []);
});

test('selection is tied to exactly one matching context and revision', () => {
  const invalid = [
    (v: StoryTurnWithNpcIdentities) => { v.selectedNpcId = 'mira-one'; },
    (v: StoryTurnWithNpcIdentities) => { v.selectedNpcId = 'ghost'; },
    (v: StoryTurnWithNpcIdentities) => { v.selectedNpcId = '../mira-two'; },
    (v: StoryTurnWithNpcIdentities) => { v.selectedNpcId = ''; },
    (v: StoryTurnWithNpcIdentities) => { v.campaignRevision = 9; },
    (v: StoryTurnWithNpcIdentities) => { v.npcContexts![0]!.campaignRevision = 7; },
    (v: StoryTurnWithNpcIdentities) => { v.npcContexts![0]!.campaignId = 'foreign'; },
    (v: StoryTurnWithNpcIdentities) => { v.npcContexts![0]!.notes[0]!.npcId = 'mira-one'; },
    (v: StoryTurnWithNpcIdentities) => { v.npcContexts![0]!.notes = []; },
    (v: StoryTurnWithNpcIdentities) => { v.npcContexts = []; },
    (v: StoryTurnWithNpcIdentities) => { v.npcContexts!.push(structuredClone(v.npcContexts![0]!)); },
    (v: StoryTurnWithNpcIdentities) => { delete v.npcContexts; },
    (v: StoryTurnWithNpcIdentities) => { delete v.campaignRevision; },
  ];
  for (const mutate of invalid) {
    const data = request();
    mutate(data);
    assert.throws(() => validateNpcIdentityContext(data));
    assert.equal(mockNpcIdentityHint(data), '');
  }
});

test('legacy API and previously valid identity contexts stay compatible', () => {
  const legacy = request();
  delete legacy.selectedNpcId;
  delete legacy.npcContexts;
  delete legacy.campaignRevision;
  assert.doesNotThrow(() => validateNpcIdentityContext(legacy));
  const oldIdentity = request();
  delete oldIdentity.selectedNpcId;
  assert.doesNotThrow(() => validateNpcIdentityContext(oldIdentity));
});

const config: Config = {
  host: '127.0.0.1',
  port: 3000,
  accessToken: 'selected-npc-access-0123456789abcdef',
  sessionSecret: 'selected-npc-session-0123456789abcdef',
  sessionTtlSeconds: 300,
  requestsPerMinute: 30,
  requestsPerDay: 100,
  provider: 'mock',
};

test('real story endpoint narrates chosen NPC and rejects wrong ID before provider', async t => {
  const app = buildApp(config);
  t.after(() => app.close());
  const token = await app.inject({
    method: 'POST',
    url: '/v1/session',
    headers: { authorization: 'Bearer ' + config.accessToken },
    payload: {},
  });
  assert.equal(token.statusCode, 200);
  assert.deepEqual(token.json().capabilities, ['npc-identity-v1', 'npc-selection-v1']);
  const headers = { authorization: 'Bearer ' + token.json<{token:string}>().token };
  const session = await app.inject({
    method: 'GET', url: '/v1/session', headers,
  });
  assert.equal(session.statusCode, 200);
  assert.deepEqual(session.json().capabilities, ['npc-identity-v1', 'npc-selection-v1']);

  const success = await app.inject({
    method: 'POST', url: '/v1/story/advance', headers, payload: request(),
  });
  assert.equal(success.statusCode, 200, success.body);
  assert.match(success.json().turn.narration, /Stadttor/);
  assert.doesNotMatch(success.json().turn.narration, /Falsches Gerücht/);
  assert.deepEqual(success.json().stateChanges, []);
  assert.deepEqual(success.json().turn.npcUpdates, []);

  for (const mutate of [
    (v: StoryTurnWithNpcIdentities) => { v.selectedNpcId = 'mira-one'; },
    (v: StoryTurnWithNpcIdentities) => { delete v.npcContexts; },
    (v: StoryTurnWithNpcIdentities) => { v.selectedNpcId = 'mira$two'; },
  ]) {
    const bad = request();
    mutate(bad);
    const result = await app.inject({
      method: 'POST', url: '/v1/story/advance', headers, payload: bad,
    });
    assert.equal(result.statusCode, 400, result.body);
    assert.equal(result.json().error, 'invalid_request');
  }
});
