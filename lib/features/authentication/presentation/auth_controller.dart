import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../profile/domain/employee.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.employee,
    this.error,
    this.isSubmitting = false,
  });

  const AuthState.initializing() : this(status: AuthStatus.initializing);
  const AuthState.unauthenticated({String? error})
    : this(status: AuthStatus.unauthenticated, error: error);

  final AuthStatus status;
  final Employee? employee;
  final String? error;
  final bool isSubmitting;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isInitializing => status == AuthStatus.initializing;

  AuthState copyWith({
    AuthStatus? status,
    Employee? employee,
    String? error,
    bool clearError = false,
    bool? isSubmitting,
  }) {
    return AuthState(
      status: status ?? this.status,
      employee: employee ?? this.employee,
      error: clearError ? null : (error ?? this.error),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.initializing();

  SessionStorage get _storage => ref.read(sessionStorageProvider);

  Future<void> initialize() async {
    final client = ref.read(apiClientProvider);
    client.onUnauthorized = () {
      state = const AuthState.unauthenticated(
        error: 'Your session has expired. Please sign in again.',
      );
    };

    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final employee = await ref
          .read(authRepositoryProvider)
          .restoreSession(token);
      if (employee == null) {
        await _storage.clearTokens();
        state = const AuthState.unauthenticated();
      } else {
        state = AuthState(status: AuthStatus.authenticated, employee: employee);
      }
    } catch (_) {
      await _storage.clearTokens();
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> login({
    required String employeeId,
    required String password,
    required bool rememberMe,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final AuthSession session = await ref
          .read(authRepositoryProvider)
          .login(
            employeeId: employeeId,
            password: password,
            rememberMe: rememberMe,
          );
      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await _storage.saveRememberMe(rememberMe, employeeId: employeeId);
      state = AuthState(
        status: AuthStatus.authenticated,
        employee: session.employee,
      );
      return true;
    } on AuthException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: error.message,
      );
      return false;
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Unable to sign in. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Local session must still be cleared even if the server is unreachable.
    }
    await _storage.clearTokens();
    state = const AuthState.unauthenticated();
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> updateProfile(Employee employee) async {
    final updated = await ref
        .read(authRepositoryProvider)
        .updateProfile(employee);
    state = state.copyWith(employee: updated);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final currentEmployeeProvider = Provider<Employee?>((ref) {
  return ref.watch(authControllerProvider).employee;
});
