import type { StoryTurnWithNpcIdentities } from './story_npc_identity_context.js';
import { validateNpcIdentityContext } from './story_npc_identity_context.js';

/**
 * A narrative hint from a *client-provided* ID-bound NPC snapshot.
 *
 * The backend cannot authenticate the client's saved game state. The snapshot
 * is therefore dialogue context only, never authorization for NPC updates,
 * quests, combat or resources.
 */
const fold = (text: string): string => text.normalize('NFC')
  .trim().toLocaleLowerCase('de-DE')
  .replace(/ä/gu, 'ae').replace(/ö/gu, 'oe')
  .replace(/ü/gu, 'ue').replace(/ß/gu, 'ss')
  .replace(/\s+/gu, ' ');

const oneLine = (text: string): string =>
  text.replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/gu, ' ')
    .replace(/\s+/gu, ' ').trim();

const shorten = (text: string, limit: number): string => {
  const points = Array.from(oneLine(text));
  return points.length <= limit
    ? points.join('')
    : points.slice(0, limit - 1).join('') + '…';
};

const mentionsName = (action: string, name: string): boolean => {
  const normalized = fold(name);
  if (!normalized) return false;
  const escaped = normalized.split('').map(char =>
    /[a-z0-9 ]/u.test(char) ? char : '\\u{' + char.codePointAt(0)!.toString(16) + '}').join('');
  return new RegExp('(?:^|[^a-z0-9])' + escaped +
    '(?=$|[^a-z0-9])', 'u').test(fold(action));
};

/**
 * Prefer newest ID-owned note when one unambiguously mentioned NPC exists.
 * Empty or malformed optional contexts are ignored; the legacy mock path can
 * then operate unchanged. Identical display names are deliberately refused
 * until the player action carries an explicit selected identity.
 */
export function mockNpcIdentityHint(input: StoryTurnWithNpcIdentities): string {
  if (input.campaignRevision === undefined || !input.npcContexts?.length) {
    return '';
  }
  try {
    validateNpcIdentityContext(input);
  } catch {
    return '';
  }

  const eligible = input.npcContexts.filter(context =>
    context.notes.length > 0 &&
    mentionsName(input.action, context.npcName) &&
    input.npcs.filter(npc => fold(npc.name) === fold(context.npcName)).length === 1,
  );
  if (eligible.length !== 1) return '';

  const npc = eligible[0]!;
  const excerpt = shorten(npc.notes[0]!.note, 160);
  if (!excerpt) return '';
  const ending = /[.!?…]$/u.test(excerpt) ? ' ' : '. ';
  return 'Dein Tagebuch zu ' + oneLine(npc.npcName) +
    ' vermerkt: „' + excerpt + '“' + ending;
}
