import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';

void main() {
  group('UserAvatarUtils Tests', () {
    test('Extracts English initials correctly', () {
      expect(UserAvatarUtils.getInitials('Mohamed Fathallah'), equals('MF'));
      expect(UserAvatarUtils.getInitials('Ahmed Fouad'), equals('AF'));
      expect(UserAvatarUtils.getInitials('John Doe'), equals('JD'));
    });

    test('Extracts Arabic initials with space separation', () {
      expect(UserAvatarUtils.getInitials('محمد فتح الله'), equals('م ف'));
      expect(UserAvatarUtils.getInitials('أحمد فؤاد'), equals('أ ف'));
      expect(UserAvatarUtils.getInitials('محمد حافظ'), equals('م ح'));
    });

    test('Handles single-word names and fallbacks', () {
      expect(UserAvatarUtils.getInitials('Fathallah'), equals('FA'));
      expect(UserAvatarUtils.getInitials(''), equals('U'));
      expect(UserAvatarUtils.getInitials(null), equals('U'));
      expect(UserAvatarUtils.getInitials(null, 'AF'), equals('AF'));
    });

    test('getPhotoUrl returns null safely for null or empty users', () {
      expect(UserAvatarUtils.getPhotoUrl(null), isNull);
    });
  });
}
