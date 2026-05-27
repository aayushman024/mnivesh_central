import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'snackBar_Service.dart';
import '../Views/Screens/RouteManagement/add_task_screen.dart';

class LocationSharingService {
  // Regex to match a pair of decimal coordinates: e.g. "12.971598, 77.594562"
  static final RegExp _coordRegex = RegExp(r'(-?\d+\.\d+),\s*(-?\d+\.\d+)');

  /// Resolves shared text and returns [longitude, latitude] in GeoJSON format.
  /// If no coordinates are found, returns null.
  static Future<List<double>?> parseCoordinates(String sharedText) async {
    // 1. Try to find coordinates directly in raw text (e.g. shared coordinates copy-paste)
    final directMatch = _coordRegex.firstMatch(sharedText);
    if (directMatch != null) {
      final lat = double.tryParse(directMatch.group(1)!);
      final lng = double.tryParse(directMatch.group(2)!);
      if (lat != null && lng != null) {
        debugPrint('[LocationService] Found coordinates directly in text: [$lng, $lat]');
        return [lng, lat]; // GeoJSON format: [longitude, latitude]
      }
    }

    // 2. Extract URLs from the shared text
    final urlRegex = RegExp(r'https?://[^\s]+');
    final urlMatch = urlRegex.firstMatch(sharedText);
    if (urlMatch == null) return null;

    String url = urlMatch.group(0)!;
    debugPrint('[LocationService] Extracted URL: $url');

    // 3. Resolve shortened Google Maps URL (e.g. maps.app.goo.gl, goo.gl/maps)
    if (url.contains('maps.app.goo.gl') || url.contains('goo.gl/maps') || url.contains('g.co/maps')) {
      try {
        final dio = Dio(BaseOptions(
          followRedirects: true,
          maxRedirects: 5,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          validateStatus: (status) => status != null && status < 400,
        ));
        final response = await dio.head(url);
        url = response.realUri.toString();
        debugPrint('[LocationService] Resolved short URL via HEAD: $url');
      } catch (e) {
        debugPrint('[LocationService] HEAD request failed, trying GET: $e');
        try {
          final dio = Dio(BaseOptions(
            followRedirects: true,
            maxRedirects: 5,
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ));
          final response = await dio.get(url);
          url = response.realUri.toString();
          debugPrint('[LocationService] Resolved short URL via GET: $url');
        } catch (err) {
          debugPrint('[LocationService] GET redirect failed: $err');
          rethrow; // Rethrow to let callers know a network timeout / failure occurred
        }
      }
    }

    // 4. Extract coordinates from expanded URL parameters
    // Format A: /@latitude,longitude
    final atMatch = RegExp(r'/@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null) {
        return [lng, lat];
      }
    }

