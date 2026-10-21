import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/srd_initiative_roster_rules.dart';

class ManualTurnQueueChoice {
  const ManualTurnQueueChoice.create(
    this.actorIds, {
    required this.baseConfirmed,
    required this.tieConfirmed,
  }) : advance = false;

  const ManualTurnQueueChoice.advance()
    : actorIds = const [],
      baseConfirmed = false,
      tieConfirmed = false,
      advance = true;

  final List<String> actorIds;
  final bool baseConfirmed, tieConfirmed, advance;
}

/// Deliberately advisory; does not replace Encounter's combat engine.
class ManualTurnQueueDialog extends StatefulWidget {
  const ManualTurnQueueDialog({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<ManualTurnQueueDialog> createState() => _ManualTurnQueueDialogState();
}

class _ManualTurnQueueDialogState extends State<ManualTurnQueueDialog> {
  late final InitiativeRoster _roster;
  late final List<InitiativeRosterEntry> _actors;
  bool _baseConfirmed = false;
  bool _tiesConfirmed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _roster = SrdInitiativeRosterRules.preview(
      widget.campaign,
      baseInitiativeConfirmed: false,
    );
    _actors = [for (final group in _roster.groups) ...group.entries];
  }

  void _move(int index, int offset) {
    final other = index + offset;
    if (other < 0 ||
        other >= _actors.length ||
        _actors[index].total != _actors[other].total) {
      return;
    }
    setState(() {
      final previous = _actors[index];
      _actors[index] = _actors[other];
      _actors[other] = previous;
      _tiesConfirmed = false;
      _error = null;
    });
  }

  void _establish() {
    try {
      SrdInitiativeRosterRules.createManualQueue(
        widget.campaign,
        orderedActorIds: _actors.map((actor) => actor.id).toList(),
        baseInitiativeConfirmed: _baseConfirmed,
        tiedOrderConfirmed: _tiesConfirmed,
      );
      Navigator.of(context).pop(
        ManualTurnQueueChoice.create(
          _actors.map((actor) => actor.id).toList(),
          baseConfirmed: _baseConfirmed,
          tieConfirmed: _tiesConfirmed,
        ),
      );
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = widget.campaign.manualTurnQueue;
    final queueCurrent =
        queue != null &&
        SrdInitiativeRosterRules.isCurrent(widget.campaign, queue);
    return AlertDialog(
      title: const Text('Manuelle Kampf-Zugfolge'),
      content: SizedBox(
        width: 510,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Dies ist eine persistente Reihenfolge-Hilfe, '
                'keine automatische Mehrgegner-Kampfengine. '
                'Held und Hauptgegner nutzen weiterhin '
                'den bisherigen Kampfablauf.',
              ),
              if (queue != null) ...[
                const SizedBox(height: 12),
                Text('Manuelle Runde: ${queue.round}'),
                Text('Aktueller Marker: ${queue.activeActorId}'),
                if (!queueCurrent)
                  const Text(
                    'Die gespeicherte Zugfolge ist nach Änderungen '
                    'nicht mehr aktuell und muss neu bestätigt werden.',
                  ),
              ],
              if (_roster.missing.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Initiative fehlt: '
                  '${_roster.missing.map((x) => x.name).join(', ')}',
                ),
              ],
              const SizedBox(height: 12),
              const Text('Reihenfolge – nur Gleichstände umsortieren:'),
              for (var index = 0; index < _actors.length; index++)
                Row(
                  key: ValueKey('queue-entry-${_actors[index].id}'),
                  children: [
                    Expanded(
                      child: Text(
                        '${index + 1}. ${_actors[index].name} '
                        '(Initiative ${_actors[index].total})',
                      ),
                    ),
                    IconButton(
                      key: ValueKey('queue-up-${_actors[index].id}'),
                      tooltip: 'Bei Gleichstand nach oben',
                      onPressed:
                          index > 0 &&
                              _actors[index - 1].total == _actors[index].total
                          ? () => _move(index, -1)
                          : null,
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      key: ValueKey('queue-down-${_actors[index].id}'),
                      tooltip: 'Bei Gleichstand nach unten',
                      onPressed:
                          index + 1 < _actors.length &&
                              _actors[index + 1].total == _actors[index].total
                          ? () => _move(index, 1)
                          : null,
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                ),
              CheckboxListTile(
                key: const ValueKey('queue-base-confirmed'),
                value: _baseConfirmed,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Initiative von Held und Hauptgegner ist bestätigt.',
                ),
                onChanged: (value) => setState(() {
                  _baseConfirmed = value ?? false;
                  _error = null;
                }),
              ),
              if (_roster.hasUnresolvedTies)
                CheckboxListTile(
                  key: const ValueKey('queue-ties-confirmed'),
                  value: _tiesConfirmed,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Die angezeigte Reihenfolge aller Gleichstände '
                    'wurde von Spielern bzw. SL entschieden.',
                  ),
                  onChanged: (value) => setState(() {
                    _tiesConfirmed = value ?? false;
                    _error = null;
                  }),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
        if (queueCurrent)
          TextButton(
            key: const ValueKey('queue-advance'),
            onPressed: () => Navigator.of(
              context,
            ).pop(const ManualTurnQueueChoice.advance()),
            child: const Text('Manuellen Marker weiter'),
          ),
        FilledButton(
          key: const ValueKey('queue-establish'),
          onPressed: _roster.missing.isNotEmpty ? null : _establish,
          child: const Text('Zugfolge bestätigen'),
        ),
      ],
    );
  }
}
