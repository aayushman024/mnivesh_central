class FieldExecutiveSummary {
  final String id;
  final String name;
  final String employeeId;
  final String contactNumber;
  final bool isAvailable;
  final bool isNearer;
  final int? distanceMeters;
  final String? nextAvailableAt;

  const FieldExecutiveSummary({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.contactNumber,
    this.isAvailable = true,
    this.isNearer = false,
    this.distanceMeters,
    this.nextAvailableAt,
  });

  factory FieldExecutiveSummary.fromJson(Map<String, dynamic> json) {
    return FieldExecutiveSummary(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown FE',
      employeeId: json['employeeId']?.toString() ?? '-',
      contactNumber: json['contactNumber']?.toString() ?? '-',
      isAvailable: json['isAvailable'] ?? true,
      isNearer: json['isNearer'] ?? false,
      distanceMeters: _asInt(json['distanceMeters']),
      nextAvailableAt: json['nextAvailableAt']?.toString(),
    );
  }
}

class LocationUpdate {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime? timestamp;
  final int? batteryPercentage;

  const LocationUpdate({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.batteryPercentage,
  });

  factory LocationUpdate.fromJson(Map<String, dynamic> json) {
    final location = _asMap(json['location']);
    return LocationUpdate(
      latitude: _extractLatitude(location) ?? 0,
      longitude: _extractLongitude(location) ?? 0,
      address: json['locationString']?.toString() ?? 'Unknown location',
      timestamp: _asDateTime(json['time']),
      batteryPercentage: _asInt(json['batteryPercentage']),
    );
  }
}

class FieldExecutiveTrackingDetails {
  final LocationUpdate latest;
  final List<LocationUpdate> history;
  final ({double latitude, double longitude})? clientLocation;

  const FieldExecutiveTrackingDetails({
    required this.latest,
    required this.history,
    this.clientLocation,
  });

  factory FieldExecutiveTrackingDetails.fromJson(Map<String, dynamic> json) {
    final latestList = json['latestDetails'] as List?;
    final pastList = json['pastLocations'] as List?;
    final clientLocMap = _asMap(json['clientLocation']);

    final latestUpdate = latestList != null && latestList.isNotEmpty
        ? LocationUpdate.fromJson(_asMap(latestList.first))
        : const LocationUpdate(
            latitude: 0,
            longitude: 0,
            address: 'No latest data',
            timestamp: null,
            batteryPercentage: null,
          );

    final historyUpdates = pastList != null
        ? pastList.map((j) => LocationUpdate.fromJson(_asMap(j))).toList()
        : <LocationUpdate>[];

    final clientLat = _extractLatitude(clientLocMap);
    final clientLng = _extractLongitude(clientLocMap);

    return FieldExecutiveTrackingDetails(
      latest: latestUpdate,
      history: historyUpdates,
      clientLocation: (clientLat != null && clientLng != null)
          ? (latitude: clientLat, longitude: clientLng)
          : null,
    );
  }
}

class ClientSearchResult {
  final String clientId;
  final String name;
  final String mobile;
  final String address;
  final bool isTemporary;

  const ClientSearchResult({
    required this.clientId,
    required this.name,
    required this.mobile,
    required this.address,
    required this.isTemporary,
  });

  factory ClientSearchResult.fromJson(Map<String, dynamic> json) {
    return ClientSearchResult(
      clientId: json['clientId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      isTemporary: json['isTemporary'] == true,
    );
  }
}

class AddressSuggestion {
  final String name;
  final String address;
  final List<double>? coordinates; // [lng, lat]

  const AddressSuggestion({
    required this.name,
    required this.address,
    this.coordinates,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List?;
    return AddressSuggestion(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      coordinates: coords != null
          ? coords.map((e) => (e as num).toDouble()).toList()
          : null,
    );
  }
}

class FieldExecutiveLocation {
  final String id;
  final String name;
  final String employeeId;
  final String contactNumber;
  final LocationUpdate latest;
  final List<LocationUpdate> history;
  final ({double latitude, double longitude})? clientLocation;

  const FieldExecutiveLocation({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.contactNumber,
    required this.latest,
    required this.history,
    this.clientLocation,
  });
}

class RouteClientDetails {
  final String id;
  final String name;
  final String contactNumber;
  final String address;

