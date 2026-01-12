import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/env.dart';
import '../errors/exceptions.dart';
import 'api_interceptor.dart';

/// Provider for the Dio client
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// HTTP client wrapper using Dio
class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LogInterceptor(
        requestBody: Env.isDebug,
        responseBody: Env.isDebug,
        error: true,
      ),
    ]);
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert to app exceptions
  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please try again.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        String message = 'Server error occurred';
        String? code;

        if (data is Map<String, dynamic>) {
          final errorData = data['error'];
          if (errorData is Map<String, dynamic>) {
            message = errorData['message'] ?? message;
            code = errorData['code'];
          }
        }

        if (statusCode == 401) {
          return AuthException(
            message: message,
            code: code ?? 'UNAUTHORIZED',
          );
        }

        if (statusCode == 404) {
          return NotFoundException(
            message: message,
            code: code,
          );
        }

        if (statusCode == 422) {
          Map<String, List<String>>? fieldErrors;
          if (data is Map<String, dynamic>) {
            final details = data['error']?['details'];
            if (details is List) {
              fieldErrors = {};
              for (final detail in details) {
                if (detail is Map<String, dynamic>) {
                  final field = detail['field'] as String?;
                  final msg = detail['message'] as String?;
                  if (field != null && msg != null) {
                    fieldErrors[field] = [msg];
                  }
                }
              }
            }
          }
          return ValidationException(
            message: message,
            code: code,
            fieldErrors: fieldErrors,
          );
        }

        return ServerException(
          message: message,
          code: code,
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const AppException(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      default:
        return AppException(
          message: error.message ?? 'An unexpected error occurred',
          code: 'UNKNOWN',
          originalError: error,
        );
    }
  }
}
