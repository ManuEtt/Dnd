import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backup_files.dart';

Future<String?> showImportBackupDialog(
  BuildContext context, {
  required String title,
  required BackupFiles files,
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _ImportBackupDialog(title: title, files: files),
);

Future<void> showExportBackupDialog(
  BuildContext context, {
  required String title,
  required String json,
  required String name,
  required BackupFiles files,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      _ExportBackupDialog(title: title, json: json, name: name, files: files),
);

class _BackupStatus extends StatelessWidget {
  const _BackupStatus({required this.busy, required this.message});
  final bool busy;
  final String? message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (busy)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: LinearProgressIndicator(),
        ),
      if (message != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(liveRegion: true, child: Text(message!)),
        ),
    ],
  );
}

String _fileError(Object error) => error is BackupFileException
    ? error.message
    : 'Die Datei konnte nicht verarbeitet werden. Versuche es erneut oder nutze den JSON-Text.';

class _ImportBackupDialog extends StatefulWidget {
  const _ImportBackupDialog({required this.title, required this.files});
  final String title;
  final BackupFiles files;

  @override
  State<_ImportBackupDialog> createState() => _ImportBackupDialogState();
}

class _ImportBackupDialogState extends State<_ImportBackupDialog> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = 'Wähle eine JSON-Datei im Dateidialog.';
    });
    try {
      final json = await widget.files.openJson();
      if (!mounted) return;
      if (json != null) _text.text = json;
      setState(() {
        _message = json == null
            ? 'Dateiauswahl abgebrochen. Deine Eingabe bleibt erhalten.'
            : 'Datei geladen. Prüfe den Inhalt und bestätige mit „Importieren“.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = _fileError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wähle eine JSON-Datei oder füge den exportierten Text ein. '
                'Erst „Importieren“ übernimmt geprüfte Daten. Fehlerhafte Daten werden abgewiesen.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _chooseFile,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Datei wählen'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                readOnly: _busy,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'JSON-Spielstand',
                  alignLabelWithHint: true,
                ),
              ),
              _BackupStatus(busy: _busy, message: _message),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _busy ? null : () => Navigator.pop(context, _text.text),
          child: const Text('Importieren'),
        ),
      ],
    ),
  );
}

class _ExportBackupDialog extends StatefulWidget {
  const _ExportBackupDialog({
    required this.title,
    required this.json,
    required this.name,
    required this.files,
  });
  final String title;
  final String json;
  final String name;
  final BackupFiles files;

  @override
  State<_ExportBackupDialog> createState() => _ExportBackupDialogState();
}

class _ExportBackupDialogState extends State<_ExportBackupDialog> {
  bool _busy = false;
  String? _message;

  Future<void> _saveFile() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = 'Wähle den Speicherort im Dateidialog.';
    });
    try {
      final saved = await widget.files.saveJson(
        name: widget.name,
        json: widget.json,
      );
      if (!mounted) return;
      setState(() {
        _message = saved
            ? 'JSON-Datei gespeichert.'
            : 'Speichern abgebrochen. Dein Spielstand bleibt unverändert.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = _fileError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Clipboard.setData(ClipboardData(text: widget.json));
      if (mounted) {
        setState(() => _message = 'JSON in die Zwischenablage kopiert.');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Kopieren nicht möglich. Nutze „Als Datei speichern“.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sichere den vollständigen Charakter oder Spielstand als JSON-Datei. '
                'Wähle einen lokalen Speicherort für eine lokale Sicherung. '
                'Du kannst den Text auch kopieren.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _saveFile,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Als Datei speichern'),
              ),
              _BackupStatus(busy: _busy, message: _message),
              const SizedBox(height: 12),
              SelectableText(
                widget.json,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _copy,
          icon: const Icon(Icons.copy),
          label: const Text('Kopieren'),
        ),
      ],
    ),
  );
}
