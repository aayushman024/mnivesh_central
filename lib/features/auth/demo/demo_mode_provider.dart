import 'package:flutter_riverpod/legacy.dart';

/// Single source of truth for whether the app is running in Demo Mode.
///
/// When `true`:
///  - No API calls are made (announcements, location, attendance, etc.)
///  - User profile shows hardcoded guest data from [DemoConstants]
///  - Hardcoded announcements are shown
///  - Firebase / analytics events are suppressed
///
/// Set to `true` by [DemoLoginDialog] on successful credential match.
/// Reset to `false` when the user logs out from demo mode.
final demoModeProvider = StateProvider<bool>((ref) => false);
