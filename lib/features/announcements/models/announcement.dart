enum AnnouncementPriority { normal, high, critical }

class Announcement {
  final String id;
  final String title;
  final String message;
  final String uploadedBy;
  final DateTime uploadedOn;
  final DateTime? expiryDate;
  final AnnouncementPriority priority;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.uploadedBy,
    required this.uploadedOn,
    required this.priority,
    this.expiryDate,
  });

  bool get isUrgent {
    if (expiryDate == null) return false;
    final remaining = expiryDate!.difference(DateTime.now()).inDays;
    return remaining >= 0 && remaining <= 2;
  }

  bool get isNew {
    final age = DateTime.now().difference(uploadedOn).inHours;
    return age >= 0 && age < 24;
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse((json['createdAt'] ?? '').toString())
            ?.toLocal() ??
        DateTime.now();
    final title = (json['title'] ?? '').toString().trim();
    final body = (json['body'] ?? '').toString().trim();
    final senderName = (json['senderName'] ?? '').toString().trim();
    final expiresOn = DateTime.tryParse((json['expiresOn'] ?? '').toString())
        ?.toLocal();
    final priorityRaw = (json['priority'] ?? '').toString().trim();

    return Announcement(
      id: '${createdAt.microsecondsSinceEpoch}_${title}_$body',
      title: title,
      message: body,
      uploadedBy: senderName.isEmpty ? 'Unknown' : senderName,
      uploadedOn: createdAt,
      expiryDate: expiresOn,
      priority: AnnouncementPriorityX.fromApiValue(priorityRaw),
    );
  }
}

extension AnnouncementPriorityX on AnnouncementPriority {
  String get label => switch (this) {
        AnnouncementPriority.critical => 'CRITICAL',
        AnnouncementPriority.high => 'HIGH',
        AnnouncementPriority.normal => 'INFO',
      };

  String get apiValue => switch (this) {
        AnnouncementPriority.critical => 'critical',
        AnnouncementPriority.high => 'high',
        AnnouncementPriority.normal => 'info',
      };

  static AnnouncementPriority fromApiValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'critical':
        return AnnouncementPriority.critical;
      case 'high':
        return AnnouncementPriority.high;
      case 'info':
      default:
        return AnnouncementPriority.normal;
    }
  }
}