  const RouteClientDetails({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.address,
  });

  factory RouteClientDetails.fromJson(Map<String, dynamic> json) {
    return RouteClientDetails(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Client',
      contactNumber: json['contactNumber']?.toString() ?? '-',
      address: json['address']?.toString() ?? '-',
    );
  }
}

class FieldExecutiveComment {
  final String text;
  final String byName;
  final DateTime? createdAt;

  const FieldExecutiveComment({
    required this.text,
    required this.byName,
    required this.createdAt,
  });

  factory FieldExecutiveComment.fromJson(Map<String, dynamic> json) {
    var target = json;

    // Handle Mongoose internal metadata if present
    // Sometimes the backend sends the subdocument with its parent array context
    if (json.containsKey('__parentArray') && json['__parentArray'] is List) {
      final arr = json['__parentArray'] as List;
      final idx = int.tryParse(json['__index']?.toString() ?? '');
      if (idx != null && idx >= 0 && idx < arr.length) {
        final item = arr[idx];
        if (item is Map) {
          target = Map<String, dynamic>.from(item);
        }
      }
    }

    return FieldExecutiveComment(
      text: target['text']?.toString() ?? '',
      byName: target['byName']?.toString() ?? 'Field Executive',
      createdAt: _asDateTime(target['createdAt']),
    );
  }
}

class AssignedVisitDetails {
  final String id;
  final String feId;
  final String feName;
  final String employeeId;
  final String contactNumber;
  final String clientType;
  final String purposeOfVisit;
  final String priority;
  final String status;
  final bool isCompleted;
  final bool onHold;
  final String visitingAddress;
  final String? additionalAddressDetails;
  final DateTime? slotStart;
  final DateTime? slotEnd;
  final List<FieldExecutiveComment> feComments;
  final RouteClientDetails client;
  final String addedBy;
  final bool canGoAnytime;
  final List<String> completionImages;

  const AssignedVisitDetails({
    required this.id,
    required this.feId,
    required this.feName,
    required this.employeeId,
    required this.contactNumber,
    required this.clientType,
    required this.purposeOfVisit,
    required this.priority,
    required this.status,
    required this.isCompleted,
    required this.onHold,
    required this.visitingAddress,
    this.additionalAddressDetails,
    required this.slotStart,
    required this.slotEnd,
    required this.feComments,
    required this.client,
    this.addedBy = 'System',
    this.canGoAnytime = false,
    this.completionImages = const [],
  });
}

class AssignedRouteSummary {
  final String feId;
  final String feName;
  final String employeeId;
  final String contactNumber;
  final List<AssignedRouteVisit> visits;

  const AssignedRouteSummary({
    required this.feId,
    required this.feName,
    required this.employeeId,
    required this.contactNumber,
    required this.visits,
  });

  factory AssignedRouteSummary.fromJson(Map<String, dynamic> json) {
    final visits = json['visits'] as List?;
    return AssignedRouteSummary(
      feId: json['feId']?.toString() ?? '',
      feName: json['feName']?.toString() ?? 'Unknown FE',
      employeeId: json['employeeId']?.toString() ?? '-',
      contactNumber: json['contactNumber']?.toString() ?? '-',
      visits: visits == null
          ? const []
          : visits
                .whereType<Map>()
                .map(
                  (item) => AssignedRouteVisit.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(),
    );
  }
}

class AssignedRouteVisit {
  final String visitId;
  final String clientName;
  final String purposeOfVisit;
  final String status;
  final bool canGoAnytime;
  final String priority;
  final String order;
  final AssignedRouteVisitTimings timings;
  final AssignedRouteVisitLocation location;
  final RouteTravelMetric? fromLastDestination;

  const AssignedRouteVisit({
    required this.visitId,
    required this.clientName,
    required this.purposeOfVisit,
    required this.status,
    required this.canGoAnytime,
    required this.priority,
    required this.order,
    required this.timings,
    required this.location,
    required this.fromLastDestination,
  });

