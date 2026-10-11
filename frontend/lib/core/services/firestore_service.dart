import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService() : _db = FirebaseFirestore.instance {
    try {
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // Ignore if already configured in platform
    }
  }

  // --- 1. User & Role Management ---

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('Users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user role from Firestore: $e');
      return null;
    }
  }

  Future<void> setUserRole({
    required String uid,
    required String email,
    required String role,
    String? fullName,
    String? photoUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'user_id': uid,
        'email': email,
        'role': role,
        'full_name': fullName ?? email.split('@').first,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (photoUrl != null && photoUrl.trim().isNotEmpty) {
        data['photo_url'] = photoUrl.trim();
      }
      await _db.collection('Users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting user role in Firestore: $e');
    }
  }

  Future<void> updateUserPhoto({
    required String uid,
    required String photoUrl,
  }) async {
    try {
      await _db.collection('Users').doc(uid).set({
        'photo_url': photoUrl.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user photo in Firestore: $e');
    }
  }

  // --- 2. Dedicated Owner Property Tree (Users/{ownerId}/properties/{propertyId}) ---

  /// Saves or updates a property in the owner's dedicated Firestore tree
  /// and automatically synchronizes to the Public Marketplace (/Properties)
  Future<bool> saveOwnerProperty({
    required String ownerId,
    required ManagedPropertyModel property,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ Skip Firestore write: user is unauthenticated');
        return false;
      }
      final propData = property.toMap();
      propData['owner_id'] = ownerId;
      propData['updated_at'] = FieldValue.serverTimestamp();

      // Ensure owner user doc exists
      await _db.collection('Users').doc(ownerId).set({
        'user_id': ownerId,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 1. Save to Owner's Dedicated Private Tree
      await _db
          .collection('Users')
          .doc(ownerId)
          .collection('properties')
          .doc(property.id)
          .set(propData, SetOptions(merge: true));

      // 2. Synchronize with Public Marketplace (Properties/{propertyId})
      final marketDocRef = _db.collection('Properties').doc(property.id);
      if (property.isPublished && property.rentalStatus == PropertyRentalStatus.available) {
        final marketItem = property.toPropertyItem();
        final marketData = marketItem.toMap();
        marketData['owner_id'] = ownerId;
        marketData['status'] = 'vacant';
        marketData['is_published'] = true;
        marketData['updated_at'] = FieldValue.serverTimestamp();

        await marketDocRef.set(marketData, SetOptions(merge: true));
      } else {
        // If property is rented or unpublished, hide it from the public marketplace
        await marketDocRef.set({
          'is_published': false,
          'status': property.rentalStatus == PropertyRentalStatus.rented ? 'rented' : 'unavailable',
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      debugPrint('✅ Property [${property.id}] successfully persisted to owner [$ownerId] tree and marketplace.');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving owner property to Firestore: $e');
      rethrow;
    }
  }

  /// Fetches all properties belonging to an owner's dedicated tree
  Future<List<ManagedPropertyModel>> getOwnerProperties(String ownerId) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        return [];
      }
      final snapshot = await _db
          .collection('Users')
          .doc(ownerId)
          .collection('properties')
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        return ManagedPropertyModel.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting owner properties from Firestore: $e');
      return [];
    }
  }

  /// Real-time stream of an owner's dedicated properties tree
  Stream<List<ManagedPropertyModel>> streamOwnerProperties(String ownerId) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Stream.empty();
    }
    return _db
        .collection('Users')
        .doc(ownerId)
        .collection('properties')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ManagedPropertyModel.fromMap(doc.data(), docId: doc.id);
      }).toList();
    });
  }

  /// Purges any legacy mock starter properties (e.g. prop-eg-101, prop-eg-102, SIM-*) from the owner's Firestore tree
  Future<void> purgeMockPropertiesForOwner(String ownerId) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) return;
      final snapshot = await _db
          .collection('Users')
          .doc(ownerId)
          .collection('properties')
          .get();

      final batch = _db.batch();
      bool hasDeletions = false;
      for (final doc in snapshot.docs) {
        final id = doc.id;
        final isMock = id.startsWith('prop-eg-') ||
            id.startsWith('prop-ae-') ||
            id.startsWith('SIM-');
        if (isMock) {
          batch.delete(doc.reference);
          final marketRef = _db.collection('Properties').doc(id);
          batch.delete(marketRef);
          hasDeletions = true;
        }
      }
      if (hasDeletions) {
        await batch.commit();
        debugPrint('✅ Cleaned legacy mock properties from owner [$ownerId] Firestore tree.');
      }
    } catch (e) {
      debugPrint('Note: Purging mock properties note: $e');
    }
  }

  /// Real user accounts must NEVER be polluted with mock sample data.
  Future<void> seedDefaultOwnerPropertiesIfEmpty(
    String ownerId,
    List<ManagedPropertyModel> sampleProperties,
  ) async {
    // Intentionally no-op: new owner accounts must always start with a clean slate.
  }

  /// Deletes a property from owner tree and marketplace
  Future<void> deleteOwnerProperty({
    required String ownerId,
    required String propertyId,
  }) async {
    try {
      await _db
          .collection('Users')
          .doc(ownerId)
          .collection('properties')
          .doc(propertyId)
          .delete();

      await _db.collection('Properties').doc(propertyId).delete();
    } catch (e) {
      debugPrint('Error deleting property from Firestore: $e');
    }
  }

  // --- 3. General Save (for backward compatibility) ---

  Future<void> saveProperty(Map<String, dynamic> propertyData) async {
    try {
      final id = propertyData['id'] as String? ?? 'prop-${DateTime.now().millisecondsSinceEpoch}';
      await _db.collection('Properties').doc(id).set({
        ...propertyData,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving general property to Firestore: $e');
    }
  }

  // --- 4. Public Marketplace Retrieval ---

  /// Fetches public marketplace properties from Firestore
  Future<List<PropertyItem>> getMarketplaceProperties({String? countryCode}) async {
    try {
      Query query = _db.collection('Properties').where('is_published', isEqualTo: true);
      if (countryCode != null) {
        query = query.where('countryCode', isEqualTo: countryCode);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return PropertyItem.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting marketplace properties: $e');
      return [];
    }
  }
}

