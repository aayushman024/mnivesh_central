import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/appModel.dart';
import '../Models/userDetailsModel.dart';

class ApiService {

  static const String localBaseUrl = "http://localhost:5500";
  static const String ipBaseUrl = "http://192.168.1.78:5500";
  static const String prodBaseUrl = "https://app-store-dqg8bnf4d8cberf7.centralindia-01.azurewebsites.net";

  static const String baseUrl = prodBaseUrl;

  // Passing token through to get protected apps
  Future<List<AppModel>> fetchApps(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/apps'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AppModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load apps: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // Syncing user details, now auth protected
  static Future<void> postUserDetails(Map<String, dynamic> data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to sync user details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error posting user details: $e');
    }
  }

  // Already taking token, just keeping it consistent
  static Future<List<UserDetail>> getUserDetails(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((user) => UserDetail.fromJson(user)).toList();
    } else {
      throw Exception('Failed to fetch team details');
    }
  }

  // Needed token here too for the Zoho endpoint
  static Future<String?> getZohoAuthUrl() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/zoho'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['authUrl'];
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching Zoho auth URL: $e');
    }
  }

  // Validate token and get user info
  static Future<String?> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name'];
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user info: $e');
    }
  }
}