import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';

class FirebasePerformanceInterceptor extends Interceptor {
  static const _metricKey = 'firebase_http_metric';

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final uri = options.uri;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final firebaseAppReady = Firebase.apps.isNotEmpty;
      if (!firebaseAppReady) {
        handler.next(options);
        return;
      }

      try {
        final metric = FirebasePerformance.instance.newHttpMetric(
          uri.toString(),
          _resolveHttpMethod(options.method),
        );

        metric.requestPayloadSize = _payloadSize(options.data);
        metric.putAttribute('base_url', options.baseUrl);
        metric.putAttribute('path', options.path);
        metric.putAttribute('client', 'dio');

        await metric.start();
        options.extra[_metricKey] = metric;
      } catch (_) {
        // Performance tracing must never block API traffic.
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) async {
    await _stopMetric(
      response.requestOptions,
      statusCode: response.statusCode,
      responseData: response.data,
    );
    handler.next(response);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    await _stopMetric(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      responseData: err.response?.data,
    );
    handler.next(err);
  }

  Future<void> _stopMetric(
      RequestOptions options, {
        int? statusCode,
        dynamic responseData,
      }) async {
    final metric = options.extra.remove(_metricKey);
    if (metric is! HttpMetric) {
      return;
    }

    try {
      metric.httpResponseCode = statusCode;
      metric.responseContentType = _contentType(options.responseType, responseData);
      metric.responsePayloadSize = _payloadSize(responseData);
      await metric.stop();
    } catch (_) {
      // Ignore trace shutdown errors so responses still propagate normally.
    }
  }

  HttpMethod _resolveHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'HEAD':
        return HttpMethod.Head;
      case 'OPTIONS':
        return HttpMethod.Options;
      case 'TRACE':
        return HttpMethod.Trace;
      case 'CONNECT':
        return HttpMethod.Connect;
      case 'GET':
      default:
        return HttpMethod.Get;
    }
  }

  int? _payloadSize(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      return data.length;
    }
    if (data is List<int>) {
      return data.length;
    }
    if (data is Map || data is List) {
      return data.toString().length;
    }
    return data.toString().length;
  }

  String? _contentType(ResponseType responseType, dynamic data) {
    if (responseType == ResponseType.bytes || data is List<int>) {
      return 'application/octet-stream';
    }
    if (data is String) {
      return 'text/plain';
    }
    if (data is Map || data is List) {
      return 'application/json';
    }
    return null;
  }
}
