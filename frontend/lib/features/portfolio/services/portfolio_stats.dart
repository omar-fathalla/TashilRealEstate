import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';

import '../models/portfolio_models.dart';
import 'portfolio_controller.dart';

enum ActivityKind { leaseDraft, leaseOffered, leaseActive, leaseRejected, leaseEnded, maintenance, payment, viewing, application }

/// One line of the overview feed. [titleKey] is a dictionary key that takes [params].
class ActivityEvent {
  final ActivityKind kind;
  final String titleKey;
  final Map<String, String> params;
  final DateTime time;

  /// The dashboard tab that holds the record.
  final int targetTab;

  const ActivityEvent(this.kind, this.titleKey, this.params, this.time, this.targetTab);
}

/// Dashboard tab indexes of the agency workspace.
class AgencyTab {
  static const overview = 0;
  static const properties = 1;
  static const leases = 3;
  static const rentCollection = 4;
  static const requests = 7;
  static const maintenance = 8;
}

String currencyOfCountry(String countryCode) => countryCode == 'EG' ? 'EGP' : 'AED';

/// The overview numbers for one country, computed from real records only. With nothing to count
/// every number is zero (never a placeholder) and [isEmpty] is true.
class PortfolioStats {
  final int properties;
  final int rented;
  final int vacant;
  final int activeLeases;
  final int pendingOffers;
  final int draftLeases;
  final int openMaintenance;
  final int escalatedMaintenance;
  final int newViewings;
  final int pendingApplications;
  final double collectedThisMonth;
  final double expectedThisMonth;
  final String currencyCode;
  final List<ActivityEvent> activity;

  const PortfolioStats({
    this.properties = 0,
    this.rented = 0,
    this.vacant = 0,
    this.activeLeases = 0,
    this.pendingOffers = 0,
    this.draftLeases = 0,
    this.openMaintenance = 0,
    this.escalatedMaintenance = 0,
    this.newViewings = 0,
    this.pendingApplications = 0,
    this.collectedThisMonth = 0,
    this.expectedThisMonth = 0,
    this.currencyCode = 'AED',
    this.activity = const [],
  });

  /// Whole percent of units that are rented, or null with no units.
  int? get occupancyPercent => properties == 0 ? null : (rented * 100 / properties).round();

  /// Whole percent of this month's expected rent that is paid, or null with nothing expected.
  int? get collectionPercent => expectedThisMonth <= 0 ? null : (collectedThisMonth * 100 / expectedThisMonth).round().clamp(0, 100);

  bool get isEmpty => properties == 0 && activeLeases == 0 && pendingOffers == 0 && openMaintenance == 0 && activity.isEmpty;

  static String periodOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  factory PortfolioStats.compute(
    PortfolioSnapshot snapshot,
    List<ManagedPropertyModel> managed, {
    required String countryCode,
    required DateTime now,
    int feedSize = 6,
  }) {
    final currency = currencyOfCountry(countryCode);
    final props = managed.where((p) => p.countryCode == countryCode).toList();
    final leases = snapshot.leases.where((l) => l.countryCode == countryCode).toList();
    final leaseById = {for (final l in snapshot.leases) l.id: l};
    final period = periodOf(now);

    final collected = snapshot.transactions
        .where((t) => t.isPaid && t.period == period && t.currencyCode == currency)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);
    final expected = leases.where((l) => l.isActive && _overlaps(l, monthStart, monthEnd)).fold<double>(0, (sum, l) => sum + l.monthlyRent);

    bool inCountry(PortfolioMaintenance m) {
      final lease = leaseById[m.leaseId];
      return lease == null || lease.countryCode == countryCode;
    }

    final tickets = snapshot.maintenance.where(inCountry).toList();
    final open = tickets.where((m) => m.isOpen).toList();

    final events = <ActivityEvent>[];
    for (final l in leases) {
      final time = l.lastChange;
      if (time == null) continue;
      final params = {'property': l.propertyTitle.isEmpty ? l.id : l.propertyTitle};
      switch (l.status) {
        case 'draft':
          events.add(ActivityEvent(ActivityKind.leaseDraft, 'actLeaseDraft', params, time, AgencyTab.leases));
        case 'pending_tenant_approval':
          events.add(ActivityEvent(ActivityKind.leaseOffered, 'actLeaseOffered', params, time, AgencyTab.leases));
        case 'active':
          events.add(ActivityEvent(ActivityKind.leaseActive, 'actLeaseActive', params, time, AgencyTab.leases));
        case 'rejected':
          events.add(ActivityEvent(ActivityKind.leaseRejected, 'actLeaseRejected', params, time, AgencyTab.leases));
        case 'expired':
        case 'terminated':
          events.add(ActivityEvent(ActivityKind.leaseEnded, 'actLeaseEnded', params, time, AgencyTab.leases));
      }
    }
    for (final m in tickets) {
      final time = m.lastChange;
      if (time == null) continue;
      final key = m.status == 'resolved' ? 'actMaintenanceResolved' : (m.status == 'pending' ? 'actMaintenanceNew' : 'actMaintenanceProgress');
      events.add(ActivityEvent(
        ActivityKind.maintenance,
        key,
        {'title': m.title.isEmpty ? m.propertyTitle : m.title},
        time,
        AgencyTab.maintenance,
      ));
    }
    for (final t in snapshot.transactions.where((t) => t.isPaid && t.currencyCode == currency)) {
      final time = t.paidAt;
      if (time == null) continue;
      events.add(ActivityEvent(
        ActivityKind.payment,
        'actPaymentReceived',
        {'amount': t.amount.toStringAsFixed(t.amount == t.amount.roundToDouble() ? 0 : 2), 'currency': t.currencyCode, 'period': t.period},
        time,
        AgencyTab.rentCollection,
      ));
    }
    for (final v in snapshot.viewings) {
      final time = v.createdAt;
      if (time == null || !v.isPending) continue;
      events.add(ActivityEvent(ActivityKind.viewing, 'actViewingRequest', {'name': v.requesterName}, time, AgencyTab.requests));
    }
    for (final a in snapshot.applications) {
      final time = a.createdAt;
      if (time == null || !a.isPending) continue;
      events.add(ActivityEvent(ActivityKind.application, 'actApplication', {'name': a.applicantName}, time, AgencyTab.requests));
    }
    events.sort((a, b) => b.time.compareTo(a.time));

    return PortfolioStats(
      properties: props.length,
      rented: props.where((p) => p.isOccupied).length,
      vacant: props.where((p) => !p.isOccupied).length,
      activeLeases: leases.where((l) => l.isActive).length,
      pendingOffers: leases.where((l) => l.isOffer).length,
      draftLeases: leases.where((l) => l.isDraft).length,
      openMaintenance: open.length,
      escalatedMaintenance: open.where((m) => m.isEscalated).length,
      newViewings: snapshot.viewings.where((v) => v.isPending).length,
      pendingApplications: snapshot.applications.where((a) => a.isPending).length,
      collectedThisMonth: collected,
      expectedThisMonth: expected,
      currencyCode: currency,
      activity: events.take(feedSize).toList(),
    );
  }

  static bool _overlaps(PortfolioLease l, DateTime from, DateTime to) {
    final start = DateTime.tryParse(l.startDate);
    final end = DateTime.tryParse(l.endDate);
    if (start != null && !start.isBefore(to)) return false;
    if (end != null && end.isBefore(from)) return false;
    return true;
  }
}
