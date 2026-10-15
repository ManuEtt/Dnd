import 'models.dart';

/// Compact house-rule encounter templates. The optional AI supplies ONLY the
/// template identifier and fiction, never HP, AC, damage, XP or loot quantities.
class AdventureEnemy {
  const AdventureEnemy(this.name, this.hitPoints, this.armorClass,
      this.attackBonus, this.damage, this.loot, this.minimumLevel);
  final String name, damage, loot;
  final int hitPoints, armorClass, attackBonus, minimumLevel;
}

class AdventureCatalog {
  static const enemies = <String, AdventureEnemy>{
    'bandit': AdventureEnemy('Wegelagerer', 11, 12, 3, '1d6+1', 'Brief mit Siegel', 1),
    'wolf': AdventureEnemy('Wilder Wolf', 11, 13, 4, '2d4+2', 'Wolfsspur-Karte', 1),
    'skeleton': AdventureEnemy('Skelettwächter', 13, 13, 4, '1d6+2', 'Verwittertes Abzeichen', 1),
    'goblin': AdventureEnemy('Goblin-Späher', 7, 15, 4, '1d6+2', 'Späherkarte', 1),
    'orc': AdventureEnemy('Ork-Plünderer', 15, 13, 5, '1d12+3', 'Orkisches Feldzeichen', 2),
  };

  static AdventureEnemy forHero(String archetype, HeroCharacter hero) {
    final enemy = enemies[archetype];
    if (enemy == null || hero.level < enemy.minimumLevel || hero.level > 20) {
      throw const FormatException('Gegnerprofil ist für den Helden nicht freigegeben.');
    }
    return enemy;
  }
}
