// Historical campaign compatibility fixture, deliberately NOT shipped as an
// asset or offered as a built-in save in the Flutter application.
import 'dart:convert';
import 'dart:io';

import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

Campaign legacyArescanCampaign() => Campaign.fromJson(
  jsonDecode(File('test/fixtures/arescan_legacy.json').readAsStringSync())
      as Map<String, dynamic>,
);

Future<void> importLegacyArescan(GameController controller) =>
    controller.importCampaign(jsonEncode(legacyArescanCampaign().toJson()));
