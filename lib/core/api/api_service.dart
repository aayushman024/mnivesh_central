import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'dart:typed_data';
import 'package:mnivesh_central/features/app_store/models/app_model.dart';
import 'package:mnivesh_central/features/investwell_report/models/investwell_report_models.dart';
import 'package:mnivesh_central/features/team_status/models/user_details_model.dart';
import 'package:mnivesh_central/core/services/bootstrap_service.dart';
import 'package:mnivesh_central/core/api/api_config.dart';
import 'package:mnivesh_central/core/api/api_client.dart';

class ApiService {
  Future<List<AppModel>> fetchApps() async {
    await BootstrapService.ready;
    try {
      final response = await ApiClient.getDio(
        ApiConfig.defaultBaseUrl,
      ).get('/api/apps');

      final List<dynamic> data = response.data;
      return data.map((json) => AppModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load apps: ${e.message}');
    } catch (e) {
      throw Exception('Error processing apps data: $e');
    }
  }

  static Future<void> postUserDetails(Map<String, dynamic> data) async {
    await BootstrapService.ready;
    try {
      await ApiClient.getDio(
        ApiConfig.defaultBaseUrl,
      ).post('/api/users', data: data);
    } on DioException catch (e) {
      throw Exception(
        'Failed to sync user details: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      throw Exception('Error posting user details: $e');
    }
  }

  static Future<List<UserDetail>> getUserDetails() async {
    await BootstrapService.ready;
    try {
      final response = await ApiClient.getDio(
        ApiConfig.defaultBaseUrl,
      ).get('/api/users');

      List data = response.data;
      return data.map((user) => UserDetail.fromJson(user)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch team details: ${e.message}');
    } catch (e) {
      throw Exception('Error parsing team details: $e');
    }
  }

  static Future<String?> getZohoAuthUrl() async {
    try {
      final response = await ApiClient.getDio(ApiConfig.defaultBaseUrl).get(
        '/auth/zoho',
        queryParameters: {
          'appKey': ApiConfig.centralAppKey,
          'redirect': ApiConfig.mobileRedirectUri,
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

  static Future<Map<String, String>> getMobileAppTokens() async {
    try {
      final response = await ApiClient.getDio(
        ApiConfig.defaultBaseUrl,
      ).get('/auth/mobile/apps/tokens');
      final data = response.data;

      if (data is! Map) {
        throw Exception('Unexpected app tokens response format.');
      }

      final tokens = <String, String>{};
      for (final entry in Map<String, dynamic>.from(data).entries) {
        final appKey = entry.key.trim();
        final token = entry.value?.toString().trim();

        if (appKey.isEmpty || token == null || token.isEmpty) {
          continue;
        }

        tokens[appKey] = token;
      }

      return tokens;
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch mobile app tokens: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      throw Exception('Error processing mobile app tokens: $e');
    }
  }

  static Future<void> registerFcmToken(String fcmToken) async {
    await BootstrapService.ready;
    try {
      await ApiClient.getDio(
        ApiConfig.defaultBaseUrl,
      ).post('/api/notifications/register-token', data: {'fcmToken': fcmToken});
      debugPrint('FCM token registered successfully');
    } on DioException catch (e) {
      debugPrint(
        'Failed to register FCM token: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchActiveAnnouncements() async {
    await BootstrapService.ready;
    try {
      final response = await ApiClient.getDio(
        ApiConfig.defaultBaseUrl,
      ).get('/api/notifications/activeNotifications');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'notifications': response.data};
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch active announcements: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      throw Exception('Error fetching active announcements: $e');
    }
  }

  static Future<Map<String, dynamic>> createAnnouncement(
    Map<String, dynamic> payload,
  ) async {
    await BootstrapService.ready;
    try {
      final response = await ApiClient.getDio(
        ApiConfig.defaultBaseUrl,
      ).post('/api/notifications/send', data: payload);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'data': response.data};
    } on DioException catch (e) {
      throw Exception(
        'Failed to create announcement: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      throw Exception('Error creating announcement: $e');
    }
  }

  static Future<InvestwellReportFile> fetchInvestwellReport(
    InvestwellReportRequest request,
  ) async {
    await BootstrapService.ready;

    final normalizedPan = request.pan.trim().toUpperCase();
    if (normalizedPan.isEmpty) {
      throw Exception('PAN is required.');
    }
    if (request.type == InvestwellReportType.capitalGain &&
        request.year == null) {
      throw Exception('Year is required for Capital Gain report.');
    }

    final endpoint = request.type == InvestwellReportType.capitalGain
        ? '/api/investwell/capital-gain'
        : '/api/investwell/portfolio';

    final query = <String, dynamic>{'pan': normalizedPan};
    if (request.type == InvestwellReportType.capitalGain) {
      query['year'] = request.year;
    }

    try {
      final response = await ApiClient.getDio(ApiConfig.defaultBaseUrl).get(
        endpoint,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );

      final rawData = response.data;
      final bytes = rawData is List<int>
          ? rawData
          : (rawData is Uint8List ? rawData : <int>[]);
      if (bytes.isEmpty) {
        throw Exception('Empty report response.');
      }

      final headers = response.headers.map;
      final contentType = headers['content-type']?.first ?? 'application/pdf';
      final disposition = headers['content-disposition']?.first ?? '';
      final fileName =
          _extractFilename(disposition) ??
          (request.type == InvestwellReportType.capitalGain
              ? 'Capital_Gain_${normalizedPan}_${request.year}.pdf'
              : 'Portfolio_$normalizedPan.pdf');

      return InvestwellReportFile(
        type: request.type,
        bytes: Uint8List.fromList(bytes),
        contentType: contentType,
        fileName: fileName,
        pan: normalizedPan,
        year: request.year,
      );
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch report: ${e.response?.statusCode ?? ''} ${e.message ?? ''}',
      );
    } catch (e) {
      throw Exception('Error fetching report: $e');
    }
  }

  static String? _extractFilename(String contentDisposition) {
    final match = RegExp(
      r'filename="?([^"]+)"?',
    ).firstMatch(contentDisposition);
    return match?.group(1);
  }

  static Future<List<dynamic>> searchMintDbGraphQL(
    InvestwellInvestorSearchRequest request,
  ) async {
    await BootstrapService.ready;
    final normalizedSearchQuery = request.searchQuery.trim();
    if (normalizedSearchQuery.isEmpty) {
      return [];
    }

    try {
      final response = await ApiClient.getDio(
        ApiConfig.defaultBaseUrl,
      ).post('/graphql', data: request.toJson());

      final data = response.data;
      if (data != null && data is Map) {
        if (data.containsKey('errors')) {
          throw Exception('GraphQL errors: ${data['errors']}');
        }
        final result = data['data']?['searchMintDb'];
        if (result is List) {
          return result;
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        'Failed to execute GraphQL search: ${e.response?.statusCode ?? ''} ${e.message ?? ''}',
      );
    } catch (e) {
      throw Exception('Error processing GraphQL search: $e');
    }
  }
}
