import 'rules_engine.dart';

/// Starting combat values from explicit SRD 5.2.1 species and ability data.
/// These are proposals, not guesses for historical/custom characters.
class SrdStartingCombatValues {
  const SrdStartingCombatValues._();

  /// Exact SRD walking speed in tenths of a meter; 1 foot = 0.3 meters.
  /// Goliaths and explicitly chosen Wood Elves have 35 ft = 10.5 m.
  static int? speedDecimeters(String species) {
    final name = species.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    const thirtyFoot = {
      'mensch',
      'human',
      'zwerg',
      'dwarf',
      'elf',
      'elfe',
      'elfin',
      'elfer',
      'gnom',
      'gnome',
      'halbling',
      'halfling',
      'drachenblütiger',
      'drachenblütige',
      'drachenblut',
      'dragonborn',
      'orc',
      'ork',
      'tiefling',
    };
    if (thirtyFoot.contains(name)) return 90;
    if (const {'goliath', 'waldelf', 'waldelfe', 'wood elf'}.contains(name)) {
      return 105;
    }
    return null; // Unspecified/custom species: do not invent its Speed.
  }

  /// Only a non-armored confirmed Dexterity (and relevant class abilities)
  /// supplies a safe default AC. Armor and shield require an equipment choice.
  static int? unarmoredArmorClass({
    required String className,
    required int? dexterity,
    int? constitution,
    int? wisdom,
  }) {
    if (dexterity == null || dexterity < 1 || dexterity > 30) return null;
    final dexMod = RulesEngine.abilityModifier(dexterity);
    switch (className.trim().toLowerCase()) {
      case 'barbar':
      case 'barbarin':
      case 'barbarian':
        if (constitution == null || constitution < 1 || constitution > 30) {
          return null;
        }
        return 10 + dexMod + RulesEngine.abilityModifier(constitution);
      case 'mönch':
      case 'mönchin':
      case 'moench':
      case 'monk':
        if (wisdom == null || wisdom < 1 || wisdom > 30) return null;
        return 10 + dexMod + RulesEngine.abilityModifier(wisdom);
      default:
        return 10 + dexMod;
    }
  }

  static String formatSpeedDecimeters(int dm) {
    if (dm < 0 || dm % 5 != 0) {
      throw const FormatException('Bewegung in 0,5-Meter-Schritten eingeben.');
    }
    final whole = dm ~/ 10;
    return dm % 10 == 0 ? '$whole' : '$whole,5';
  }

  static int parseSpeedDecimeters(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(?:\.[05])?$').hasMatch(trimmed)) {
      throw const FormatException(
        'Bewegung als ganze oder halbe Meter eingeben (z. B. 9 oder 10,5).',
      );
    }
    final parts = trimmed.split('.');
    final whole = int.parse(parts[0]);
    final dm = whole * 10 + (parts.length == 2 && parts[1] == '5' ? 5 : 0);
    if (dm < 10 || dm > 2000) {
      throw const FormatException('Bewegung muss 1 bis 200 Meter betragen.');
    }
    return dm;
  }
}
