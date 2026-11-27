import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

String _text(dynamic value) => value is String ? value : '';

double _number(dynamic value) => value is num ? value.toDouble() : 0;

/// Which records a manager sees: the ones of an agency (`agency_id`) or of an owner (`owner_id`).
/// The rules allow exactly these two equality queries, so a manager never reads another's data.
/// [PortfolioScope.platform] (TAQ-162) reads the latest records of the whole platform, capped;
/// the rules allow that to a SuperAdmin only, and the client asks for it only for one.
class PortfolioScope {
  final String field;
  final String value;
  const PortfolioScope._(this.field, this.value);

  const PortfolioScope.agency(String agencyId) : this._('agency_id', agencyId);
  const PortfolioScope.owner(String uid) : this._('owner_id', uid);
  const PortfolioScope.platform() : this._('', '');

  bool get isAgency => field == 'agency_id';
  bool get isPlatform => field.isEmpty;

  @override
  bool operator ==(Object other) => other is PortfolioScope && other.field == field && other.value == value;

  @override
  int get hashCode => Object.hash(field, value);
}

/// A lease the signed-in manager is party to (`Leases/{id}`).
class PortfolioLease {
  final String id;
  final String status;
  final String propertyId;
  final String propertyTitle;
  final String tenantId;
  final String tenantName;
  final String ownerId;
  final String agencyId;
  final double monthlyRent;
  final String currencyCode;
  final String countryCode;
  final String startDate;
  final String endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PortfolioLease({
    required this.id,
    this.status = 'draft',
    this.propertyId = '',
    this.propertyTitle = '',
    this.tenantId = '',
    this.tenantName = '',
    this.ownerId = '',
    this.agencyId = '',
    this.monthlyRent = 0,
    this.currencyCode = 'AED',
    this.countryCode = 'AE',
    this.startDate = '',
    this.endDate = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isDraft => status == 'draft';
  bool get isOffer => status == 'pending_tenant_approval';
  bool get isActive => status == 'active';
  bool get isEnded => status == 'expired' || status == 'terminated';

  /// The latest known change, for the activity feed.
  DateTime? get lastChange => updatedAt ?? createdAt;

  factory PortfolioLease.fromMap(String id, Map<String, dynamic> data) {
    final terms = (data['financialTerms'] as Map?) ?? const {};
    var rent = _number(terms['monthlyRent']);
    if (rent <= 0) rent = _number(data['monthly_rent']);
    if (rent <= 0) rent = _number(data['baseAmount']);
    if (rent <= 0) rent = _number(terms['annualRent']) / 12;
    final country = _text(data['country_code']).toUpperCase();
    final currency = _text(data['currencyCode']);
    return PortfolioLease(
      id: id,
      status: _text(data['status']).isEmpty ? 'draft' : _text(data['status']),
      propertyId: _text(data['property_id']),
      propertyTitle: _text(data['property_title']).isNotEmpty ? _text(data['property_title']) : _text(data['propertyTitle']),
      tenantId: _text(data['tenant_id']),
      tenantName: _text(data['tenant_name']).isNotEmpty ? _text(data['tenant_name']) : _text(data['tenantName']),
      ownerId: _text(data['owner_id']),
      agencyId: _text(data['agency_id']),
      monthlyRent: rent,
      currencyCode: currency.isNotEmpty ? currency : (country == 'EG' ? 'EGP' : 'AED'),
      countryCode: country == 'EG' ? 'EG' : 'AE',
      startDate: _text(data['start_date']),
      endDate: _text(data['end_date']),
      createdAt: _date(data['created_at']),
      updatedAt: _date(data['updated_at']),
    );
  }
}

/// A payment attempt or payment (`Transactions/{leaseId}_{YYYY-MM}`, written only by the server).
class PortfolioTransaction {
  final String id;
  final String leaseId;
  final String period;
  final double amount;
  final String currencyCode;
  final String status;
  final String method;
  final String gateway;
  final String reference;
  final String invoiceNumber;
  final DateTime? paidAt;

  const PortfolioTransaction({
    required this.id,
    this.leaseId = '',
    this.period = '',
    this.amount = 0,
    this.currencyCode = 'AED',
    this.status = 'pending',
    this.method = '',
    this.gateway = '',
    this.reference = '',
    this.invoiceNumber = '',
    this.paidAt,
  });

  bool get isPaid => status == 'paid';

  factory PortfolioTransaction.fromMap(String id, Map<String, dynamic> data) {
    return PortfolioTransaction(
      id: id,
      leaseId: _text(data['leaseId']),
      period: _text(data['period']),
      amount: _number(data['amount']),
      currencyCode: _text(data['currencyCode']).isEmpty ? 'AED' : _text(data['currencyCode']),
      status: _text(data['status']).isEmpty ? 'pending' : _text(data['status']),
      method: _text(data['method']),
      gateway: _text(data['gateway']),
      reference: _text(data['reference']),
      invoiceNumber: _text(data['invoiceNumber']),
      paidAt: _date(data['paidAt']),
    );
  }
}

/// A receipt (`Invoices/{invoiceNumber}`), issued by the server when a payment is paid or recorded.
class PortfolioInvoice {
  final String invoiceNumber;
  final String leaseId;
  final String transactionId;
  final String period;
  final double amount;
  final double totalPaid;
  final double platformFee;
  final double agencyFee;
  final double ownerPayout;
  final String currencyCode;
  final String status;
  final String paymentMethod;
  final DateTime? createdAt;

  const PortfolioInvoice({
    required this.invoiceNumber,
    this.leaseId = '',
    this.transactionId = '',
    this.period = '',
    this.amount = 0,
    this.totalPaid = 0,
    this.platformFee = 0,
    this.agencyFee = 0,
    this.ownerPayout = 0,
    this.currencyCode = 'AED',
    this.status = '',
    this.paymentMethod = '',
    this.createdAt,
  });

  factory PortfolioInvoice.fromMap(String id, Map<String, dynamic> data) {
    return PortfolioInvoice(
      invoiceNumber: _text(data['invoiceNumber']).isEmpty ? id : _text(data['invoiceNumber']),
      leaseId: _text(data['leaseId']),
      transactionId: _text(data['transactionId']),
      period: _text(data['period']),
      amount: _number(data['amount']),
      totalPaid: _number(data['totalPaid']),
      platformFee: _number(data['platformFee']),
      agencyFee: _number(data['agencyFee']),
      ownerPayout: _number(data['ownerPayout']),
      currencyCode: _text(data['currencyCode']).isEmpty ? 'AED' : _text(data['currencyCode']),
      status: _text(data['status']),
      paymentMethod: _text(data['paymentMethod']),
      createdAt: _date(data['createdAt']),
    );
  }
}

/// A tenant's maintenance request (`Maintenance/{id}`). Photos are not read: the overview only counts.
class PortfolioMaintenance {
  final String id;
  final String leaseId;
  final String status;
  final String title;
  final String propertyTitle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PortfolioMaintenance({
    required this.id,
    this.leaseId = '',
    this.status = 'pending',
    this.title = '',
    this.propertyTitle = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Still needs work: not resolved yet (pending, in progress or escalated).
  bool get isOpen => status != 'resolved';
  bool get isEscalated => status == 'escalated';

  DateTime? get lastChange => updatedAt ?? createdAt;

  factory PortfolioMaintenance.fromMap(String id, Map<String, dynamic> data) {
    return PortfolioMaintenance(
      id: id,
      leaseId: _text(data['lease_id']),
      status: _text(data['status']).isEmpty ? 'pending' : _text(data['status']),
      title: _text(data['title']),
      propertyTitle: _text(data['property_title']),
      createdAt: _date(data['created_at']),
      updatedAt: _date(data['updated_at']),
    );
  }
}
