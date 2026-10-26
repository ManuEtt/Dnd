import type { StoryTurnInput } from './story.js';

/**
 * Optional, client-asserted local NPC snapshot.
 *
 * The backend has no campaign database. Structural validation proves only
 * internal consistency, NOT that a client actually saved these notes or that
 * its declared revision is current. Never use this as a rule/state command.
 */
export interface StoryNpcIdentityNote {
  id: string;
  npcId: string;
  relationship: string;
  note: string;
  recordedAt: string;
}

export interface StoryNpcIdentityContext {
  campaignId: string;
  campaignRevision: number;
  npcId: string;
  npcName: string;
  alive: boolean;
  relationship: string;
  notes: StoryNpcIdentityNote[];
}

export interface StoryTurnWithNpcIdentities extends StoryTurnInput {
  campaignRevision?: number;
  npcContexts?: StoryNpcIdentityContext[];
}

const safeId = (value: unknown): value is string =>
  typeof value === 'string' && /^[a-zA-Z0-9_-]{1,64}$/.test(value);
const validText = (value: unknown, limit: number): value is string =>
  typeof value === 'string' &&
  value.length > 0 &&
  value.length <= limit &&
  value.trim().length > 0 &&
  !/[\x00-\x1f\x7f-\x9f\u2028\u2029]/u.test(value);
const validRevision = (value: unknown): value is number =>
  Number.isSafeInteger(value) && Number(value) >= 0 && Number(value) <= 2147483647;
const validTimestamp = (value: unknown): value is string => {
  if (typeof value !== 'string' ||
      !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,6})?Z$/u.test(value)) {
    return false;
  }
  const parsed = Date.parse(value);
  // Date.parse normalizes impossible dates (e.g. Feb 30) and 24:00 into
  // another calendar day. Such a rewritten NPC history is not accepted.
  return !Number.isNaN(parsed) &&
    new Date(parsed).toISOString().slice(0, 19) === value.slice(0, 19);
};

/**
 * Fail closed before invoking a paid provider. No silent truncation, remapping
 * of IDs by NPC name, revision coercion, or adoption of provider-written facts.
 * Legacy clients with neither optional field remain supported.
 */
export function validateNpcIdentityContext(input: StoryTurnWithNpcIdentities): void {
  const suppliedRevision = input.campaignRevision !== undefined;
  const suppliedContexts = input.npcContexts !== undefined;
  if (suppliedRevision !== suppliedContexts) {
    throw new Error('incomplete_npc_identity_context');
  }
  if (!suppliedRevision) return;
  if (!validRevision(input.campaignRevision) ||
      !Array.isArray(input.npcContexts) ||
      input.npcContexts.length > 3) {
    throw new Error('invalid_npc_identity_context');
  }

  const known = new Map<string, { id: string; name: string; relationship: string }>();
  for (const npc of input.npcs) {
    if (!safeId(npc.id) || known.has(npc.id)) {
      throw new Error('ambiguous_npc_identity_context');
    }
    known.set(npc.id, npc);
  }

  const usedNpcs = new Set<string>();
  const usedNotes = new Set<string>();
  for (const context of input.npcContexts) {
    if (!context ||
        context.campaignId !== input.campaignId ||
        context.campaignRevision !== input.campaignRevision ||
        !safeId(context.npcId) ||
        usedNpcs.has(context.npcId) ||
        !validText(context.npcName, 80) ||
        !validText(context.relationship, 80) ||
        typeof context.alive !== 'boolean' ||
        !Array.isArray(context.notes) ||
        context.notes.length > 5) {
      throw new Error('invalid_npc_identity_context');
    }
    usedNpcs.add(context.npcId);
    const npc = known.get(context.npcId);
    if (!npc ||
        npc.name !== context.npcName ||
        npc.relationship !== context.relationship) {
      throw new Error('mismatched_npc_identity_context');
    }
    let previousTimestamp = Number.POSITIVE_INFINITY;
    for (const note of context.notes) {
      if (!note ||
          !safeId(note.id) ||
          usedNotes.has(note.id) ||
          note.npcId !== context.npcId ||
          !validText(note.relationship, 80) ||
          !validText(note.note, 500) ||
          !validTimestamp(note.recordedAt)) {
        throw new Error('invalid_npc_identity_note');
      }
      usedNotes.add(note.id);
      const timestamp = Date.parse(note.recordedAt);
      if (timestamp > previousTimestamp) {
        throw new Error('unsorted_npc_identity_notes');
      }
      previousTimestamp = timestamp;
    }
  }
}
