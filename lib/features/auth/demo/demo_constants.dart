import 'package:mnivesh_central/features/announcements/models/announcement.dart';

/// Compile-time constants for the app-store reviewer demo mode.
/// These credentials are intentionally non-sensitive and exist solely
/// to let store reviewers explore the app without a real account.
abstract final class DemoConstants {
  static const String email = 'guest@niveshonline.com';
  static const String password = 'guest@central24';
  static const String displayName = 'Guest';
  static const String department = 'Play Store';

  /// Three hardcoded announcements shown to demo-mode users.
  static final List<Announcement> announcements = [
    Announcement(
      id: 'demo_announcement_1',
      title: '🎉 Welcome to mNivesh Central',
      message:
          'You are exploring mNivesh Central in Demo Mode. This is a preview of the app experience available to all team members.',
      uploadedBy: 'mNivesh Team',
      uploadedOn: DateTime.now().subtract(const Duration(hours: 2)),
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      priority: AnnouncementPriority.high,
    ),
    Announcement(
      id: 'demo_announcement_2',
      title: '📊 Track Attendance & Field Visits',
      message:
          'Use the Daftar tab to mark daily attendance, log field visits, and view your location-based check-in history — all in one place.',
      uploadedBy: 'HR Department',
      uploadedOn: DateTime.now().subtract(const Duration(hours: 5)),
      expiryDate: DateTime.now().add(const Duration(days: 14)),
      priority: AnnouncementPriority.normal,
    ),
    Announcement(
      id: 'demo_announcement_3',
      title: '🚀 Explore All Modules',
      message:
          'Head to the Modules tab to discover tools for Route Management, Analytics, Operations, and more — designed to power your day-to-day workflow.',
      uploadedBy: 'Product Team',
      uploadedOn: DateTime.now().subtract(const Duration(days: 1)),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      priority: AnnouncementPriority.normal,
    ),
  ];
}
