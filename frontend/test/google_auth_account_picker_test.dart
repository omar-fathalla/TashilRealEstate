import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleAuthProvider Custom Parameters Test', () {
    test('GoogleAuthProvider includes prompt: select_account', () {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      expect(googleProvider.parameters['prompt'], equals('select_account'));
      expect(googleProvider.scopes, contains('email'));
      expect(googleProvider.scopes, contains('profile'));
    });
  });
}
