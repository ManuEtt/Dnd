import { mockNpcDiaryHint } from './mock_npc_memory.js';
import { mockNpcIdentityHint } from './mock_npc_identity_hint.js';
import type { StoryTurnWithNpcIdentities } from './story_npc_identity_context.js';

/** A provider proposes fiction only. All returned values are validated before being sent to a client. */
export interface StoryStartInput {
  heroName: string;
  heroClass: string;
  theme: string;
}
export interface StoryThreadInput { id: string; title: string; description: string; status: string }
export interface StoryNpcInput { id: string; name: string; relationship: string }
export interface StoryTurnInput {
  campaignId: string;
  heroName: string;
  action: string;
  scene: string;
  premise: string;
  goal: string;
  secret: string;
  threads: StoryThreadInput[];
  npcs: StoryNpcInput[];
  memories: string[];
  recentActions: string[];
}
export interface StoryThreadDraft { id: string; title: string; description: string }
export interface StoryNpcDraft { id: string; name: string; description: string; relationship: string }
export interface StoryPlaceDraft { id: string; name: string; description: string }
export interface StoryPlan {
  title: string;
  world: string;
  opening: string;
  premise: string;
  secret: string;
  goal: string;
  threads: StoryThreadDraft[];
  npcs: StoryNpcDraft[];
  places: StoryPlaceDraft[];
}
export interface AdventureDraft {
  id: string; title: string; description: string; archetype: string;
  questTitle: string; questDescription: string;
}
export interface StoryTurn {
  narration: string;
  adventure: AdventureDraft | null;
  threadUpdates: Array<{ id: string; status: 'open' | 'resolved' | 'abandoned'; description: string }>;
  newThreads: StoryThreadDraft[];
  npcUpdates: Array<{ id: string; relationship: string; note: string }>;
}
const object = (value: unknown): Record<string, unknown> => {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('invalid_story');
  return value as Record<string, unknown>;
};
// Mirror Flutter's story parser: preserve legitimate prose while rejecting
// invisible control characters and bidirectional text spoofing from providers.
const unsafeStoryFormatting = /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f\u061c\u200b\u200e\u200f\u2028-\u202e\u2060\u2066-\u2069\ufeff]/u;
const string = (value: unknown, max: number): string => {
  if (typeof value !== 'string' || !value.trim() || value.length > max ||
      unsafeStoryFormatting.test(value)) throw new Error('invalid_story');
  return value.trim();
};
const id = (value: unknown): string => {
  const result = string(value, 64);
  if (!/^[a-z][a-z0-9_-]{0,63}$/.test(result)) throw new Error('invalid_story');
  return result;
};
const list = <T>(value: unknown, max: number, fn: (item: unknown) => T): T[] => {
  if (!Array.isArray(value) || value.length > max) throw new Error('invalid_story');
  return value.map(fn);
};
const unique = (ids: string[]) => {
  if (new Set(ids).size !== ids.length) throw new Error('duplicate_story_id');
};
const thread = (item: unknown): StoryThreadDraft => {
  const o = object(item);
  return { id: id(o.id), title: string(o.title, 120), description: string(o.description, 1000) };
};
export function parseStoryPlan(raw: unknown): StoryPlan {
  const o = object(raw);
  const threads = list(o.threads, 4, thread);
  const npcs = list(o.npcs, 4, (raw): StoryNpcDraft => {
    const n = object(raw);
    return { id: id(n.id), name: string(n.name, 80), description: string(n.description, 500), relationship: string(n.relationship, 80) };
  });
  const places = list(o.places, 4, (raw): StoryPlaceDraft => {
    const n = object(raw);
    return { id: id(n.id), name: string(n.name, 80), description: string(n.description, 500) };
  });
  if (threads.length < 2 || npcs.length < 1 || places.length < 1) throw new Error('incomplete_story');
  unique(threads.map(x => x.id)); unique(npcs.map(x => x.id)); unique(places.map(x => x.id));
  return {
    title: string(o.title, 120), world: string(o.world, 120), opening: string(o.opening, 2500),
    premise: string(o.premise, 1000), secret: string(o.secret, 1000), goal: string(o.goal, 500),
    threads, npcs, places,
  };
}
const allowedArchetypes = ['bandit', 'wolf', 'skeleton', 'goblin', 'orc', 'investigation'];
export function parseAdventureDraft(raw: unknown): AdventureDraft {
  const o = object(raw);
  const archetype = string(o.archetype, 32);
  if (!allowedArchetypes.includes(archetype)) throw new Error('unknown_adventure_archetype');
  return { id: id(o.id), title: string(o.title, 120),
    description: string(o.description, 500), archetype,
    questTitle: string(o.questTitle, 120),
    questDescription: string(o.questDescription, 500) };
}

/**
 * Untrusted requests cannot provide two conflicting versions of the same
 * saved thread or NPC. Validate this before invoking a paid storyteller,
 * and again when parsing any provider output outside the HTTP endpoint.
 */
export function validateStoryTurnContext(input: StoryTurnInput): void {
  unique(input.threads.map(thread => thread.id));
  unique(input.npcs.map(npc => npc.id));
}

