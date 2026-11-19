import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/models/employee.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../authentication/domain/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String employeeId,
    required String password,
    required bool rememberMe,
  });

  Future<Employee?> restoreSession(String token);
  Future<void> logout();
  Future<Employee> updateProfile(Employee employee);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._db);

  final MockDatabase _db;

  @override
  Future<AuthSession> login({
    required String employeeId,
    required String password,
    required bool rememberMe,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final normalized = employeeId.trim().toUpperCase();
    final validId =
        normalized == AppConfig.demoEmployeeId ||
        normalized == _db.currentUser.email.toUpperCase();
    if (!validId || password != AppConfig.demoPassword) {
      throw const AuthException('Invalid employee ID or password.');
    }
    return AuthSession(
      accessToken: 'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-refresh-token',
      employee: _db.currentUser,
    );
  }

  @override
  Future<Employee?> restoreSession(String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (token.isEmpty) return null;
    return _db.currentUser;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<Employee> updateProfile(Employee employee) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return employee;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (currentPassword != AppConfig.demoPassword) {
      throw const AuthException('Your current password is incorrect.');
    }
    if (newPassword.length < 8) {
      throw const AuthException('New password must be at least 8 characters.');
    }
  }
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> login({
    required String employeeId,
    required String password,
    required bool rememberMe,
  }) async {
    final data = await _client.post(
      ApiEndpoints.login,
      data: {
        'employee_id': employeeId.trim(),
        'password': password,
        'remember_me': rememberMe,
      },
    );
    final map = _asMap(data);
    final token = map['access_token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const AuthException('The server did not return an access token.');
    }
    return AuthSession(
      accessToken: token,
      refreshToken: map['refresh_token']?.toString(),
      employee: Employee.fromJson(_asMap(map['employee'] ?? map['user'])),
    );
  }

  @override
  Future<Employee?> restoreSession(String token) async {
    if (token.isEmpty) return null;
    final data = await _client.get(ApiEndpoints.me);
    return Employee.fromJson(_asMap(data));
  }

  @override
  Future<void> logout() async {
    await _client.post(ApiEndpoints.logout);
  }

  @override
  Future<Employee> updateProfile(Employee employee) async {
    final data = await _client.patch(
      ApiEndpoints.updateProfile,
      data: employee.toJson(),
    );
    return Employee.fromJson(_asMap(data));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post(
      ApiEndpoints.changePassword,
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    if (value['data'] is Map) {
      return (value['data'] as Map).cast<String, dynamic>();
    }
    return value;
  }
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockAuthRepository(MockDatabase.instance);
  }
  return ApiAuthRepository(ref.watch(apiClientProvider));
});
