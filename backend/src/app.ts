import Fastify, { type FastifyRequest, type FastifyReply } from 'fastify';
import type { Config } from './config.js';
import { bearerToken, issueSession, secureEqual, verifySession } from './auth.js';
import { WindowLimiter } from './limits.js';
import { createNarrator, type NarrationInput, type Narrator } from './providers.js';
import { parseStoryPlan, parseStoryTurn, validateStoryTurnContext, type StoryStartInput } from './story.js';
import { guardStoryPlanSecrets, guardStoryTurnSecrets } from './story_secret_guard.js';
import { filterAmbiguousNpcDiaryMemories } from './story_npc_memory_guard.js';
import { validateNpcIdentityContext, type StoryTurnWithNpcIdentities } from './story_npc_identity_context.js';

interface AppDependencies {
  clock?: () => number;
  narrator?: Narrator;
}
const nonBlankString = (maxLength: number) => ({ type: 'string', minLength: 1, maxLength, pattern: '\\S' });
const narrationSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['campaignId', 'playerName', 'action', 'scene'],
  properties: {
    campaignId: { type: 'string', minLength: 1, maxLength: 128, pattern: '^[a-zA-Z0-9_-]+$' },
    playerName: nonBlankString(80),
    action: nonBlankString(2000),
    scene: nonBlankString(4000),
    outcome: nonBlankString(4000),
    memories: { type: 'array', maxItems: 20, items: nonBlankString(400) },
  },
};

