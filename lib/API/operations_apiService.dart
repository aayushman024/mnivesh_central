import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../Managers/AuthManager.dart';
import '../Models/mftrans_models.dart';
import '../Services/app_tokens_service.dart';
import 'api_config.dart';
import 'api_client.dart';

class OperationsApiService {
  static Future<List<String>> searchAmcNames(String keywords) async {
    final normalizedKeywords = keywords.trim();
    if (normalizedKeywords.isEmpty) {
      return const [];
    }

    return _executeWithRetry(
      endpoint: '/api/data/amc',
      request: (options) => ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/amc',
        queryParameters: {'keywords': normalizedKeywords},
        options: options,
      ),
      transform: (response) {
        final list = _extractList(response.data);
        return list
            .map((item) => item['FUND NAME']?.toString().trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();
      },
    );
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

    return _executeWithRetry(
      endpoint: '/api/data/schemename',
      request: (options) => ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/schemename',
        queryParameters: {'amc': normalizedAmc, 'keywords': normalizedKeywords},
        options: options,
      ),
      transform: (response) {
        final list = _extractList(response.data);
        return list
            .map((item) => _normalizeSchemeName(item['scheme_name']))
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();
      },
    );
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

    return _executeWithRetry(
      endpoint: '/api/data/folios',
      request: (options) => ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/folios',
        queryParameters: {'iwell': normalizedIwell, 'amcName': normalizedAmc},
        options: options,
      ),
      transform: (response) {
        final list = _extractList(response.data);
        return list
            .map((item) => item['FOLIO NO']?.toString().trim() ?? '')
            .where((folio) => folio.isNotEmpty)
            .toSet()
            .toList();
      },
    );
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

    return _executeWithRetry(
      endpoint: '/api/data/investors',
      request: (options) => ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/investors',
        queryParameters: query,
        options: options,
      ),
      transform: (response) {
        final list = _extractList(response.data);
        return list
            .map((item) => InvestorModel.fromJson(item))
            .where(
              (item) =>
                  item.name.isNotEmpty ||
                  item.pan.isNotEmpty ||
                  item.familyHead.isNotEmpty,
            )
            .toList();
      },
    );
  }

  static Future<List<UccModel>> fetchUccByPan(String pan) async {
    final normalizedPan = pan.trim().toUpperCase();
    if (normalizedPan.isEmpty) {
      return const [];
    }

    return _executeWithRetry(
      endpoint: '/api/data/ucc',
      request: (options) => ApiClient.getDio(ApiConfig.operationsBaseUrl).get(
        '/api/data/ucc',
        queryParameters: {'pan': normalizedPan},
        options: options,
      ),
      transform: (response) {
        final payload = response.data;
        final list = payload is Map
            ? _extractList(Map<String, dynamic>.from(payload)['data'])
            : _extractList(payload);
        return list
            .map((item) => UccModel.fromBackendJson(item))
            .where((item) => item.id.isNotEmpty)
            .toList();
      },
    );
  }

  static Future<UccKycStatus> fetchKycStatus(String pan) async {
    final normalizedPan = pan.trim().toUpperCase();
    if (normalizedPan.isEmpty) {
      return UccKycStatus.checking;
    }

    return _executeWithRetry(
      endpoint: '/api/data/kycstatuscheck',
      request: (options) => ApiClient.getDio(ApiConfig.operationsBaseUrl).post(
        '/api/data/kycstatuscheck',
        data: {'Pan': normalizedPan, 'detailCheck': 'N', 'detailedOutput': 'N'},
        options: options,
      ),
      transform: (response) {
        final data = response.data;
        final map = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        map['Status'] = map['Status'] ?? data;
        return UccModel.parseKycStatus(map);
      },
      fallbackOn401Failure: UccKycStatus.checking,
    );
  }

  //post form
  static Future<Map<String, dynamic>> submitMfTransactions(Map<String, dynamic> formData) async {
    final isLoggedIn = await AuthManager.isLoggedIn();
    final accessToken = await AuthManager.getAccessToken();
    
    if (!isLoggedIn || accessToken == null || accessToken.isEmpty) {
      throw Exception('user not logged in');
    }

    return _executeWithRetry(
      endpoint: '/api/data',
      request: (options) => ApiClient.getDio(ApiConfig.operationsBaseUrl).post(
        '/api/data',
        data: {'formData': formData},
        options: options,
      ),
      transform: (response) {
        final data = response.data;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return <String, dynamic>{};
      },
      rethrowAs: (error) {
        if (error is StateError) {
          return Exception('user not logged in');
        }
        if (error is DioException) {
          final errorMessage = error.response?.data is Map
              ? error.response?.data['message'] ?? error.response?.data['error']
              : 'Server error! Try again later.';
          return Exception(errorMessage);
        }
        return null;
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Core: execute a request and retry once on 401 after refreshing
  // app tokens from /auth/mobile/apps/tokens.
  // ──────────────────────────────────────────────────────────────
  static Future<T> _executeWithRetry<T>({
    required String endpoint,
    required Future<Response<dynamic>> Function(Options options) request,
    required T Function(Response<dynamic> response) transform,
    T? fallbackOn401Failure,
    Exception? Function(Object error)? rethrowAs,
  }) async {
    try {
      final options = await _buildOpsOptions();
      final response = await request(options);
      final result = transform(response);
      debugPrint('[OperationsApiService] $endpoint -> $result');
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        debugPrint(
          '[OperationsApiService] $endpoint returned 401 — refreshing app tokens…',
        );
        try {
          // Re-fetch all app tokens (hits /auth/mobile/apps/tokens)
          await AppTokensService.syncInBackground(
            trigger: 'ops_401_$endpoint',
          );

          // Rebuild headers with the fresh token and retry once
          final retryOptions = await _buildOpsOptions();
          final retryResponse = await request(retryOptions);
          final result = transform(retryResponse);
          debugPrint(
            '[OperationsApiService] $endpoint retry succeeded after token refresh.',
          );
          return result;
        } catch (retryError) {
          debugPrint(
            '[OperationsApiService] $endpoint retry failed: $retryError',
          );
          if (fallbackOn401Failure != null) return fallbackOn401Failure;
          if (rethrowAs != null) {
            final mapped = rethrowAs(retryError);
            if (mapped != null) throw mapped;
          }
          rethrow;
        }
      }

      debugPrint(
        '[OperationsApiService] $endpoint failed: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      if (rethrowAs != null) {
        final mapped = rethrowAs(error);
        if (mapped != null) throw mapped;
      }
      rethrow;
    } on StateError catch (error) {
      debugPrint('[OperationsApiService] $endpoint state error: ${error.message}');
      if (rethrowAs != null) {
        final mapped = rethrowAs(error);
        if (mapped != null) throw mapped;
      }
      rethrow;
    } catch (error) {
      debugPrint('[OperationsApiService] $endpoint failed: $error');
      rethrow;
    }
  }

  static Future<Options> _buildOpsOptions() async {
    var appToken = await AuthManager.getAppBackendToken(
      ApiConfig.operationsAppKey,
    );
    final accessToken = await AuthManager.getAccessToken();

    // Auto-fetch app token if missing (cold-start race condition)
    if (appToken == null || appToken.trim().isEmpty) {
      await AppTokensService.syncInBackground(trigger: 'missing_ops_token');
      appToken = await AuthManager.getAppBackendToken(
        ApiConfig.operationsAppKey,
      );
    }

    if (appToken == null || appToken.trim().isEmpty) {
      throw StateError(
        'Missing ${ApiConfig.operationsAppKey} app token in secure storage.',
      );
    }
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError('Missing mobile access token for operations API.');
    }

    return Options(
      headers: {
        'x-cc-app-token': appToken.trim(),
      },
      extra: {
        'useRawBearer': true,
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
