import '../domain/models.dart';

/// Explicit player choice of a saved NPC, bound to one campaign revision.
///
/// The name is for display only: only [npcId] identifies the selected NPC.
/// This object authorizes read-only narrative context, never rule changes.
class NpcStorySelection {
  const NpcStorySelection._({
    required this.campaignId,
    required this.revision,
    required this.npcId,
    required this.name,
    required this.relationship,
    required this.alive,
  });

  final String campaignId;
  final int revision;
  final String npcId;
  final String name;
  final String relationship;
  final bool alive;

  /// Called after a player actively selects one saved NPC identity.
  static NpcStorySelection choose(Campaign campaign, String npcId) {
    if (campaign.id.trim().isEmpty ||
        campaign.revision < 0 ||
        campaign.revision > 2147483647 ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(npcId)) {
      throw const FormatException('Ungültige NPC-Auswahl.');
    }
    final matches = campaign.npcs.where((npc) => npc.id == npcId).toList();
    if (matches.length != 1) {
      throw const FormatException('NPC-ID nicht eindeutig bestätigt.');
    }
    final npc = matches.single;
    return NpcStorySelection._(
      campaignId: campaign.id,
      revision: campaign.revision,
      npcId: npc.id,
      name: npc.name,
      relationship: npc.relationship,
      alive: npc.alive,
    );
  }

  /// Fails closed on a newer save, a different campaign, or changed NPC data.
  ///
  /// A stale selection must never silently retarget a same-name NPC.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId || campaign.revision != revision) {
      throw const FormatException('NPC-Auswahl ist nicht mehr aktuell.');
    }
    final matches = campaign.npcs.where((npc) => npc.id == npcId).toList();
    if (matches.length != 1 ||
        matches.single.name != name ||
        matches.single.relationship != relationship ||
        matches.single.alive != alive) {
      throw const FormatException('Ausgewählter NPC wurde verändert.');
    }
  }
}
