import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
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
  });

  String get computedFirstName =>
      firstName.trim().isNotEmpty ? firstName.trim() : UserAvatarUtils.getFirstName(fullName);

  String get computedSurname =>
      surname.trim().isNotEmpty ? surname.trim() : UserAvatarUtils.getSurname(fullName);

  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasFullName => fullName.trim().isNotEmpty;

  /// Calculate completion percentage (0.0 to 1.0) based on Email, Name, and Phone
  double get completeness {
    int points = 0;
    if (email.trim().isNotEmpty) points++;
    if (hasFullName) points++;
    if (hasPhone) points++;
    return points / 3.0;
  }

  int get completenessPercent => (completeness * 100).round();

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
    );
  }
}

/// Central reactive service managing user profile state and Firestore synchronization
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;

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
    loadProfile();

    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        loadProfile();
      });
    } catch (_) {
      // Ignore in mock or test environment
    }
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

    // Prioritize Google's display name if provided (e.g. "Mohamed Fathallah")
    String fullName = '';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      fullName = user.displayName!.trim();
    } else if (email.isNotEmpty) {
      fullName = email.split('@').first;
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

        // If Google provides a real display name, do not let an old email prefix fallback in DB override it
        if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          if (dbName != null && dbName.isNotEmpty && dbName != emailPrefix) {
            fullName = dbName;
          } else {
            fullName = user.displayName!.trim();
          }
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
        );
      }
    } catch (e) {
      debugPrint('UserProfileService.loadProfile fetch error: $e');
    }
  }

  /// Explicitly re-syncs profile photo and data from Google / Firebase Auth
  Future<bool> syncFromGoogleAuth() async {
    final user = UserAvatarUtils.safeCurrentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final freshPhoto = UserAvatarUtils.getPhotoUrl(user);
      if (freshPhoto != null && freshPhoto.isNotEmpty) {
        await updateProfile(photoUrl: freshPhoto);
        return true;
      }
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

    final updated = current.copyWith(
      fullName: resolvedFullName,
      firstName: resolvedFirstName,
      surname: resolvedSurname,
      phone: phone,
      preferredContactMethod: preferredContactMethod,
      photoUrl: photoUrl,
      isPhoneVerified: isPhoneVerified,
    );

    profileNotifier.value = updated;

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
        if (phone != null) updateMap['phone'] = phone.trim();
        if (isPhoneVerified != null) updateMap['phone_verified'] = isPhoneVerified;
        if (preferredContactMethod != null) {
          updateMap['preferred_contact_method'] = preferredContactMethod;
        }
        if (photoUrl != null) updateMap['photo_url'] = photoUrl;

        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .set(updateMap, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating Firestore profile: $e');
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
