import 'package:flutter/material.dart';

import '../API/analytics_api_service.dart';
import '../Models/modules_analytics_model.dart';

class ModulesAnalyticsViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  DateTimeRangeSelection rangeSelection = DateTimeRangeSelection.last30Days;
  DateTimeRange dateRange = DateTimeRange(
    start: _startOfDay(DateTime.now().subtract(const Duration(days: 29))),
    end: _endOfDay(DateTime.now()),
  );

  ModuleAnalyticsSortOrder sortOrder = ModuleAnalyticsSortOrder.mostToLeast;
  List<ModuleAnalyticsGroup> modules = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final summaries = await AnalyticsApiService.getModuleTapsSummary(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );

      final groupedRecords = <String, List<ModuleTapSummaryRecord>>{};
      for (final summary in summaries) {
        groupedRecords.putIfAbsent(summary.moduleName, () => []).add(summary);
      }

      final moduleNames = groupedRecords.keys.toList();
      final usersByModule = <String, List<ModuleUserAccessRecord>>{};

      await Future.wait(
        moduleNames.map((moduleName) async {
          try {
            usersByModule[moduleName] =
                await AnalyticsApiService.getRecentModuleUsers(
                  moduleName,
                  hours: 24,
                );
          } catch (_) {
            usersByModule[moduleName] = const [];
          }
        }),
      );

      modules = moduleNames.map((moduleName) {
        final records = groupedRecords[moduleName] ?? const [];
        final totalTaps = records.fold<int>(
          0,
          (sum, record) => sum + record.totalTaps,
        );

        return ModuleAnalyticsGroup(
          moduleName: moduleName,
          totalTaps: totalTaps,
          records: records,
          recentUsers: usersByModule[moduleName] ?? const [],
        );
      }).toList();

      _sortAll();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectPreset(DateTimeRangeSelection selection) async {
    rangeSelection = selection;
    dateRange = switch (selection) {
      DateTimeRangeSelection.today => DateTimeRange(
        start: _startOfDay(DateTime.now()),
        end: _endOfDay(DateTime.now()),
      ),
      DateTimeRangeSelection.last7Days => DateTimeRange(
        start: _startOfDay(DateTime.now().subtract(const Duration(days: 6))),
        end: _endOfDay(DateTime.now()),
      ),
      DateTimeRangeSelection.last30Days => DateTimeRange(
        start: _startOfDay(DateTime.now().subtract(const Duration(days: 29))),
        end: _endOfDay(DateTime.now()),
      ),
      DateTimeRangeSelection.custom => dateRange,
    };
    await load();
  }

  Future<void> setCustomRange(DateTimeRange range) async {
    rangeSelection = DateTimeRangeSelection.custom;
    dateRange = DateTimeRange(
      start: _startOfDay(range.start),
      end: _endOfDay(range.end),
    );
    await load();
  }

  Future<void> toggleSortOrder() async {
    sortOrder = sortOrder == ModuleAnalyticsSortOrder.mostToLeast
        ? ModuleAnalyticsSortOrder.leastToMost
        : ModuleAnalyticsSortOrder.mostToLeast;
    _sortAll();
    notifyListeners();
  }

  bool get isDescending => sortOrder == ModuleAnalyticsSortOrder.mostToLeast;

  void _sortAll() {
    final descending = isDescending;

    modules.sort((left, right) {
      final totalCompare = left.totalTaps.compareTo(right.totalTaps);
      if (totalCompare != 0) {
        return descending ? -totalCompare : totalCompare;
      }
      return left.moduleName.toLowerCase().compareTo(
        right.moduleName.toLowerCase(),
      );
    });

    modules = modules.map((module) {
      final sortedRecords = [...module.records]
        ..sort((left, right) {
          final tapsCompare = left.totalTaps.compareTo(right.totalTaps);
          if (tapsCompare != 0) {
            return descending ? -tapsCompare : tapsCompare;
          }
          return descending
              ? right.date.compareTo(left.date)
              : left.date.compareTo(right.date);
        });

      final sortedUsers = [...module.recentUsers]
        ..sort((left, right) {
          final tapsCompare = left.taps.compareTo(right.taps);
          if (tapsCompare != 0) {
            return descending ? -tapsCompare : tapsCompare;
          }
          return left.email.toLowerCase().compareTo(right.email.toLowerCase());
        });

      return ModuleAnalyticsGroup(
        moduleName: module.moduleName,
        totalTaps: module.totalTaps,
        records: sortedRecords,
        recentUsers: sortedUsers,
      );
    }).toList();
  }

  static DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }
}

enum DateTimeRangeSelection { today, last7Days, last30Days, custom }
