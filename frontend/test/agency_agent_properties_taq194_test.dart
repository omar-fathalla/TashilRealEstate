// TAQ-194: an AgencyAgent's Properties tab lists the agency's listings, read-only.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_dashboard.dart';
import 'package:tashil_real_estate/features/agency_workspace/services/agency_properties_feed.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';

import 'agency_agent_taq169_test.dart' show agent, desktop;
import 'agency_ux_test.dart' show FakeIdentitySource, pumpApp, sara;

class FakeAgencyProperties implements AgencyPropertiesBackend {
  final controller = StreamController<List<ManagedPropertyModel>>.broadcast();
  final asked = <String>[];
  List<ManagedPropertyModel> stock = const [];
  Object? stockError;

  @override
  Future<List<ManagedPropertyModel>> fetchAgencyStock() async {
    if (stockError != null) throw stockError!;
    return stock;
  }

  @override
  Stream<List<ManagedPropertyModel>> watchAgencyProperties(String agencyId) {
    asked.add(agencyId);
    return controller.stream;
  }
}

ManagedPropertyModel listing(String id, String title, {bool published = true}) => ManagedPropertyModel.fromMap({
      'countryCode': CountryController.countryCode,
      'titles': {'ar': title, 'en': title, 'hi': title},
      'agency_id': 'ag1',
      'is_published': published,
    }, docId: id);

Future<void> openProperties(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.apartment_outlined).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("an agent's Properties tab lists the agency's listings, read-only", (tester) async {
    desktop(tester);
    final backend = FakeAgencyProperties();
    await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(agent), agencyProperties: backend));
    expect(backend.asked, ['ag1']);
    // The feed is still loading until the first snapshot; the tab shows a spinner meanwhile.
    backend.controller.add([listing('p1', 'Marina Tower 12'), listing('p2', 'JLT Cluster D')]);
    await tester.pump();
    await openProperties(tester);
    expect(find.text('Marina Tower 12'), findsOneWidget);
    expect(find.text('JLT Cluster D'), findsOneWidget);
    // Read-only: no add button, and tapping a unit opens no editor.
    expect(find.text('Add Property'), findsNothing);
    await tester.tap(find.text('Marina Tower 12'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await backend.controller.close();
  });

  testWidgets('the AgencyAdmin keeps its own tab and never asks for the agent feed', (tester) async {
    desktop(tester);
    final backend = FakeAgencyProperties();
    await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(sara), agencyProperties: backend));
    await openProperties(tester);
    expect(backend.asked, isEmpty);
    await backend.controller.close();
  });

  test('the feed starts once per agency and stops hydrating on error', () async {
    final backend = FakeAgencyProperties();
    final feed = AgencyPropertiesFeed(backend: backend);
    feed.start('');
    expect(backend.asked, isEmpty);
    feed.start('ag1');
    feed.start('ag1');
    expect(backend.asked, ['ag1']);
    expect(feed.hydrating.value, isTrue);
    backend.controller.addError(StateError('denied'));
    await Future<void>.delayed(Duration.zero);
    expect(feed.hydrating.value, isFalse);
    expect(feed.properties.value, isEmpty);
    feed.dispose();
    await backend.controller.close();
  });

  testWidgets("TAQ-197: the agent's tab also lists the agency's unpublished stock, once each", (tester) async {
    desktop(tester);
    final backend = FakeAgencyProperties()
      ..stock = [listing('s1', 'Draft Studio', published: false), listing('p1', 'Marina Tower 12')];
    await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(agent), agencyProperties: backend));
    backend.controller.add([listing('p1', 'Marina Tower 12'), listing('m1', 'Managed Owner Flat')]);
    await tester.pump();
    await openProperties(tester);
    expect(find.text('Draft Studio'), findsOneWidget);
    expect(find.text('Marina Tower 12'), findsOneWidget);
    expect(find.text('Managed Owner Flat'), findsOneWidget);
    expect(find.text('Add Property'), findsNothing);
    await backend.controller.close();
  });

  test('TAQ-197: a refused stock call keeps the published listings', () async {
    final backend = FakeAgencyProperties()..stockError = StateError('denied');
    final feed = AgencyPropertiesFeed(backend: backend);
    feed.start('ag1');
    backend.controller.add([listing('p1', 'Marina Tower 12')]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(feed.properties.value.map((p) => p.id), ['p1']);
    feed.dispose();
    await backend.controller.close();
  });
}
