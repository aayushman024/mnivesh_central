class UserDetail {
  final String username;
  final String email;
  final String department;
  final String deviceModel;
  final String osVersion;
  final List<String> appsInstalled;
  final DateTime lastSeen;

  UserDetail({
    required this.username,
    required this.email,
    required this.department,
    required this.deviceModel,
    required this.osVersion,
    required this.appsInstalled,
    required this.lastSeen,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      username: json['username'] ?? 'Unknown',
      email: json['email'] ?? 'N/A',
      department: json['department'] ?? 'N/A',
      deviceModel: json['phoneDetails']?['deviceModel'] ?? 'Unknown',
      osVersion: json['phoneDetails']?['osVersion'] ?? 'Unknown',
      appsInstalled: List<String>.from(json['appsInstalled'] ?? []),
      lastSeen: DateTime.parse(json['lastSeen'] ?? DateTime.now().toIso8601String()),
    );
  }
}