import 'package:flutter/material.dart';

import '../data/game_repository.dart';
import '../domain/models.dart';
import '../domain/rules_engine.dart';
import '../services/mock_game_master.dart';
import '../services/voice_service.dart';

const _navy = Color(0xFF101D2C);
const _gold = Color(0xFFE5C279);

class AetheriaApp extends StatelessWidget {
  const AetheriaApp({super.key, required this.repository});
  final GameRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Aetheria – Der lebendige Spielleiter',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _gold, brightness: Brightness.dark,
        surface: _navy,
      ),
      scaffoldBackgroundColor: _navy,
      appBarTheme: const AppBarTheme(backgroundColor: _navy),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: CardThemeData(color: const Color(0xFF1D3041)),
    ),
    home: HomeScreen(repository: repository),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});
  final GameRepository repository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<(List<CharacterSheet>, List<Campaign>)> _data;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<(List<CharacterSheet>, List<Campaign>)> _fetch() async {
    final heroes = await widget.repository.characters();
    final campaigns = await widget.repository.campaigns();
    return (heroes, campaigns);
  }

  void _reload() { _data = _fetch(); }

  Future<void> _editCharacter([CharacterSheet? character]) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CharacterEditor(repository: widget.repository, original: character),
    ));
    if (mounted) setState(_reload);
  }

  Future<void> _newCampaign(List<CharacterSheet> heroes) async {
    if (heroes.isEmpty) {
      await _editCharacter();
      return;
    }
    String chosen = heroes.first.id;
    final nameController = TextEditingController(text: 'Eine neue Reise');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
        title: const Text('Neue Kampagne'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Titel')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: chosen,
            items: heroes.map((hero) => DropdownMenuItem(value: hero.id, child: Text(hero.name))).toList(),
            onChanged: (value) { if (value != null) refresh(() => chosen = value); },
            decoration: const InputDecoration(labelText: 'Held'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Erstellen')),
        ],
      )),
    );
    if (accepted == true && nameController.text.trim().isNotEmpty) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      await widget.repository.createCampaign(Campaign(
        id: 'custom-$id', title: nameController.text.trim(), heroId: chosen,
        location: 'Aetheria – am Beginn eines neuen Weges',
        scene: 'Du stehst auf einer Anhöhe. Jenseits des Flusses erhebt sich ein geheimnisvoller Wald.',
      ));
      if (mounted) setState(_reload);
    }
    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Aetheria'), actions: [
      IconButton(tooltip: 'Aktualisieren', onPressed: () => setState(_reload), icon: const Icon(Icons.refresh)),
    ]),
    body: FutureBuilder<(List<CharacterSheet>, List<Campaign>)>(
      future: _data,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) return Center(child: Text('Fehler: ${snapshot.error}'));
          return const Center(child: CircularProgressIndicator());
        }
        final (heroes, campaigns) = snapshot.data!;
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Icon(Icons.auto_stories, color: _gold, size: 64),
          const SizedBox(height: 8),
          const Text('Der lebendige Spielleiter', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Offline-Demo · Deutsch · Solo-Abenteuer', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: () => _newCampaign(heroes), icon: const Icon(Icons.add),
              label: const Text('Neue Kampagne')),
          OutlinedButton.icon(onPressed: () => _editCharacter(), icon: const Icon(Icons.person_add),
              label: const Text('Neuen Charakter erstellen')),
          const SizedBox(height: 18),
          const Text('Deine Abenteuer', style: TextStyle(fontSize: 20, color: _gold)),
          for (final campaign in campaigns)
            Card(child: ListTile(
              title: Text(campaign.title),
              subtitle: Text('${campaign.location} · Runde ${campaign.turn}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => AdventureScreen(repository: widget.repository, campaignId: campaign.id),
              )).then((_) { if (mounted) setState(_reload); }),
            )),
          const SizedBox(height: 18),
          const Text('Charaktere', style: TextStyle(fontSize: 20, color: _gold)),
          for (final hero in heroes)
            Card(child: ListTile(
              title: Text(hero.name),
              subtitle: Text('${hero.species} · ${hero.characterClass} · Stufe ${hero.level}${hero.isComplete ? '' : ' · Unvollständig'}'),
              trailing: const Icon(Icons.edit), onTap: () => _editCharacter(hero),
            )),
          const SizedBox(height: 12),
          const Text('Alle Antworten im Demo-Modus sind vorgegebene, lokale Erzählzweige. Es ist noch keine Live-KI angebunden.',
              style: TextStyle(fontSize: 12, color: Colors.white60)),
        ]);
      },
    ),
  );
}