  factory AssignedRouteVisit.fromJson(Map<String, dynamic> json) {
    final travelMetrics = _asMap(json['travelMetrics']);
    return AssignedRouteVisit(
      visitId: json['visitId']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? 'Unknown Client',
      purposeOfVisit: json['purposeOfVisit']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'pending',
      canGoAnytime: json['canGoAnytime'] == true,
      priority: json['priority']?.toString() ?? '0',
      order: json['order']?.toString() ?? '0',
      timings: AssignedRouteVisitTimings.fromJson(_asMap(json['timings'])),
      location: AssignedRouteVisitLocation.fromJson(_asMap(json['location'])),
      fromLastDestination: travelMetrics['fromLastDestination'] == null
          ? null
          : RouteTravelMetric.fromJson(
              _asMap(travelMetrics['fromLastDestination']),
            ),
    );
  }
}

class AssignedRouteVisitTimings {
  final DateTime? start;
  final DateTime? end;

  const AssignedRouteVisitTimings({required this.start, required this.end});

  factory AssignedRouteVisitTimings.fromJson(Map<String, dynamic> json) {
    return AssignedRouteVisitTimings(
      start: _asDateTime(json['start']),
      end: _asDateTime(json['end']),
    );
  }
}

class AssignedRouteVisitLocation {
  final List<double> coordinates;
  final String clientLocality;
  final String shortAddress;

  const AssignedRouteVisitLocation({
    required this.coordinates,
    required this.clientLocality,
    required this.shortAddress,
  });

  factory AssignedRouteVisitLocation.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List?;
    return AssignedRouteVisitLocation(
      coordinates: coordinates == null
          ? const []
          : coordinates
                .whereType<num>()
                .map((value) => value.toDouble())
                .toList(),
      clientLocality: json['clientLocality']?.toString() ?? '-',
      shortAddress: json['shortAddress']?.toString() ?? '-',
    );
  }
}

class RouteTravelMetric {
  final String distance;
  final String expectedTime;

  const RouteTravelMetric({required this.distance, required this.expectedTime});

  factory RouteTravelMetric.fromJson(Map<String, dynamic> json) {
    return RouteTravelMetric(
      distance: json['distance']?.toString() ?? '--',
      expectedTime: json['expectedTime']?.toString() ?? '--',
    );
  }
}

class OnHoldVisitDetails {
  final String id;
  final String clientType;
  final String purposeOfVisit;
  final String priority;
  final String status;
  final bool isCompleted;
  final bool onHold;
  final String visitingAddress;
  final String? additionalAddressDetails;
  final DateTime? availabilityStart;
  final DateTime? availabilityEnd;
  final String? assignedFeId;
  final String? assignedFeName;
  final List<FieldExecutiveComment> feComments;
  final RouteClientDetails client;
  final DateTime? completedAtTime;
  final String addedBy;
  final bool canGoAnytime;
  final List<String> completionImages;

  const OnHoldVisitDetails({
    required this.id,
    required this.clientType,
    required this.purposeOfVisit,
    required this.priority,
    required this.status,
    required this.isCompleted,
    required this.onHold,
    required this.visitingAddress,
    this.additionalAddressDetails,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.assignedFeId,
    required this.assignedFeName,
    required this.feComments,
    required this.client,
    this.completedAtTime,
    this.addedBy = 'System',
    this.canGoAnytime = false,
    this.completionImages = const [],
  });