    // Format B: ?q=latitude,longitude
    final qMatch = RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) {
        return [lng, lat];
      }
    }

    // Format C: ?daddr=latitude,longitude (Google Navigation parameters)
    final daddrMatch = RegExp(r'[?&]daddr=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
    if (daddrMatch != null) {
      final lat = double.tryParse(daddrMatch.group(1)!);
      final lng = double.tryParse(daddrMatch.group(2)!);
      if (lat != null && lng != null) {
        return [lng, lat];
      }
    }

    // Format D: ?ll=latitude,longitude
    final llMatch = RegExp(r'[?&]ll=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
    if (llMatch != null) {
      final lat = double.tryParse(llMatch.group(1)!);
      final lng = double.tryParse(llMatch.group(2)!);
      if (lat != null && lng != null) {
        return [lng, lat];
      }
    }

    // Format E: general lat,lng match inside query parameter
    final queryMatch = _coordRegex.firstMatch(url);
    if (queryMatch != null) {
      final lat = double.tryParse(queryMatch.group(1)!);
      final lng = double.tryParse(queryMatch.group(2)!);
      if (lat != null && lng != null) {
        return [lng, lat];
      }
    }

    // Format F: Extract and native-geocode place name/address from URL
    String? extractedAddress;
    final placeMatch = RegExp(r'/maps/(?:place|search)/([^/?#]+)').firstMatch(url);
    if (placeMatch != null) {
      extractedAddress = Uri.decodeComponent(placeMatch.group(1)!.replaceAll('+', ' '));
    }

    if (extractedAddress == null) {
      final qParamMatch = RegExp(r'[?&]q=([^&]+)').firstMatch(url);
      if (qParamMatch != null) {
        final rawQ = Uri.decodeComponent(qParamMatch.group(1)!.replaceAll('+', ' '));
        if (!_coordRegex.hasMatch(rawQ)) {
          extractedAddress = rawQ;
        }
      }
    }

    if (extractedAddress != null && extractedAddress.isNotEmpty) {
      debugPrint('[LocationService] Attempting to geocode place/address name from URL: $extractedAddress');
      try {
        final locations = await locationFromAddress(extractedAddress).timeout(
          const Duration(seconds: 5),
        );
        if (locations.isNotEmpty) {
          final loc = locations.first;
          debugPrint('[LocationService] Geocoded coordinates from URL: [${loc.longitude}, ${loc.latitude}]');
          return [loc.longitude, loc.latitude]; // GeoJSON format
        }
      } catch (e) {
        debugPrint('[LocationService] Geocoding place name failed: $e');
      }
    }

    // 5. Fallback: Try to geocode the whole shared text if it's a short address string (no URLs)
    if (!sharedText.contains('http://') && !sharedText.contains('https://') && sharedText.trim().length < 250) {
      final cleanText = sharedText.trim();
      if (cleanText.isNotEmpty) {
        debugPrint('[LocationService] Attempting to geocode raw text address: $cleanText');
        try {
          final locations = await locationFromAddress(cleanText).timeout(
            const Duration(seconds: 5),
          );
          if (locations.isNotEmpty) {
            final loc = locations.first;
            debugPrint('[LocationService] Geocoded raw text: [${loc.longitude}, ${loc.latitude}]');
            return [loc.longitude, loc.latitude]; // GeoJSON format
          }
        } catch (e) {
          debugPrint('[LocationService] Geocoding raw text failed: $e');
        }
      }
    }

    return null;
  }

  /// Reverse geocodes coordinates (lat, lng) to a clean address string
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng).timeout(
        const Duration(seconds: 5),
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          if (place.name != null && place.name != place.street) place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode
        ].where((e) => e != null && e.trim().isNotEmpty).toList();
        
        final cleanAddress = parts.join(', ');
        debugPrint('[LocationService] Reverse-geocoded address: $cleanAddress');
        return cleanAddress;
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocoding failed: $e');
      rethrow; // Rethrow to indicate geocoding exception
    }
    return null;
  }

  static StreamSubscription? _intentSub;

  /// Initializes listening for location sharing intents.
  static void initListeners() {
    // 1. Listen for share intent while app is running in background/foreground
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _handleSharedIntent(value);
    }, onError: (err) {
      debugPrint("[ShareIntent] getMediaStream error: $err");
    });

    // 2. Capture share intent that cold-started the app
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _handleSharedIntent(value);
    });
  }

  /// Disposes sharing listeners.
  static void disposeListeners() {
    _intentSub?.cancel();
    _intentSub = null;
  }

  static void _handleSharedIntent(List<SharedMediaFile> value) async {
    if (value.isEmpty) return;

    final sharedText = value.first.path;
    if (sharedText.isEmpty) return;

    // Reset intent stream so we don't handle it again on subsequent resumes
    try {
      ReceiveSharingIntent.instance.reset();
    } catch (e) {
      debugPrint('[ShareIntent] Error resetting intent: $e');
    }

    if (!_shouldHandleSharedText(sharedText)) {
      debugPrint('[ShareIntent] Ignoring non-location deep link/shared text: $sharedText');
      return;
    }

    final context = SnackbarService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[ShareIntent] App context is not initialized yet. Delaying intent handling.');
      // Retrying in 1 second when navigator key is ready
      Future.delayed(const Duration(seconds: 1), () => _handleSharedIntent(value));
      return;
    }

    // Show a premium loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Resolving shared location...",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final coords = await parseCoordinates(sharedText);
      final activeContext1 = SnackbarService.navigatorKey.currentContext;
      if (activeContext1 == null || !activeContext1.mounted) return;

      if (coords == null) {
        // Dismiss dialog
        Navigator.of(activeContext1, rootNavigator: true).pop();
        SnackbarService.showError("Failed to extract location details from shared link");
        return;
      }

      // Reverse geocode coords[1]=lat, coords[0]=lng
      String? address;
      try {
        address = await reverseGeocode(coords[1], coords[0]);
      } catch (geocodingError) {
        // If native geocoding fails, dismiss loading dialog and show error alert as approved
        final activeContext2 = SnackbarService.navigatorKey.currentContext;
        if (activeContext2 == null || !activeContext2.mounted) return;
        Navigator.of(activeContext2, rootNavigator: true).pop();
        
        // Show Network timeout alert
        showDialog(
          context: activeContext2,
          builder: (ctx) => AlertDialog(
            title: const Text("Location Search Failed"),
            content: const Text("Network timeout or Geocoder error. Please try again or search in the address bar."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              )
            ],
          ),
        );
        return;
      }

      // Dismiss loading dialog
      final activeContext3 = SnackbarService.navigatorKey.currentContext;
      if (activeContext3 == null || !activeContext3.mounted) return;
      Navigator.of(activeContext3, rootNavigator: true).pop();

      // Navigate to AddTaskScreen with the prefilled values
      Navigator.push(
        activeContext3,
        MaterialPageRoute(
          builder: (context) => AddTaskScreen(
            initialCoordinates: coords,
            initialAddress: address,
          ),
        ),
      );
    } catch (e) {
      final activeContext4 = SnackbarService.navigatorKey.currentContext;
      if (activeContext4 == null || !activeContext4.mounted) return;
      
      // Dismiss dialog
      Navigator.of(activeContext4, rootNavigator: true).pop();
      debugPrint('[ShareIntent] Error resolving shared location: $e');
      
      // If redirection / Dio failed, show Network timeout alert
      showDialog(
        context: activeContext4,
        builder: (ctx) => AlertDialog(
          title: const Text("Connection Error"),
          content: const Text("Network timeout. Please copy coordinates manually or try searching in the address bar."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  static bool _shouldHandleSharedText(String sharedText) {
    if (_coordRegex.hasMatch(sharedText)) {
      return true;
    }

    final trimmedText = sharedText.trim();
    final uri = Uri.tryParse(trimmedText);
    if (uri == null) {
      // Allow plain-text addresses/place names to go through existing geocoding fallback.
      return true;
    }

    // Internal app callbacks are handled by app_links, not by location sharing.
    if (uri.scheme == 'mniveshcentral') {
      return false;
    }

    // External web URLs may still be valid location links in arbitrary formats.
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return true;
    }

    // Ignore other custom-scheme deep links.
    if (uri.hasScheme) {
      return false;
    }

    return true;
  }
}
