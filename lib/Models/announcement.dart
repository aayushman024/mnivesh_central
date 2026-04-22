enum AnnouncementPriority { normal, high, critical }

class Announcement {
  final String id;
  final String companyId;
  final String message;
  final String uploadedBy;
  final DateTime uploadedOn;
  final DateTime? expiryDate;
  final AnnouncementPriority priority;
  final String notificationStatus;
  final String notificationError;
  final String notificationMessageId;
  final bool isActive;

  const Announcement({
    required this.id,
    this.companyId = '',
    required this.message,
    required this.uploadedBy,
    required this.uploadedOn,
    required this.priority,
    this.expiryDate,
    this.notificationStatus = 'pending',
    this.notificationError = '',
    this.notificationMessageId = '',
    this.isActive = true,
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
    String creator = '';

    // First try the nested uploadedBy object
    creator = _readNestedString(
      json,
      const [
        ['uploadedBy', 'name'],
        ['uploaded_by', 'name'],
        ['createdBy', 'name'],
        ['creator', 'name'],
        ['author', 'name'],
        ['user', 'name'],
      ],
    );

    // If still empty or if it was a plain string, try reading as string array
    if (creator.trim().isEmpty) {
      creator = _readString(
        json,
        const [
          'createdByName',
          'creatorName',
          'authorName',
          'name',
        ],
      );

      // Handle the case where uploadedBy is directly a string
      if (creator.trim().isEmpty) {
        final rawUploadedBy = json['uploadedBy'] ?? json['uploaded_by'];
        if (rawUploadedBy is String) {
          creator = rawUploadedBy;
        }
      }
    }

    return Announcement(
      id: _readString(json, const ['id', '_id']).trim(),
      companyId: _readString(json, const ['companyId', 'company_id']).trim(),
      message: _readString(
        json,
        const ['message', 'content', 'text', 'body', 'announcement'],
      ).trim(),
      uploadedBy: creator.trim().isNotEmpty ? creator.trim() : 'Unknown',
      uploadedOn: _readDateTime(
            json,
            const ['uploadedAt', 'uploaded_at', 'createdAt', 'uploadedOn'],
          ) ??
          DateTime.now(),
      expiryDate: _readDateTime(
        json,
        const ['expiresAt', 'expiry_date', 'expiryDate', 'expiresOn'],
      ),
      priority: AnnouncementPriorityX.fromApiValue(
        _readString(json, const ['priority', 'type', 'level']),
      ),
      notificationStatus: _readString(json, const ['notificationStatus', 'notification_status']).trim().isNotEmpty ? _readString(json, const ['notificationStatus', 'notification_status']).trim() : 'pending',
      notificationError: _readString(json, const ['notificationError', 'notification_error']).trim(),
      notificationMessageId: _readString(json, const ['notificationMessageId', 'notification_message_id']).trim(),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
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
        AnnouncementPriority.normal => 'normal',
      };

  static AnnouncementPriority fromApiValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'critical':
        return AnnouncementPriority.critical;
      case 'high':
        return AnnouncementPriority.high;
      default:
        return AnnouncementPriority.normal;
    }
  }
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final asString = value.toString();
    if (asString.isNotEmpty) return asString;
  }
  return '';
}

String _readNestedString(
  Map<String, dynamic> json,
  List<List<String>> paths,
) {
  for (final path in paths) {
    dynamic current = json;
    for (final segment in path) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        current = null;
        break;
      }
    }

    if (current == null) continue;
    final asString = current.toString();
    if (asString.isNotEmpty) return asString;
  }

  return '';
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
  return null;
}
