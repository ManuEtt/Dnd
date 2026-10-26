/**
 * Rejects ambiguous NPC diary labels before a text provider sees them.
 *
 * A "confirmed" prefix is still client input, NOT server authentication.
 * This is a defensive attribution guard, not proof that a note is true.
 * The existing transport cannot disambiguate same-name NPCs by ID, so those
 * marked notes are omitted rather than guessed or attached to the wrong NPC.
 */
export interface NpcMemoryContext {
  npcs: ReadonlyArray<{ id: string; name: string }>;
  memories: ReadonlyArray<string>;
}

const diaryPrefix = 'Bestätigte NPC-Beziehungsnotiz zu ';
const diaryPattern =
  /^Bestätigte NPC-Beziehungsnotiz zu (.+?) \(([^()\r\n]+)\): ([^\r\n]+)$/u;

const fold = (value: string): string =>
  value.normalize('NFC').trim().toLocaleLowerCase('de-DE')
    .replace(/ä/gu, 'ae').replace(/ö/gu, 'oe')
    .replace(/ü/gu, 'ue').replace(/ß/gu, 'ss')
    .replace(/\s+/gu, ' ');

/**
 * Pure, order-preserving filtering for the story narration input.
 *
 * Unmarked general memories keep their existing behavior. Marked NPC notes
 * survive only when their displayed NPC name belongs to exactly one saved
 * NPC with an ID. No new facts, IDs or mechanical updates are generated.
 */
export function filterAmbiguousNpcDiaryMemories(input: NpcMemoryContext): string[] {
  const nameCounts = new Map<string, number>();
  for (const npc of input.npcs) {
    const key = fold(npc.name);
    if (!npc.id.trim() || !key) continue;
    nameCounts.set(key, (nameCounts.get(key) ?? 0) + 1);
  }

  const result: string[] = [];
  for (const entry of input.memories) {
    if (!fold(entry).startsWith(fold(diaryPrefix))) {
      result.push(entry);
      continue;
    }

    const match = diaryPattern.exec(entry.trim());
    if (!match) continue;
    const name = fold(match[1]!);
    const relationship = match[2]!.trim();
    const note = match[3]!.trim();
    if (!name || !relationship || !note || nameCounts.get(name) !== 1) continue;
    result.push(entry);
  }
  return result;
}
