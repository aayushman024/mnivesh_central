import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../Managers/AuthManager.dart';
import '../Models/route_optimization_models.dart';
import '../Services/app_tokens_service.dart';
import '../Services/bootstrap_service.dart';
import 'api_client.dart';
import 'api_config.dart';

class RouteOptimizationApiService {
  static const String _basePath = '/api/route-plan';
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static Future<List<FieldExecutiveSummary>> fetchActiveFieldExecutives({
    double? lat,
    double? lng,
    DateTime? slotStart,
    DateTime? slotEnd,
  }) async {
    final queryParameters = <String, dynamic>{
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (slotStart != null) 'slotStart': formatWithOffset(slotStart),
      if (slotEnd != null) 'slotEnd': formatWithOffset(slotEnd),
    };

    return _executeWithRetry(
      endpoint: '$_basePath/fe/list',
      request: (options) =>
          ApiClient.getDio(ApiConfig.routeOptimizationBaseUrl).get(
            '$_basePath/fe/list',
            queryParameters: queryParameters.isEmpty ? null : queryParameters,
            options: options,
          ),
      transform: (response) {
        final list = _extractList(response.data);
        return list.map(FieldExecutiveSummary.fromJson).toList();
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<FieldExecutiveTrackingDetails> trackFieldExecutive(
    String feId,
  ) async {
    return _executeWithRetry(
      endpoint: '$_basePath/fe/$feId/track',
      request: (options) => ApiClient.getDio(
        ApiConfig.routeOptimizationBaseUrl,
      ).get('$_basePath/fe/$feId/track', options: options),
      transform: (response) {
        final payload = _asMap(response.data);
        print(payload);
        return FieldExecutiveTrackingDetails.fromJson(payload);
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<List<AssignedVisitDetails>> fetchAssignedVisitDetails({
    DateTime? startDate,
    DateTime? endDate,
    String? feName,
    String? employeeId,
    String? clientName,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'startDate': _dateFormat.format(startDate),
      if (endDate != null) 'endDate': _dateFormat.format(endDate),
      if (_isNotBlank(feName)) 'feName': feName!.trim(),
      if (_isNotBlank(employeeId)) 'employeeId': employeeId!.trim(),
      if (_isNotBlank(clientName)) 'clientName': clientName!.trim(),
      if (_isNotBlank(status)) 'status': status!.trim(),
    };

    return _executeWithRetry(
      endpoint: '$_basePath/get-combined-list',
      request: (options) =>
          ApiClient.getDio(ApiConfig.routeOptimizationBaseUrl).get(
            '$_basePath/get-combined-list',
            queryParameters: queryParameters.isEmpty ? null : queryParameters,
            options: options,
          ),
      transform: (response) {
        final payload = _asMap(response.data);
        final groups = _extractList(payload['data']);
        final visits = <AssignedVisitDetails>[];

        for (final group in groups) {
          final fe = _asMap(group['feId']);
          final slots = _extractList(group['bookedSlots']);

          for (final slot in slots) {
            final client = RouteClientDetails.fromJson(_asMap(slot['client']));
            final visit = _asMap(slot['visit']);

            final imagesList = visit['completionImages'] as List?;
            final completionImages = imagesList != null
                ? imagesList.map((e) => e.toString()).toList()
                : const <String>[];

            visits.add(
              AssignedVisitDetails(
                id: visit['_id']?.toString() ?? '',
                feId: fe['_id']?.toString() ?? '',
                feName: fe['name']?.toString() ?? 'Unknown FE',
                employeeId: fe['employeeId']?.toString() ?? '-',
                contactNumber: fe['contactNumber']?.toString() ?? '-',
                clientType: slot['clientType']?.toString() ?? 'unknown',
                purposeOfVisit: visit['purposeOfVisit']?.toString() ?? '-',
                priority: visit['priority']?.toString() ?? '0',
                status: visit['status']?.toString() ?? 'pending',
                isCompleted: visit['isCompleted'] == true,
                onHold: visit['onHold'] == true,
                visitingAddress:
                    (visit['visitingAddress']?.toString().isNotEmpty ?? false)
                    ? visit['visitingAddress'].toString()
                    : client.address,
                slotStart: _asDateTime(slot['start']),
                slotEnd: _asDateTime(slot['end']),
                feComments: _extractComments(visit['feComments']),
                client: client,
                addedBy: visit['addedBy']?.toString() ?? 'System',
                canGoAnytime: visit['canGoAnytime'] == true,
                completionImages: completionImages,
              ),
            );
          }
        }

        return visits;
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<List<AssignedRouteSummary>>
  fetchAssignedRouteSummaries() async {
    return _executeWithRetry(
      endpoint: '$_basePath/tasks/assigned-summary',
      request: (options) => ApiClient.getDio(
        ApiConfig.routeOptimizationBaseUrl,
      ).get('$_basePath/tasks/assigned-summary', options: options),
      transform: (response) {
        final payload = _asMap(response.data);
        final list = _extractList(payload['data']);
        return list.map(AssignedRouteSummary.fromJson).toList();
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<List<OnHoldVisitDetails>> fetchOnHoldVisitDetails({
    String? scope,
  }) async {
    final queryParameters = <String, dynamic>{
      if (_isNotBlank(scope) && scope != 'all') 'scope': scope,
    };

    return _executeWithRetry(
      endpoint: '$_basePath/clients/on-hold',
      request: (options) =>
          ApiClient.getDio(ApiConfig.routeOptimizationBaseUrl).get(
            '$_basePath/clients/on-hold',
            queryParameters: queryParameters.isEmpty ? null : queryParameters,
            options: options,
          ),
      transform: (response) {
        final list = _extractList(response.data);
        // print(list);
        return list.map(OnHoldVisitDetails.fromJson).toList();
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<List<CompletedVisitDetails>> fetchCompletedVisitDetails({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      if (startDate != null) 'from': _dateFormat.format(startDate),
      if (endDate != null) 'to': _dateFormat.format(endDate),
    };

    return _executeWithRetry(
      endpoint: '$_basePath/tasks/completed',
      request: (options) =>
          ApiClient.getDio(ApiConfig.routeOptimizationBaseUrl).get(
            '$_basePath/tasks/completed',
            queryParameters: queryParameters.isEmpty ? null : queryParameters,
            options: options,
          ),
      transform: (response) {
        final payload = _asMap(response.data);
        final list = _extractList(payload['tasks']);
        return list.map(CompletedVisitDetails.fromJson).toList();
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<List<ClientSearchResult>> searchClients(
    String query, {
    bool temporary = false,
    bool searchAll = false,
  }) async {
    return _executeWithRetry(
      endpoint: '$_basePath/clients/list',
      request: (options) =>
          ApiClient.getDio(ApiConfig.routeOptimizationBaseUrl).get(
            '$_basePath/clients/list',
            queryParameters: {
              'search': query,
              'temporary': temporary,
              'searchall': searchAll,
            },
            options: options,
          ),
      transform: (response) {
        final payload = _asMap(response.data);
        final list = _extractList(payload['clientList']);
        return list.map(ClientSearchResult.fromJson).toList();
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<List<AddressSuggestion>> searchAddresses(String query) async {
    return _executeWithRetry(
      endpoint: '$_basePath/client/searchAddress',
      request: (options) =>
          ApiClient.getDio(ApiConfig.routeOptimizationBaseUrl).post(
            '$_basePath/client/searchAddress',
            data: {'searchedAddress': query},
            options: options,
          ),
      transform: (response) {
        final payload = _asMap(response.data);
        final list = _extractList(payload['suggestions']);
        return list.map(AddressSuggestion.fromJson).toList();
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<List<double>?> getCoordinates(String address) async {
    return _executeWithRetry(
      endpoint: '$_basePath/client/getCoordinatesFromAddress',
      request: (options) =>
          ApiClient.getDio(ApiConfig.routeOptimizationBaseUrl).get(
            '$_basePath/client/getCoordinatesFromAddress',
            queryParameters: {'address': address},
            options: options,
          ),
      transform: (response) {
        final payload = _asMap(response.data);
        final coords = payload['coordinates'] as List?;
        return coords?.map((e) => (e as num).toDouble()).toList();
      },
      rethrowAs: _mapRouteError,
    );
  }

  static Future<void> createVisit(Map<String, dynamic> data) async {
    await _executeWithRetry(
      endpoint: '$_basePath/clients/add-visit',
      request: (options) => ApiClient.getDio(
        ApiConfig.routeOptimizationBaseUrl,
      ).post('$_basePath/clients/add-visit', data: data, options: options),
      transform: (response) => null,
      rethrowAs: _mapRouteError,
    );
  }

  static Future<void> editTask(
    String visitId,
    Map<String, dynamic> data,
  ) async {
    await _executeWithRetry(
      endpoint: '$_basePath/tasks/$visitId/edit',
      request: (options) => ApiClient.getDio(
        ApiConfig.routeOptimizationBaseUrl,
      ).patch('$_basePath/tasks/$visitId/edit', data: data, options: options),
      transform: (response) => null,
      rethrowAs: _mapRouteError,
    );
  }

  static Future<T> _executeWithRetry<T>({
    required String endpoint,
    required Future<Response<dynamic>> Function(Options options) request,
    required T Function(Response<dynamic> response) transform,
    Exception? Function(Object error)? rethrowAs,
  }) async {
    try {
      final options = await _buildRouteOptions();
      final response = await request(options);
      final result = transform(response);
      debugPrint('[RouteOptimizationApiService] $endpoint -> $result');
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        debugPrint(
          '[RouteOptimizationApiService] $endpoint returned 401; refreshing app tokens...',
        );
        try {
          await AppTokensService.syncInBackground(
            trigger: 'route_401_$endpoint',
          );
          final retryOptions = await _buildRouteOptions();
          final retryResponse = await request(retryOptions);
          final result = transform(retryResponse);
          debugPrint(
            '[RouteOptimizationApiService] $endpoint retry succeeded after token refresh.',
          );
          return result;
        } catch (retryError) {
          debugPrint(
            '[RouteOptimizationApiService] $endpoint retry failed: $retryError',
          );
          if (rethrowAs != null) {
            final mapped = rethrowAs(retryError);
            if (mapped != null) {
              throw mapped;
            }
          }
          rethrow;
        }
      }

      debugPrint(
        '[RouteOptimizationApiService] $endpoint failed: '
        '${error.response?.statusCode} - ${error.response?.data ?? error.message}',
      );
      if (rethrowAs != null) {
        final mapped = rethrowAs(error);
        if (mapped != null) {
          throw mapped;
        }
      }
      rethrow;
    } on StateError catch (error) {
      if (rethrowAs != null) {
        final mapped = rethrowAs(error);
        if (mapped != null) {
          throw mapped;
        }
      }
      rethrow;
    }
  }

  static Future<Options> _buildRouteOptions() async {
    await BootstrapService.ready;

    var appToken = AuthManager.getAppToken(ApiConfig.routeAppKey);
    final accessToken = AuthManager.accessToken;

    if (appToken == null || appToken.trim().isEmpty) {
      await AppTokensService.syncInBackground(trigger: 'missing_route_token');
      appToken = AuthManager.getAppToken(ApiConfig.routeAppKey);
    }

    if (appToken == null || appToken.trim().isEmpty) {
      throw StateError(
        'Missing ${ApiConfig.routeAppKey} app token in secure storage.',
      );
    }
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError(
        'Missing mobile access token for route optimization API.',
      );
    }

    return Options(
      headers: {'x-cc-app-token': appToken.trim()},
      extra: {'useRawBearer': true, 'skipRefresh': false},
    );
  }

  static Exception? _mapRouteError(Object error) {
    if (error is StateError) {
      return Exception(error.message);
    }
    if (error is DioException) {
      final payload = error.response?.data;
      if (payload is Map) {
        final message =
            payload['message']?.toString() ??
            payload['error']?.toString() ??
            payload['details']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return Exception(message);
        }
      }
      return Exception(error.message ?? 'Route optimization request failed');
    }
    return null;
  }

  static bool _isNotBlank(String? value) =>
      value != null && value.trim().isNotEmpty;

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static DateTime? _asDateTime(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    // Parse the ISO string and convert to local (which will be IST for users)
    return DateTime.tryParse(text)?.toLocal();
  }

  /// Formats a DateTime as ISO8601 with the local timezone offset (e.g. +05:30)
  /// This ensures MongoDB correctly identifies the moment and stores it as UTC.
  static String formatWithOffset(DateTime dt) {
    final iso = dt.toIso8601String();
    if (dt.isUtc) return iso;

    final offset = dt.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';

    return '$iso$sign$hours:$minutes';
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

  static List<FieldExecutiveComment> _extractComments(dynamic data) {
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) =>
              FieldExecutiveComment.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.text.trim().isNotEmpty)
        .toList();
  }
}
