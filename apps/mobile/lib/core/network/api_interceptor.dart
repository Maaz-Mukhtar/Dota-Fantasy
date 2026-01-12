import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interceptor that adds the Supabase auth token to requests
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get the current session from Supabase
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Add the access token to the Authorization header
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If we get a 401, try to refresh the token
    if (err.response?.statusCode == 401) {
      try {
        final response = await Supabase.instance.client.auth.refreshSession();

        if (response.session != null) {
          // Retry the request with the new token
          final options = err.requestOptions;
          options.headers['Authorization'] =
              'Bearer ${response.session!.accessToken}';

          final dio = Dio();
          final retryResponse = await dio.fetch(options);
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        // Token refresh failed, sign out the user
        await Supabase.instance.client.auth.signOut();
      }
    }

    handler.next(err);
  }
}
