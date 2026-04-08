import 'package:dio/dio.dart';
import '../Models/appModel.dart';
import '../Models/userDetailsModel.dart';
import 'api_client.dart';

class ApiService {
  static const String localBaseUrl = "http://localhost:5500";
  static const String prodBaseUrl = "https://app-store-dqg8bnf4d8cberf7.centralindia-01.azurewebsites.net";
  static const String appKey = "MNIVESH_CENTRAL";
  static const String mobileRedirectUri = "mniveshcentral://auth/callback";

  // Default backend currently in use
  static const String defaultBaseUrl = localBaseUrl;

  Future<List<AppModel>> fetchApps() async {
    try {
      final response = await ApiClient.getDio(defaultBaseUrl).get('/api/apps');

      final List<dynamic> data = response.data;
      return data.map((json) => AppModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load apps: ${e.message}');
    } catch (e) {
      throw Exception('Error processing apps data: $e');
    }
  }

  static Future<void> postUserDetails(Map<String, dynamic> data) async {
    try {
      await ApiClient.getDio(defaultBaseUrl).post(
        '/api/users',
        data: data,
      );
    } on DioException catch (e) {
      throw Exception('Failed to sync user details: ${e.response?.statusCode} - ${e.message}');
    } catch (e) {
      throw Exception('Error posting user details: $e');
    }
  }

  static Future<List<UserDetail>> getUserDetails() async {
    try {
      final response = await ApiClient.getDio(defaultBaseUrl).get('/api/users');

      List data = response.data;
      return data.map((user) => UserDetail.fromJson(user)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch team details: ${e.message}');
    } catch (e) {
      throw Exception('Error parsing team details: $e');
    }
  }

  // static Future<String?> getZohoAuthUrl() async {
  //   try {
  //     final response = await ApiClient.getDio(defaultBaseUrl).get('/auth/zoho');
  //     return response.data['authUrl'];
  //   } on DioException catch (e) {
  //     throw Exception('Error fetching Zoho auth URL: ${e.message}');
  //   } catch (e) {
  //     throw Exception('Error processing Zoho response: $e');
  //   }
  // }

  static Future<String?> getZohoAuthUrl() async {
    try {
      final response = await ApiClient.getDio(defaultBaseUrl).get(
        '/auth/zoho',
        queryParameters: {
          'appKey': appKey,
          'redirect': mobileRedirectUri,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return response.data['authUrl']?.toString();
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data)['authUrl']?.toString();
      }
      return null;
    } on DioException catch (e) {
      throw Exception('Error fetching Zoho auth URL: ${e.message}');
    } catch (e) {
      throw Exception('Error processing Zoho auth URL: $e');
    }
  }


  static Future<String?> getMe() async {
    try {
      final response = await ApiClient.getDio(defaultBaseUrl).get('/auth/me');
      return response.data['name'];
    } on DioException catch (e) {
      throw Exception('Error fetching user info: ${e.message}');
    } catch (e) {
      throw Exception('Error parsing user info: $e');
    }
  }
}

