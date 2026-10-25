import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_opportunity_attack_rules.dart';

HeroCharacter _hero() => GameEngine().createDemo().hero.copyWith(
  equippedWeaponId: 'dagger',
  weaponDamage: '1d4',
  inventory: const [
    InventoryItem(id: 'dagger', name: 'Dolch', catalogId: 'weapon-dagger'),
    InventoryItem(id: 'bow', name: 'Kurzbogen', catalogId: 'weapon-shortbow'),
  ],
);

Campaign _campaign({HeroCharacter? hero, Encounter? fight}) =>
    GameEngine().createDemo(hero: hero ?? _hero()).copyWith(
      encounter:
          fight ??
          const Encounter(
            id: 'enemy-1',
            enemyName: 'Gegner',
            enemyHitPoints: 12,
            enemyMaxHitPoints: 12,
            activeParticipant: 'enemy',
          ),
    );

ConfirmedOpportunityTrigger _trigger({
  String encounterId = 'enemy-1',
  int before = 5,
  int after = 10,
  int reach = 5,
  bool visible = true,
  bool authorized = true,
  OpportunityMovement movement = OpportunityMovement.ordinary,
  OpportunityStrike strike = OpportunityStrike.equippedMeleeWeapon,
  String weaponId = 'dagger',
}) => ConfirmedOpportunityTrigger(
  encounterId: encounterId,
  beforeDistanceFeet: before,
  afterDistanceFeet: after,
  reachFeet: reach,
  targetVisibleConfirmed: visible,
  playerAuthorizedReaction: authorized,
  movement: movement,
  strike: strike,
  weaponId: weaponId,
);

