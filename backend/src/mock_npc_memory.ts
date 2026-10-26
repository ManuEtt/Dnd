/**
 * A read-only hint for the *offline mock* narrator.
 *
 * The server cannot authenticate the provenance of client-supplied memories:
 * "Tagebuch" describes the submitted text, not a newly confirmed game fact.
 * No memory text can create NPC updates, quests or rule state.
 */
export interface MockNpcContext {
  action: string;
  npcs: Array<{ id: string; name: string; relationship: string }>;
  memories: string[];
}

const oneLine = (text: string): string =>
  text.replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/gu, ' ')
    .replace(/\s+/gu, ' ').trim();

const fold = (text: string): string =>
  oneLine(text).toLocaleLowerCase('de-DE')
    .replace(/ä/gu, 'ae').replace(/ö/gu, 'oe')
    .replace(/ü/gu, 'ue').replace(/ß/gu, 'ss');

const escapeRegex = (text: string): string =>
  text.replace(/[.*+?^$()|[\]{}\\]/gu, '\\$&');

const mentionsName = (action: string, name: string): boolean => {
  const folded = fold(name);
  if (!folded) return false;
  return new RegExp('(?:^|[^a-z0-9])' + escapeRegex(folded) +
    '(?=$|[^a-z0-9])', 'u').test(fold(action));
};

const shorten = (text: string, maxCodePoints: number): string => {
  const points = Array.from(text);
  return points.length <= maxCodePoints
    ? text
    : points.slice(0, maxCodePoints - 1).join('') + '…';
};

/**
 * Reads at most one note relevant to an explicitly mentioned, unambiguous NPC.
 * Rejects accidental substring matches and cross-NPC attribution. As with all
 * client memory strings, this may only enrich narration, not establish truth.
 */
export function mockNpcDiaryHint(input: MockNpcContext): string {
  const matchingNpcs = input.npcs.filter(npc => mentionsName(input.action, npc.name));
  const uniqueNames = matchingNpcs.filter(npc =>
    input.npcs.filter(other => fold(other.name) === fold(npc.name)).length === 1);
  const pattern = /^Bestätigte NPC-Beziehungsnotiz zu (.+?) \(([^()\r\n]+)\): (.+)$/u;

  for (const memory of input.memories) {
    const parsed = pattern.exec(oneLine(memory));
    if (!parsed) continue;
    const matching = uniqueNames.find(npc => fold(npc.name) === fold(parsed[1]!));
    if (!matching) continue;
    const note = oneLine(parsed[3]!);
    if (!note) continue;
    const excerpt = shorten(note, 160);
    const ending = /[.!?…]$/u.test(excerpt) ? ' ' : '. ';
    return 'Dein Tagebuch zu ' + oneLine(matching.name) +
      ' vermerkt: „' + excerpt + '“' + ending;
  }
  return '';
}
