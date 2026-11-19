import '../../../core/models/employee.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.employee,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final Employee employee;
}
