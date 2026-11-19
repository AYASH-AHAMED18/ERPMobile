import 'package:dio/dio.dart';

/// User-facing error abstraction. Repositories never expose raw exceptions to
/// the presentation layer.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.isUnauthorized = false});

  final String message;
  final String? code;
  final bool isUnauthorized;

  factory AppException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return const AppException(
        'Your session has expired. Please sign in again.',
        isUnauthorized: true,
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const AppException(
        'The server took too long to respond. Please try again.',
        code: 'timeout',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const AppException(
        'No internet connection. Check your network and try again.',
        code: 'network',
      );
    }
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return AppException(
        data['message'] as String,
        code: data['code']?.toString(),
      );
    }
    return AppException(
      'Something went wrong. Please try again.',
      code: status?.toString(),
    );
  }

  @override
  String toString() => message;
}

String readableError(Object error) {
  if (error is AppException) return error.message;
  return 'Something went wrong. Please try again.';
}
