import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';

/// Where an AgencyAgent's Properties tab reads (TAQ-194): the agency's `Properties` docs. The
/// rules allow an agent to list them with an equality on its own `agency_id`
/// (agencyMemberReads()). Tests pass a fake.
abstract class AgencyPropertiesBackend {
  Stream<List<ManagedPropertyModel>> watchAgencyProperties(String agencyId);
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

  /// Starts following [agencyId]; a repeat call with the same id does nothing.
  void start(String agencyId) {
    if (agencyId.isEmpty || agencyId == _agencyId) return;
    _agencyId = agencyId;
    _sub?.cancel();
    hydrating.value = true;
    _sub = backend.watchAgencyProperties(agencyId).listen(
      (items) {
        properties.value = items;
        hydrating.value = false;
      },
      onError: (Object e) {
        debugPrint('AgencyPropertiesFeed: $e');
        hydrating.value = false;
      },
    );
  }

  void dispose() {
    _sub?.cancel();
    properties.dispose();
    hydrating.dispose();
  }
}
