import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../Managers/AuthManager.dart';
import '../Models/modules_analytics_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class AnalyticsApiService {
  static Future<void> logModuleTap(String moduleName) async {
    final normalizedModuleName = moduleName.trim();
    if (normalizedModuleName.isEmpty) {
      return;
    }

    final email = await AuthManager.getUserEmail();
    final normalizedEmail = email?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      debugPrint(
        '[AnalyticsApiService] Skipping module tap log for "$normalizedModuleName" because user email is unavailable.',
      );
      return;
    }

    try {
      await ApiClient.getDio(ApiConfig.defaultBaseUrl).post(
        '/api/analytics/module-tap',
        data: {'moduleName': normalizedModuleName, 'email': normalizedEmail},
      );
    } on DioException catch (error) {
      debugPrint(
        '[AnalyticsApiService] Failed to log module tap for "$normalizedModuleName": '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
    } catch (error) {
      debugPrint(
        '[AnalyticsApiService] Failed to log module tap for "$normalizedModuleName": $error',
      );
    }
  }

  static Future<List<ModuleTapSummaryRecord>> getModuleTapsSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? moduleName,
  }) async {
    try {
      final response = await ApiClient.getDio(ApiConfig.defaultBaseUrl).get(
        '/api/analytics/module-taps',
        queryParameters: {
          if (startDate != null) 'startDate': _toDateParam(startDate),
          if (endDate != null) 'endDate': _toDateParam(endDate),
          if (moduleName != null && moduleName.trim().isNotEmpty)
            'moduleName': moduleName.trim(),
        },
      );

      final payload = _asMap(response.data);
      final data = payload['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map>()
          .map(
            (item) => ModuleTapSummaryRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.moduleName.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw Exception(
        'Failed to fetch module tap summary: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
    } catch (error) {
      throw Exception('Failed to fetch module tap summary: $error');
    }
  }

  static Future<List<ModuleUserAccessRecord>> getRecentModuleUsers(
    String moduleName, {
    int? hours,
  }) async {
    final normalizedModuleName = moduleName.trim();
    if (normalizedModuleName.isEmpty) {
      return const [];
    }

    try {
      final response = await ApiClient.getDio(ApiConfig.defaultBaseUrl).get(
        '/api/analytics/module-users/$normalizedModuleName',
        queryParameters: {if (hours != null && hours > 0) 'hours': hours},
      );

      final payload = _asMap(response.data);
      final data = payload['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map>()
          .map(
            (item) => ModuleUserAccessRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.email.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw Exception(
        'Failed to fetch module users: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
    } catch (error) {
      throw Exception('Failed to fetch module users: $error');
    }
  }

  static String _toDateParam(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}
