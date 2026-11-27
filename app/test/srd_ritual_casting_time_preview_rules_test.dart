import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_ritual_casting_time_preview_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

SrdSpellDefinition spell({
  String time = '10 minutes or Ritual',
  bool ritual = true,
}) => SrdSpellDefinition(
  id: 'test-ritual-time',
  name: 'Test Ritual',
  level: 1,
  school: 'Divination',
  classes: const ['Magier'],
  castingTime: time,
  range: 'Self',
  components: 'V',
  duration: 'Instantaneous',
  verbal: true,
  somatic: false,
  material: false,
  concentration: false,
  ritual: ritual,
);

void main() {
  test('extended ritual adds ten minutes to ordinary casting time', () {
    final result = SrdRitualCastingTimeRules.preview(
      spell(),
      ritualCastingAuthorizedConfirmed: true,
    );
    expect(result.ordinaryMinutes, 10);
    expect(result.additionalMinutes, 10);
    expect(result.totalMinutes, 20);
  });

  test('action ritual does not invent an exact minute total', () {
    final result = SrdRitualCastingTimeRules.preview(
      spell(time: 'Action or Ritual'),
      ritualCastingAuthorizedConfirmed: true,
    );
    expect(result.ordinaryMinutes, isNull);
    expect(result.additionalMinutes, 10);
    expect(result.totalMinutes, isNull);
  });

  test('one hour ritual requires seventy minutes', () {
    final result = SrdRitualCastingTimeRules.preview(
      spell(time: '1 hour or Ritual'),
      ritualCastingAuthorizedConfirmed: true,
    );
    expect(result.totalMinutes, 70);
  });

  test('missing authorization or ritual option fails closed', () {
    expect(
      () => SrdRitualCastingTimeRules.preview(
        spell(),
        ritualCastingAuthorizedConfirmed: false,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SrdRitualCastingTimeRules.preview(
        spell(time: 'Action', ritual: false),
        ritualCastingAuthorizedConfirmed: true,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('contradictory casting-time metadata is rejected', () {
    expect(
      () => SrdRitualCastingTimeRules.preview(
        spell(time: 'Action', ritual: true),
        ritualCastingAuthorizedConfirmed: true,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
