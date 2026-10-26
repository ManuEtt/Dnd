import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

Map<String, dynamic> _entry({
  required String components,
  required bool material,
}) {
  return {
    'id': 'component-metadata-test',
    'name': 'Component Test',
    'level': 1,
    'school': 'Evocation',
    'classes': ['Wizard'],
    'casting_time': 'Action',
    'range': '120 feet',
    'components': components,
    'duration': 'Instantaneous',
    'verbal': true,
    'somatic': true,
    'material': material,
    'concentration': false,
    'ritual': false,
  };
}

void main() {
  test('valid verbal somatic and material components are accepted', () {
    final simple = SrdSpellDefinition.fromJson(
      _entry(components: 'V, S', material: false),
    );
    expect(simple.material, isFalse);
    expect(simple.components, 'V, S');

    final supplied = SrdSpellDefinition.fromJson(
      _entry(components: 'V, S, M (a pinch of ash)', material: true),
    );
    expect(supplied.material, isTrue);
    expect(supplied.components, 'V, S, M (a pinch of ash)');
  });

  test('duplicate unknown and reordered component symbols are rejected', () {
    for (final invalid in [
      'V, S, X',
      'V, V, S',
      'V,, S',
      'V, S, S',
      'S, V',
      'V, S (unexpected details)',
      'V, S\nM',
    ]) {
      expect(
        () => SrdSpellDefinition.fromJson(
          _entry(components: invalid, material: false),
        ),
        throwsFormatException,
        reason: invalid,
      );
    }
  });

  test('material components require one clear nonempty description', () {
    for (final invalid in [
      'V, S, M',
      'V, S, M ()',
      'V, S, M (ash) (other)',
      'V, S, M, M (ash)',
      'V, S, M (ash)\nX',
    ]) {
      expect(
        () => SrdSpellDefinition.fromJson(
          _entry(components: invalid, material: true),
        ),
        throwsFormatException,
        reason: invalid,
      );
    }
  });
}
