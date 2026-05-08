import 'package:flutter/material.dart';

class FieldExecutiveLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const FieldExecutiveLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class RouteOptimizationViewModel extends ChangeNotifier {
  RouteOptimizationViewModel();

  static const String allExecutivesFilter = 'all';

  final List<FieldExecutiveLocation> _fieldExecutives = const [
    FieldExecutiveLocation(
      id: 'fe_1',
      name: 'Amit Sharma',
      address: 'Connaught Place, New Delhi, Delhi 110001',
      latitude: 28.6315,
      longitude: 77.2167,
    ),
    FieldExecutiveLocation(
      id: 'fe_2',
      name: 'Neha Verma',
      address: 'Sector 18, Noida, Uttar Pradesh 201301',
      latitude: 28.5706,
      longitude: 77.3272,
    ),
    FieldExecutiveLocation(
      id: 'fe_3',
      name: 'Rahul Mehta',
      address: 'Cyber City, Gurugram, Haryana 122002',
      latitude: 28.4949,
      longitude: 77.0895,
    ),
    FieldExecutiveLocation(
      id: 'fe_4',
      name: 'Priya Nair',
      address: 'Raj Nagar, Ghaziabad, Uttar Pradesh 201002',
      latitude: 28.6760,
      longitude: 77.4375,
    ),
  ];

  String _selectedExecutiveId = allExecutivesFilter;
  String? _activeExecutiveId;

  List<FieldExecutiveLocation> get fieldExecutives =>
      List.unmodifiable(_fieldExecutives);

  String get selectedExecutiveId => _selectedExecutiveId;

  String? get activeExecutiveId => _activeExecutiveId;

  bool get isShowingAll => _selectedExecutiveId == allExecutivesFilter;

  List<FieldExecutiveLocation> get visibleExecutives {
    if (isShowingAll) return fieldExecutives;
    final selected = selectedExecutive;
    return selected == null ? fieldExecutives : [selected];
  }

  FieldExecutiveLocation? get selectedExecutive {
    if (isShowingAll) return null;
    return executiveById(_selectedExecutiveId);
  }

  FieldExecutiveLocation? get activeExecutive {
    final activeId = _activeExecutiveId;
    if (activeId == null) return null;
    return executiveById(activeId);
  }

  List<DropdownMenuItem<String>> buildExecutiveDropdownItems() {
    return [
      const DropdownMenuItem<String>(
        value: allExecutivesFilter,
        child: Text('All Field Executives'),
      ),
      ..._fieldExecutives.map(
        (executive) => DropdownMenuItem<String>(
          value: executive.id,
          child: Text(executive.name),
        ),
      ),
    ];
  }

  FieldExecutiveLocation? executiveById(String id) {
    for (final executive in _fieldExecutives) {
      if (executive.id == id) return executive;
    }
    return null;
  }

  bool isMarkerActive(String executiveId) => _activeExecutiveId == executiveId;

  void selectExecutive(String executiveId) {
    if (_selectedExecutiveId == executiveId) return;
    _selectedExecutiveId = executiveId;

    if (executiveId == allExecutivesFilter) {
      _activeExecutiveId = null;
    } else {
      _activeExecutiveId = executiveId;
    }

    notifyListeners();
  }

  void activateExecutive(String executiveId) {
    if (_activeExecutiveId == executiveId) return;
    _activeExecutiveId = executiveId;
    notifyListeners();
  }

  void clearActiveExecutive() {
    if (_activeExecutiveId == null) return;
    _activeExecutiveId = null;
    notifyListeners();
  }

  ({double latitude, double longitude}) getInitialCenter() {
    final visible = visibleExecutives;
    if (visible.isEmpty) {
      return (latitude: 20.5937, longitude: 78.9629);
    }

    double totalLatitude = 0;
    double totalLongitude = 0;
    for (final executive in visible) {
      totalLatitude += executive.latitude;
      totalLongitude += executive.longitude;
    }

    return (
      latitude: totalLatitude / visible.length,
      longitude: totalLongitude / visible.length,
    );
  }

  double getInitialZoom() => isShowingAll ? 4.6 : 12.8;

  ({
    double minLatitude,
    double maxLatitude,
    double minLongitude,
    double maxLongitude,
  })
  getVisibleBounds() {
    final visible = visibleExecutives;
    if (visible.isEmpty) {
      return (
        minLatitude: 20.5937,
        maxLatitude: 20.5937,
        minLongitude: 78.9629,
        maxLongitude: 78.9629,
      );
    }

    double minLatitude = visible.first.latitude;
    double maxLatitude = visible.first.latitude;
    double minLongitude = visible.first.longitude;
    double maxLongitude = visible.first.longitude;

    for (final executive in visible.skip(1)) {
      if (executive.latitude < minLatitude) {
        minLatitude = executive.latitude;
      }
      if (executive.latitude > maxLatitude) {
        maxLatitude = executive.latitude;
      }
      if (executive.longitude < minLongitude) {
        minLongitude = executive.longitude;
      }
      if (executive.longitude > maxLongitude) {
        maxLongitude = executive.longitude;
      }
    }

    return (
      minLatitude: minLatitude,
      maxLatitude: maxLatitude,
      minLongitude: minLongitude,
      maxLongitude: maxLongitude,
    );
  }
}
