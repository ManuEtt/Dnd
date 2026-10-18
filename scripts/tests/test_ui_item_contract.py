"""Regressions checks independent of a Flutter installation."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class UiItemContractTests(unittest.TestCase):
    def test_action_bar_only_inside_adventure(self):
        code = (ROOT / 'app/lib/ui/app.dart').read_text(encoding='utf-8')
        self.assertEqual(code.count('bottomNavigationBar: FantasyPinnedActionBar('), 1)
        self.assertIn('class _AdventurePage', code)
        self.assertGreater(code.index('bottomNavigationBar: FantasyPinnedActionBar('),
                           code.index('class _AdventurePage'))

    def test_catalog_does_not_render_concatenated_detail(self):
        code = (ROOT / 'app/lib/ui/equipment_catalog_dialog.dart').read_text(encoding='utf-8')
        self.assertNotIn('entry.detail', code)
        self.assertIn('EquipmentFields(entry: entry)', code)

    def test_new_catalog_inventory_does_not_store_mechanical_prose(self):
        code = (ROOT / 'app/lib/ui/character_editor.dart').read_text(encoding='utf-8')
        self.assertNotIn('description: selected.detail', code)
        self.assertIn('catalogId: selected.id', code)


if __name__ == '__main__':
    unittest.main()
