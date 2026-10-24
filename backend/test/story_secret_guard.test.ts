import test from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import {
  guardStoryPlanSecrets,
  guardStoryTurnSecrets,
} from '../src/story_secret_guard.js';
import {
  mockStoryPlan, mockStoryTurn,
  type StoryTurnInput,
} from '../src/story.js';
import type { Config } from '../src/config.js';
import type { Narrator } from '../src/providers.js';

const accessToken = 'local-test-access-0123456789abcdef';
const signingSecret = 'local-test-signing-0123456789abcdef';
const config: Config = {
  host: '127.0.0.1',
  port: 3000,
  sessionSecret: signingSecret,
  accessToken,
  sessionTtlSeconds: 300,
  requestsPerMinute: 30,
  requestsPerDay: 100,
  provider: 'mock',
};

const plan = mockStoryPlan({
  heroName: 'Eila', heroClass: 'Waldläufer', theme: 'verlorene Städte',
});

const input: StoryTurnInput = {
  campaignId: 'schattenpfad', heroName: 'Eila',
  action: 'Ich spreche mit der Kartografin.', scene: 'Am Markttor',
  premise: 'Die Karte weist nach Norden.', goal: 'Finde den Pfad.',
  secret: plan.secret,
  threads: [
    { id: 'spur', title: 'Die Spur', description: 'Noch offen', status: 'open' },
  ],
  npcs: [{ id: 'seli', name: 'Seli', relationship: 'vorsichtig' }],
  memories: [], recentActions: [],
};

const turn = mockStoryTurn(input);

test('story start protects the secret across all public plan fields', () => {
  assert.equal(guardStoryPlanSecrets(plan), plan);
  const rawSecret = plan.secret;
  for (const changed of [
    { opening: 'Du hörst: ' + rawSecret },
    { title: rawSecret.toUpperCase() },
    { goal: '  ' + rawSecret + '  ' },
    { threads: [{ ...plan.threads[0]!, description: rawSecret }, ...plan.threads.slice(1) ] },
    { npcs: [{ ...plan.npcs[0]!, relationship: rawSecret }] },
    { places: [{ ...plan.places[0]!, description: rawSecret }] },
  ]) {
    assert.throws(
      () => guardStoryPlanSecrets({ ...plan, ...changed }),
      /story_secret_exposed/,
    );
  }
  assert.throws(() => guardStoryPlanSecrets({
    ...plan,
    opening: 'Die   NEBELKRONE ist kein Gegenstand, sondern ein gebrochener Schwur.',
  }), /story_secret_exposed/);
});

test('story turn protects dialogue, NPC notes, updates and adventure offers', () => {
  assert.equal(guardStoryTurnSecrets(turn, input.secret), turn);
  for (const changed of [
    { narration: 'Vorsicht! ' + input.secret },
    { newThreads: [{ id: 'warnung', title: 'Hinweis', description: input.secret }] },
    { threadUpdates: [{ id: 'spur', status: 'open' as const, description: input.secret }] },
    { npcUpdates: [{ id: 'seli', relationship: 'neutral', note: input.secret }] },
    { adventure: {
      id: 'pfad', title: 'Das Tor', description: input.secret,
      archetype: 'investigation', questTitle: 'Untersuche das Tor',
      questDescription: 'Finde den Hinweis.',
    } },
  ]) {
    assert.throws(
      () => guardStoryTurnSecrets({ ...turn, ...changed }, input.secret),
      /story_secret_exposed/,
    );
  }
});

test('whole-secret matching avoids false positives inside innocent names', () => {
  const simple = { ...turn, narration: 'Eila trägt einen Bogenläufer-Umhang.' };
  assert.equal(guardStoryTurnSecrets(simple, 'Bogen'), simple);
  assert.throws(
    () => guardStoryTurnSecrets({ ...simple, narration: 'Der Bogen fällt.' }, 'Bogen'),
    /story_secret_exposed/,
  );
  // Partial thematic hints are not automatic proof of a full secret reveal.
  assert.equal(guardStoryTurnSecrets(turn, 'Ein verborgenes Bündnis'), turn);
});

test('story routes reject exposed plot secrets without echoing private text', async (t) => {
  let leaked = true;
  const narrator: Narrator = {
    narrate: async () => ({ text: 'Unverändert.', provider: 'mock', stateChanges: [] }),
    startStory: async () => leaked
      ? { ...plan, opening: 'Unerwartet: ' + plan.secret }
      : plan,
    advanceStory: async () => leaked
      ? { ...turn, npcUpdates: [
        { id: 'seli', relationship: 'vorsichtig', note: input.secret },
      ] }
      : turn,
  };
  const app = buildApp(config, { narrator });
  t.after(() => app.close());
  const issued = await app.inject({
    method: 'POST', url: '/v1/session',
    headers: { authorization: 'Bearer ' + accessToken }, payload: {},
  });
  assert.equal(issued.statusCode, 200);
  const headers = { authorization: 'Bearer ' + issued.json<{ token: string }>().token };
  const startPayload = { heroName: 'Eila', heroClass: 'Waldläufer', theme: 'Küste' };
  for (const [url, payload] of [
    ['/v1/story/start', startPayload],
    ['/v1/story/advance', input],
  ] as const) {
    const refused = await app.inject({ method: 'POST', url, headers, payload });
    assert.equal(refused.statusCode, 502);
    assert.deepEqual(refused.json(), { error: 'provider_unavailable' });
    assert.doesNotMatch(refused.body, /Nebelkrone|verborgener Schwur|story_secret_exposed/);
  }
  leaked = false;
  const start = await app.inject({
    method: 'POST', url: '/v1/story/start', headers, payload: startPayload,
  });
  assert.equal(start.statusCode, 200);
  assert.deepEqual(start.json().stateChanges, []);
  assert.equal(start.json().story.opening, plan.opening);
  const advance = await app.inject({
    method: 'POST', url: '/v1/story/advance', headers, payload: input,
  });
  assert.equal(advance.statusCode, 200);
  assert.deepEqual(advance.json().stateChanges, []);
  assert.equal(advance.json().turn.narration, turn.narration);
});
