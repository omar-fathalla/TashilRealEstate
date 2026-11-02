import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile & Avatar M3 Standards Tests', () {
    testWidgets('UserAvatarUtils.buildAvatar renders fallback initials when photoUrl is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => UserAvatarUtils.buildAvatar(
                context: context,
                photoUrl: null,
                displayName: 'محمد أحمد',
                fallbackInitials: 'م أ',
                radius: 26,
              ),
            ),
          ),
        ),
      );

      expect(find.text('م أ'), findsOneWidget);
    });

    testWidgets('UserAvatarUtils.buildAvatar handles Base64 data URI gracefully', (tester) async {
      // 1x1 transparent GIF base64
      const base64Pixel = 'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
      const dataUri = 'data:image/gif;base64,$base64Pixel';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => UserAvatarUtils.buildAvatar(
                context: context,
                photoUrl: dataUri,
                displayName: 'Mohamed Fathalla',
                fallbackInitials: 'MF',
                radius: 26,
              ),
            ),
          ),
        ),
      );

      // Verify that buildAvatar rendered Image.memory rather than falling back immediately
      expect(find.byType(Image), findsOneWidget);
    });

    test('UserProfileData and Service correctly prioritizes ID card legal name over email prefix', () {
      final data = {
        'uid': 'test-owner-123',
        'email': 'fathalla80800@gmail.com',
        'phone': '+20 121 185 7725',
        'full_name': 'محمد احمد حسن فتح الله حسن',
        'national_id': '28709040200112',
        'address': '37 شارع الجمرك القديم, الإسكندرية',
        'bank_name': 'البنك الأهلي المصري (NBE)',
        'bank_account_number': '2115001380416701010',
      };

      final profile = UserProfileData.fromMap(data);

      expect(profile.fullName, equals('محمد احمد حسن فتح الله حسن'));
      expect(profile.nationalId, equals('28709040200112'));
      expect(profile.address, contains('الجمرك القديم'));
      expect(profile.hasNationalId, isTrue);
      expect(profile.hasAddress, isTrue);
      expect(profile.completeness, equals(1.0));
      expect(profile.completenessPercent, equals(100));
    });

    test('Trilingual Parity for new Profile and ID Card Preview keys', () {
      final locAr = AppLocalizations(const Locale('ar'));
      final locEn = AppLocalizations(const Locale('en'));
      final locHi = AppLocalizations(const Locale('hi'));

      const requiredKeys = [
        'idCardVerifiedPreview',
        'tapToViewFullCardAndRotate',
        'flipHorizontal',
        'resetOrientation',
        'changeAvatarPhoto',
        'avatarUpdatedSuccess',
        'rotateLeft',
        'rotateRight',
        'zoomIn',
        'zoomOut',
      ];

      for (final key in requiredKeys) {
        final valAr = locAr.tr(key);
        final valEn = locEn.tr(key);
        final valHi = locHi.tr(key);

        expect(valAr != key && valAr.isNotEmpty, isTrue, reason: 'Missing Arabic translation for: $key');
        expect(valEn != key && valEn.isNotEmpty, isTrue, reason: 'Missing English translation for: $key');
        expect(valHi != key && valHi.isNotEmpty, isTrue, reason: 'Missing Hindi translation for: $key');
      }
    });
  });
}
