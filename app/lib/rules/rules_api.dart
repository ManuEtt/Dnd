// Public rule-only entrypoint for parallel SRD 5.2.1 development.
//
// No story generation, campaign scripts or backend requests are exported.
// Legacy implementations stay in domain/ while the existing app migrates.
export '../domain/dice_engine.dart';
export '../domain/rules_engine.dart';
export '../domain/sneak_attack_ally_rules.dart';
export '../domain/damage_rules.dart';
export '../domain/condition_rules.dart';
export '../domain/cover_rules.dart';
export '../domain/spellcasting_rules.dart';
export '../domain/srd_spell_component_rules.dart';
export '../domain/srd_spell_duration_rules.dart';
export '../domain/srd_spell_catalog.dart';
export '../domain/srd_spell_preflight_rules.dart';
export '../domain/srd_spell_target_rules.dart';
export '../domain/srd_spell_grid_target_rules.dart';
export '../domain/srd_sphere_area_rules.dart';
export '../domain/srd_cone_area_rules.dart';
export '../domain/srd_line_area_rules.dart';
export '../domain/srd_spell_inventory_rules.dart';
export '../domain/srd_spell_saving_throw_rules.dart';
export '../domain/srd_initiative_roster_rules.dart';
export '../domain/srd_extra_creature_attack_rules.dart';
export '../domain/srd_opportunity_attack_rules.dart';
export '../domain/srd_cube_area_rules.dart';
export '../domain/srd_sending_rules.dart';
export '../domain/srd_sending_cast_preflight_rules.dart';
