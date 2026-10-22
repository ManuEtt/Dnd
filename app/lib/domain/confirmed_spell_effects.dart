import 'models.dart';

/// A separately confirmed, already-resolved hero spell effect. Merely
/// registering this record never casts a spell or applies its mechanics.
/// Each independently confirmed cause has its own ID and source.
class ConfirmedSpellEffect {
  ConfirmedSpellEffect({
    required this.id,
    required this.spellName,
    required String source,
    this.concentrationBound = false,
    this.expiresInEncounterId,
    this.expiresAtOwnTurnEndRound,
  }) : source = source.trim() {
    for (final item in [id, spellName, this.source]) {
      if (item.isEmpty || item.trim() != item || item.length > 200) {
        throw const FormatException('Ungültiger bestätigter Zaubereintrag.');
      }
    }
    if ((expiresInEncounterId == null) != (expiresAtOwnTurnEndRound == null)) {
      throw const FormatException('Unvollständiges Zauberwirkungsende.');
    }
    if (expiresInEncounterId != null &&
        (expiresInEncounterId!.isEmpty ||
            expiresInEncounterId!.trim() != expiresInEncounterId ||
            expiresInEncounterId!.length > 200)) {
      throw const FormatException('Ungültige Zauber-Begegnungsreferenz.');
    }
    if (expiresAtOwnTurnEndRound != null &&
        (expiresAtOwnTurnEndRound! < 1 ||
            expiresAtOwnTurnEndRound! > 1000000)) {
      throw const FormatException('Ungültige Zauber-Endrunde.');
    }
  }

  final String id;
  final String spellName;
  final String source;
  final bool concentrationBound;
  final String? expiresInEncounterId;
  final int? expiresAtOwnTurnEndRound;

  Map<String, dynamic> toJson() => {
    'id': id,
    'spellName': spellName,
    'source': source,
    if (concentrationBound) 'concentrationBound': true,
    if (expiresInEncounterId != null)
      'expiresInEncounterId': expiresInEncounterId,
    if (expiresAtOwnTurnEndRound != null)
      'expiresAtOwnTurnEndRound': expiresAtOwnTurnEndRound,
  };

  factory ConfirmedSpellEffect.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Zaubereintrag muss ein Objekt sein.');
    }
    String string(String name) {
      final field = value[name];
      if (field is! String) {
        throw FormatException('Ungültiges Zauberfeld: $name.');
      }
      return field;
    }
    final bound = value['concentrationBound'];
    if (bound != null && bound is! bool) {
      throw const FormatException('Ungültige Konzentrationsbindung.');
    }
    final encounter = value['expiresInEncounterId'];
    if (encounter != null && encounter is! String) {
      throw const FormatException('Ungültige Zauber-Begegnungsreferenz.');
    }
    final round = value['expiresAtOwnTurnEndRound'];
    if (round != null && round is! int) {
      throw const FormatException('Ungültige Zauber-Endrunde.');
    }
    return ConfirmedSpellEffect(
      id: string('id'),
      spellName: string('spellName'),
      source: string('source'),
      concentrationBound: bound == true,
      expiresInEncounterId: encounter as String?,
      expiresAtOwnTurnEndRound: round as int?,
    );
  }
}

/// Read-only expiry evidence, plus pure spell-effect bookkeeping.
/// No catalog duration, target effect, action, resource or clock is inferred.
class ConfirmedSpellEffectRules {
  const ConfirmedSpellEffectRules._();

  static List<ConfirmedSpellEffect> validated(
    List<ConfirmedSpellEffect> effects,
  ) {
    if (effects.length > 40) {
      throw const FormatException('Zu viele bestätigte Zauberwirkungen.');
    }
    if (effects.map((effect) => effect.id).toSet().length != effects.length) {
      throw const FormatException('Doppelte Zauberwirkungs-ID.');
    }
    return List.unmodifiable(effects);
  }

  static HeroCharacter add(
    HeroCharacter hero,
    ConfirmedSpellEffect effect,
  ) {
    if (!hero.spells.contains(effect.spellName)) {
      throw const FormatException('Zauber ist dem Helden nicht bekannt.');
    }
    if (effect.concentrationBound &&
        (hero.concentratingOn != effect.spellName ||
            hero.isDead ||
            hero.hitPoints == 0 ||
            hero.confirmedSpellEffects.any((e) => e.concentrationBound))) {
      throw const FormatException(
        'Konzentrationsgebundener Eintrag benötigt aktive Konzentration.',
      );
    }
    return hero.copyWith(
      confirmedSpellEffects: validated([...hero.confirmedSpellEffects, effect]),
    );
  }

  static HeroCharacter remove(HeroCharacter hero, String effectId) {
    final found = hero.confirmedSpellEffects.where((e) => e.id == effectId);
    if (found.length != 1) {
      throw const FormatException('Zauberwirkung ist nicht mehr vorhanden.');
    }
    return hero.copyWith(
      confirmedSpellEffects: [
        for (final current in hero.confirmedSpellEffects)
          if (current.id != effectId) current,
      ],
    );
  }

  /// Concentration loss and replacement are authoritative in the hero state.
  /// An old record never restores or establishes concentration.
  static HeroCharacter discardBrokenConcentration(HeroCharacter hero) {
    final kept = [
      for (final effect in hero.confirmedSpellEffects)
        if (!effect.concentrationBound ||
            effect.spellName == hero.concentratingOn)
          effect,
    ];
    return kept.length == hero.confirmedSpellEffects.length
        ? hero
        : hero.copyWith(confirmedSpellEffects: kept);
  }

  /// ONLY called at a confirmed own-turn boundary for this encounter.
  static HeroCharacter expireAtOwnTurnEnd(
    HeroCharacter hero, {
    required String encounterId,
    required int round,
  }) {
    if (encounterId.isEmpty || round < 1) {
      throw ArgumentError('Ungültiger bestätigter Zauber-Zugendpunkt.');
    }
    final expired = hero.confirmedSpellEffects.where(
      (effect) =>
          effect.expiresInEncounterId == encounterId &&
          effect.expiresAtOwnTurnEndRound != null &&
          effect.expiresAtOwnTurnEndRound! <= round,
    ).toList();
    if (expired.isEmpty) return hero;
    final endingConcentration = expired.any(
      (e) => e.concentrationBound && e.spellName == hero.concentratingOn,
    );
    return discardBrokenConcentration(
      hero.copyWith(
        confirmedSpellEffects: [
          for (final effect in hero.confirmedSpellEffects)
            if (!expired.any((e) => e.id == effect.id)) effect,
        ],
        concentratingOn: endingConcentration ? '' : hero.concentratingOn,
      ),
    );
  }

  /// Only display a count in the owner's active, unfinished encounter.
  static int? remainingOwnTurnEnds(
    ConfirmedSpellEffect effect,
    Encounter? encounter,
  ) {
    final end = effect.expiresAtOwnTurnEndRound;
    if (end == null ||
        encounter == null ||
        encounter.isFinished ||
        encounter.activeParticipant != 'hero' ||
        encounter.id != effect.expiresInEncounterId ||
        encounter.round < 1 ||
        encounter.round > end) {
      return null;
    }
    return end - encounter.round + 1;
  }
}
