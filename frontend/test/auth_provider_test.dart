import 'package:flutter_test/flutter_test.dart';
import 'package:aura_ems_frontend/providers/auth_provider.dart';

void main() {
  group('AuthProvider Unit Tests', () {
    test('initial state should be unauthenticated', () {
      final auth = AuthProvider();
      expect(auth.isAuthenticated, false);
      expect(auth.currentUser, null);
      expect(auth.isLoading, false);
      expect(auth.errorMessage, null);
    });

    test('logout should clear currentUser and state', () {
      final auth = AuthProvider();
      auth.logout();
      expect(auth.isAuthenticated, false);
      expect(auth.currentUser, null);
    });
  });
}
