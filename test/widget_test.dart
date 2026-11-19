import 'package:flutter_test/flutter_test.dart';
import 'package:speedcode_erp/core/models/employee.dart';
import 'package:speedcode_erp/core/utils/date_utils.dart';

void main() {
  group('Employee', () {
    const employee = Employee(
      id: 'emp-001',
      employeeCode: 'SCL-001',
      name: 'Ayash Perera',
      email: 'ayash@speedcodelabs.com',
      phone: '+94 77 452 8891',
      department: 'Engineering',
      designation: 'Senior Flutter Engineer',
      location: 'Colombo',
    );

    test('builds initials from first and last name', () {
      expect(employee.initials, 'AP');
    });

    test('copyWith updates only the requested fields', () {
      final updated = employee.copyWith(
        phone: '+94 70 000 0000',
        location: 'Kandy',
      );

      expect(updated.phone, '+94 70 000 0000');
      expect(updated.location, 'Kandy');
      expect(updated.name, employee.name);
      expect(updated.employeeCode, employee.employeeCode);
    });

    test('round-trips through JSON', () {
      final restored = Employee.fromJson(employee.toJson());

      expect(restored.id, employee.id);
      expect(restored.name, employee.name);
      expect(restored.department, employee.department);
      expect(restored.workStatus, employee.workStatus);
    });
  });

  group('AppDate', () {
    test('formats durations with hours and minutes', () {
      expect(AppDate.duration(const Duration(minutes: 42)), '42m');
      expect(AppDate.duration(const Duration(hours: 8, minutes: 5)), '8h 05m');
    });

    test('compares calendar days without time', () {
      expect(
        AppDate.isSameDay(DateTime(2026, 5, 4, 9), DateTime(2026, 5, 4, 18)),
        isTrue,
      );
      expect(
        AppDate.isSameDay(DateTime(2026, 5, 4, 23), DateTime(2026, 5, 5)),
        isFalse,
      );
    });

    test('greeting changes across the day', () {
      expect(AppDate.greeting(DateTime(2026, 5, 4, 8)), 'Good morning');
      expect(AppDate.greeting(DateTime(2026, 5, 4, 14)), 'Good afternoon');
      expect(AppDate.greeting(DateTime(2026, 5, 4, 20)), 'Good evening');
    });
  });
}
