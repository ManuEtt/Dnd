import 'package:flutter/material.dart';

import 'data/game_repository.dart';
import 'ui/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final repository = await GameRepository.open();
    runApp(AetheriaApp(repository: repository));
  } catch (error) {
    runApp(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Aetheria konnte seine Datenbank nicht öffnen: $error'),
          )),
        ),
      ),
    ));
  }
}
