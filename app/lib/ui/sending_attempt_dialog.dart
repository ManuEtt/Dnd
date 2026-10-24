import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../domain/spellcasting_rules.dart';
import '../domain/srd_sending_cast_preflight_rules.dart';
import '../domain/srd_sending_rules.dart';
import '../domain/srd_spell_catalog.dart';
import 'fantasy_buttons.dart';
import 'fantasy_ui.dart';

/// The UI returns a read-only, validated preview. Only GameController can
/// charge resources and persist a receipt after the dialog is dismissed.
class SendingAttemptChoice {
  const SendingAttemptChoice({
    required this.preview,
    required this.requestId,
  });

  final SrdSendingCastPreview preview;
  final String requestId;
}

class SendingAttemptDialog extends StatefulWidget {
  const SendingAttemptDialog({
    super.key,
    required this.hero,
    required this.sending,
  });

  final HeroCharacter hero;
  final SrdSpellDefinition sending;

  @override
  State<SendingAttemptDialog> createState() => _SendingAttemptDialogState();
}

class _SendingAttemptDialogState extends State<SendingAttemptDialog> {
  final _recipient = TextEditingController();
  final _message = TextEditingController();
  final _percentile = TextEditingController();
  // Generated once for this exact approval, rather than on each rebuild.
  final String _requestId = 'sending_${const Uuid().v4().replaceAll('-', '_')}';

  String? _castingClass;
  int? _slotLevel;
  bool _pactMagic = false;
  SendingRecipientKnowledge _knowledge = SendingRecipientKnowledge.unverified;
  SendingBlockStatus _block = SendingBlockStatus.unverified;
  SendingPlaneRelation _plane = SendingPlaneRelation.unverified;
  bool _creatureConfirmed = false;
  bool _actionConfirmed = false;
  bool _componentsConfirmed = false;
  bool _approved = false;

  List<String> get _eligibleClasses => [
    for (final name in [
      widget.hero.className,
      if (widget.hero.hasSecondClass) widget.hero.secondaryClassName,
    ])
      if (const ['Magier', 'Kleriker', 'Barde'].contains(name)) name,
  ].toSet().toList();

  Map<int, int> get _slots => SpellcastingRules.availableSlots(widget.hero);

  List<int> get _regularGrades => [
    for (final entry in _slots.entries)
      if (entry.key >= 3 && entry.value > 0) entry.key,
  ];

  @override
  void initState() {
    super.initState();
    final classes = _eligibleClasses;
    if (classes.isNotEmpty) _castingClass = classes.first;
    try {
      final grades = _regularGrades;
      if (grades.isNotEmpty) _slotLevel = grades.first;
    } on FormatException {
      // An invalid imported resource pool is handled by the preflight.
    }
  }

  @override
  void dispose() {
    _recipient.dispose();
    _message.dispose();
    _percentile.dispose();
    super.dispose();
  }

  void _change(VoidCallback update) {
    setState(() {
      update();
      _approved = false;
    });
  }

  String _outcome(SendingDeliveryOutcome value) => switch (value) {
    SendingDeliveryOutcome.unresolved =>
      'Zustellung ungeklärt – keine Erfolgsaussage.',
    SendingDeliveryOutcome.blocked =>
      'Bestätigte Blockade – keine Zustellung behauptet.',
    SendingDeliveryOutcome.planarFailure =>
      'Bestätigter Ebenenwurf: der Zustellversuch scheitert.',
    SendingDeliveryOutcome.deliverable =>
      'Regel-Vorprüfung günstig; keine tatsächliche Zustellung.',
  };

