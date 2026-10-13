export interface MockTurnRequest {
  hero: string;
  campaignId: string;
  input: string;
}

export function parseMockTurn(raw: unknown): MockTurnRequest {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new TypeError('Objekt erwartet');
  }
  const data = raw as Record<string, unknown>;
  for (const key of ['hero', 'campaignId', 'input'] as const) {
    if (typeof data[key] !== 'string' || !data[key].trim() || data[key].length > 2000) {
      throw new TypeError(`Ungültiges Feld: ${key}`);
    }
  }
  return {
    hero: (data.hero as string).trim(),
    campaignId: (data.campaignId as string).trim(),
    input: (data.input as string).trim(),
  };
}

export function localMockReply(payload: MockTurnRequest): string {
  const text = payload.input.toLocaleLowerCase('de-DE');
  if (text.includes('amulett')) {
    return `${payload.hero}, das Amulett pulsiert mit rotem Licht. Welche Spur möchtest du verfolgen?`;
  }
  if (text.includes('würfel')) {
    return `${payload.hero}, die Regelengine muss zuerst die Probe und ihre Modifikatoren bestimmen.`;
  }
  return `${payload.hero}, der Wind trägt ein Geheimnis durch Aetheria. Was tust du?`;
}
