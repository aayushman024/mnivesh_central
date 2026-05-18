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
  final List<ModuleItem> mostUsedModules;
  final bool isDefault;

  const RecentModulesState({
    required this.modules,
    required this.mostUsedModules,
    required this.isDefault,
  });
}

/// Riverpod provider that exposes a sorted list of [ModuleItem]s
/// based on local usage data (recency → frequency).
final recentModulesProvider =
    StateNotifierProvider<RecentModulesNotifier, RecentModulesState>((ref) {
  return RecentModulesNotifier();
});

class RecentModulesNotifier extends StateNotifier<RecentModulesState> {
  RecentModulesNotifier() : super(const RecentModulesState(modules: [], mostUsedModules: [], isDefault: true)) {
    _hydrate();
  }

  /// Load persisted usage data and build the sorted list.
  Future<void> _hydrate() async {
    try {
      final sortedNames = await ModuleUsageService.getSortedModuleNames();
      final usage = await ModuleUsageService.getUsageMap();

      if (sortedNames.isEmpty) {
        // No usage history → show defaults, filtered by department
        final defaults = await _defaultModules();
        state = RecentModulesState(modules: defaults, mostUsedModules: defaults, isDefault: true);
        return;
      }

      // Map sorted names back to ModuleItem objects (including sub-modules!)
      final allPossible = [...appModules, ...subModules];
      final moduleMap = {for (final m in allPossible) m.title: m};
      
      final recentResult = <ModuleItem>[];
      for (final name in sortedNames) {
        final item = moduleMap[name];
        if (item != null) recentResult.add(item);
      }

      // Most used: sorted purely by count descending
      final mostUsedEntries = usage.entries.toList()
        ..sort((a, b) => b.value.count.compareTo(a.value.count));
      
      final mostUsedResult = <ModuleItem>[];
      for (final entry in mostUsedEntries) {
        final item = moduleMap[entry.key];
        if (item != null) mostUsedResult.add(item);
      }

      state = RecentModulesState(
        modules: recentResult,
        mostUsedModules: mostUsedResult,
        isDefault: false,
      );
    } catch (e) {
      debugPrint('[RecentModulesNotifier] hydrate failed: $e');
      final defaults = await _defaultModules();
      state = RecentModulesState(modules: defaults, mostUsedModules: defaults, isDefault: true);
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

class FavouritesNotifier extends StateNotifier<List<String>> {
  FavouritesNotifier() : super([]) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final favs = await ModuleUsageService.getFavourites();
      state = favs;
    } catch (e) {
      debugPrint('[FavouritesNotifier] hydrate failed: $e');
    }
  }

  Future<void> toggleFavourite(String moduleName) async {
    try {
      await ModuleUsageService.toggleFavourite(moduleName);
      await _hydrate();
    } catch (e) {
      debugPrint('[FavouritesNotifier] toggle failed: $e');
    }
  }
}

final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, List<String>>((ref) {
  return FavouritesNotifier();
});

