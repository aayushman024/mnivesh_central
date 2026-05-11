import 'dart:async';
import 'package:flutter/material.dart';

import '../API/route_optimization_api_service.dart';
import '../Models/route_optimization_models.dart';

class RouteOptimizationViewModel extends ChangeNotifier {
  RouteOptimizationViewModel();

  static const String allExecutivesFilter = 'all';

  // --- Tracking State ---
  final List<FieldExecutiveLocation> _fieldExecutives = [];
  bool isTrackingLoading = false;
  String? trackingErrorMessage;
  String _selectedExecutiveId = allExecutivesFilter;
  String? _activeExecutiveId;

  // --- Visit Details State ---
  final List<AssignedVisitDetails> _assignedVisits = [];
  final List<OnHoldVisitDetails> _onHoldVisits = [];
  final List<CompletedVisitDetails> _completedVisits = [];
  bool isVisitDetailsLoading = false;
  String? visitDetailsErrorMessage;
  int _selectedVisitTabIndex = 0;

  // Visit Filters
  String assignedSearchQuery = '';
  String onHoldSearchQuery = '';
  String completedSearchQuery = '';
  DateTime? assignedStartDate;
  DateTime? assignedEndDate;
  DateTime? completedStartDate;
  DateTime? completedEndDate;
  String assignedFeName = '';
  String assignedEmployeeId = '';
  String assignedStatus = 'all';
  String onHoldScope = 'all';

  // --- Add Task State ---
  List<ClientSearchResult> clientSuggestions = [];
  List<AddressSuggestion> addressSuggestions = [];
  List<FieldExecutiveSummary> availableFEs = [];
  
  bool isLoadingFEs = false;
  bool isSubmitting = false;
  bool isTemporary = false;
  
  String? selectedClientId;
  List<double>? selectedCoordinates;
  String selectedVisitType = 'Collection';
  int selectedPriority = 3;
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  Timer? _clientDebounce;
  Timer? _addressDebounce;

  @override
  void dispose() {
    _clientDebounce?.cancel();
    _addressDebounce?.cancel();
    super.dispose();
  }

  // --- Getters ---

  List<FieldExecutiveLocation> get fieldExecutives => List.unmodifiable(_fieldExecutives);
  String get selectedExecutiveId => _selectedExecutiveId;
  String? get activeExecutiveId => _activeExecutiveId;
  bool get isShowingAll => _selectedExecutiveId == allExecutivesFilter;
  int get selectedVisitTabIndex => _selectedVisitTabIndex;

  List<AssignedVisitDetails> get assignedVisits => _filterVisits(_assignedVisits, assignedSearchQuery);
  List<OnHoldVisitDetails> get onHoldVisits => _filterOnHold(_onHoldVisits, onHoldSearchQuery);
  List<CompletedVisitDetails> get completedVisits => _filterCompleted(_completedVisits, completedSearchQuery);

  List<FieldExecutiveLocation> get visibleExecutives {
    if (isShowingAll) return fieldExecutives;
    final selected = selectedExecutive;
    return selected == null ? fieldExecutives : [selected];
  }

  FieldExecutiveLocation? get selectedExecutive => isShowingAll ? null : executiveById(_selectedExecutiveId);
  
  FieldExecutiveLocation? get activeExecutive => _activeExecutiveId == null ? null : executiveById(_activeExecutiveId!);

  // --- Tracking Logic ---

  Future<void> loadTrackingData() async {
    if (isTrackingLoading) return;

    isTrackingLoading = true;
    trackingErrorMessage = null;
    notifyListeners();

    try {
      final executives = await RouteOptimizationApiService.fetchActiveFieldExecutives();
      final locations = await Future.wait(executives.map(_buildTrackingLocation));

      _fieldExecutives.clear();
      _fieldExecutives.addAll(locations.whereType<FieldExecutiveLocation>());

      _validateSelection();
    } catch (error) {
      trackingErrorMessage = error.toString().replaceFirst('Exception: ', '');
      _fieldExecutives.clear();
    } finally {
      isTrackingLoading = false;
      notifyListeners();
    }
  }

