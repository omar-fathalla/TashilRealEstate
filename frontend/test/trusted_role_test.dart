import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/auth/trusted_role.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';

void main() {
  group('TAQ-53: TrustedRole mirrors currentRole() in firestore.rules', () {
    test('a custom claim wins over the profile', () {
      expect(TrustedRole.fromSources(claimRole: 'AgencyAdmin', profileRole: 'Owner'), 'AgencyAdmin');
      expect(TrustedRole.fromSources(claimRole: 'Tenant', profileRole: 'Owner'), 'Tenant');
      expect(TrustedRole.fromSources(claimRole: 'SuperAdmin'), 'SuperAdmin');
    });

    test('the profile is trusted only for self-service roles', () {
      expect(TrustedRole.fromSources(profileRole: 'Owner'), 'Owner');
      expect(TrustedRole.fromSources(profileRole: 'Tenant'), 'Tenant');
      expect(TrustedRole.fromSources(profileRole: 'SuperAdmin'), '');
      expect(TrustedRole.fromSources(profileRole: 'AgencyAdmin'), '');
    });

    test('unknown, empty, or non-string values grant nothing', () {
      expect(TrustedRole.fromSources(), '');
      expect(TrustedRole.fromSources(claimRole: 'Root', profileRole: 'Owner'), '');
      expect(TrustedRole.fromSources(claimRole: '', profileRole: 'Owner'), 'Owner');
      expect(TrustedRole.fromSources(profileRole: 'owner'), '');
      expect(TrustedRole.fromSources(profileRole: 42), '');
    });
  });

  group('TAQ-53: the verified badge needs the server flag', () {
    test('profiles start unverified', () {
      expect(const UserProfileData(uid: 'u', email: 'e', fullName: 'n').isVerified, isFalse);
    });

    test('a cached profile without the flag is unverified', () {
      expect(UserProfileData.fromMap(const {'uid': 'u', 'email': 'e', 'fullName': 'n'}).isVerified, isFalse);
      expect(UserProfileData.fromMap(const {'uid': 'u', 'email': 'e', 'fullName': 'n', 'isVerified': true}).isVerified, isTrue);
    });
  });
}
