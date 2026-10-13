from pathlib import Path
import re

manifest = Path('android/app/src/main/AndroidManifest.xml')
content = manifest.read_text(encoding='utf-8')
permission = '<uses-permission android:name="android.permission.RECORD_AUDIO" />'
if permission not in content:
    content = re.sub(r'(<manifest\b[^>]*>)', r'\1\n    ' + permission, content, count=1)
query = '<queries><intent><action android:name="android.speech.RecognitionService" /></intent><intent><action android:name="android.intent.action.TTS_SERVICE" /></intent></queries>'
if 'android.speech.RecognitionService' not in content:
    content = content.replace('</manifest>', '    ' + query + '\n</manifest>')
manifest.write_text(content, encoding='utf-8')