  factory OnHoldVisitDetails.fromJson(Map<String, dynamic> json) {
    final availability = _asMap(json['availability']);
    final imagesList = json['completionImages'] as List?;

    return OnHoldVisitDetails(
      id: json['_id']?.toString() ?? '',
      clientType: json['clientType']?.toString() ?? 'unknown',
      purposeOfVisit: json['purposeOfVisit']?.toString() ?? '-',
      priority: json['priority']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'cancelled',
      isCompleted: json['isCompleted'] == true,
      onHold: json['onHold'] == true,
      visitingAddress: json['visitingAddress']?.toString() ?? '-',
      additionalAddressDetails: json['additionalAddressDetails']?.toString(),
      availabilityStart: _asDateTime(availability['start']),
      availabilityEnd: _asDateTime(availability['end']),
      assignedFeId: json['feId']?.toString(),
      assignedFeName: json['feName']?.toString(),
      feComments: _extractComments(json['feComments']),
      client: RouteClientDetails.fromJson(_asMap(json['clientId'])),
      completedAtTime: _asDateTime(json['completedAtTime']),
      addedBy: json['addedBy']?.toString() ?? 'System',
      canGoAnytime: json['canGoAnytime'] == true,
      completionImages: imagesList != null
          ? imagesList.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class CompletedVisitDetails {
  final String id;
  final String clientType;
  final String purposeOfVisit;
  final String priority;
  final String status;
  final bool isCompleted;
  final String visitingAddress;
  final String? additionalAddressDetails;
  final DateTime? actualVisitStart;
  final DateTime? actualVisitEnd;
  final String? feId;
  final String? feName;
  final String? feEmployeeId;
  final List<FieldExecutiveComment> feComments;
  final RouteClientDetails client;
  final DateTime? availabilityStart;
  final DateTime? availabilityEnd;
  final DateTime? completedAtTime;
  final String addedBy;
  final bool canGoAnytime;
  final List<String> completionImages;

  const CompletedVisitDetails({
    required this.id,
    required this.clientType,
    required this.purposeOfVisit,
    required this.priority,
    required this.status,
    required this.isCompleted,
    required this.visitingAddress,
    this.additionalAddressDetails,
    required this.actualVisitStart,
    required this.actualVisitEnd,
    required this.feId,
    required this.feName,
    required this.feEmployeeId,
    required this.feComments,
    required this.client,
    this.availabilityStart,
    this.availabilityEnd,
    this.completedAtTime,
    this.addedBy = 'System',
    this.canGoAnytime = false,
    this.completionImages = const [],
  });

  factory CompletedVisitDetails.fromJson(Map<String, dynamic> json) {
    final availability = _asMap(json['availability']);
    final imagesList = json['completionImages'] as List?;

    return CompletedVisitDetails(
      id: json['_id']?.toString() ?? '',
      clientType: json['clientType']?.toString() ?? 'unknown',
      purposeOfVisit: json['purposeOfVisit']?.toString() ?? '-',
      priority: json['priority']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'completed',
      isCompleted: json['isCompleted'] == true,
      visitingAddress: json['visitingAddress']?.toString() ?? '-',
      additionalAddressDetails: json['additionalAddressDetails']?.toString(),
      actualVisitStart: _asDateTime(json['actualVisitStart']),
      actualVisitEnd: _asDateTime(json['actualVisitEnd']),
      feId: json['feId']?.toString(),
      feName: json['feName']?.toString(),
      feEmployeeId: json['feEmployeeId']?.toString(),
      feComments: _extractComments(json['feComments']),
      client: RouteClientDetails.fromJson(_asMap(json['clientId'])),
      availabilityStart: _asDateTime(availability['start']),
      availabilityEnd: _asDateTime(availability['end']),
      completedAtTime: _asDateTime(json['completedAtTime']),
      addedBy: json['addedBy']?.toString() ?? 'System',
      canGoAnytime: json['canGoAnytime'] == true,
      completionImages: imagesList != null
          ? imagesList.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

DateTime? _asDateTime(dynamic value) {
  var text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text)?.toLocal();
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '');
}

double? _extractLatitude(Map<String, dynamic> value) {
  final coordinates = value['coordinates'];
  if (coordinates is List && coordinates.length >= 2) {
    return (coordinates[1] as num?)?.toDouble();
  }
  return null;
}

double? _extractLongitude(Map<String, dynamic> value) {
  final coordinates = value['coordinates'];
  if (coordinates is List && coordinates.length >= 2) {
    return (coordinates[0] as num?)?.toDouble();
  }
  return null;
}

List<FieldExecutiveComment> _extractComments(dynamic value) {
  if (value == null) {
    return const [];
  }

  // Handle case where value might be wrapped in a 'visit' or 'task' object
  // although usually handled by the caller.
  if (value is Map && value.containsKey('feComments')) {
    return _extractComments(value['feComments']);
  }

  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map(
        (item) =>
            FieldExecutiveComment.fromJson(Map<String, dynamic>.from(item)),
      )
      .where((item) => item.text.trim().isNotEmpty)
      .toList();
}
