import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../Managers/AuthManager.dart';
import '../Services/app_tokens_service.dart';
import 'api_config.dart';
import 'api_client.dart';

class AttendanceApiService {

  static Future<Map<String, dynamic>> fetchLeaveSummary() async {
    return _executeWithRetry(
      endpoint: '/leave/summary',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get('/leave/summary', options: options),
    );
  }

  // Fetch today's live attendance status for initial button state
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

  static Future<Map<String, dynamic>> fetchWorkScheduleSummary({required String from, required String to}) async {
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
      ).get(
        '/attendance/summary/date/$date',
        options: options,
      ),
    );
  }

  static Future<Map<String, dynamic>> fetchAnnouncements() async {
    return _executeWithRetry(
      endpoint: '/announcements',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get('/announcements', options: options),
    );
  }

  static Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) async {
    return _executeWithRetry(
      endpoint: '/announcements',
      request: (options) => ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).post('/announcements', data: data, options: options),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Core: execute a request and retry once on 401 after refreshing
  // app tokens from /auth/mobile/apps/tokens.
  // ──────────────────────────────────────────────────────────────
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
          '[AttendanceApiService] $endpoint returned 401 — refreshing app tokens…',
        );
        try {
          // Re-fetch all app tokens (hits /auth/mobile/apps/tokens)
          await AppTokensService.syncInBackground(
            trigger: 'attendance_401_$endpoint',
          );

          // Rebuild headers with the fresh token and retry once
          final retryOptions = await _buildDaftarOptions();
          final retryResponse = await request(retryOptions);
          debugPrint(
            '[AttendanceApiService] $endpoint retry succeeded after token refresh.',
          );
          return _parseResponseData(retryResponse.data, endpoint);
        } on DioException catch (retryError) {
          debugPrint(
            '[AttendanceApiService] $endpoint retry failed: '
            '${retryError.response?.statusCode} - ${retryError.message}',
          );
          rethrow;
        } catch (retryError) {
          debugPrint(
            '[AttendanceApiService] $endpoint retry failed: $retryError',
          );
          rethrow;
        }
      }

      debugPrint(
        '[AttendanceApiService] $endpoint failed: '
        '${error.response?.statusCode} - ${error.message}',
      );
      rethrow;
    } catch (error) {
      debugPrint('[AttendanceApiService] $endpoint failed: $error');
      rethrow;
    }
  }

  static Map<String, dynamic> _parseResponseData(dynamic responseData, String endpointName) {
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
    var daftarToken = AuthManager.getAppToken(ApiConfig.daftarAppKey);
    final accessToken = AuthManager.accessToken;

    // Auto-fetch app token if missing (cold-start race condition)
    if (daftarToken == null || daftarToken.trim().isEmpty) {
      debugPrint(
        '[AttendanceApiService] Missing app token for ${ApiConfig.daftarAppKey} — fetching…',
      );
      await AppTokensService.syncInBackground(trigger: 'missing_daftar_token');
      daftarToken = AuthManager.getAppToken(ApiConfig.daftarAppKey);
    }

    final headers = <String, dynamic>{};

    if (daftarToken != null && daftarToken.isNotEmpty) {
      final normalizedToken = daftarToken.trim();
      headers['Authorization'] = 'Bearer $accessToken';
      headers['x-cc-app-token'] = normalizedToken;
      debugPrint(
        '[AttendanceApiService] Found ${ApiConfig.daftarAppKey} token in storage '
        '(len=${normalizedToken.length}, head=${_tokenHead(normalizedToken)}).',
      );
    } else {
      debugPrint(
        '[AttendanceApiService] Missing app token for ${ApiConfig.daftarAppKey} in secure storage.',
      );
    }

    return Options(
      headers: headers,
      extra: {
        'skipAuth': true,
        'skipRefresh': true,
      },
    );
  }

  static String _tokenHead(String token) {
    final headLength = token.length >= 8 ? 8 : token.length;
    return token.substring(0, headLength);
  }
}
