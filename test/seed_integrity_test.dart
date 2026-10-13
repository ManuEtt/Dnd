import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arescan historical save remains non-authoritative', () async {
    final raw = await rootBundle.loadString('assets/arescan_save.json');
    final save = jsonDecode(raw) as Map<String, dynamic>;
    final character = save['character'] as Map<String, dynamic>;
    final campaign = save['campaign'] as Map<String, dynamic>;
    final history = List<String>.from(save['history'] as List);
    expect(character['name'], 'Arescan');
    expect(campaign['heroId'], character['id']);
    expect((character['abilities'] as Map<String, dynamic>).values.every((v) => v == null), isTrue);
    expect(history.join(' '), contains('19'));
    expect(history.join(' '), contains('14 TP'));
  });
}
