import { execFileSync } from 'node:child_process';
import { test } from 'node:test';

test('temporary Dart formatter diagnostic for Chat B fixture', () => {
  const formatted = execFileSync(
    'dart',
    ['format', '--output=show', '../app/test/ai_story_zero_width_validation_test.dart'],
    { encoding: 'utf8' },
  );
  console.log('CHAT_B_DART_FORMAT_BEGIN\n' + formatted + '\nCHAT_B_DART_FORMAT_END');
});
