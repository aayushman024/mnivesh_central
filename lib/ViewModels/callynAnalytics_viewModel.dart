import 'package:flutter/material.dart';
import '../API/api_service.dart';
import '../API/callyn_apiService.dart';
import '../Models/callyn_analytics_model.dart';
import '../Models/userDetailsModel.dart';

enum AnalyticsFilter { today, yesterday, thisWeek, lastWeek, currentMonth, allTime }

class CallLogAnalyticsViewModel extends ChangeNotifier {
  CallLogAnalyticsModel? analyticsData;
  bool isLoading = true;
  String? errorMessage;
  DateTime? _customFromDate;
  DateTime? _customToDate;
  bool _isCustom = false;

  AnalyticsFilter selectedFilter = AnalyticsFilter.today;

  List<UserDetail> employees = [];
  String? searchName;

  CallLogAnalyticsViewModel() {
    fetchEmployees();
    fetchData();
  }

  // Fetch employees for the dropdown
  Future<void> fetchEmployees() async {
    try {
      employees = await ApiService.getUserDetails();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load employees for filter: $e');
    }
  }

  // Update selected employee and trigger fetch
  void setSearchName(String? name) {
    if (searchName == name) return;
    searchName = name;
    fetchData();
  }

  final Map<AnalyticsFilter, String> filterLabels = {
    AnalyticsFilter.today: "Today",
    AnalyticsFilter.yesterday: "Yesterday",
    AnalyticsFilter.thisWeek: "This Week",
    AnalyticsFilter.lastWeek: "Last Week",
    AnalyticsFilter.currentMonth: "Current Month",
    AnalyticsFilter.allTime: "All Time",
  };

  void setFilter(AnalyticsFilter filter) {
    if (selectedFilter == filter) return;

    selectedFilter = filter;
    _isCustom = false;
    _customFromDate = null;
    _customToDate = null;

    fetchData();
  }

  void setCustomDate(DateTime date) {
    _customFromDate = date;
    _customToDate = date;
    _isCustom = true;
    fetchData();
  }

  void setCustomDateRange(DateTimeRange range) {
    _customFromDate = range.start;
    _customToDate = range.end;
    _isCustom = true;
    fetchData();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetchData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      String? fromDate;
      String? toDate;

      if (_isCustom && _customFromDate != null) {
        fromDate = _formatDate(_customFromDate!);
        toDate = _formatDate(_customToDate ?? _customFromDate!);
      } else {
        toDate = _formatDate(now);

        switch (selectedFilter) {
          case AnalyticsFilter.today:
            fromDate = _formatDate(now);
            break;

          case AnalyticsFilter.yesterday:
            final yesterday = now.subtract(const Duration(days: 1));
            fromDate = _formatDate(yesterday);
            toDate = _formatDate(yesterday);
            break;

          case AnalyticsFilter.thisWeek:
            fromDate = _formatDate(
                now.subtract(Duration(days: now.weekday - 1)));
            break;

          case AnalyticsFilter.lastWeek:
            final startOfThisWeek =
            now.subtract(Duration(days: now.weekday - 1));

            final startLastWeek =
            startOfThisWeek.subtract(const Duration(days: 7));

            final endLastWeek =
            startOfThisWeek.subtract(const Duration(days: 1));

            fromDate = _formatDate(startLastWeek);
            toDate = _formatDate(endLastWeek);
            break;

          case AnalyticsFilter.currentMonth:
            fromDate = _formatDate(DateTime(now.year, now.month, 1));
            break;

          case AnalyticsFilter.allTime:
            fromDate = null;
            toDate = DateTime.now().toIso8601String();
            break;
        }
      }

      final rawData = await CallynApiService.fetchCallLogAnalytics(
        fromDate: fromDate,
        toDate: toDate,
        name: searchName,
      );

      analyticsData = CallLogAnalyticsModel.fromJson(rawData);

    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
