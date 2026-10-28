import 'models.dart';
import 'srd_character_classes.dart';

/// Level unlocks from the SRD 5.2.1 class tables (CC BY 4.0).
/// IMPORTANT: A listed feature is NOT evidence its effect is simulated.
/// Subclass entries are scoped to their SRD subclass only; unknown subclasses
/// never receive features from a different subclass.
class SrdClassFeature {
  const SrdClassFeature({
    required this.id,
    required this.className,
    required this.classLevel,
    required this.name,
    this.subclass = '',
    required this.automation,
  });

  final String id, className, name, subclass;
  final int classLevel;
  final FeatureAutomation automation;
  bool get isSubclass => subclass.isNotEmpty;
  bool get needsRuleResolution => automation != FeatureAutomation.automatic;
}

enum FeatureAutomation { automatic, partial, choiceRequired, manual }

class SrdClassFeatureCatalog {
  const SrdClassFeatureCatalog._();
  static const source = 'https://www.dndbeyond.com/srd';

  // Every base class table level with a feature. Entries repeat only when a
  // table explicitly grants another use/improvement of an existing feature.
  // Values separated by semicolons are distinct individual features.
  static const Map<String, String> _base = {
    'Barbar': '''
1|Rage; Unarmored Defense; Weapon Mastery
2|Danger Sense; Reckless Attack
3|Barbarian Subclass; Primal Knowledge
4|Ability Score Improvement
5|Extra Attack; Fast Movement
7|Feral Instinct; Instinctive Pounce
8|Ability Score Improvement
9|Brutal Strike
11|Relentless Rage
12|Ability Score Improvement
13|Improved Brutal Strike
15|Persistent Rage
16|Ability Score Improvement
17|Improved Brutal Strike
18|Indomitable Might
19|Epic Boon
20|Primal Champion''',
    'Barde': '''
1|Bardic Inspiration; Spellcasting
2|Expertise; Jack of All Trades
3|Bard Subclass
4|Ability Score Improvement
5|Font of Inspiration
7|Countercharm
8|Ability Score Improvement
9|Expertise
10|Magical Secrets
12|Ability Score Improvement
16|Ability Score Improvement
18|Superior Inspiration
19|Epic Boon
20|Words of Creation''',
    'Kleriker': '''
1|Spellcasting; Divine Order
2|Channel Divinity
3|Cleric Subclass
4|Ability Score Improvement
5|Sear Undead
7|Blessed Strikes
8|Ability Score Improvement
10|Divine Intervention
12|Ability Score Improvement
14|Improved Blessed Strikes
16|Ability Score Improvement
19|Epic Boon
20|Greater Divine Intervention''',
    'Druide': '''
1|Spellcasting; Druidic; Primal Order
2|Wild Shape; Wild Companion
3|Druid Subclass
4|Ability Score Improvement
5|Wild Resurgence
7|Elemental Fury
8|Ability Score Improvement
12|Ability Score Improvement
15|Improved Elemental Fury
16|Ability Score Improvement
18|Beast Spells
19|Epic Boon
20|Archdruid''',
    'Kämpfer': '''
1|Fighting Style; Second Wind; Weapon Mastery
2|Action Surge; Tactical Mind
3|Fighter Subclass
4|Ability Score Improvement
5|Extra Attack; Tactical Shift
6|Ability Score Improvement
8|Ability Score Improvement
9|Indomitable; Tactical Master
11|Two Extra Attacks
12|Ability Score Improvement
13|Indomitable; Studied Attacks
14|Ability Score Improvement
16|Ability Score Improvement
17|Action Surge; Indomitable
19|Epic Boon
20|Three Extra Attacks''',
    'Mönch': '''
1|Martial Arts; Unarmored Defense
2|Monk's Focus; Unarmored Movement; Uncanny Metabolism
3|Deflect Attacks; Monk Subclass
4|Ability Score Improvement; Slow Fall
5|Extra Attack; Stunning Strike
6|Empowered Strikes
7|Evasion
8|Ability Score Improvement
9|Acrobatic Movement
10|Heightened Focus; Self-Restoration
12|Ability Score Improvement
13|Deflect Energy
14|Disciplined Survivor
15|Perfect Focus
16|Ability Score Improvement
18|Superior Defense
19|Epic Boon
20|Body and Mind''',
    'Paladin': '''
1|Lay On Hands; Spellcasting; Weapon Mastery
2|Fighting Style; Paladin's Smite
3|Channel Divinity; Paladin Subclass
4|Ability Score Improvement
5|Extra Attack; Faithful Steed
6|Aura of Protection
8|Ability Score Improvement
9|Abjure Foes
10|Aura of Courage
11|Radiant Strikes
12|Ability Score Improvement
14|Restoring Touch
16|Ability Score Improvement
18|Aura Expansion
19|Epic Boon''',
    'Waldläufer': '''
1|Spellcasting; Favored Enemy; Weapon Mastery
2|Deft Explorer; Fighting Style
3|Ranger Subclass
4|Ability Score Improvement
5|Extra Attack
6|Roving
8|Ability Score Improvement
9|Expertise
10|Tireless
12|Ability Score Improvement
13|Relentless Hunter
14|Nature's Veil
16|Ability Score Improvement
17|Precise Hunter
18|Feral Senses
19|Epic Boon
20|Foe Slayer''',
    'Schurke': '''
1|Expertise; Sneak Attack; Thieves' Cant; Weapon Mastery
2|Cunning Action
3|Rogue Subclass; Steady Aim
4|Ability Score Improvement
5|Cunning Strike; Uncanny Dodge
6|Expertise
7|Evasion; Reliable Talent
8|Ability Score Improvement
10|Ability Score Improvement
11|Improved Cunning Strike
12|Ability Score Improvement
14|Devious Strikes
15|Slippery Mind
16|Ability Score Improvement
18|Elusive
19|Epic Boon
20|Stroke of Luck''',
    'Zauberer': '''
1|Spellcasting; Innate Sorcery
2|Font of Magic; Metamagic
3|Sorcerer Subclass
4|Ability Score Improvement
5|Sorcerous Restoration
7|Sorcery Incarnate
8|Ability Score Improvement
10|Metamagic
12|Ability Score Improvement
16|Ability Score Improvement
17|Metamagic
19|Epic Boon
20|Arcane Apotheosis''',
    'Hexenmeister': '''
1|Eldritch Invocations; Pact Magic
2|Magical Cunning
3|Warlock Subclass
4|Ability Score Improvement
8|Ability Score Improvement
9|Contact Patron
11|Mystic Arcanum (6th)
12|Ability Score Improvement
13|Mystic Arcanum (7th)
15|Mystic Arcanum (8th)
16|Ability Score Improvement
17|Mystic Arcanum (9th)
19|Epic Boon
20|Eldritch Master''',
    'Magier': '''
1|Spellcasting; Ritual Adept; Arcane Recovery
2|Scholar
3|Wizard Subclass
4|Ability Score Improvement
5|Memorize Spell
8|Ability Score Improvement
12|Ability Score Improvement
16|Ability Score Improvement
18|Spell Mastery
19|Epic Boon
20|Signature Spells''',
  };

