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

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        debugPrint('[AttendanceApiService] /leave/summary: $responseData');
        return responseData;
      }
      if (responseData is Map) {
        final mapped = Map<String, dynamic>.from(responseData);
        debugPrint('[AttendanceApiService] /leave/summary: $mapped');
        return mapped;
      }

      final fallback = {'data': responseData};
      debugPrint('[AttendanceApiService] /leave/summary: $fallback');
      return fallback;
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

  static Future<Options> _buildDaftarOptions() async {
    final daftarToken = await AuthManager.getAppBackendToken(
      ApiConfig.daftarAppKey,
    );
    final headers = <String, dynamic>{};

    if (daftarToken != null && daftarToken.isNotEmpty) {
      final normalizedToken = daftarToken.trim();
      headers['Authorization'] = 'Bearer $normalizedToken';
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
        // Use app-key token instead of central access token for Daftar APIs.
        'skipAuth': true,
        // Daftar backend has separate auth flow; don't trigger central refresh flow.
        'skipRefresh': true,
      },
    );
  }

  static String _tokenHead(String token) {
    final headLength = token.length >= 8 ? 8 : token.length;
    return token.substring(0, headLength);
  }
}
