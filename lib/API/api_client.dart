import 'package:dio/dio.dart';
import 'api_config.dart';
import '../Managers/AuthManager.dart';
import '../Services/FirebasePerformanceNetworkInterceptor.dart';

// Inject token and handle 401s globally
class AuthInterceptor extends Interceptor {
  static Future<String?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    final token = await AuthManager.getAccessToken();
    final tokenType = await AuthManager.getTokenType() ?? 'Bearer';

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = '$tokenType $token';
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

    try {
      final refreshedToken = await _refreshAccessToken();
      if (refreshedToken == null) {
        await AuthManager.logout();
        handler.next(err);
        return;
      }

      final retryResponse = await _retryRequest(
        err.requestOptions,
        refreshedToken,
      );
      handler.resolve(retryResponse);
    } on DioException catch (refreshError) {
      final statusCode = refreshError.response?.statusCode;
      if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
        await AuthManager.logout();
      }
      handler.next(err);
    } catch (_) {
      handler.next(err);
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
    final refreshToken = await AuthManager.getRefreshToken();
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
    final tokenType = await AuthManager.getTokenType() ?? 'Bearer';
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = '$tokenType $accessToken';

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
