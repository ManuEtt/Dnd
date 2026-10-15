"""Offline guardrails for the SRD tables; Dart tests remain authoritative."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / 'app/lib/domain/srd_equipment_catalog.dart'
MODELS = ROOT / 'app/lib/domain/models.dart'
EDITOR = ROOT / 'app/lib/ui/character_editor.dart'


class SrdEquipmentSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = CATALOG.read_text(encoding='utf-8')

    def test_all_weapons_and_armor_present_once(self):
        ids = re.findall(r'EquipmentEntry\(id: "([\w-]+)"', self.source)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(sum(i.startswith('weapon-') for i in ids), 38)
        self.assertEqual(sum(i.startswith('armor-') for i in ids), 13)
        self.assertGreaterEqual(len(ids), 240)

    def test_critical_srd_baselines(self):
        for part in (
            'weapon-longsword', 'twoHandDamage: "1d10"',
            'weapon-dagger', 'mastery: "nick"',
            'weapon-longbow', 'rangeLong: 600',
            'armor-plate-armor', 'armorBaseAc: 18',
            'armor-shield', 'armorBaseAc: 2',
            'strengthMin: 13',
        ):
            self.assertIn(part, self.source)

    def test_no_automatic_unconfirmed_magic_effects(self):
        self.assertIn('Magischer Gegenstand:', self.source)
        self.assertIn('Keine automatische Regeländerung.', self.source)
        self.assertIn('armorClassWithDex(int? dexModifier)', self.source)
        self.assertIn('catalogId', MODELS.read_text(encoding='utf-8'))
        self.assertIn('character-catalog-open', EDITOR.read_text(encoding='utf-8'))


if __name__ == '__main__':
    unittest.main()
