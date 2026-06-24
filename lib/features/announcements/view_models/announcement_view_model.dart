import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:mnivesh_central/core/api/api_service.dart';
import 'package:mnivesh_central/features/auth/managers/auth_manager.dart';
import 'package:mnivesh_central/features/announcements/models/announcement.dart';
import 'package:mnivesh_central/core/services/snack_bar_service.dart';
import 'package:mnivesh_central/features/auth/demo/demo_constants.dart';
import 'package:mnivesh_central/features/auth/demo/demo_mode_provider.dart';

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
      return AnnouncementViewModel(ref);
    });

class AnnouncementViewModel extends StateNotifier<AnnouncementState> {
  final Ref _ref;
  AnnouncementViewModel(this._ref) : super(const AnnouncementState());

  bool canSubmitAnnouncement({
    required String title,
    required String message,
    required DateTime? expiryDate,
    required List<String> selectedDepartments,
    required List<String> selectedEmails,
  }) {
    return title.trim().isNotEmpty &&
        message.trim().isNotEmpty &&
        (selectedDepartments.isNotEmpty || selectedEmails.isNotEmpty) &&
        !state.isSubmitting;
  }

  Future<bool> submitAnnouncement({
    required String title,
    required String message,
    required AnnouncementPriority priority,
    required DateTime? expiryDate,
    required List<String> selectedDepartments,
    required List<String> selectedEmails,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedMessage = message.trim();

    if (normalizedTitle.isEmpty) {
      SnackbarService.showError('Title is required');
      return false;
    }
    if (normalizedMessage.isEmpty) {
      SnackbarService.showError('Announcement message is required');
      return false;
    }
    if (selectedDepartments.isEmpty && selectedEmails.isEmpty) {
      SnackbarService.showError('Select at least one user or department');
      return false;
    }

    final resolvedExpiry =
        expiryDate ?? DateTime.now().add(const Duration(days: 1));

    return createAnnouncement(
      title: normalizedTitle,
      message: normalizedMessage,
      priority: priority,
      expiryDate: resolvedExpiry,
      selectedDepartments: selectedDepartments,
      selectedEmails: selectedEmails,
    );
  }

  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.hasLoadedOnce && !forceRefresh) return;

    // Demo mode: return hardcoded announcements, no API call
    if (_ref.read(demoModeProvider)) {
      state = state.copyWith(
        items: DemoConstants.announcements,
        isLoading: false,
        hasLoadedOnce: true,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiService.fetchActiveAnnouncements();
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
    required String title,
    required String message,
    required AnnouncementPriority priority,
    required DateTime expiryDate,
    required List<String> selectedDepartments,
    required List<String> selectedEmails,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final payload = {
        'senderName': (AuthManager.userName ?? 'Unknown').trim(),
        'targets': {
          'topics': selectedDepartments,
          'emails': selectedEmails,
        },
        'notificationType': priority.apiValue,
        'expiresOn': expiryDate.toIso8601String(),
        'notification': {
          'title': title.trim(),
          'body': message.trim(),
        },
        'data': {
          'type': 'announcement',
        },
      };

      await ApiService.createAnnouncement(payload);

      state = state.copyWith(
        isSubmitting: false,
        hasLoadedOnce: true,
        clearError: true,
      );

      await fetchAnnouncements(forceRefresh: true);

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
      map['notifications'],
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

}