  /// Exactly the subclass made available by SRD 5.2.1 for each base class.
  static const Map<String, String> defaultSubclass = {
    'Barbar': 'Berserker',
    'Barde': 'College of Lore',
    'Kleriker': 'Life Domain',
    'Druide': 'Circle of the Land',
    'Kämpfer': 'Champion',
    'Mönch': 'Warrior of the Open Hand',
    'Paladin': 'Oath of Devotion',
    'Waldläufer': 'Hunter',
    'Schurke': 'Thief',
    'Zauberer': 'Draconic Sorcery',
    'Hexenmeister': 'Fiend Patron',
    'Magier': 'Evoker',
  };

  static const Map<String, String> _subclassFeatures = {
    'Barbar':
        '3|Frenzy\n6|Mindless Rage\n10|Retaliation\n14|Intimidating Presence',
    'Barde':
        '3|Bonus Proficiencies; Cutting Words\n6|Magical Discoveries\n14|Peerless Skill',
    'Kleriker':
        '3|Disciple of Life; Preserve Life; Life Domain Spells\n6|Blessed Healer\n17|Supreme Healing',
    'Druide':
        '3|Circle of the Land Spells; Land’s Aid\n6|Natural Recovery\n10|Nature’s Ward\n14|Nature’s Sanctuary',
    'Kämpfer':
        '3|Improved Critical; Remarkable Athlete\n7|Additional Fighting Style\n10|Heroic Warrior\n15|Superior Critical\n18|Survivor',
    'Mönch':
        '3|Open Hand Technique\n6|Wholeness of Body\n11|Fleet Step\n17|Quivering Palm',
    'Paladin':
        '3|Oath of Devotion Spells; Sacred Weapon\n7|Aura of Devotion\n15|Smite of Protection\n20|Holy Nimbus',
    'Waldläufer':
        '3|Hunter’s Prey; Hunter’s Lore\n7|Defensive Tactics\n11|Superior Hunter’s Prey\n15|Superior Hunter’s Defense',
    'Schurke':
        '3|Fast Hands; Second-Story Work\n9|Supreme Sneak\n13|Use Magic Device\n17|Thief’s Reflexes',
    'Zauberer':
        '3|Draconic Resilience; Draconic Spells; Dragon Speech\n6|Elemental Affinity\n14|Dragon Wings\n18|Dragon Companion',
    'Hexenmeister':
        '3|Dark One’s Blessing; Fiend Spells\n6|Dark One’s Own Luck\n10|Fiendish Resilience\n14|Hurl Through Hell',
    'Magier':
        '3|Evocation Savant; Potent Cantrip\n6|Sculpt Spells\n10|Empowered Evocation\n14|Overchannel',
  };

