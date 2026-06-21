import 'package:dio/dio.dart';
import 'package:mnivesh_central/core/api/api_config.dart';
import 'package:mnivesh_central/core/api/api_client.dart';

class CallynApiService {
  static Future<Map<String, dynamic>> fetchCallLogAnalytics({
    String? fromDate,
    String? toDate,
    String? name,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (fromDate != null) {
        queryParams['from'] = fromDate; // format: YYYY-MM-DD
      }
      if (toDate != null) {
        queryParams['to'] = toDate;
      }
      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final response = await ApiClient.getDio(ApiConfig.callynAnalyticsBaseUrl)
          .get(
            '/getCallLogAnalytics',
            queryParameters: queryParams.isNotEmpty ? queryParams : null,
          );

      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch call log analytics: ${e.message}');
    } catch (e) {
      throw Exception('Error processing analytics data: $e');
    }
  }

  static Future<List<dynamic>> fetchWhitelistStats() async {
    try {
      final response = await ApiClient.getDio(ApiConfig.callynAnalyticsBaseUrl)
          .get('/whitelist/stats');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch whitelist stats: ${e.message}');
    } catch (e) {
      throw Exception('Error processing whitelist stats: $e');
    }
  }
}

