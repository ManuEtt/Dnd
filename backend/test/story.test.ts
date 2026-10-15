import test from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { mockStoryPlan, mockStoryTurn, parseStoryPlan, parseStoryTurn } from '../src/story.js';
import type { StoryTurnInput } from '../src/story.js';
import type { Config } from '../src/config.js';

const token = 'story-test-access-token-0123456789abcdef';
const secret = 'story-test-signing-secret-0123456789abcdef';
const config: Config = {
  host: '127.0.0.1', port: 3000, accessToken: token, sessionSecret: secret,
  sessionTtlSeconds: 300, requestsPerMinute: 30, requestsPerDay: 100,
  provider: 'mock',
};
const action: StoryTurnInput = {
  campaignId: 'story-1', heroName: 'Eila', action: 'Ich helfe Tela.',
  scene: 'Im Hafen', premise: 'Eine bedrohte Welt', goal: 'Finde das Licht',
  secret: 'Ein verborgenes Bündnis',
  threads: [
    { id: 'spur', title: 'Die Spur', description: 'Offen', status: 'open' },
    { id: 'bund', title: 'Der Bund', description: 'Offen', status: 'open' },
  ],
  npcs: [{ id: 'tela', name: 'Tela', relationship: 'neutral' }],
  memories: ['Tela ist die Kapitänin.'], recentActions: ['Ich frage nach der Karte.'],
};

test('story plan validates ids, structure and secret safely', () => {
  const plan = mockStoryPlan({ heroName: 'Eila', heroClass: 'Waldläufer', theme: 'Sturm' });
  assert.equal(parseStoryPlan(plan).threads.length, 2);
  assert.throws(() => parseStoryPlan({ ...plan, secret: '' }));
  assert.throws(() => parseStoryPlan({ ...plan, threads: [plan.threads[0], plan.threads[0]] }));
  assert.throws(() => parseStoryPlan({ ...plan, places: [] }));
});

test('story changes cannot address unknown NPCs or overwrite existing IDs', () => {
  assert.ok(parseStoryTurn(mockStoryTurn(action), action).narration.includes('Eila'));
  assert.throws(() => parseStoryTurn({ narration: 'Ein Schritt.', threadUpdates: [],
    newThreads: [], npcUpdates: [{ id: 'stranger', relationship: 'gut', note: 'Hi' }] }, action));
  assert.throws(() => parseStoryTurn({ narration: 'Ein Schritt.', threadUpdates: [],
    newThreads: [{ id: 'spur', title: 'Doppelt', description: 'Kollision' }], npcUpdates: [] }, action));
  const safe = parseStoryTurn({ narration: 'Ein Schritt.', threadUpdates: [],
    newThreads: [], npcUpdates: [], hitPoints: 200, inventory: ['Sternenschwert'] }, action);
  assert.equal('hitPoints' in safe, false);
  assert.equal('inventory' in safe, false);
});

test('story routes require session and return validated fiction without stateChanges', async (t) => {
  const app = buildApp(config); t.after(() => app.close());
  const payload = { heroName: 'Eila', heroClass: 'Waldläufer', theme: 'eine geheimnisvolle Küste' };
  const denied = await app.inject({method: 'POST', url: '/v1/story/start', payload});
  assert.equal(denied.statusCode, 401);
  const issued = await app.inject({ method: 'POST', url: '/v1/session',
    headers: {authorization: `Bearer ${token}`}, payload: {} });
  const session = issued.json<{token:string}>().token;
  const headers = {authorization: `Bearer ${session}`};
  const started = await app.inject({ method: 'POST', url: '/v1/story/start', headers, payload });
  assert.equal(started.statusCode, 200);
  assert.equal(started.json().provider, 'mock');
  assert.deepEqual(started.json().stateChanges, []);
  assert.equal(started.json().story.threads.length, 2);
  const continued = await app.inject({method: 'POST', url: '/v1/story/advance',
    headers, payload: action });
  assert.equal(continued.statusCode, 200);
  assert.deepEqual(continued.json().stateChanges, []);
  assert.ok(continued.json().turn.narration.includes('Eila'));
  for (const bad of [{...action, threads: 'broken'}, {...action, recentActions: ['']},
    {...action, extra: 'untrusted'}]) {
    assert.equal((await app.inject({method:'POST',url:'/v1/story/advance',headers,payload:bad})).statusCode, 400);
  }
});

test('story requests share the session rate limit with narrative requests', async (t) => {
  const app = buildApp({...config, requestsPerMinute: 1}); t.after(() => app.close());
  const issued = await app.inject({method:'POST',url:'/v1/session',
    headers:{authorization:`Bearer ${token}`},payload:{}});
  const headers = {authorization:`Bearer ${issued.json().token}`};
  const start = await app.inject({method:'POST',url:'/v1/story/start',headers,
    payload:{heroName:'Eila',heroClass:'Kämpfer',theme:'ein neues Rätsel'}});
  assert.equal(start.statusCode, 200);
  const blocked = await app.inject({method:'POST',url:'/v1/story/advance',headers,payload:action});
  assert.equal(blocked.statusCode, 429);
});

test('OpenAI story calls use Responses structured JSON schema, no tools and store=false', async () => {
  const { OpenAiNarrator } = await import('../src/providers.js');
  let posted: Record<string, unknown> = {};
  const sample = mockStoryPlan({heroName:'Eila', heroClass:'Waldläufer',theme:'Abenteuer'});
  const fakeFetch: typeof fetch = async (_uri, options) => {
    posted = JSON.parse(String(options?.body)) as Record<string, unknown>;
    return { ok: true, json: async () => ({
      output: [{type: 'message', content: [{type: 'output_text', text: JSON.stringify(sample)}]}],
    }) } as Response;
  };
  const provider = new OpenAiNarrator('fake-key','test-model',fakeFetch);
  const result = await provider.startStory({heroName:'Eila', heroClass:'Waldläufer', theme:'Abenteuer'});
  assert.equal(result.title, sample.title);
  assert.equal(posted.store, false);
  assert.equal('tools' in posted, false);
  const format = (posted.text as {format:{type:string,name:string,strict:boolean}}).format;
  assert.equal(format.type, 'json_schema');
  assert.equal(format.name, 'story_plan');
  assert.equal(format.strict, true);
});
