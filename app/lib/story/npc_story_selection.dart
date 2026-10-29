import '../domain/models.dart';

/// Explicit player choice of a saved NPC, bound to one campaign session
/// and revision. Profile fields are retained only to detect stale choices.
///
/// The name is for display only: only [npcId] identifies the selected NPC.
/// This object authorizes read-only narrative context, never rule changes.
class NpcStorySelection {
  const NpcStorySelection._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required this.npcId,
    required this.name,
    required this.description,
    required this.relationship,
    required this.alive,
  });

  final String campaignId, sessionId;
  final int revision;
  final String npcId;
  final String name;
  final String description;
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
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      npcId: npc.id,
      name: npc.name,
      description: npc.description,
      relationship: npc.relationship,
      alive: npc.alive,
    );
  }

  /// Fails closed on a newer save, another session/campaign, or changed NPC data.
  ///
  /// A stale selection must never silently retarget a same-name NPC.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision) {
      throw const FormatException('NPC-Auswahl ist nicht mehr aktuell.');
    }
    final matches = campaign.npcs.where((npc) => npc.id == npcId).toList();
    if (matches.length != 1 ||
        matches.single.name != name ||
        matches.single.description != description ||
        matches.single.relationship != relationship ||
        matches.single.alive != alive) {
      throw const FormatException('Ausgewählter NPC wurde verändert.');
    }
  }
}
