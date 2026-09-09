import 'package:flutter_test/flutter_test.dart';
import 'package:aura_ems_frontend/models/client_model.dart';
import 'package:aura_ems_frontend/models/user_model.dart';
import 'package:aura_ems_frontend/providers/client_provider.dart';

void main() {
  group('Multi-Tenant Client Models & Provider Tests', () {
    test('ClientModel should parse JSON correctly and compute getters', () {
      final json = {
        'id': 2,
        'name': 'Bright Future Public School',
        'slug': 'bright-future',
        'status': 'active',
        'adminEmail': 'admin@brightfuture.edu',
        'createdAt': '2026-09-08T12:00:00.000Z',
        '_count': {
          'students': 45,
          'teachers': 8,
          'classes': 5,
          'users': 3,
        }
      };

      final client = ClientModel.fromJson(json);

      expect(client.id, 2);
      expect(client.name, 'Bright Future Public School');
      expect(client.slug, 'bright-future');
      expect(client.isActive, true);
      expect(client.isSuspended, false);
      expect(client.totalStudents, 45);
      expect(client.totalTeachers, 8);
    });

    test('ClientModel should correctly reflect suspended status', () {
      final client = ClientModel(
        id: 4,
        name: 'Suspended Academy',
        slug: 'suspended',
        status: 'suspended',
        adminEmail: 'admin@suspended.edu',
        createdAt: '2026-09-08',
      );

      expect(client.isActive, false);
      expect(client.isSuspended, true);
    });

    test('UserModel should correctly identify superadmin vs tenant admin', () {
      final superUser = UserModel(
        id: '1',
        name: 'Platform Owner',
        email: 'superadmin@auraems.com',
        role: 'SUPERADMIN',
        clientId: 1,
      );

      expect(superUser.isSuperAdmin, true);
      expect(superUser.isAdmin, false);

      final tenantAdmin = UserModel(
        id: '2',
        name: 'School Admin',
        email: 'admin@brightfuture.edu',
        role: 'ADMIN',
        clientId: 2,
        clientName: 'Bright Future Public School',
      );

      expect(tenantAdmin.isSuperAdmin, false);
      expect(tenantAdmin.isAdmin, true);
      expect(tenantAdmin.clientName, 'Bright Future Public School');
    });

    test('ClientProvider initial state should be empty and not loading', () {
      final provider = ClientProvider();
      expect(provider.clients, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.stats['totalClients'], 0);
    });
  });
}
