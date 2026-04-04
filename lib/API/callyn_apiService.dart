import 'package:dio/dio.dart';
import 'api_client.dart';

class CallynApiService {

  static const String analyticsBaseUrl = "http://192.168.1.59:5000";

  static Future<Map<String, dynamic>> fetchCallLogAnalytics({String? fromDate, String? toDate, String? name}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (fromDate != null) queryParams['from'] = fromDate; // format: YYYY-MM-DD
      if (toDate != null) queryParams['to'] = toDate;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;

      final response = await ApiClient.getDio(analyticsBaseUrl).get(
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
}