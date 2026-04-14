import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../Managers/AuthManager.dart';
import 'api_config.dart';
import 'api_client.dart';

class AttendanceApiService {
  static Future<Map<String, dynamic>> fetchLeaveSummary() async {
    try {
      final response = await ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get('/leave/summary', options: await _buildDaftarOptions());

      return _parseResponseData(response.data, '/leave/summary');
    } on DioException catch (error) {
      debugPrint(
        '[AttendanceApiService] /leave/summary failed: '
        '${error.response?.statusCode} - ${error.message}',
      );
      rethrow;
    } catch (error) {
      debugPrint('[AttendanceApiService] /leave/summary failed: $error');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> checkIn(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).post('/attendance/check-in', data: data, options: await _buildDaftarOptions());

      return _parseResponseData(response.data, '/attendance/check-in');
    } on DioException catch (error) {
      debugPrint('[AttendanceApiService] /attendance/check-in failed: ${error.response?.statusCode} - ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('[AttendanceApiService] /attendance/check-in failed: $error');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> checkOut(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).post('/attendance/check-out', data: data, options: await _buildDaftarOptions());

      return _parseResponseData(response.data, '/attendance/check-out');
    } on DioException catch (error) {
      debugPrint('[AttendanceApiService] /attendance/check-out failed: ${error.response?.statusCode} - ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('[AttendanceApiService] /attendance/check-out failed: $error');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchWorkScheduleSummary({required String from, required String to}) async {
    try {
      final response = await ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get(
        '/attendance/summary/range',
        queryParameters: {'from': from, 'to': to},
        options: await _buildDaftarOptions(),
      );

      return _parseResponseData(response.data, '/attendance/summary/range');
    } on DioException catch (error) {
      debugPrint('[AttendanceApiService] /attendance/summary/range failed: ${error.response?.statusCode} - ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('[AttendanceApiService] /attendance/summary/range failed: $error');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchDailySummary(String date) async {
    try {
      final response = await ApiClient.getDio(
        ApiConfig.attendanceBaseUrl,
      ).get(
        '/attendance/summary/date/$date',
        options: await _buildDaftarOptions(),
      );

      return _parseResponseData(response.data, '/attendance/summary/date/$date');
    } on DioException catch (error) {
      debugPrint('[AttendanceApiService] /attendance/summary/date/$date failed: ${error.response?.statusCode} - ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('[AttendanceApiService] /attendance/summary/date/$date failed: $error');
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
    final accessToken = await AuthManager.getAccessToken();
    final daftarToken = await AuthManager.getAppBackendToken(
      ApiConfig.daftarAppKey,
    );
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
