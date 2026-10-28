import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/sneak_attack_ally_rules.dart';
import '../domain/two_weapon_fighting_rules.dart';
import '../domain/condition_rules.dart';
import '../domain/srd_opportunity_attack_rules.dart';
import '../data/srd_spell_catalog_loader.dart';
import '../domain/campaign_experience.dart';
import '../domain/rabenwacht_campaign.dart';
import '../domain/damage_rules.dart';
import '../domain/magic_missile_rules.dart';
import '../domain/fire_bolt_rules.dart';
import '../domain/sacred_flame_rules.dart';
import '../domain/acid_splash_rules.dart';
import '../domain/healing_spell_rules.dart';
import '../domain/saving_throw_class_actions.dart';
import '../domain/class_resource_rules.dart';
import '../domain/srd_terrain_movement_rules.dart';
import '../domain/prone_movement_rules.dart';
import '../domain/monk_flurry_rules.dart';
import '../domain/monk_self_restoration.dart';
import '../services/backup_files.dart';
import '../services/game_controller.dart';
import '../services/player_action_outbox.dart';
import '../services/voice_controller.dart';
import 'app_build_info.dart';
import 'backend_settings_panel.dart';
import 'backup_dialogs.dart';
import 'character_editor.dart';
import 'character_effect_dialog.dart';
import 'condition_effect_dialog.dart';
import 'sneak_attack_ally_dialog.dart';
import 'offhand_attack_dialog.dart';
import 'opportunity_movement_dialog.dart';
import 'confirmed_spell_effect_dialog.dart';
import 'sending_attempt_dialog.dart';
import 'experience_reward_dialog.dart';
import 'hero_shield_reaction_dialog.dart';
import 'monk_slow_fall_dialog.dart';
import '../domain/hero_shield_reaction_rules.dart';
import 'magic_missile_dialog.dart';
import 'fire_bolt_dialog.dart';
import 'sacred_flame_dialog.dart';
import 'acid_splash_dialog.dart';
import 'area_creature_registration_dialog.dart';
import 'srd_fireball_grid_preview_dialog.dart';
import 'tracked_creature_initiative_dialog.dart';
import 'manual_turn_queue_dialog.dart';
import 'manual_extra_creature_attack_dialog.dart';
import 'healing_spell_dialog.dart';
import 'death_save_decision_panel.dart';
import 'fantasy_character_sheet.dart';
import 'fantasy_ui.dart';
import 'fantasy_buttons.dart';
import 'fantasy_art.dart';
import 'fantasy_experience.dart';
import 'fantasy_campaign_dashboard.dart';
import 'fantasy_adventure_hud.dart';
import 'fantasy_combatant_card.dart';
import 'fantasy_combat_status.dart';
import 'fantasy_effect_ward.dart';
import 'fantasy_combat_turn_tracker.dart';
import 'fantasy_combat_threat_status.dart';
import 'fantasy_combat_chronicle.dart';
import 'character_portrait_picker.dart';
import 'campaign_memory_panel.dart';

const _gold = Color(0xffddb96c);
const _ink = Color(0xff0d1927);
const _srdAttribution =
    'This work includes material from the System Reference Document 5.2.1 '
    '(“SRD 5.2.1”) by Wizards of the Coast LLC, available at '
    'https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the '
    'Creative Commons Attribution 4.0 International License, available at '
    'https://creativecommons.org/licenses/by/4.0/legalcode.';

ThemeData fantasyTheme() => buildFantasyTheme();

class LivingGameApp extends StatefulWidget {
  const LivingGameApp({
    super.key,
    required this.controller,
    required this.voice,
    this.backupFiles,
  });
  final GameController controller;
  final VoiceController voice;
  final BackupFiles? backupFiles;

  @override
  State<LivingGameApp> createState() => _LivingGameAppState();
}

class _LivingGameAppState extends State<LivingGameApp> {
  int _page = 0;
  late final BackupFiles _backupFiles;

  @override
  void initState() {
    super.initState();
    _backupFiles = widget.backupFiles ?? AndroidBackupFiles();
  }

