import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../Managers/AuthManager.dart';
import '../Models/mftrans_models.dart';
import 'api_config.dart';
import 'api_client.dart';

class OperationsApiService {
  static Future<List<String>> searchAmcNames(String keywords) async {
    final normalizedKeywords = keywords.trim();
    if (normalizedKeywords.isEmpty) {
      return const [];
    }

    try {
      final response = await ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/amc',
        queryParameters: {'keywords': normalizedKeywords},
        options: await _buildOpsOptions(),
      );

      final list = _extractList(response.data);
      final amcNames = list
          .map((item) => item['FUND NAME']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      debugPrint('[OperationsApiService] /api/data/amc -> ${amcNames.length}');
      return amcNames;
    } on DioException catch (error) {
      debugPrint(
        '[OperationsApiService] /api/data/amc failed: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      rethrow;
    }
  }

  static Future<List<String>> searchSchemeNames({
    required String amc,
    required String keywords,
  }) async {
    final normalizedAmc = amc.trim();
    final normalizedKeywords = keywords.trim();
    if (normalizedAmc.isEmpty || normalizedKeywords.isEmpty) {
      return const [];
    }

    try {
      final response = await ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/schemename',
        queryParameters: {'amc': normalizedAmc, 'keywords': normalizedKeywords},
        options: await _buildOpsOptions(),
      );

      final list = _extractList(response.data);
      final schemeNames = list
          .map((item) => _normalizeSchemeName(item['scheme_name']))
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      debugPrint(
        '[OperationsApiService] /api/data/schemename -> ${schemeNames.length}',
      );
      return schemeNames;
    } on DioException catch (error) {
      debugPrint(
        '[OperationsApiService] /api/data/schemename failed: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      rethrow;
    }
  }

  static Future<List<String>> fetchFolioOptions({
    required String iWellCode,
    required String amcName,
  }) async {
    final normalizedIwell = iWellCode.trim();
    final normalizedAmc = amcName.trim();
    if (normalizedIwell.isEmpty || normalizedAmc.isEmpty) {
      return const [];
    }

    try {
      final response = await ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/folios',
        queryParameters: {'iwell': normalizedIwell, 'amcName': normalizedAmc},
        options: await _buildOpsOptions(),
      );

      final list = _extractList(response.data);
      final folios = list
          .map((item) => item['FOLIO NO']?.toString().trim() ?? '')
          .where((folio) => folio.isNotEmpty)
          .toSet()
          .toList();

      debugPrint('[OperationsApiService] /api/data/folios -> ${folios.length}');
      return folios;
    } on DioException catch (error) {
      debugPrint(
        '[OperationsApiService] /api/data/folios failed: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      rethrow;
    }
  }

  static Future<List<InvestorModel>> searchInvestors({
    String? name,
    String? pan,
    String? familyHead,
    bool searchAll = true,
  }) async {
    final normalizedName = name?.trim();
    final normalizedPan = pan?.trim();
    final normalizedFamilyHead = familyHead?.trim();

    if ((normalizedName == null || normalizedName.isEmpty) &&
        (normalizedPan == null || normalizedPan.isEmpty) &&
        (normalizedFamilyHead == null || normalizedFamilyHead.isEmpty)) {
      return const [];
    }

    final query = <String, dynamic>{'searchall': searchAll};
    if (normalizedName != null && normalizedName.isNotEmpty) {
      query['name'] = normalizedName;
    } else if (normalizedPan != null && normalizedPan.isNotEmpty) {
      query['pan'] = normalizedPan;
    } else if (normalizedFamilyHead != null &&
        normalizedFamilyHead.isNotEmpty) {
      query['fh'] = normalizedFamilyHead;
    }

    try {
      final response = await ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/investors',
        queryParameters: query,
        options: await _buildOpsOptions(),
      );

      final list = _extractList(response.data);
      final investors = list
          .map((item) => InvestorModel.fromJson(item))
          .where(
            (item) =>
                item.name.isNotEmpty ||
                item.pan.isNotEmpty ||
                item.familyHead.isNotEmpty,
          )
          .toList();

      debugPrint(
        '[OperationsApiService] /api/data/investors (${query.keys.join(',')}) -> ${investors.length}',
      );
      return investors;
    } on DioException catch (error) {
      debugPrint(
        '[OperationsApiService] /api/data/investors failed: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      rethrow;
    }
  }

  static Future<List<UccModel>> fetchUccByPan(String pan) async {
    final normalizedPan = pan.trim().toUpperCase();
    if (normalizedPan.isEmpty) {
      return const [];
    }

    try {
      final response = await ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/ucc',
        queryParameters: {'pan': normalizedPan},
        options: await _buildOpsOptions(),
      );

      final payload = response.data;
      final list = payload is Map
          ? _extractList(Map<String, dynamic>.from(payload)['data'])
          : _extractList(payload);
      final uccData = list
          .map((item) => UccModel.fromBackendJson(item))
          .where((item) => item.id.isNotEmpty)
          .toList();

      debugPrint('[OperationsApiService] /api/data/ucc -> ${uccData.length}');
      return uccData;
    } on DioException catch (error) {
      debugPrint(
        '[OperationsApiService] /api/data/ucc failed: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      rethrow;
    }
  }

  static Future<UccKycStatus> fetchKycStatus(String pan) async {
    final normalizedPan = pan.trim().toUpperCase();
    if (normalizedPan.isEmpty) {
      return UccKycStatus.checking;
    }

    try {
      final options = await _buildOpsOptions();
      final response = await ApiClient.getDio(ApiConfig.operationsBaseUrl).post(
        '/api/data/kycstatuscheck',
        data: {'Pan': normalizedPan, 'detailCheck': 'N', 'detailedOutput': 'N'},
        options: options,
      );

      final data = response.data;
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      map['Status'] = map['Status'] ?? data;
      final status = UccModel.parseKycStatus(map);

      debugPrint(
        '[OperationsApiService] /api/data/kycstatuscheck ($normalizedPan) -> ${map['Status']}',
      );
      return status;
    } on DioException catch (error) {
      debugPrint(
        '[OperationsApiService] /api/data/kycstatuscheck failed for $normalizedPan: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      return UccKycStatus.checking;
    }
  }

  /// Quick debug call for MF Trans data flow verification.
  static Future<void> debugFetchInvestors() async {
    try {
      final investors = await searchInvestors(name: 'A', searchAll: true);
      debugPrint('[OperationsApiService] debug investors: $investors');
    } catch (error) {
      debugPrint('[OperationsApiService] debugFetchInvestors failed: $error');
    }
  }

  static Future<Options> _buildOpsOptions() async {
    final appToken = await AuthManager.getAppBackendToken(
      ApiConfig.operationsAppKey,
    );
    final accessToken = await AuthManager.getAccessToken();
    final tokenType = (await AuthManager.getTokenType()) ?? 'Bearer';

    if (appToken == null || appToken.trim().isEmpty) {
      throw StateError(
        'Missing ${ApiConfig.operationsAppKey} app token in secure storage.',
      );
    }
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError('Missing mobile access token for operations API.');
    }

    final rawAccessToken = _extractRawAccessToken(accessToken);
    if (rawAccessToken.isEmpty) {
      throw StateError('Invalid mobile access token for operations API.');
    }

    if (tokenType.trim().toLowerCase() != 'bearer') {
      debugPrint(
        '[OperationsApiService] Ignoring tokenType="$tokenType" and forcing Bearer scheme for OPS mobile auth.',
      );
    }

    return Options(
      headers: {
        'Authorization': 'Bearer $rawAccessToken',
        'x-cc-app-token': appToken.trim(),
      },
      extra: {
        // Authorization is explicitly set above.
        'skipAuth': true,
        // Allow interceptor refresh flow on 401 for potentially expired token.
        'skipRefresh': false,
      },
    );
  }

  static List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _extractRawAccessToken(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  static String _normalizeSchemeName(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    if (raw.endsWith(' (G)')) {
      return raw.substring(0, raw.length - 4).trimRight();
    }
    return raw;
  }
}
