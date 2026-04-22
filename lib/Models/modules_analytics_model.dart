class ModuleTapSummaryRecord {
  final String moduleName;
  final DateTime date;
  final int totalTaps;

  ModuleTapSummaryRecord({
    required this.moduleName,
    required this.date,
    required this.totalTaps,
  });

  factory ModuleTapSummaryRecord.fromJson(Map<String, dynamic> json) {
    return ModuleTapSummaryRecord(
      moduleName: json['moduleName']?.toString().trim() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime(1970),
      totalTaps: (json['totalTaps'] as num?)?.toInt() ?? 0,
    );
  }
}

class ModuleUserAccessRecord {
  final String email;
  final int taps;
  final DateTime? createdAt;

  ModuleUserAccessRecord({
    required this.email,
    required this.taps,
    this.createdAt,
  });

  factory ModuleUserAccessRecord.fromJson(Map<String, dynamic> json) {
    return ModuleUserAccessRecord(
      email: json['email']?.toString().trim() ?? '',
      taps: (json['taps'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class ModuleAnalyticsGroup {
  final String moduleName;
  final int totalTaps;
  final List<ModuleTapSummaryRecord> records;
  final List<ModuleUserAccessRecord> recentUsers;

  ModuleAnalyticsGroup({
    required this.moduleName,
    required this.totalTaps,
    required this.records,
    required this.recentUsers,
  });
}

enum ModuleAnalyticsSortOrder { mostToLeast, leastToMost }
