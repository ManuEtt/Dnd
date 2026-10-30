import { randomBytes } from 'node:crypto';

export type AiProviderName = 'mock' | 'openai';
export interface Config {
  host: string;
  port: number;
  publicOrigin?: string;
  accessToken?: string;
  sessionSecret: string;
  sessionTtlSeconds: number;
  requestsPerMinute: number;
  requestsPerDay: number;
  provider: AiProviderName;
  openaiKey?: string;
  openaiModel?: string;
}

function integer(env: NodeJS.ProcessEnv, name: string, fallback: number, max: number): number {
  const value = env[name] === undefined || env[name] === '' ? fallback : Number(env[name]);
  if (!Number.isSafeInteger(value) || value < 1 || value > max) {
    throw new Error(`${name} muss eine ganze Zahl von 1 bis ${max} sein.`);
  }
  return value;
}

/** Fail closed: paid requests require a provider, explicit consent, key and model. */
export function readConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const host = env.HOST?.trim() || '127.0.0.1';
  const publicOrigin = env.PUBLIC_ORIGIN?.trim() || undefined;
  if (publicOrigin) {
    const origin = new URL(publicOrigin);
    if (origin.protocol !== 'https:' || origin.username || origin.password ||
        origin.pathname !== '/' || origin.search || origin.hash) {
      throw new Error('PUBLIC_ORIGIN muss ein reiner HTTPS-Ursprung ohne Zugangsdaten, Pfad, Query oder Fragment sein.');
    }
  }
  if (!['127.0.0.1', '::1', 'localhost'].includes(host) && !publicOrigin) {
    throw new Error('Remote-Betrieb benötigt PUBLIC_ORIGIN und einen HTTPS-Reverse-Proxy.');
  }
  const provider = env.AI_PROVIDER?.trim() || 'mock';
  if (provider !== 'mock' && provider !== 'openai') throw new Error('Ungültiger AI_PROVIDER.');
  const accessToken = env.LOCAL_ACCESS_TOKEN?.trim() || undefined;
  if (accessToken && accessToken.length < 32) throw new Error('LOCAL_ACCESS_TOKEN muss mindestens 32 Zeichen haben.');
  const sessionSecret = env.SESSION_SECRET?.trim() || randomBytes(32).toString('hex');
  if (sessionSecret.length < 32) throw new Error('SESSION_SECRET muss mindestens 32 Zeichen haben.');
  const openaiKey = env.OPENAI_API_KEY?.trim() || undefined;
  const openaiModel = env.OPENAI_MODEL?.trim() || undefined;
  if (provider === 'openai' && (env.ALLOW_PAID_AI !== 'true' || !openaiKey || !openaiModel)) {
    throw new Error('OpenAI benötigt ALLOW_PAID_AI=true, OPENAI_API_KEY und OPENAI_MODEL.');
  }
  return {
    host,
    port: integer(env, 'PORT', 3000, 65535),
    ...(publicOrigin ? { publicOrigin } : {}),
    ...(accessToken ? { accessToken } : {}),
    sessionSecret,
    sessionTtlSeconds: integer(env, 'SESSION_TTL_SECONDS', 300, 900),
    requestsPerMinute: integer(env, 'REQUESTS_PER_MINUTE', 15, 1000),
    requestsPerDay: integer(env, 'REQUESTS_PER_DAY', 100, 10000),
    provider,
    ...(openaiKey ? { openaiKey } : {}),
    ...(openaiModel ? { openaiModel } : {}),
  };
}