  static const Set<String> _automaticNames = {
    'Extra Attack',
    'Two Extra Attacks',
    'Three Extra Attacks',
    'Second Wind',
    'Superior Inspiration',
    'Unarmored Movement',
    'Fast Movement',
    'Feral Instinct',
    'Danger Sense',
    'Improved Critical',
    'Superior Critical',
    'Jack of All Trades',
    'Reliable Talent',
    'Slippery Mind',
    // Numeric level-20 capstones are applied by SrdClassLevelUpRules.
    'Primal Champion',
    'Body and Mind',
  };
  static const Set<String> _partialNames = {
    'Spellcasting',
    'Pact Magic',
    'Channel Divinity',
    'Rage',
    'Action Surge',
    "Monk's Focus",
    'Bardic Inspiration',
    'Lay On Hands',
    'Font of Magic',
    'Wild Shape',
    'Favored Enemy',
    'Weapon Mastery',
    'Sneak Attack',
    'Martial Arts',
    'Unarmored Defense',
    // Strength checks and saves have a confirmed floor, but full action
    // coverage and final CI are tracked separately.
    'Indomitable Might',
    'Remarkable Athlete',
    // A confirmed Reaction damage preflight exists, but HP/reaction
    // expenditure is not yet committed atomically in an encounter.
    'Slow Fall',
    // Confirmed Dexterity-save-for-half preflight; no automatic HP commit.
    'Evasion',
    // Speed and derived movement types work; climbing/swimming terrain
    // expenditure still requires a dedicated confirmed movement action.
    'Roving',
    // The rest-driven exhaustion benefit works; the Magic action that
    // generates temporary HP is a separate player-confirmed step.
    'Tireless',
    // Range is derived automatically, but target detection is not resolved
    // without confirmed cover, distance and concealment.
    'Feral Senses',
  };

  static final Map<String, List<SrdClassFeature>> _catalog = {
    for (final key in _base.keys)
      key: List.unmodifiable([
        ..._parse(key, _base[key]!),
        ..._parse(
          key,
          _subclassFeatures[key]!,
          subclass: defaultSubclass[key]!,
        ),
      ]),
  };

