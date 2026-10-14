import 'package:flutter/material.dart';

import '../services/game_controller.dart';

String _providerLabel(String? provider) => switch (provider) {
  'mock' => 'Server-Demo',
  'openai' => 'OpenAI',
  _ => 'Backend',
};

/// Settings for the optional narrator. Long-lived provider credentials never
/// belong in this dialog; its short-lived session token stays in memory only.
class BackendSettingsPanel extends StatelessWidget {
  const BackendSettingsPanel({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final narrator = controller.narrator;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            narrator.enabled ? Icons.cloud_outlined : Icons.offline_bolt,
          ),
          title: Text(
            narrator.enabled
                ? 'Aktiver Spielleiter: ${_providerLabel(narrator.provider)}'
                : 'Aktiver Spielleiter: lokale Demo',
          ),
          subtitle: Text(
            narrator.enabled
                ? 'Anfragenversuche: ${narrator.requestsUsed}/${narrator.requestLimit}. '
                      'Bei einem Ausfall erzählt die lokale Demo weiter.'
                : 'Die lokale Demo funktioniert ohne Backend und ohne API-Kosten.',
          ),
        ),
        if (narrator.statusMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(narrator.statusMessage!),
          ),
        if (narrator.enabled && narrator.expiresAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Sitzung gültig bis ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(narrator.expiresAt!.toLocal()), alwaysUse24HourFormat: true)} Uhr. '
              'Nach einem App-Neustart erneut verbinden.',
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: controller.busy || narrator.connecting
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          _BackendConnectDialog(controller: controller),
                    ),
              icon: const Icon(Icons.link),
              label: Text(
                narrator.enabled ? 'Neu verbinden' : 'Backend verbinden',
              ),
            ),
            if (narrator.enabled)
              TextButton.icon(
                onPressed: narrator.connecting
                    ? null
                    : controller.disconnectNarrator,
                icon: const Icon(Icons.link_off),
                label: const Text('Lokale Demo verwenden'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Optionales Backend: Charaktername, Handlung, Szene und ausgewählte '
          'Kampagnenfakten werden an deinen Server und dessen Erzählanbieter '
          'übertragen. Es werden keine Audioaufzeichnungen übertragen. '
          'Kosten hängen vom Anbieter und der Serverkonfiguration ab.',
        ),
      ],
    );
  }
}

/// A compact status in the scrollable adventure header keeps the composer
/// reachable while the Android keyboard is open.
class BackendAdventureStatus extends StatelessWidget {
  const BackendAdventureStatus({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final narrator = controller.narrator;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            narrator.enabled ? Icons.cloud_outlined : Icons.offline_bolt,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              narrator.enabled
                  ? '${_providerLabel(narrator.provider)} · '
                        '${narrator.requestsUsed}/${narrator.requestLimit} Anfragenversuche'
                        '${narrator.statusMessage == null ? '' : '\n${narrator.statusMessage}'}'
                  : narrator.statusMessage ??
                        'Lokaler Demo-Spielleiter · ohne API-Kosten',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendConnectDialog extends StatefulWidget {
  const _BackendConnectDialog({required this.controller});

  final GameController controller;

  @override
  State<_BackendConnectDialog> createState() => _BackendConnectDialogState();
}

class _BackendConnectDialogState extends State<_BackendConnectDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _url;
  final _token = TextEditingController();
  late final TextEditingController _limit;
  bool _allowPaid = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.controller.narrator.backendUrl);
    _limit = TextEditingController(
      text: widget.controller.narrator.requestLimit.toString(),
    );
  }

  @override
  void dispose() {
    _url.dispose();
    _token.clear();
    _token.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_submitting || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.controller.connectNarrator(
        url: _url.text.trim(),
        sessionToken: _token.text.trim(),
        allowPaidProvider: _allowPaid,
        requestLimit: int.parse(_limit.text),
      );
      if (!mounted) return;
      if (widget.controller.error == null &&
          widget.controller.narrator.enabled) {
        _token.clear();
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _error =
            widget.controller.error ??
            widget.controller.narrator.statusMessage ??
            'Verbindung nicht bestätigt. Prüfe Adresse und Sitzungstoken.';
      });
    } catch (_) {
      // Never show a transport exception: it might contain credentials or a
      // server-supplied response body.
      if (mounted) {
        setState(() {
          _error =
              'Verbindung nicht bestätigt. Prüfe Adresse und Sitzungstoken.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      title: const Text('Backend verbinden'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verbinde einen eigenen Erzählserver. Die Prüfung erzeugt '
                  'keine Modellerzählung. Die lokale Demo bleibt als Fallback verfügbar.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('backend-url'),
                  controller: _url,
                  enabled: !_submitting,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'HTTPS-Serveradresse',
                    hintText: 'https://spielleiter.example.org',
                  ),
                  validator: (value) {
                    final uri = Uri.tryParse(value?.trim() ?? '');
                    return uri == null ||
                            (value?.trim().length ?? 0) > 2048 ||
                            uri.scheme != 'https' ||
                            uri.host.isEmpty ||
                            uri.userInfo.isNotEmpty ||
                            uri.hasQuery ||
                            uri.hasFragment
                        ? 'HTTPS-Adresse ohne Zugangsdaten eingeben.'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('backend-token'),
                  controller: _token,
                  enabled: !_submitting,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: const InputDecoration(
                    labelText: 'Kurzlebiges Sitzungstoken',
                    helperText:
                        'Kein Anbieter-API-Schlüssel. Bleibt nur im Arbeitsspeicher.',
                    helperMaxLines: 3,
                  ),
                  validator: (value) {
                    final token = value?.trim() ?? '';
                    return token.isEmpty ||
                            token.length > 4096 ||
                            RegExp(r'\s').hasMatch(token)
                        ? 'Gültiges kurzlebiges Sitzungstoken eingeben.'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('backend-limit'),
                  controller: _limit,
                  enabled: !_submitting,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximale Anfragenversuche',
                    helperText: '1–100 pro Verbindung; kein Euro-Kostendeckel.',
                    helperMaxLines: 2,
                  ),
                  validator: (value) {
                    final count = int.tryParse(value ?? '');
                    return count == null || count < 1 || count > 100
                        ? 'Eine ganze Zahl zwischen 1 und 100 eingeben.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  key: const Key('backend-allow-paid'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _allowPaid,
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _allowPaid = value ?? false),
                  title: const Text('Kostenpflichtigen Anbieter erlauben'),
                  subtitle: const Text(
                    'Kann API-Kosten verursachen. Zusätzlich muss dein Server '
                    'diesen Anbieter freigeben. Die Server-Demo bleibt kostenlos.',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Beim Spielen werden Charaktername, Handlung, Szene und '
                  'ausgewählte Kampagnenfakten an Server und Erzählanbieter gesendet. '
                  'Die Adresse und das Anfragenlimit werden lokal gespeichert; '
                  'das Sitzungstoken und die Kostenfreigabe werden nicht gespeichert.',
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _connect,
          child: Text(_submitting ? 'Prüfe Verbindung …' : 'Verbinden'),
        ),
      ],
    ),
  );
}
