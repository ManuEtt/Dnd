import type { StoryPlan, StoryTurn } from './story.js';

/**
 * Blocks verbatim spoilers in player-visible story fields, including simple
 * Unicode/case/whitespace variations. This is not semantic spoiler detection:
 * paraphrases require a separate, explicit reveal policy in the local app.
 */
const normalize = (value: string): string =>
  value.normalize('NFKC')
    // Unicode format/variation controls are invisible to players, but would
    // otherwise split an exact plot secret and bypass whole-secret matching.
    .replace(/\p{Default_Ignorable_Code_Point}/gu, '')
    .replace(/\s+/g, ' ').trim().toLocaleLowerCase('de-DE');

function containsWholeSecret(text: string, secret: string): boolean {
  const needle = normalize(secret);
  if (!needle) return false;
  const escaped = needle.replace(/[.*+?^$()|[\]{}\\]/g, '\\$&');
  const pattern = new RegExp('(^|[^\\p{L}\\p{N}])' + escaped + '($|[^\\p{L}\\p{N}])', 'u');
  return pattern.test(normalize(text));
}

function rejectPublicSpoilers(secret: string, visible: string[]): void {
  if (visible.some(text => containsWholeSecret(text, secret))) {
    throw new Error('story_secret_exposed');
  }
}

/** A plan's secret is private GM context; its other fields are player-facing. */
export function guardStoryPlanSecrets(plan: StoryPlan): StoryPlan {
  rejectPublicSpoilers(plan.secret, [
    plan.title, plan.world, plan.opening, plan.premise, plan.goal,
    ...plan.threads.flatMap(t => [t.title, t.description]),
    ...plan.npcs.flatMap(n => [n.name, n.description, n.relationship]),
    ...plan.places.flatMap(p => [p.name, p.description]),
  ]);
  return plan;
}

/** No automatic story turn is authorized to disclose the saved plot secret. */
export function guardStoryTurnSecrets(turn: StoryTurn, secret: string): StoryTurn {
  rejectPublicSpoilers(secret, [
    turn.narration,
    ...turn.threadUpdates.map(t => t.description),
    ...turn.newThreads.flatMap(t => [t.title, t.description]),
    ...turn.npcUpdates.flatMap(n => [n.relationship, n.note]),
    ...(turn.adventure == null ? [] : [
      turn.adventure.title, turn.adventure.description,
      turn.adventure.questTitle, turn.adventure.questDescription,
    ]),
  ]);
  return turn;
}
