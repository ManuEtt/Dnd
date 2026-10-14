import 'dart:math' as math;

import 'rules_engine.dart';

/// D&D SRD 5.2.1, Character Creation: level-1 HP = the class Hit Die's
/// maximum + Constitution modifier. This is a proposal, never an automatic
/// change to an existing character's confirmed hit points.
/// Source: https://www.dndbeyond.com/srd
class StartingHitPoints {
  const StartingHitPoints._({
    required this.characterClass,
    required this.hitDie,
    required this.constitutionModifier,
  });

  final String characterClass;
  final int hitDie;
  final int constitutionModifier;

  /// The character must have at least one hit point at level 1.
  int get maximum => math.max(1, hitDie + constitutionModifier);

  static StartingHitPoints propose({
    required String className,
    required int? constitutionScore,
    required int? characterLevel,
  }) {
    if (characterLevel != 1) {
      throw const FormatException(
        'Start-Trefferpunkte werden nur für Charaktere der Stufe 1 vorgeschlagen.',
      );
    }
    if (constitutionScore == null) {
      throw const FormatException(
        'Bestätige zuerst den Konstitutionswert des Charakters.',
      );
    }
    final modifier = RulesEngine.abilityModifier(constitutionScore);
    final hitDie = _hitDie(className);
    if (hitDie == null) {
      throw FormatException(
        'Die Klasse „$className“ ist keinem SRD-5.2.1-Trefferwürfel zugeordnet. '
        'Wähle eine unterstützte Klasse; vorhandene Werte bleiben unverändert.',
      );
    }
    return StartingHitPoints._(
      characterClass: className.trim(),
      hitDie: hitDie,
      constitutionModifier: modifier,
    );
  }

  static int? _hitDie(String source) {
    final name = source.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return switch (name) {
      'barbar' || 'barbarin' || 'barbarian' => 12,
      'kämpfer' || 'kämpferin' || 'kaempfer' || 'fighter' ||
      'paladin' || 'waldläufer' || 'waldläuferin' || 'waldlaeufer' ||
      'ranger' => 10,
      'barde' || 'bardin' || 'bard' || 'kleriker' || 'klerikerin' ||
      'cleric' || 'druide' || 'druidin' || 'druid' || 'mönch' ||
      'mönchin' || 'moench' || 'monk' || 'schurke' || 'schurkin' ||
      'rogue' || 'hexenmeister' || 'hexenmeisterin' || 'warlock' => 8,
      'zauberer' || 'zauberin' || 'sorcerer' || 'magier' ||
      'magierin' || 'wizard' => 6,
      _ => null,
    };
  }
}
