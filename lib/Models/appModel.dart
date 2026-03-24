
class AppModel {
  final String id;
  final String appName;
  final String packageName;
  final String version;
  final bool isActive;
  final String description;
  final String changelog;
  final String colorKey;
  final String icon;
  final String downloadUrl;

  AppModel({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.version,
    required this.isActive,
    required this.description,
    required this.changelog,
    required this.colorKey,
    required this.icon,
    required this.downloadUrl,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['_id'] ?? '',
      appName: json['appName'] ?? '',
      packageName: json['packageName'] ?? '',
      version: json['version'] ?? '',
      isActive: json['isActive'] ?? false,
      description: json['description'] ?? '',
      changelog: json['changelog'] ?? '',
      colorKey: json['colorKey'] ?? 'violet', // Default fallback
      icon: json['icon'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
    );
  }
}