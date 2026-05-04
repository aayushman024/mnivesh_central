import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/api_service.dart';
import '../Models/appModel.dart';

// The ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final refreshTriggerProvider = StateProvider<int>((ref) => 0);
final updateCountProvider = StateProvider<int>((ref) => 0);

// --- THEME PROVIDERS ---

// Self-hydrating theme notifier — defaults to light mode,
// then self-corrects once SharedPreferences loads (~50ms).
class ThemeNotifier extends StateNotifier<ThemeMode> {
  SharedPreferences? _prefs;

  ThemeNotifier() : super(ThemeMode.light) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString('theme_mode');
    if (saved == 'dark' && state != ThemeMode.dark) {
      state = ThemeMode.dark;
    }
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _prefs?.setString('theme_mode', state == ThemeMode.light ? 'light' : 'dark');
  }
}

// The exposed theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// --- APPS PROVIDERS ---

// The ViewModel/Controller
class AppsNotifier extends AsyncNotifier<List<AppModel>> {
  @override
  FutureOr<List<AppModel>> build() async {
    // Automatically fetches data when the provider is first watched
    return _fetchApps();
  }

  Future<List<AppModel>> _fetchApps() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.fetchApps();
  }

  // Method to refresh manually if needed
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchApps());
  }
}

// The exposed provider
final appsProvider = AsyncNotifierProvider<AppsNotifier, List<AppModel>>(() {
  return AppsNotifier();
});