  static List<SrdClassFeature> _parse(
    String className,
    String data, {
    String subclass = '',
  }) {
    final result = <SrdClassFeature>[];
    for (final line in data.trim().split('\n')) {
      if (line.trim().isEmpty) continue;
      final index = line.indexOf('|');
      if (index < 1) throw FormatException('Ungültige Klassenzeile: $line');
      final level = int.parse(line.substring(0, index).trim());
      if (level < 1 || level > 20) throw FormatException('Stufe $level');
      final entries = line.substring(index + 1).split(';');
      for (var index = 0; index < entries.length; index++) {
        final name = entries[index].trim();
        if (name.isEmpty) {
          throw FormatException('Leeres Merkmal bei $className');
        }
        final status = _automaticNames.contains(name)
            ? FeatureAutomation.automatic
            : _partialNames.contains(name)
            ? FeatureAutomation.partial
            : name.contains('Subclass') ||
                  name == 'Epic Boon' ||
                  name == 'Ability Score Improvement' ||
                  name == 'Fighting Style' ||
                  name == 'Metamagic' ||
                  name == 'Eldritch Invocations' ||
                  name == 'Divine Order' ||
                  name == 'Primal Order' ||
                  name == 'Blessed Strikes' ||
                  name == 'Elemental Fury'
            ? FeatureAutomation.choiceRequired
            : FeatureAutomation.manual;
        final classSlug = className.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '-',
        );
        final featureSlug = name.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '-',
        );
        final source = subclass.isEmpty ? 'base' : 'subclass';
        final id = '${classSlug}_${level}_${source}_${featureSlug}_$index';
        result.add(
          SrdClassFeature(
            id: id,
            className: className,
            classLevel: level,
            name: name,
            subclass: subclass,
            automation: status,
          ),
        );
      }
    }
    return result;
  }

  static List<SrdClassFeature> allForClass(String name) {
    final key = findSrdClass(name)?.name;
    return key == null ? const [] : _catalog[key]!;
  }

  static List<SrdClassFeature> atClassLevel(
    String name,
    int classLevel, {
    String subclass = '',
  }) {
    if (classLevel < 1 || classLevel > 20) return const [];
    final key = findSrdClass(name)?.name;
    if (key == null) return const [];
    return List.unmodifiable(
      _catalog[key]!.where(
        (feature) =>
            feature.classLevel == classLevel &&
            (feature.subclass.isEmpty || _matchesSubclass(key, subclass)),
      ),
    );
  }

  static bool _matchesSubclass(String className, String entered) {
    final expected = defaultSubclass[className];
    if (expected == null || entered.trim().isEmpty) return false;
    final normalized = entered.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final canonical = expected.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    if (normalized == canonical) return true;
    const localized = {
      'Barbar': ['Berserker', 'Pfad des Berserkers'],
      'Barde': ['Schule des Wissens'],
      'Kleriker': ['Domäne des Lebens', 'Lebensdomäne'],
      'Druide': ['Zirkel des Landes'],
      'Kämpfer': ['Champion'],
      'Mönch': ['Offene Hand', 'Weg der offenen Hand'],
      'Paladin': ['Schwur der Hingabe'],
      'Waldläufer': ['Jäger'],
      'Schurke': ['Dieb'],
      'Zauberer': ['Drakonische Zauberei'],
      'Hexenmeister': ['Unhold', 'Unhold-Schutzherr'],
      'Magier': ['Hervorrufer'],
    };
    return (localized[className] ?? const <String>[]).any(
      (v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == normalized,
    );
  }

  /// Handles character *class levels*, never total levels of multiclass heroes.
  /// Source list features are not inserted into HeroCharacter.features, because
  /// that field represents explicitly confirmed/manual special abilities.
  static List<SrdClassFeature> unlocked(HeroCharacter hero) {
    final primary = findSrdClass(hero.className)?.name;
    final secondary = findSrdClass(hero.secondaryClassName)?.name;
    final result = <SrdClassFeature>[];
    if (primary != null) {
      result.addAll(
        _catalog[primary]!.where(
          (x) =>
              x.classLevel <= hero.primaryClassLevel &&
              (x.subclass.isEmpty || _matchesSubclass(primary, hero.subclass)),
        ),
      );
    }
    if (secondary != null && hero.hasSecondClass) {
      // A second class has its own independently confirmed subclass.
      // Its special features remain class-level gated, never total-level gated.
      result.addAll(
        _catalog[secondary]!.where(
          (x) =>
              x.classLevel <= hero.secondaryClassLevel &&
              (x.subclass.isEmpty ||
                  _matchesSubclass(secondary, hero.secondarySubclass)),
        ),
      );
    }
    result.sort((a, b) => a.classLevel.compareTo(b.classLevel));
    return List.unmodifiable(result);
  }

  static Map<String, int> get counts => {
    for (final key in _catalog.keys) key: _catalog[key]!.length,
  };
}
