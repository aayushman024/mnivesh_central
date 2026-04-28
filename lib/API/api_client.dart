import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'api_config.dart';
import '../Managers/AuthManager.dart';
import '../Managers/AuthWrapper.dart';
import '../Services/FirebasePerformanceNetworkInterceptor.dart';
import '../Services/snackBar_Service.dart';

// Inject token and handle 401s globally
class AuthInterceptor extends Interceptor {
  static Future<String?>? _refreshFuture;
  static bool _isNavigatingToLogin = false;

  static Future<String?> refreshAccessTokenManually() async {
    debugPrint("Refreshed Token");
    final interceptor = AuthInterceptor();
    return interceptor._refreshAccessToken();
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    if (AuthManager.isLogoutInProgress) {
      handler.next(options);
      return;
    }

    final token = AuthManager.accessToken;
    final tokenType = AuthManager.tokenType ?? 'Bearer';

    if (token != null && token.isNotEmpty) {
      if (options.extra['useRawBearer'] == true) {
        options.headers['Authorization'] = 'Bearer ${_extractRaw(token)}';
      } else {
        options.headers['Authorization'] = '$tokenType $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldAttemptRefresh(err)) {
      handler.next(err);
      return;
    }

    if (AuthManager.isLogoutInProgress) {
      handler.next(err);
      return;
    }

    try {
      final refreshedToken = await _refreshAccessToken();
      if (refreshedToken == null) {
        await AuthManager.logout();
        _navigateToLogin();
        handler.next(err);
        return;
      }

      try {
        final retryResponse = await _retryRequest(
          err.requestOptions,
          refreshedToken,
        );
        handler.resolve(retryResponse);
      } on DioException catch (retryError) {
        // The refresh call succeeded, so a retry failure should be surfaced to
        // the caller instead of forcing logout. This allows service-specific
        // recovery like app-token sync on operations/attendance APIs.
        handler.next(retryError);
      }
    } on DioException catch (refreshError) {
      final statusCode = refreshError.response?.statusCode;
      if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
        await AuthManager.logout();
        _navigateToLogin();
      }
      handler.next(err);
    } catch (_) {
      handler.next(err);
    }
  }

  static void _navigateToLogin() {
    if (_isNavigatingToLogin) {
      return;
    }

    final nav = SnackbarService.navigatorKey.currentState;
    if (nav != null && nav.mounted) {
      _isNavigatingToLogin = true;
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (_) => false,
      );
      Future<void>.delayed(const Duration(milliseconds: 300)).then((_) {
        _isNavigatingToLogin = false;
      });
    }
  }

  bool _shouldAttemptRefresh(DioException err) {
    final requestOptions = err.requestOptions;
    if (err.response?.statusCode != 401) return false;
    if (requestOptions.extra['skipRefresh'] == true) return false;
    if (requestOptions.extra['retried'] == true) return false;
    if (requestOptions.path.endsWith('/auth/mobile/refresh')) return false;
    return true;
  }

  Future<String?> _refreshAccessToken() async {
    final existingRefresh = _refreshFuture;
    if (existingRefresh != null) {
      return existingRefresh;
    }

    final refreshFuture = _performRefresh();
    _refreshFuture = refreshFuture;

    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }
  }

  Future<String?> _performRefresh() async {
    final refreshToken = AuthManager.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final response = await dio.post(
      '/auth/mobile/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
    );

    final data = response.data;
    if (data is! Map) {
      return null;
    }
    final responseMap = Map<String, dynamic>.from(data);
    debugPrint("REFRESH TOKEN RESPONSE: $responseMap");

    final accessToken = responseMap['accessToken']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    await AuthManager.updateAccessToken(
      accessToken: accessToken,
      tokenType: responseMap['tokenType']?.toString(),
      kid: responseMap['kid']?.toString(),
      associatedNumber: responseMap['associatedNumber']?.toString(),
      departmentName: responseMap['departmentName']?.toString(),
    );

    return accessToken;
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String accessToken,
  ) async {
    final tokenType = AuthManager.tokenType ?? 'Bearer';
    final headers = Map<String, dynamic>.from(requestOptions.headers);

    if (requestOptions.extra['useRawBearer'] == true) {
      headers['Authorization'] = 'Bearer ${_extractRaw(accessToken)}';
    } else {
      headers['Authorization'] = '$tokenType $accessToken';
    }

    final extra = Map<String, dynamic>.from(requestOptions.extra);
    extra['retried'] = true;

    final retryOptions = requestOptions.copyWith(
      headers: headers,
      extra: extra,
    );

    return ApiClient.getDio(
      requestOptions.baseUrl,
    ).fetch<dynamic>(retryOptions);
  }

  static String _extractRaw(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ').trim();
    }
    return trimmed;
  }
}

// Caching dio instances based on the base URL
class ApiClient {
  static final Map<String, Dio> _dios = {};

  static Dio getDio(String baseUrl) {
    if (_dios.containsKey(baseUrl)) {
      return _dios[baseUrl]!;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );

    dio.interceptors.add(FirebasePerformanceInterceptor());
    dio.interceptors.add(AuthInterceptor());
    // dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true)); // un-comment for debugging

    _dios[baseUrl] = dio;
    return dio;
  }
}