export function buildApp(config: Config, dependencies: AppDependencies = {}) {
  const app = Fastify({
    logger: false,
    bodyLimit: 32768,
    trustProxy: false,
    ajv: { customOptions: { removeAdditional: false, coerceTypes: false, useDefaults: false } },
  });
  const clock = dependencies.clock ?? Date.now;
  const narrator = dependencies.narrator ?? createNarrator(config);
  const sessionLimiter = new WindowLimiter();
  const minuteLimiter = new WindowLimiter();
  const dayLimiter = new WindowLimiter();

  app.addHook('onSend', async (_request, reply) => {
    reply.header('Cache-Control', 'no-store');
    reply.header('X-Content-Type-Options', 'nosniff');
    reply.header('Content-Security-Policy', "default-src 'none'");
  });
  app.setErrorHandler((error, _request, reply) => {
    const reportedStatus = error && typeof error === 'object' && 'statusCode' in error && typeof error.statusCode === 'number' ? error.statusCode : 500;
    const status = reportedStatus >= 400 && reportedStatus < 500 ? reportedStatus : 500;
    reply.code(status).send({
      error: status === 400 ? 'invalid_request' : status === 413 ? 'request_too_large' : status < 500 ? 'request_rejected' : 'internal_error',
      message: status === 400 ? 'Die Eingabe ist ungültig oder unvollständig.' : 'Die Anfrage konnte nicht verarbeitet werden.',
    });
  });

  app.get('/health', async () => ({ status: 'ok', provider: config.provider, version: '0.3.1' }));

  app.post('/v1/session', {
    schema: { body: { type: 'object', additionalProperties: false, properties: {} } },
  }, async (request, reply) => {
    if (!sessionLimiter.take(request.ip, clock(), 60000, 10)) {
      reply.header('Retry-After', '60');
      return reply.code(429).send({ error: 'rate_limit', message: 'Bitte warte eine Minute vor der nächsten Anmeldung.' });
    }
    if (!config.accessToken) return reply.code(503).send({ error: 'auth_not_configured', message: 'Der lokale Serverzugang ist noch nicht konfiguriert.' });
    const supplied = bearerToken(request.headers.authorization);
    if (!supplied || !secureEqual(supplied, config.accessToken)) {
      return reply.code(401).send({ error: 'unauthorized', message: 'Der Serverzugang ist ungültig.' });
    }
    const session = issueSession(config.sessionSecret, 'local-player', clock(), config.sessionTtlSeconds);
    return {
      token: session.token,
      tokenType: 'Bearer',
      expiresAt: new Date(session.claims.expiresAt * 1000).toISOString(),
      expiresIn: config.sessionTtlSeconds,
      provider: config.provider,
      scope: 'narration:read-only',
    };
  });

  // Checks an existing short-lived token without invoking a paid provider.
  // Mobile clients receive no bootstrap secret and never mint sessions themselves.
  app.get('/v1/session', async (request, reply) => {
    const token = bearerToken(request.headers.authorization);
    const session = token ? verifySession(token, config.sessionSecret, clock()) : undefined;
    if (!session) return reply.code(401).send({ error: 'invalid_session', message: 'Die Sitzung ist abgelaufen. Bitte verbinde dich erneut.' });
    return {
      scope: 'narration:read-only',
      provider: config.provider,
      expiresAt: new Date(session.expiresAt * 1000).toISOString(),
    };
  });

  // Shared provider budget: creative generation counts just like narration.
  const storyRateLimit = async (request: FastifyRequest, reply: FastifyReply) => {
    const token = bearerToken(request.headers.authorization);
    const session = token ? verifySession(token, config.sessionSecret, clock()) : undefined;
    if (!session) return reply.code(401).send({ error: 'invalid_session', message: 'Die Sitzung ist abgelaufen.' });
    const now = clock();
    if (!minuteLimiter.take(session.subject, now, 60000, config.requestsPerMinute)) {
      reply.header('Retry-After', '60');
      return reply.code(429).send({ error: 'rate_limit', message: 'Das Minutenlimit ist erreicht.' });
    }
    if (!dayLimiter.take(session.subject, now, 86400000, config.requestsPerDay)) {
      reply.header('Retry-After', '86400');
      return reply.code(429).send({ error: 'daily_limit', message: 'Das Tageslimit ist erreicht.' });
    }
  };
  const threadSchema = { type: 'object', additionalProperties: false,
    required: ['id', 'title', 'description', 'status'], properties: {
      id: nonBlankString(64), title: nonBlankString(120),
      description: { type: 'string', maxLength: 1000 },
      status: { type: 'string', enum: ['open', 'resolved', 'abandoned'] },
    } };
  const npcSchema = { type: 'object', additionalProperties: false,
    required: ['id', 'name', 'relationship'], properties: {
      id: nonBlankString(64), name: nonBlankString(80), relationship: nonBlankString(80),
    } };
  // Optional identity-bearing story context. Bounds match the read-only
  // client snapshot; older story clients can omit both optional fields.
  const npcIdentityNoteSchema = { type: 'object', additionalProperties: false,
    required: ['id', 'npcId', 'relationship', 'note', 'recordedAt'],
    properties: {
      id: nonBlankString(64), npcId: nonBlankString(64),
      relationship: nonBlankString(80), note: nonBlankString(500),
      recordedAt: nonBlankString(35),
    } };
  const npcIdentitySchema = { type: 'object', additionalProperties: false,
    required: ['campaignId', 'campaignRevision', 'npcId', 'npcName', 'alive', 'relationship', 'notes'],
    properties: {
      campaignId: nonBlankString(128),
      campaignRevision: { type: 'integer', minimum: 0, maximum: 2147483647 },
      npcId: nonBlankString(64), npcName: nonBlankString(80),
      alive: { type: 'boolean' }, relationship: nonBlankString(80),
      notes: { type: 'array', maxItems: 5, items: npcIdentityNoteSchema },
    } };
  app.post<{ Body: StoryStartInput }>('/v1/story/start', {
    schema: { body: { type: 'object', additionalProperties: false,
      required: ['heroName', 'heroClass', 'theme'], properties: {
        heroName: nonBlankString(80), heroClass: nonBlankString(80), theme: nonBlankString(300),
      } } }, preHandler: storyRateLimit,
  }, async (request, reply) => {
    if (!narrator.startStory) return reply.code(503).send({ error: 'story_unavailable' });
    try { return { provider: config.provider, stateChanges: [], story: guardStoryPlanSecrets(parseStoryPlan(await narrator.startStory(request.body))) }; }
    catch { return reply.code(502).send({ error: 'provider_unavailable' }); }
  });
  app.post<{ Body: StoryTurnWithNpcIdentities }>('/v1/story/advance', {
    schema: { body: { type: 'object', additionalProperties: false,
      required: ['campaignId', 'heroName', 'action', 'scene', 'premise', 'goal', 'secret', 'threads', 'npcs', 'memories', 'recentActions'],
      properties: {
        campaignId: { type: 'string', minLength: 1, maxLength: 128, pattern: '^[a-zA-Z0-9_-]+$' },
        heroName: nonBlankString(80), action: nonBlankString(2000), scene: nonBlankString(4000),
        premise: nonBlankString(1000), goal: nonBlankString(500), secret: nonBlankString(1000),
        threads: { type: 'array', maxItems: 100, items: threadSchema },
        npcs: { type: 'array', maxItems: 50, items: npcSchema },
        memories: { type: 'array', maxItems: 20, items: nonBlankString(400) },
        recentActions: { type: 'array', maxItems: 8, items: nonBlankString(2000) },
        campaignRevision: { type: 'integer', minimum: 0, maximum: 2147483647 },
        npcContexts: { type: 'array', maxItems: 3, items: npcIdentitySchema },
      } } }, preHandler: storyRateLimit,
  }, async (request, reply) => {
    // Reject ambiguous saved identifiers before making a potentially paid
    // provider call. A provider failure is 502; bad input is always 400.
    try { validateStoryTurnContext(request.body); validateNpcIdentityContext(request.body); }
    catch { return reply.code(400).send({ error: 'invalid_request', message: 'Die Kampagnendaten sind ungültig.' }); }
    if (!narrator.advanceStory) return reply.code(503).send({ error: 'story_unavailable' });
    try {
      // Never guess which same-name saved NPC a client-provided diary note
      // describes. Keep ordinary memories and the existing wire schema.
      const context: StoryTurnWithNpcIdentities = {
        ...request.body,
        memories: filterAmbiguousNpcDiaryMemories(request.body),
      };
      const proposed = await narrator.advanceStory(context);
      return {
        provider: config.provider,
        stateChanges: [],
        turn: guardStoryTurnSecrets(
          parseStoryTurn(proposed, context),
          context.secret,
        ),
      };
    }
    catch { return reply.code(502).send({ error: 'provider_unavailable' }); }
  });

  app.post<{ Body: NarrationInput }>('/v1/narrate', {
    schema: { body: narrationSchema },
    preHandler: async (request, reply) => {
      const token = bearerToken(request.headers.authorization);
      const session = token ? verifySession(token, config.sessionSecret, clock()) : undefined;
      if (!session) return reply.code(401).send({ error: 'invalid_session', message: 'Die Sitzung ist abgelaufen. Bitte verbinde dich erneut.' });
      const now = clock();
      if (!minuteLimiter.take(session.subject, now, 60000, config.requestsPerMinute)) {
        reply.header('Retry-After', '60');
        return reply.code(429).send({ error: 'rate_limit', message: 'Das Minutenlimit ist erreicht. Bitte warte kurz.' });
      }
      if (!dayLimiter.take(session.subject, now, 86400000, config.requestsPerDay)) {
        reply.header('Retry-After', '86400');
        return reply.code(429).send({ error: 'daily_limit', message: 'Das tägliche Anfragelimit ist erreicht.' });
      }
    },
  }, async (request, reply) => {
    try {
      return await narrator.narrate(request.body);
    } catch {
      // Provider errors can contain API keys, input and account details. Never forward them.
      return reply.code(502).send({ error: 'provider_unavailable', message: 'Der Spielleiterdienst ist vorübergehend nicht erreichbar. Nutze den lokalen Demo-Modus oder versuche es später erneut.' });
    }
  });
  return app;
}
