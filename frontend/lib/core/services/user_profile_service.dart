import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/services/storage/local_storage_service.dart';
import '../utils/digit_utils.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';

/// Immutable model representing the active user's PropTech profile
class UserProfileData {
  final String uid;
  final String email;
  final String fullName;
  final String firstName;
  final String surname;
  final String? photoUrl;
  final String phone;
  final String role;
  final String preferredContactMethod; // 'phone', 'whatsapp', 'email'
  final bool isVerified;
  final bool isPhoneVerified;
  final DateTime? memberSince;
  final String nationalId;
  final String address;
  final String? idCardPhotoUrl;
  final String bankName;
  final String bankAccountNumber;
  final String iban;

  const UserProfileData({
    required this.uid,
    required this.email,
    required this.fullName,
    this.firstName = '',
    this.surname = '',
    this.photoUrl,
    this.phone = '',
    this.role = 'Owner',
    this.preferredContactMethod = 'phone',
    this.isVerified = true,
    this.isPhoneVerified = false,
    this.memberSince,
    this.nationalId = '',
    this.address = '',
    this.idCardPhotoUrl,
    this.bankName = '',
    this.bankAccountNumber = '',
    this.iban = '',
  });

  String get computedFirstName =>
      firstName.trim().isNotEmpty ? firstName.trim() : UserAvatarUtils.getFirstName(fullName);

  String get computedSurname =>
      surname.trim().isNotEmpty ? surname.trim() : UserAvatarUtils.getSurname(fullName);

  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasFullName => fullName.trim().isNotEmpty;
  bool get hasNationalId => nationalId.trim().isNotEmpty;
  bool get hasAddress => address.trim().isNotEmpty;
  bool get hasBankInfo =>
      bankName.trim().isNotEmpty || bankAccountNumber.trim().isNotEmpty || iban.trim().isNotEmpty;

  /// Calculate completion percentage (0.0 to 1.0) based on Email, Name, Phone, National ID, Address, and Bank
  double get completeness {
    int points = 0;
    const int total = 6;
    if (email.trim().isNotEmpty) points++;
    if (hasFullName) points++;
    if (hasPhone) points++;
    if (hasNationalId) points++;
    if (hasAddress) points++;
    if (hasBankInfo) points++;
    return points / total;
  }

  int get completenessPercent => (completeness * 100).round();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'firstName': firstName,
      'surname': surname,
      'photoUrl': photoUrl,
      'phone': phone,
      'role': role,
      'preferredContactMethod': preferredContactMethod,
      'isVerified': isVerified,
      'isPhoneVerified': isPhoneVerified,
      'memberSince': memberSince?.toIso8601String(),
      'nationalId': nationalId,
      'address': address,
      'idCardPhotoUrl': idCardPhotoUrl,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'iban': iban,
    };
  }

  factory UserProfileData.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserProfileData(
      uid: (map['uid'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['fullName'] ?? map['full_name'] ?? '').toString(),
      firstName: (map['firstName'] ?? map['first_name'] ?? '').toString(),
      surname: (map['surname'] ?? '').toString(),
      photoUrl: (map['photoUrl'] ?? map['photo_url'])?.toString(),
      phone: DigitUtils.normalize((map['phone'] ?? '').toString()),
      role: (map['role'] ?? 'Owner').toString(),
      preferredContactMethod: (map['preferredContactMethod'] ?? map['preferred_contact_method'] ?? 'phone').toString(),
      isVerified: map['isVerified'] != false && map['verified'] != false,
      isPhoneVerified: map['isPhoneVerified'] == true || map['phone_verified'] == true,
      memberSince: parseDate(map['memberSince'] ?? map['created_at']),
      nationalId: DigitUtils.normalize((map['nationalId'] ?? map['national_id'] ?? '').toString()),
      address: DigitUtils.normalize((map['address'] ?? '').toString()),
      idCardPhotoUrl: (map['idCardPhotoUrl'] ?? map['id_card_photo_url'])?.toString(),
      bankName: (map['bankName'] ?? map['bank_name'] ?? '').toString(),
      bankAccountNumber: DigitUtils.normalize((map['bankAccountNumber'] ?? map['bank_account_number'] ?? '').toString()),
      iban: DigitUtils.normalize((map['iban'] ?? '').toString()),
    );
  }

  UserProfileData copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? firstName,
    String? surname,
    String? photoUrl,
    String? phone,
    String? role,
    String? preferredContactMethod,
    bool? isVerified,
    bool? isPhoneVerified,
    DateTime? memberSince,
    String? nationalId,
    String? address,
    String? idCardPhotoUrl,
    String? bankName,
    String? bankAccountNumber,
    String? iban,
  }) {
    return UserProfileData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      surname: surname ?? this.surname,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      isVerified: isVerified ?? this.isVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      memberSince: memberSince ?? this.memberSince,
      nationalId: nationalId ?? this.nationalId,
      address: address ?? this.address,
      idCardPhotoUrl: idCardPhotoUrl ?? this.idCardPhotoUrl,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      iban: iban ?? this.iban,
    );
  }
}

