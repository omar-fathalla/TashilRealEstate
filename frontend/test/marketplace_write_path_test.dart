import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TAQ-51: public listings (/Properties) are written only by the
/// syncOwnerPropertyToMarketplace trigger. Client code may query the catalog
/// but must never hold a reference it could write through.
///
/// TAQ-91: the one exception is the platform Admin moderation data source. firestore.rules let an
/// Admin change only is_published, verified, moderation_hidden and updated_at, and this test
/// pins the client to that same set.
const adminModerationSource = 'lib/features/admin/admin_data_source.dart';
const moderationFields = {'is_published', 'verified', 'moderation_hidden', 'updated_at'};
final _agencyWrite = RegExp(r'_agency\([^)]*\)\.update\(\{([^}]*)\}\)', dotAll: true);

void main() {
  test('the Admin moderation source writes only the moderation fields', () {
    // The one agency write (licence verification, TAQ-154) is pinned by its own test below.
    final source = File(adminModerationSource).readAsStringSync().replaceAll(_agencyWrite, '');
    final writes = RegExp(r'\.update\((?:_listing\([^)]*\),\s*)?\{([^}]*)\}\)', dotAll: true).allMatches(source).toList();
    expect(writes, isNotEmpty);
    for (final write in writes) {
      final keys = RegExp(r"'([a-z_]+)'\s*:").allMatches(write.group(1)!).map((m) => m.group(1)!);
      expect(keys, isNotEmpty);
      expect(moderationFields.containsAll(keys), isTrue, reason: write.group(0));
    }
    expect(source.contains('.delete('), isFalse);
    expect(source.contains('.add('), isFalse);
  });

  test('the only agency write is the licence status and badge (TAQ-154)', () {
    final source = File(adminModerationSource).readAsStringSync();
    final writes = _agencyWrite.allMatches(source).toList();
    expect(writes.length, 1);
    final keys = RegExp(r"'([a-z_]+)'\s*:").allMatches(writes.single.group(1)!).map((m) => m.group(1)!).toSet();
    expect(keys, {'licence_status', 'verified_badge', 'updated_at'});
    expect(RegExp(r"collection\('Agencies'\)").allMatches(source).length, 2, reason: 'the list query and _agency()');
  });

  test('the Admin moderation source writes PropertyModeration only with the four moderation-doc fields', () {
    final source = File(adminModerationSource).readAsStringSync();
    final sets = RegExp(r'batch\.set\(_moderation\([^)]*\),\s*\{([^}]*)\}\)', dotAll: true).allMatches(source).toList();
    expect(sets.length, 2, reason: 'one batch.set for hide and one for restore');
    for (final write in sets) {
      final keys = RegExp(r"'([a-z_]+)'\s*:").allMatches(write.group(1)!).map((m) => m.group(1)!).toSet();
      expect(keys, {'hidden', 'pre_hide_published', 'updated_by', 'updated_at'});
    }
    expect(RegExp(r'\.set\(').allMatches(source).length, 2, reason: 'no other .set() in the Admin source');
    expect(source.contains("collection('Properties').doc(id).set"), isFalse);
  });

  test('client code only queries the public Properties collection', () {
    final propertiesRef = RegExp(r'''collection\(\s*['"]Properties['"]\s*\)''');
    final propertiesPath = RegExp(r'''['"]Properties/''');
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path == adminModerationSource) continue;
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
