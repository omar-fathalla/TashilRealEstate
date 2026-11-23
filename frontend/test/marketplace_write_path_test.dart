import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TAQ-51: public listings (/Properties) are written only by the
/// syncOwnerPropertyToMarketplace trigger. Client code may query the catalog
/// but must never hold a reference it could write through.
void main() {
  test('client code only queries the public Properties collection', () {
    final propertiesRef = RegExp(r'''collection\(\s*['"]Properties['"]\s*\)''');
    final propertiesPath = RegExp(r'''['"]Properties/''');
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();

      for (final match in propertiesRef.allMatches(source)) {
        final end = source.indexOf(';', match.end);
        final statement = source.substring(match.start, end == -1 ? source.length : end);
        final isQuery = RegExp(r'^collection\([^)]*\)\s*\.where\(').hasMatch(statement);
        if (!isQuery) offenders.add('${entity.path}: $statement');
      }
      for (final match in propertiesPath.allMatches(source)) {
        final line = source.substring(source.lastIndexOf('\n', match.start) + 1, source.indexOf('\n', match.start));
        if (!line.trimLeft().startsWith('//')) offenders.add('${entity.path}: $line');
      }
    }

    expect(offenders, isEmpty, reason: 'Write listings to Users/{ownerId}/properties instead.');
  });
}
