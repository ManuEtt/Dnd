import { createHash, createHmac, randomUUID, timingSafeEqual } from 'node:crypto';

export interface SessionClaims {
  version: 1;
  audience: 'narration';
  subject: string;
  issuedAt: number;
  expiresAt: number;
  id: string;
}

export function secureEqual(left: string, right: string): boolean {
  const digest = (value: string) => createHash('sha256').update(value).digest();
  return timingSafeEqual(digest(left), digest(right));
}

function signature(payload: string, secret: string): string {
  return createHmac('sha256', secret).update(payload).digest('base64url');
}

export function issueSession(secret: string, subject: string, now: number, ttlSeconds: number) {
  const claims: SessionClaims = {
    version: 1,
    audience: 'narration',
    subject,
    issuedAt: Math.floor(now / 1000),
    expiresAt: Math.floor(now / 1000) + ttlSeconds,
    id: randomUUID(),
  };
  const payload = Buffer.from(JSON.stringify(claims)).toString('base64url');
  return { token: `${payload}.${signature(payload, secret)}`, claims };
}

export function verifySession(token: string, secret: string, now: number): SessionClaims | undefined {
  if (token.length > 2048 || !/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(token)) return undefined;
  const [payload, suppliedSignature] = token.split('.');
  if (!payload || !suppliedSignature || !secureEqual(signature(payload, secret), suppliedSignature)) return undefined;
  try {
    const parsed: unknown = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    if (!parsed || typeof parsed !== 'object') return undefined;
    const claims = parsed as Partial<SessionClaims>;
    const seconds = Math.floor(now / 1000);
    if (claims.version !== 1 || claims.audience !== 'narration' || claims.subject !== 'local-player' ||
      typeof claims.id !== 'string' || !Number.isSafeInteger(claims.issuedAt) || !Number.isSafeInteger(claims.expiresAt) ||
      !claims.issuedAt || !claims.expiresAt || claims.issuedAt > seconds || claims.expiresAt <= seconds ||
      claims.expiresAt - claims.issuedAt > 900) return undefined;
    return claims as SessionClaims;
  } catch {
    return undefined;
  }
}

export function bearerToken(header: string | undefined): string | undefined {
  const match = header?.match(/^Bearer ([A-Za-z0-9._-]+)$/);
  return match?.[1];
}
