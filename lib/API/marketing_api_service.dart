import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../Managers/AuthManager.dart';
import '../Models/marketing_model.dart';
import '../Services/app_tokens_service.dart';
import 'api_client.dart';
import 'api_config.dart';

class MarketingOptionsResponse {
  final List<MarketingCategory> categories;
  final List<DisclaimerOption> disclaimers;

  MarketingOptionsResponse({
    required this.categories,
    required this.disclaimers,
  });
}

class MarketingApiService {
  static Future<List<MarketingTemplate>> getMarketingTemplates(
    String? categoryKey,
  ) async {
    return _executeWithRetry(
      endpoint: '/api/marketing-template',
      request: (options) => ApiClient.getDio(ApiConfig.marketingBaseUrl).get(
        '/api/marketing-template',
        queryParameters: categoryKey != null ? {'category': categoryKey} : null,
        options: options,
      ),
      transform: (response) {
        final payload = _asMap(response.data);
        if (payload['success'] == true) {
          final data = payload['data'] as List<dynamic>? ?? const [];
          return data.map((json) => MarketingTemplate.fromJson(json)).toList();
        }
        throw Exception(
          payload['message'] ?? 'Failed to fetch marketing templates',
        );
      },
      rethrowAs: (error) {
        if (error is DioException) {
          return Exception(
            'Failed to load marketing templates: ${error.message}',
          );
        }
        return null;
      },
    );
  }

  static Future<MarketingOptionsResponse> getMarketingOptions() async {
    return _executeWithRetry(
      endpoint: '/api/marketing-template/getList',
      request: (options) => ApiClient.getDio(
        ApiConfig.marketingBaseUrl,
      ).get('/api/marketing-template/getList', options: options),
      transform: (response) {
        final payload = _asMap(response.data);
        if (payload['success'] == true) {
          final categoryData =
              payload['category'] as List<dynamic>? ?? const [];
          final disclaimerData =
              payload['disclaimerOptions'] as List<dynamic>? ?? const [];

          final categories = categoryData
              .map((json) => MarketingCategory.fromJson(json))
              .toList();
          final disclaimers = disclaimerData
              .map((json) => DisclaimerOption.fromJson(json))
              .toList();

          return MarketingOptionsResponse(
            categories: categories,
            disclaimers: disclaimers,
          );
        }
        throw Exception(payload['message'] ?? 'Failed to fetch options');
      },
      rethrowAs: (error) {
        if (error is DioException) {
          return Exception(
            'Failed to load marketing options: ${error.message}',
          );
        }
        return null;
      },
    );
  }

  static Future<T> _executeWithRetry<T>({
    required String endpoint,
    required Future<Response<dynamic>> Function(Options options) request,
    required T Function(Response<dynamic> response) transform,
    Exception? Function(Object error)? rethrowAs,
  }) async {
    try {
      final options = await _buildMarketingOptions();
      final response = await request(options);
      final result = transform(response);
      debugPrint('[MarketingApiService] $endpoint -> $result');
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        debugPrint(
          '[MarketingApiService] $endpoint returned 401; refreshing app tokens...',
        );
        try {
          await AppTokensService.syncInBackground(
            trigger: 'marketing_401_$endpoint',
          );

          final retryOptions = await _buildMarketingOptions();
          final retryResponse = await request(retryOptions);
          final result = transform(retryResponse);
          debugPrint(
            '[MarketingApiService] $endpoint retry succeeded after token refresh.',
          );
          return result;
        } catch (retryError) {
          debugPrint(
            '[MarketingApiService] $endpoint retry failed: $retryError',
          );
          if (rethrowAs != null) {
            final mapped = rethrowAs(retryError);
            if (mapped != null) throw mapped;
          }
          rethrow;
        }
      }

      debugPrint(
        '[MarketingApiService] $endpoint failed: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      if (rethrowAs != null) {
        final mapped = rethrowAs(error);
        if (mapped != null) throw mapped;
      }
      rethrow;
    } on StateError catch (error) {
      debugPrint(
        '[MarketingApiService] $endpoint state error: ${error.message}',
      );
      if (rethrowAs != null) {
        final mapped = rethrowAs(error);
        if (mapped != null) throw mapped;
      }
      rethrow;
    } catch (error) {
      debugPrint('[MarketingApiService] $endpoint failed: $error');
      rethrow;
    }
  }

  static Future<Options> _buildMarketingOptions() async {
    var appToken = await AuthManager.getAppBackendToken(
      ApiConfig.marketingAppKey,
    );
    final accessToken = await AuthManager.getAccessToken();

    if (appToken == null || appToken.trim().isEmpty) {
      await AppTokensService.syncInBackground(
        trigger: 'missing_marketing_token',
      );
      appToken = await AuthManager.getAppBackendToken(
        ApiConfig.marketingAppKey,
      );
    }

    if (appToken == null || appToken.trim().isEmpty) {
      throw StateError(
        'Missing ${ApiConfig.marketingAppKey} app token in secure storage.',
      );
    }
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError('Missing mobile access token for marketing API.');
    }

    return Options(
      headers: {'x-cc-app-token': appToken.trim()},
      extra: {'skipRefresh': false},
    );
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
