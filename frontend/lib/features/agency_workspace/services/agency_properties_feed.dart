import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/core/services/session_guard.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';

/// Where an AgencyAgent's Properties tab reads (TAQ-194): the agency's `Properties` docs. The
/// rules allow an agent to list them with an equality on its own `agency_id`
/// (agencyMemberReads()). The agency's own stock, published or not, sits in its AgencyAdmin's
/// private tree, which comes from the `listAgencyStock` callable (TAQ-197). Tests pass a fake.
abstract class AgencyPropertiesBackend {
  Stream<List<ManagedPropertyModel>> watchAgencyProperties(String agencyId);
  Future<List<ManagedPropertyModel>> fetchAgencyStock();
}

class FirebaseAgencyPropertiesBackend implements AgencyPropertiesBackend {
  /// The tab shows at most this many listings.
  static const int limit = 500;

  @override
  Stream<List<ManagedPropertyModel>> watchAgencyProperties(String agencyId) => FirebaseFirestore.instance
      .collection('Properties')
      .where('agency_id', isEqualTo: agencyId)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map((d) => ManagedPropertyModel.fromMap(d.data(), docId: d.id)).toList());

  @override
  Future<List<ManagedPropertyModel>> fetchAgencyStock() async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('listAgencyStock');
    final result = await SessionGuard.instance.run(() => callable.call<dynamic>(const {}));
    final data = result.data;
    final raw = data is Map ? data['properties'] : null;
    if (raw is! List) return const [];
    return [
      for (final item in raw.whereType<Map<dynamic, dynamic>>())
        ManagedPropertyModel.fromMap(Map<String, dynamic>.from(item), docId: item['id']?.toString()),
    ];
  }
}

/// The agency's listings for the read-only Properties tab of an agent, as the listenables
/// PropertiesView takes.
class AgencyPropertiesFeed {
  AgencyPropertiesFeed({AgencyPropertiesBackend? backend}) : backend = backend ?? FirebaseAgencyPropertiesBackend();

  final AgencyPropertiesBackend backend;
  final ValueNotifier<List<ManagedPropertyModel>> properties = ValueNotifier(const []);
  final ValueNotifier<bool> hydrating = ValueNotifier(false);
  StreamSubscription<List<ManagedPropertyModel>>? _sub;
  String _agencyId = '';
  List<ManagedPropertyModel> _stock = const [];
  List<ManagedPropertyModel> _listings = const [];
  bool _disposed = false;

  /// The agency's own stock first, then the published listings it manages that aren't in it.
  void _publish() {
    if (_disposed) return;
    final ids = {for (final p in _stock) p.id};
    properties.value = [..._stock, ..._listings.where((p) => !ids.contains(p.id))];
  }

  /// Starts following [agencyId]; a repeat call with the same id does nothing.
  void start(String agencyId) {
    if (agencyId.isEmpty || agencyId == _agencyId) return;
    _agencyId = agencyId;
    _sub?.cancel();
    hydrating.value = true;
    _sub = backend.watchAgencyProperties(agencyId).listen(
      (items) {
        _listings = items;
        _publish();
        hydrating.value = false;
      },
      onError: (Object e) {
        debugPrint('AgencyPropertiesFeed: $e');
        hydrating.value = false;
      },
    );
    backend.fetchAgencyStock().then((items) {
      _stock = items;
      _publish();
    }, onError: (Object e) => debugPrint('AgencyPropertiesFeed stock: $e'));
  }

  void dispose() {
    _disposed = true;
    _sub?.cancel();
    properties.dispose();
    hydrating.dispose();
  }
}