  @override
  Widget build(BuildContext context) {
    final classes = _eligibleClasses;
    List<int> grades = [];
    String? failure;
    try {
      grades = _regularGrades;
    } catch (error) {
      failure = error.toString();
    }
    bool pactAvailable = false;
    try {
      pactAvailable = SpellcastingRules.pactSlotLevel(widget.hero) >= 3 &&
          SpellcastingRules.availablePactSlots(widget.hero) > 0;
    } on FormatException catch (error) {
      failure = error.message;
    }
    final selectedGrade = _pactMagic
        ? SpellcastingRules.pactSlotLevel(widget.hero)
        : _slotLevel;
    final hasSlot = selectedGrade != null &&
        (_pactMagic ? pactAvailable : grades.contains(selectedGrade));
    SrdSendingCastPreview? preview;
    if (_recipient.text.trim().isNotEmpty &&
        _message.text.trim().isNotEmpty &&
        _castingClass != null &&
        hasSlot &&
        _creatureConfirmed &&
        _actionConfirmed &&
        _componentsConfirmed) {
      try {
        preview = SrdSendingCastPreflightRules.preview(
          widget.hero,
          spell: widget.sending,
          castingClass: _castingClass!,
          slotLevel: selectedGrade!,
          pactMagic: _pactMagic,
          recipientId: _recipient.text,
          message: _message.text,
          recipientKnowledge: _knowledge,
          recipientIsCreatureConfirmed: _creatureConfirmed,
          blockStatus: _block,
          planeRelation: _plane,
          percentileRoll:
              _block != SendingBlockStatus.blockedConfirmed &&
                  _plane == SendingPlaneRelation.differentPlaneConfirmed
              ? int.tryParse(_percentile.text)
              : null,
          actionAvailableConfirmed: _actionConfirmed,
          slotTurnLimitConfirmed: _actionConfirmed,
          verbalComponentConfirmed: _componentsConfirmed,
          somaticComponentConfirmed: _componentsConfirmed,
          materialComponentConfirmed: _componentsConfirmed,
        );
      } catch (error) {
        failure = error.toString().replaceFirst('FormatException: ', '');
      }
    }
    final canApprove = preview != null && _approved;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      title: const Text('Sending – Zauberversuch'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Dieser Dialog dokumentiert nur einen bestätigten '
                'Zauberversuch und verbraucht einen Zauberplatz. '
                'Er verschickt keine Nachricht und erzeugt keine Antwort.',
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('sending-recipient'),
                controller: _recipient,
                maxLength: 160,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Eindeutige Empfängerkennung',
                  helperText: 'Keine Leerzeichen, z. B. npc-tarek',
                ),
                onChanged: (_) => _change(() {}),
              ),
              DropdownButtonFormField<SendingRecipientKnowledge>(
                key: const ValueKey('sending-knowledge'),
                initialValue: _knowledge,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Woher kennst du die Kreatur?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: SendingRecipientKnowledge.unverified,
                    child: Text('Nicht bestätigt'),
                  ),
                  DropdownMenuItem(
                    value: SendingRecipientKnowledge.personallyMet,
                    child: Text('Persönlich getroffen'),
                  ),
                  DropdownMenuItem(
                    value: SendingRecipientKnowledge.describedByEyewitness,
                    child: Text('Von Augenzeugen beschrieben'),
                  ),
                ],
                onChanged: (value) => _change(
                  () => _knowledge = value ?? SendingRecipientKnowledge.unverified,
                ),
              ),
              CheckboxListTile(
                key: const ValueKey('sending-creature'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Empfänger ist als Kreatur bestätigt'),
                value: _creatureConfirmed,
                onChanged: (value) =>
                    _change(() => _creatureConfirmed = value ?? false),
              ),
              TextField(
                key: const ValueKey('sending-message'),
                controller: _message,
                minLines: 2,
                maxLines: 3,
                maxLength: SrdSendingRules.maxMessageCodeUnits,
                decoration: const InputDecoration(
                  labelText: 'Nachricht (höchstens 25 Wörter)',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => _change(() {}),
              ),
              DropdownButtonFormField<String>(
                key: const ValueKey('sending-class'),
                initialValue: _castingClass,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Zauberklasse'),
                items: [
                  for (final name in classes)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (value) =>
                    _change(() => _castingClass = value),
              ),
              if (grades.isNotEmpty)
                DropdownButtonFormField<int>(
                  key: ValueKey('sending-slot-$_pactMagic'),
                  initialValue: _pactMagic ? null : _slotLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Verbrauchter Zauberplatz',
                  ),
                  items: [
                    for (final grade in grades)
                      DropdownMenuItem(
                        value: grade,
                        child: Text('Grad $grade – ${_slots[grade]} frei'),
                      ),
                  ],
                  onChanged: _pactMagic
                      ? null
                      : (value) => _change(() => _slotLevel = value),
                ),
              if (pactAvailable)
                SwitchListTile.adaptive(
                  key: const ValueKey('sending-pact'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Paktmagieplatz verwenden'),
                  subtitle: Text(
                    'Grad ${SpellcastingRules.pactSlotLevel(widget.hero)} '
                    '– ${SpellcastingRules.availablePactSlots(widget.hero)} frei',
                  ),
                  value: _pactMagic,
                  onChanged: (value) => _change(() => _pactMagic = value),
                ),
              DropdownButtonFormField<SendingBlockStatus>(
                key: const ValueKey('sending-block'),
                initialValue: _block,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Empfangsblockade (8 Stunden)',
                ),
                items: const [
                  DropdownMenuItem(
                    value: SendingBlockStatus.unverified,
                    child: Text('Unbekannt'),
                  ),
                  DropdownMenuItem(
                    value: SendingBlockStatus.blockedConfirmed,
                    child: Text('Blockiert – bestätigt'),
                  ),
                  DropdownMenuItem(
                    value: SendingBlockStatus.notBlockedConfirmed,
                    child: Text('Nicht blockiert – bestätigt'),
                  ),
                ],
                onChanged: (value) => _change(
                  () => _block = value ?? SendingBlockStatus.unverified,
                ),
              ),
              DropdownButtonFormField<SendingPlaneRelation>(
                key: const ValueKey('sending-plane'),
                initialValue: _plane,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ebene des Ziels'),
                items: const [
                  DropdownMenuItem(
                    value: SendingPlaneRelation.unverified,
                    child: Text('Unbekannt'),
                  ),
                  DropdownMenuItem(
                    value: SendingPlaneRelation.samePlaneConfirmed,
                    child: Text('Gleiche Ebene – bestätigt'),
                  ),
                  DropdownMenuItem(
                    value: SendingPlaneRelation.differentPlaneConfirmed,
                    child: Text('Andere Ebene – bestätigt'),
                  ),
                ],
                onChanged: (value) => _change(() {
                  _plane = value ?? SendingPlaneRelation.unverified;
                  _percentile.clear();
                }),
              ),
              if (_block != SendingBlockStatus.blockedConfirmed &&
                  _plane == SendingPlaneRelation.differentPlaneConfirmed)
                TextField(
                  key: const ValueKey('sending-percentile'),
                  controller: _percentile,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bestätigter W100 (1–100)',
                  ),
                  onChanged: (_) => _change(() {}),
                ),
              CheckboxListTile(
                key: const ValueKey('sending-action'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Aktion verfügbar; höchstens ein Zauberplatz in diesem Zug',
                ),
                value: _actionConfirmed,
                onChanged: (value) =>
                    _change(() => _actionConfirmed = value ?? false),
              ),
              CheckboxListTile(
                key: const ValueKey('sending-components'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Sprechen, Gesten und Kupferdraht sind bestätigt',
                ),
                value: _componentsConfirmed,
                onChanged: (value) =>
                    _change(() => _componentsConfirmed = value ?? false),
              ),
              const SizedBox(height: 8),
              FantasyPanel(
                padding: const EdgeInsets.all(10),
                material: FantasyPanelMaterial.parchment,
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verbindliche Kostenvorschau',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        hasSlot
                            ? '1 ${_pactMagic ? 'Paktmagieplatz' : 'Zauberplatz'} '
                                  'Grad $selectedGrade'
                            : 'Kein passender bestätigter Zauberplatz.',
                      ),
                      if (preview != null) ...[
                        Text(
                          'Danach: ${preview.remainingSlotsIfCommitted} '
                          'Platz/Plätze verfügbar',
                          key: const ValueKey('sending-cost-preview'),
                        ),
                        Text('Wörter: ${preview.recipient.wordCount} / 25'),
                        Text(
                          _outcome(preview.assessment.outcome),
                          key: const ValueKey('sending-delivery-preview'),
                        ),
                      ],
                      if (failure != null)
                        Text(
                          failure,
                          key: const ValueKey('sending-validation'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              CheckboxListTile(
                key: const ValueKey('sending-consent'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Ich bestätige den unveränderten Text, '
                  'den Empfänger und den Verbrauch ausdrücklich.',
                ),
                value: _approved,
                onChanged: preview == null
                    ? null
                    : (value) => setState(() => _approved = value ?? false),
              ),
            ],
          ),
        ),
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        FantasyTextButton(
          key: const ValueKey('sending-cancel'),
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.of(context).pop(),
        ),
        FantasyTextButton(
          key: const ValueKey('sending-confirm'),
          label: 'Versuch verbindlich buchen',
          style: FantasyButtonStyle.arcane,
          onPressed: canApprove
              ? () => Navigator.of(context).pop(
                  SendingAttemptChoice(
                    preview: preview!,
                    requestId: _requestId,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
