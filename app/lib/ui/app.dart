import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../services/backup_files.dart';
import '../services/game_controller.dart';
import '../services/voice_controller.dart';
import 'backend_settings_panel.dart';
import 'backup_dialogs.dart';
import 'character_editor.dart';
import 'campaign_memory_panel.dart';

const _gold = Color(0xffddb96c);
const _ink = Color(0xff0d1927);
const _forest = Color(0xff19382f);
const _parchment = Color(0xffeee6cf);
const _srdAttribution =
    'This work includes material from the System Reference Document 5.2.1 '
    '(“SRD 5.2.1”) by Wizards of the Coast LLC, available at '
    'https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the '
    'Creative Commons Attribution 4.0 International License, available at '
    'https://creativecommons.org/licenses/by/4.0/legalcode.';

ThemeData fantasyTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _gold,
    brightness: Brightness.dark,
    primary: _gold,
    secondary: const Color(0xff84b3a1),
    surface: _ink,
    onSurface: _parchment,
  ),
  scaffoldBackgroundColor: const Color(0xff08121e),
  appBarTheme: const AppBarTheme(
    backgroundColor: _ink,
    foregroundColor: _parchment,
  ),
  cardTheme: CardThemeData(
    color: _forest.withValues(alpha: .6),
    margin: const EdgeInsets.only(bottom: 12),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _ink,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  navigationBarTheme: const NavigationBarThemeData(backgroundColor: _ink),
);

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
      title: 'Der lebendige Spielleiter',
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
            ),
            _AdventurePage(
              controller: controller,
              backupFiles: _backupFiles,
              voice: widget.voice,
              onHome: () => setState(() => _page = 0),
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
              title: Text(
                const [
                  'Der lebendige Spielleiter',
                  'Abenteuer',
                  'Deine Helden',
                  'Kampagnen-Tagebuch',
                  'Einstellungen',
                ][_page],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                IconButton(
                  tooltip: 'Einstellungen',
                  onPressed: () => setState(() => _page = 4),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            body: SafeArea(
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
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: pages[_page],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _page,
              onDestinationSelected: (value) => setState(() => _page = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Start',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  label: 'Abenteuer',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Helden',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  label: 'Tagebuch',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune),
                  label: 'Optionen',
                ),
              ],
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
    required this.backupFiles,
  });
  final BackupFiles backupFiles;
  final GameController controller;
  final _Play onPlay;
  final VoidCallback onCharacters;

  Future<void> _newCampaign(BuildContext context, {bool ai = false}) async {
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
                  '${hero.species} · ${hero.className} · Stufe ${hero.level}',
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
    if (hero == null || !context.mounted) return;
    if (!ai) {
      onPlay(() => controller.newCampaign(hero));
      return;
    }
    var prompt = 'Epische Fantasy mit Geheimnissen, lebendigen NPCs und moralischen Entscheidungen';
    final theme = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eigene KI-Geschichte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Der verbundene Erzähldienst entwickelt eine neue Geschichte. '
                'Jeder weitere KI-Zug zählt zum vereinbarten Anfragelimit. '
                'Die Geschichte bleibt lokal gespeichert.'),
              const SizedBox(height: 14),
              TextFormField(initialValue: prompt, maxLength: 300, maxLines: 3,
                onChanged: (value) => prompt = value,
                decoration: const InputDecoration(labelText: 'Wunschthema')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.pop(context, prompt),
              child: const Text('Geschichte erstellen')),
          ],
        ),
      );
    if (theme != null && theme.trim().isNotEmpty) {
      onPlay(() => controller.newAiCampaign(hero, theme: theme.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_forest, _ink]),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _gold.withValues(alpha: .4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: _gold, size: 40),
              const SizedBox(height: 14),
              Text(
                'Deine Geschichte wartet.',
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
                  FilledButton.icon(
                    onPressed: controller.busy
                        ? null
                        : () => onPlay(controller.createDemo),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Kostenlose Demo starten'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.busy
                        ? null
                        : () => _newCampaign(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Neue Kampagne'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.busy || !controller.narrator.enabled
                        ? null : () => _newCampaign(context, ai: true),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(controller.narrator.provider == 'mock'
                        ? 'Testgeschichte starten' : 'KI-Kampagne erstellen'),
                  ),
                  TextButton.icon(
                    onPressed: onCharacters,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Helden verwalten'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (!controller.narrator.enabled) const _Notice(
          icon: Icons.auto_awesome_outlined,
          text: 'Für eine frei entwickelte KI-Kampagne zuerst unter „Optionen“ '
            'einen Spielleiter-Server verbinden und bei Bedarf ausdrücklich '
            'den kostenpflichtigen KI-Anbieter freigeben. Ohne Server bleibt die Demo verfügbar.',
        ),
        if (controller.narrator.enabled && controller.narrator.provider == 'mock')
          const _Notice(icon: Icons.science_outlined,
            text: 'Der verbundene Mock-Dienst erzeugt nur eine regelbasierte Testgeschichte. '
              'Für eine wirklich generierte Geschichte ist der OpenAI-Anbieter erforderlich.'),
        const _Notice(
          icon: Icons.offline_bolt_outlined,
          text:
              'Demo-Modus: Die lokale Erzähl- und Regelengine benötigt weder API-Schlüssel '
              'noch kostenpflichtigen Dienst. Die Antworten sind regelbasierte Szenen. '
              'Spracherkennung kann je nach Android-Dienst eine Internetverbindung benötigen.',
        ),
        const SizedBox(height: 16),
        Text('Deine Kampagnen', style: Theme.of(context).textTheme.titleLarge),
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
        for (final campaign in controller.campaigns)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: const Icon(Icons.auto_stories, color: _gold),
              title: Text(campaign.name),
              subtitle: Text(
                '${campaign.world} · ${campaign.hero.name}\n${campaign.scene}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              onTap: controller.busy
                  ? null
                  : () => onPlay(() => controller.openCampaign(campaign.id)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Kampagne löschen',
                onPressed: controller.busy
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
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Das Herz der Ewigkeit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Arescan steht in Silberhain neben der Elfenmagierin und einem verletzten '
          'Schattenritter. Sein rotes Amulett leuchtet. Der historische Angriff von 19 und '
          'der erzählte Schaden von 14 werden bewahrt; fehlende Charakterwerte bleiben unbestätigt.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: controller.busy
              ? null
              : () => onPlay(controller.createArescan),
          icon: const Icon(Icons.history_edu),
          label: const Text('Arescan-Spielstand laden'),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
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
          icon: const Icon(Icons.file_upload_outlined),
          label: const Text('Kampagne aus JSON importieren'),
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
      MaterialPageRoute(builder: (context) => CharacterEditor(hero: hero)),
    );
    if (result != null) await controller.saveStandaloneHero(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: controller.busy ? null : () => _edit(context, null),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Charakter erstellen'),
            ),
            OutlinedButton.icon(
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
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Importieren'),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hero.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${hero.species} · ${hero.className} · Stufe ${hero.level}',
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
                      TextButton.icon(
                        onPressed: controller.busy
                            ? null
                            : () => _edit(context, hero),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Bearbeiten'),
                      ),
                      TextButton.icon(
                        onPressed: () => _showExport(
                          context,
                          '${hero.name} exportieren',
                          controller.exportHero(hero),
                          backupFiles,
                          backupFileName(hero.name, kind: 'charakter'),
                        ),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Exportieren'),
                      ),
                      TextButton.icon(
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
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Löschen'),
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
    required this.backupFiles,
  });
  final BackupFiles backupFiles;
  final GameController controller;
  final VoiceController voice;
  final VoidCallback onHome;

  @override
  State<_AdventurePage> createState() => _AdventurePageState();
}

class _AdventurePageState extends State<_AdventurePage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _combat = false;

  @override
  void dispose() {
    unawaited(widget.voice.stopListening());
    unawaited(widget.voice.stopSpeaking());
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || widget.controller.busy) return;
    await widget.voice.stopListening();
    await widget.voice.stopSpeaking();
    final previousMessageId = _lastMessageId;
    await widget.controller.sendAction(text);
    if (!mounted) return;
    if (widget.controller.error == null) {
      _input.clear();
      await _afterTurn(previousMessageId);
    }
  }

  /// Read-only in-game recap; it never replaces an unfinished typed action.
  Future<void> _recap() async {
    if (widget.controller.busy) return;
    await widget.voice.stopListening();
    await widget.voice.stopSpeaking();
    final previousMessageId = _lastMessageId;
    await widget.controller.sendAction(
      'Fasse unsere bisherige Geschichte zusammen.',
    );
    if (mounted) await _afterTurn(previousMessageId);
  }

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

  Future<void> _editHero() async {
    final hero = widget.controller.currentCampaign?.hero;
    if (hero == null) return;
    final result = await Navigator.of(context).push<HeroCharacter>(
      MaterialPageRoute(builder: (context) => CharacterEditor(hero: hero)),
    );
    if (result != null) await widget.controller.saveHero(result);
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
    // Scene details share the scroll area with the story so the composer remains
    // reachable on small screens while the software keyboard is open.
    final header = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${campaign.hero.name} · TP ${campaign.hero.hitPoints ?? '?'}/${campaign.hero.maxHitPoints ?? '?'} '
                      '· RK ${campaign.hero.armorClass ?? '?'}',
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _editHero,
                tooltip: 'Charakterbogen bearbeiten',
                icon: const Icon(Icons.person_outline),
              ),
              IconButton(
                onPressed: () => _showInventory(context, campaign.hero),
                tooltip: 'Inventar öffnen',
                icon: const Icon(Icons.backpack_outlined),
              ),
              IconButton(
                onPressed: () => _showExport(
                  context,
                  'Spielstand exportieren',
                  widget.controller.exportCampaign(),
                  widget.backupFiles,
                  backupFileName(campaign.name),
                ),
                tooltip: 'Spielstand exportieren',
                icon: const Icon(Icons.file_download_outlined),
              ),
            ],
          ),
          BackendAdventureStatus(controller: widget.controller),
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
          if (encounter.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: _gold),
                Expanded(
                  child: Text(
                    _combat ? 'Kampfübersicht' : 'Eine Begegnung ist aktiv.',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _combat = !_combat),
                  child: Text(_combat ? 'Zur Erzählung' : 'Kampf ansehen'),
                ),
              ],
            ),
        ],
      ),
    );
    return Column(
      children: [
        Expanded(
          child: _combat && encounter.isNotEmpty
              ? _CombatView(
                  encounter: campaign.encounter!,
                  hero: campaign.hero,
                  onAction: (text) {
                    _input.text = text;
                    _send();
                  },
                  busy: widget.controller.busy,
                  header: header,
                )
              : ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  children: [
                    header,
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktuelle Szene',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(color: _gold),
                            ),
                            const SizedBox(height: 8),
                            Text(campaign.scene),
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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Würfelprobe ausstehend',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${pending['label'] ?? pending['type'] ?? 'Probe'} · '
                                'Modifikator ${_signed(pending['modifier'] ?? pending['bonus'] ?? 0)}',
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: widget.controller.busy
                                    ? null
                                    : _roll,
                                icon: const Icon(Icons.casino_outlined),
                                label: const Text('Wurf durchführen'),
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
          TextButton.icon(
            onPressed: widget.voice.stopSpeaking,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Vorlesen unterbrechen'),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
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
                  IconButton.filled(
                    onPressed: widget.controller.busy ? null : _send,
                    tooltip: 'Handlung senden',
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('adventure-memory-recap'),
                    onPressed: widget.controller.busy ? null : _recap,
                    icon: const Icon(Icons.history),
                    label: const Text('Rückblick'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.controller.busy ? null : _roll,
                    icon: const Icon(Icons.casino),
                    label: const Text('Würfeln'),
                  ),
                  Semantics(
                    label: widget.voice.listening
                        ? 'Mikrofon stoppen'
                        : 'Push-to-Talk. Halten zum Sprechen oder tippen zum Umschalten.',
                    button: true,
                    child: GestureDetector(
                      onLongPressStart: (_) {
                        if (!widget.voice.listening) _toggleMic();
                      },
                      onLongPressEnd: (_) => widget.voice.stopListening(),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(150, 56),
                          backgroundColor: widget.voice.listening
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        onPressed: widget.controller.busy ? null : _toggleMic,
                        icon: Icon(
                          widget.voice.listening ? Icons.mic : Icons.mic_none,
                        ),
                        label: Text(
                          widget.voice.listening ? 'Stopp' : 'Sprechen',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
          color: player ? _forest : _ink,
          border: Border.all(
            color: player
                ? const Color(0xff375c49)
                : _gold.withValues(alpha: .2),
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
                  IconButton(
                    onPressed: () => onSpeak(text),
                    tooltip: 'Diese Antwort vorlesen',
                    icon: const Icon(Icons.volume_up_outlined),
                    iconSize: 20,
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
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text(
            'TP ${hero.hitPoints ?? '?'}/${hero.maxHitPoints ?? '?'}',
          ),
        ),
        Chip(label: Text('RK ${hero.armorClass ?? '?'}')),
        Chip(label: Text('Bewegung ${hero.speed ?? '?'} m')),
        for (final entry in hero.abilities.entries)
          Chip(
            label: Text(
              '${const {'strength': 'STÄ', 'dexterity': 'GES', 'constitution': 'KON', 'intelligence': 'INT', 'wisdom': 'WEI', 'charisma': 'CHA'}[entry.key] ?? entry.key} ${entry.value ?? '?'}',
            ),
          ),
      ],
    );
  }
}

class _CombatView extends StatelessWidget {
  const _CombatView({
    required this.encounter,
    required this.hero,
    required this.onAction,
    required this.busy,
    required this.header,
  });
  final Encounter encounter;
  final HeroCharacter hero;
  final void Function(String) onAction;
  final bool busy;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        header,
        Text(
          'Runde ${encounter.round}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Aktiver Zug: ${encounter.activeParticipant == 'hero' ? hero.name : encounter.enemyName}',
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: _gold),
            title: Text(hero.name),
            subtitle: Text(
              'Initiative ${encounter.heroInitiative} · '
              'TP ${hero.hitPoints ?? '?'}/${hero.maxHitPoints ?? '?'} · RK ${hero.armorClass ?? '?'}',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(encounter.enemyName),
            subtitle: Text(
              'Initiative ${encounter.enemyInitiative} · '
              'TP ${encounter.enemyHitPoints}/${encounter.enemyMaxHitPoints} · RK ${encounter.enemyArmorClass}',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(
                'Aktion: ${encounter.actionUsed ? 'verbraucht' : 'verfügbar'}',
              ),
            ),
            Chip(
              label: Text(
                'Bonusaktion: ${encounter.bonusActionUsed ? 'verbraucht' : 'verfügbar'}',
              ),
            ),
            Chip(
              label: Text(
                'Reaktion: ${encounter.reactionUsed ? 'verbraucht' : 'verfügbar'}',
              ),
            ),
            Chip(label: Text('Bewegung: ${encounter.movementRemaining} m')),
          ],
        ),
        const SizedBox(height: 20),
        Text('Deine Handlung', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Text(
          'Beschreibe deinen Angriff oder deine Entscheidung. Trefferpunkte '
          'ändern sich erst nach einer bestätigten Probe durch die Regelengine. '
          'Der Solo-Kampf löst den Gegnerzug automatisch nach deiner Aktion auf.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: busy || encounter.isFinished
                  ? null
                  : () => onAction('Ich greife an.'),
              icon: const Icon(Icons.sports_martial_arts),
              label: const Text('Angreifen'),
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => onAction('Ich versuche zu fliehen.'),
              child: const Text('Fliehen'),
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => onAction('Ich untersuche meinen Gegner.'),
              child: const Text('Gegner untersuchen'),
            ),
          ],
        ),
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
        Text(campaign.name, style: Theme.of(context).textTheme.headlineSmall),
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
        _JournalSection(
          title: 'Ereignisprotokoll',
          icon: Icons.history,
          children: _journalItems(data['events']),
        ),
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
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
        Text('Sprache & Audio', style: Theme.of(context).textTheme.titleLarge),
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
        OutlinedButton.icon(
          key: const ValueKey('refresh-voices'),
          onPressed: voice.refreshingVoices ? null : voice.refreshVoices,
          icon: Icon(
            voice.refreshingVoices ? Icons.hourglass_top : Icons.refresh,
          ),
          label: Text(
            voice.refreshingVoices
                ? 'Stimmen werden geprüft …'
                : 'Stimmen neu prüfen',
          ),
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
            OutlinedButton.icon(
              key: const ValueKey('test-voice'),
              onPressed: canChooseVoice
                  ? () => voice.speak(
                      'Willkommen in Aetheria. Deine Geschichte wartet auf dich.',
                    )
                  : null,
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Stimme testen'),
            ),
            TextButton(
              key: const ValueKey('stop-voice'),
              onPressed: voice.stopSpeaking,
              child: const Text('Wiedergabe stoppen'),
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
        Text('KI & Kosten', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        BackendSettingsPanel(controller: controller),
        const SizedBox(height: 24),
        Text(
          'Datenschutz & Spielstände',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Charaktere und Kampagnen bleiben lokal in der App. Du kannst sie einzeln '
          'als JSON sichern oder löschen. Die App speichert keine Audioaufzeichnungen. '
          'Deinstallation kann lokale Daten entfernen: exportiere wichtige Spielstände vorher.',
        ),
        const SizedBox(height: 12),
        if (controller.currentCampaign != null)
          OutlinedButton.icon(
            onPressed: () => _showExport(
              context,
              'Spielstand sichern',
              controller.exportCampaign(),
              backupFiles,
              backupFileName(controller.currentCampaign!.name),
            ),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Aktuelle Kampagne exportieren'),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
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
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Alle lokalen Spieldaten löschen'),
        ),
        const SizedBox(height: 24),
        Text('Lizenz & Inhalte', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Text(
          'Eigenständiges Fantasy-Rollenspiel mit einem ausgewählten Regelkern des '
          'System Reference Document 5.2.1. Nicht alle Klassenfähigkeiten und '
          'Zauberregeln des SRD sind bereits umgesetzt.',
        ),
        const SizedBox(height: 12),
        const SelectableText(_srdAttribution),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Der lebendige Spielleiter',
          ),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Softwarelizenzen anzeigen'),
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
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(const _ManualRoll()),
              icon: const Icon(Icons.casino),
              label: const Text('Automatisch würfeln'),
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
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        onPressed: _confirm,
        child: const Text('Manuellen Wurf bestätigen'),
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
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton.icon(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          final modifier = int.parse(_modifier.text);
          Navigator.pop(
            context,
            '${int.parse(_count.text)}d$_sides${modifier == 0 ? '' : _signed(modifier)}',
          );
        },
        icon: const Icon(Icons.casino),
        label: const Text('Würfeln'),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Endgültig löschen'),
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
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Inventar · ${hero.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text('Gold: ${data['gold'] ?? 'unbekannt'}'),
          const SizedBox(height: 12),
          Text(
            'Waffenschaden: ${hero.weaponDamage.isEmpty ? 'Nicht bestätigt' : hero.weaponDamage} · '
            'Waffenübung: ${hero.weaponProficient ? 'ja' : 'nein'}',
          ),
          const SizedBox(height: 20),
          for (final entry in const <String, String>{
            'inventory': 'Gegenstände, Waffen & Ausrüstung',
            'spells': 'Zauber',
            'features': 'Klassenfähigkeiten',
            'conditions': 'Zustände',
          }.entries) ...[
            Text(entry.value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._journalItems(data[entry.key]),
          ],
        ],
      ),
    ),
  );
}