/// Central reactive service managing user profile state and Firestore synchronization
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;

  static const String _profileCacheKey = 'tashil_cached_user_profile_v1';
  static const String _lastOwnerKey = 'tashil_last_authenticated_owner_id';

  UserProfileService._internal() {
    _initProfile();
  }

  final ValueNotifier<UserProfileData> profileNotifier = ValueNotifier<UserProfileData>(
    const UserProfileData(
      uid: '',
      email: '',
      fullName: '',
      firstName: '',
      surname: '',
      phone: '',
      role: 'Owner',
    ),
  );

  bool _initialized = false;

  void _initProfile() {
    if (_initialized) return;
    _initialized = true;

    // Instant 0ms synchronous local cache hydration
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final cachedJson = LocalStorageService().getString(_profileCacheKey);
      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        final decoded = jsonDecode(cachedJson);
        if (decoded is Map<String, dynamic> || decoded is Map) {
          final profileMap = Map<String, dynamic>.from(decoded as Map);
          final cachedUid = profileMap['uid']?.toString() ?? '';
          // Only hydrate from cache if it matches the current user or if not authenticated yet
          if (currentUid == null || cachedUid.isEmpty || cachedUid == currentUid) {
            final authUser = FirebaseAuth.instance.currentUser;
            var hydratedProfile = UserProfileData.fromMap(profileMap);
            // If cached profile lacks a photo, auto-fill from Google auth if available
            if ((hydratedProfile.photoUrl == null || hydratedProfile.photoUrl!.isEmpty) && authUser != null) {
              final googlePhoto = UserAvatarUtils.getPhotoUrl(authUser);
              if (googlePhoto != null && googlePhoto.isNotEmpty) {
                hydratedProfile = hydratedProfile.copyWith(photoUrl: googlePhoto);
              }
            }
            profileNotifier.value = hydratedProfile;
            debugPrint('UserProfileService: Hydrated profile in 0ms from LocalStorage for [${profileNotifier.value.fullName}] (Photo: ${profileNotifier.value.photoUrl != null})');
          }
        }
      }
    } catch (e) {
      debugPrint('UserProfileService cache load note: $e');
    }

    loadProfile();

    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null && user.uid.isNotEmpty) {
          LocalStorageService().setString(_lastOwnerKey, user.uid);
        }
        loadProfile();
      });
    } catch (_) {
      // Ignore in mock or test environment
    }
  }

  void _persistProfileLocally(UserProfileData profile) {
    try {
      if (profile.uid.isNotEmpty) {
        LocalStorageService().setString(_lastOwnerKey, profile.uid);
        LocalStorageService().setString(_profileCacheKey, jsonEncode(profile.toMap()));
      }
    } catch (e) {
      debugPrint('UserProfileService._persistProfileLocally error: $e');
    }
  }

  void clearLocalCache() {
    LocalStorageService().remove(_profileCacheKey);
    LocalStorageService().remove(_lastOwnerKey);
    profileNotifier.value = const UserProfileData(
      uid: '',
      email: '',
      fullName: '',
      firstName: '',
      surname: '',
      phone: '',
      role: 'Owner',
    );
  }

  /// Reloads profile data combining Firebase Auth and Firestore data
  Future<void> loadProfile() async {
    final user = UserAvatarUtils.safeCurrentUser;
    if (user == null) {
      profileNotifier.value = const UserProfileData(
        uid: '',
        email: '',
        fullName: '',
        firstName: '',
        surname: '',
        phone: '',
        role: 'Owner',
      );
      return;
    }

    // Refresh user metadata from Firebase Auth safely
    try {
      await user.reload();
    } catch (_) {}

    // Default seed directly from Google / Firebase Auth
    String email = user.email ?? '';
    String? photoUrl = UserAvatarUtils.getPhotoUrl(user);

    // Prioritize Google's display name if provided (e.g. "Mohamed Fathallah" / "omar fathalla")
    String fullName = '';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      fullName = user.displayName!.trim();
    } else {
      for (final provider in user.providerData) {
        if (provider.displayName != null && provider.displayName!.trim().isNotEmpty) {
          fullName = provider.displayName!.trim();
          break;
        }
      }
      if (fullName.isEmpty && email.isNotEmpty) {
        fullName = email.split('@').first;
      }
    }

    String firstName = UserAvatarUtils.getFirstName(fullName);
    String surname = UserAvatarUtils.getSurname(fullName);
    String phone = user.phoneNumber ?? '';
    String role = 'Owner';
    String preferredMethod = 'phone';
    bool verified = true;
    DateTime? memberSince = user.metadata.creationTime;

    // Populate initial state before remote fetch
    profileNotifier.value = UserProfileData(
      uid: user.uid,
      email: email,
      fullName: fullName,
      firstName: firstName,
      surname: surname,
      photoUrl: photoUrl,
      phone: phone,
      role: role,
      preferredContactMethod: preferredMethod,
      isVerified: verified,
      memberSince: memberSince,
    );

    // Fetch Firestore remote document
    try {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final dbName = data['full_name']?.toString().trim();
        final emailPrefix = email.split('@').first.trim();

        // The user's ID Card and saved profile data take strict priority over Google Auth display name
        if (dbName != null && dbName.isNotEmpty && dbName != emailPrefix) {
          fullName = dbName;
        } else if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          fullName = user.displayName!.trim();
        } else if (dbName != null && dbName.isNotEmpty) {
          fullName = dbName;
        }

        if (data['first_name'] != null && data['first_name'].toString().trim().isNotEmpty) {
          firstName = data['first_name'].toString().trim();
        } else {
          firstName = UserAvatarUtils.getFirstName(fullName);
        }

        if (data['surname'] != null && data['surname'].toString().trim().isNotEmpty) {
          surname = data['surname'].toString().trim();
        } else {
          surname = UserAvatarUtils.getSurname(fullName);
        }

        if (data['photo_url'] != null && data['photo_url'].toString().trim().isNotEmpty) {
          photoUrl = data['photo_url'].toString().trim();
        } else if (photoUrl != null && photoUrl.isNotEmpty) {
          // Auto-sync Google photo into Firestore if missing
          try {
            await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
              'photo_url': photoUrl,
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
        }

        if (data['phone'] != null && data['phone'].toString().trim().isNotEmpty) {
          phone = data['phone'].toString().trim();
        }
        if (data['role'] != null && data['role'].toString().trim().isNotEmpty) {
          role = data['role'].toString().trim();
        }
        if (data['preferred_contact_method'] != null) {
          preferredMethod = data['preferred_contact_method'].toString().trim();
        }
        if (data['verified'] != null) {
          verified = data['verified'] == true;
        }
        bool phoneVerified = false;
        if (data['phone_verified'] != null) {
          phoneVerified = data['phone_verified'] == true;
        }

        final nationalId = DigitUtils.normalize(data['national_id']?.toString().trim() ?? '');
        final address = DigitUtils.normalize(data['address']?.toString().trim() ?? '');
        final idCardPhotoUrl = data['id_card_photo_url']?.toString().trim();
        final bankName = data['bank_name']?.toString().trim() ?? '';
        final bankAccountNumber = DigitUtils.normalize(data['bank_account_number']?.toString().trim() ?? '');
        final iban = DigitUtils.normalize(data['iban']?.toString().trim() ?? '');

        profileNotifier.value = UserProfileData(
          uid: user.uid,
          email: email,
          fullName: fullName,
          firstName: firstName,
          surname: surname,
          photoUrl: photoUrl,
          phone: phone,
          role: role,
          preferredContactMethod: preferredMethod,
          isVerified: verified,
          isPhoneVerified: phoneVerified,
          memberSince: memberSince,
          nationalId: nationalId,
          address: address,
          idCardPhotoUrl: idCardPhotoUrl,
          bankName: bankName,
          bankAccountNumber: bankAccountNumber,
          iban: iban,
        );
        _persistProfileLocally(profileNotifier.value);
        debugPrint('UserProfileService: Loaded profile for [${profileNotifier.value.fullName}] (Photo: ${profileNotifier.value.photoUrl != null})');
      }
    } catch (e) {
      debugPrint('UserProfileService.loadProfile fetch error: $e');
    }
  }

  /// Explicitly re-syncs profile photo and data from Google / Firebase Auth
  Future<bool> syncFromGoogleAuth({bool overrideName = true}) async {
    final user = UserAvatarUtils.safeCurrentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final freshPhoto = UserAvatarUtils.getPhotoUrl(user);
      String? freshName;
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        freshName = user.displayName!.trim();
      } else {
        for (final provider in user.providerData) {
          if (provider.displayName != null && provider.displayName!.trim().isNotEmpty) {
            freshName = provider.displayName!.trim();
            break;
          }
        }
      }

      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (freshPhoto != null && freshPhoto.isNotEmpty) {
        updates['photo_url'] = freshPhoto;
      }
      if (overrideName && freshName != null && freshName.isNotEmpty) {
        updates['full_name'] = freshName;
        updates['first_name'] = UserAvatarUtils.getFirstName(freshName);
        updates['surname'] = UserAvatarUtils.getSurname(freshName);
      }
      if (user.email != null && user.email!.isNotEmpty) {
        updates['email'] = user.email!;
      }

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set(updates, SetOptions(merge: true));

      await updateProfile(
        photoUrl: freshPhoto,
        fullName: overrideName ? freshName : null,
        firstName: overrideName && freshName != null ? UserAvatarUtils.getFirstName(freshName) : null,
        surname: overrideName && freshName != null ? UserAvatarUtils.getSurname(freshName) : null,
      );
      debugPrint('UserProfileService.syncFromGoogleAuth: Successfully synced [name: $freshName, photo: $freshPhoto]');
      return true;
    } catch (e) {
      debugPrint('UserProfileService.syncFromGoogleAuth error: $e');
    }
    return false;
  }

  /// Updates user profile in Firestore and local state
  Future<void> updateProfile({
    String? fullName,
    String? firstName,
    String? surname,
    String? phone,
    String? preferredContactMethod,
    String? photoUrl,
    bool? isPhoneVerified,
    String? nationalId,
    String? address,
    String? idCardPhotoUrl,
    String? bankName,
    String? bankAccountNumber,
    String? iban,
  }) async {
    final current = profileNotifier.value;
    String resolvedFullName = fullName ?? current.fullName;
    String resolvedFirstName = firstName ?? current.firstName;
    String resolvedSurname = surname ?? current.surname;

    if (firstName != null || surname != null) {
      resolvedFirstName = (firstName ?? current.firstName).trim();
      resolvedSurname = (surname ?? current.surname).trim();
      resolvedFullName = '$resolvedFirstName $resolvedSurname'.trim();
    }

    final normPhone = phone != null ? DigitUtils.normalize(phone.trim()) : null;
    final normNationalId = nationalId != null ? DigitUtils.normalize(nationalId.trim()) : null;
    final normAddress = address != null ? DigitUtils.normalize(address.trim()) : null;
    final normBankAccount = bankAccountNumber != null ? DigitUtils.normalize(bankAccountNumber.trim()) : null;
    final normIban = iban != null ? DigitUtils.normalize(iban.trim()) : null;

    final updated = current.copyWith(
      fullName: resolvedFullName,
      firstName: resolvedFirstName,
      surname: resolvedSurname,
      phone: normPhone,
      preferredContactMethod: preferredContactMethod,
      photoUrl: photoUrl,
      isPhoneVerified: isPhoneVerified,
      nationalId: normNationalId,
      address: normAddress,
      idCardPhotoUrl: idCardPhotoUrl,
      bankName: bankName,
      bankAccountNumber: normBankAccount,
      iban: normIban,
    );

    profileNotifier.value = updated;
    _persistProfileLocally(updated);

    final user = UserAvatarUtils.safeCurrentUser;
    if (user != null) {
      try {
        if (resolvedFullName.isNotEmpty && resolvedFullName != user.displayName) {
          await user.updateDisplayName(resolvedFullName);
        }
      } catch (e) {
        debugPrint('Error updating Auth displayName: $e');
      }

      try {
        final updateMap = <String, dynamic>{
          'updated_at': FieldValue.serverTimestamp(),
          'full_name': resolvedFullName,
          'first_name': resolvedFirstName,
          'surname': resolvedSurname,
        };
        if (normPhone != null) updateMap['phone'] = normPhone;
        if (isPhoneVerified != null) updateMap['phone_verified'] = isPhoneVerified;
        if (preferredContactMethod != null) {
          updateMap['preferred_contact_method'] = preferredContactMethod;
        }
        if (photoUrl != null) updateMap['photo_url'] = photoUrl;
        if (normNationalId != null) updateMap['national_id'] = normNationalId;
        if (normAddress != null) updateMap['address'] = normAddress;
        if (idCardPhotoUrl != null) updateMap['id_card_photo_url'] = idCardPhotoUrl;
        if (bankName != null) updateMap['bank_name'] = bankName.trim();
        if (normBankAccount != null) updateMap['bank_account_number'] = normBankAccount;
        if (normIban != null) updateMap['iban'] = normIban;

        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .set(updateMap, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating Firestore profile: $e');
      }
    }
  }

  /// Direct fast update for user avatar photo (Data URI or URL)
  Future<void> updateAvatarPhoto(String photoDataOrUrl) async {
    final cleanPhoto = photoDataOrUrl.trim();
    if (cleanPhoto.isEmpty) return;

    final current = profileNotifier.value;
    final updated = current.copyWith(photoUrl: cleanPhoto);
    profileNotifier.value = updated;
    _persistProfileLocally(updated);

    final user = UserAvatarUtils.safeCurrentUser;
    if (user != null && user.uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
          'photo_url': cleanPhoto,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('UserProfileService.updateAvatarPhoto Firestore error: $e');
      }
    }
  }

  /// Send Phone Verification OTP
  Future<String> sendPhoneVerificationOtp(String fullPhoneNumber) async {
    debugPrint('UserProfileService: Sending OTP to $fullPhoneNumber');
    return await FirebaseAuthService().sendPhoneOtp(fullPhoneNumber);
  }

  /// Verify OTP code and update user profile in Firestore
  Future<bool> verifyPhoneOtp({
    required String fullPhoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    final cleanCode = smsCode.trim();
    debugPrint('UserProfileService: Verifying OTP "$cleanCode" for $fullPhoneNumber');

    final isSuccess = await FirebaseAuthService().verifyPhoneOtp(
      fullPhoneNumber: fullPhoneNumber,
      verificationId: verificationId,
      smsCode: cleanCode,
    );

    if (isSuccess) {
      await updateProfile(
        phone: fullPhoneNumber,
        isPhoneVerified: true,
      );
      return true;
    }
    return false;
  }

  /// Setter for testing purposes
  @visibleForTesting
  void setMockProfile(UserProfileData mock) {
    profileNotifier.value = mock;
  }
}
