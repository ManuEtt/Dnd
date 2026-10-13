"""Zero-dependency checks that work before Flutter is installed."""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
source = json.loads((root / 'assets/arescan_save.json').read_text(encoding='utf-8'))
assert source['format'] == 'aetheria-save-v1'
assert source['character']['id'] == source['campaign']['heroId']
assert len(source['history']) == 9
assert all(value is None for value in source['character']['abilities'].values())
assert re.search(r'19', ' '.join(source['history']))
assert re.search(r'14 TP', ' '.join(source['history']))
expected = [
    'lib/main.dart', 'lib/domain/models.dart', 'lib/domain/rules_engine.dart',
    'lib/data/game_repository.dart', 'lib/services/mock_game_master.dart',
    'lib/services/voice_service.dart', '.github/workflows/android-build.yml',
]
assert all((root / item).is_file() for item in expected)
print('Aetheria smoke checks: PASS (seed integrity and required files)')
