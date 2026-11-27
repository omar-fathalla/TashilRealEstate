import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import '../models/portfolio_models.dart';
import 'portfolio_data_service.dart';

enum PortfolioLoad { loading, ready, error, noAgency, signedOut }

/// Everything the agency overview, properties tab and sidebar need, from one set of listeners.
class PortfolioSnapshot {
  final PortfolioLoad load;
  final List<PortfolioLease> leases;
  final List<PortfolioTransaction> transactions;
  final List<PortfolioInvoice> invoices;
  final List<PortfolioMaintenance> maintenance;
  final List<ViewingRequestItem> viewings;
  final List<RentalApplicationItem> applications;
  final List<PortfolioRentRowState> rentRowStates;

  const PortfolioSnapshot({
    this.load = PortfolioLoad.loading,
    this.leases = const [],
    this.transactions = const [],
    this.invoices = const [],
    this.maintenance = const [],
    this.viewings = const [],
    this.applications = const [],
    this.rentRowStates = const [],
  });

  bool get isLoading => load == PortfolioLoad.loading;
  bool get isReady => load == PortfolioLoad.ready;
}

/// Watches the signed-in manager's own records (the agency's by `agency_id`, an owner's by
/// `owner_id`) and exposes them as one snapshot. It never reads another tenant's data: the scope
/// comes from the sign-in claims and every query is an equality on it.
class PortfolioController extends ChangeNotifier {
  PortfolioController({
    PortfolioDataService? data,
    RequestsService? requests,
    this.agencyOnly = true,
    this.includeRequests = true,
    this.platform = false,
  })  : data = data ?? PortfolioDataService.instance,
        requests = requests ?? RequestsService.instance;

  final PortfolioDataService data;
  final RequestsService requests;
  final bool agencyOnly;
  final bool includeRequests;

  /// Reads the whole platform (SuperAdmin only, TAQ-162). Requests are never included then.
  final bool platform;

  PortfolioSnapshot _snapshot = const PortfolioSnapshot();
  PortfolioSnapshot get snapshot => _snapshot;

  final List<StreamSubscription<dynamic>> _subs = [];
  bool _disposed = false;
  bool _gotLeases = false;

  Future<void> start() async {
    _update(const PortfolioSnapshot());
    try {
      final scope = await data.scopeFor(agencyOnly: agencyOnly, platform: platform);
      if (_disposed) return;
      if (scope == null) {
        _update(PortfolioSnapshot(load: data.isSignedIn ? PortfolioLoad.noAgency : PortfolioLoad.signedOut));
        return;
      }
      _listen<List<PortfolioLease>>(data.watchLeases(scope), (v) {
        _gotLeases = true;
        _update(_copy(leases: v, load: PortfolioLoad.ready));
      });
      // TAQ-169: an agency agent cannot read invoices or transactions.
      final agent = scope.isAgency && await data.backend.currentIsAgencyAgent();
      if (_disposed) return;
      if (!agent) {
        _listen<List<PortfolioTransaction>>(data.watchTransactions(scope), (v) => _update(_copy(transactions: v)));
        _listen<List<PortfolioInvoice>>(data.watchInvoices(scope), (v) => _update(_copy(invoices: v)));
      }
      _listen<List<PortfolioMaintenance>>(data.watchMaintenance(scope), (v) => _update(_copy(maintenance: v)));
      // Row states are an overlay (TAQ-163): if they cannot be read, the rows still show.
      _subs.add(data.watchRentRowStates(scope).listen(
        (v) => _update(_copy(rentRowStates: v)),
        onError: (Object e) => debugPrint('PortfolioController rent row states: $e'),
      ));
      if (includeRequests && !scope.isPlatform) {
        final requestScope = scope.isAgency ? RequestScope.agency(scope.value) : RequestScope.owner(scope.value);
        _listen<List<ViewingRequestItem>>(requests.watchViewings(requestScope), (v) => _update(_copy(viewings: v)));
        _listen<List<RentalApplicationItem>>(requests.watchApplications(requestScope), (v) => _update(_copy(applications: v)));
      }
    } catch (e) {
      debugPrint('PortfolioController start: $e');
      if (!_disposed) _update(const PortfolioSnapshot(load: PortfolioLoad.error));
    }
  }

  void _listen<T>(Stream<T> stream, void Function(T) onData) {
    _subs.add(stream.listen(onData, onError: (Object e) {
      debugPrint('PortfolioController stream: $e');
      _update(_copy(load: PortfolioLoad.error));
    }));
  }

  PortfolioSnapshot _copy({
    PortfolioLoad? load,
    List<PortfolioLease>? leases,
    List<PortfolioTransaction>? transactions,
    List<PortfolioInvoice>? invoices,
    List<PortfolioMaintenance>? maintenance,
    List<ViewingRequestItem>? viewings,
    List<RentalApplicationItem>? applications,
    List<PortfolioRentRowState>? rentRowStates,
  }) {
    final s = _snapshot;
    var nextLoad = load ?? s.load;
    // A late event from another stream must not hide a failure or pull "ready" back to loading.
    if (load == null && s.load == PortfolioLoad.error) nextLoad = PortfolioLoad.error;
    if (load == PortfolioLoad.ready && s.load == PortfolioLoad.error) nextLoad = PortfolioLoad.error;
    return PortfolioSnapshot(
      load: nextLoad,
      leases: leases ?? s.leases,
      transactions: transactions ?? s.transactions,
      invoices: invoices ?? s.invoices,
      maintenance: maintenance ?? s.maintenance,
      viewings: viewings ?? s.viewings,
      applications: applications ?? s.applications,
      rentRowStates: rentRowStates ?? s.rentRowStates,
    );
  }

  void _update(PortfolioSnapshot next) {
    if (_disposed) return;
    _snapshot = next;
    notifyListeners();
  }

  bool get hasLeases => _gotLeases;

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}
