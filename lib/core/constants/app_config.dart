/// Compile-time application configuration.
///
/// Run against a real backend with:
/// `flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://erp.example.com/api`
///
/// The mock layer lives exclusively in `features/*/data/*_mock_repository.dart`
/// and `core/mock/mock_database.dart`, so switching to production cannot leak
/// fake responses into a release build.
abstract final class AppConfig {
  static const appName = 'SpeedCode Labs';
  static const appSubtitle = 'Staff ERP';
  static const appVersion = '1.0.0';

  static const useMockData = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.speedcodelabs.com/api/v1',
  );

  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 25);

  /// Demo credentials used only by the mock authentication repository.
  static const demoEmployeeId = 'SCL-001';
  static const demoPassword = 'password123';
}
