import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/services/crash_reporting_service.dart';

void main() {
  late CrashReportingService service;
  late List<Map<String, dynamic>> writes;

  setUp(() {
    service = CrashReportingService();
    service.resetSession();
    writes = [];
    service.uidOverride = () => null;
    service.writeOverride = (id, data) async => writes.add({'id': id, ...data});
  });

  tearDown(() {
    service.writeOverride = null;
    service.uidOverride = null;
    service.resetSession();
  });

  test('TAQ-67: the report holds only the keys firestore.rules allow', () async {
    await service.recordError('boom', StackTrace.current, reason: 'widget build', fatal: true);
    expect(writes, hasLength(1));
    final data = writes.single;
    const allowed = {'id', 'message', 'stack', 'context', 'isFatal', 'platform', 'uid', 'createdAt'};
    expect(data.keys.toSet().difference(allowed), isEmpty);
    expect(data['message'], 'boom');
    expect(data['isFatal'], isTrue);
    expect(data['uid'], isNull);
    expect(data.containsKey('userId'), isFalse);
    expect(data.containsKey('timestamp'), isFalse);
    expect(data['createdAt'], isNotNull);
  });

  test('TAQ-67: only the signed-in uid is attached', () async {
    service.uidOverride = () => 'user-1';
    await service.recordError('boom', null);
    expect(writes.single['uid'], 'user-1');
  });

  test('TAQ-67: long message, stack and context are capped to the rules limits', () async {
    await service.recordError(
      'm' * 5000,
      StackTrace.fromString('s' * 20000),
      reason: 'c' * 2000,
    );
    final data = writes.single;
    expect((data['message'] as String).length, CrashReportingService.maxMessageLength);
    expect((data['stack'] as String).length, CrashReportingService.maxStackLength);
    expect((data['context'] as String).length, CrashReportingService.maxContextLength);
  });

  test('TAQ-67: an empty message is replaced so the rules accept it', () async {
    await service.recordError('', null);
    expect((writes.single['message'] as String).isNotEmpty, isTrue);
  });

  test('TAQ-67: the same message is sent only once per session', () async {
    for (var i = 0; i < 20; i++) {
      await service.recordError('same crash', null);
    }
    expect(writes, hasLength(1));
    expect(service.recentErrors.value.length, greaterThan(1), reason: 'the live list still shows every error');
  });

  test('TAQ-67: at most 5 reports are sent per session', () async {
    for (var i = 0; i < 30; i++) {
      await service.recordError('crash $i', null);
    }
    expect(writes, hasLength(CrashReportingService.maxReportsPerSession));
    expect(CrashReportingService.maxReportsPerSession, 5);
  });

  test('TAQ-67: document ids are unique and fit the 64-character rule', () async {
    for (var i = 0; i < 5; i++) {
      await service.recordError('crash $i', null);
    }
    final ids = writes.map((w) => w['id'] as String).toList();
    expect(ids.toSet(), hasLength(5));
    expect(ids.every((id) => id.length <= 64), isTrue);
  });

  test('TAQ-67: a denied or failing write is swallowed', () async {
    service.writeOverride = (id, data) async => throw Exception('permission-denied');
    await service.recordError('boom', null);
    service.resetSession();
    service.writeOverride = (id, data) => Future<void>.error(StateError('offline'));
    await service.recordError('boom again', null);
  });

  test('TAQ-67: a write that never completes does not hang the reporter', () async {
    service.writeOverride = (id, data) => Completer<void>().future;
    final done = service.recordError('stuck', null);
    await done.timeout(CrashReportingService.writeTimeout + const Duration(seconds: 2));
  });

  test('TAQ-67: an error whose toString throws is swallowed', () async {
    await service.recordError(_Unprintable(), null);
  });
}

class _Unprintable {
  @override
  String toString() => throw StateError('no string form');
}