void main() {
  test('sichtbarer Gegner verlässt bestätigte Reichweite: reines Angebot', () {
    final before = _campaign();
    final snapshot = before.toJson();
    final offer = SrdOpportunityAttackRules.prepare(before, _trigger());
    expect(offer.encounterId, before.encounter!.id);
    expect(offer.revision, before.revision);
    expect(offer.strike, OpportunityStrike.equippedMeleeWeapon);
    expect(offer.weaponId, 'dagger');
    expect(before.toJson(), snapshot);
    expect(before.encounter!.reactionUsed, isFalse);
  });

  test('erweiterte bestätigte Reichweite gilt erst beim Verlassen', () {
    final before = _campaign();
    expect(
      SrdOpportunityAttackRules.prepare(
        before,
        _trigger(before: 10, after: 15, reach: 10),
      ).encounterId,
      'enemy-1',
    );
    for (final invalid in [
      _trigger(before: 10, after: 10, reach: 10),
      _trigger(before: 15, after: 20, reach: 10),
      _trigger(before: 15, after: 5, reach: 10),
      _trigger(before: 5, after: 10, reach: 0),
      _trigger(before: -1, after: 10),
      _trigger(before: 5, after: -1),
    ]) {
      expect(
        () => SrdOpportunityAttackRules.prepare(before, invalid),
        throwsFormatException,
      );
    }
  });

  test('Rückzug, Teleportation und fremde Bewegung provozieren nicht', () {
    final before = _campaign();
    for (final movement in [
      OpportunityMovement.disengage,
      OpportunityMovement.teleport,
      OpportunityMovement.forced,
    ]) {
      expect(
        () => SrdOpportunityAttackRules.prepare(
          before,
          _trigger(movement: movement),
        ),
        throwsFormatException,
      );
    }
  });

  test('Sicht und ausdrückliche Einwilligung sind obligatorisch', () {
    final campaign = _campaign();
    for (final invalid in [
      _trigger(visible: false),
      _trigger(authorized: false),
    ]) {
      expect(
        () => SrdOpportunityAttackRules.prepare(campaign, invalid),
        throwsFormatException,
      );
    }
  });

  test(
    'keine Reaktion bei fremdem Ziel, falschem Zug oder verbrauchter Reaktion',
    () {
    final initial = _campaign();
    expect(
      () => SrdOpportunityAttackRules.prepare(
        initial,
        _trigger(encounterId: 'other-target'),
      ),
      throwsFormatException,
    );
    for (final invalid in [
      initial.encounter!.copyWith(activeParticipant: 'hero'),
      initial.encounter!.copyWith(reactionUsed: true),
      initial.encounter!.copyWith(enemyHitPoints: 0),
    ]) {
      expect(
        () => SrdOpportunityAttackRules.prepare(
          initial.copyWith(encounter: invalid),
          _trigger(),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => SrdOpportunityAttackRules.prepare(
        initial.copyWith(encounter: null),
        _trigger(),
      ),
      throwsFormatException,
    );
  },
  );

  test('aktionsunfähiger und kampfunfähiger Held erhält keine Reaktion', () {
    final initial = _campaign();
    for (final hero in [
      _hero().copyWith(hitPoints: 0),
      _hero().copyWith(conditions: ['betäubt']),
      _hero().copyWith(conditions: ['bewusstlos']),
      _hero().copyWith(conditions: ['tot']),
      _hero().copyWith(abilities: {..._hero().abilities, 'strength': null}),
    ]) {
      expect(
        () => SrdOpportunityAttackRules.prepare(
          initial.copyWith(hero: hero),
          _trigger(),
        ),
        throwsFormatException,
      );
    }
  });

  test('nur eindeutige angelegte Nahkampf-Katalogwaffe', () {
    final initial = _campaign();
    final badHeroes = [
      _hero().copyWith(equippedWeaponId: 'bow'),
      _hero().copyWith(equippedWeaponId: ''),
      _hero().copyWith(inventory: const []),
      _hero().copyWith(inventory: const [
        InventoryItem(
          id: 'dagger',
          name: 'Dolch 1',
          catalogId: 'weapon-dagger',
        ),
        InventoryItem(
          id: 'dagger',
          name: 'Dolch 2',
          catalogId: 'weapon-dagger',
        ),
      ]),
      _hero().copyWith(inventory: const [
        InventoryItem(id: 'dagger', name: 'Unbekanntes Erbstück'),
      ]),
      _hero().copyWith(inventory: const [
        InventoryItem(
          id: 'dagger',
          name: 'Dolch',
          catalogId: 'weapon-dagger',
          quantity: 0,
        ),
      ]),
    ];
    for (final hero in badHeroes) {
      expect(
        () => SrdOpportunityAttackRules.prepare(
          initial.copyWith(hero: hero),
          _trigger(weaponId: hero.equippedWeaponId == 'bow' ? 'bow' : 'dagger'),
        ),
        throwsFormatException,
      );
    }
  });

  test('waffenloser Schlag ohne erfundene Waffe ist zulässig', () {
    final initial = _campaign(hero: _hero().copyWith(equippedWeaponId: ''));
    final offer = SrdOpportunityAttackRules.prepare(
      initial,
      _trigger(strike: OpportunityStrike.unarmedStrike, weaponId: ''),
    );
    expect(offer.weaponId, isEmpty);
    expect(offer.strike, OpportunityStrike.unarmedStrike);
    expect(
      () => SrdOpportunityAttackRules.prepare(
        initial,
        _trigger(strike: OpportunityStrike.unarmedStrike, weaponId: 'dagger'),
      ),
      throwsFormatException,
    );
  });

  test('vorhandene JSON-Spielstände bleiben unverändert lesbar', () {
    final campaign = _campaign();
    final loaded = Campaign.fromJson(campaign.toJson());
    final initialJson = loaded.toJson();
    final offer = SrdOpportunityAttackRules.prepare(loaded, _trigger());
    expect(offer.revision, loaded.revision);
    expect(loaded.toJson(), initialJson);
    expect(loaded.encounter!.reactionUsed, isFalse);
  });
}
