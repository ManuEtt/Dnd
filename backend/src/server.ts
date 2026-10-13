import Fastify from 'fastify';
import { localMockReply, parseMockTurn } from './guards.ts';

const app = Fastify({ logger: true, bodyLimit: 16 * 1024 });
app.get('/health', async () => ({ status: 'ok', mode: 'mock', version: '0.1.0' }));
app.post('/v1/mock-turn', async (request, reply) => {
  try {
    const payload = parseMockTurn(request.body);
    return { narratorText: localMockReply(payload), rulesMutation: false };
  } catch {
    return reply.status(400).send({ error: 'invalid_request' });
  }
});

// Local-only binding: this prototype must not be exposed as a public API.
const port = Number(process.env.PORT ?? 8787);
app.listen({ host: '127.0.0.1', port }).catch((error: unknown) => {
  app.log.error(error);
  process.exitCode = 1;
});