export function parseStoryTurn(raw: unknown, input: StoryTurnInput): StoryTurn {
  validateStoryTurnContext(input);
  const o = object(raw);
  const knownThreads = new Map(input.threads.map(x => [x.id, x]));
  const knownNpcs = new Set(input.npcs.map(x => x.id));
  const threadUpdates = list(o.threadUpdates, 6, (raw) => {
    const item = object(raw);
    const target = id(item.id);
    const status = string(item.status, 16);
    if (!knownThreads.has(target) || !['open', 'resolved', 'abandoned'].includes(status)) throw new Error('unknown_story_thread');
    // A closed lead is confirmed player history, including its description.
    // Only explicit local edits may reopen or rewrite it.
    const previous = knownThreads.get(target)!;
    const description = string(item.description, 1000);
    if (previous.status !== 'open' &&
        (status !== previous.status || description !== previous.description)) {
      throw new Error('closed_story_thread');
    }
    return { id: target, status: status as 'open' | 'resolved' | 'abandoned', description };
  });
  const newThreads = list(o.newThreads, 2, thread);
  const npcUpdates = list(o.npcUpdates, 4, (raw) => {
    const item = object(raw);
    const target = id(item.id);
    if (!knownNpcs.has(target)) throw new Error('unknown_story_npc');
    return { id: target, relationship: string(item.relationship, 80), note: string(item.note, 500) };
  });
  unique(threadUpdates.map(x => x.id)); unique(newThreads.map(x => x.id)); unique(npcUpdates.map(x => x.id));
  if (newThreads.some(x => knownThreads.has(x.id)) || input.threads.length + newThreads.length > 100) throw new Error('story_thread_collision');
  const adventure = o.adventure == null ? null : parseAdventureDraft(o.adventure);
  return { narration: string(o.narration, 4000), threadUpdates, newThreads, npcUpdates, adventure };
}

/** Offline mock is deterministic and explicitly not a generative AI. */
export function mockStoryPlan(input: StoryStartInput): StoryPlan {
  const theme = input.theme.trim() || 'ein rätselhafter Neubeginn';
  return parseStoryPlan({
    title: 'Das Vermächtnis der Nebelkrone', world: 'Veyr',
    opening: `${input.heroName}, vor den Toren der Hafenstadt Eiren fällt ein schwarzer Stern ins Meer. Eine Kartografin bittet dich um Hilfe. Was tust du?`,
    premise: `Eine uralte Karte führt durch einen Konflikt um ${theme}.`, secret: 'Die Nebelkrone ist kein Gegenstand, sondern ein gebrochener Schwur.',
    goal: 'Entdecke den Ursprung der Nebelkrone und entscheide selbst über das Schicksal der Küste.',
    threads: [
      { id: 'sternenspur', title: 'Die Spur des schwarzen Sterns', description: 'Untersuche, warum der Stern in die Bucht fiel.' },
      { id: 'kartografen', title: 'Der geheime Atlas', description: 'Finde heraus, wem die Kartografin vertraut.' },
    ],
    npcs: [{ id: 'seli', name: 'Seli', description: 'Kartografin mit verborgenen Motiven.', relationship: 'vorsichtig' }],
    places: [{ id: 'eiren', name: 'Eiren', description: 'Nebelverhangene Hafenstadt.' }],
  });
}
export function mockStoryTurn(input: StoryTurnWithNpcIdentities): StoryTurn {
  // Journal threads may have no description. Do not turn that valid local
  // state into an invalid provider update or invent a replacement note.
  const first = input.threads.find(x => x.status === 'open' && x.description.trim());
  return parseStoryTurn({
    narration: `${input.heroName}, deine Entscheidung „${input.action.slice(0, 110)}“ bleibt nicht unbemerkt. In ${input.scene.slice(0, 140)} zeichnet sich eine neue Spur ab. ${mockNpcIdentityHint(input) || mockNpcDiaryHint(input)}Was möchtest du als Nächstes tun?`,
    threadUpdates: first ? [{ id: first.id, status: 'open', description: first.description }] : [],
    newThreads: [], npcUpdates: [],
    adventure: /gefahr|hinterhalt|begegnung|gegner|kampf|spur|untersuch|geheimnis/i.test(input.action)
      ? /spur|untersuch|geheimnis/i.test(input.action)
        ? { id: `spur_${Math.max(1, input.recentActions.length + 1)}`,
            title: 'Die verlorenen Zeichen',
            description: 'Ein verwitterter Stein birgt Hinweise auf eine verborgene Route.',
            archetype: 'investigation', questTitle: 'Entziffere die Zeichen',
            questDescription: 'Untersuche die Spuren mit einer bestätigten Wahrnehmungsprobe.' }
        : { id: `mission_${Math.max(1, input.recentActions.length + 1)}`,
            title: 'Der Späher am Nebelpfad',
            description: 'Ein Wegelagerer versperrt die Passage zum Küstenpfad.',
            archetype: 'bandit', questTitle: 'Sichere den Nebelpfad',
            questDescription: 'Überwinde den Wegelagerer und sichere die Passage.' }
      : null,
  }, input);
}
