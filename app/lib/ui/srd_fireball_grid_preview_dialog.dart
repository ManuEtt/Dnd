import 'package:flutter/material.dart';

import '../domain/srd_spell_catalog.dart';
import '../domain/srd_spell_grid_target_rules.dart';
import '../domain/srd_sphere_area_rules.dart';

enum _PreviewTool { caster, origin, wall }

/// Only a local planning aid. It never casts a spell, mutates a campaign,
/// charges a spell slot, changes HP or persists an inferred target.
class SrdFireballGridPreviewDialog extends StatefulWidget {
  const SrdFireballGridPreviewDialog({super.key, required this.fireball});

  final SrdSpellDefinition fireball;

  @override
  State<SrdFireballGridPreviewDialog> createState() =>
      _SrdFireballGridPreviewDialogState();
}

class _SrdFireballGridPreviewDialogState
    extends State<SrdFireballGridPreviewDialog> {
  int _size = 12;
  SrdGridCell _caster = const SrdGridCell(2, 5);
  SrdGridCell _origin = const SrdGridCell(6, 5);
  final Set<SrdGridCell> _walls = {};
  _PreviewTool _tool = _PreviewTool.origin;
  bool _surveyed = false;
  SrdSphereAreaPreview? _result;
  String? _error;

  void _invalidate() {
    _surveyed = false;
    _result = null;
    _error = null;
  }

  void _resize(int size) {
    setState(() {
      _size = size;
      _walls.clear();
      _caster = const SrdGridCell(2, 5);
      _origin = const SrdGridCell(6, 5);
      _invalidate();
    });
  }

  void _edit(SrdGridCell cell) {
    setState(() {
      if (_tool == _PreviewTool.caster) {
        if (_walls.contains(cell) || cell == _origin) {
          _error = 'Die Figur benötigt ein freies, eigenes Feld.';
          return;
        }
        _caster = cell;
      } else if (_tool == _PreviewTool.origin) {
        if (_walls.contains(cell)) {
          _error = 'Der Ursprung darf nicht in einem Vollhindernis liegen.';
          return;
        }
        _origin = cell;
      } else {
        if (cell == _caster || cell == _origin) {
          _error = 'Figur oder Ursprung darf nicht zur Wand werden.';
          return;
        }
        if (!_walls.add(cell)) _walls.remove(cell);
      }
      _invalidate();
    });
  }

  void _calculate() {
    try {
      if (widget.fireball.name != 'Fireball' ||
          widget.fireball.range != '150 feet') {
        throw const FormatException(
          'Die Vorschau ist nur für den SRD-Feuerball geprüft.',
        );
      }
      final map = SrdSpellGridMap(
        width: _size,
        height: _size,
        fullBlockers: _walls,
        fullBlockersSurveyedConfirmed: _surveyed,
      );
      final preview = SrdSphereAreaRules.previewConfirmedSpell(
        spell: widget.fireball,
        gridTarget: SrdSpellGridTargetRequest(
          map: map,
          caster: _caster,
          origin: _origin,
        ),
        sphereShapeVerifiedFromEffect: true,
        verifiedEffectRadiusFeet: 20,
      );
      setState(() {
        _result = preview;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _error = error.message;
      });
    } on UnsupportedError catch (error) {
      setState(() {
        _result = null;
        _error = error.toString();
      });
    }
  }

  Widget _grid() {
    const side = 26.0;
    final scheme = Theme.of(context).colorScheme;
    final candidates = {
      for (final entry in _result?.candidates ?? <SrdSphereCellCandidate>[])
        entry.cell: entry,
    };
    return SingleChildScrollView(
      key: const ValueKey('fireball-map-horizontal'),
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _size * side,
        height: _size * side,
        child: GridView.builder(
          key: const ValueKey('fireball-map-grid'),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _size,
          ),
          itemCount: _size * _size,
          itemBuilder: (_, index) {
            final cell = SrdGridCell(index % _size, index ~/ _size);
            final caster = cell == _caster;
            final origin = cell == _origin;
            final wall = _walls.contains(cell);
            final candidate = candidates[cell];
            final uncertain =
                candidate?.centerRay == SrdSphereCenterRay.requiresCoverReview;
            final color = caster
                ? scheme.primary
                : origin
                ? scheme.tertiary
                : wall
                ? scheme.onSurface
                : candidate == null
                ? scheme.surfaceContainerHighest
                : uncertain
                ? scheme.errorContainer
                : candidate.centerWithinRadius
                ? scheme.secondaryContainer
                : scheme.tertiaryContainer;
            final description = caster
                ? 'Figur'
                : origin
                ? 'Feuerball-Ursprung'
                : wall
                ? 'Vollhindernis'
                : candidate == null
                ? 'Außerhalb der Vorschau'
                : uncertain
                ? 'Deckung ungeklärt'
                : candidate.centerWithinRadius
                ? 'Mittelpunkt im 2D-Radius'
                : 'Mögliches Randfeld';
            return Tooltip(
              message: '$description (${cell.column}, ${cell.row})',
              child: InkWell(
                key: ValueKey('fireball-cell-${cell.column}-${cell.row}'),
                onTap: () => _edit(cell),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    caster
                        ? 'S'
                        : origin
                        ? 'Z'
                        : wall
                        ? 'X'
                        : candidate == null
                        ? ''
                        : uncertain
                        ? '?'
                        : candidate.centerWithinRadius
                        ? '●'
                        : '·',
                    style: TextStyle(
                      color: caster || wall
                          ? scheme.onPrimary
                          : scheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _result?.candidates.length ?? 0;
    final uncertain =
        _result?.candidates
            .where(
              (entry) =>
                  entry.centerRay == SrdSphereCenterRay.requiresCoverReview,
            )
            .length ??
        0;
    return AlertDialog(
      title: const Text('Feuerball: Flächenvorschau'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nur Planung: Reichweite bis zum Ursprung 150 Fuß, '
                'Kugelradius 20 Fuß. Kein automatischer Treffer, '
                'Rettungswurf oder Schaden.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const ValueKey('fireball-map-size'),
                initialValue: _size,
                decoration: const InputDecoration(
                  labelText: 'Karte – je Feld 5 Fuß',
                ),
                items: const [
                  DropdownMenuItem(value: 12, child: Text('12 × 12 Felder')),
                  DropdownMenuItem(value: 20, child: Text('20 × 20 Felder')),
                  DropdownMenuItem(value: 32, child: Text('32 × 32 Felder')),
                ],
                onChanged: (size) {
                  if (size != null) _resize(size);
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final tool in _PreviewTool.values)
                    ChoiceChip(
                      key: ValueKey('fireball-tool-${tool.name}'),
                      selected: _tool == tool,
                      label: Text(switch (tool) {
                        _PreviewTool.caster => 'S: Figur',
                        _PreviewTool.origin => 'Z: Ursprung',
                        _PreviewTool.wall => 'X: Vollhindernis',
                      }),
                      onSelected: (_) => setState(() => _tool = tool),
                    ),
                ],
              ),
              const Text(
                'Werkzeug wählen und Feld antippen. Hindernisse durch '
                'erneutes Tippen entfernen. Änderungen setzen die '
                'Kartenbestätigung zurück.',
              ),
              const SizedBox(height: 10),
              _grid(),
              CheckboxListTile(
                key: const ValueKey('fireball-map-surveyed'),
                contentPadding: EdgeInsets.zero,
                value: _surveyed,
                onChanged: (value) => setState(() {
                  _surveyed = value ?? false;
                  _result = null;
                  _error = null;
                }),
                title: const Text('Alle Vollhindernisse sind erfasst.'),
                subtitle: const Text(
                  'Nur nach echter Prüfung bestätigen. Höhe, Sicht, '
                  'Teil-/Voll-Deckung und Kreaturen bleiben offen.',
                ),
              ),
              if (_result != null) ...[
                Text(
                  '$count mögliche 2D-Bodenfelder, '
                  '$uncertain mit ungeklärtem Mittelpunktstrahl.',
                  key: const ValueKey('fireball-preview-summary'),
                ),
                const Text(
                  '● Mittelpunkt im Radius · mögliches Randfeld '
                  '? Deckung ungeklärt. Keine automatische Zielwirkung.',
                ),
              ],
              if (_error != null)
                Text(
                  _error!,
                  key: const ValueKey('fireball-preview-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('fireball-preview-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
        FilledButton(
          key: const ValueKey('fireball-preview-calculate'),
          onPressed: _calculate,
          child: const Text('Vorschau berechnen'),
        ),
      ],
    );
  }
}
