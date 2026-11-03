import 'package:tashil_real_estate/core/config/demo_data.dart';
import 'package:tashil_real_estate/features/brokers/models/broker_profile.dart';

class BrokerRepository {
  static final BrokerRepository _instance = BrokerRepository._();
  factory BrokerRepository() => _instance;

  final Map<String, BrokerProfile> _brokers = {};

  BrokerRepository._() {
    if (DemoData.enabled) {
      _brokers[BrokerProfile.marinaDemo.id] = BrokerProfile.marinaDemo;
    }
  }

  List<BrokerProfile> get all => _brokers.values.toList(growable: false);

  BrokerProfile? byId(String id) => _brokers[id];

  List<BrokerProfile> forAgency(String agencyId) =>
      _brokers.values.where((broker) => broker.agencyId == agencyId).toList(growable: false);

  void upsert(BrokerProfile broker) {
    _brokers[broker.id] = broker;
  }

  void clear() => _brokers.clear();
}
