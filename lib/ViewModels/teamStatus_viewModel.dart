import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../API/api_service.dart';
import '../../Models/appModel.dart';
import '../../Models/userDetailsModel.dart';

class TeamStatusData {
  final List<UserDetail> users;
  final List<AppModel> managedApps;
  TeamStatusData(this.users, this.managedApps);
}

// combining everything into a single state so the UI reacts to both
// data loads and local filter changes automatically
class TeamStatusState {
  final AsyncValue<TeamStatusData> data;
  final String searchQuery;
  final bool latestFirst;

  TeamStatusState({
    required this.data,
    this.searchQuery = "",
    this.latestFirst = true,
  });

  TeamStatusState copyWith({
    AsyncValue<TeamStatusData>? data,
    String? searchQuery,
    bool? latestFirst,
  }) {
    return TeamStatusState(
      data: data ?? this.data,
      searchQuery: searchQuery ?? this.searchQuery,
      latestFirst: latestFirst ?? this.latestFirst,
    );
  }

  // running the exact same filtering/sorting logic here
  // returning the computed list directly
  List<UserDetail> get filteredUsers {
    return data.maybeWhen(
      data: (teamData) {
        var filtered = teamData.users.where((u) {
          final query = searchQuery.toLowerCase();
          return u.username.toLowerCase().contains(query) ||
              u.department.toLowerCase().contains(query) ||
              u.appsInstalled.any((a) => a.toLowerCase().contains(query));
        }).toList();

        filtered.sort((a, b) => latestFirst
            ? b.lastSeen.compareTo(a.lastSeen)
            : a.lastSeen.compareTo(b.lastSeen));

        return filtered;
      },
      orElse: () => [],
    );
  }
}

// using StateNotifier for bulletproof compilation
class TeamStatusViewModel extends StateNotifier<TeamStatusState> {
  TeamStatusViewModel() : super(TeamStatusState(data: const AsyncLoading())) {
    _fetchData();
  }

  Future<void> _fetchData() async {
    state = state.copyWith(data: const AsyncLoading());
    try {
      // Fetch both in parallel just like before
      final results = await Future.wait([
        ApiService.getUserDetails(),
        ApiService().fetchApps(),
      ]);

      final data = TeamStatusData(
        results[0] as List<UserDetail>,
        results[1] as List<AppModel>,
      );

      state = state.copyWith(data: AsyncData(data));
    } catch (e, st) {
      state = state.copyWith(data: AsyncError(e, st));
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSortOrder() {
    state = state.copyWith(latestFirst: !state.latestFirst);
  }

  void retryConnection() {
    _fetchData();
  }
}

final teamStatusViewModelProvider = StateNotifierProvider.autoDispose<TeamStatusViewModel, TeamStatusState>((ref) {
  return TeamStatusViewModel();
});