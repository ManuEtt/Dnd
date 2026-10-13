import assert from 'node:assert/strict';
import { test } from 'node:test';
import { localMockReply, parseMockTurn } from '../src/guards.ts';

test('accepts a well-formed turn', () => {
  assert.deepEqual(parseMockTurn({ hero: 'Arescan', campaignId: 'heart-eternity', input: 'Amulett untersuchen' }), {
    hero: 'Arescan', campaignId: 'heart-eternity', input: 'Amulett untersuchen',
  });
});

test('rejects missing and empty fields', () => {
  for (const value of [null, {}, { hero: '', campaignId: 'x', input: 'Hallo' },
    { hero: 'A', campaignId: 'x', input: ' ' },
    { hero: 'A', campaignId: 'x', input: 'x'.repeat(2001) }]) {
    assert.throws(() => parseMockTurn(value), TypeError);
  }
});

test('mock reply stays non-authoritative', () => {
  const text = localMockReply(parseMockTurn({ hero: 'Arescan', campaignId: 'heart-eternity', input: 'Amulett' }));
  assert.match(text, /Arescan/);
  assert.match(text, /Amulett/);
  assert.doesNotMatch(text, /verlierst 10 Trefferpunkte/);
});
