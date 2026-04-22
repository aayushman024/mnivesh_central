import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../API/attendance_apiService.dart';
import '../Models/announcement.dart';
import '../Services/snackBar_Service.dart';

class AnnouncementState {
  final List<Announcement> items;
  final bool isLoading;
  final bool isSubmitting;
  final bool hasLoadedOnce;
  final String? errorMessage;

  const AnnouncementState({
    this.items = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.hasLoadedOnce = false,
    this.errorMessage,
  });

  AnnouncementState copyWith({
    List<Announcement>? items,
    bool? isLoading,
    bool? isSubmitting,
    bool? hasLoadedOnce,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnnouncementState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final announcementViewModelProvider =
    StateNotifierProvider<AnnouncementViewModel, AnnouncementState>((ref) {
      return AnnouncementViewModel();
    });

class AnnouncementViewModel extends StateNotifier<AnnouncementState> {
  AnnouncementViewModel() : super(const AnnouncementState());

  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.hasLoadedOnce && !forceRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await AttendanceApiService.fetchAnnouncements();
      final items = _extractAnnouncements(response);

      state = state.copyWith(
        items: items,
        isLoading: false,
        hasLoadedOnce: true,
        clearError: true,
      );
    } catch (error) {
      debugPrint('Failed to fetch announcements: $error');
      state = state.copyWith(
        isLoading: false,
        hasLoadedOnce: true,
        errorMessage: 'Failed to fetch announcements',
      );
    }
  }

  Future<bool> createAnnouncement({
    required String message,
    required AnnouncementPriority priority,
    required DateTime expiryDate,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final payload = {
        'message': message.trim(),
        'content': message.trim(),
        'priority': priority.apiValue,
        'type': priority.apiValue,
        'expiryDate': expiryDate.toIso8601String(),
        'expiresAt': expiryDate.toIso8601String(),
      };

      final response = await AttendanceApiService.createAnnouncement(payload);
      final created = _extractCreatedAnnouncement(response);

      state = state.copyWith(
        items: created == null ? state.items : [created, ...state.items],
        isSubmitting: false,
        hasLoadedOnce: true,
        clearError: true,
      );

      if (created == null) {
        await fetchAnnouncements(forceRefresh: true);
      }

      SnackbarService.showSuccess('Announcement added successfully');
      return true;
    } catch (error) {
      debugPrint('Failed to create announcement: $error');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to add announcement',
      );
      SnackbarService.showError('Failed to add announcement');
      return false;
    }
  }

  List<Announcement> _extractAnnouncements(dynamic response) {
    final rawList = switch (response) {
      List<dynamic> list => list,
      Map<String, dynamic> map => _extractListFromMap(map),
      Map map => _extractListFromMap(Map<String, dynamic>.from(map)),
      _ => const <dynamic>[],
    };

    return rawList
        .whereType<dynamic>()
        .map((item) {
          if (item is Map<String, dynamic>) {
            return Announcement.fromJson(item);
          }
          if (item is Map) {
            return Announcement.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<Announcement>()
        .toList();
  }

  List<dynamic> _extractListFromMap(Map<String, dynamic> map) {
    final candidates = [
      map['announcements'],
      map['data'],
      map['items'],
      map['rows'],
      map['results'],
    ];

    for (final candidate in candidates) {
      if (candidate is List<dynamic>) return candidate;
      if (candidate is List) return List<dynamic>.from(candidate);
    }

    return const [];
  }

  Announcement? _extractCreatedAnnouncement(dynamic response) {
    if (response is Map<String, dynamic>) {
      final candidate = response['announcement'] ??
          response['data'] ??
          response['item'] ??
          response['result'];
      if (candidate is Map<String, dynamic>) {
        return Announcement.fromJson(candidate);
      }
      if (candidate is Map) {
        return Announcement.fromJson(Map<String, dynamic>.from(candidate));
      }
    }

    if (response is Map) {
      return _extractCreatedAnnouncement(Map<String, dynamic>.from(response));
    }

    return null;
  }
}
