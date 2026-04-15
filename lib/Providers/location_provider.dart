import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

// -- Office locations ----------------------------------------------------------

class _OfficeLocation {
  final String label;
  final double latitude;
  final double longitude;

  const _OfficeLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

const List<_OfficeLocation> _officeLocations = [
  _OfficeLocation(
    label: 'Delhi Head Office',
    latitude: 28.7193204,
    longitude: 77.1087568,
  ),
  _OfficeLocation(
    label: 'Sonipat Office',
    latitude: 28.9389909,
    longitude: 77.0563942,
  ),  _OfficeLocation(
    label: 'Noida Home',
    latitude: 28.543531327,
    longitude: 77.3792592,
  ),
];

const double _geofenceRadiusMeters = 200.0;

// -- Status --------------------------------------------------------------------

enum LocationStatus {
  checking,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  tooFar,
  ready,
}

// -- State ---------------------------------------------------------------------

class LocationState {
  final LocationStatus status;
  final String? displayName;
  final String? distanceLabel;
  final Position? position;

  const LocationState({
    required this.status,
    this.displayName,
    this.distanceLabel,
    this.position
  });

  LocationState copyWith({
    LocationStatus? status,
    String? displayName,
    String? distanceLabel,
    Position? position,
  }) =>
      LocationState(
        status: status ?? this.status,
        displayName: displayName ?? this.displayName,
        distanceLabel: distanceLabel ?? this.distanceLabel,
        position: position ?? this.position,
      );
}

// -- Notifier ------------------------------------------------------------------

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier()
      : super(const LocationState(status: LocationStatus.checking));

  bool _isBusy = false;

  Future<void> checkAndFetch() async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      await _run(requestIfDenied: true);
    } finally {
      _isBusy = false;
    }
  }

  Future<void> refreshStatus() async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      await _run(requestIfDenied: false);
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _run({required bool requestIfDenied}) async {
    // 1. Service check
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = const LocationState(status: LocationStatus.serviceDisabled);
      return;
    }

    // 2. Permission check
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      state = const LocationState(status: LocationStatus.permissionDeniedForever);
      return;
    }

    if (permission == LocationPermission.denied) {
      if (!requestIfDenied) {
        state = const LocationState(status: LocationStatus.permissionDenied);
        return;
      }
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        state = const LocationState(status: LocationStatus.permissionDenied);
        return;
      }
    }

    // 3. Fetch position
    state = const LocationState(status: LocationStatus.checking);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Find nearest office
      _OfficeLocation? nearestOffice;
      double nearestDistance = double.infinity;

      for (final office in _officeLocations) {
        final distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          office.latitude,
          office.longitude,
        );
        if (distanceMeters < nearestDistance) {
          nearestDistance = distanceMeters;
          nearestOffice = office;
        }
      }

      // 5. Check if within radius
      if (nearestOffice == null || nearestDistance > _geofenceRadiusMeters) {
        final label = nearestOffice == null
            ? 'No office locations configured'
            : nearestDistance >= 1000
            ? '${(nearestDistance / 1000).toStringAsFixed(1)} km from ${nearestOffice.label}'
            : '${nearestDistance.toStringAsFixed(0)} m from ${nearestOffice.label}';

        state = LocationState(
          status: LocationStatus.tooFar,
          distanceLabel: label,
          position: position,
        );
        return;
      }

      // 6. Inside radius - Use office label directly (no reverse geocoding)
      state = LocationState(
        status: LocationStatus.ready,
        displayName: nearestOffice.label,
        position: position,
      );
    } catch (_) {
      state = const LocationState(status: LocationStatus.serviceDisabled);
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
      (ref) => LocationNotifier(),
);