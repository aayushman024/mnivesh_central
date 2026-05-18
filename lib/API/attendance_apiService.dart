import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../Managers/AuthManager.dart';
import '../Services/app_tokens_service.dart';
import '../Services/bootstrap_service.dart';
import 'api_client.dart';
import 'api_config.dart';

class AttendanceApiService {
  static Future<Map<String, dynamic>> fetchLeaveSummary() async {
    return _executeWithRetry(
      endpoint: '/leave/summary',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get('/leave/summary', options: options),
    );
  }

  static Future<Map<String, dynamic>> fetchLiveAttendance() async {
    return _executeWithRetry(
      endpoint: '/attendance/liveAttendance',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get('/attendance/liveAttendance', options: options),
    );
  }

  static Future<Map<String, dynamic>> checkIn(Map<String, dynamic> data) async {
    return _executeWithRetry(
      endpoint: '/attendance/check-in',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).post('/attendance/check-in', data: data, options: options),
    );
  }

  static Future<Map<String, dynamic>> checkOut(Map<String, dynamic> data) async {
    return _executeWithRetry(
      endpoint: '/attendance/check-out',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).post('/attendance/check-out', data: data, options: options),
    );
  }

  static Future<Map<String, dynamic>> fetchWorkScheduleSummary({
    required String from,
    required String to,
  }) async {
    return _executeWithRetry(
      endpoint: '/attendance/summary/range',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get(
        '/attendance/summary/range',
        queryParameters: {'from': from, 'to': to},
        options: options,
      ),
    );
  }

  static Future<Map<String, dynamic>> fetchDailySummary(String date) async {
    return _executeWithRetry(
      endpoint: '/attendance/summary/date/$date',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get('/attendance/summary/date/$date', options: options),
    );
  }

  static Future<Map<String, dynamic>> _executeWithRetry({
    required String endpoint,
    required Future<Response<dynamic>> Function(Options options) request,
  }) async {
    try {
      final options = await _buildDaftarOptions();
      final response = await request(options);
      return _parseResponseData(response.data, endpoint);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        debugPrint(
          '[AttendanceApiService] $endpoint returned 401, refreshing app tokens...',
        );
        await AppTokensService.syncInBackground(
          trigger: 'attendance_401_$endpoint',
        );

        final retryOptions = await _buildDaftarOptions();
        final retryResponse = await request(retryOptions);
        return _parseResponseData(retryResponse.data, endpoint);
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _parseResponseData(
    dynamic responseData,
    String endpointName,
  ) {
    if (responseData is Map<String, dynamic>) {
      debugPrint('[AttendanceApiService] $endpointName: $responseData');
      return responseData;
    }
    if (responseData is Map) {
      final mapped = Map<String, dynamic>.from(responseData);
      debugPrint('[AttendanceApiService] $endpointName: $mapped');
      return mapped;
    }

    final fallback = {'data': responseData};
    debugPrint('[AttendanceApiService] $endpointName: $fallback');
    return fallback;
  }

  static Future<Options> _buildDaftarOptions() async {
    await BootstrapService.ready;

    var daftarToken = AuthManager.getAppToken(ApiConfig.daftarAppKey);
    final accessToken = AuthManager.accessToken;

    if (daftarToken == null || daftarToken.trim().isEmpty) {
      await AppTokensService.syncInBackground(trigger: 'missing_daftar_token');
      daftarToken = AuthManager.getAppToken(ApiConfig.daftarAppKey);
    }

    final headers = <String, dynamic>{};
    if (daftarToken != null && daftarToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
      headers['x-cc-app-token'] = daftarToken.trim();
    }

    return Options(
      headers: headers,
      extra: {'skipAuth': true, 'skipRefresh': true},
    );
  }
}
