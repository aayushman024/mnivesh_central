import 'package:dio/dio.dart';
import '../Managers/AuthManager.dart';

// Inject token and handle 401s globally
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthManager.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // logout if token is invalid/expired
      AuthManager.logout();
    }
    return super.onError(err, handler);
  }
}

// Caching dio instances based on the base URL
class ApiClient {
  static final Map<String, Dio> _dios = {};

  static Dio getDio(String baseUrl) {
    if (_dios.containsKey(baseUrl)) {
      return _dios[baseUrl]!;
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(AuthInterceptor());
    // dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true)); // un-comment for debugging

    _dios[baseUrl] = dio;
    return dio;
  }
}