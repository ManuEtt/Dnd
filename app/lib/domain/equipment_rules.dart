import 'models.dart';
import 'rules_engine.dart';
import 'srd_equipment_catalog.dart';
import 'fighter_style_combat_rules.dart';

/// One explicitly selected, catalog-backed loadout. All ids refer to inventory
/// *instances*, not catalog definitions, so duplicate items remain distinct.
class EquipmentSelection {
  const EquipmentSelection({
    this.armorId = '',
    this.shieldId = '',
    this.weaponId = '',
    this.armorTrained = false,
    this.shieldTrained = false,
    this.weaponProficient = false,
    this.preferDexterity = false,
    this.twoHands = false,
    this.thrown = false,
  });
  final String armorId, shieldId, weaponId;
  final bool armorTrained, shieldTrained, weaponProficient;
  final bool preferDexterity, twoHands, thrown;
}

/// Pure preview: no gold, inventory, hit points, or conditions are changed.
class EquipmentRulePreview {
  const EquipmentRulePreview({
    required this.selection,
    required this.sourceHeroId,
    required this.sourceArmorClass,
    required this.sourceWeaponDamage,
    required this.sourceWeaponAbility,
    required this.sourceWeaponProficient,
    this.armorClass,
    this.weaponDamage,
    this.weaponAbility,
    this.attackBonus,
    this.damageModifier,
    this.speedPenaltyFeet = 0,
    this.stealthDisadvantage = false,
    this.armorUntrained = false,
    this.heavyAttackDisadvantage = false,
    this.needsAmmunition = false,
    this.rangeNormal,
    this.rangeLong,
    this.warnings = const [],
  });
  final EquipmentSelection selection;
  final String sourceHeroId, sourceWeaponDamage, sourceWeaponAbility;
  final bool sourceWeaponProficient;
  final int? sourceArmorClass;
  final int? armorClass, attackBonus, damageModifier;
  final String? weaponDamage, weaponAbility;
  final int speedPenaltyFeet;
  final bool stealthDisadvantage,
      armorUntrained,
      heavyAttackDisadvantage,
      needsAmmunition;
  final int? rangeNormal, rangeLong;
  final List<String> warnings;
}

/// SRD 5.2.1 equipment mechanics. Magic effects and alternate unarmored AC
/// features are intentionally outside this narrowly scoped rule module.
class EquipmentRules {
  const EquipmentRules._();

  static EquipmentEntry? _owned(HeroCharacter hero, String id) {
    if (id.isEmpty) return null;
    final matches = hero.inventory.where((e) => e.id == id).toList();
    if (matches.length != 1 || matches.single.quantity < 1) {
      throw StateError('Ausrüstung fehlt oder ist nicht eindeutig.');
    }
    final item = SrdEquipmentCatalog.byId(matches.single.catalogId);
    if (item == null) {
      throw StateError(
        'Nur bestätigte SRD-Katalogeinträge können angelegt werden.',
      );
    }
    return item;
  }

