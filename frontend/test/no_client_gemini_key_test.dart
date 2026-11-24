import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Gemini runs only through the `geminiGenerate` Cloud Function. The app must not ship a
/// Gemini key (plain or base64), read one from a define, or call the Gemini API directly.
/// backend/scripts/check_client_ai_keys.js applies the same rules in `npm test`.
const _firebaseOptions = 'lib/firebase_options.dart';

final _rules = <String, RegExp>{
  'Google API key (AIza…)': RegExp(r'AIza[0-9A-Za-z_-]{30,}'),
  'Google API key (AQ.…)': RegExp(r'AQ\.[0-9A-Za-z_-]{20,}'),
  'base64 of an AIza key': RegExp(r'QUl6Y[0-9A-Za-z+/=]{20,}'),
  'base64 of an AQ. key': RegExp(r'QVEu[0-9A-Za-z+/=]{16,}'),
  'direct Gemini API URL': RegExp(r'generativelanguage\.googleapis\.com'),
  'direct Vertex AI URL': RegExp(r'aiplatform\.googleapis\.com'),
  'GEMINI_API_KEY define': RegExp('GEMINI_API_KEY'),
  'Gemini REST method': RegExp(r':(stream)?[gG]enerateContent\b'),
};

final _firebaseApiKeyLine = RegExp(r"^\s*apiKey:\s*'[^']+',\s*$");

List<String> scanLine(String file, int lineNo, String line) {
  final findings = <String>[];
  _rules.forEach((name, pattern) {
    if (!pattern.hasMatch(line)) return;
    if (name.startsWith('Google API key (AIza') && file == _firebaseOptions && _firebaseApiKeyLine.hasMatch(line)) {
      return;
    }
    findings.add('$file:$lineNo: $name');
  });
  return findings;
}

List<String> scanDir(String dir) {
  final findings = <String>[];
  final root = Directory(dir);
  if (!root.existsSync()) return findings;
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (!RegExp(r'\.(dart|js|html|json|yaml|txt)$').hasMatch(path)) continue;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      findings.addAll(scanLine(path, i + 1, lines[i]));
    }
  }
  return findings;
}

void main() {
  test('lib/ and web/ hold no Gemini key, key define or direct Gemini URL', () {
    expect([...scanDir('lib'), ...scanDir('web')], isEmpty);
  });

  test('the check catches keys, their base64 forms and direct Gemini calls', () {
    String fake(String prefix) => prefix + 'x' * 36;
    final samples = [
      "const k = '${fake('AI' 'za')}';",
      "const k = '${fake('AQ' '.')}';",
      "base64.decode('${base64.encode(utf8.encode(fake('AI' 'za')))}')",
      "base64.decode('${base64.encode(utf8.encode(fake('AQ' '.')))}')",
      "Uri.parse('https://generative' 'language.googleapis.com/v1beta')".replaceAll("' '", ''),
      "String.fromEnvironment('GEMINI_' 'API_KEY')".replaceAll("' '", ''),
      r"'models/$m:generate" "Content'",
    ];
    for (final line in samples) {
      expect(scanLine('lib/x.dart', 1, line), isNotEmpty, reason: line);
    }
  });

  test('Firebase config keys are allowed only as apiKey entries in firebase_options.dart', () {
    final key = 'AI' 'za${'y' * 35}';
    expect(scanLine(_firebaseOptions, 1, "    apiKey: '$key',"), isEmpty);
    expect(scanLine('lib/other.dart', 1, "    apiKey: '$key',"), hasLength(1));
    expect(scanLine(_firebaseOptions, 1, "final k = '$key';"), hasLength(1));
  });
}
