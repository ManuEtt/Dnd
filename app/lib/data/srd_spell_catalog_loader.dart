import 'package:flutter/services.dart';

import '../domain/srd_spell_catalog.dart';

/// Asset boundary: deterministic domain code remains Flutter-independent.
class SrdSpellCatalogLoader {
  const SrdSpellCatalogLoader._();

  static Future<SrdSpellCatalog> load() async {
    final json = await rootBundle.loadString('assets/srd_5_2_1_spells.json');
    return SrdSpellCatalog.fromJsonString(json);
  }
}
