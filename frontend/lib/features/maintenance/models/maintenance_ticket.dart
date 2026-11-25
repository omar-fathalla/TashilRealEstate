import 'package:cloud_firestore/cloud_firestore.dart';

const maintenanceCategories = ['plumbing', 'electrical', 'ac', 'appliance', 'structural', 'cleaning', 'other'];
const maintenanceStatuses = ['pending', 'in_progress', 'resolved', 'escalated'];

String _text(dynamic v) => v is String ? v : '';

/// A maintenance request (`Maintenance/{id}`). Photos are inline data URIs.
class MaintenanceTicket {
  final String id;
  final String leaseId;
  final String tenantId;
  final String ownerId;
  final String agencyId;
  final String propertyTitle;
  final String tenantName;
  final String title;
  final String description;
  final String category;
  final List<String> photos;
  final String status;
  final String resolutionNote;
  final DateTime? createdAt;

  const MaintenanceTicket({
    required this.id,
    this.leaseId = '',
    this.tenantId = '',
    this.ownerId = '',
    this.agencyId = '',
    this.propertyTitle = '',
    this.tenantName = '',
    required this.title,
    this.description = '',
    this.category = 'other',
    this.photos = const [],
    this.status = 'pending',
    this.resolutionNote = '',
    this.createdAt,
  });

  bool get isResolved => status == 'resolved';

  factory MaintenanceTicket.fromMap(String id, Map<String, dynamic> data) {
    final created = data['created_at'];
    final status = _text(data['status']);
    return MaintenanceTicket(
      id: id,
      leaseId: _text(data['lease_id']),
      tenantId: _text(data['tenant_id']),
      ownerId: _text(data['owner_id']),
      agencyId: _text(data['agency_id']),
      propertyTitle: _text(data['property_title']),
      tenantName: _text(data['tenant_name']),
      title: _text(data['title']),
      description: _text(data['description']),
      category: maintenanceCategories.contains(data['category']) ? data['category'] as String : 'other',
      photos: [for (final p in (data['photos'] as List? ?? const [])) if (p is String) p],
      status: maintenanceStatuses.contains(status) ? status : 'pending',
      resolutionNote: _text(data['resolution_note']),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

/// The tenant's active lease, as far as a new request needs it.
class ActiveLeaseRef {
  final String id;
  final String ownerId;
  final String agencyId;
  final String propertyId;
  final String propertyTitle;
  final String tenantName;

  const ActiveLeaseRef({
    required this.id,
    required this.ownerId,
    this.agencyId = '',
    this.propertyId = '',
    this.propertyTitle = '',
    this.tenantName = '',
  });

  factory ActiveLeaseRef.fromMap(String id, Map<String, dynamic> data) => ActiveLeaseRef(
        id: id,
        ownerId: _text(data['owner_id']),
        agencyId: _text(data['agency_id']),
        propertyId: _text(data['property_id']),
        propertyTitle: _text(data['property_title']),
        tenantName: _text(data['tenant_name']),
      );
}