class CharacterEditor extends StatefulWidget {
  const CharacterEditor({super.key, required this.repository, this.original});
  final GameRepository repository;
  final CharacterSheet? original;
  @override
  State<CharacterEditor> createState() => _CharacterEditorState();
}

class _CharacterEditorState extends State<CharacterEditor> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _className;
  late final Map<String, TextEditingController> _abilities;
  late final TextEditingController _hp;
  late final TextEditingController _ac;

  @override
  void initState() {
    super.initState();
    final hero = widget.original;
    _name = TextEditingController(text: hero?.name ?? '');
    _species = TextEditingController(text: hero?.species ?? 'Mensch');
    _className = TextEditingController(text: hero?.characterClass ?? 'Waldläufer');
    _abilities = {
      for (final name in abilityNames)
        name: TextEditingController(text: hero?.abilities[name]?.toString() ?? ''),
    };
    _hp = TextEditingController(text: hero?.hp?.toString() ?? '');
    _ac = TextEditingController(text: hero?.armorClass?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _species.dispose(); _className.dispose();
    _hp.dispose(); _ac.dispose();
    for (final controller in _abilities.values) { controller.dispose(); }
    super.dispose();
  }

  int? _number(String text) => text.trim().isEmpty ? null : int.tryParse(text.trim());
  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final original = widget.original;
    final scoreMap = {for (final field in _abilities.entries) field.key: _number(field.value.text)};
    final hero = CharacterSheet(
      id: original?.id ?? 'hero-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(), species: _species.text.trim(),
      characterClass: _className.text.trim(), level: original?.level ?? 1,
      background: original?.background ?? '', backstory: original?.backstory ?? '',
      abilities: scoreMap, hp: _number(_hp.text),
      maxHp: original?.maxHp ?? _number(_hp.text),
      armorClass: _number(_ac.text), gold: original?.gold,
      experience: original?.experience ?? 0, inventory: original?.inventory ?? [],
    );
    await widget.repository.saveCharacter(hero);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.original == null ? 'Held erstellen' : 'Charakterbogen')),
    body: Form(key: _key, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Unbekannte Werte dürfen leer bleiben. Für vollständige Regelprüfungen müssen sie ergänzt werden.'),
      const SizedBox(height: 16),
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) => value == null || value.trim().isEmpty ? 'Name fehlt' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _species, decoration: const InputDecoration(labelText: 'Spezies'),
          validator: (value) => value == null || value.trim().isEmpty ? 'Spezies fehlt' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _className, decoration: const InputDecoration(labelText: 'Klasse'),
          validator: (value) => value == null || value.trim().isEmpty ? 'Klasse fehlt' : null),
      const Padding(padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Attribute (1–20)', style: TextStyle(fontSize: 20, color: _gold))),
      for (final name in abilityNames) ...[
        TextFormField(
          controller: _abilities[name], keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: name),
          validator: (v) { final n = _number(v ?? ''); return v != null && v.isNotEmpty && (n == null || n < 1 || n > 20) ? 'Wert 1–20 oder leer' : null; },
        ),
        const SizedBox(height: 10),
      ],
      TextFormField(controller: _hp, decoration: const InputDecoration(labelText: 'Aktuelle Trefferpunkte (optional)'),
          keyboardType: TextInputType.number,
          validator: (v) { final n = _number(v ?? ''); return v != null && v.isNotEmpty && (n == null || n < 0) ? 'Ungültige TP' : null; }),
      const SizedBox(height: 12),
      TextFormField(controller: _ac, decoration: const InputDecoration(labelText: 'Rüstungsklasse (optional)'),
          keyboardType: TextInputType.number,
          validator: (v) { final n = _number(v ?? ''); return v != null && v.isNotEmpty && (n == null || n < 1) ? 'Ungültige RK' : null; }),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Charakter speichern')),
      const SizedBox(height: 20),
    ])),
  );
}

