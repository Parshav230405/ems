import 'package:flutter_test/flutter_test.dart';
import 'package:aura_ems_frontend/models/user_model.dart';
import 'package:aura_ems_frontend/models/student_model.dart';
import 'package:aura_ems_frontend/models/academic_models.dart';
import 'package:aura_ems_frontend/models/dashboard_model.dart';

void main() {
  group('Frontend Models Unit Tests', () {
    test('UserModel should correctly parse JSON and identify admin role', () {
      final json = {
        'id': 'user-123',
        'name': 'Super Admin',
        'email': 'admin@auraems.com',
        'role': 'ADMIN',
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.name, 'Super Admin');
      expect(user.isAdmin, true);
      expect(user.isStaff, false);
    });

    test('UserModel should correctly identify staff role', () {
      final json = {
        'id': 'user-456',
        'name': 'Staff User',
        'email': 'staff@auraems.com',
        'role': 'STAFF',
      };
      final user = UserModel.fromJson(json);
      expect(user.isAdmin, false);
      expect(user.isStaff, true);
    });

    test('StudentModel should parse JSON and format classDivision', () {
      final json = {
        'id': 'std-1',
        'admissionNumber': 'ADM001',
        'name': 'Rahul Patel',
        'dob': '2010-05-15',
        'gender': 'Male',
        'classId': 'cls-1',
        'class': {'name': '10', 'division': 'A'},
        'parentName': 'Amit Patel',
        'parentContact': '9876543210',
        'status': 'ACTIVE',
        'admissionDate': '2025-06-01',
      };
      final student = StudentModel.fromJson(json);
      expect(student.name, 'Rahul Patel');
      expect(student.admissionNumber, 'ADM001');
      expect(student.classDivision, '10-A');
    });

    test('ClassModel should format displayName properly', () {
      final json = {
        'id': 'cls-1',
        'name': '10',
        'division': 'A',
        'academicYear': '2025-2026',
        '_count': {'students': 25, 'subjects': 6},
      };
      final c = ClassModel.fromJson(json);
      expect(c.displayName, '10-A (2025-2026)');
      expect(c.studentCount, 25);
      expect(c.subjectCount, 6);
    });

    test('DashboardSummary should parse metrics and attendance stats', () {
      final json = {
        'totalStudents': 30,
        'totalTeachers': 5,
        'totalClasses': 3,
        'totalFeesCollected': 125000,
        'pendingFees': 35000,
        'attendance': {
          'percentage': 94,
          'present': 28,
          'absent': 2,
          'leave': 0,
          'date': '2026-09-08',
        },
      };
      final summary = DashboardSummary.fromJson(json);
      expect(summary.totalStudents, 30);
      expect(summary.totalTeachers, 5);
      expect(summary.attendancePercentage, 94);
      expect(summary.presentCount, 28);
      expect(summary.absentCount, 2);
    });
  });
}
