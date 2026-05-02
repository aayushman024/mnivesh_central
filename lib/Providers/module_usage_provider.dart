import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mnivesh_central/Services/bootstrap_service.dart';

import '../Managers/AuthManager.dart';
import '../Models/moduleScreen_data.dart';
import '../Services/module_usage_service.dart';

/// Default modules shown when the user has no usage history.
/// Department-filtered at display time.
const List<String> _defaultModuleNames = [
  'MF Transaction Form',
  'Callyn Analytics',
  'Modules Analytics',
  'Leave Management'
];

/// State class for the recent modules provider.
class RecentModulesState {
  final List<ModuleItem> modules;
  final bool isDefault;

  const RecentModulesState({required this.modules, required this.isDefault});
}

/// Riverpod provider that exposes a sorted list of [ModuleItem]s
/// based on local usage data (recency → frequency).
final recentModulesProvider =
    StateNotifierProvider<RecentModulesNotifier, RecentModulesState>((ref) {
  return RecentModulesNotifier();
});

class RecentModulesNotifier extends StateNotifier<RecentModulesState> {
  RecentModulesNotifier() : super(const RecentModulesState(modules: [], isDefault: true)) {
    _hydrate();
  }

  /// Load persisted usage data and build the sorted list.
  Future<void> _hydrate() async {
    try {
      final sortedNames = await ModuleUsageService.getSortedModuleNames();

      if (sortedNames.isEmpty) {
        // No usage history → show defaults, filtered by department
        state = RecentModulesState(modules: await _defaultModules(), isDefault: true);
        return;
      }

      // Map sorted names back to ModuleItem objects
      final moduleMap = {for (final m in appModules) m.title: m};
      final result = <ModuleItem>[];
      for (final name in sortedNames) {
        final item = moduleMap[name];
        if (item != null) result.add(item);
      }

      state = RecentModulesState(modules: result, isDefault: false);
    } catch (e) {
      debugPrint('[RecentModulesNotifier] hydrate failed: $e');
      state = RecentModulesState(modules: await _defaultModules(), isDefault: true);
    }
  }

  /// Record a module tap and refresh the sorted list.
  Future<void> recordAndRefresh(String moduleName) async {
    await ModuleUsageService.recordOpen(moduleName);
    await _hydrate();
  }

  /// Force-refresh from storage (e.g. on pull-to-refresh).
  Future<void> refresh() async => _hydrate();

  /// Returns the default modules, filtered by the current user's
  /// department when restrictions apply.
  Future<List<ModuleItem>> _defaultModules() async {
    await BootstrapService.ready;
    final dept = AuthManager.department;
    return appModules.where((m) {
      if (!_defaultModuleNames.contains(m.title)) return false;
      if (m.allowedDepartments.isEmpty) return true;
      return dept != null && m.allowedDepartments.contains(dept);
    }).toList();
  }
}
