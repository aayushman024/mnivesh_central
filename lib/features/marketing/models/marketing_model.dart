class MarketingCategory {
  final String id;
  final String key;
  final String label;

  MarketingCategory({
    required this.id,
    required this.key,
    required this.label,
  });

  factory MarketingCategory.fromJson(Map<String, dynamic> json) {
    return MarketingCategory(
      id: json['_id'] ?? '',
      key: json['key'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class DisclaimerOption {
  final String id;
  final String key;
  final String label;
  final String text;

  DisclaimerOption({
    required this.id,
    required this.key,
    required this.label,
    required this.text,
  });

  factory DisclaimerOption.fromJson(Map<String, dynamic> json) {
    return DisclaimerOption(
      id: json['_id'] ?? '',
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

class MarketingTemplate {
  final String id;
  final String title;
  final String description;
  final String proxyImageUrl;
  final MarketingCategory? category;
  final DisclaimerOption? disclaimer;
  final DateTime publishDate;
  final DateTime? closeDate;

  MarketingTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.proxyImageUrl,
    this.category,
    this.disclaimer,
    required this.publishDate,
    this.closeDate,
  });

  factory MarketingTemplate.fromJson(Map<String, dynamic> json) {
    return MarketingTemplate(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      proxyImageUrl: json['proxyImageUrl'] ?? '',
      category: json['category'] != null
          ? MarketingCategory.fromJson(json['category'])
          : null,
      disclaimer: json['disclaimer'] != null
          ? DisclaimerOption.fromJson(json['disclaimer'])
          : null,
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'])
          : DateTime.now(),
      closeDate: json['closeDate'] != null
          ? DateTime.parse(json['closeDate'])
          : null,
    );
  }
}