  Future<FieldExecutiveLocation?> _buildTrackingLocation(FieldExecutiveSummary executive) async {
    try {
      final tracking = await RouteOptimizationApiService.trackFieldExecutive(executive.id);
      return FieldExecutiveLocation(
        id: executive.id,
        name: executive.name,
        employeeId: executive.employeeId,
        contactNumber: executive.contactNumber,
        latest: tracking.latest,
        history: tracking.history,
        clientLocation: tracking.clientLocation,
      );
    } catch (_) {
      return null;
    }
  }

  // --- Visit Details Logic ---

  Future<void> initializeVisitDetails() async {
    if (isVisitDetailsLoading) return;

    isVisitDetailsLoading = true;
    visitDetailsErrorMessage = null;
    notifyListeners();

    await Future.wait([
      loadAssignedVisits(notify: false),
      loadOnHoldVisits(notify: false),
      loadCompletedVisits(notify: false),
    ]);

    isVisitDetailsLoading = false;
    notifyListeners();
  }

  Future<void> loadAssignedVisits({bool notify = true}) async {
    await _runVisitDetailsLoader(
      notify: notify,
      action: () async {
        final visits = await RouteOptimizationApiService.fetchAssignedVisitDetails(
          startDate: assignedStartDate,
          endDate: assignedEndDate,
          feName: assignedFeName,
          employeeId: assignedEmployeeId,
          clientName: assignedSearchQuery,
          status: assignedStatus == 'all' ? null : assignedStatus,
        );
        _assignedVisits.clear();
        _assignedVisits.addAll(visits);
      },
    );
  }

  Future<void> loadOnHoldVisits({bool notify = true}) async {
    await _runVisitDetailsLoader(
      notify: notify,
      action: () async {
        final visits = await RouteOptimizationApiService.fetchOnHoldVisitDetails(scope: onHoldScope);
        _onHoldVisits.clear();
        _onHoldVisits.addAll(visits);
      },
    );
  }

  Future<void> loadCompletedVisits({bool notify = true}) async {
    await _runVisitDetailsLoader(
      notify: notify,
      action: () async {
        final visits = await RouteOptimizationApiService.fetchCompletedVisitDetails(
          startDate: completedStartDate,
          endDate: completedEndDate,
        );
        _completedVisits.clear();
        _completedVisits.addAll(visits);
      },
    );
  }

  Future<void> refreshActiveVisitTab() async {
    switch (_selectedVisitTabIndex) {
      case 0: await loadAssignedVisits(); break;
      case 1: await loadOnHoldVisits(); break;
      case 2: await loadCompletedVisits(); break;
    }
  }

  // --- Add Task Logic ---


