import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how often and when each module is opened, persisted via
/// SharedPreferences.
class ModuleUsageService {
  ModuleUsageService._();

  static const String _storageKey = 'module_usage';

  /// Record that the user opened [moduleName] right now.
  static Future<void> recordOpen(String moduleName) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);

    final existing = map[moduleName];
    map[moduleName] = {
      'lastOpened': DateTime.now().millisecondsSinceEpoch,
      'count': (existing?['count'] as int? ?? 0) + 1,
    };

    await prefs.setString(_storageKey, jsonEncode(map));
  }

  /// Returns every tracked module as a map of
  /// `{ moduleName: ModuleUsageEntry }`.
  static Future<Map<String, ModuleUsageEntry>> getUsageMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _readMap(prefs);

    return raw.map((key, value) {
      return MapEntry(
        key,
        ModuleUsageEntry(
          lastOpened: DateTime.fromMillisecondsSinceEpoch(
            value['lastOpened'] as int? ?? 0,
          ),
          count: value['count'] as int? ?? 0,
        ),
      );
    });
  }

  /// Returns module names sorted by most-recently-opened first,
  /// with open-count as the tiebreaker (higher count wins).
  static Future<List<String>> getSortedModuleNames() async {
    final usage = await getUsageMap();
    if (usage.isEmpty) return [];

    final entries = usage.entries.toList()
      ..sort((a, b) {
        // Primary: most recent first
        final timeCmp = b.value.lastOpened.compareTo(a.value.lastOpened);
        if (timeCmp != 0) return timeCmp;
        // Secondary: highest count first
        return b.value.count.compareTo(a.value.count);
      });

    return entries.map((e) => e.key).toList();
  }

  /// Wipe all stored usage data (e.g. on logout).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_favouritesKey);
  }

  static const String _favouritesKey = 'module_favourites';

  /// Retrieve the list of favorited module titles.
  static Future<List<String>> getFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favouritesKey) ?? [];
  }

  /// Toggle the favorite status of [moduleName].
  static Future<void> toggleFavourite(String moduleName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_favouritesKey) ?? [];
    if (current.contains(moduleName)) {
      current.remove(moduleName);
    } else {
      current.add(moduleName);
    }
    await prefs.setStringList(_favouritesKey, current);
  }

  // ── Private helpers ──────────────────────────────────────────────

  static Map<String, Map<String, dynamic>> _readMap(SharedPreferences prefs) {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(
            key as String,
            Map<String, dynamic>.from(value as Map),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ModuleUsageService] Failed to decode usage data: $e');
    }
    return {};
  }
}

/// A single module's usage stats.
class ModuleUsageEntry {
  final DateTime lastOpened;
  final int count;

  const ModuleUsageEntry({required this.lastOpened, required this.count});
}