  static EquipmentRulePreview preview(
    HeroCharacter hero,
    EquipmentSelection s,
  ) {
    if (s.armorId.isEmpty && s.shieldId.isEmpty && s.weaponId.isEmpty) {
      throw StateError('Bitte zuerst einen Inventargegenstand auswählen.');
    }
    final ids = [
      s.armorId,
      s.shieldId,
      s.weaponId,
    ].where((e) => e.isNotEmpty).toList();
    if (ids.toSet().length != ids.length) {
      throw StateError(
        'Ein Gegenstand darf nur einen Ausrüstungsplatz belegen.',
      );
    }
    final armor = _owned(hero, s.armorId);
    final shield = _owned(hero, s.shieldId);
    final weapon = _owned(hero, s.weaponId);
    if (armor != null && !armor.isArmor ||
        shield != null && !shield.isShield ||
        weapon != null && !weapon.isWeapon) {
      throw StateError('Der Gegenstand passt nicht zum ausgewählten Platz.');
    }
    if (s.armorTrained && armor == null || s.shieldTrained && shield == null) {
      throw StateError(
        'Übung setzt eine ausgerüstete Rüstung bzw. einen Schild voraus.',
      );
    }
    if (weapon == null &&
        (s.twoHands || s.preferDexterity || s.thrown || s.weaponProficient)) {
      throw StateError(
        'Waffeneigenschaften benötigen eine ausgerüstete Waffe.',
      );
    }
    if (weapon != null) {
      if (s.preferDexterity && !weapon.hasProperty('finesse')) {
        throw StateError('Geschicklichkeit ist hier keine Finesse-Wahl.');
      }
      if (s.thrown && !weapon.hasProperty('thrown')) {
        throw StateError('Diese Waffe kann nicht geworfen werden.');
      }
      if (s.twoHands &&
          !weapon.hasProperty('versatile') &&
          !weapon.hasProperty('two-handed')) {
        throw StateError('Diese Waffe wird nicht zweihändig geführt.');
      }
      if (shield != null && (s.twoHands || weapon.hasProperty('two-handed'))) {
        throw StateError(
          'Schild und zweihändig geführte Waffe belegen zu viele Hände.',
        );
      }
    }
    final warnings = <String>[];
    int? ac;
    var penalty = 0;
    var stealth = false;
    if (armor != null || shield != null) {
      final dex = hero.abilities['dexterity'];
      if ((armor == null || armor.category != EquipmentCategory.heavyArmor) &&
          dex == null) {
        throw StateError(
          'Geschicklichkeit muss für die Rüstungsklasse bestätigt sein.',
        );
      }
      final dexBonus = dex == null ? null : RulesEngine.abilityModifier(dex);
      ac = armor == null ? 10 + dexBonus! : armor.armorClassWithDex(dexBonus);
      if (shield != null && s.shieldTrained) ac = ac! + shield.armorBaseAc!;
      ac = ac! + FighterStyleCombatRules.defenseBonus(hero, armor);
      if (armor != null && armor.strengthMin != null) {
        final str = hero.abilities['strength'];
        if (str == null) {
          throw StateError('Stärke für die Rüstungsvoraussetzung fehlt.');
        }
        if (str < armor.strengthMin!) penalty = 10;
      }
      stealth = armor?.stealthDisadvantage ?? false;
      if (armor == null) {
        warnings.add(
          'Grund-RK 10 + GE benutzt; Klassenmerkmale mit abweichender RK bitte separat prüfen.',
        );
      }
      if (shield != null && !s.shieldTrained) {
        warnings.add('Ohne Schildübung wird kein RK-Bonus gewährt.');
      }
    }
    final untrained = armor != null && !s.armorTrained;
    if (untrained) {
      warnings.add(
        'Ohne Rüstungsübung: Nachteil auf ST-/GE-W20-Tests und keine Zauberwirkung möglich.',
      );
    }
    if (penalty != 0) {
      warnings.add('Bewegungsrate: -10 Fuß wegen fehlender Stärke.');
    }
    if (stealth) warnings.add('Heimlichkeitsproben mit Nachteil.');
    String? damage;
    String? ability;
    int? atk;
    int? damageMod;
    var heavyDisadvantage = false;
    if (weapon != null) {
      final ranged = const [
        EquipmentCategory.simpleRanged,
        EquipmentCategory.martialRanged,
      ].contains(weapon.category);
      ability = ranged && !s.thrown
          ? 'dexterity'
          : (s.preferDexterity ? 'dexterity' : 'strength');
      final score = hero.abilities[ability];
      if (score == null) {
        throw StateError('Waffenattribut $ability ist noch offen.');
      }
      damageMod = RulesEngine.abilityModifier(score);
      atk =
          damageMod +
          (s.weaponProficient ? RulesEngine.proficiencyBonus(hero.level) : 0) +
          FighterStyleCombatRules.archeryBonus(hero, weapon);
      damage = s.twoHands && weapon.twoHandDamage != null
          ? weapon.twoHandDamage
          : weapon.damage;
      if (damage == null) throw StateError('Keine bestätigten Schadenswürfel.');
      if (weapon.hasProperty('heavy')) {
        final heavyAbility = ranged ? 'dexterity' : 'strength';
        final heavyScore = hero.abilities[heavyAbility];
        if (heavyScore == null) {
          throw StateError('Attribut für schwere Waffe fehlt.');
        }
        heavyDisadvantage = heavyScore < 13;
        if (heavyDisadvantage) {
          warnings.add(
            'Schwere Waffe: Angriffe mit Nachteil (Attribut unter 13).',
          );
        }
      }
      if (weapon.hasProperty('ammunition')) {
        warnings.add(
          'Munition muss bei jedem Angriff vorhanden sein und verbraucht werden.',
        );
      }
      if (weapon.mastery != null) {
        warnings.add(
          'Waffenmeisterschaft ${weapon.mastery}: nur mit passendem Klassenmerkmal.',
        );
      }
      if (weapon.hasProperty('reach')) {
        warnings.add(
          'Reichweite: +5 Fuß für Nahkampfangriffe und Gelegenheitsangriffe.',
        );
      }
      if (weapon.hasProperty('loading')) {
        warnings.add('Laden begrenzt Schüsse pro Aktion/Bonusaktion/Reaktion.');
      }
      if (weapon.hasProperty('light')) {
        warnings.add(
          'Zusatzangriff mit leichter Waffe ist eine eigene, begrenzte Aktion.',
        );
      }
    }
    return EquipmentRulePreview(
      selection: s,
      sourceHeroId: hero.id,
      sourceArmorClass: hero.armorClass,
      sourceWeaponDamage: hero.weaponDamage,
      sourceWeaponAbility: hero.weaponAbility,
      sourceWeaponProficient: hero.weaponProficient,
      armorClass: ac,
      weaponDamage: damage,
      weaponAbility: ability,
      attackBonus: atk,
      damageModifier: damageMod,
      speedPenaltyFeet: penalty,
      stealthDisadvantage: stealth,
      armorUntrained: untrained,
      heavyAttackDisadvantage: heavyDisadvantage,
      needsAmmunition: weapon?.hasProperty('ammunition') ?? false,
      rangeNormal: weapon?.rangeNormal,
      rangeLong: weapon?.rangeLong,
      warnings: List.unmodifiable(warnings),
    );
  }