class AdventureScreen extends StatefulWidget {
  const AdventureScreen({super.key, required this.repository, required this.campaignId});
  final GameRepository repository;
  final String campaignId;
  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  final _message = TextEditingController();
  final _voice = VoiceService();
  final _story = const MockGameMaster();
  Campaign? _campaign;
  CharacterSheet? _hero;
  List<GameEvent> _events = [];
  bool _busy = false;
  bool _voiceReady = false;
  bool _autoSpeak = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _voice.initialize().then((ready) {
      if (mounted) setState(() => _voiceReady = ready);
    }).catchError((Object error) {
      if (mounted) setState(() => _error = 'Audio: $error');
      return false;
    });
  }

  Future<void> _load() async {
    try {
      final campaign = await widget.repository.campaign(widget.campaignId);
      if (campaign == null) throw StateError('Kampagne nicht vorhanden');
      final hero = await widget.repository.character(campaign.heroId);
      final events = await widget.repository.events(campaign.id);
      if (mounted) setState(() { _campaign = campaign; _hero = hero; _events = events; });
    } catch (e) { if (mounted) setState(() => _error = '$e'); }
  }

  Future<void> _send() async {
    if (_busy || _campaign == null || _hero == null || _message.text.trim().isEmpty) return;
    final text = _message.text.trim();
    setState(() { _busy = true; _error = null; });
    try {
      final answer = _story.respond(_campaign!, text, _hero!);
      await widget.repository.appendTurn(expected: _campaign!, playerText: text, narratorText: answer);
      _message.clear();
      await _load();
      if (_autoSpeak) {
        try {
          await _voice.speak(answer);
        } catch (audioError) {
          if (mounted) setState(() => _error = 'Text gespeichert; Vorlesen nicht verfügbar: $audioError');
        }
      }
    } catch (e) { if (mounted) setState(() => _error = '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _microphone() async {
    try {
      if (_voice.listening) {
        await _voice.stopListening();
      } else {
        await _voice.stopSpeaking();
        await _voice.listen((words) { if (mounted) setState(() => _message.text = words); });
      }
      if (mounted) setState(() {});
    } catch (e) { if (mounted) setState(() => _error = 'Mikrofon: $e'); }
  }

  Future<void> _rollDialog() async {
    final campaign = _campaign;
    final hero = _hero;
    if (campaign == null || hero == null) return;
    int sides = 20;
    bool manual = false;
    final entered = TextEditingController();
    final decision = await showDialog<(int, bool, String)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
        title: const Text('Würfelprobe'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButton<int>(value: sides, isExpanded: true,
            items: RulesEngine.supportedDice.map((v) => DropdownMenuItem(value: v, child: Text('W$v'))).toList(),
            onChanged: (v) { if (v != null) refresh(() => sides = v); }),
          SwitchListTile(title: const Text('Echte Würfel'), value: manual,
              onChanged: (v) => refresh(() => manual = v)),
          if (manual) TextField(controller: entered, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Natürliches Würfelergebnis')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, (sides, manual, entered.text)), child: const Text('Würfeln')),
        ],
      )),
    );
    entered.dispose();
    if (decision == null) return;
    final (die, isManual, input) = decision;
    try {
      // We show ONLY a known dexterity modifier and no unconfirmed proficiency.
      final dexMod = die == 20 ? RulesEngine.dexterityModifier(hero) : null;
      final result = isManual
          ? RulesEngine.manualCheck(int.parse(input), sides: die, modifier: dexMod ?? 0)
          : RulesEngine.rollCheck(RandomDice(), sides: die, modifier: dexMod ?? 0);
      final unconfirmed = die == 20 && dexMod == null;
      final details = 'W$die: natürlich ${result.natural}, '
          'bestätigter Modifikator ${result.modifier >= 0 ? '+' : ''}${result.modifier}, '
          'Zwischensumme ${result.total}${unconfirmed ? ' (Geschicklichkeit unbekannt, keine vollständige Probe)' : ' (kein Übungsbonus eingerechnet)'}';
      await widget.repository.appendRoll(campaign: campaign, details: details, data: {
        'sides': die, 'natural': result.natural, 'modifier': result.modifier,
        'subtotal': result.total, 'manual': isManual, 'incomplete': unconfirmed,
      });
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(details)));
    } catch (e) { if (mounted) setState(() => _error = 'Ungültiger Wurf: $e'); }
  }

  @override
  void dispose() {
    _message.dispose();
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaign = _campaign;
    return Scaffold(
      appBar: AppBar(title: Text(campaign?.title ?? 'Abenteuer'), actions: [
        IconButton(tooltip: 'Vorlesen stoppen', onPressed: _voice.stopSpeaking,
            icon: const Icon(Icons.volume_off)),
        IconButton(tooltip: 'Tagebuch', onPressed: campaign == null ? null : () => Navigator.push(
          context, MaterialPageRoute<void>(builder: (_) => JournalScreen(events: _events))),
          icon: const Icon(Icons.menu_book)),
      ]),
      body: campaign == null
          ? Center(child: Text(_error ?? 'Spielstand wird geladen ...'))
          : Column(children: [
              Container(width: double.infinity, padding: const EdgeInsets.all(14), color: const Color(0xFF1A3540),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(campaign.location, style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5), Text(campaign.scene),
                  const SizedBox(height: 6),
                  Text('${_hero?.name ?? 'Unbekannter Held'} · TP ${_hero?.hp?.toString() ?? '?'} · RK ${_hero?.armorClass?.toString() ?? '?'}',
                    style: const TextStyle(color: Colors.white70)),
                  if (_hero != null && !_hero!.isComplete)
                    const Text('Charakterwerte unvollständig – Ergebnisse nur eingeschränkt regelprüfbar',
                        style: TextStyle(color: _gold, fontSize: 12)),
                ]),
              ),
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _events.length,
                itemBuilder: (_, i) {
                  final event = _events[i];
                  final player = event.type == 'player';
                  return Align(
                    alignment: player ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Card(color: player ? const Color(0xFF294B3A) : const Color(0xFF203548),
                        child: Padding(padding: const EdgeInsets.all(12), child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(event.type == 'historic' ? 'Bisherige Geschichte (ungeprüft)' :
                              player ? 'Du' : event.type == 'roll' ? 'Würfel' : 'Spielleiter',
                              style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4), Text(event.text),
                          ],
                        )),
                      ),
                    ),
                  );
                },
              )),
              if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
              SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
                Row(children: [
                  IconButton.filledTonal(tooltip: 'Würfeln', onPressed: _rollDialog,
                      icon: const Icon(Icons.casino)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _message, maxLines: 2, minLines: 1,
                    decoration: const InputDecoration(hintText: 'Was möchtest du tun?'))),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: _voiceReady ? 'Spracheingabe starten / stoppen' : 'Spracheingabe nicht verfügbar',
                    onPressed: _voiceReady ? _microphone : null,
                    icon: Icon(_voice.listening ? Icons.mic_off : Icons.mic),
                  ),
                  IconButton.filled(tooltip: 'Nachricht senden', onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send)),
                ]),
                Row(children: [
                  const Text('Antwort vorlesen'),
                  Switch(value: _autoSpeak, onChanged: (value) => setState(() => _autoSpeak = value)),
                  const Spacer(),
                  const Text('Mock-Spielleiter', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              ]))),
            ]),
    );
  }
}

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key, required this.events});
  final List<GameEvent> events;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kampagnentagebuch')),
    body: ListView.builder(padding: const EdgeInsets.all(12), itemCount: events.length,
      itemBuilder: (_, i) => Card(child: ListTile(
        title: Text(events[i].text),
        subtitle: Text('${events[i].type} · ${events[i].createdAt.toLocal().toString().substring(0, 16)}'),
      )),
    ),
  );
}
