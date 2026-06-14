import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum ApiErrorType {
  unauthorized,
  notFound,
  badRequest,
  serverError,
  timeout,
  noConnection,
  unknown
}

class ApiErrorStateView extends StatelessWidget {
  final ApiErrorType errorType;
  final String errorCode;
  final VoidCallback onRetry;
  final bool isCompact;

  const ApiErrorStateView({
    super.key,
    required this.errorType,
    required this.errorCode,
    required this.onRetry,
    this.isCompact = false,
  });

  /// Helper method to map HTTP status codes to ApiErrorType
  static ApiErrorType fromStatusCode(int? statusCode) {
    if (statusCode == null) return ApiErrorType.unknown;
    if (statusCode == 401 || statusCode == 403) return ApiErrorType.unauthorized;
    if (statusCode == 404) return ApiErrorType.notFound;
    if (statusCode == 400) return ApiErrorType.badRequest;
    if (statusCode >= 500 && statusCode <= 599) return ApiErrorType.serverError;
    return ApiErrorType.unknown;
  }

  String get _imageAsset {
    switch (errorType) {
      case ApiErrorType.unauthorized:
        return 'assets/unauth_401_403.webp';
      case ApiErrorType.badRequest:
        return 'assets/bad_req.webp';
      case ApiErrorType.notFound:
        return 'assets/notFound_404.webp';
      case ApiErrorType.serverError:
        return 'assets/defaultError_500.webp';
      case ApiErrorType.noConnection:
        return 'assets/noConnection.webp';
      case ApiErrorType.timeout:
        return 'assets/timeout.webp';
      case ApiErrorType.unknown:
        return 'assets/defaultError_500.webp'; // Fallback
    }
  }

  String get _title {
    switch (errorType) {
      case ApiErrorType.unauthorized:
        return 'Hold up! ✋';
      case ApiErrorType.notFound:
        return 'Uh oh, it\'s a ghost town 👻';
      case ApiErrorType.badRequest:
        return 'Well, that was awkward 😬';
      case ApiErrorType.serverError:
        return 'Our servers are taking a nap 💤';
      case ApiErrorType.timeout:
        return 'Patience is a virtue... 🐢';
      case ApiErrorType.noConnection:
        return 'You\'re off the grid 📡';
      case ApiErrorType.unknown:
        return 'Oops, the gremlins got us! 👾';
    }
  }

  String get _description {
    switch (errorType) {
      case ApiErrorType.unauthorized:
        return 'You don\'t have the secret handshake to view this.';
      case ApiErrorType.notFound:
        return 'We looked everywhere, but couldn\'t find what you\'re looking for.';
      case ApiErrorType.badRequest:
        return 'Something went wrong with that request.';
      case ApiErrorType.serverError:
        return 'Things are a bit chaotic on our end. We\'re on it!';
      case ApiErrorType.timeout:
        return 'This is taking longer than expected. Let\'s try again.';
      case ApiErrorType.noConnection:
        return 'No internet! Reconnect to civilization and try again.';
      case ApiErrorType.unknown:
        return 'Something unexpected happened.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Allows use in scrollable areas or dialogs
          children: [
            Image.asset(
              _imageAsset,
              fit: BoxFit.contain,
              height: isCompact ? 120 : 220, // Constrain height based on compact mode
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if the webp is missing or path is wrong
                return Icon(Icons.error_outline, size: isCompact ? 40 : 80, color: Colors.grey);
              },
            ),
            SizedBox(height: isCompact ? 16 : 24),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 18 : null,
              ),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              _description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color ?? Colors.grey.shade600,
                fontSize: isCompact ? 13 : null,
              ),
            ),
        Text(
          "Error Code:$errorCode",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color ?? Colors.grey.shade600,
            fontSize: isCompact ? 11 : null,
          ),
        ),
            SizedBox(height: isCompact ? 16 : 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  PhosphorIcon(PhosphorIcons.arrowCounterClockwise()),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 24 : 32, 
                  vertical: isCompact ? 8 : 12
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
