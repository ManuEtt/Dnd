import 'package:flutter/material.dart';

import '../domain/srd_character_creation_audit.dart';
import 'fantasy_ui.dart';

/// Read-only inspection of one editor snapshot. No confirmation or persistence.
class SrdCreationAuditDialog extends StatelessWidget {
  const SrdCreationAuditDialog({super.key, required this.steps});

  final List<CreationStep> steps;

  static String _label(CreationStepStatus status) => switch (status) {
    CreationStepStatus.confirmed => 'Bestätigt',
    CreationStepStatus.missing => 'Fehlt',
    CreationStepStatus.invalid => 'Ungültig',
    CreationStepStatus.dependent => 'Weitere Auswahl nötig',
    CreationStepStatus.notAutomated => 'Nicht automatisiert',
    CreationStepStatus.houseRule => 'Hausregel',
    CreationStepStatus.notInSrd => 'Nicht im SRD',
  };

  static IconData _icon(CreationStepStatus status) => switch (status) {
    CreationStepStatus.confirmed => Icons.check_circle_outline,
    CreationStepStatus.missing => Icons.pending_outlined,
    CreationStepStatus.invalid => Icons.error_outline,
    CreationStepStatus.dependent => Icons.account_tree_outlined,
    CreationStepStatus.notAutomated => Icons.info_outline,
    CreationStepStatus.houseRule => Icons.edit_note_outlined,
    CreationStepStatus.notInSrd => Icons.help_outline,
  };

  static Color _color(CreationStepStatus status) => switch (status) {
    CreationStepStatus.confirmed => FantasyPalette.success,
    CreationStepStatus.invalid => FantasyPalette.danger,
    CreationStepStatus.missing ||
    CreationStepStatus.dependent ||
    CreationStepStatus.houseRule => FantasyPalette.gold,
    CreationStepStatus.notAutomated ||
    CreationStepStatus.notInSrd => FantasyPalette.muted,
  };

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('srd-creation-audit-dialog'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    title: const Text('SRD-Charaktererstellung prüfen'),
    content: SizedBox(
      width: 430,
      child: ListView(
        key: const ValueKey('srd-creation-audit-list'),
        shrinkWrap: true,
        children: [
          const Text(
            'Prüfung des aktuellen Entwurfs. Gespeicherte Daten bleiben '
            'unverändert. Diese Teilprüfung bescheinigt keine vollständige '
            'SRD-Regeltreue.',
          ),
          const SizedBox(height: 16),
          for (final step in steps)
            Semantics(
              key: ValueKey('creation-audit-${step.id}'),
              container: true,
              label: '${step.title}. ${_label(step.status)}. ${step.detail}',
              child: ExcludeSemantics(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _color(step.status).withValues(alpha: .6),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _icon(step.status),
                            color: _color(step.status),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _label(step.status),
                              style: TextStyle(color: _color(step.status)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(step.detail),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('close-srd-creation-audit'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Schließen'),
      ),
    ],
  );
}
