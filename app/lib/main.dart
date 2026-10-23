import 'dart:async';

import 'package:flutter/material.dart';

import 'data/campaign_repository.dart';
import 'data/sqlite_campaign_repository.dart';
import 'services/game_controller.dart';
import 'services/voice_controller.dart';
import 'ui/app.dart';
import 'ui/fantasy_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});
  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp>
    with WidgetsBindingObserver {
  GameController? _controller;
  VoiceController? _voice;
  SqliteCampaignRepository? _repository;
  String? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  Future<void> _start() async {
    setState(() => _failure = null);
    try {
      final repository = await SqliteCampaignRepository.open();
      _repository = repository;
      final controller = GameController(repository: repository);
      await controller.initialize();
      if (controller.error != null) {
        throw StateError(controller.error!);
      }
      final voice = VoiceController(
        onPreferencesChanged: (changes) async {
          await repository.patchSettings(changes);
        },
      );
      voice.configure(await repository.loadSettings());
      if (!mounted) {
        controller.dispose();
        voice.dispose();
        await repository.close();
        return;
      }
      setState(() {
        _controller = controller;
        _voice = voice;
      });
      // Local play is ready even if the device speech provider is unresponsive.
      // VoiceController reports bounded initialization failures in settings.
      unawaited(voice.initialize());
    } catch (_) {
      await _repository?.close();
      _repository = null;
      if (mounted) {
        setState(() {
          _failure =
              'Die lokalen Spielstände konnten nicht geladen werden. '
              'Es wurden keine Daten gelöscht. Versuche den Start erneut.';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_voice?.stopListening() ?? Future<void>.value());
      unawaited(_voice?.stopSpeaking() ?? Future<void>.value());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _voice != null) {
      return LivingGameApp(controller: _controller!, voice: _voice!);
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildFantasyTheme(),
      home: Scaffold(
        body: FantasyBackdrop(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _failure == null
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 24),
                        Text('Das Abenteuer erwacht …'),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_failure!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _start,
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _voice?.dispose();
    unawaited(_repository?.close() ?? Future<void>.value());
    super.dispose();
  }
}