  Future<void> _run(Future<void> Function() action, {bool play = false}) async {
    await action();
    if (!mounted) return;
    if (play &&
        widget.controller.error == null &&
        widget.controller.currentCampaign != null) {
      setState(() => _page = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Würfelraunen – Der lebendige Spielleiter',
      debugShowCheckedModeBanner: false,
      theme: fantasyTheme(),
      home: AnimatedBuilder(
        animation: Listenable.merge([
          widget.controller,
          widget.voice,
          widget.controller.narrator,
        ]),
        builder: (context, _) {
          final controller = widget.controller;
          final pages = <Widget>[
            _HomePage(
              controller: controller,
              backupFiles: _backupFiles,
              onPlay: (action) => _run(action, play: true),
              onCharacters: () => setState(() => _page = 2),
              onAdventure: () => setState(() => _page = 1),
              onJournal: () => setState(() => _page = 3),
            ),
            _AdventurePage(
              controller: controller,
              backupFiles: _backupFiles,
              voice: widget.voice,
              onHome: () => setState(() => _page = 0),
              onJournal: () => setState(() => _page = 3),
            ),
            _CharactersPage(controller: controller, backupFiles: _backupFiles),
            _JournalPage(controller: controller),
            _SettingsPage(
              controller: controller,
              voice: widget.voice,
              backupFiles: _backupFiles,
            ),
          ];
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  FantasySelectedNavigationRune(
                    key: const ValueKey('fantasy-appbar-rune'),
                    rune: switch (_page) {
                      0 => FantasyRune.compass,
                      1 => FantasyRune.dice,
                      2 => FantasyRune.hero,
                      3 => FantasyRune.tome,
                      _ => FantasyRune.moon,
                    },
                    size: 30,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      const [
                        'WÜRFELRAUNEN',
                        'Abenteuer',
                        'Deine Helden',
                        'Kampagnen-Tagebuch',
                        'Einstellungen',
                      ][_page],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: FantasyPalette.gold),
                    ),
                  ),
                ],
              ),
              actions: [
                if (controller.busy)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                FantasyIconButton(
                  tooltip: 'Einstellungen',
                  onPressed: () => setState(() => _page = 4),
                  icon: Icons.settings_outlined,
                ),
              ],
            ),
            body: Row(
              children: [
                if (MediaQuery.sizeOf(context).width >= 920)
                  NavigationRail(
                    selectedIndex: _page,
                    onDestinationSelected: (value) =>
                        setState(() => _page = value),
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: FantasyRuneEmblem(
                        rune: FantasyRune.compass,
                        size: 42,
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: FantasyRuneEmblem(
                          rune: FantasyRune.compass,
                          size: 28,
                        ),
                        selectedIcon: FantasySelectedNavigationRune(
                          rune: FantasyRune.compass,
                          size: 32,
                        ),
                        label: Text('Start'),
                      ),
                      NavigationRailDestination(
                        icon: FantasyRuneEmblem(
                          rune: FantasyRune.dice,
                          size: 28,
                        ),
                        selectedIcon: FantasySelectedNavigationRune(
                          rune: FantasyRune.dice,
                          size: 32,
                        ),
                        label: Text('Abenteuer'),
                      ),
                      NavigationRailDestination(
                        icon: FantasyRuneEmblem(
                          rune: FantasyRune.hero,
                          size: 28,
                        ),
                        selectedIcon: FantasySelectedNavigationRune(
                          rune: FantasyRune.hero,
                          size: 32,
                        ),
                        label: Text('Helden'),
                      ),
                      NavigationRailDestination(
                        icon: FantasyRuneEmblem(
                          rune: FantasyRune.tome,
                          size: 28,
                        ),
                        selectedIcon: FantasySelectedNavigationRune(
                          rune: FantasyRune.tome,
                          size: 32,
                        ),
                        label: Text('Tagebuch'),
                      ),
                      NavigationRailDestination(
                        icon: FantasyRuneEmblem(
                          rune: FantasyRune.moon,
                          size: 28,
                        ),
                        selectedIcon: FantasySelectedNavigationRune(
                          rune: FantasyRune.moon,
                          size: 32,
                        ),
                        label: Text('Optionen'),
                      ),
                    ],
                  ),
                Expanded(
                  child: FantasyBackdrop(
                    scene: switch (_page) {
                      0 => FantasyBackdropScene.home,
                      1 => FantasyBackdropScene.adventure,
                      2 => FantasyBackdropScene.heroes,
                      3 => FantasyBackdropScene.journal,
                      _ => FantasyBackdropScene.settings,
                    },
                    child: SafeArea(
                      child: Column(
                        children: [
                          if (controller.error != null)
                            MaterialBanner(
                              content: Text(controller.error!),
                              leading: const Icon(Icons.error_outline),
                              actions: [
                                TextButton(
                                  onPressed: controller.clearError,
                                  child: const Text('Schließen'),
                                ),
                              ],
                            ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1100,
                                ),
                                child: pages[_page],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: MediaQuery.sizeOf(context).width >= 920
                ? null
                : Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0x55ddb96c))),
                    ),
                    child: NavigationBar(
                      selectedIndex: _page,
                      onDestinationSelected: (value) =>
                          setState(() => _page = value),
                      destinations: const [
                        NavigationDestination(
                          icon: FantasyRuneEmblem(
                            rune: FantasyRune.compass,
                            size: 26,
                          ),
                          selectedIcon: FantasySelectedNavigationRune(
                            rune: FantasyRune.compass,
                            size: 32,
                          ),
                          label: 'Start',
                        ),
                        NavigationDestination(
                          icon: FantasyRuneEmblem(
                            rune: FantasyRune.dice,
                            size: 26,
                          ),
                          selectedIcon: FantasySelectedNavigationRune(
                            rune: FantasyRune.dice,
                            size: 32,
                          ),
                          label: 'Abenteuer',
                        ),
                        NavigationDestination(
                          icon: FantasyRuneEmblem(
                            rune: FantasyRune.hero,
                            size: 26,
                          ),
                          selectedIcon: FantasySelectedNavigationRune(
                            rune: FantasyRune.hero,
                            size: 32,
                          ),
                          label: 'Helden',
                        ),
                        NavigationDestination(
                          icon: FantasyRuneEmblem(
                            rune: FantasyRune.tome,
                            size: 26,
                          ),
                          selectedIcon: FantasySelectedNavigationRune(
                            rune: FantasyRune.tome,
                            size: 32,
                          ),
                          label: 'Tagebuch',
                        ),
                        NavigationDestination(
                          icon: FantasyRuneEmblem(
                            rune: FantasyRune.moon,
                            size: 26,
                          ),
                          selectedIcon: FantasySelectedNavigationRune(
                            rune: FantasyRune.moon,
                            size: 32,
                          ),
                          label: 'Optionen',
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

typedef _Play = void Function(Future<void> Function());

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.controller,
    required this.onPlay,
    required this.onCharacters,
    required this.onAdventure,
    required this.onJournal,
    required this.backupFiles,
  });
  final BackupFiles backupFiles;
  final GameController controller;
  final _Play onPlay;
  final VoidCallback onCharacters;
  final VoidCallback onAdventure;
  final VoidCallback onJournal;

  Future<void> _newCampaign(
    BuildContext context, {
    bool ai = false,
    bool prepared = false,
  }) async {
    final hero = await showDialog<HeroCharacter>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Wähle deinen Helden'),
        children: [
          for (final hero in controller.characters)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, hero),
              child: ListTile(
                title: Text(hero.name),
                subtitle: Text(
                  '${hero.species} · ${hero.classSummary} · Stufe ${hero.level}',
                ),
                trailing: Icon(
                  hero.isComplete
                      ? Icons.check_circle_outline
                      : Icons.warning_amber,
                ),
              ),
            ),
          if (controller.characters.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Erstelle zuerst einen Charakter unter „Helden“ oder starte die fertige Demo.',
              ),
            ),
          FantasyTextButton(
            label: 'Schließen',
            style: FantasyButtonStyle.iron,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (hero == null || !context.mounted) return;
    if (prepared) {
      onPlay(() => controller.newRabenwachtCampaign(hero));
      return;
    }
    if (!ai) {
      onPlay(() => controller.newCampaign(hero));
      return;
    }
    var prompt =
        'Epische Fantasy mit Geheimnissen, lebendigen NPCs und moralischen Entscheidungen';
    final theme = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eigene KI-Geschichte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Der verbundene Erzähldienst entwickelt eine neue Geschichte. '
              'Jeder weitere KI-Zug zählt zum vereinbarten Anfragelimit. '
              'Die Geschichte bleibt lokal gespeichert.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: prompt,
              maxLength: 300,
              maxLines: 3,
              onChanged: (value) => prompt = value,
              decoration: const InputDecoration(labelText: 'Wunschthema'),
            ),
          ],
        ),
        actions: [
          FantasyTextButton(
            label: 'Abbrechen',
            style: FantasyButtonStyle.iron,
            onPressed: () => Navigator.pop(context),
          ),
          FantasyTextButton(
            label: 'Geschichte erstellen',
            icon: Icons.auto_awesome_outlined,
            style: FantasyButtonStyle.arcane,
            onPressed: () => Navigator.pop(context, prompt),
          ),
        ],
      ),
    );
    if (theme != null && theme.trim().isNotEmpty) {
      onPlay(() => controller.newAiCampaign(hero, theme: theme.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current =
        controller.currentCampaign ??
        (controller.campaigns.isEmpty ? null : controller.campaigns.first);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const FantasyBrandPlaque(),
        const SizedBox(height: 12),
        FantasyIllustratedBanner(
          key: const ValueKey('home-illustrated-banner'),
          image: FantasyArtwork.ruins,
          eyebrow: current == null
              ? 'Würfelraunen · Deine Reise beginnt'
              : 'Kampagne fortsetzen',
          title: current?.name ?? 'Deine Geschichte wartet.',
          description: current == null
              ? 'Erkunde geheimnisvolle Welten und entscheide selbst, wohin dein Abenteuer führt.'
              : current.scene,
          actionLabel: current == null
              ? 'Kostenlose Demo starten'
              : 'Fortsetzen',
          onPressed: controller.busy
              ? null
              : () => current == null
                    ? onPlay(controller.createDemo)
                    : onPlay(() => controller.openCampaign(current.id)),
        ),
        if (current != null) ...[
          const FantasyChapterHeading(
            label: 'Dein Held am Spieltisch',
            rune: FantasyRune.hero,
          ),
          FantasyActiveHeroCard(
            hero: current.hero,
            campaignName: current.name,
            onContinue: controller.busy
                ? null
                : () => onPlay(() => controller.openCampaign(current.id)),
            onHeroes: onCharacters,
          ),
          const SizedBox(height: 14),
        ],
        const FantasyChapterHeading(
          label: 'Wähle deinen Weg',
          rune: FantasyRune.compass,
          description: 'Vier Wege führen zurück an deinen Spieltisch.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 660
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: FantasyJourneyCard(
                    title: 'Neues Abenteuer',
                    description: 'Erschaffe eine eigene Geschichte.',
                    image: FantasyArtwork.shadowForest,
                    rune: FantasyRune.dice,
                    onTap: controller.busy ? null : () => _newCampaign(context),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: FantasyJourneyCard(
                    title: 'Rabenwacht',
                    description: 'Das Soloabenteuer für 2–3 Stunden.',
                    image: FantasyArtwork.ruins,
                    rune: FantasyRune.compass,
                    accent: FantasyPalette.blue,
                    onTap: controller.busy
                        ? null
                        : () => _newCampaign(context, prepared: true),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: FantasyJourneyCard(
                    title: 'Heldenarchiv',
                    description: 'Charaktere und Porträts verwalten.',
                    image: FantasyArtwork.castle,
                    rune: FantasyRune.hero,
                    onTap: onCharacters,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: FantasyJourneyCard(
                    title: 'Abenteuerchronik',
                    description: 'Erinnerungen, Aufträge und Ereignisse.',
                    image: FantasyArtwork.forgottenWoods,
                    rune: FantasyRune.tome,
                    accent: FantasyPalette.success,
                    onTap: onJournal,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        FantasyPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FantasyRuneEmblem(rune: FantasyRune.dice, size: 46),
              const SizedBox(height: 12),
              Text(
                'Dein Spieltisch',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Erkunde vergessene Tempel, begegne wundersamen Wesen und '
                'entscheide selbst, wohin dein Abenteuer führt. Dein bestätigter Spielstand bleibt erhalten.',
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FantasyTextButton(
                    label: 'Demo erneut starten',
                    icon: Icons.play_arrow,
                    style: FantasyButtonStyle.woodGold,
                    onPressed: controller.busy
                        ? null
                        : () => onPlay(controller.createDemo),
                  ),
                  FantasyTextButton(
                    key: const ValueKey('start-rabenwacht-campaign'),
                    label: 'Rabenwacht (Solo, 2–3 Std.)',
                    icon: Icons.menu_book_outlined,
                    style: FantasyButtonStyle.woodGold,
                    onPressed: controller.busy
                        ? null
                        : () => _newCampaign(context, prepared: true),
                  ),
                  FantasyTextButton(
                    label: 'Neue Kampagne',
                    icon: Icons.add,
                    onPressed: controller.busy
                        ? null
                        : () => _newCampaign(context),
                  ),
                  FantasyTextButton(
                    label: controller.narrator.provider == 'mock'
                        ? 'Testgeschichte starten'
                        : 'KI-Kampagne erstellen',
                    icon: Icons.auto_awesome,
                    style: FantasyButtonStyle.arcane,
                    onPressed: controller.busy || !controller.narrator.enabled
                        ? null
                        : () => _newCampaign(context, ai: true),
                  ),
                  FantasyTextButton(
                    label: 'Helden verwalten',
                    icon: Icons.person_add_alt,
                    style: FantasyButtonStyle.iron,
                    onPressed: onCharacters,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const FantasyChapterHeading(
          label: 'Schnellzugriff',
          rune: FantasyRune.dice,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FantasyShortcutTile(
                label: 'Neues Abenteuer',
                approvedIconIndex: 1,
                icon: Icons.sports_martial_arts,
                color: FantasyPalette.danger,
                onTap: controller.busy ? null : () => _newCampaign(context),
              ),
              const SizedBox(width: 9),
              FantasyShortcutTile(
                label: 'Helden',
                approvedIconIndex: 0,
                icon: Icons.groups_outlined,
                color: FantasyPalette.gold,
                onTap: onCharacters,
              ),
              const SizedBox(width: 9),
              FantasyShortcutTile(
                label: 'Chronik',
                approvedIconIndex: 6,
                icon: Icons.menu_book_outlined,
                color: FantasyPalette.blue,
                onTap: onJournal,
              ),
              const SizedBox(width: 9),
              FantasyShortcutTile(
                label: 'Weiterspielen',
                approvedIconIndex: 3,
                icon: Icons.auto_stories_outlined,
                color: const Color(0xffbc8dde),
                onTap: current == null ? null : onAdventure,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!controller.narrator.enabled)
          const _Notice(
            icon: Icons.auto_awesome_outlined,
            text:
                'Für eine frei entwickelte KI-Kampagne zuerst unter „Optionen“ '
                'einen Spielleiter-Server verbinden und bei Bedarf ausdrücklich '
                'den kostenpflichtigen KI-Anbieter freigeben. Ohne Server bleibt die Demo verfügbar.',
          ),
        if (controller.narrator.enabled &&
            controller.narrator.provider == 'mock')
          const _Notice(
            icon: Icons.science_outlined,
            text:
                'Der verbundene Mock-Dienst erzeugt nur eine regelbasierte Testgeschichte. '
                'Für eine wirklich generierte Geschichte ist der OpenAI-Anbieter erforderlich.',
          ),
        const _Notice(
          icon: Icons.offline_bolt_outlined,
          text:
              'Demo-Modus: Die lokale Erzähl- und Regelengine benötigt weder API-Schlüssel '
              'noch kostenpflichtigen Dienst. Die Antworten sind regelbasierte Szenen. '
              'Spracherkennung kann je nach Android-Dienst eine Internetverbindung benötigen.',
        ),
        const SizedBox(height: 16),
        const FantasyChapterHeading(
          label: 'Deine Kampagnen',
          rune: FantasyRune.tome,
        ),
        const SizedBox(height: 12),
        if (controller.campaigns.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Noch keine Kampagne gespeichert. Die Demo enthält einen fertigen Helden und ein eigenes Abenteuer.',
              ),
            ),
          ),
        for (var index = 0; index < controller.campaigns.length; index++)
          Builder(
            builder: (context) {
              final campaign = controller.campaigns[index];
              return FantasyCampaignCard(
                key: ValueKey('illustrated-campaign-${campaign.id}'),
                name: campaign.name,
                detail:
                    '${campaign.world} · ${campaign.hero.name}\n${campaign.scene}',
                image: FantasyArtwork.campaign(index),
                accent: index % 3 == 1
                    ? FantasyPalette.danger
                    : index % 3 == 2
                    ? FantasyPalette.success
                    : FantasyPalette.gold,
                onTap: controller.busy
                    ? null
                    : () => onPlay(() => controller.openCampaign(campaign.id)),
                onDelete: controller.busy
                    ? null
                    : () async {
                        if (await _confirmDelete(
                              context,
                              '„${campaign.name}“ unwiderruflich löschen?',
                            ) ==
                            true) {
                          await controller.deleteCampaign(campaign.id);
                        }
                      },
              );
            },
          ),
        const SizedBox(height: 20),
        FantasyTextButton(
          label: 'Kampagne aus JSON importieren',
          style: FantasyButtonStyle.iron,
          icon: Icons.file_upload_outlined,
          onPressed: controller.busy
              ? null
              : () async {
                  final json = await _importText(
                    context,
                    'Kampagne importieren',
                    backupFiles,
                  );
                  if (context.mounted && json != null) {
                    onPlay(() => controller.importCampaign(json));
                  }
                },
        ),
      ],
    );
  }
}

class _CharactersPage extends StatelessWidget {
  const _CharactersPage({required this.controller, required this.backupFiles});
  final GameController controller;
  final BackupFiles backupFiles;

  Future<void> _edit(BuildContext context, HeroCharacter? hero) async {
    final result = await Navigator.of(context).push<HeroCharacter>(
      MaterialPageRoute(
        builder: (context) =>
            CharacterEditor(hero: hero, autoFillExistingCombatValues: true),
      ),
    );
    if (result != null) await controller.saveStandaloneHero(result);
  }

  Future<void> _showSheet(BuildContext context, HeroCharacter hero) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (sheetContext) => CharacterSheetPage(
          hero: hero,
          onEdit: controller.busy
              ? null
              : () async {
                  Navigator.of(sheetContext).pop();
                  if (context.mounted) await _edit(context, hero);
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const FantasyIllustratedBanner(
          image: FantasyArtwork.castle,
          eyebrow: 'Heldenchronik',
          title: 'Deine Helden',
          description:
              'Bewahre die Geschichten deiner Charaktere und führe ihre Abenteuer fort.',
          icon: Icons.shield_outlined,
          height: 145,
        ),
        const SizedBox(height: 17),
        const FantasyChapterHeading(
          label: 'Heldenarchiv',
          rune: FantasyRune.hero,
          description: 'Charaktere ansehen, bearbeiten und sicher verwalten.',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            FantasyTextButton(
              label: 'Charakter erstellen',
              icon: Icons.person_add_alt_1,
              style: FantasyButtonStyle.woodGold,
              onPressed: controller.busy ? null : () => _edit(context, null),
            ),
            FantasyTextButton(
              label: 'Importieren',
              icon: Icons.file_upload_outlined,
              style: FantasyButtonStyle.iron,
              onPressed: controller.busy
                  ? null
                  : () async {
                      final json = await _importText(
                        context,
                        'Charakter importieren',
                        backupFiles,
                      );
                      if (context.mounted && json != null) {
                        await controller.importHero(json);
                      }
                    },
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (controller.characters.isEmpty)
          const _Empty(
            icon: Icons.person_outline,
            title: 'Hier beginnt dein Held.',
            text:
                'Erstelle deinen eigenen Charakter oder starte die Demo mit einem vorbereiteten Waldläufer.',
          ),
        for (final hero in controller.characters)
          FantasyPanel(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (hero.portraitPreset >= 0 ||
                          hero.portraitPhotoBase64.isNotEmpty)
                        FantasyCharacterPortrait(
                          key: ValueKey('list-hero-portrait-${hero.id}'),
                          preset: hero.portraitPreset,
                          photoBase64: hero.portraitPhotoBase64,
                          name: hero.name,
                          size: 70,
                        )
                      else
                        FantasyHeroMedallion(name: hero.name),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hero.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${hero.species} · ${hero.classSummary} · Stufe ${hero.level}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HeroStats(hero: hero),
                  if (!hero.isComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Noch zu bestätigen: ${hero.incompleteFields.join(', ')}',
                        style: const TextStyle(color: _gold),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      FantasyTextButton(
                        key: ValueKey('open-character-sheet-${hero.id}'),
                        label: 'Bogen ansehen',
                        icon: Icons.auto_stories_outlined,
                        style: FantasyButtonStyle.woodGold,
                        onPressed: () => _showSheet(context, hero),
                      ),
                      FantasyTextButton(
                        label: 'Bearbeiten',
                        icon: Icons.edit_outlined,
                        style: FantasyButtonStyle.iron,
                        onPressed: controller.busy
                            ? null
                            : () => _edit(context, hero),
                      ),
                      FantasyTextButton(
                        label: 'Exportieren',
                        icon: Icons.file_download_outlined,
                        style: FantasyButtonStyle.iron,
                        onPressed: () => _showExport(
                          context,
                          '${hero.name} exportieren',
                          controller.exportHero(hero),
                          backupFiles,
                          backupFileName(hero.name, kind: 'charakter'),
                        ),
                      ),
                      FantasyTextButton(
                        label: 'Löschen',
                        icon: Icons.delete_outline,
                        style: FantasyButtonStyle.wax,
                        onPressed: controller.busy
                            ? null
                            : () async {
                                if (await _confirmDelete(
                                      context,
                                      'Charakter „${hero.name}“ löschen? '
                                      'Bereits gespeicherte Kampagnen behalten ihren Charakterbogen.',
                                    ) ==
                                    true) {
                                  await controller.deleteCharacter(hero.id);
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AdventurePage extends StatefulWidget {
  const _AdventurePage({
    required this.controller,
    required this.voice,
    required this.onHome,
    required this.onJournal,
    required this.backupFiles,
  });
  final BackupFiles backupFiles;
  final GameController controller;
  final VoiceController voice;
  final VoidCallback onHome;
  final VoidCallback onJournal;

  @override
  State<_AdventurePage> createState() => _AdventurePageState();
}

class _AdventurePageState extends State<_AdventurePage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final PlayerActionOutbox _outbox;
  PendingPlayerAction? _pendingAction;
  String? _loadedCampaignId;
  String? _outboxError;
  bool _outboxReady = false;
  Future<void>? _loadingOutbox;
  bool _submittingAction = false;
  bool _sendingInFlight = false;
  bool _combat = false;

  bool get _ruleInteractionBlocked =>
      widget.controller.busy ||
      widget.controller.currentCampaign?.pendingOpportunityAttack != null;

  bool get _canInteract =>
      _pendingAction == null && !_submittingAction && !_ruleInteractionBlocked;

  @override
  void initState() {
    super.initState();
    _outbox = PlayerActionOutbox(widget.controller.repository);
    _loadPending();
  }

  @override
  void didUpdateWidget(covariant _AdventurePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_loadedCampaignId != widget.controller.currentCampaign?.id) {
      _loadPending();
    }
  }

  void _loadPending() {
    final campaignId = widget.controller.currentCampaign?.id;
    _loadedCampaignId = campaignId;
    _outboxReady = campaignId == null;
    _pendingAction = null;
    _outboxError = null;
    if (campaignId == null) {
      _loadingOutbox = null;
      return;
    }
    _loadingOutbox = _outbox
        .pendingFor(campaignId)
        .then((action) {
          if (!mounted || _loadedCampaignId != campaignId) return;
          setState(() {
            _pendingAction = action;
            _outboxReady = true;
          });
        })
        .catchError((Object failure) {
          if (!mounted || _loadedCampaignId != campaignId) return;
          setState(() {
            _outboxError = 'Ausstehende Handlung konnte nicht geladen werden.';
            _outboxReady =
                false; // Fail closed: never overwrite an unknown intent.
          });
        });
  }

  @override
  void dispose() {
    unawaited(widget.voice.stopListening());
    unawaited(widget.voice.stopSpeaking());
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Typed text, reviewed speech, combat and fixed shortcuts all stage the
  // exact intent before the shared authoritative controller can execute it.
  Future<void> _send({String? quickAction}) async {
    final text = (quickAction ?? _input.text).trim();
    final campaign = widget.controller.currentCampaign;
    if (text.isEmpty || campaign == null || !_canInteract) return;
    setState(() {
      _submittingAction = true;
      _outboxError = null;
    });
    try {
      // A tap during loading must wait for the saved command.
      await _loadingOutbox;
      if (!_outboxReady ||
          _pendingAction != null ||
          widget.controller.currentCampaign?.id != campaign.id) {
        return;
      }
      final action = await _outbox.stage(campaign.id, text);
      if (!mounted) return; // Durable action survives disposed page.
      setState(() => _pendingAction = action);
      await _dispatch(action, clearDraft: quickAction == null);
    } catch (_) {
      if (mounted) {
        setState(
          () => _outboxError =
              'Die Handlung konnte nicht sicher vorgemerkt oder abgeschlossen werden.',
        );
      }
    } finally {
      if (mounted) setState(() => _submittingAction = false);
    }
  }

  Future<void> _dispatch(
    PendingPlayerAction action, {
    bool clearDraft = false,
  }) async {
    if (widget.controller.currentCampaign?.id != action.campaignId) return;
    await widget.voice.stopListening();
    await widget.voice.stopSpeaking();
    final previousMessageId = _lastMessageId;
    await widget.controller.sendAction(
      action.text,
      requestId: action.requestId,
    );
    if (!mounted || widget.controller.error != null) return;
    // Success also includes replay of an already committed request.
    await _outbox.remove(action);
    if (!mounted) return;
    setState(() {
      _pendingAction = null;
      _outboxError = null;
    });
    if (clearDraft && _input.text.trim() == action.text) _input.clear();
    await _afterTurn(previousMessageId);
  }

  Future<void> _retryPending() async {
    final action = _pendingAction;
    if (action == null ||
        !_outboxReady ||
        _submittingAction ||
        _ruleInteractionBlocked) {
      return;
    }
    setState(() {
      _submittingAction = true;
      _outboxError = null;
    });
    try {
      // Never generate a second request ID during a retry.
      await _dispatch(action);
    } catch (_) {
      if (mounted) {
        setState(
          () => _outboxError =
              'Die Handlung bleibt vorgemerkt. Du kannst sie erneut bestätigen.',
        );
      }
    } finally {
      if (mounted) setState(() => _submittingAction = false);
    }
  }

  Future<void> _discardPending() async {
    final action = _pendingAction;
    if (action == null || _submittingAction || _ruleInteractionBlocked) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Handlung verwerfen?'),
        content: const Text(
          'Dies entfernt nur den ausstehenden Sendeauftrag. '
          'Eine bereits gespeicherte Handlung wird nicht rückgängig gemacht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Auftrag verwerfen'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    setState(() => _submittingAction = true);
    try {
      await _outbox.remove(action);
      if (mounted) {
        setState(() {
          _pendingAction = null;
          _outboxError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _outboxError =
              'Der Sendeauftrag konnte nicht sicher entfernt werden.',
        );
      }
    } finally {
      if (mounted) setState(() => _submittingAction = false);
    }
  }

  Future<void> _recap() =>
      _send(quickAction: 'Fasse unsere bisherige Geschichte zusammen.');

  String? get _lastMessageId {
    final messages = widget.controller.currentCampaign?.messages;
    return messages == null || messages.isEmpty ? null : messages.last.id;
  }

  Future<void> _afterTurn(String? previousMessageId) async {
    if (!mounted || widget.controller.error != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
    final campaign = widget.controller.currentCampaign;
    if (widget.voice.autoSpeak &&
        campaign != null &&
        campaign.messages.isNotEmpty) {
      final message = campaign.messages.last;
      if (message.role == 'gm' && message.id != previousMessageId) {
        await widget.voice.speak(message.text);
      }
    }
  }

  Future<void> _toggleMic() async {
    if (widget.voice.listening) {
      await widget.voice.stopListening();
    } else {
      await widget.voice.stopSpeaking();
      await widget.voice.startListening((text) {
        if (mounted) {
          setState(() {
            _input.text = text;
            _input.selection = TextSelection.collapsed(offset: text.length);
          });
        }
      });
    }
  }

  Future<void> _roll() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null) return;
    final json = campaign.toJson();
    final pending = _map(json['pendingRoll']);
    if (pending.isEmpty) {
      final expression = await showDialog<String>(
        context: context,
        builder: (context) => const _FreeDiceDialog(),
      );
      if (expression != null) {
        final previousMessageId = _lastMessageId;
        await widget.controller.rollDice(expression);
        if (mounted) await _afterTurn(previousMessageId);
      }
      return;
    }
    final result = await showDialog<_ManualRoll>(
      context: context,
      builder: (context) => _RollDialog(pending: pending),
    );
    if (result == null) return;
    await widget.voice.stopSpeaking();
    final previousMessageId = _lastMessageId;
    await widget.controller.resolveRoll(
      natural: result.natural,
      total: result.total,
    );
    if (mounted) await _afterTurn(previousMessageId);
  }

  Future<void> _prepareOffhandAttack() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null ||
        !_canInteract ||
        !_outboxReady ||
        !TwoWeaponFightingRules.canPrepare(campaign)) {
      return;
    }
    final choice = await showDialog<OffhandAttackChoice>(
      context: context,
      builder: (_) => OffhandAttackDialog(
        hero: campaign.hero,
        targetName: campaign.encounter!.enemyName,
      ),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.prepareOffhandAttack(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      weaponId: choice.weaponId,
      attackAbility: choice.attackAbility,
      weaponProficient: choice.weaponProficient,
      weaponsHeldConfirmed: choice.weaponsHeldConfirmed,
      playerConfirmed: choice.playerConfirmed,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _confirmSneakAttackAlly() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null ||
        !_canInteract ||
        !SneakAttackAllyRules.canPrepare(campaign)) {
      return;
    }
    final pending = campaign.pendingRoll!;
    final choice = await showDialog<SneakAttackAllyChoice>(
      context: context,
      builder: (_) => SneakAttackAllyDialog(
        targetName: pending.targetName.isNotEmpty
            ? pending.targetName
            : campaign.encounter!.enemyName,
      ),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.confirmSneakAttackAlly(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      rollId: pending.id,
      allyName: choice.allyName,
      withinFiveFeetOfTargetConfirmed: choice.withinFiveFeetOfTargetConfirmed,
      notIncapacitatedConfirmed: choice.notIncapacitatedConfirmed,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _clearSneakAttackAlly() async {
    final campaign = widget.controller.currentCampaign;
    final pending = campaign?.pendingRoll;
    if (campaign == null || pending?.sneakAttackAlly == null || !_canInteract) {
      return;
    }
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.clearSneakAttackAlly(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      rollId: pending!.id,
    );
    if (mounted) await _afterTurn(previous);
  }

  /// The dialog reviews a pure Sending preview. The authoritative resource
  /// charge and event journal belong exclusively to the controller.
  Future<void> _confirmSendingAttempt() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null ||
        !_canInteract ||
        !_outboxReady ||
        _sendingInFlight ||
        campaign.pendingRoll != null ||
        campaign.pendingDeathSave != null ||
        campaign.pendingEnemyShieldHit != null ||
        (campaign.encounter != null && !campaign.encounter!.isFinished)) {
      return;
    }
    setState(() => _sendingInFlight = true);
    try {
      final catalog = await SrdSpellCatalogLoader.load();
      if (!mounted || widget.controller.currentCampaign?.id != campaign.id) {
        return;
      }
      final sending = catalog.find('Sending');
      if (sending == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SRD-Sending ist nicht verfügbar.')),
        );
        return;
      }
      final choice = await showDialog<SendingAttemptChoice>(
        context: context,
        builder: (_) =>
            SendingAttemptDialog(hero: campaign.hero, sending: sending),
      );
      if (choice == null || !mounted) return;
      if (widget.controller.currentCampaign?.id != campaign.id ||
          widget.controller.currentCampaign?.revision != campaign.revision) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Der Spielstand wurde geändert. Sending bitte neu prüfen.',
            ),
          ),
        );
        return;
      }
      final previousMessageId = _lastMessageId;
      await widget.voice.stopSpeaking();
      await widget.controller.confirmSendingAttempt(
        campaignId: campaign.id,
        expectedRevision: campaign.revision,
        preview: choice.preview,
        requestId: choice.requestId,
        playerConfirmed: true,
      );
      if (!mounted) return;
      if (widget.controller.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.controller.error!)));
        return;
      }
      final saved = widget.controller.currentCampaign;
      final confirmed =
          saved != null &&
          saved.id == campaign.id &&
          saved.events.any(
            (event) =>
                event.type == 'spell.sending.attemptConfirmed' &&
                event.payload['actionRequestId'] == choice.requestId &&
                event.payload['recipientId'] ==
                    choice.preview.recipient.recipientId &&
                event.payload['message'] == choice.preview.recipient.message &&
                event.payload['deliveryNotPerformed'] == true,
          );
      if (!confirmed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: ValueKey('sending-attempt-receipt'),
          content: Text(
            'Sending-Versuch und Zauberplatz gespeichert. '
            'Eine Nachricht wurde nicht zugestellt.',
          ),
        ),
      );
      await _afterTurn(previousMessageId);
    } finally {
      if (mounted) setState(() => _sendingInFlight = false);
    }
  }

  Future<void> _confirmExperienceReward() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || !_canInteract) return;
    final choice = await showDialog<ExperienceRewardChoice>(
      context: context,
      builder: (_) => ExperienceRewardDialog(campaign: campaign),
    );
    if (choice == null || !mounted) return;
    final previousMessageId = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.confirmExperienceReward(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      rewardId: choice.rewardId,
      amount: choice.amount,
      requestId: choice.requestId,
      playerConfirmed: true,
    );
    if (!mounted || widget.controller.error != null) return;
    final saved = widget.controller.currentCampaign;
    final confirmed =
        saved != null &&
        saved.events.any(
          (event) =>
              event.type == 'xp.reward.confirmed' &&
              event.payload['actionRequestId'] == choice.requestId &&
              event.payload['rewardId'] == choice.rewardId &&
              event.payload['amount'] == choice.amount,
        );
    if (!confirmed) return; // Never show a success notice without a receipt.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const ValueKey('xp-reward-receipt'),
        content: Text(
          'Bestätigte EP-Belohnung gespeichert. Neuer Stand: ${saved.hero.experience} EP.',
        ),
      ),
    );
    await _afterTurn(previousMessageId);
  }

  Future<void> _confirmCharacterEffect() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || _ruleInteractionBlocked) return;
    final choice = await showDialog<CharacterEffectChoice>(
      context: context,
      builder: (_) => CharacterEffectDialog(hero: campaign.hero),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    switch (choice.kind) {
      case CharacterEffectKind.damage:
        await widget.controller.applyDamage(
          campaignId: campaign.id,
          expectedRevision: campaign.revision,
          source: choice.source,
          components: [DamageComponent(choice.damageType, choice.amount)],
          defenses: DamageDefenses(
            resistances: choice.resistant ? [choice.damageType] : [],
            vulnerabilities: choice.vulnerable ? [choice.damageType] : [],
            immunities: choice.immune ? [choice.damageType] : [],
          ),
          critical: choice.critical,
        );
      case CharacterEffectKind.healing:
        await widget.controller.applyHealing(
          campaignId: campaign.id,
          expectedRevision: campaign.revision,
          source: choice.source,
          amount: choice.amount,
        );
      case CharacterEffectKind.temporaryHitPoints:
        await widget.controller.grantTemporaryHitPoints(
          campaignId: campaign.id,
          expectedRevision: campaign.revision,
          source: choice.source,
          amount: choice.amount,
          replaceExisting: choice.replaceTemporary,
        );
    }
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _standUp() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || _ruleInteractionBlocked) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.standUp(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _crawl(int distanceFeet, bool difficultTerrain) async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || _ruleInteractionBlocked) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.crawl(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      distanceFeet: distanceFeet,
      difficultTerrain: difficultTerrain,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _confirmSlowFall() async {
    final campaign = widget.controller.currentCampaign;
    final encounter = campaign?.encounter;
    if (campaign == null ||
        encounter == null ||
        !_canInteract ||
        encounter.isFinished ||
        encounter.reactionUsed ||
        ClassResourceRules.level(campaign.hero, 'Mönch') < 4) {
      return;
    }
    final choice = await showDialog<ConfirmedSlowFallChoice>(
      context: context,
      builder: (_) =>
          MonkSlowFallDialog(hero: campaign.hero, encounter: encounter),
    );
    if (choice == null || !mounted) return;
    // The dialog keeps its original hero/encounter snapshot while it is open.
    // If another action changed the campaign, do not present the now-stale
    // confirmation as if it could be applied to the current state.
    final current = widget.controller.currentCampaign;
    if (!_canInteract ||
        current?.id != campaign.id ||
        current?.revision != campaign.revision ||
        current?.encounter?.id != encounter.id ||
        current?.encounter?.reactionUsed != encounter.reactionUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: ValueKey('slow-fall-stale-feedback'),
          content: Text(
            'Der Spielstand hat sich geändert. Sanften Fall bitte erneut öffnen.',
          ),
        ),
      );
      return;
    }
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    // Still pass the original revision and encounter. The controller's
    // authority check closes races that occur after this UI guard.
    await widget.controller.applyConfirmedSlowFall(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      encounterId: encounter.id,
      confirmedFallDamage: choice.damageAfterDefenses,
      fallConfirmed: true,
      playerConfirmedReaction: true,
      damageAfterOtherDefensesConfirmed: true,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _moveOnConfirmedTerrain(
    SrdTerrainMovement kind,
    int distanceFeet,
    bool difficultTerrain,
  ) async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || _ruleInteractionBlocked) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.moveOnConfirmedTerrain(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      kind: kind,
      distanceFeet: distanceFeet,
      difficultTerrain: difficultTerrain,
      terrainConfirmed: true,
      // Popup entries explicitly cover ordinary passable terrain, not
      // slippery walls, dangerous currents or an unresolved Athletics check.
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _manageConfirmedSpellEffects() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || _ruleInteractionBlocked) return;
    final choice = await showDialog<ConfirmedSpellEffectChoice>(
      context: context,
      builder: (_) => ConfirmedSpellEffectDialog(
        hero: campaign.hero,
        encounter: campaign.encounter,
      ),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    if (choice.isRemoval) {
      await widget.controller.removeConfirmedSpellEffect(
        campaignId: campaign.id,
        expectedRevision: campaign.revision,
        effectId: choice.effectId,
      );
    } else {
      await widget.controller.registerConfirmedSpellEffect(
        campaignId: campaign.id,
        expectedRevision: campaign.revision,
        spellName: choice.spellName,
        source: choice.source,
        concentrationBound: choice.concentrationBound,
        ownTurnEnds: choice.ownTurnEnds,
      );
    }
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _manageConditionEffects() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || _ruleInteractionBlocked) return;
    final choice = await showDialog<ConditionEffectChoice>(
      context: context,
      builder: (_) => ConditionEffectDialog(
        hero: campaign.hero,
        encounter: campaign.encounter,
      ),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    if (choice.isRemoval) {
      await widget.controller.removeConditionEffect(
        campaignId: campaign.id,
        expectedRevision: campaign.revision,
        effectId: choice.effectId,
      );
    } else {
      await widget.controller.applyConditionEffect(
        campaignId: campaign.id,
        expectedRevision: campaign.revision,
        source: choice.source,
        condition: choice.condition,
        duration: choice.duration,
      );
    }
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _decideDeathSave(
    Campaign campaign, {
    SavingThrowRerollFeature? feature,
  }) async {
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.resolveDeathSaveDecision(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      feature: feature,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _endTurnWithShield() async {
    final current = widget.controller.currentCampaign;
    if (current == null ||
        current.encounter == null ||
        _ruleInteractionBlocked ||
        current.hero.isDead) {
      return;
    }
    final plan = await showDialog<HeroShieldReactionPlan>(
      context: context,
      builder: (_) => HeroShieldReactionDialog(hero: current.hero),
    );
    if (plan == null || !mounted) return;
    final prior = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.endTurnWithShield(
      campaignId: current.id,
      expectedRevision: current.revision,
      plan: plan,
    );
    if (mounted) await _afterTurn(prior);
  }

  bool _canConfirmOpportunityMovement(Campaign campaign) {
    final fight = campaign.encounter;
    return !_ruleInteractionBlocked &&
        _outboxReady &&
        _pendingAction == null &&
        !_submittingAction &&
        fight != null &&
        !fight.isFinished &&
        fight.activeParticipant == 'enemy' &&
        !fight.reactionUsed &&
        campaign.pendingRoll == null &&
        campaign.pendingDeathSave == null &&
        campaign.pendingEnemyShieldHit == null &&
        campaign.hero.isComplete &&
        (campaign.hero.hitPoints ?? 0) > 0 &&
        ConditionRules.canTakeActions(campaign.hero);
  }

  Future<void> _confirmOpportunityMovement() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || !_canConfirmOpportunityMovement(campaign)) return;
    final trigger = await showDialog<ConfirmedOpportunityTrigger>(
      context: context,
      builder: (_) => OpportunityMovementDialog(campaign: campaign),
    );
    if (trigger == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.confirmOpportunityMovement(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      trigger: trigger,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _declineOpportunityAttack(Campaign campaign) async {
    final offer = campaign.pendingOpportunityAttack;
    if (offer == null || widget.controller.busy) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.declineOpportunityAttack(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      offerId: offer.id,
      playerConfirmed: true,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _decideEnemyShieldHit({required bool castShield}) async {
    final current = widget.controller.currentCampaign;
    if (current == null ||
        current.pendingEnemyShieldHit == null ||
        _ruleInteractionBlocked) {
      return;
    }
    HeroShieldReactionPlan? plan;
    if (castShield) {
      plan = await showDialog<HeroShieldReactionPlan>(
        context: context,
        builder: (_) => HeroShieldReactionDialog(hero: current.hero),
      );
      if (plan == null || !mounted) return;
    }
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.resolveEnemyShieldHit(
      campaignId: current.id,
      expectedRevision: current.revision,
      plan: plan,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _manualExtraCreatureAttack() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null ||
        campaign.encounter == null ||
        _ruleInteractionBlocked) {
      return;
    }
    final choice = await showDialog<ManualAttackChoice>(
      context: context,
      builder: (_) => ManualExtraCreatureAttackDialog(campaign: campaign),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.manualExtraCreatureAttack(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      attackerId: choice.attackerId,
      targetId: choice.targetId,
      attack: choice.attack,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _editManualTurnQueue() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null ||
        campaign.encounter == null ||
        _ruleInteractionBlocked) {
      return;
    }
    final choice = await showDialog<ManualTurnQueueChoice>(
      context: context,
      builder: (_) => ManualTurnQueueDialog(campaign: campaign),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    if (choice.advance) {
      await widget.controller.advanceManualTurnQueue(
        campaignId: campaign.id,
        expectedRevision: campaign.revision,
      );
    } else {
      await widget.controller.establishManualTurnQueue(
        campaignId: campaign.id,
        expectedRevision: campaign.revision,
        orderedActorIds: choice.actorIds,
        baseInitiativeConfirmed: choice.baseConfirmed,
        tiedOrderConfirmed: choice.tieConfirmed,
      );
    }
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _confirmAreaCreatureInitiative() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null ||
        campaign.encounter == null ||
        _ruleInteractionBlocked) {
      return;
    }
    final choice = await showDialog<ConfirmedInitiativeChoice>(
      context: context,
      builder: (_) => TrackedCreatureInitiativeDialog(campaign: campaign),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.controller.confirmAreaCreatureInitiative(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      creatureId: choice.creatureId,
      initiativeTotal: choice.total,
      initiativeController: choice.controller,
      initiativeConfirmed: true,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _showFireballGridPreview() async {
    // A planning-only tool: its result never writes campaign or character.
    final catalog = await SrdSpellCatalogLoader.load();
    if (!mounted) return;
    final fireball = catalog.find('Fireball');
    if (fireball == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SRD-Feuerball nicht verfügbar.')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => SrdFireballGridPreviewDialog(fireball: fireball),
    );
  }

  Future<void> _trackAreaCreature() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null ||
        campaign.encounter == null ||
        _ruleInteractionBlocked) {
      return;
    }
    final creature = await showDialog<TrackedAreaCreature>(
      context: context,
      builder: (_) => const AreaCreatureRegistrationDialog(),
    );
    if (creature == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.controller.trackAreaCreature(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      creatureId: creature.id,
      creatureName: creature.name,
      hitPoints: creature.hitPoints,
      maxHitPoints: creature.maxHitPoints,
      valuesConfirmed: true,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _castAcidSplash() async {
    final campaign = widget.controller.currentCampaign;
    final fight = campaign?.encounter;
    if (campaign == null || fight == null || _ruleInteractionBlocked) return;
    final choice = await showDialog<AcidSplashChoice>(
      context: context,
      builder: (_) => AcidSplashDialog(
        hero: campaign.hero,
        encounter: fight,
        trackedAreaCreatures: campaign.trackedAreaCreatures,
      ),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.castAcidSplash(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      castingClass: choice.castingClass,
      confirmedTargetDexteritySaveModifier: choice.targetDexteritySaveModifier,
      originWithin60FeetConfirmed: choice.originWithin60FeetConfirmed,
      currentEnemyIsOnlyCreatureInSphereConfirmed:
          choice.onlyCreatureInSphereConfirmed,
      verbalComponentConfirmed: choice.verbalConfirmed,
      somaticComponentConfirmed: choice.somaticConfirmed,
      noUnmodelledDcModifiersConfirmed: choice.noUnmodelledDcConfirmed,
      targetSaveCircumstancesConfirmed: choice.saveCircumstancesConfirmed,
      targetCoverRelationshipConfirmed: choice.coverRelationshipConfirmed,
      effectPathConfirmed: choice.effectPathConfirmed,
      noAcidDamageAdjustmentConfirmed: choice.noAcidDamageAdjustmentConfirmed,
      targetSourceOppositeCover: choice.sourceOppositeCover,
      targetSaveAdvantage: choice.saveAdvantage,
      targetSaveDisadvantage: choice.saveDisadvantage,
      additionalTargets: choice.additionalTargets,
      allCreaturesInSphereAccountedForConfirmed:
          choice.everyCreatureInSphereIncludedConfirmed,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _castSacredFlame() async {
    final campaign = widget.controller.currentCampaign;
    final fight = campaign?.encounter;
    if (campaign == null || fight == null || _ruleInteractionBlocked) return;
    final choice = await showDialog<SacredFlameChoice>(
      context: context,
      builder: (_) => SacredFlameDialog(hero: campaign.hero, encounter: fight),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.castSacredFlame(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      confirmedTargetDexteritySaveModifier:
          choice.confirmedTargetDexteritySaveModifier,
      targetVisibleConfirmed: choice.targetVisibleConfirmed,
      targetWithinRangeConfirmed: choice.targetWithinRangeConfirmed,
      verbalComponentConfirmed: choice.verbalComponentConfirmed,
      somaticComponentConfirmed: choice.somaticComponentConfirmed,
      noRadiantDamageAdjustmentConfirmed:
          choice.noRadiantDamageAdjustmentConfirmed,
      noUnmodelledDcModifiersConfirmed: choice.noUnmodelledDcModifiersConfirmed,
      saveCircumstancesConfirmed: choice.saveCircumstancesConfirmed,
      saveAdvantage: choice.saveAdvantage,
      saveDisadvantage: choice.saveDisadvantage,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _castFireBolt() async {
    final campaign = widget.controller.currentCampaign;
    final fight = campaign?.encounter;
    if (campaign == null || fight == null || _ruleInteractionBlocked) return;
    final choice = await showDialog<FireBoltChoice>(
      context: context,
      builder: (_) => FireBoltDialog(hero: campaign.hero, encounter: fight),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.castFireBolt(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      castingClass: choice.castingClass,
      targetVisibleConfirmed: choice.targetVisibleConfirmed,
      targetWithinRangeConfirmed: choice.targetWithinRangeConfirmed,
      verbalComponentConfirmed: choice.verbalComponentConfirmed,
      somaticComponentConfirmed: choice.somaticComponentConfirmed,
      noFireResistanceOrImmunityConfirmed:
          choice.noFireResistanceOrImmunityConfirmed,
      noUnresolvedShieldReactionConfirmed:
          choice.noUnresolvedShieldReactionConfirmed,
      situationalAttackConditionsConfirmed:
          choice.situationalAttackConditionsConfirmed,
      noUnmodelledAttackModifiersConfirmed:
          choice.noUnmodelledAttackModifiersConfirmed,
      advantage: choice.advantage,
      disadvantage: choice.disadvantage,
      targetProne: choice.targetProne,
      targetWithinFiveFeet: choice.targetWithinFiveFeet,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _castMagicMissile() async {
    final campaign = widget.controller.currentCampaign;
    final fight = campaign?.encounter;
    if (campaign == null || fight == null || _ruleInteractionBlocked) return;
    final choice = await showDialog<MagicMissileChoice>(
      context: context,
      builder: (_) => MagicMissileDialog(hero: campaign.hero, encounter: fight),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.castMagicMissile(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      castingClass: choice.castingClass,
      slotLevel: choice.slotLevel,
      pactMagic: choice.pactMagic,
      targetVisibleConfirmed: choice.targetVisibleConfirmed,
      targetWithinRangeConfirmed: choice.targetWithinRangeConfirmed,
      verbalComponentConfirmed: choice.verbalComponentConfirmed,
      somaticComponentConfirmed: choice.somaticComponentConfirmed,
      noProtectionConfirmed: choice.noProtectionConfirmed,
      confirmedForceDefense: choice.confirmedForceDefense,
      shieldReactionConfirmed: choice.shieldReactionConfirmed,
      shieldPreparedAndComponentsConfirmed:
          choice.shieldPreparedAndComponentsConfirmed,
      confirmedEnemyShieldSlots: choice.confirmedEnemyShieldSlots,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _castHealingSpell() async {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null || _ruleInteractionBlocked) return;
    final choice = await showDialog<HealingSpellChoice>(
      context: context,
      builder: (_) => HealingSpellDialog(hero: campaign.hero),
    );
    if (choice == null || !mounted) return;
    final previous = _lastMessageId;
    await widget.voice.stopSpeaking();
    await widget.controller.castHealingSpell(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      spellName: choice.spellName,
      castingClass: choice.castingClass,
      slotLevel: choice.slotLevel,
      pactMagic: choice.pactMagic,
      verbalComponentConfirmed: choice.verbalComponentConfirmed,
      somaticComponentConfirmed: choice.somaticComponentConfirmed,
    );
    if (mounted) await _afterTurn(previous);
  }

  Future<void> _editHero() async {
    if (_ruleInteractionBlocked) return;
    final hero = widget.controller.currentCampaign?.hero;
    if (hero == null) return;
    final result = await Navigator.of(context).push<HeroCharacter>(
      MaterialPageRoute(
        builder: (context) =>
            CharacterEditor(hero: hero, autoFillExistingCombatValues: true),
      ),
    );
    if (result != null) await widget.controller.saveHero(result);
  }

  Future<void> _showHeroSheet() async {
    final hero = widget.controller.currentCampaign?.hero;
    if (hero == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (sheetContext) => CharacterSheetPage(
          hero: hero,
          onRoll: () {
            Navigator.of(sheetContext).pop();
            if (mounted) _roll();
          },
          onEdit: _ruleInteractionBlocked
              ? null
              : () {
                  Navigator.of(sheetContext).pop();
                  if (mounted) _editHero();
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.controller.currentCampaign;
    if (campaign == null) {
      return _Empty(
        icon: Icons.auto_stories_outlined,
        title: 'Wähle dein Abenteuer.',
        text: 'Starte eine Demo oder setze eine gespeicherte Kampagne fort.',
        action: FilledButton(
          onPressed: widget.onHome,
          child: const Text('Zur Kampagnenauswahl'),
        ),
      );
    }
    final data = campaign.toJson();
    final pending = _map(data['pendingRoll']);
    final messages = _list(data['messages']);
    final encounter = _map(data['encounter']);
    final opportunityWeapons = campaign.hero.inventory
        .where((item) => item.id == campaign.pendingOpportunityAttack?.weaponId)
        .toList();
    // Scene details share the scroll area with the story so the composer remains
    // reachable on small screens while the software keyboard is open.
    final header = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FantasyPanel(
        material: FantasyPanelMaterial.leather,
        child: Column(
          children: [
            Row(
              children: [
                const FantasyRuneEmblem(rune: FantasyRune.compass, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${campaign.hero.name} · TP ${campaign.hero.hitPoints ?? '?'}/${campaign.hero.maxHitPoints ?? '?'} '
                        '· RK ${campaign.hero.armorClass ?? '?'} · Stufe ${campaign.hero.level}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FantasyIconButton(
                  key: const ValueKey('adventure-open-character-sheet'),
                  tooltip: 'Charakterbogen ansehen',
                  onPressed: _showHeroSheet,
                  icon: Icons.auto_stories_outlined,
                ),
                FantasyIconButton(
                  onPressed: () => _showExport(
                    context,
                    'Spielstand exportieren',
                    widget.controller.exportCampaign(),
                    widget.backupFiles,
                    backupFileName(campaign.name),
                  ),
                  tooltip: 'Spielstand exportieren',
                  icon: Icons.file_download_outlined,
                ),
              ],
            ),
            const SizedBox(height: 11),
            if (!campaign.hero.isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _Notice(
                  icon: Icons.warning_amber,
                  text:
                      'Charakterbogen unvollständig. Erzählung und historische Ereignisse sind verfügbar. '
                      'Bestätige die fehlenden Werte im Charakterbogen für regelgebundene Proben.',
                  action: TextButton(
                    onPressed: _editHero,
                    child: const Text('Vervollständigen'),
                  ),
                ),
              ),
            FantasyAdventureStatusHud(hero: campaign.hero),
            const SizedBox(height: 12),
            const FantasyChapterHeading(
              label: 'Held & Kampf',
              rune: FantasyRune.hero,
              description: 'Charakterbogen, Zustände und Begegnungen',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _showHeroSheet,
                  icon: const Icon(Icons.auto_stories_outlined, size: 17),
                  label: const Text('Charakterbogen ansehen'),
                ),
                IconButton(
                  onPressed: _ruleInteractionBlocked ? null : _editHero,
                  tooltip: 'Charakterbogen bearbeiten',
                  icon: const Icon(Icons.person_outline),
                ),
                IconButton(
                  onPressed: () => _showInventory(context, campaign.hero),
                  tooltip: 'Inventar öffnen',
                  icon: const Icon(Icons.backpack_outlined),
                ),
                FantasyTextButton(
                  key: const ValueKey('adventure-confirm-character-effect'),
                  onPressed:
                      _ruleInteractionBlocked ||
                          campaign.pendingRoll != null ||
                          campaign.pendingDeathSave != null ||
                          campaign.hero.hitPoints == null ||
                          campaign.hero.isDead
                      ? null
                      : _confirmCharacterEffect,
                  icon: Icons.health_and_safety_outlined,
                  style: FantasyButtonStyle.woodGold,
                  label: 'Effekt bestätigen',
                ),
                if (campaign.hero.conditions.contains('liegend'))
                  FantasyTextButton(
                    key: const ValueKey('adventure-stand-up'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.hero.isDead ||
                            (campaign.encounter != null &&
                                !campaign.encounter!.isFinished &&
                                campaign.encounter!.activeParticipant != 'hero')
                        ? null
                        : _standUp,
                    icon: Icons.accessibility_new_outlined,
                    style: FantasyButtonStyle.iron,
                    label: 'Aufstehen',
                  ),
                if (campaign.hero.conditions.contains('liegend') &&
                    campaign.encounter != null &&
                    !campaign.encounter!.isFinished)
                  PopupMenuButton<int>(
                    key: const ValueKey('adventure-crawl'),
                    tooltip: 'Kriechstrecke und Gelände bestätigen',
                    enabled:
                        !_ruleInteractionBlocked &&
                        campaign.pendingRoll == null &&
                        campaign.pendingDeathSave == null &&
                        !campaign.hero.isDead &&
                        campaign.encounter!.activeParticipant == 'hero',
                    onSelected: (value) => _crawl(
                      value >= 100 ? value - 100 : value,
                      value >= 100,
                    ),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 5,
                        child: Text('1,5 m kriechen – kostet 3 m'),
                      ),
                      PopupMenuItem(
                        value: 10,
                        child: Text('3 m kriechen – kostet 6 m'),
                      ),
                      PopupMenuItem(
                        value: 105,
                        child: Text('1,5 m schwieriges Gelände – kostet 4,5 m'),
                      ),
                      PopupMenuItem(
                        value: 110,
                        child: Text('3 m schwieriges Gelände – kostet 9 m'),
                      ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.accessibility_outlined, size: 17),
                          SizedBox(width: 6),
                          Text('Kriechen'),
                        ],
                      ),
                    ),
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    !campaign.hero.conditions.contains('liegend'))
                  for (final kind in SrdTerrainMovement.values)
                    PopupMenuButton<int>(
                      key: ValueKey('adventure-terrain-${kind.name}'),
                      tooltip:
                          'Bestätigte Strecke und passierbares Gelände wählen',
                      enabled:
                          !_ruleInteractionBlocked &&
                          campaign.pendingRoll == null &&
                          campaign.pendingDeathSave == null &&
                          campaign.pendingEnemyShieldHit == null &&
                          campaign.pendingOpportunityAttack == null &&
                          !campaign.hero.isDead &&
                          (campaign.hero.hitPoints ?? 0) > 0 &&
                          campaign.encounter!.activeParticipant == 'hero',
                      onSelected: (value) => _moveOnConfirmedTerrain(
                        kind,
                        value >= 100 ? value - 100 : value,
                        value >= 100,
                      ),
                      itemBuilder: (_) => [
                        for (final distance in [5, 10])
                          for (final difficult in [false, true])
                            PopupMenuItem<int>(
                              value: distance + (difficult ? 100 : 0),
                              child: Text(
                                '${distance * 0.3} m ${kind == SrdTerrainMovement.climb ? 'klettern' : 'schwimmen'} '
                                '(${difficult ? 'schwieriges' : 'normales'} Gelände, '
                                '${ProneMovementRules.formatDecimeters(SrdTerrainMovementRules.costDecimeters(campaign.hero, kind: kind, distanceFeet: distance, difficultTerrain: difficult))} Verbrauch)',
                              ),
                            ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              kind == SrdTerrainMovement.climb
                                  ? Icons.terrain_outlined
                                  : Icons.pool_outlined,
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              kind == SrdTerrainMovement.climb
                                  ? 'Klettern'
                                  : 'Schwimmen',
                            ),
                          ],
                        ),
                      ),
                    ),
                FantasyTextButton(
                  key: const ValueKey('adventure-manage-spell-effects'),
                  onPressed:
                      _ruleInteractionBlocked ||
                          campaign.pendingRoll != null ||
                          campaign.pendingDeathSave != null ||
                          campaign.pendingEnemyShieldHit != null ||
                          campaign.hero.isDead
                      ? null
                      : _manageConfirmedSpellEffects,
                  icon: Icons.auto_fix_high,
                  style: FantasyButtonStyle.iron,
                  label: 'Zauberwirkungen verwalten',
                ),
                if (campaign.hero.spells.contains('Sending'))
                  FantasyTextButton(
                    key: const ValueKey('adventure-confirm-sending'),
                    label: 'Sending versuchen',
                    icon: Icons.mark_email_unread_outlined,
                    style: FantasyButtonStyle.arcane,
                    onPressed:
                        !_canInteract ||
                            !_outboxReady ||
                            _sendingInFlight ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.pendingEnemyShieldHit != null ||
                            (campaign.encounter != null &&
                                !campaign.encounter!.isFinished)
                        ? null
                        : _confirmSendingAttempt,
                  ),
                FantasyTextButton(
                  key: const ValueKey('adventure-manage-condition-effects'),
                  onPressed:
                      _ruleInteractionBlocked ||
                          campaign.pendingRoll != null ||
                          campaign.pendingDeathSave != null ||
                          campaign.hero.hitPoints == null ||
                          campaign.hero.isDead
                      ? null
                      : _manageConditionEffects,
                  icon: Icons.shield_moon_outlined,
                  style: FantasyButtonStyle.iron,
                  label: 'Zustände verwalten',
                ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    campaign.encounter!.activeParticipant == 'hero' &&
                    HeroShieldReactionRules.preparedName(campaign.hero) != null)
                  FantasyTextButton(
                    key: const ValueKey('adventure-end-turn-with-shield'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.hero.isDead ||
                            campaign.hero.hitPoints == null ||
                            campaign.hero.hitPoints! <= 0
                        ? null
                        : _endTurnWithShield,
                    icon: Icons.shield_outlined,
                    style: FantasyButtonStyle.arcane,
                    label: 'Zug beenden: Schild ggf. wirken',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    campaign.encounter!.activeParticipant == 'enemy')
                  FantasyTextButton(
                    key: const ValueKey(
                      'adventure-confirm-opportunity-movement',
                    ),
                    onPressed: _canConfirmOpportunityMovement(campaign)
                        ? _confirmOpportunityMovement
                        : null,
                    icon: Icons.pause_circle_outline,
                    style: FantasyButtonStyle.iron,
                    label: 'Gegnerbewegung bestätigen',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    ClassResourceRules.level(campaign.hero, 'Mönch') >= 4)
                  FantasyTextButton(
                    key: const ValueKey('adventure-monk-slow-fall'),
                    onPressed:
                        !_canInteract ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.pendingEnemyShieldHit != null ||
                            campaign.encounter!.reactionUsed ||
                            campaign.hero.isDead ||
                            (campaign.hero.hitPoints ?? 0) <= 0 ||
                            !ConditionRules.canTakeActions(campaign.hero)
                        ? null
                        : _confirmSlowFall,
                    icon: Icons.airline_stops_outlined,
                    style: FantasyButtonStyle.iron,
                    label: 'Sanfter Fall',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished)
                  FantasyTextButton(
                    key: const ValueKey('adventure-register-area-creature'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.trackedAreaCreatures.length >= 19
                        ? null
                        : _trackAreaCreature,
                    icon: Icons.group_add_outlined,
                    style: FantasyButtonStyle.woodGold,
                    label: 'Kreatur-TP erfassen',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    campaign.trackedAreaCreatures.isNotEmpty)
                  FantasyTextButton(
                    key: const ValueKey('adventure-initiative-roster'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.pendingEnemyShieldHit != null
                        ? null
                        : _confirmAreaCreatureInitiative,
                    icon: Icons.format_list_numbered,
                    style: FantasyButtonStyle.iron,
                    label: 'Initiative der Kreaturen',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    campaign.trackedAreaCreatures.isNotEmpty)
                  FantasyTextButton(
                    key: const ValueKey('adventure-manual-turn-queue'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.pendingEnemyShieldHit != null
                        ? null
                        : _editManualTurnQueue,
                    icon: Icons.format_list_bulleted,
                    style: FantasyButtonStyle.iron,
                    label: 'Manuelle Zugfolge',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    campaign.manualTurnQueue != null &&
                    !campaign.manualTurnQueue!.actionUsed &&
                    campaign.trackedAreaCreatures.any(
                      (creature) =>
                          creature.id ==
                              campaign.manualTurnQueue!.activeActorId &&
                          creature.hitPoints > 0 &&
                          creature.initiativeController == 'gm',
                    ) &&
                    campaign.trackedAreaCreatures.any(
                      (creature) =>
                          creature.id !=
                              campaign.manualTurnQueue!.activeActorId &&
                          creature.hitPoints > 0,
                    ))
                  FantasyTextButton(
                    key: const ValueKey('adventure-manual-extra-attack'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.pendingEnemyShieldHit != null
                        ? null
                        : _manualExtraCreatureAttack,
                    icon: Icons.gavel,
                    style: FantasyButtonStyle.wax,
                    label: 'Zusatzkreatur-Angriff',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const FantasyChapterHeading(
              label: 'Zauber & Rituale',
              rune: FantasyRune.tome,
              description: 'Vorbereitete Magie und Heilung',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    AcidSplashRules.preparedName(campaign.hero) != null)
                  FantasyTextButton(
                    key: const ValueKey('adventure-cast-acid-splash'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.pendingEnemyShieldHit != null ||
                            campaign.hero.isDead ||
                            campaign.hero.hitPoints == 0 ||
                            campaign.encounter!.activeParticipant != 'hero' ||
                            campaign.encounter!.actionUsed
                        ? null
                        : _castAcidSplash,
                    icon: Icons.bubble_chart_outlined,
                    style: FantasyButtonStyle.arcane,
                    label: 'Säurespritzer',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    SacredFlameRules.preparedName(campaign.hero) != null &&
                    SacredFlameRules.isClericCaster(campaign.hero))
                  FantasyTextButton(
                    key: const ValueKey('adventure-cast-sacred-flame'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.pendingEnemyShieldHit != null ||
                            campaign.hero.isDead ||
                            campaign.hero.hitPoints == 0 ||
                            campaign.encounter!.activeParticipant != 'hero' ||
                            campaign.encounter!.actionUsed
                        ? null
                        : _castSacredFlame,
                    icon: Icons.wb_sunny_outlined,
                    style: FantasyButtonStyle.arcane,
                    label: 'Heilige Flamme',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    FireBoltRules.preparedName(campaign.hero) != null)
                  FantasyTextButton(
                    key: const ValueKey('adventure-cast-fire-bolt'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.hero.isDead ||
                            campaign.hero.hitPoints == 0 ||
                            campaign.encounter!.activeParticipant != 'hero' ||
                            campaign.encounter!.actionUsed
                        ? null
                        : _castFireBolt,
                    icon: Icons.local_fire_department_outlined,
                    style: FantasyButtonStyle.arcane,
                    label: 'Feuerpfeil',
                  ),
                if (campaign.encounter != null &&
                    !campaign.encounter!.isFinished &&
                    MagicMissileRules.preparedName(campaign.hero) != null)
                  FantasyTextButton(
                    key: const ValueKey('adventure-cast-magic-missile'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.hero.isDead ||
                            campaign.hero.hitPoints == 0 ||
                            campaign.encounter!.activeParticipant != 'hero' ||
                            campaign.encounter!.actionUsed ||
                            campaign.encounter!.spellSlotExpendedThisTurn
                        ? null
                        : _castMagicMissile,
                    icon: Icons.auto_awesome_outlined,
                    style: FantasyButtonStyle.arcane,
                    label: 'Magisches Geschoss',
                  ),
                FantasyTextButton(
                  key: const ValueKey('adventure-fireball-area-preview'),
                  onPressed: _ruleInteractionBlocked
                      ? null
                      : _showFireballGridPreview,
                  icon: Icons.grid_on_outlined,
                  style: FantasyButtonStyle.arcane,
                  label: 'Feuerball-Kartenvorschau',
                ),
                if (campaign.hero.spells.any(
                  (name) => HealingSpellRules.find(name) != null,
                ))
                  FantasyTextButton(
                    key: const ValueKey('adventure-cast-healing-spell'),
                    onPressed:
                        _ruleInteractionBlocked ||
                            campaign.pendingRoll != null ||
                            campaign.pendingDeathSave != null ||
                            campaign.hero.isDead ||
                            campaign.hero.hitPoints == 0
                        ? null
                        : _castHealingSpell,
                    icon: Icons.auto_fix_high_outlined,
                    style: FantasyButtonStyle.woodGold,
                    label: 'Heilzauber wirken',
                  ),
              ],
            ),
            if (campaign.pendingOpportunityAttack != null)
              FantasyPanel(
                key: const ValueKey('pending-opportunity-attack'),
                title: 'Offene Reaktionsentscheidung',
                icon: Icons.pause_circle_outline,
                accent: FantasyPalette.gold,
                material: FantasyPanelMaterial.iron,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gelegenheitsangriffs-Angebot gegen '
                        '${campaign.encounter?.enemyName ?? "den bestätigten Gegner"} '
                        'in Runde ${campaign.pendingOpportunityAttack!.round}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bestätigter Abstand: '
                        '${campaign.pendingOpportunityAttack!.beforeDistanceFeet} '
                        '→ ${campaign.pendingOpportunityAttack!.afterDistanceFeet} Fuß. '
                        'Reichweite: '
                        '${campaign.pendingOpportunityAttack!.reachFeet} Fuß. '
                        '${campaign.pendingOpportunityAttack!.unarmedStrike ? "Waffenloser Schlag." : "Waffe: ${opportunityWeapons.length == 1 ? opportunityWeapons.single.name : "bestätigte Nahkampfwaffe"}."}',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ein Angriff wird hier noch nicht gewürfelt. '
                        'Trefferpunkte und Reaktion bleiben unverändert. '
                        'Du kannst die Entscheidung gespeichert offen lassen '
                        'oder ausdrücklich auf den Gelegenheitsangriff '
                        'verzichten. Bis dahin bleibt der Gegnerzug unterbrochen.',
                      ),
                      const SizedBox(height: 8),
                      FantasyTextButton(
                        key: const ValueKey('opportunity-attack-decline'),
                        label: 'Auf Gelegenheitsangriff verzichten',
                        icon: Icons.close,
                        style: FantasyButtonStyle.iron,
                        onPressed: widget.controller.busy
                            ? null
                            : () => _declineOpportunityAttack(campaign),
                      ),
                    ],
                  ),
                ),
              ),
            if (campaign.pendingEnemyShieldHit != null)
              FantasyPanel(
                key: const ValueKey('pending-enemy-shield-hit'),
                title: 'Schildreaktion',
                icon: Icons.shield_outlined,
                accent: FantasyPalette.blue,
                material: FantasyPanelMaterial.iron,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gegnerangriff trifft – Schildreaktion',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gewürfelter Treffer: '
                        '${campaign.pendingEnemyShieldHit!.total}. '
                        'Der Schaden wurde noch nicht gewürfelt.',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FantasyTextButton(
                            key: const ValueKey('enemy-shield-cast-now'),
                            label: 'Jetzt Schild wirken',
                            icon: Icons.shield_outlined,
                            style: FantasyButtonStyle.arcane,
                            onPressed: _ruleInteractionBlocked
                                ? null
                                : () => _decideEnemyShieldHit(castShield: true),
                          ),
                          FantasyTextButton(
                            key: const ValueKey('enemy-shield-decline'),
                            label: 'Treffer hinnehmen',
                            icon: Icons.shield_moon_outlined,
                            style: FantasyButtonStyle.iron,
                            onPressed: _ruleInteractionBlocked
                                ? null
                                : () =>
                                      _decideEnemyShieldHit(castShield: false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (campaign.pendingDeathSave != null)
              DeathSaveDecisionPanel(
                hero: campaign.hero,
                pending: campaign.pendingDeathSave!,
                busy: _ruleInteractionBlocked,
                onAccept: () => _decideDeathSave(campaign),
                onReroll: (feature) =>
                    _decideDeathSave(campaign, feature: feature),
              ),
            BackendAdventureStatus(controller: widget.controller),

            if (encounter.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: _gold),
                  Expanded(
                    child: Text(
                      _combat ? 'Kampfübersicht' : 'Eine Begegnung ist aktiv.',
                    ),
                  ),
                  FantasyToggleButton(
                    key: const ValueKey('adventure-combat-mode-toggle'),
                    label: _combat ? 'Zur Erzählung' : 'Kampf ansehen',
                    icon: _combat
                        ? Icons.auto_stories_outlined
                        : Icons.shield_outlined,
                    selected: _combat,
                    onPressed: () => setState(() => _combat = !_combat),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
    // The story and composer belong to the body. The bottom dock belongs to
    // Scaffold.bottomNavigationBar so it cannot scroll away with the scene.
    return Scaffold(
      backgroundColor: Colors.transparent,
      // The surrounding app Scaffold already adjusts for Android's keyboard.
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: _combat && encounter.isNotEmpty
                ? FantasyBackdrop(
                    scene: FantasyBackdropScene.combat,
                    child: _CombatView(
                      encounter: campaign.encounter!,
                      hero: campaign.hero,
                      events: campaign.events,
                      pendingShieldDecision:
                          campaign.pendingEnemyShieldHit != null,
                      onAction: (text) {
                        _send(quickAction: text);
                      },
                      busy: _ruleInteractionBlocked,
                      onPrepareOffhandAttack:
                          _canInteract &&
                              _outboxReady &&
                              TwoWeaponFightingRules.canPrepare(campaign)
                          ? _prepareOffhandAttack
                          : null,
                      onManageSpells:
                          _ruleInteractionBlocked ||
                              campaign.pendingRoll != null ||
                              campaign.pendingDeathSave != null ||
                              campaign.pendingEnemyShieldHit != null ||
                              campaign.hero.isDead
                          ? null
                          : _manageConfirmedSpellEffects,
                      onManageEffects:
                          _ruleInteractionBlocked ||
                              campaign.pendingRoll != null ||
                              campaign.pendingDeathSave != null ||
                              campaign.hero.hitPoints == null ||
                              campaign.hero.isDead
                          ? null
                          : _manageConditionEffects,
                      header: header,
                    ),
                  )
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                      header,
                      FantasyAdventureQuestBoard(
                        campaign: campaign,
                        onOpenJournal: widget.onJournal,
                      ),
                      if (campaign.storyBible['mode'] ==
                          RabenwachtCampaign.mode)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FantasyTextButton(
                            key: const ValueKey('rabenwacht-discovered-clues'),
                            label: 'Hinweise und Aufträge',
                            icon: Icons.fact_check_outlined,
                            style: FantasyButtonStyle.iron,
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Ermittlungsstand'),
                                content: SingleChildScrollView(
                                  child: SelectableText(
                                    RabenwachtCampaign.discoveredClues(
                                      campaign,
                                    ),
                                  ),
                                ),
                                actions: [
                                  FantasyTextButton(
                                    label: 'Schließen',
                                    style: FantasyButtonStyle.iron,
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      FantasyPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Erfahrungsfortschritt: ${campaign.hero.experience?.toString() ?? 'nicht bestätigt'} EP'
                              '${CampaignExperience.nextThreshold(campaign.hero) == null ? ' · Höchststufe' : ' / ${CampaignExperience.nextThreshold(campaign.hero)} EP'}',
                              key: const ValueKey('adventure-xp-details'),
                            ),
                            const SizedBox(height: 6),
                            if (CampaignExperience.levelProgress(
                                  campaign.hero,
                                ) !=
                                null)
                              LinearProgressIndicator(
                                key: const ValueKey('adventure-xp-progress'),
                                value: CampaignExperience.levelProgress(
                                  campaign.hero,
                                ),
                                minHeight: 5,
                              ),
                            FantasyTextButton(
                              key: const ValueKey(
                                'adventure-confirm-xp-reward',
                              ),
                              label: 'EP-Belohnung bestätigen',
                              icon: Icons.military_tech_outlined,
                              style: FantasyButtonStyle.woodGold,
                              onPressed:
                                  !_canInteract ||
                                      campaign.hero.experience == null ||
                                      campaign.pendingRoll != null ||
                                      campaign.pendingDeathSave != null ||
                                      campaign.pendingEnemyShieldHit != null
                                  ? null
                                  : _confirmExperienceReward,
                            ),
                            if (CampaignExperience.canLevelUp(campaign.hero))
                              FantasyTextButton(
                                key: const ValueKey('adventure-levelup-ready'),
                                label: 'Stufenaufstieg verfügbar',
                                icon: Icons.trending_up_outlined,
                                style: FantasyButtonStyle.woodGold,
                                onPressed:
                                    _ruleInteractionBlocked ||
                                        campaign.pendingRoll != null ||
                                        campaign.encounter != null ||
                                        campaign.pendingDeathSave != null
                                    ? null
                                    : _editHero,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FantasyScenePanel(
                        key: const ValueKey('adventure-illustrated-scene'),
                        scene: campaign.scene,
                        image: FantasyArtwork.ruins,
                      ),
                      const SizedBox(height: 14),
                      if (campaign.adventureOffer != null)
                        FantasyPanel(
                          key: const ValueKey('adventure-offer-card'),
                          accent: FantasyPalette.blue,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FantasySectionTitle(
                                  title: 'Neue spielbare Begegnung',
                                  icon: Icons.sports_martial_arts,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  campaign.adventureOffer!.title,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(campaign.adventureOffer!.description),
                                const SizedBox(height: 6),
                                Text(
                                  'Auftrag: ${campaign.adventureOffer!.questTitle}',
                                ),
                                Text(
                                  'Gegnerprofil: ${campaign.adventureOffer!.archetype}. '
                                  'Werte und Beute kommen nur aus der lokalen Regelengine.',
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    FantasyTextButton(
                                      key: const ValueKey('adventure-accept'),
                                      label: 'Begegnung annehmen',
                                      icon: Icons.check_circle_outline,
                                      style: FantasyButtonStyle.woodGold,
                                      onPressed: _ruleInteractionBlocked
                                          ? null
                                          : () async {
                                              final prior = _lastMessageId;
                                              await widget.controller
                                                  .acceptAdventure();
                                              if (mounted) {
                                                await _afterTurn(prior);
                                              }
                                            },
                                    ),
                                    if (campaign.adventureOffer!.archetype !=
                                            'investigation' &&
                                        ClassResourceRules.level(
                                              campaign.hero,
                                              'Mönch',
                                            ) >=
                                            2 &&
                                        campaign.hero.hitPoints != null &&
                                        campaign.hero.hitPoints! > 0 &&
                                        ClassResourceRules.remaining(
                                              campaign.hero,
                                              'uncannyMetabolism',
                                            ) >
                                            0)
                                      FantasyTextButton(
                                        key: const ValueKey(
                                          'adventure-accept-uncanny-metabolism',
                                        ),
                                        label:
                                            'Annehmen + Unheimlicher Stoffwechsel',
                                        icon: Icons.self_improvement,
                                        style: FantasyButtonStyle.woodGold,
                                        onPressed: _ruleInteractionBlocked
                                            ? null
                                            : () async {
                                                final prior = _lastMessageId;
                                                await widget.controller
                                                    .acceptAdventure(
                                                      useUncannyMetabolism:
                                                          true,
                                                    );
                                                if (mounted) {
                                                  await _afterTurn(prior);
                                                }
                                              },
                                      ),
                                    FantasyTextButton(
                                      key: const ValueKey('adventure-reject'),
                                      label: 'Anderen Weg wählen',
                                      icon: Icons.alt_route_outlined,
                                      style: FantasyButtonStyle.iron,
                                      onPressed: _ruleInteractionBlocked
                                          ? null
                                          : () async {
                                              final prior = _lastMessageId;
                                              await widget.controller
                                                  .rejectAdventure();
                                              if (mounted) {
                                                await _afterTurn(prior);
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final item in messages)
                        _MessageBubble(
                          message: _map(item),
                          onSpeak: (text) => widget.voice.speak(text),
                        ),
                      if (pending.isNotEmpty)
                        FantasyPanel(
                          accent: FantasyPalette.gold,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Würfelprobe ausstehend',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${pending['label'] ?? pending['type'] ?? 'Probe'} · '
                                  'Modifikator ${_signed(pending['modifier'] ?? pending['bonus'] ?? 0)}',
                                ),
                                if ((campaign.pendingRoll!.type == 'attack' ||
                                        campaign.pendingRoll!.type ==
                                            'offhandAttack') &&
                                    campaign.pendingRoll!.sneakAttackAlly !=
                                        null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Bestätigter Verbündeter: ${campaign.pendingRoll!.sneakAttackAlly!.allyName}',
                                    key: const ValueKey(
                                      'adventure-sneak-attack-ally-source',
                                    ),
                                  ),
                                  const Text(
                                    'Innerhalb von 5 Fuß des Ziels und nicht handlungsunfähig bestätigt. Gilt nur für diesen Angriff.',
                                  ),
                                  FantasyTextButton(
                                    key: const ValueKey(
                                      'adventure-clear-sneak-attack-ally',
                                    ),
                                    label: 'Verbündetenbestätigung entfernen',
                                    icon: Icons.close,
                                    style: FantasyButtonStyle.iron,
                                    onPressed: _canInteract
                                        ? _clearSneakAttackAlly
                                        : null,
                                  ),
                                ] else if (SneakAttackAllyRules.canPrepare(
                                  campaign,
                                )) ...[
                                  const SizedBox(height: 12),
                                  FantasyTextButton(
                                    key: const ValueKey(
                                      'adventure-confirm-sneak-attack-ally',
                                    ),
                                    label:
                                        'Verbündeten für Hinterhältigen Angriff bestätigen',
                                    icon: Icons.group_outlined,
                                    style: FantasyButtonStyle.arcane,
                                    onPressed: _canInteract
                                        ? _confirmSneakAttackAlly
                                        : null,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                FantasyTextButton(
                                  label: 'Wurf durchführen',
                                  icon: Icons.casino_outlined,
                                  style: FantasyButtonStyle.dice,
                                  onPressed: _ruleInteractionBlocked
                                      ? null
                                      : _roll,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (widget.voice.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.voice.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (widget.voice.speaking)
            FantasyTextButton(
              label: 'Vorlesen unterbrechen',
              icon: Icons.stop_circle_outlined,
              style: FantasyButtonStyle.iron,
              onPressed: widget.voice.stopSpeaking,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: FantasyPanel(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              accent: FantasyPalette.blue,
              child: Column(
                children: [
                  if (_submittingAction)
                    const SizedBox.shrink(
                      key: ValueKey('adventure-action-submitting'),
                    ),
                  if (_pendingAction != null && !_submittingAction) ...[
                    const Text(
                      'Ausstehende Handlung – noch nicht sicher bestätigt',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pendingAction!.text,
                      key: const ValueKey('adventure-pending-action-text'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        FantasyTextButton(
                          key: const ValueKey('adventure-retry-action'),
                          label: 'Erneut bestätigen',
                          icon: Icons.refresh,
                          style: FantasyButtonStyle.woodGold,
                          onPressed:
                              _submittingAction || _ruleInteractionBlocked
                              ? null
                              : _retryPending,
                        ),
                        FantasyTextButton(
                          key: const ValueKey('adventure-discard-action'),
                          label: 'Verwerfen',
                          icon: Icons.close,
                          style: FantasyButtonStyle.iron,
                          onPressed:
                              _submittingAction || _ruleInteractionBlocked
                              ? null
                              : _discardPending,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_outboxError != null)
                    Text(
                      _outboxError!,
                      key: const ValueKey('adventure-outbox-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          enabled: _canInteract,
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            labelText: widget.voice.listening
                                ? 'Ich höre zu …'
                                : 'Was möchtest du tun?',
                            helperText:
                                'Erkannten Text vor dem Senden prüfen und korrigieren.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FantasyIconButton(
                        onPressed: _canInteract ? _send : null,
                        tooltip: 'Handlung senden',
                        icon: Icons.send,
                      ),
                    ],
                  ),
                  // Secondary action stays by the text composer. Speech and
                  // dice are available exactly once in the fixed bottom dock.
                  if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FantasyTextButton(
                        key: const ValueKey('adventure-memory-recap'),
                        label: 'Rückblick',
                        icon: Icons.history,
                        style: FantasyButtonStyle.iron,
                        onPressed: _canInteract ? _recap : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      // Permanently docked below the composer and above main navigation.
      bottomNavigationBar: FantasyPinnedActionBar(
        busy: !_canInteract,
        listening: widget.voice.listening,
        onSpeech: _toggleMic,
        attackEnabled:
            campaign.encounter != null &&
            !campaign.encounter!.isFinished &&
            campaign.encounter!.activeParticipant == 'hero' &&
            campaign.pendingRoll == null &&
            campaign.pendingDeathSave == null &&
            campaign.pendingEnemyShieldHit == null &&
            campaign.pendingOpportunityAttack == null,
        attackUnavailableReason:
            campaign.encounter == null || campaign.encounter!.isFinished
            ? 'Angriff erst mit einem bestätigten aktiven Kampf möglich.'
            : campaign.encounter!.activeParticipant != 'hero'
            ? 'Ein anderer Kampfteilnehmer ist am Zug.'
            : 'Eine ausstehende Entscheidung muss zuerst geklärt werden.',
        onInspect: () => _send(quickAction: 'Ich untersuche die Umgebung.'),
        onAttack: () => _send(quickAction: 'Ich greife an.'),
        onRoll: _roll,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onSpeak});
  final Map<String, dynamic> message;
  final void Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    final player = ['user', 'player'].contains(message['role']);
    final text = _messageText(message);
    return Align(
      alignment: player ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: player ? const Color(0xff1e3c4d) : _ink,
          border: Border.all(
            color: player
                ? FantasyPalette.blue.withValues(alpha: .47)
                : _gold.withValues(alpha: .4),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player ? 'Du' : 'Spielleiter',
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!player)
                  FantasyIconButton(
                    onPressed: () => onSpeak(text),
                    tooltip: 'Diese Antwort vorlesen',
                    icon: Icons.volume_up_outlined,
                  ),
              ],
            ),
            SelectableText(text),
          ],
        ),
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          FantasyStatTile(
            icon: Icons.favorite_outline,
            title: 'Trefferpunkte',
            value: 'TP ${hero.hitPoints ?? '?'}/${hero.maxHitPoints ?? '?'}',
            color: FantasyPalette.danger,
          ),
          FantasyStatTile(
            icon: Icons.shield_outlined,
            title: 'Rüstungsklasse',
            value: 'RK ${hero.armorClass ?? '?'}',
            color: FantasyPalette.gold,
          ),
          FantasyStatTile(
            icon: Icons.directions_run_outlined,
            title: 'Bewegung',
            value: '${hero.speed ?? '?'} m',
            color: FantasyPalette.blue,
          ),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final entry in hero.abilities.entries)
            Chip(
              label: Text(
                '${const {'strength': 'STÄ', 'dexterity': 'GES', 'constitution': 'KON', 'intelligence': 'INT', 'wisdom': 'WEI', 'charisma': 'CHA'}[entry.key] ?? entry.key} ${entry.value ?? '?'}',
              ),
            ),
        ],
      ),
    ],
  );
}

class _CombatView extends StatelessWidget {
  const _CombatView({
    required this.encounter,
    required this.hero,
    required this.events,
    required this.pendingShieldDecision,
    required this.onAction,
    required this.busy,
    required this.onManageEffects,
    required this.onManageSpells,
    required this.onPrepareOffhandAttack,
    required this.header,
  });
  final Encounter encounter;
  final HeroCharacter hero;
  final List<GameEvent> events;
  final bool pendingShieldDecision;
  final void Function(String) onAction;
  final bool busy;
  final VoidCallback? onManageEffects;
  final VoidCallback? onManageSpells;
  final VoidCallback? onPrepareOffhandAttack;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        header,
        FantasyCombatTurnTracker(
          round: encounter.round,
          heroName: hero.name,
          enemyName: encounter.enemyName,
          heroInitiative: encounter.heroInitiative,
          enemyInitiative: encounter.enemyInitiative,
          activeParticipant: encounter.activeParticipant,
          isFinished: encounter.isFinished,
        ),
        const SizedBox(height: 12),
        FantasyCombatThreatStatus(
          enemyAttacksPerTurn: encounter.enemyAttacksPerTurn,
          enemyAttacksRemaining: encounter.enemyAttacksRemaining,
          activeParticipant: encounter.activeParticipant,
          pendingShieldDecision: pendingShieldDecision,
          heroShieldActive: encounter.heroShieldActive,
          enemyShieldActive: encounter.enemyShieldActive,
          enemyShieldReactionUsed: encounter.enemyShieldReactionUsed,
          isFinished: encounter.isFinished,
        ),
        const SizedBox(height: 16),
        FantasyCombatantCard(
          key: const ValueKey('combat-hero-card'),
          name: hero.name,
          isHero: true,
          isActive: encounter.activeParticipant == 'hero',
          initiative: encounter.heroInitiative,
          hitPoints: hero.hitPoints,
          maxHitPoints: hero.maxHitPoints,
          armorClass: hero.armorClass,
          temporaryHitPoints: hero.temporaryHitPoints,
        ),
        const SizedBox(height: 10),
        FantasyCombatantCard(
          key: const ValueKey('combat-enemy-card'),
          name: encounter.enemyName,
          isHero: false,
          isActive: encounter.activeParticipant == 'enemy',
          initiative: encounter.enemyInitiative,
          hitPoints: encounter.enemyHitPoints,
          maxHitPoints: encounter.enemyMaxHitPoints,
          armorClass: encounter.enemyArmorClass,
        ),
        const SizedBox(height: 12),
        FantasyEffectWard(
          hero: hero,
          encounter: encounter,
          onManage: onManageEffects,
          onManageSpells: onManageSpells,
        ),
        const SizedBox(height: 12),
        FantasyCombatCoverPanel(
          heroCover: encounter.heroCover,
          enemyCover: encounter.enemyCover,
          canChange:
              !busy &&
              !encounter.isFinished &&
              encounter.activeParticipant == 'hero',
          onAction: onAction,
        ),
        const SizedBox(height: 12),
        FantasyCombatActionEconomy(
          actionUsed: encounter.actionUsed,
          bonusActionUsed: encounter.bonusActionUsed,
          reactionUsed: encounter.reactionUsed,
          movementRemainingLabel: encounter.movementRemainingLabel,
          spellSlotExpendedThisTurn: encounter.spellSlotExpendedThisTurn,
        ),
        const SizedBox(height: 20),
        const FantasySectionTitle(
          title: 'Deine Handlung',
          icon: Icons.sports_martial_arts,
        ),
        const SizedBox(height: 10),
        const Text(
          'Beschreibe deinen Angriff oder deine Entscheidung. Trefferpunkte '
          'ändern sich erst nach einer bestätigten Probe durch die Regelengine. '
          'Der Solo-Kampf löst den Gegnerzug nach abgeschlossenen Aktionen '
          'auf. Eine verfügbare Nebenhand- oder Klassen-Bonusaktion kannst '
          'du vorher nutzen oder deinen Zug ausdrücklich beenden.',
        ),
        const SizedBox(height: 16),
        if (ClassResourceRules.level(hero, 'Kämpfer') >= 9 ||
            ClassResourceRules.level(hero, 'Mönch') >= 14)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Manueller Rettungswurf: z. B. „Rettungswurf: Weisheit SG 15“. '
              'Nach einem Fehlschlag kann „Rettungswurf wiederholen: '
              'Unbeugsam“ oder „Rettungswurf wiederholen: Fokus“ gewählt werden.',
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FantasyTextButton(
              label: 'Angreifen',
              icon: Icons.sports_martial_arts,
              style: FantasyButtonStyle.wax,
              onPressed: busy || encounter.isFinished
                  ? null
                  : () => onAction('Ich greife an.'),
            ),
            if (onPrepareOffhandAttack != null)
              FantasyTextButton(
                key: const ValueKey('combat-prepare-offhand-attack'),
                label: 'Nebenhandangriff vorbereiten',
                icon: Icons.sports_martial_arts,
                style: FantasyButtonStyle.wax,
                onPressed: onPrepareOffhandAttack,
              ),
            PopupMenuButton<int>(
              key: const ValueKey('enemy-multiattack-count'),
              tooltip: 'Bestätigte Gegner-Angriffe',
              enabled:
                  !busy &&
                  !encounter.isFinished &&
                  encounter.activeParticipant == 'hero',
              onSelected: (count) => onAction('Gegner: $count Angriffe'),
              itemBuilder: (_) => [
                for (var count = 1; count <= 4; count++)
                  PopupMenuItem<int>(
                    value: count,
                    child: Text('$count bestätigte Gegner-Angriffe'),
                  ),
              ],
              child: Chip(
                label: Text(
                  'Gegner-Angriffe: ${encounter.enemyAttacksPerTurn}',
                ),
              ),
            ),
            if (encounter.activeParticipant == 'enemy' &&
                encounter.enemyAttacksRemaining > 0)
              FantasyTextButton(
                key: const ValueKey('enemy-attack-continue'),
                label:
                    'Gegnerangriff fortsetzen '
                    '(${encounter.enemyAttacksRemaining} übrig)',
                icon: Icons.arrow_forward,
                style: FantasyButtonStyle.wax,
                onPressed: busy
                    ? null
                    : () => onAction('Gegnerangriff fortsetzen'),
              ),
            FantasyTextButton(
              key: const ValueKey('combat-end-hero-turn'),
              label: 'Zug beenden',
              icon: Icons.skip_next_outlined,
              style: FantasyButtonStyle.iron,
              onPressed:
                  busy ||
                      encounter.isFinished ||
                      encounter.activeParticipant != 'hero' ||
                      hero.isDead
                  ? null
                  : () => onAction('Zug beenden'),
            ),
            FantasyTextButton(
              label: 'Fliehen',
              icon: Icons.directions_run_outlined,
              style: FantasyButtonStyle.iron,
              onPressed: busy
                  ? null
                  : () => onAction('Ich versuche zu fliehen.'),
            ),
            FantasyTextButton(
              label: 'Gegner untersuchen',
              icon: Icons.search_outlined,
              style: FantasyButtonStyle.arcane,
              onPressed: busy
                  ? null
                  : () => onAction('Ich untersuche meinen Gegner.'),
            ),
            if (ClassResourceRules.level(hero, 'Mönch') >= 2) ...[
              FantasyTextButton(
                key: const ValueKey('monk-patient-defense'),
                label: 'Mönch: Rückzug',
                icon: Icons.shield_outlined,
                style: FantasyButtonStyle.iron,
                onPressed: busy || encounter.bonusActionUsed
                    ? null
                    : () => onAction('Geduldige Verteidigung'),
              ),
              FantasyTextButton(
                key: const ValueKey('monk-step-wind'),
                label: 'Mönch: Sprinten',
                icon: Icons.air,
                style: FantasyButtonStyle.arcane,
                onPressed: busy || encounter.bonusActionUsed
                    ? null
                    : () => onAction('Schritt des Windes'),
              ),
              if (ClassResourceRules.remaining(hero, 'focusPoints') > 0) ...[
                FantasyTextButton(
                  key: const ValueKey('monk-flurry-of-blows'),
                  label:
                      'Schlaghagel · ${ClassResourceRules.level(hero, 'Mönch') >= 10 ? 3 : 2} Angriffe · 1 Fokus',
                  icon: Icons.sports_martial_arts,
                  style: FantasyButtonStyle.wax,
                  onPressed: busy || !MonkFlurryRules.canUse(hero, encounter)
                      ? null
                      : () => onAction('Schlaghagel'),
                ),
                FantasyTextButton(
                  key: const ValueKey('monk-patient-defense-focus'),
                  label: ClassResourceRules.level(hero, 'Mönch') >= 10
                      ? 'Rückzug + Ausweichen + temporäre TP · 1 Fokus'
                      : 'Rückzug + Ausweichen · 1 Fokus',
                  icon: Icons.shield_outlined,
                  style: FantasyButtonStyle.arcane,
                  onPressed: busy || encounter.bonusActionUsed
                      ? null
                      : () => onAction('Geduldige Verteidigung mit Fokuspunkt'),
                ),
                FantasyTextButton(
                  key: const ValueKey('monk-step-wind-focus'),
                  label: 'Sprinten + Rückzug · 1 Fokus',
                  icon: Icons.air,
                  style: FantasyButtonStyle.arcane,
                  onPressed: busy || encounter.bonusActionUsed
                      ? null
                      : () => onAction('Schritt des Windes verstärkt'),
                ),
              ],
            ],
            if (MonkSelfRestoration.choices(hero).isNotEmpty) ...[
              for (final condition in MonkSelfRestoration.choices(hero))
                FantasyToggleButton(
                  key: ValueKey('monk-self-restoration-$condition'),
                  label: encounter.selfRestorationChoice == condition
                      ? 'Ausgewählt für Zugende: $condition'
                      : 'Am Zugende beenden: $condition',
                  icon: Icons.auto_fix_high_outlined,
                  selected: encounter.selfRestorationChoice == condition,
                  onPressed: busy || encounter.activeParticipant != 'hero'
                      ? null
                      : () => onAction('Selbstwiederherstellung: $condition'),
                ),
            ],
            if (ClassResourceRules.level(hero, 'Paladin') >= 1) ...[
              FantasyTextButton(
                key: const ValueKey('paladin-lay-on-hands-heal'),
                label:
                    'Handauflegen · '
                    '${ClassResourceRules.remaining(hero, 'layOnHands')} TP-Vorrat',
                icon: Icons.healing_outlined,
                style: FantasyButtonStyle.woodGold,
                onPressed:
                    busy ||
                        encounter.bonusActionUsed ||
                        encounter.activeParticipant != 'hero' ||
                        (hero.hitPoints ?? 0) <= 0 ||
                        hero.hitPoints == hero.maxHitPoints ||
                        ClassResourceRules.remaining(hero, 'layOnHands') <= 0
                    ? null
                    : () {
                        final missing = hero.maxHitPoints! - hero.hitPoints!;
                        final pool = ClassResourceRules.remaining(
                          hero,
                          'layOnHands',
                        );
                        final amount = missing < pool ? missing : pool;
                        onAction('Handauflegen: $amount');
                      },
              ),
              if (hero.conditions.contains('vergiftet'))
                FantasyTextButton(
                  key: const ValueKey('paladin-lay-on-hands-poison'),
                  label: 'Vergiftung entfernen · 5 Punkte',
                  icon: Icons.healing_outlined,
                  style: FantasyButtonStyle.woodGold,
                  onPressed:
                      busy ||
                          encounter.bonusActionUsed ||
                          encounter.activeParticipant != 'hero' ||
                          ClassResourceRules.remaining(hero, 'layOnHands') < 5
                      ? null
                      : () => onAction('Handauflegen: Vergiftung'),
                ),
            ],
            if (ClassResourceRules.level(hero, 'Schurke') >= 2)
              FantasyTextButton(
                key: const ValueKey('rogue-cunning-disengage'),
                label: 'Schurke: Rückzug',
                icon: Icons.directions_run_outlined,
                style: FantasyButtonStyle.iron,
                onPressed: busy || encounter.bonusActionUsed
                    ? null
                    : () => onAction('Flinke Aktion: Rückzug'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FantasyCombatChronicle(events: events),
      ],
    );
  }
}

class _JournalPage extends StatelessWidget {
  const _JournalPage({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final campaign = controller.currentCampaign;
    if (campaign == null) {
      return const _Empty(
        icon: Icons.menu_book_outlined,
        title: 'Deine Geschichte wird hier bewahrt.',
        text:
            'Öffne eine Kampagne, um Erinnerungen, Quests und Ereignisse zu sehen.',
      );
    }
    final data = campaign.toJson();
    final facts = _map(data['facts']);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FantasyIllustratedBanner(
          image: FantasyArtwork.forgottenWoods,
          eyebrow: 'Deine Chronik',
          title: campaign.name,
          description:
              'Alle bestätigten Erlebnisse und Erinnerungen deiner Reise.',
          icon: Icons.auto_stories_outlined,
          height: 138,
        ),
        const SizedBox(height: 16),
        FantasyChapterHeading(
          label: campaign.name,
          rune: FantasyRune.quill,
          description: 'Die Chronik deines Abenteuers',
        ),
        const SizedBox(height: 8),
        Text(
          'Welt: ${campaign.world} · Bestätigter Stand: ${campaign.revision}',
        ),
        const SizedBox(height: 18),
        _JournalSection(
          title: 'Aktuelle Szene',
          icon: Icons.landscape_outlined,
          children: [Text(campaign.scene)],
        ),
        CampaignMemoryPanel(controller: controller),
        _JournalSection(
          title: 'Dauerhafte Erinnerungen',
          icon: Icons.psychology_outlined,
          children: facts.isEmpty
              ? [const Text('Noch keine zusätzlichen Fakten.')]
              : [
                  for (final fact in facts.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('${_humanLabel(fact.key)}: ${fact.value}'),
                    ),
                ],
        ),
        for (final section in <String, String>{
          'quests': 'Quests',
          'npcs': 'Bekannte Personen',
          'places': 'Besuchte Orte',
        }.entries)
          _JournalSection(
            title: section.value,
            icon: section.key == 'quests'
                ? Icons.flag_outlined
                : Icons.explore_outlined,
            children: _journalItems(data[section.key]),
          ),
        FantasyCombatChronicle(events: campaign.events, maxEntries: 20),
        const _Notice(
          icon: Icons.save_outlined,
          text:
              'Bestätigte Handlungen und Würfelproben werden gemeinsam mit dem Spielstand '
              'transaktional gespeichert. Rohe Audioaufzeichnungen werden nicht gespeichert.',
        ),
      ],
    );
  }
}

class _JournalSection extends StatelessWidget {
  const _JournalSection({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FantasyPanel(
      material: FantasyPanelMaterial.parchment,
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.controller,
    required this.voice,
    required this.backupFiles,
  });
  final BackupFiles backupFiles;
  final GameController controller;
  final VoiceController voice;

  @override
  Widget build(BuildContext context) {
    final voices = voice.voices;
    final value =
        voices.any((v) => '${v['locale']}|${v['name']}' == voice.selectedVoice)
        ? voice.selectedVoice
        : null;
    final canChooseVoice = voice.ttsAvailable && !voice.refreshingVoices;
    final voiceItemHeight = MediaQuery.textScalerOf(context).scale(48) + 16;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const FantasyChapterHeading(
          label: 'Sprache & Audio',
          rune: FantasyRune.moon,
        ),
        const SizedBox(height: 12),
        Text(
          voice.refreshingVoices
              ? 'Sprachausgabe wird geprüft …'
              : voice.ttsAvailable
              ? 'Sprachausgabe: Anbieter meldet Deutsch'
              : 'Sprachausgabe: Deutsch nicht verfügbar',
        ),
        if (voice.ttsLocale != null)
          Text('Ausgabe-Sprache: ${voice.ttsLocale}'),
        if (voice.ttsEngine != null) Text('Sprachdienst: ${voice.ttsEngine}'),
        Text(
          voice.recognitionLocale == null
              ? 'Spracheingabe wird beim Mikrofontipp geprüft.'
              : 'Eingabe-Sprache: ${voice.recognitionLocale}',
        ),
        const SizedBox(height: 12),
        FantasyTextButton(
          key: const ValueKey('refresh-voices'),
          label: voice.refreshingVoices
              ? 'Stimmen werden geprüft …'
              : 'Stimmen neu prüfen',
          icon: voice.refreshingVoices ? Icons.hourglass_top : Icons.refresh,
          style: FantasyButtonStyle.iron,
          onPressed: voice.refreshingVoices ? null : voice.refreshVoices,
        ),
        const SizedBox(height: 8),
        const Text(
          'Nach der Installation eines deutschen Sprachpakets hier erneut '
          'prüfen. Dabei wird das Mikrofon nicht gestartet.',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: voice.autoSpeak,
          onChanged: voice.setAutoSpeak,
          title: const Text('Antworten automatisch vorlesen'),
          subtitle: const Text(
            'Du kannst die Wiedergabe jederzeit unterbrechen.',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('voice-choice-${value ?? 'system'}'),
          initialValue: value,
          isExpanded: true,
          isDense: false,
          itemHeight: voiceItemHeight,
          decoration: const InputDecoration(labelText: 'Deutsche Stimme'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Systemstandard'),
            ),
            for (final entry in voices)
              DropdownMenuItem(
                value: '${entry['locale']}|${entry['name']}',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['name']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${entry['locale']} · ${_voiceNetworkLabel(entry)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
          onChanged: canChooseVoice ? voice.setVoice : null,
        ),
        if (voices.isEmpty && voice.ttsAvailable)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Der Anbieter meldet keine einzelnen deutschen Stimmen. '
              'Du kannst den Systemstandard testen.',
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            FantasyTextButton(
              key: const ValueKey('test-voice'),
              label: 'Stimme testen',
              icon: Icons.volume_up_outlined,
              style: FantasyButtonStyle.arcane,
              onPressed: canChooseVoice
                  ? () => voice.speak(
                      'Willkommen bei Würfelraunen. Deine Geschichte wartet auf dich.',
                    )
                  : null,
            ),
            FantasyTextButton(
              key: const ValueKey('stop-voice'),
              label: 'Wiedergabe stoppen',
              icon: Icons.stop_circle_outlined,
              style: FantasyButtonStyle.iron,
              onPressed: voice.stopSpeaking,
            ),
          ],
        ),
        if (voice.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              voice.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        const _Notice(
          icon: Icons.mic_none,
          text:
              'Das Spiel und die Sprachfunktionen sind auf Deutsch ausgerichtet. '
              'Spracheingabe verwendet den Spracherkennungsdienst des Geräts. '
              'Je nach Anbieter benötigt dieser Internet und überträgt Sprache an ihn. '
              '„Lokal laut Anbieter“ beschreibt nur die ausgewählte Stimme; '
              'es garantiert keinen Offlinebetrieb der Spracheingabe. '
              'Textspiel, Würfel und Speicherung sind im Demo-Modus offline verfügbar.',
        ),
        const SizedBox(height: 24),
        const FantasyChapterHeading(
          label: 'KI & Kosten',
          rune: FantasyRune.dice,
        ),
        const SizedBox(height: 12),
        FantasyPanel(
          accent: FantasyPalette.blue,
          child: BackendSettingsPanel(controller: controller),
        ),
        const SizedBox(height: 24),
        const FantasyChapterHeading(
          label: 'Datenschutz & Spielstände',
          rune: FantasyRune.hero,
        ),
        const SizedBox(height: 12),
        const Text(
          'Charaktere und Kampagnen bleiben lokal in der App. Du kannst sie einzeln '
          'als JSON sichern oder löschen. Die App speichert keine Audioaufzeichnungen. '
          'Deinstallation kann lokale Daten entfernen: exportiere wichtige Spielstände vorher.',
        ),
        const SizedBox(height: 12),
        if (controller.currentCampaign != null)
          FantasyTextButton(
            label: 'Aktuelle Kampagne exportieren',
            icon: Icons.file_download_outlined,
            style: FantasyButtonStyle.woodGold,
            onPressed: () => _showExport(
              context,
              'Spielstand sichern',
              controller.exportCampaign(),
              backupFiles,
              backupFileName(controller.currentCampaign!.name),
            ),
          ),
        const SizedBox(height: 12),
        FantasyTextButton(
          label: 'Alle lokalen Spieldaten löschen',
          icon: Icons.delete_forever_outlined,
          style: FantasyButtonStyle.wax,
          onPressed: controller.busy
              ? null
              : () async {
                  if (await _confirmDelete(
                        context,
                        'Alle lokalen Kampagnen, Charaktere und Einstellungen unwiderruflich löschen? '
                        'Die Backend-Verbindung wird getrennt. '
                        'Exportiere deine Spielstände vorher.',
                      ) !=
                      true) {
                    return;
                  }
                  await voice.stopListening();
                  await voice.stopSpeaking();
                  await controller.deleteAllData();
                  if (controller.error == null) voice.configure({});
                },
        ),
        const SizedBox(height: 24),
        const FantasyChapterHeading(
          label: 'App-Version',
          rune: FantasyRune.compass,
        ),
        const SizedBox(height: 10),
        FutureBuilder<AppBuildInfo>(
          future: AppBuildInfo.current,
          builder: (context, snapshot) {
            final label = snapshot.hasData
                ? snapshot.data!.display
                : snapshot.hasError
                ? 'Version konnte nicht ermittelt werden'
                : 'Version wird geladen …';
            return FantasyPanel(
              child: Semantics(
                label: label,
                child: SelectableText(
                  label,
                  key: const ValueKey('settings-app-version'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const FantasyChapterHeading(
          label: 'Lizenz & Inhalte',
          rune: FantasyRune.tome,
        ),
        const SizedBox(height: 10),
        const Text(
          'Eigenständiges Fantasy-Rollenspiel mit einem ausgewählten Regelkern des '
          'System Reference Document 5.2.1. Nicht alle Klassenfähigkeiten und '
          'Zauberregeln des SRD sind bereits umgesetzt.',
        ),
        const SizedBox(height: 12),
        const SelectableText(_srdAttribution),
        const SizedBox(height: 12),
        FantasyTextButton(
          label: 'Softwarelizenzen anzeigen',
          icon: Icons.description_outlined,
          style: FantasyButtonStyle.iron,
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Würfelraunen',
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

String _voiceNetworkLabel(Map<String, String> voice) =>
    switch (voice['network_required']) {
      '0' => 'lokal laut Anbieter',
      '1' => 'Internet benötigt',
      _ => 'Netzwerkstatus unbekannt',
    };

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _ink,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _gold.withValues(alpha: .25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _gold),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
        if (action != null)
          Align(alignment: Alignment.centerRight, child: action!),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });
  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: _gold),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 20), child: action!),
        ],
      ),
    ),
  );
}

class _ManualRoll {
  const _ManualRoll({this.natural, this.total});
  final int? natural;
  final int? total;
}

class _RollDialog extends StatefulWidget {
  const _RollDialog({required this.pending});
  final Map<String, dynamic> pending;

  @override
  State<_RollDialog> createState() => _RollDialogState();
}

class _RollDialogState extends State<_RollDialog> {
  final _input = TextEditingController();
  bool _total = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = int.tryParse(_input.text);
    if (value == null || (!_total && (value < 1 || value > 20))) {
      setState(
        () => _error = _total
            ? 'Bitte eine ganze Zahl eingeben.'
            : 'Der natürliche W20-Wurf liegt zwischen 1 und 20.',
      );
      return;
    }
    Navigator.of(context).pop(
      _ManualRoll(natural: _total ? null : value, total: _total ? value : null),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Würfelprobe'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pending['label']?.toString() ??
                  'Eine W20-Probe ist ausstehend.',
            ),
            const SizedBox(height: 12),
            Text(
              'Bestätigter Modifikator: ${_signed(widget.pending['modifier'] ?? widget.pending['bonus'] ?? 0)}',
            ),
            const SizedBox(height: 14),
            FantasyTextButton(
              label: 'Automatisch würfeln',
              icon: Icons.casino,
              style: FantasyButtonStyle.arcane,
              onPressed: () => Navigator.of(context).pop(const _ManualRoll()),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            const Text('Oder mit echten Würfeln:'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _total,
              onChanged: (value) => setState(() {
                _total = value;
                _error = null;
              }),
              title: const Text('Gesamtergebnis inklusive Boni'),
              subtitle: Text(
                _total
                    ? 'Der Bonus wird nicht erneut addiert. Natürliche 1/20 sind nicht ableitbar.'
                    : 'Nur die Zahl auf dem W20 eingeben. Der Bonus wird einmal addiert.',
              ),
            ),
            TextField(
              controller: _input,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(
                labelText: _total ? 'Gesamtergebnis' : 'Natürlicher W20-Wurf',
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      FantasyTextButton(
        label: 'Abbrechen',
        style: FantasyButtonStyle.iron,
        onPressed: () => Navigator.pop(context),
      ),
      FantasyTextButton(
        label: 'Manuellen Wurf bestätigen',
        onPressed: _confirm,
      ),
    ],
  );
}

class _FreeDiceDialog extends StatefulWidget {
  const _FreeDiceDialog();

  @override
  State<_FreeDiceDialog> createState() => _FreeDiceDialogState();
}

class _FreeDiceDialogState extends State<_FreeDiceDialog> {
  final _form = GlobalKey<FormState>();
  final _count = TextEditingController(text: '1');
  final _modifier = TextEditingController(text: '0');
  int _sides = 20;

  @override
  void dispose() {
    _count.dispose();
    _modifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Freier Würfelwurf'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Das Ergebnis wird im Tagebuch gespeichert. Ein freier Wurf verändert '
                'keine Trefferpunkte. Für Aktionen fordert der Spielleiter eine eigene Probe an.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _sides,
                decoration: const InputDecoration(labelText: 'Würfeltyp'),
                items: [
                  for (final sides in [4, 6, 8, 10, 12, 20, 100])
                    DropdownMenuItem(value: sides, child: Text('W$sides')),
                ],
                onChanged: (value) => setState(() => _sides = value ?? 20),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _count,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Anzahl der Würfel',
                ),
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  return n == null || n < 1 || n > 20
                      ? '1 bis 20 Würfel eingeben.'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _modifier,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Zusätzlicher Modifikator',
                ),
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  return n == null || n < -100 || n > 100
                      ? '-100 bis 100 eingeben.'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      FantasyTextButton(
        label: 'Abbrechen',
        style: FantasyButtonStyle.iron,
        onPressed: () => Navigator.pop(context),
      ),
      FantasyTextButton(
        label: 'Würfeln',
        icon: Icons.casino,
        style: FantasyButtonStyle.arcane,
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          final modifier = int.parse(_modifier.text);
          Navigator.pop(
            context,
            '${int.parse(_count.text)}d$_sides${modifier == 0 ? '' : _signed(modifier)}',
          );
        },
      ),
    ],
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<dynamic> _list(Object? value) => value is List ? value : <dynamic>[];
String _messageText(Map<String, dynamic> message) =>
    (message['text'] ?? message['content'] ?? message['message'] ?? '')
        .toString();
String _signed(Object? value) {
  final n = int.tryParse(value.toString()) ?? 0;
  return n >= 0 ? '+$n' : '$n';
}

String _humanLabel(String value) =>
    const <String, String>{
      'name': 'Name',
      'title': 'Titel',
      'description': 'Beschreibung',
      'status': 'Status',
      'id': 'Kennung',
      'type': 'Ereignis',
      'timestamp': 'Zeitpunkt',
      'data': 'Details',
      'round': 'Runde',
      'activeId': 'Aktiver Teilnehmer',
      'enemy': 'Gegner',
      'enemyHitPoints': 'Gegner-TP',
      'hitPoints': 'Trefferpunkte',
      'maxHitPoints': 'Maximale Trefferpunkte',
      'armorClass': 'Rüstungsklasse',
    }[value] ??
    value.replaceAll('_', ' ');
String _displayValue(Object? value) {
  if (value is Map) {
    return value.entries
        .map(
          (e) => '${_humanLabel(e.key.toString())}: ${_displayValue(e.value)}',
        )
        .join('\n');
  }
  if (value is List) return value.map(_displayValue).join(', ');
  return value?.toString() ?? 'Unbekannt';
}

List<Widget> _journalItems(Object? value) {
  final items = value is Map ? value.values.toList() : _list(value);
  if (items.isEmpty) return [const Text('Noch keine Einträge.')];
  return [
    for (final item in items)
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: item is Map ? Text(_displayValue(item)) : Text(item.toString()),
      ),
  ];
}

Future<bool?> _confirmDelete(BuildContext context, String message) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: Text(message),
        actions: [
          FantasyTextButton(
            label: 'Abbrechen',
            style: FantasyButtonStyle.iron,
            onPressed: () => Navigator.pop(context, false),
          ),
          FantasyTextButton(
            label: 'Endgültig löschen',
            style: FantasyButtonStyle.wax,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

Future<String?> _importText(
  BuildContext context,
  String title,
  BackupFiles files,
) => showImportBackupDialog(context, title: title, files: files);

Future<void> _showExport(
  BuildContext context,
  String title,
  String json,
  BackupFiles files,
  String name,
) => showExportBackupDialog(
  context,
  title: title,
  json: json,
  files: files,
  name: name,
);

Future<void> _showInventory(BuildContext context, HeroCharacter hero) {
  final data = hero.toJson();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FantasyBackdrop(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FantasySectionTitle(
              title: 'Inventar · ${hero.name}',
              icon: Icons.backpack_outlined,
            ),
            FantasyPanel(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FantasyStatTile(
                    icon: Icons.monetization_on_outlined,
                    title: 'Gold',
                    value: '${data['gold'] ?? '–'}',
                  ),
                  FantasyStatTile(
                    icon: Icons.sports_martial_arts,
                    title: 'Waffenschaden',
                    value: hero.weaponDamage.isEmpty ? '–' : hero.weaponDamage,
                    color: FantasyPalette.blue,
                  ),
                  FantasyStatTile(
                    icon: Icons.verified_outlined,
                    title: 'Waffenübung',
                    value: hero.weaponProficient ? 'Ja' : 'Nein',
                    color: FantasyPalette.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const FantasySectionTitle(
              title: 'Gegenstände & Ausrüstung',
              icon: Icons.inventory_2_outlined,
            ),
            FantasyPanel(child: FantasyInventoryCards(items: hero.inventory)),
            const SizedBox(height: 20),
            for (final entry in const <String, String>{
              'spells': 'Zauber',
              'features': 'Klassenfähigkeiten',
              'conditions': 'Zustände',
            }.entries) ...[
              FantasySectionTitle(
                title: entry.value,
                icon: entry.key == 'inventory'
                    ? Icons.inventory_2_outlined
                    : entry.key == 'spells'
                    ? Icons.auto_awesome_outlined
                    : entry.key == 'conditions'
                    ? Icons.healing_outlined
                    : Icons.military_tech_outlined,
              ),
              FantasyPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _journalItems(
                    entry.key == 'conditions'
                        ? hero.conditions
                        : data[entry.key],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