  void onAddressSearchChanged(String query) {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().length < 3) {
        addressSuggestions = [];
        notifyListeners();
        return;
      }
      try {
        addressSuggestions = await RouteOptimizationApiService.searchAddresses(query);
      } catch (e) {
        debugPrint('Error searching addresses: $e');
      }
      notifyListeners();
    });
  }

  Future<void> fetchCoordinatesForAddress(String address) async {
    if (address.isEmpty) return;
    try {
      final coords = await RouteOptimizationApiService.getCoordinates(address);
      if (coords != null) {
        selectedCoordinates = coords;
        await fetchAvailableFEs();
      }
    } catch (e) {
      debugPrint('Error fetching coordinates: $e');
    }
    notifyListeners();
  }

  Future<void> fetchAvailableFEs() async {
    if (selectedCoordinates == null) return;
    
    isLoadingFEs = true;
    notifyListeners();
    
    try {
      final start = _combineDateAndTime(selectedDate, startTime);
      final end = _combineDateAndTime(selectedDate, endTime);

      availableFEs = await RouteOptimizationApiService.fetchActiveFieldExecutives(
        lat: selectedCoordinates![1],
        lng: selectedCoordinates![0],
        slotStart: start,
        slotEnd: end,
      );
    } catch (e) {
      debugPrint('Error fetching FEs: $e');
    } finally {
      isLoadingFEs = false;
      notifyListeners();
    }
  }

  bool isTemporaryClientMode = false;
  String? temporaryClientName; // For dropdown visibility
  String? selectedTemporaryName; // For final submission

  void onClientSearchChanged(String query) async {
    _clientDebounce?.cancel();
    
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      temporaryClientName = null;
      clientSuggestions = [];
      notifyListeners();
      return;
    }

    _clientDebounce = Timer(const Duration(milliseconds: 300), () async {
      selectedClientId = null;
      isTemporaryClientMode = false;
      temporaryClientName = trimmedQuery; 
      
      if (trimmedQuery.length < 3) {
        clientSuggestions = [];
        notifyListeners();
        return;
      }

      try {
        clientSuggestions = await RouteOptimizationApiService.searchClients(trimmedQuery);
      } catch (e) {
        clientSuggestions = [];
      }
      notifyListeners();
    });
  }

  void switchToTemporaryClientMode(String name, TextEditingController nameController) {
    isTemporaryClientMode = true;
    selectedClientId = null;
    selectedTemporaryName = name; // Save for submission
    temporaryClientName = null; // Clear to close dropdown
    clientSuggestions = [];
    nameController.text = name;
    notifyListeners();
  }
  
  void selectClient(ClientSearchResult client, {required TextEditingController nameController, required TextEditingController mobileController, required TextEditingController addressController}) {
    selectedClientId = client.clientId;
    nameController.text = client.name;
    mobileController.text = client.mobile;
    clientSuggestions = [];
    
    if (client.address.isNotEmpty) {
      addressController.text = client.address;
      fetchCoordinatesForAddress(client.address);
    } else {
      addressController.clear();
      selectedCoordinates = null;
    }
    notifyListeners();
  }

  void selectAddress(AddressSuggestion suggestion, {required TextEditingController addressController}) {
    addressController.text = suggestion.address;
    selectedCoordinates = suggestion.coordinates;
    addressSuggestions = [];
    
    if (suggestion.coordinates == null) {
      fetchCoordinatesForAddress(suggestion.address);
    } else {
      fetchAvailableFEs();
    }
    notifyListeners();
  }

  Future<void> submitTask({
    required String address,
    required String mobile,
    required String purpose,
    required String? selectedFeId,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (selectedCoordinates == null) {
      onError('Please select a valid location');
      return;
    }

    final start = _combineDateAndTime(selectedDate, startTime);
    final end = _combineDateAndTime(selectedDate, endTime);

    if (start.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      onError('Start time cannot be in the past');
      return;
    }

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      onError('End time must be after start time');
      return;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      final payload = {
        'clientId': selectedClientId, // null for new temporary
        'clientType': isTemporaryClientMode ? 'temporary' : 'mint',
        if (isTemporaryClientMode) ...{
          'clientName': selectedTemporaryName,
          'clientMobile': mobile,
        },
        'visitingAddress': address,
        'availabilityStart': RouteOptimizationApiService.formatWithOffset(start),
        'availabilityEnd': RouteOptimizationApiService.formatWithOffset(end),
        'locationCoordinates': selectedCoordinates,
        'purposeOfVisit': purpose,
        'visitType': selectedVisitType,
        'priority': selectedPriority,
        'feId': selectedFeId,
        'slotStart': RouteOptimizationApiService.formatWithOffset(start),
        'slotEnd': RouteOptimizationApiService.formatWithOffset(end),
      };

      await RouteOptimizationApiService.createVisit(payload);
      onSuccess();
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateTask({
    required String visitId,
    required Map<String, dynamic> originalData,
    required Map<String, dynamic> newData,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    // 1. Identify only changed fields (delta)
    final delta = <String, dynamic>{};
    
    newData.forEach((key, value) {
      final originalValue = originalData[key];
      
      // Special handling for lists (coordinates)
      if (value is List && originalValue is List) {
        if (value.length != originalValue.length || 
            value.asMap().entries.any((e) => e.value != originalValue[e.key])) {
          delta[key] = value;
        }
      } else if (value != originalValue) {
        if (value is DateTime) {
          delta[key] = RouteOptimizationApiService.formatWithOffset(value);
        } else {
          delta[key] = value;
        }
      }
    });

    if (delta.isEmpty) {
      onSuccess(); // Nothing to change
      return;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      await RouteOptimizationApiService.editTask(visitId, delta);
      await initializeVisitDetails();
      onSuccess();
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> closeTask({
    required String visitId,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    isSubmitting = true;
    notifyListeners();

    try {
      await RouteOptimizationApiService.editTask(visitId, {'status': 'closed'});
      await refreshActiveVisitTab();
      onSuccess();
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void resetAddTaskForm() {
    selectedClientId = null;
    selectedCoordinates = null;
    selectedVisitType = 'Collection';
    selectedPriority = 3;
    selectedDate = DateTime.now();
    startTime = TimeOfDay.now();
    endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    clientSuggestions = [];
    addressSuggestions = [];
    availableFEs = [];
    isTemporary = false;
    notifyListeners();
  }

  // --- Setters ---

  void setVisitTabIndex(int index) {
    if (_selectedVisitTabIndex == index) return;
    _selectedVisitTabIndex = index;
    notifyListeners();
  }

  void setAssignedSearchQuery(String value) {
    assignedSearchQuery = value.trim();
    notifyListeners();
  }

  void setOnHoldSearchQuery(String value) {
    onHoldSearchQuery = value.trim();
    notifyListeners();
  }

  void setCompletedSearchQuery(String value) {
    completedSearchQuery = value.trim();
    notifyListeners();
  }

  void updateAssignedFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? feName,
    String? employeeId,
    String? status,
    bool clearDates = false,
  }) {
    assignedStartDate = clearDates ? null : startDate ?? assignedStartDate;
    assignedEndDate = clearDates ? null : endDate ?? assignedEndDate;
    assignedFeName = feName ?? assignedFeName;
    assignedEmployeeId = employeeId ?? assignedEmployeeId;
    assignedStatus = status ?? assignedStatus;
    notifyListeners();
  }

  void resetAssignedFilters() {
    assignedStartDate = null;
    assignedEndDate = null;
    assignedFeName = '';
    assignedEmployeeId = '';
    assignedStatus = 'all';
    assignedSearchQuery = '';
    notifyListeners();
  }

  void setOnHoldScope(String value) {
    if (onHoldScope == value) return;
    onHoldScope = value;
    notifyListeners();
  }

  void resetOnHoldFilters() {
    onHoldScope = 'all';
    onHoldSearchQuery = '';
    notifyListeners();
  }

  void updateCompletedFilters({DateTime? startDate, DateTime? endDate, bool clearDates = false}) {
    completedStartDate = clearDates ? null : startDate ?? completedStartDate;
    completedEndDate = clearDates ? null : endDate ?? completedEndDate;
    notifyListeners();
  }

  void resetCompletedFilters() {
    completedStartDate = null;
    completedEndDate = null;
    completedSearchQuery = '';
    notifyListeners();
  }

  void selectExecutive(String executiveId) {
    if (_selectedExecutiveId == executiveId) return;
    _selectedExecutiveId = executiveId;
    _activeExecutiveId = (executiveId == allExecutivesFilter) ? null : executiveId;
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

  void updateVisitType(String type) {
    selectedVisitType = type;
    notifyListeners();
  }

  void updatePriority(int priority) {
    selectedPriority = priority;
    notifyListeners();
  }

  void updateDate(DateTime date) {
    selectedDate = date;
    fetchAvailableFEs();
    notifyListeners();
  }

  void updateStartTime(TimeOfDay time) {
    startTime = time;
    fetchAvailableFEs();
    notifyListeners();
  }

  void updateEndTime(TimeOfDay time) {
    endTime = time;
    fetchAvailableFEs();
    notifyListeners();
  }

  void setTemporary(bool value) {
    isTemporary = value;
    notifyListeners();
  }

  // --- Helper Methods ---

  List<AssignedVisitDetails> _filterVisits(List<AssignedVisitDetails> list, String query) {
    if (query.isEmpty) return List.unmodifiable(list);
    final q = query.toLowerCase();
    return List.unmodifiable(list.where((v) =>
        v.client.name.toLowerCase().contains(q) ||
        v.feName.toLowerCase().contains(q) ||
        v.employeeId.toLowerCase().contains(q) ||
        v.visitingAddress.toLowerCase().contains(q) ||
        v.purposeOfVisit.toLowerCase().contains(q)));
  }

  List<OnHoldVisitDetails> _filterOnHold(List<OnHoldVisitDetails> list, String query) {
    if (query.isEmpty) return List.unmodifiable(list);
    final q = query.toLowerCase();
    return List.unmodifiable(list.where((v) =>
        v.client.name.toLowerCase().contains(q) ||
        v.client.contactNumber.toLowerCase().contains(q) ||
        v.visitingAddress.toLowerCase().contains(q) ||
        v.purposeOfVisit.toLowerCase().contains(q)));
  }

  List<CompletedVisitDetails> _filterCompleted(List<CompletedVisitDetails> list, String query) {
    if (query.isEmpty) return List.unmodifiable(list);
    final q = query.toLowerCase();
    return List.unmodifiable(list.where((v) =>
        v.client.name.toLowerCase().contains(q) ||
        (v.feName?.toLowerCase().contains(q) ?? false) ||
        (v.feEmployeeId?.toLowerCase().contains(q) ?? false) ||
        v.visitingAddress.toLowerCase().contains(q) ||
        v.purposeOfVisit.toLowerCase().contains(q)));
  }

  void _validateSelection() {
    if (_fieldExecutives.isEmpty) {
      _selectedExecutiveId = allExecutivesFilter;
      _activeExecutiveId = null;
    } else if (!isShowingAll && executiveById(_selectedExecutiveId) == null) {
      _selectedExecutiveId = allExecutivesFilter;
      _activeExecutiveId = null;
    }
  }

  Future<void> _runVisitDetailsLoader({required Future<void> Function() action, bool notify = true}) async {
    if (notify) {
      isVisitDetailsLoading = true;
      visitDetailsErrorMessage = null;
      notifyListeners();
    }
    try {
      await action();
    } catch (error) {
      visitDetailsErrorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (notify) {
        isVisitDetailsLoading = false;
        notifyListeners();
      }
    }
  }

  FieldExecutiveLocation? executiveById(String id) => _fieldExecutives.cast<FieldExecutiveLocation?>().firstWhere((e) => e?.id == id, orElse: () => null);

  bool isMarkerActive(String executiveId) => _activeExecutiveId == executiveId;

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) => DateTime(date.year, date.month, date.day, time.hour, time.minute);

  List<DropdownMenuItem<String>> buildExecutiveDropdownItems() {
    return [
      const DropdownMenuItem<String>(value: allExecutivesFilter, child: Text('All Field Executives')),
      ..._fieldExecutives.map((e) => DropdownMenuItem<String>(value: e.id, child: Text(e.name))),
    ];
  }

  ({double latitude, double longitude}) getInitialCenter() {
    final visible = visibleExecutives;
    if (visible.isEmpty) return (latitude: 20.5937, longitude: 78.9629);
    final lat = visible.map((e) => e.latest.latitude).reduce((a, b) => a + b) / visible.length;
    final lng = visible.map((e) => e.latest.longitude).reduce((a, b) => a + b) / visible.length;
    return (latitude: lat, longitude: lng);
  }

  double getInitialZoom() => isShowingAll ? 4.6 : 12.8;

  ({double minLatitude, double maxLatitude, double minLongitude, double maxLongitude}) getVisibleBounds() {
    final visible = visibleExecutives;
    if (visible.isEmpty) return (minLatitude: 20.5937, maxLatitude: 20.5937, minLongitude: 78.9629, maxLongitude: 78.9629);
    final lats = visible.map((e) => e.latest.latitude);
    final lngs = visible.map((e) => e.latest.longitude);
    return (
      minLatitude: lats.reduce((a, b) => a < b ? a : b),
      maxLatitude: lats.reduce((a, b) => a > b ? a : b),
      minLongitude: lngs.reduce((a, b) => a < b ? a : b),
      maxLongitude: lngs.reduce((a, b) => a > b ? a : b),
    );
  }
}