  /// Called only after the preview is accepted. Recomputes on the *current*
  /// hero and refuses to apply if any relevant value has changed.
  static HeroCharacter confirm(
    HeroCharacter current,
    EquipmentRulePreview proposed,
  ) {
    if (current.id != proposed.sourceHeroId ||
        current.armorClass != proposed.sourceArmorClass ||
        current.weaponDamage != proposed.sourceWeaponDamage ||
        current.weaponAbility != proposed.sourceWeaponAbility ||
        current.weaponProficient != proposed.sourceWeaponProficient) {
      throw StateError(
        'Ausrüstungsvorschlag gehört zu einem anderen oder veränderten Helden.',
      );
    }
    final fresh = preview(current, proposed.selection);
    if (fresh.armorClass != proposed.armorClass ||
        fresh.weaponDamage != proposed.weaponDamage ||
        fresh.weaponAbility != proposed.weaponAbility ||
        fresh.attackBonus != proposed.attackBonus ||
        fresh.speedPenaltyFeet != proposed.speedPenaltyFeet ||
        fresh.heavyAttackDisadvantage != proposed.heavyAttackDisadvantage ||
        fresh.stealthDisadvantage != proposed.stealthDisadvantage) {
      throw StateError(
        'Die Charakterwerte haben sich seit der Vorschau geändert.',
      );
    }
    final s = proposed.selection;
    return current.copyWith(
      armorClass: fresh.armorClass ?? current.armorClass,
      weaponDamage: fresh.weaponDamage ?? current.weaponDamage,
      weaponAbility: fresh.weaponAbility ?? current.weaponAbility,
      weaponProficient: s.weaponId.isNotEmpty
          ? s.weaponProficient
          : current.weaponProficient,
      equippedArmorId: s.armorId,
      equippedShieldId: s.shieldId,
      equippedWeaponId: s.weaponId,
      equippedArmorTrained: s.armorTrained,
      equippedShieldTrained: s.shieldTrained,
    );
  }
}
